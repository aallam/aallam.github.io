---
title: "RxJava: Parallelisation"
layout: post
date: 2019-03-04 00:06
description: Learn RxJava parallelization techniques using flatMap operator and Schedulers to process multiple emissions concurrently for dramatically improved performance.
tag:
- ReactiveX
- RxJava
- Java
- Kotlin
blog: true
hidden: true
jemoji:
---

Let’s define **parallelism** as processing multiple emissions at a time for a given `Observable`. 
Although, the `Observable` contract dictates that emissions must be pushed _serially_ down to an `Observable`, RxJava gives enough operators and tools to be clever. 

Let’s take the following example:
```kotlin
fun main() {
    Observable.range(1, 10)
        .map { i -> intenseCalculation(i) }
        .subscribe { System.out.println("Received $it ${LocalTime.now()}") }
}
```
```
Received 1 20:40:34.094
Received 2 20:40:36.109
Received 3 20:40:39.119
Received 4 20:40:42.128
Received 5 20:40:45.132
Received 6 20:40:45.132
Received 7 20:40:46.138
Received 8 20:40:49.140
Received 9 20:40:52.148
Received 10 20:40:54.149
```
The previous example took around 20 seconds to finish !

### Operator: flatMap()
Let's parallelise the previous example using `flatMap`:
```kotlin
fun main() {
    Observable.range(1, 10)
        .flatMap {
            Observable.just(it)
                .subscribeOn(Schedulers.computation())
                .map { i -> intenseCalculation(i) }
        }
        .subscribe { System.out.println("[${Thread.currentThread().name}] Received $it ${LocalTime.now()}") }

    TimeUnit.SECONDS.sleep(5)
}
```
```
[RxComputationThreadPool-1] Received 1 20:55:20.026
[RxComputationThreadPool-7] Received 7 20:55:20.982
[RxComputationThreadPool-10] Received 5 20:55:20.985
[RxComputationThreadPool-10] Received 10 20:55:20.985
[RxComputationThreadPool-3] Received 3 20:55:21.982
[RxComputationThreadPool-3] Received 4 20:55:21.983
[RxComputationThreadPool-3] Received 9 20:55:21.983
[RxComputationThreadPool-2] Received 2 20:55:22.982
[RxComputationThreadPool-2] Received 6 20:55:22.983
[RxComputationThreadPool-2] Received 8 20:55:22.983
```
This time, it took only 3 seconds to complete !

An `Observable` is created from each emission, emit it on a _computation_ thread using `subscribeOn()`, perform the `intenseCalculation()`, and finally, `flatMap()` will merge all of the threads safely back into a serialised stream. 

_Note: If a thread is already pushing an emission out of `flatMap()` , any threads also waiting to push emissions will simply leave their emissions for that occupying thread to take ownership of._ 

### Operator: groupBy()
Another way to parallelise the same example is by using `groupBy()` and `GroupedObservables`. This can be useful to restrict the number of thread to parallelise on (to  the number of processor cores for example):
```kotlin
fun main() {
    val coreCount = Runtime.getRuntime().availableProcessors()
    val assigner = AtomicInteger(0)
    Observable.range(1, 10)
        .groupBy { assigner.incrementAndGet() % coreCount }
        .flatMap { groupedObservable ->
            groupedObservable
                .observeOn(Schedulers.io())
                .map { i -> intenseCalculation(i) }
        }
        .subscribe { System.out.println("[${Thread.currentThread().name}] Received $it ${LocalTime.now()}") }

    TimeUnit.SECONDS.sleep(5)
}
```
```
[RxCachedThreadScheduler-5] Received 5 21:29:20.407
[RxCachedThreadScheduler-5] Received 3 21:29:20.415
[RxCachedThreadScheduler-5] Received 4 21:29:20.415
[RxCachedThreadScheduler-5] Received 7 21:29:20.415
[RxCachedThreadScheduler-5] Received 9 21:29:20.415
[RxCachedThreadScheduler-8] Received 8 21:29:21.344
[RxCachedThreadScheduler-8] Received 10 21:29:21.344
[RxCachedThreadScheduler-6] Received 6 21:29:22.343
[RxCachedThreadScheduler-6] Received 1 21:29:22.343
[RxCachedThreadScheduler-2] Received 2 21:29:23.340
```
Again, it took only 3 seconds to complete!

_Note: `GroupedObservables` are not necessarily impacted by `subscribeOn()` , that’s why `observeOn()` has been used here to parallelise instead._
