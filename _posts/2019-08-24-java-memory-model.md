---
title: "Java Memory Model"
layout: post
date: 2019-08-24 14:42
description: "Deep dive into Java Memory Model covering sequential consistency, happens-before relationships, volatile, synchronized, and concurrency optimization patterns."
image: /assets/images/blog/cart-observing-wrong.png
tag:
- Java
- JVM
blog: true
jemoji:
---

<div class="text-center" markdown="1">
![Java][0]{:width="50%"}
</div>

## The problem

A **data race** occurs when two conflicting accesses to one variable lack a happens-before ordering. At least one access writes the variable. A program with a data race can observe values that surprise a reader who expects one shared execution order.

The [Java 8 memory model](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html) defines which values a read may see. It describes language guarantees, independent of a particular processor cache or JIT compiler.

### Sequential consistency

Within one thread, execution must preserve the behavior that Java assigns to that thread. Across threads, a correctly synchronized program appears sequentially consistent. A racy program does not receive that guarantee.

For example, these ordinary fields have no ordering between a writer and reader:

```java
class Reorder {
    int foo;
    int bar;

    void write() {
        foo = 1;
        bar = 1;
    }

    int read() {
        return bar == 1 ? foo : 0;
    }
}
```

A reader can observe `bar == 1` without a guarantee that it sees `foo == 1`. The memory model permits this result because neither access establishes a happens-before edge. Do not interpret the example as a claim about a specific cache operation.

### 1.3 Atomicity

Most single variable reads and writes are atomic. Under Java 8, a non-`volatile` `long` or `double` access may be treated as two 32-bit accesses. A `volatile` access to either type is atomic.

```java
class LongTearing {
    long value;

    void writeLowBits() {
        value = 0x00000000FFFFFFFFL;
    }

    void writeHighBits() {
        value = 0xFFFFFFFF00000000L;
    }
}
```

If writes tear, a racing read could combine the upper half from one write with the lower half from the other. Possible mixed values include `0x0000000000000000L` and `0xFFFFFFFFFFFFFFFFL`. A particular JVM need not produce either value. This example explains a permitted behavior, not a reliable experiment.

## What is the Java memory model?

The model covers **visibility**, **ordering**, and **atomicity**. Visibility asks which write a read may observe. Ordering relates actions across threads. Atomicity asks whether one access can be observed in pieces.

A happens-before relation joins program order with synchronization rules. If a write happens-before a read of the same field, that ordering constrains which values the read can observe. Happens-before does not require an immediate hardware cache flush.

### Building blocks

Program order connects earlier actions to later actions within one thread. Synchronization adds edges across threads, including volatile write-to-read, monitor unlock-to-lock, thread start, and successful thread join. Happens-before is transitive: if A precedes B and B precedes C, A precedes C.

### Volatile

A write to a `volatile` field happens-before each subsequent read of that field in synchronization order. Ordinary writes before the volatile write become visible to a reader after that read.

```java
class PublishedAnswer {
    int answer;
    volatile boolean ready;

    void publish() {
        answer = 42;
        ready = true;
    }

    int read() {
        if (!ready) return -1;
        return answer; // 42 if this read observed publish()
    }
}
```

A reader can see `ready == false` before publication. If it reads the published `true`, it must also see the earlier `answer = 42`, assuming no other writes race with `answer`. `volatile` does not make compound operations such as `count++` atomic.

<div class="text-center" markdown="1">
![Volatile Synchronization][2]
<figcaption class="caption">The write to the volatile flag publishes earlier writes to a reader that observes the flag.</figcaption>
</div>

### Synchronized

A monitor unlock happens-before each later lock of the same monitor. Both methods below use the object's monitor. Each method releases that monitor when it returns.

```java
class MonitorAnswer {
    private boolean ready;
    private int answer;

    synchronized void publish() {
        answer = 42;
        ready = true;
    }

    synchronized int read() {
        return ready ? answer : -1;
    }
}
```

If `read()` acquires the monitor before `publish()`, it returns `-1`. If `publish()` completes first, `read()` returns `42`. The lock protects the check and the value together. A loop that holds this lock while waiting for `ready` would prevent `publish()` from acquiring it.

### Thread life-cycle semantics

Actions before a call to `Thread.start()` happen-before actions in the started thread. Actions in a thread happen-before another thread successfully returns from `join()` on it.

```java
class ThreadLifeCycle {
    int value;

    void runExample() throws InterruptedException {
        value = 42;
        Thread worker = new Thread(() -> {
            if (value != 42) throw new AssertionError();
            value = 43;
        });
        worker.start();
        worker.join();
        if (value != 43) throw new AssertionError();
    }
}
```

The start edge publishes `42` to the worker. The successful join edge publishes the worker's `43` to the caller.

<div class="text-center" markdown="1">
![Thread Life-cycle][4]
<figcaption class="caption">Actions before start reach the worker. Worker actions reach a thread after successful join.</figcaption>
</div>

### Final field semantics

A correctly constructed object has special guarantees for its `final` fields. Its reference may be shared without ordinary synchronization, but the object must not escape during construction.

```java
class Settings {
    final int limit;

    Settings(int limit) {
        this.limit = limit;
    }
}

class Holder {
    static Settings shared;

    static void publish() {
        shared = new Settings(42);
    }
}
```

A thread that obtains the `Settings` reference sees `limit == 42`, provided the constructor did not let `this` escape. This guarantee does not ensure that another thread discovers the new `shared` reference. It also does not make later changes to other fields visible. Use synchronization or `volatile` when discovery or later updates matter.

## In Practice

### Double-checking

Double-checked locking needs a `volatile` reference and a second check while holding the lock:

```java
class DoubleChecked {
    private static volatile DoubleChecked instance;
    final int value;

    private DoubleChecked() {
        value = 42;
    }

    static DoubleChecked getInstance() {
        DoubleChecked result = instance;
        if (result == null) {
            synchronized (DoubleChecked.class) {
                result = instance;
                if (result == null) {
                    result = new DoubleChecked();
                    instance = result;
                }
            }
        }
        return result;
    }
}
```

The volatile publication makes constructor writes visible to readers that obtain the instance. The inner check prevents two creators from publishing separate instances. Without `volatile`, the unsynchronized first read has no publication guarantee.

### Arrays

A `volatile` array field makes reads and writes of the **array reference** volatile. It does not make element accesses volatile.

```java
class ArrayReference {
    volatile boolean[] ready = {false};

    void publish() {
        ready = new boolean[] {true}; // volatile reference write
    }

    boolean read() {
        return ready[0]; // volatile reference read, then ordinary element read
    }
}
```

A reader that observes the new reference also sees its initialized element. Mutating `ready[0]` later does not create another volatile edge. For coordinated element updates, use a suitable atomic array such as `AtomicIntegerArray`, or use a lock.

## Sources

* [Java 8 JLS, Chapter 17: Threads and Locks](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html)
* [Java 8 JLS, happens-before order](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html#jls-17.4.5)
* [Java 8 JLS, final field semantics](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html#jls-17.5)

[0]: {{ site.url }}/assets/images/blog/cart-observing-wrong.png
[2]: {{ site.url }}/assets/images/blog/volatile_sync.png
[4]: {{ site.url }}/assets/images/blog/thread_lifecycle.png
