---
title: "V8 Memory and the Node Event Loop"
layout: post
date: 2026-07-28 00:10
description: "How V8 manages memory and how Node runs callbacks, with interactive guides to garbage collection, the event loop, the thread pool, workers, and processes."
tag:
- V8
- Node.js
- Garbage Collection
- Event Loop
blog: true
jemoji:
---

Reference notes for myself on how V8 manages memory and how Node decides what runs next. The two meet on the JavaScript thread: a garbage-collection pause delays callbacks just as a long piece of synchronous code does. That pause is different from the event loop waiting for I/O when it has no callbacks ready to run.

Two interactive animations do most of the explaining. Each has a guided tour you can step through beat by beat, plus a free mode where you fire operations and watch them move.

Keyboard in both: `↓`/`↑` step one beat, `←`/`→` jump sections, `Space` play or pause, `R` replay, `Home`/`End` first or last section.

## The V8 heap

<div class="interactive-explainer">
  <iframe src="{{ site.url }}/assets/files/v8-memory-and-the-node-event-loop/v8-memory.html"
          title="Interactive explainer: how V8 manages memory"
          loading="lazy"
          allowfullscreen></iframe>
  <div class="interactive-explainer-mobile">
    <span class="interactive-explainer-mobile__eyebrow">Interactive diagram</span>
    <strong>Explore how V8 manages memory</strong>
    <span>Open the guided animation in a full-screen, mobile-friendly view.</span>
    <a href="{{ site.url }}/assets/files/v8-memory-and-the-node-event-loop/v8-memory.html">Open interactive diagram <span aria-hidden="true">→</span></a>
  </div>
</div>

The animation shows a simplified heap layout, using the Scavenger to collect young objects. V8 versions and build options can use other layouts or collectors.

Most new objects start in **New space**, split into two halves. A **bump pointer** marks the next free position and advances as objects are added. Objects that survive collections can move to **Old space**. Large objects use separate spaces, while some allocation sites send objects straight to Old space, a choice called **pretenuring**. **Code space** holds generated machine code, and **Read-only space** holds fixed runtime data.

The parts that are easiest to get wrong:

**Heap size is only part of memory use.** Small integers can be stored directly in a value, without a separate heap object. The bytes behind `ArrayBuffer` and Node `Buffer` objects live outside V8's managed heap, so `--max-old-space-size` does not limit them. `process.memoryUsage().arrayBuffers` reports those bytes as part of the broader `external` figure. Check them when process memory grows while the JavaScript heap stays steady.

**Minor GC copies the survivors.** The Scavenger finds live young objects through roots and recorded references from older objects. It copies survivors to the other half of New space or promotes them to Old space, then flips the halves. It does not copy dead objects. Copying work depends on how much survives; allocating more still fills the space sooner and causes more collections. JavaScript pauses during a scavenge, even when helper threads share the work.

**Surviving twice is a rule of thumb.** In this model, an object that survives a second scavenge usually moves to Old space. V8 uses an age mark to distinguish objects kept by the previous scavenge from newer allocations. It does not need a counter on each object. Space pressure can move survivors earlier. Pretenuring is different: it puts an object in Old space from the start.

**Marking follows chains of references.** V8's major collector, Mark-Compact, starts from roots such as references on the stack. In the three-color model, white means unseen, grey means found but not yet scanned, and black means scanned. Scanning follows references to other objects. If a root reaches A, A reaches B, and B reaches C, all three stay alive. The animation follows those links one at a time.

**Sweeping frees space; compaction moves objects.** Sweeping makes dead objects' memory available for reuse. Compaction moves live objects from selected pages to reduce gaps. Large objects are not moved by this compaction step; when they become unreachable, their pages can be freed.

**Orinoco reduces pauses.** V8 divides collection work in three ways: incremental marking takes small steps between JavaScript work; concurrent marking uses helper threads while JavaScript keeps running; parallel collection uses several threads during a pause. Some pauses remain.

V8 tracks reference changes with **write barriers**, small checks made when code stores a reference. They record links from old objects to young ones, keep marking safe while JavaScript changes objects, and record references that need updating after objects move.

An **isolate** is a separate V8 engine instance with its own JavaScript heap. That matters when we get to worker threads.

## The Node event loop

<div class="interactive-explainer">
  <iframe src="{{ site.url }}/assets/files/v8-memory-and-the-node-event-loop/node-concurrency.html"
          title="Interactive explainer: how Node.js runs your code"
          loading="lazy"
          allowfullscreen></iframe>
  <div class="interactive-explainer-mobile">
    <span class="interactive-explainer-mobile__eyebrow">Interactive diagram</span>
    <strong>Explore how Node.js runs your code</strong>
    <span>Open the guided animation in a full-screen, mobile-friendly view.</span>
    <a href="{{ site.url }}/assets/files/v8-memory-and-the-node-event-loop/node-concurrency.html">Open interactive diagram <span aria-hidden="true">→</span></a>
  </div>
</div>

By default, Node runs your JavaScript on one main thread. The event loop decides which callback runs next; workers can run JavaScript on additional threads.

