---
title: "RxJava: Multicasting"
layout: post
date: 2019-02-04 17:36
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

Multicasting is helpful to prevent redundant work being done by multiple Observers, but instead makes all Observers subscribe to a single stream.

Using cold `Observable`, without multicasting:
```kotlin
fun main() {
    val observable = Observable.just("Alpha", "Beta", "Gamma").map *{*(0..1000).random() *}*
observable.subscribe *{*println("Observer 1: $*it*") *}*
observable.subscribe *{*println("Observer 2: $*it*") *}*
}
```
```
Observer 1: 438
Observer 1: 261
Observer 1: 414
Observer 2: 520
Observer 2: 927
Observer 2: 125
```

Using hot `Observable`, with multicasting (`ConnectableObservable`):
```kotlin
fun main() {
    val observable = Observable.just("Alpha", "Beta", "Gamma").map { (0..1000).random() }.publish()
    observable.subscribe { println("Observer 1: $it") }
    observable.subscribe { println("Observer 2: $it") }
    observable.connect()
}
```
```
Observer 1: 591
Observer 2: 591
Observer 1: 447
Observer 2: 447
Observer 1: 706
Observer 2: 706
```

## Automatic connection
There is operators to automatically call connect(), but it is important to have awareness of their subscribe timing behaviours.

### autoConnect()
For a given `ConnectableObservable<T>`, calling `autoConnect()` will return an `Observable<T>` that will automatically call `connect()` after a specified number subscriptions: 
```kotlin
fun main() {
    val observable = Observable.range(1, 3).map { (0..100).random() }.publish().autoConnect(2)
    observable.subscribe { println("Observer 1: $it") }
    observable.reduce { total, next -> total + next }.subscribe { t -> println("Observer 2: $t") }
}
```
```
Observer 1: 42
Observer 1: 35
Observer 1: 25
Observer 2: 102
```
Note: Even when all downstream Observers finish or dispose, `autoConnect()` will _persist its subscription to the source_.

### refCount()
This operator fires after getting _one subscription_, and when it has no Observers anymore, it will _dispose of itself_ and _start over_ when a new one comes in:
```kotlin
fun main() {
    val observable = Observable.interval(1, TimeUnit.SECONDS).publish().refCount()
    observable.take(5).subscribe { println("Observer 1: $it") }
    TimeUnit.SECONDS.sleep(3)
    observable.take(2).subscribe { println("Observer 2: $it") }
    TimeUnit.SECONDS.sleep(3) // should be no more Observers after this.
    observable.subscribe { println("Observer 3: $it") }
    TimeUnit.SECONDS.sleep(3)
}
```
```
Observer 1: 0
Observer 1: 1
Observer 1: 2
Observer 1: 3
Observer 2: 3
Observer 1: 4
Observer 2: 4
Observer 3: 0
Observer 3: 1
Observer 3: 2
```
Note: `share()` is an alias for `publish().refCount()`.
