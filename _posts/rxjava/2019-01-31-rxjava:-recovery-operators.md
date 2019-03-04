---
title: "RxJava: Recovery Operators"
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

Sometimes,  intercepting exceptions before they get to the `Observer` and attempt some form of recovery is wanted. It’s not always possible to suppress the error and expect emissions to resume, but it’s possible to attempt re-subscribing or switch to an alternate source `Observable`.

Let’s take the following example:
```kotlin
fun main() {
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> 10 / i }
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )
}
```
```
Received: 2
Received: 10
Received: 3
Error: java.lang.ArithmeticException: / by zero
```
Let’s try some recovering:

## onErrorReturnItem()
Resorting to a default value when an exception occurs may be an option using `onErrorReturnItem()`:
```kotlin
fun main() {
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> 10 / i }
        .onErrorReturnItem(-1)
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )
}
```
```
Received: 2
Received: 10
Received: 3
Received: -1
```
Note that there is _no more emission_ s after the error, the sequence is terminated!

## onErrorReturn()
On error, the operator `onErrorReturn()` allow to return a value dynamically using a given function:
```kotlin
fun main() {
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> 10 / i }
        .onErrorReturn { e -> e.hashCode() }
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )
}
```
```
Received: 2
Received: 10
Received: 3
Received: 1617791695
```

Just like `onErrorReturnItem()`, `onErrorReturn()` will terminate the sequence when an error occurs.
A way to keep the sequence alive is by handling the error in the `map()` operator:
```kotlin
fun main() {
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> try { 10 / i } catch (e: Exception) { -1 } }
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )
}
```
```
Received: 2
Received: 10
Received: 3
Received: -1
Received: 2
Received: 3
Received: 1
```

## OnErrorResumeNext()
This operator accepts an `Observable` as a parameter to emit potentially multiple values on error:

```kotlin
fun main() {
    val altObservable = Observable.just(-1).repeat(3)
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> 10 / i }
        .onErrorResumeNext(altObservable)
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )
}
```
```
Received: 2
Received: 10
Received: 3
Received: -1
Received: -1
Received: -1
```

This operator can be used too to end gracefully emissions on error using `Observable.empty()`:
```kotlin
fun main() {
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> 10 / i }
        .onErrorResumeNext(Observable.empty())
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )
}
```
```
Received: 2
Received: 10
Received: 3
```

It’s possible too to provide a function to dynamically handle errors like the previous operators.

## retry()
It’s possible to use the operator `retry()` to attempt recovery from an error.   
A simple case is calling this operator without arguments. It will re-subscribe to the preceding Observable **infinitely** until no error occurs :
```kotlin
fun main() {
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> 10 / i }
        .retry()
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )
}
```
```
Received: 2
Received: 10
Received: 3
Received: 2
Received: 10
Received: 3
...
```

Passing a `Long`  as argument to the `retry()` _fixes_ the number of retries before it gives up and just emits the error to the `Observer`.

Providing a `Predicate<Throwable>` or `BiPredicate<Integer,Throwable>` conditionally controls when `retry()` is attempted:
```kotlin
fun main() {
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> 10 / i }
        .retry (1) { e -> e is ArithmeticException }
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )
}
```
```
Received: 2
Received: 10
Received: 3
Received: 2
Received: 10
Received: 3
Error: java.lang.ArithmeticException: / by zero
```

## retryUntil()
The `retryUntil()` operator will _allow retries_ **until** a given `BooleanSupplier` lambda is _true_:
```kotlin
fun main() {
    var j = 0
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> 10 / i }
        .retryUntil { j += 1; j == 2 }
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )
}
```
```
Received: 2
Received: 10
Received: 3
Received: 2
Received: 10
Received: 3
Error: java.lang.ArithmeticException: / by zero
```

## retryWhen()
The `retryWhen()` operator supports advanced composition for tasks such as delaying retries:
```kotlin
fun main() {
    Observable.just(4, 1, 3, 0, 5, 3, 9)
        .map { i -> 10 / i }
        .retryWhen { Observable.timer(3, TimeUnit.SECONDS) }
        .subscribe(
            { println("Received: $it") },
            { println("Error: $it") }
        )

    TimeUnit.SECONDS.sleep(5)
}
```
```
Received: 2
Received: 10
Received: 3
Received: 2
Received: 10
Received: 3
```
