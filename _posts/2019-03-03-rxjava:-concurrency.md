---
title: "RxJava: Concurrency"
layout: post
date: 2019-03-03 23:55
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

**Concurrency** is handling multiple tasks being in progress at the same time, but not necessary simultaneously.

The following are two tasks which will run sequentially:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .map { intenseCalculation(it) }
        .subscribe { println(it) }

    Observable.range(1, 6)
        .map { s -> intenseCalculation(s) }
        .subscribe { println(it) }
}
```
```
Alpha
Beta
Gamma
Delta
Epsilon
1
2
3
4
5
6
```

Using the operator `subscribeOn()` makes the same tasks  run concurrently:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .subscribeOn(Schedulers.computation())
        .map { intenseCalculation(it) }
        .subscribe { println(it) }

    Observable.range(1, 6)
        .subscribeOn(Schedulers.computation())
        .map { s -> intenseCalculation(s) }
        .subscribe { println(it) }

    TimeUnit.SECONDS.sleep(20)
}
```
```
Alpha
1
2
Beta
3
Gamma
4
Delta
5
Epsilon
6
```

RxJava operators work safely with Observables on different threads. For example, operators and factories that combine multiple Observables (`merge()`, `zip()`…), will safely combine emissions pushed by different threads:
```kotlin
fun main() {
    val source1 = Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .subscribeOn(Schedulers.computation())
        .map { intenseCalculation(it) }

    val source2 = Observable.range(1, 6)
        .subscribeOn(Schedulers.computation())
        .map { s -> intenseCalculation(s) }

    Observable.zip(source1, source2, BiFunction { s1: String, s2: Int -> s1 to s2 })
        .subscribe { println(it) }

    TimeUnit.SECONDS.sleep(20)
}
```
```
(Alpha, 1)
(Beta, 2)
(Gamma, 3)
(Delta, 4)
(Epsilon, 5)
```

Instead of using sleep, it’s possible to use `blockingSubscribe()` (mostly for testing purposes).

## Schedulers
Schedulers are mainly thread pools with different policies, threads may be persisted and maintained so they can be reused. A queue of tasks is then executed by that thread pool:

* `Schedulers.computation()`: maintains a fixed number of threads based on the processor count available, making it appropriate for computational tasks. 
* `Schedulers.io()`: maintains as many threads as there are tasks and will dynamically grow, cache, and reduce the number of threads as needed. 
* `Schedulers.newThread()`: creates a new thread for each Observer and then destroy the thread when it is done (without caching/persisting threads).
* `Schedulers.single()`: backed by a single-threaded (to run tasks sequentially on a single thread).
* `Schedulers.trampoline()`: run on the immediate thread, but it prevents cases of recursive scheduling.
* `Schedulers.from()`: it’s possible to create a custom thread pool using `ExecurtorService`, and pass it as argument to `Schedulers.from()`.


## Operator: subscribeOn()
The `subscribeOn()` operator can be put anywhere in the `Observable` chain to suggest to the upstream _source_ which `Scheduler` to use.   
If that source is not already tied to a particular `Scheduler`, it will use the specified `Scheduler`. It will then push emissions _all the way_to the final `Observer` using that thread (unless `observeOn()` calls are added). 

```kotlin
fun main() {
    val source1 = Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .subscribeOn(Schedulers.computation())
        .map { intenseCalculation(it) }
        .doOnNext { println("${Thread.currentThread().name} $it") }

    val source2 = Observable.range(1, 6)
        .map { s -> intenseCalculation(s) }
        .subscribeOn(Schedulers.computation())
        .doOnNext { println("${Thread.currentThread().name} $it") }

    val source3 = Observable.just('α', 'β', 'γ', 'δ', 'ε')
        .map { intenseCalculation(it) }
        .doOnNext { println("${Thread.currentThread().name} $it") }
        .subscribeOn(Schedulers.computation())

    Observable.zip(source1, source2, source3, Function3 { s1: String, s2: Int, s3: Char -> Triple(s1, s2, s3) })
        .subscribe { println(it) }

    TimeUnit.SECONDS.sleep(20)
}
```
```
RxComputationThreadPool-2 1
RxComputationThreadPool-1 Alpha
RxComputationThreadPool-3 α
(Alpha, 1, α)
RxComputationThreadPool-3 β
RxComputationThreadPool-3 γ
RxComputationThreadPool-1 Beta
RxComputationThreadPool-2 2
(Beta, 2, β)
RxComputationThreadPool-1 Gamma
RxComputationThreadPool-2 3
RxComputationThreadPool-3 δ
(Gamma, 3, γ)
RxComputationThreadPool-3 ε
RxComputationThreadPool-1 Delta
RxComputationThreadPool-2 4
(Delta, 4, δ)
RxComputationThreadPool-1 Epsilon
RxComputationThreadPool-2 5
(Epsilon, 5, ε)
```

