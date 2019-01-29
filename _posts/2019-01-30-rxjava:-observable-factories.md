---
title: "RxJava: (More) Observable Factories"
layout: post
date: 2019-01-29 23:47
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

There the classic factories: `Observable.create()`, `Observable.just()` and `Observable.fromIterable()`.  
Let's see more:

## Observable.range
Emits a consecutive range of integers:
```kotlin
fun main() {
    Observable.range(1, 5).subscribe { println("Received: $it") }
}
```
```
Received: 1
Received: 2
Received: 3
Received: 4
Received: 5
```
The _first_ argument is the _start_ value, the _second_ argument is the _total count_ of the values to emit.  
Another variant of the same factory: `Observable.rangeLong()`.

## Observable.interval()
Emits a consecutive long emission (starting at 0) at every specified time interval:
```kotlin
fun main() {
    Observable.interval(1, TimeUnit.SECONDS).subscribe { s -> println(s!!.toString() + " Mississippi") }
    TimeUnit.SECONDS.sleep(5)
}
```
```
0 Mississippi
1 Mississippi
2 Mississippi
3 Mississippi
4 Mississippi
```
`Observable.interval()` runs on the _computation Scheduler_ by default, and it is a **cold** `Observable` (each observable will get its own emissions, starting at 0). But it’s always possible to make it **hot** using `publish()` and `connect()`

## Observable.future()
Its possible to use Java `Future` and turn them to `Observable`:
```kotlin
fun main() {
    val future: Future<String> = CompletableFuture.completedFuture("Alpha")
    Observable.fromFuture(future)
        .map { it.length }
        .subscribe { println(it) }
}
```

## Observable.empty()
It is sometimes helpful to create an Observable that emits nothing and calls `onComplete()`:
```kotlin
fun main() {
    Observable.empty<String>().subscribe(
        { println(it) },
        { it.printStackTrace() },
        { println("Done!") }
    )
}
```
```
Done!
```

## Observable.never()
Same as `Observable.empty()` but  _never_ calls `onComplete() `:
```kotlin
fun main() {
    Observable.never<String>().subscribe(
        { println(it) },
        { it.printStackTrace() },
        { println("Done!") }
    )
    TimeUnit.SECONDS.sleep(5)
}
```
This `Observable` is primarily used for testing and not that often in production. 

## Observable.error()
This `Observable` is mainly for testing: it creates an Observable that immediately calls `onError()` with a specified exception:
```kotlin
fun main() {
    Observable.error<String>(Exception("Crash!")).subscribe(
        { println(it) },
        { it.printStackTrace() },
        { println("Done!") }
    )
}
```
The `Exception` creation in `error()` call can be replaced by a lambda so that an `Exception` is created from scratch and provided to each `Observer`.

## Observable.defer()
`Observable.defer()` is able to create a separate state for each `Observer`:
```kotlin
fun main() {
    val start = 0
    var count = 3

    val source = Observable.defer { Observable.range(start, count) }
    source.subscribe { println("Observer 1: $it") }
    //modify count
    count = 5
    source.subscribe { println("Observer 2: $it") }
}
```
The variable `count`  value changes it taken in consideration thanks to `Observable.defer()`, The output:
```
Observer 1: 0
Observer 1: 1
Observer 1: 2
Observer 2: 0
Observer 2: 1
Observer 2: 2
Observer 2: 3
Observer 2: 4
```
`Observable.defer()` is good to capture changes (variables, reuse iterators…).

## Observable.fromCallable()
Perform a calculation or action in a lazy or deferred manner, and in case of an error, emit the `Exception` up the Observable chain through `onError()` instead of throwing the error at that location:
```kotlin
fun main() {
    Observable.fromCallable { 1 / 0 }
        .subscribe(
            { i -> println("Eeceived: " + i!!) },
            { e -> println("Error Captured: $e") }
        )
}
```
```
Error Captured: java.lang.ArithmeticException: / by zero
```
The error was emitted to the `Observer` rather than being thrown where it occurred. 

## Single, Completable, and Maybe
There are a few specialised flavours of `Observable` that are explicitly set up for one or no emissions: `Single`, `Maybe`, and `Completable`. 

### Single
`Single` is essentially an `Observable` that will only emit one item, and has its own `SingleObserver` interface (with `onSuccess` instead of `onNext` and `onComplete`):
```kotlin
fun main() {
    Single.just("Alpha")
        .map { it.length }
        .subscribe { i -> println("Received: $i") }
}
```
```
Received: 5
```

It’s possible to get a `Single` by calling `first()` for example on an `Observable`:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Charlie")
        .first("None") //Create a Single, default: "None"
        .map { it.length }
        .subscribe { i -> println("Received: $i") }
}
```
```
Received: 5
```
It’s possible to get back an `Observable` by using `toObservable()`.

### Maybe
`Maybe` is like a `Single` except it will only emit 0 or 1 emissions, and has its own  `MaybeObserver` (with `onSuccess()` instead of `onNext()`):
```kotlin
fun main() {
    // has emission
    Maybe.just("Alpha")
        .map { it.length }
        .subscribe (
            { println("Maybe1: Received: $it") },
            { it.printStackTrace() },
            { println("Maybe1: Completed")}
        )

    // no emission
    Maybe.empty<String>()
        .map { it.length }
        .subscribe (
            { println("Maybe2: Received: $it") },
            { it.printStackTrace() },
            { println("Maybe2: Completed")}
        )
}
```
```
Maybe1: Received: 5
Maybe2: Completed
```

It’s possible to get a `Maybe`  from an `Observable` by calling `firstElement()` :
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Charlie")
        .firstElement() // Create a Maybe<String>
        .map { it.length }
        .subscribe(
            { println("Maybe1: Received: $it") },
            { it.printStackTrace() },
            { println("Maybe1: Completed") }
        )
}
```

### Completable
`Completable` is to execute an action without receiving any emissions, and has a `CompletableObserver` (with no `onNext()` or `onSuccess()`):
```kotlin
fun main() {
    Completable.fromRunnable { doThings() }
        .subscribe { println("Done!") }
}

fun doThings() {
    // Omitted..
}
```
```
Done!
```
