---
title: "V8 Memory and the Node Event Loop"
layout: post
date: 2026-07-28 00:10
description: "How V8 manages memory and how Node schedules work, with two interactive animations covering heap spaces, the Scavenger, Mark-Compact, the event loop phases, the libuv thread pool, workers and process isolation."
tag:
- V8
- Node.js
- Garbage Collection
- Event Loop
blog: true
jemoji:
---

Reference notes for myself on two things that turn out to be one thing: how V8 lays out memory and collects garbage, and how Node decides what runs next. They meet at a single point, which is that a garbage-collection pause and a blocked event loop are the same stall seen from two angles.

Two interactive animations do most of the explaining. Each has a guided tour you can step through beat by beat, plus a free mode where you fire operations and watch them move.

Keyboard in both: `↓`/`↑` step one beat, `←`/`→` jump sections, `Space` play or pause, `R` replay, `Home`/`End` first or last section.

## The V8 heap

<div style="position:relative; left:50%; transform:translateX(-50%); width:min(1480px,94vw); margin-block:1.6em;">
  <iframe src="{{ site.url }}/assets/files/v8-memory-and-the-node-event-loop/v8-memory.html"
          title="Interactive explainer: how V8 manages memory"
          loading="lazy"
          style="width:100%; height:800px; border:1px solid #d4dae5; border-radius:10px;"></iframe>
</div>

The model in one paragraph. Most objects live in a heap split into spaces. A small **New space**, itself split into two equal halves, takes most fresh allocations via a bump pointer; anything above the large-object threshold, or covered by pretenuring, skips it. A large **Old space** holds whatever survived long enough to be promoted. Around them sit **Large-object** space for things too big to copy, **Code** space for JIT output, and an immortal **Read-only** space.

The parts that are easiest to get wrong:

**Not everything is on the heap.** Small integers are encoded directly in the value and never allocated at all. `ArrayBuffer` backing stores, including `Buffer` bytes, live outside V8's managed heap, which is why `--max-old-space-size` does not bound them. `process.memoryUsage().arrayBuffers` reports them specifically, counted within the broader `external` figure. This is the single most common surprise when diagnosing real memory growth.

**Minor GC is cheap because of what it does not do.** The Scavenger copies live objects from one semi-space to the other, then flips their roles. Dead objects are never individually traced or copied; their half is reclaimed wholesale. Cost tracks the survivors, not the allocation volume. It is still a stop-the-world pause, just a short parallel one.

**Promotion is positional, not a counter.** The rule of thumb is that surviving a second scavenge promotes you to Old space. The mechanism is not a per-object counter, it is an age mark in the semi-space: a reachable survivor sitting below that mark is eligible for promotion. Copy or space pressure can promote survivors earlier, and allocation-site **pretenuring** is a different thing entirely, since it allocates straight into Old space and skips New space altogether. Treat "survives twice" as the common path, not a guarantee.

**Marking is transitive, which is the whole point.** Major GC is Mark-Compact. Objects start white, become grey when discovered, and turn black once their fields have been scanned. Scanning a grey object greys everything it references, so an object stays alive by being reachable at *any* depth, not by being named directly by a root. The invariant that no black object points to a white one is what guarantees nothing live is missed. The animation walks this one edge at a time, which is the part flat diagrams never show.

**Sweep and compact are different phases.** Sweeping adds the gaps left by dead objects in the paged spaces to the free-lists. Unreachable large objects are reclaimed in that same phase, but by releasing their pages outright rather than through a free-list. Compaction is selective: V8 evacuates live objects off its most fragmented pages onto fresh ones. Large objects are never relocated, so they are freed in the sweep but are never part of compaction.

**Orinoco shrinks pauses, it does not remove them.** Incremental marking splits work into small scheduled steps, concurrent marking runs on helper threads while JavaScript executes, and parallel collection uses several threads to finish the unavoidable pauses faster. V8's write-barrier machinery is what makes that safe, and it serves at least three purposes: recording old-to-young references in remembered sets for the minor GC, preserving the marking invariant so concurrent marking cannot miss an object that becomes reachable mid-flight, and recording old-to-old slots that will need their pointers updated after compaction moves things.

One heap per isolate. That fact is what makes the second half make sense.

## The Node event loop

<div style="position:relative; left:50%; transform:translateX(-50%); width:min(1480px,94vw); margin-block:1.6em;">
  <iframe src="{{ site.url }}/assets/files/v8-memory-and-the-node-event-loop/node-concurrency.html"
          title="Interactive explainer: how Node.js runs your code"
          loading="lazy"
          style="width:100%; height:800px; border:1px solid #d4dae5; border-radius:10px;"></iframe>
</div>

Node runs your JavaScript on one thread. Everything else is about how work reaches that thread.

**The phase order moved.** This is the one worth double-checking against whatever you already believe. Since **libuv 1.45**, which landed in **Node 20.3.0** (Node 20.0 through 20.2 still carried libuv 1.44.2 and ran timers first), a loop iteration runs:

    pending → idle/prepare → poll → check → close → timers

Timers run at the *end* of an iteration, not the start, and a compatibility timer pass runs each time the loop is entered in default mode. Note also that `pending` gets a second turn right after poll, up to eight times, to avoid starving that queue.