Having multiple Observers to the same `Observable` with `subscribeOn()` will result in each one getting its own thread:
```kotlin
fun main() {
    val source = Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .subscribeOn(Schedulers.computation())
        .map { intenseCalculation(it) }

    source.subscribe { println("${Thread.currentThread().name} $it") }
    source.subscribe { println("${Thread.currentThread().name} $it") }

    TimeUnit.SECONDS.sleep(15)
}
```
```
RxComputationThreadPool-1 Alpha
RxComputationThreadPool-2 Alpha
RxComputationThreadPool-2 Beta
RxComputationThreadPool-2 Gamma
RxComputationThreadPool-2 Delta
RxComputationThreadPool-1 Beta
RxComputationThreadPool-2 Epsilon
RxComputationThreadPool-1 Gamma
RxComputationThreadPool-1 Delta
RxComputationThreadPool-1 Epsilon
```

It’s possible however to use a _multicast operator_ to only have _one thread_ to serve multiple Observers:
```kotlin
fun main() {
    val source = Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .subscribeOn(Schedulers.computation())
        .map { intenseCalculation(it) }
        .publish()
        .autoConnect(2)

    source.subscribe { println("${Thread.currentThread().name} $it") }
    source.subscribe { println("${Thread.currentThread().name} $it") }

    TimeUnit.SECONDS.sleep(15)
}
```
```
RxComputationThreadPool-1 Alpha
RxComputationThreadPool-1 Alpha
RxComputationThreadPool-1 Beta
RxComputationThreadPool-1 Beta
RxComputationThreadPool-1 Gamma
RxComputationThreadPool-1 Gamma
RxComputationThreadPool-1 Delta
RxComputationThreadPool-1 Delta
RxComputationThreadPool-1 Epsilon
RxComputationThreadPool-1 Epsilon
```

### Notes
* When having multiple `onSubscribe()` calls , only the closest call to the `Observable` source is applied:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .subscribeOn(Schedulers.computation())
        .map { intenseCalculation(it) }
        .subscribeOn(Schedulers.io())
        .subscribe { println("${Thread.currentThread().name} $it") }

    TimeUnit.SECONDS.sleep(15)
}
```
```
RxComputationThreadPool-1 Alpha
RxComputationThreadPool-1 Beta
RxComputationThreadPool-1 Gamma
RxComputationThreadPool-1 Delta
RxComputationThreadPool-1 Epsilon
```

* It is possible that `subscribeOn()` will have no effect with certain sources. This might be because these Observables already use a specific `Scheduler`, but it is possible to provide a `Scheduler` as an argument:
```kotlin
fun main() {
    Observable.interval(1, TimeUnit.SECONDS, Schedulers.io())
        .map { intenseCalculation(it) }
        .subscribe { println("[${Thread.currentThread().name}] $it") }

    TimeUnit.SECONDS.sleep(10)
}
```
```
[RxCachedThreadScheduler-1] 0
[RxCachedThreadScheduler-1] 1
[RxCachedThreadScheduler-1] 2
[RxCachedThreadScheduler-1] 3
[RxCachedThreadScheduler-1] 4
[RxCachedThreadScheduler-1] 5
[RxCachedThreadScheduler-1] 6
```

## Operator: observeOn()
The `observeOn()` is an operator that _intercepts_ emissions at the point where is has been called in the `Observable` chain and _switch_ them to a different `Scheduler` going forward:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .subscribeOn(Schedulers.computation())
        .doOnNext { println("[doOnNext][${Thread.currentThread().name}] $it") }
        .map { intenseCalculation(it) } // Runs on `Computation`
        .observeOn(Schedulers.io())
        .subscribe { println("[subscribe][${Thread.currentThread().name}] $it") } // Runs on `IO`

    TimeUnit.SECONDS.sleep(10)
}
```
```
[doOnNext][RxComputationThreadPool-1] Alpha
[doOnNext][RxComputationThreadPool-1] Beta
[subscribe][RxCachedThreadScheduler-1] Alpha
[doOnNext][RxComputationThreadPool-1] Gamma
[subscribe][RxCachedThreadScheduler-1] Beta
[doOnNext][RxComputationThreadPool-1] Delta
[subscribe][RxCachedThreadScheduler-1] Gamma
[doOnNext][RxComputationThreadPool-1] Epsilon
[subscribe][RxCachedThreadScheduler-1] Delta
[subscribe][RxCachedThreadScheduler-1] Epsilon
```

