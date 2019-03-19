---
title: "RxJava: Throttling"
layout: post
date: 2019-03-19 13:27
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

Unlike `buffer()` and `window()` operators, `throttle()` is an operator that omits emissions when they occur rapidly. 
This is helpful when rapid emissions are considered _redundant_ or _unwanted_ (such as a user clicking on a button repeatedly). 

There is multiple throttling operators: `throttleLast()`,  `throttleFirst()`, `throttleWithTimeout()`. To understand them, lets start with the following case:
```kotlin
fun main() {
    val source1 = Observable.interval(100, TimeUnit.MILLISECONDS)
        .map { (it + 1) * 100 } // map to elapsed time
        .map { "Source 1: $it" }
        .take(10)

    val source2 = Observable.interval(300, TimeUnit.MILLISECONDS)
        .map { (it + 1) * 300 } // map to elapsed time
        .map { "Source 2: $it" }
        .take(3)

    val source3 = Observable.interval(2000, TimeUnit.MILLISECONDS)
        .map { (it + 1) * 2000 } // map to elapsed time
        .map { "Source 3: $it" }
        .take(2)

    Observable.concat(source1, source2, source3)
        .subscribe { println(it) }

    TimeUnit.SECONDS.sleep(6)
} 
```
Lets concatenate 3 sources _(source1, source2 and source3)_, with different intervals _(100, 300 and 2000)_, and we take a fixed number of emissions for each one _(10, 3 and 2)_.
The output is as follows:
```
Source 1: 100
Source 1: 200
Source 1: 300
Source 1: 400
Source 1: 500
Source 1: 600
Source 1: 700
Source 1: 800
Source 1: 900
Source 1: 1000
Source 2: 300
Source 2: 600
Source 2: 900
Source 3: 2000
Source 3: 4000
```

### Operator: throttleLast() / sample()
The `throttleLast()` operator (aliased as `sample()`) will only emit the last item at a fixed time interval:
```kotlin
Observable.concat(source1, source2, source3)
    .throttleLast(1, TimeUnit.SECONDS)
    .subscribe {println(it) }
```
```
Source 1: 900
Source 2: 900
Source 3: 2000
```

### Operator: throttleFirst()
`throttleFirst` emits the _first_ item that occurs at every fixed time interval:
```kotlin
    Observable.concat(source1, source2, source3)
        .throttleFirst(1, TimeUnit.SECONDS)
        .subscribe { println(it) }
```
```
Source 1: 100
Source 2: 300
Source 3: 2000
Source 3: 4000
```

/Note: `throttleFirst()` and `throttleLast()`  both emit on the computation `Scheduler`, however, it’s possible to specify another `Scheduler` as a third argument./ 

### Operator: throttleWithTimeout()
While emissions are firing rapidly, `throttleWithTimeout()`  (aliased to `debounce()`) will not emit anything until there is a _period of inactivity_, and then it will push the last emission forward.
This operator takes time interval arguments that specify how long a period of inactivity must be:
```kotlin
    Observable.concat(source1, source2, source3)
        .throttleWithTimeout(1, TimeUnit.SECONDS)
        .subscribe { println(it) }
```
```
Source 2: 900
Source 3: 2000
Source 3: 4000
```
The `throttleWithTimeout()` is an effective way to handle excessive inputs, noisy,  and redundant events that sporadically speed up, slow down, or cease. However, it will delay each winning emission.