Most third-party diagrams still show timers first. Node's own guide has since been corrected and now documents the change explicitly, with timers appearing twice in its cycle diagram.

Drawn as an endless cycle the phase sequence looks unchanged, but do not read that as "nothing happens differently". The move is observable. A `setTimeout(0)` scheduled from inside an I/O callback used to wait for the next iteration's timers phase; now the timers phase is still ahead of it in the *same* iteration, so it can fire without another trip through poll. Node's guide says as much: the change can affect how timers and `setImmediate` interact.

**Where the waiting happens.** The loop can wait in the poll phase when nothing is immediately runnable but the loop is still *alive*, meaning it holds referenced handles or requests. Note that liveness is not only sockets: a pending timer is itself an active handle and will keep the loop waiting. The wait is bounded by the nearest timer deadline, or unbounded if no timer is armed. It does not wait at all if a `setImmediate` is queued, which Node arranges with an idle handle whose only job is to stop the loop blocking. If nothing referenced remains, the loop exits and the process ends.

The usual folk version of this is "it blocks when there is nothing to do". The empty-queue half is right; the "nothing to do" half is exactly wrong, because with no referenced work left the loop does not block, it exits.

**Two queues sit outside the phases.** When a callback hands control back to Node, the `process.nextTick` queue drains completely, then V8's microtask queue drains completely, before the loop advances. Since Node 11 this happens between individual timer and immediate callbacks too, not only between phases.

Both names are traps. `process.nextTick` does **not** wait for the next iteration; it runs before the loop advances at all. `setImmediate` targets the **check** phase right after poll, which may still be ahead of you in the current iteration rather than the next one, depending on where you scheduled it. And the nextTick-before-promises rule holds at a CommonJS callback boundary but **inverts in top-level ESM**, where the module body is itself evaluated inside a microtask drain, so promise callbacks scheduled there run before `nextTick`.

**What actually uses the thread pool.** Most async `fs`, `dns.lookup()`, async `zlib`, and specific crypto calls such as `pbkdf2`, `scrypt`, `randomBytes` and key generation. Native addons can queue work there too. Socket readiness does **not** use it, and neither does `dns.resolve*()`, which does its own network queries. This is why Node can hold tens of thousands of connections even though the pool has only four threads. Do not conclude that network code never touches the pool though: anything connecting by hostname usually goes through `dns.lookup()` first, so name resolution can contend for those same four threads.

The pool defaults to 4, is capped at 1024, and is set by `UV_THREADPOOL_SIZE` before the process starts. It is **process-global**: every event loop in the process, worker threads included, shares the same threads. Spawning workers does not multiply it. Fire more pool-backed work than there are threads and it queues, and one long task effectively shrinks the pool by one.

**Three unrelated sets of threads** get conflated constantly: V8's own GC and JIT helpers, libuv's process-global pool of four, and any worker threads you spawn. Only the last runs your JavaScript.

**Workers are isolates, not processes.** Each worker gets its own V8 isolate, heap, event loop, and pair of queues, so ordinary objects can never be shared. For payload memory there are three choices: `postMessage` structured-clones a copy, a transfer list moves an `ArrayBuffer`'s ownership with no copy, and a `SharedArrayBuffer` maps the same bytes into both isolates with `Atomics` to coordinate. Transfer lists can also hand over resources such as a `MessagePort` or a `FileHandle`. Separate heaps also means separate GC, so a worker's collection does not pause the main thread.

Workers are not a full isolation boundary though. An uncaught exception terminates that worker and emits `error` on its parent-side `Worker` object, and the parent survives *only if it handles that event*: an unhandled `error` on an `EventEmitter` is thrown and will take the process with it. A native fault or a global OOM takes everything down regardless. `resourceLimits` caps selected per-worker JS-engine resources rather than the worker's total memory, and notably excludes external data such as `ArrayBuffer` backing stores, which loops back to the external-memory point above.

**Processes are the real boundary.** With `cluster`, a primary process forks however many workers you ask for, commonly one per `os.availableParallelism()`. Under the default off-Windows `SCHED_RR` policy the primary owns the listening socket and hands accepted connections to workers over IPC; Windows lets the OS distribute them instead. Each process gets its own isolate, heap, event loop and `--max-old-space-size` budget, so a GC pause in one never stalls another. They still share OS resources such as files, sockets and system limits, so the isolation is strong but not absolute.

## Where the two halves meet

The reason to care about Orinoco is that in Node a stop-the-world GC pause lands on the event loop. Callbacks queued on *that isolate's* loop wait behind it, exactly as they would behind a synchronous `JSON.parse` of something enormous. Other worker isolates and other processes keep running, and concurrent marking is not itself a pause. Still, the list of things that block your loop is not just your own slow code; it includes the collector.

Which also explains why the process-per-core shape is more than a throughput trick. N processes means N independent heaps, each collected on its own schedule, so one process pausing to collect does not stall the others. Worker threads give you the same separation of heaps inside a single process, at the cost of sharing that process's fate.

One closing warning. The phase order is the detail most likely to be stale in your head, because the diagram everyone memorised outlived the implementation by several major versions. Widely repeated diagrams drift, and so do assumptions about which sources have caught up. Reading `uv_run()` settles it in about a minute.
