---
title: "RxJava: Reducing Operators"
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

Sometimes, it’s useful to take a series of emissions and consolidate them into a single emission (usually `Single`).  
Nearly all of reducing operators only work on a _finite_ `Observable` (that calls `onComplete()`).

## count()
This operator will _count_ the number of emissions and emit through a `Single` once `onComplete()` is called:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .count()
        .subscribe { s -> println("Received: $s") }
}
```
```
Received: 5
```

## reduce()
The `reduce()` operator is syntactically identical to `scan()`, but it only emits _the final accumulation_ when the source calls `onComplete()`:
```kotlin
fun main() {
    Observable.just(1, 1, 2, 3, 5)
        .reduce { total, next -> total + next }
        .subscribe { println("Received: $it") }
}
```
```
Received: 12
```
It's possible to pass a _seed_ argument that will serve as the _initial_ value to accumulate on. The seed value should be immutable (`collect()` or `seedWith()`  should be used for mutables).

## all()
This operator verifies that each emission qualifies with a specified condition and return a `Single<Boolean>`: 
```kotlin
fun main() {
    Observable.just(1, 5, 12, 7, 3)
        .all { it < 10 }
        .subscribe { b -> println("Received: $b") }
}
```
```
Received: false
```
Calling `all()` on an _empty_ `Observable`, will emit `true` due to the principle of [vacuous truth][1]. 

## any()
This operator will check whether _at least one emission meets a specific criterion_ and return a `Single<Boolean>`:
```kotlin
fun main() {
    Observable.just(1, 5, 12, 7, 3)
        .any { it > 10 }
        .subscribe { b -> println("Received: $b") }
}
```
```
Received: true
```
Calling `any()` on an _empty_ `Observable`, will emit `false` due to the principle of [vacuous truth][1]. 

## contains()
This operator will check whether a specific element is ever emitted from an `Observable` (based on the `hashCode()`/`equals()` implementation) : 
```kotlin
fun main() {
    Observable.just(1, 5, 12, 7, 3)
        .contains(12)
        .subscribe { b -> println("Received: $b") }
}
```
```
Received: true
```


[1]: https://en.wikipedia.org/wiki/Vacuous_truth