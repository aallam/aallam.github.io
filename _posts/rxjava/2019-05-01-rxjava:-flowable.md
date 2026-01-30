---
title: "RxJava: Flowable"
layout: post
date: 2019-05-01 14:18
description:
tag:
- ReactiveX
- RxJava
- Java
- Kotlin
blog: true
hidden: true
jemoji:
---

The `Flowable` is a variant of the `Observable` with backpressure capabilities, that tells the source to emit at a pace specified by the downstream operations.
Replace `Observable.range()` with `Flowable.range()`:
```kotlin
fun main() {
    Flowable.range(1, 999_999_999)
        .map(::Item)
        .observeOn(Schedulers.io())
        .subscribe {
            TimeUnit.MILLISECONDS.sleep(50)
            println("Received item ${it.id}")
        }

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
```
Constructing Item 1
Constructing Item 2
...
Constructing Item 127
Constructing Item 128
Received item 1
Received item 2
...
Received item 95
Received item 96
Constructing Item 129
Constructing Item 130
...
Constructing Item 223
Constructing Item 224
Received item 97
Received item 98
...
```
Some parts of the output are omitted, but the behavior is clear: **128** emissions were immediately pushed from `Flowable.range()`. After that, `observeOn()` pushed **96** of them downstream to `Subscriber` (yes, not an _Observer_, but a _Subscriber_).
This behavior of not having more than a certain number of emissions in the pipeline at any given time is what’s called: **backpressure**.

## Flowables, when?
The benefits offered from the `Flowable`: leaner usage of memory and preventing `MissingBackpressureException`. The disadvantage is that it adds overhead and may not perform as fast as an `Observable`.
When to use `Flowable`?
1. When dealing with over 10,000 elements and there is the opportunity for the source to generate emissions in a regulated manner.
2. When the goal is to emit from IO operations that support blocking while returning results. For example from data sources that iterate records (file lines, JDBC’s `ResultSet`s…), or network and streaming APIs that can request a certain amount of returned results.
3. It might be better to use `Flowables` when the stream isn't synchronous, like when zipping and combining different streams on different threads, parallelize, or use operators such as `observeOn()`, `interval()`, and `delay()`.

_Note: in RxJava 1.0, the Observable had backpressure support and was what the Flowable is in RxJava 2.0._

### BackpressureException
`Flowable` has factories  like: `Flowable.range()`,`Flowable.just()`,`Flowable.fromIterable()`, and `Flowable.interval() `. Most of these implement backpressure, and usage is the same as the `Observable` equivalent.
Let’s consider `Flowable.interval()`, which pushes time-based emissions at fixed time intervals. This can’t be logically backpressured because slowing down the `Flowable.interval()` emissions would not reflect time intervals and become misleading. For that reason, `Flowable.interval()` is one of those cases that can throw `MissingBackpressureException` the moment downstream requests backpressure:
```kotlin
fun main() {
    Flowable.interval(1, TimeUnit.MILLISECONDS)
        .observeOn(Schedulers.io())
        .map { intenseCalculation(it) }
        .subscribe({ i -> println("Received item $i") }, Throwable::printStackTrace)

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
```
Received item 0
io.reactivex.exceptions.MissingBackpressureException: Can't deliver value 128 due to lack of requests
...
```
A solution for this issue is to use operators such as `onBackpressureDrop()` or `onBackpressureBuffer()`.

## Creating a Flowable
Leveraging `Flowable.create()` to create a `Flowable` feels much like `Observable.create()`, but there is one critical difference: `BackpressureStrategy` as a second argument. This enumerable simply supports backpressure by not implementing it, caching or dropping emissions.
```kotlin
fun main() {
    val source = Flowable.create<Int>({ emitter ->
        for (i in 0..1_000) {
            if (emitter.isCancelled) return@create
            emitter.onNext(i)
        }
    }, BackpressureStrategy.BUFFER)

    source.observeOn(Schedulers.io())
        .subscribe { println("Received item $it") }

    TimeUnit.SECONDS.sleep(1)
}
```
In the earlier example,  `Flowable.create()` used to create a `Flowable`, with `BackpressureStrategy.BUFFER` as the second argument to buffer the emissions before they're backpressured.

The following  are the possible `BackpressureStrategy` options:
* `MISSING`: no backpressure implementation at all.
* `ERROR`: throws a `MissingBackpressureException` the moment the downstream can't keep up with the source.
* `BUFFER`: queues up emissions in an unbounded queue until the downstream can consume them, but can cause an `OutOfMemoryError` if the queue gets too large.
* `DROP`: ignores upstream emissions and doesn't queue anything while the downstream is busy.
* `LATEST`: keeps the latest emission until the downstream is ready to receive it.

## Backpressure Operators
A `Flowable` that has no backpressure implementation (including ones derived from Observable), `BackpressureStrategy` is applied using `onBackpressureXXX()` operators. These also offer extra configuration options.

### onBackPressureBuffer()
The `onBackPressureBuffer()` takes an existing `Flowable` that is assumed to not have backpressure implemented and apply `BackpressureStrategy.BUFFER` at that point to the downstream:
```kotlin
fun main() {
    Flowable.interval(1, TimeUnit.MILLISECONDS)
        .onBackpressureBuffer()
        .observeOn(Schedulers.io())
        .subscribe {
            TimeUnit.MILLISECONDS.sleep(5)
            println("Received item $it")
        }

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
```
Received item 0
Received item 1
Received item 2
Received item 3
Received item 4
...
```
`onBackPressureBuffer()` can accept arguments, the more common ones are:
* `capacity`: create a threshold for the buffer.
* `onOverflow`: a lambda to be fire an action when an overflow exceeds the capacity.
* `BackpressureOverflowStrategy`: enum to instruct how to handle an overflow that exceeds the capacity (`ERROR`, `DROP_OLDEST` or `DROP_LATEST`).

```kotlin
fun main() {
    Flowable.interval(1, TimeUnit.MILLISECONDS)
        .onBackpressureBuffer(10, { println("Overflow!") }, BackpressureOverflowStrategy.DROP_LATEST)
        .observeOn(Schedulers.io())
        .subscribe {
            TimeUnit.MILLISECONDS.sleep(5)
            println("Received item $it")
        }

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
```
...
Received item 22
Received item 23
Overflow!
Overflow!
Overflow!
Overflow!
Received item 24
Overflow!
Overflow!
Overflow!
Overflow!
Overflow!
Overflow!
Received item 25
Overflow!
Overflow!
...
```

### onBackPressureLatest()
The operator `onBackPressureLatest()` retains the latest value from the source while the downstream is busy, and until the downstream is free to process more. Any previous values emitted during this busy period are lost:
```kotlin
fun main() {
    Flowable.interval(1, TimeUnit.MILLISECONDS)
        .onBackpressureLatest()
        .observeOn(Schedulers.io())
        .subscribe {
            TimeUnit.MILLISECONDS.sleep(5)
            println("Received item $it")
        }

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
```
...
Received item 125
Received item 126
Received item 127
Received item 566
Received item 567
...
```

### `onBackPressureDrop()`
The `onBackpressureDrop()` operator discards emissions if the downstream is too busy to process them. The operator can accept an `onDrop` lambda argument specifying the action to do with each dropped item.
```kotlin
fun main() {
    Flowable.interval(1, TimeUnit.MILLISECONDS)
        .onBackpressureDrop{ println("Drop: $it")}
        .observeOn(Schedulers.io())
        .subscribe {
            TimeUnit.MILLISECONDS.sleep(5)
            println("Received item $it")
        }

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
```
...
Received item 19
Received item 20
Drop: 128
Received item 21
Drop: 129
Drop: 130
...
```

## Flowable.generate()
Most of `Flowable`’s standard factories and operators automatically handle backpressure. However, in the case of custom sources, `Flowable.create()` or the `onBackPressureXXX()` operators are somewhat compromised in how they handle backpressure requests, caching emissions, or simply dropping them is not always desirable. `Flowable.generate()` exists to help create backpressure, respecting sources at a nicely abstracted level.
```kotlin
fun main() {
    Flowable.generate<Int> { emitter -> emitter.onNext(Random.nextInt(1, 1_000)) }
        .subscribeOn(Schedulers.computation())
        .doOnNext { println("Emitting $it") }
        .observeOn(Schedulers.io())
        .subscribe {
            TimeUnit.MILLISECONDS.sleep(5)
            println("Received item $it")
        }

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
```
Emitting 577
Emitting 597
...
Emitting 235
Emitting 70
Received item 577
Received item 597
...
```
_Note_: invoking multiple `onNext()` operators within `Consumer<Emitter<T>>` results in `IllegalStateException`.

It's possible to provide a state that can act somewhat like a “seed” and maintain passed state from one emission to the next:
```kotlin
fun main() {
    Flowable.generate<Int, AtomicInteger>(
        Callable<AtomicInteger> { AtomicInteger(1) },
        BiConsumer<AtomicInteger, Emitter<Int>> { state, emitter -> emitter.onNext(state.getAndIncrement()) }
    )
        .subscribeOn(Schedulers.computation())
        .doOnNext { println("Emitting $it") }
        .observeOn(Schedulers.io())
        .subscribe {
            TimeUnit.MILLISECONDS.sleep(5)
            println("Received item $it")
        }
    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```

It's also possible to provide a third `Consumer<? super S>` _disposeState_ argument to do any disposal operations on termination.

`Flowable.generator()` provides an abstracted mechanism to create a source that respects backpressure, which makes it preferable over `Flowable.create()` to avoid caching or dropping emissions. 
