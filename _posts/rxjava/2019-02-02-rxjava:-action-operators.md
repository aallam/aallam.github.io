---
title: "RxJava: Action Operators"
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

Action operators _(doOn)_ are helpful operators that can assist in debugging and getting visibility into an `Observable` chain.

## doOnNext()
The `doOnNext()` operator allow to peek at each emission coming out of an operator and going into the next:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta")
        .doOnNext { s -> println("Processing: $s") }
        .map { s -> s.length}
        .subscribe { i -> println("Received: $i") }
}
```
```
Processing: Alpha
Received: 5
Processing: Beta
Received: 4
Processing: Gamma
Received: 5
Processing: Delta
Received: 5
```
It also possible to leverage `doAfterNext()` which performs the action _after_ the emission is passed downstream rather than before. 

## doOnComplete()
The `doOnComplete()` operator fires off an action when `onComplete()` is called at the point in the `Observable` chain: 
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta")
        .doOnComplete { println("Done emitting") }
        .map { s -> s.length }
        .subscribe { i -> println("Received: $i") }
}
```
```
Received: 5
Received: 4
Received: 5
Received: 5
Done emitting
```

## doOnError()
The `doOnError()` peeks at the error being emitted up the chain. This is helpful to put between operators to see which one causes an error: 
```kotlin
fun main() {
    Observable.just(5, 2, 4, 0, 3, 2, 8)
        .doOnError { println("Source failed!") }
        .map { i -> 10 / i }
        .doOnError { println("Division failed!") }
        .subscribe(
            { i -> println("Received: $i") },
            { e -> println("Error: $e") }
        )
}
```
```
Received: 2
Received: 5
Received: 2
Division failed!
Error: java.lang.ArithmeticException: / by zero
```

## doOnEach() and doOnTerminate()
* `doOnEach()`: Useful to to specify an observer in the middle of the chain to peek at all emissions.
* `doOnTerminate()`: fires for an `onComplete()` or `onError()` event.
 
## doOnSubscribe()
At a _specific point_ in an `Observable` chain, `doOnSubscribe()` fires a specific `Disposable` the moment a subscription occurs: 
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma")
        .map { it.length }
        .doOnSubscribe { println("Subscribed: $it") }
        .subscribe { println("Received: $it") }
}
```
```
Subscribed: io.reactivex.internal.operators.observable.ObservableFromArray$FromArrayDisposable@53bd815b
Received: 5
Received: 4
Received: 5
```

## doOnDispose()
At a _specific point_ in an `Observable` chain, `doOnDispose()` will perform a specific action when disposal is executed:
```kotlin
fun main() {
    var disposable: Disposable? = null
    Observable.just("Alpha", "Beta", "Gamma")
        .doAfterNext { disposable?.dispose() }
        .doOnDispose { println("Disposing!") }
        .doOnSubscribe { disposable = it }
        .subscribe { println("Received: $it") }
}
```
```
Received: Alpha
Disposing!
```
`doOnDispose()` can fire _multiple times_ for multiple disposal requests _or not at all_ if it is not disposed. 

## doFinally
This operator will fire after either onComplete() , onError() or disposing: ``
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma")
        .doFinally { println("Done !") }
        .subscribe { println("Received: $it") }
}
```
```
Received: Alpha
Received: Beta
Received: Gamma
Done !
```

## doOnSuccess()
The operator `onSuccess()` exists because of types like `Single` and `Maybe`  which do have  `onSuccess ` instead of `onNext`:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma")
        .firstElement()
        .doOnSuccess { println("Success !")  }
        .subscribe { println("Received: $it") }
}
```
```
Success !
Received: Alpha
```
