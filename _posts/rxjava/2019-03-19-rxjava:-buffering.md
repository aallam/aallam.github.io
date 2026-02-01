---
title: "RxJava: Buffering"
layout: post
date: 2019-03-19 13:27
description: Master RxJava buffer operator to batch emissions into collections. Learn fixed-size, time-based, and skip buffering strategies for stream control.
tag:
- ReactiveX
- RxJava
- Java
- Kotlin
blog: true
hidden: true
jemoji:
---

It is common to run into situations where an `Observable` is producing emissions faster than an `Observer` can consume them.  The ideal way to handle this is to leverage backpressure using `Flowable` instead of `Observable`. However, it’s not always possible to do so ! Thankfully, there are some other techniques to achieve this, and one of them: **Buffering** !

## Operator: Buffer()
The `buffer()` operator _will gather_ emissions within a certain scope _and emit_ each batch as a list or another collection type. The scope can be defined by a fixed buffer sizing, timing window or even slices. 

### Fixed-size
The simplest overload for `buffer()` accepts a _count argument_ that batches emissions in that fixed size:
```kotlin
fun main() {
    Observable.range(1, 50)
        .buffer(8)
        .subscribe { println("Received: $it") }
}
```
```
Received: [1, 2, 3, 4, 5, 6, 7, 8]
Received: [9, 10, 11, 12, 13, 14, 15, 16]
Received: [17, 18, 19, 20, 21, 22, 23, 24]
Received: [25, 26, 27, 28, 29, 30, 31, 32]
Received: [33, 34, 35, 36, 37, 38, 39, 40]
Received: [41, 42, 43, 44, 45, 46, 47, 48]
Received: [49, 50]
```
It’s possible to pass a second argument ( `bufferSupplier`) to `buffer()`  to put the items in another collection besides a list:
```kotlin
fun main() {
    Observable.range(1, 50)
        .buffer(8) { HashSet<Int>() }
        .subscribe { println("Received: $it") }
}
```
```
Received: [1, 2, 3, 4, 5, 6, 7, 8]
Received: [16, 9, 10, 11, 12, 13, 14, 15]
Received: [17, 18, 19, 20, 21, 22, 23, 24]
Received: [32, 25, 26, 27, 28, 29, 30, 31]
Received: [33, 34, 35, 36, 37, 38, 39, 40]
Received: [48, 41, 42, 43, 44, 45, 46, 47]
Received: [49, 50]
```
It’s also possible to pass a `skip` argument that specifies how many items should be skipped before starting a new buffer.  
If `skip` is equal to `count`, the `skip` has no effect. However, if they are different, you can get some interesting behaviours. 
* If `skip ` is superior to `count ` , the absolute difference between them is the number of elements to not be buffered each time:  
```kotlin
fun main() {
    Observable.range(1, 50)
        .buffer(8, 12) //count=8 and skip=12
        .subscribe { println("Received: $it") }
}
```
```
Received: [1, 2, 3, 4, 5, 6, 7, 8]
Received: [13, 14, 15, 16, 17, 18, 19, 20]
Received: [25, 26, 27, 28, 29, 30, 31, 32]
Received: [37, 38, 39, 40, 41, 42, 43, 44]
Received: [49, 50]
```
* If  `skip` is inferior to `count`, the absolute difference between them is the number of element to be re-emitted:
```kotlin
 fun main() {
    Observable.range(1, 50)
        .buffer(8, 4) //count=8 and skip=4
        .subscribe { println("Received: $it") }
}
```
```
Received: [1, 2, 3, 4, 5, 6, 7, 8]
Received: [5, 6, 7, 8, 9, 10, 11, 12]
Received: [9, 10, 11, 12, 13, 14, 15, 16]
Received: [13, 14, 15, 16, 17, 18, 19, 20]
Received: [17, 18, 19, 20, 21, 22, 23, 24]
Received: [21, 22, 23, 24, 25, 26, 27, 28]
Received: [25, 26, 27, 28, 29, 30, 31, 32]
Received: [29, 30, 31, 32, 33, 34, 35, 36]
Received: [33, 34, 35, 36, 37, 38, 39, 40]
Received: [37, 38, 39, 40, 41, 42, 43, 44]
Received: [41, 42, 43, 44, 45, 46, 47, 48]
Received: [45, 46, 47, 48, 49, 50]
Received: [49, 50]
```

### Time-based buffering
It is also possible to use `buffer()` at fixed time intervals by providing a `long` and `TimeUnit` :
```kotlin
fun main() {
    Observable.interval(300, TimeUnit.MILLISECONDS)
        .map { (it + 1) * 300 } // map to elapsed time
        .buffer(1, TimeUnit.SECONDS)
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(4)
}
```
```
Received: [300, 600, 900]
Received: [1200, 1500, 1800]
Received: [2100, 2400, 2700]
Received: [3000, 3300, 3600, 3900]
```
There is an option to also specify a `timeskip` argument, which is the timer-based counterpart to skip:
```kotlin
fun main() {
    Observable.interval(300, TimeUnit.MILLISECONDS)
        .map { (it + 1) * 300 } // map to elapsed time
        .buffer(1, 2, TimeUnit.SECONDS) // 2nd arg is timeskip
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(4)
}
```
```
Received: [300, 600, 900]
Received: [2100, 2400, 2700]
```
Also, a third `count` argument can be provided to specify a maximum buffer size. This will result in a buffer emission at each _time interval_ _or_ when _count is reached_, whichever happens first:
```kotlin
fun main() {
    Observable.interval(300, TimeUnit.MILLISECONDS)
        .map { (it + 1) * 300 } // map to elapsed time
        .buffer(1,  TimeUnit.SECONDS, 2) // 3rd arg is count
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(4)
}
```
```
Received: [300, 600]
Received: [900]
Received: [1200, 1500]
Received: [1800]
Received: [2100, 2400]
Received: [2700]
Received: [3000, 3300]
Received: [3600, 3900]
Received: []
```

### Boundary-based buffering
 `buffer()` can accept another `Observable` (whatever its type) as a _boundary argument_. Every time it emits something, it will use the timing of that emission as the buffer cut-off:
```kotlin
fun main() {
    val cutOffs = Observable.interval(1, TimeUnit.SECONDS)
    Observable.interval(300, TimeUnit.MILLISECONDS)
        .map { (it + 1) * 300 } // map to elapsed time
        .buffer(cutOffs)
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(5)
}
```
```
Received: [300, 600, 900]
Received: [1200, 1500, 1800]
Received: [2100, 2400, 2700]
Received: [3000, 3300, 3600, 3900]
Received: [4200, 4500, 4800]
```