This capacity of switching `Scheduler` can be very useful for UI thread events (Like for Android, JavaFx…): Using `observeOn()` to move UI events to a different `Scheduler` to do the work, and when the result is ready, move it back to the UI thread with another `observeOn()`.

### Notes
* For a given chained operations `A` and `B`, the operation `A` will pass emissions _strictly one at a time_  to operation `B`. But this changes when `observeOn()` comes between the two operations:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .subscribeOn(Schedulers.computation())
        .doOnNext { println("[doOnNext][${Thread.currentThread().name}] $it") }
        .observeOn(Schedulers.io())
        .map { intenseCalculation(it) } // Runs on `Computation`
        .subscribe { println("[subscribe][${Thread.currentThread().name}] $it") } // Runs on `IO`

    TimeUnit.SECONDS.sleep(10)
}
```
```
[doOnNext][RxComputationThreadPool-1] Alpha
[doOnNext][RxComputationThreadPool-1] Beta
[doOnNext][RxComputationThreadPool-1] Gamma
[doOnNext][RxComputationThreadPool-1] Delta
[doOnNext][RxComputationThreadPool-1] Epsilon
[subscribe][RxCachedThreadScheduler-1] Alpha
[subscribe][RxCachedThreadScheduler-1] Beta
[subscribe][RxCachedThreadScheduler-1] Gamma
[subscribe][RxCachedThreadScheduler-1] Delta
[subscribe][RxCachedThreadScheduler-1] Epsilon
```
When Operation `A` hands an emission to the `observeOn(),` _it will not wait_ for the downstream to finish, instead it will _immediately start the next emission_.
This means that the source and Operation `A` can _produce_ emissions _faster_ than Operation `B` and the `Observer` can _consume_them. 
If the source/Operator `A` may produce a lot of emissions (10,000 or more),  `Flowable` (which supports /backpressure/) should be used.

## Operator: unsubscribeOn()
When disposing an Observable, sometimes, such operation can be an expensive, for instance, if the `Observable` is emitting the results of a database query, it can be expensive to stop and dispose that `Observable` because it needs to shut down the JDBC resources it is using. 

Let’s take the following example:
```kotlin
fun main() {
    val disposable = Observable.interval(1, TimeUnit.SECONDS)
        .doOnDispose { System.out.println("Disposing on thread ${Thread.currentThread().name}") }
        .subscribe { System.out.println("Received $it") }

    TimeUnit.SECONDS.sleep(3)
    disposable.dispose()
    TimeUnit.SECONDS.sleep(3)
}
```
```
Received 0
Received 1
Received 2
Disposing on thread main
```
In the previous example, the disposing operation is happening in the main thread. This behaviour might not be desired (In case of Android for example), but no worries, `unsubscribeOn()` operator is here to the rescue:
```kotlin
fun main() {
    val disposable = Observable.interval(1, TimeUnit.SECONDS)
        .doOnDispose { System.out.println("Disposing on thread ${Thread.currentThread().name}") }
        .unsubscribeOn(Schedulers.io())
        .subscribe { System.out.println("Received $it") }

    TimeUnit.SECONDS.sleep(3)
    disposable.dispose()
    TimeUnit.SECONDS.sleep(3)
}
```
```
Received 0
Received 1
Received 2
Disposing on thread RxCachedThreadScheduler-1
```
Now the disposing is happening in the `IO` thread.

Note: `unsubscribeOn()` should not be used for lightweight operations as it adds unnecessary overhead.  
It’s possible to use multiple `unsubscribeOn()` calls to target specific parts of the `Observable` chain to be disposed of with different Schedulers.
