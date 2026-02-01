---
title: "RxJava: Windowing"
layout: post
date: 2019-03-19 13:27
description: Explore RxJava window operator to batch emissions into separate Observables. Learn fixed-size and time-based windowing for reactive stream processing.
tag:
- ReactiveX
- RxJava
- Java
- Kotlin
blog: true
hidden: true
jemoji:
---

The `window()` operator is almost identical to `buffer()`, except that it buffers into other _Observables_ rather than _collections_. This results in an `Observable<Observable<T>>` that emits Observables.
Yielded Observables can be transformed using operators like `flatMap()`, `concatMap()`, or `switchMap()`. 

### Fixed-size
The simplest overload for `window()` accepts a _count_ argument:
```kotlin
fun main() {
    Observable.range(1, 50)
        .window(8)
        .flatMapSingle { it.reduce("") { total, next -> "$total $next" } }
        .subscribe { println("Received: $it") }
}
```
```
Received:  1 2 3 4 5 6 7 8
Received:  9 10 11 12 13 14 15 16
Received:  17 18 19 20 21 22 23 24
Received:  25 26 27 28 29 30 31 32
Received:  33 34 35 36 37 38 39 40
Received:  41 42 43 44 45 46 47 48
Received:  49 50
```

Just like `buffer()`, It’s possible to provide a _skip_ argument:
```kotlin
fun main() {
    Observable.range(1, 50)
        .window(8, 12) // 2nd argument is skip
        .flatMapSingle { it.reduce("") { total, next -> "$total $next" } }
        .subscribe { println("Received: $it") }
}
```
```
Received:  1 2 3 4 5 6 7 8
Received:  13 14 15 16 17 18 19 20
Received:  25 26 27 28 29 30 31 32
Received:  37 38 39 40 41 42 43 44
Received:  49 50
```

### Time-based
It is possible to _cut-off_ windowed Observables _at time intervals_ :
```kotlin
fun main() {
    Observable.interval(300, TimeUnit.MILLISECONDS)
        .map { (it + 1) * 300 } // map to elapsed time
        .window(1, TimeUnit.SECONDS)
        .flatMapSingle { it.reduce("") { total, next -> "$total $next" } }
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(4)
}
```
```
Received:  300 600 900
Received:  1200 1500 1800
Received:  2100 2400 2700
Received:  3000 3300 3600 3900
```
It is also possible to specify `count` and `timeshift` arguments just like `buffer()` operator.
