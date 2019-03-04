---
title: "RxJava: Observable & Observer"
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

## Observable
There is many factories  to create Observables:
*  `Observable.create`: 
```kotlin
fun main() {
    val source: Observable<String> = Observable.create {
        try {
            it.onNext("Alpha")
            it.onNext("Beta")
            it.onNext("Charlie")
            it.onNext("Delta")
            it.onNext("Epsilon")
            it.onComplete()
        } catch (e: Throwable) {
            it.onError(e)
        }
    }

    source.map { it.length }.filter { it >= 5 }.subscribe(
        { println("Received: $it") },
        { it.printStackTrace() }
    )
}
```
*  `Observable.just` :
```kotlin
fun main() {
    val source: Observable<String> = Observable.just("Alpha", "Beta", "Charlie", "Delta", "Epsilon")

    source.map { it.length }.filter { it >= 5 }.subscribe(
        { println("Received: $it") }, //onNext
        { it.printStackTrace() } //onError
    )
}
```
*  `Observable.fromIterable`:
```kotlin
fun main() {
    val items: List<String> = listOf("Alpha", "Beta", "Charlie", "Delta", "Epsilon")

    val source: Observable<String> = Observable.fromIterable(items)

    source.map { it.length }.filter { it >= 5 }.subscribe(
        { println("Received: $it") }, //onNext
        { it.printStackTrace() } //onError
    )
}
```

## Observer
Each `Observable` returned by an operator (`map`, `filter`…) is internally an `Observer` that receives, transforms, and relays emissions to the next `Observer` downstream., without knowing if the next `Observer` is another operator or the final `Observer`. 

It’s possible to pass an object implementing the `Observer` interface to the `Observable.subscribe` method and override `onNext`, `onError`, and `onComplete`:

```kotlin
fun main() {
    val source: Observable<String> = Observable.just("Alpha", "Beta", "Charlie", "Delta", "Epsilon")

    val observer: Observer<Int> = object : Observer<Int> {
        override fun onComplete() {
            println("Done!")
        }

        override fun onSubscribe(d: Disposable) {
            //No-op at the moment.
        }

        override fun onNext(t: Int) {
            println("Received: $t")
        }

        override fun onError(e: Throwable) {
            e.stackTrace
        }

    }

    source.map { it.length }.filter { it >= 5 }.subscribe(observer)
}
```

Implementing an `Observer` is probably verbose, that’s why `subscribe` function is overloaded to accept lambda arguments for the three events:
```kotlin
ffun main() {
    val source: Observable<String> = Observable.just("Alpha", "Beta", "Charlie", "Delta", "Epsilon")

    val onNext: (Int) -> Unit = { println("Received: $it") }
    val onError: (Throwable) -> Unit = { it.stackTrace }
    val onComplete: () -> Unit = { println("Done!") }

    source.map { it.length }.filter { it >= 5 }.subscribe(onNext, onError, onComplete)
}
```
Or with a more concise version:
```kotlin
fun main() {
    val source: Observable<String> = Observable.just("Alpha", "Beta", "Charlie", "Delta", "Epsilon")

    source.map { it.length }.filter { it >= 5 }.subscribe(
        { println("Received: $it") },
        { it.stackTrace },
        { println("Done!") }
    )
}
```

It is critical to note that most of the `subscribe` overload variants return a `Disposable`. Disposables allow us to disconnect an `Observable` from an `Observer` so emissions are terminated early.
