---
title: "RxJava: Replaying and Caching"
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

Multicasting allows to cache values that are shared across multiple Observers.

## replay()
The `replay()` operator is a powerful way to hold onto previous emissions within a certain scope and re-emit them when a new Observer comes in. 

```kotlin
fun main() {
    val observable = Observable.interval(1, TimeUnit.SECONDS).replay().autoConnect()
    observable.subscribe { println("Observer 1: $it") }
    TimeUnit.SECONDS.sleep(3)
    observable.subscribe { println("Observer 2: $it") }
    TimeUnit.SECONDS.sleep(3)
}
```
```
Observer 1: 0
Observer 1: 1
Observer 1: 2
Observer 2: 0
Observer 2: 1
Observer 2: 2
Observer 1: 3
Observer 2: 3
Observer 1: 4
Observer 2: 4
Observer 1: 5
Observer 2: 5
```
It’s possible to pass a buffer size as argument, or to specify time-based window .

## cache()
When it’s not possible to control observers behaviour, `cache()` can be a solution, it caches all of its events and replays them, however, this operator should be used carefully, because it holds all elements indefinitely: 
```kotlin
fun main() {
    val observable = Observable.just(1, 1, 2, 3, 5, 8, 13)
        .scan(0) { total, next -> total + next }
        .cache()

    observable.subscribe { println("Received: $it") }
}
```
```
Received: 0
Received: 1
Received: 2
Received: 4
Received: 7
Received: 12
Received: 20
Received: 33
```