**Timers moved to the end of an iteration.** Starting with libuv 1.45, included in [Node 20.3.0](https://nodejs.org/en/blog/release/v20.3.0), the main phases run in this order:

    pending → idle/prepare → poll → check → close → timers

There is also a timer pass before entering the loop in default mode, kept for compatibility. Some pending callbacks get another turn right after poll. The [libuv source](https://github.com/libuv/libuv/blob/v1.45.0/src/unix/core.c) shows these extra steps.

The [Node event-loop guide](https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick) explains the change. Do not read the phase list above as a timing guarantee: `setTimeout(fn, 0)` has a minimum delay of 1 ms and runs only once it is due. When scheduled together inside an I/O callback, `setImmediate` runs before that timer. In older versions, timers ran at the start of the next iteration, before another pass through poll.

**Where the waiting happens.** Poll can wait for I/O when no callback is ready but work still keeps the loop alive. That includes referenced timers as well as sockets and requests. The next timer limits how long poll can wait; a queued `setImmediate` prevents that wait. Once nothing keeps the loop alive, it exits. Node can then end the process, unless a `beforeExit` handler schedules more work.

**Two queues run between callbacks.** At a normal callback boundary, Node runs queued `process.nextTick` callbacks, then V8 microtasks such as Promise callbacks. This also happens between individual timer and immediate callbacks. Work added to these queues can keep them running, so repeatedly scheduling more can delay I/O.

The names can mislead. `process.nextTick` does not wait for the next loop iteration. `setImmediate` runs in the check phase, which may still be ahead in the current iteration. There is also an exception to nextTick-first ordering: top-level ES module code runs as a microtask, so Promise callbacks scheduled there run before `nextTick` callbacks scheduled there.

**What uses the thread pool.** Most async `fs` operations, `dns.lookup()`, async `zlib`, and async forms of crypto calls such as `pbkdf2`, `scrypt`, `randomBytes`, and key generation use it. Native addons can queue work there too. Socket I/O does not use the pool, and neither does `dns.resolve*()`, which makes its own network queries. But connecting by hostname usually calls `dns.lookup()` first, so that part can wait for the pool.

The pool defaults to 4 threads, with a maximum of 1024. Set `UV_THREADPOOL_SIZE` before starting the process to change it. Every event loop in the process shares this pool, including worker threads. Starting workers does not add pool capacity. When all pool threads are busy, more work has to wait.

Keep three groups separate: V8's GC and compiler helpers, libuv's pool, and the worker threads you create. Of these, only worker threads run your JavaScript.

**Workers have separate JavaScript heaps.** Each worker has its own V8 isolate, event loop, and callback queues. Sending a normal object with `postMessage` copies it using structured cloning. A transfer list can move a transferable `ArrayBuffer` without copying its bytes; the sender then loses access. Some buffers, including Node's internal Buffer pool, cannot be transferred. A `SharedArrayBuffer` lets workers access the same bytes, with `Atomics` available to coordinate access. Transfer lists can also move resources such as a `MessagePort` or `FileHandle`.

Workers share the process's risks. An uncaught exception stops that worker and emits `error` on its parent-side `Worker` object. Handle that event in the parent; otherwise it becomes an uncaught error there too. A native crash or process-wide out-of-memory failure can stop everything. `resourceLimits` limits selected V8 resources, not total worker memory, and excludes `ArrayBuffer` backing stores.

**Processes give stronger isolation.** With `cluster`, a primary process forks workers, often using `os.availableParallelism()` to choose how many. By default, the primary accepts and distributes connections on platforms other than Windows; on Windows, the workers normally accept from a shared listening socket. Each process has its own heap, event loop, and `--max-old-space-size` limit. A GC pause in one does not directly pause another, though they still compete for CPU and system memory.

## Where the two halves meet

When GC pauses an isolate's JavaScript thread, callbacks on its loop wait, just as they would during a large synchronous `JSON.parse`. Concurrent marking is different: JavaScript can keep running while helper threads mark objects. Memory use and allocation rate therefore matter when investigating slow callbacks, alongside the application code itself.

Separate processes have independent heaps and collection schedules. Workers also give you separate JavaScript heaps within one process, but share the process's total memory use and failure risks. Neither removes competition for the machine's resources.

Check the docs for the Node version you run. Start with the event-loop guide; read `uv_run()` when the exact order matters. The animations are learning models, not a trace of every V8 or libuv detail.

## References

- [The Node.js event loop](https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick)
- [Node 20.3.0 release notes](https://nodejs.org/en/blog/release/v20.3.0)
- [libuv 1.45 event-loop implementation](https://github.com/libuv/libuv/blob/v1.45.0/src/unix/core.c)
- [libuv thread pool](https://docs.libuv.org/en/v1.x/threadpool.html)
- [Node worker threads and resource limits](https://nodejs.org/api/worker_threads.html)
- [Node process memory usage](https://nodejs.org/api/process.html#processmemoryusage)
- [Node cluster scheduling](https://nodejs.org/api/cluster.html#how-it-works)
- [V8's Orinoco garbage collector](https://v8.dev/blog/trash-talk)
- [Concurrent marking in V8](https://v8.dev/blog/concurrent-marking)
