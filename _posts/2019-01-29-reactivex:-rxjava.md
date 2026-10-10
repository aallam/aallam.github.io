---
title: "Reactive Programming with RxJava"
layout: post
date: 2019-01-29 23:06
description: "Introduction to RxJava and reactive programming. Learn the fundamentals of ReactiveX for building asynchronous, event-based applications in Java."
image: /assets/images/blog/reactivex.png
tag:
- ReactiveX
- RxJava
- Java
- Kotlin
blog: true
jemoji:
---

<div class="text-center" markdown="1">
![ReactiveX][0]{:width="25%"}
<figcaption class="caption">Reactive Extensions (ReactiveX)</figcaption>
</div>
<br/>

> **Update note:** I wrote this series for RxJava 2.x in 2019. RxJava 3.x changed some APIs. See the [RxJava 3.x migration guide](https://github.com/ReactiveX/RxJava/wiki/What's-different-in-3.0) when using that version.

I enjoyed Thomas Nield's [Learning RxJava][1]. These are my notes on RxJava 2.

## Why RxJava?
* Combine events from several sources into one stream.
* Move work to a scheduler and deliver results to a chosen thread.
* Transform values, stop subscriptions, and recover from errors with operators.

## Quickstart
In RxJava 2, an `Observable<T>` emits values of type `T` to a subscriber. Operators can transform those values before the subscriber receives them.

This `Observable<String>` contains three strings:
```kotlin
fun main() {
    val observable = Observable.just("Hello", "world", "!")
}
```
This method creates an observable but does not subscribe. Add a subscriber to print its values:
```kotlin
fun main() {
    val observable = Observable.just("Hello", "world", "!")
    observable.subscribe {
        print("$it ")
    }
}
```
This time, the output is the following:
```
Hello world !␠
```
The subscriber prints each string followed by a space. In the output above, ␠ marks the final space.

Use `map()` to transform each string before printing it:
```kotlin
fun main() {
    val observable = Observable.just("Hello", "world", "!")
    observable.map { it.uppercase() }.subscribe { print("$it ") }
}
```
The output uses the same spacing:
```
HELLO WORLD !␠
```

## RxJava vs Java 8 streams
An `Observable` emits items to subscribers. Java streams and Kotlin sequences yield items when consumers request them. RxJava also supplies operators for asynchronous events and scheduler control.

## RxJava Series Guide

This is a comprehensive guide to RxJava organized by topic. Follow the links below for in-depth coverage:

### Fundamentals
* [Observable & Observer][11] - Core concepts and Observable factories
* [Hot vs Cold Observable][12] - Understanding observable behavior patterns
* [Observable Factories][13] - Additional factory methods (range, interval, timer, etc.)
* [Disposing][14] - Resource management and stopping emissions

### Operators
* **Filtering & Control**: [Suppressing][15] - filter, take, skip, distinct
* **Transformation**: [Transforming][16] - map, flatMap, concatMap, switchMap
* **Aggregation**: [Reducing][17] - count, reduce, all, any
* **Collection**: [Collection][18] - toList, toMap, collect
* **Error Handling**: [Recovery][19] - onErrorReturn, onErrorResumeNext
* **Side Effects**: [Action][20] - doOnNext, doOnComplete, doOnError

### Advanced Topics
* [Combining Observables][21] - merge, concat, zip, combineLatest
* [Multicasting][22] - ConnectableObservable and sharing streams
* [Replaying and Caching][23] - replay() and cache() operators
* [Subjects][24] - PublishSubject, BehaviorSubject, and more
* [Concurrency][25] - subscribeOn and observeOn with Schedulers
* [Parallelisation][26] - Parallel execution strategies

### Flow Control
* [Buffering][27] - Batch emissions into collections
* [Windowing][28] - Batch emissions into separate Observables
* [Throttling][29] - Control emission rate
* [Switching][30] - Cancel previous Observables

### Backpressure
* [Backpressure][31] - Understanding and handling backpressure
* [Flowable][32] - Observable with backpressure support
* [Subscriber][33] - Consuming Flowables

### Customization
* [Transformers][34] - Reusable operator chains
* [Custom Operators][35] - Building your own operators

## Sources
* [Learning RxJava][1]
* [ReactiveX Documentation][2]
* [RxJava Github][3]
* [RxMarbles][4]

_These Kotlin examples use RxJava directly. [RxKotlin][5] offers Kotlin-specific extensions._

[0]: {{ site.url }}/assets/images/blog/reactivex.png
[1]: https://www.amazon.com/Learning-RxJava-Thomas-Nield/dp/1787120422
[2]: http://reactivex.io/documentation
[3]: https://github.com/ReactiveX/RxJava
[4]: https://rxmarbles.com/
[5]: https://github.com/ReactiveX/RxKotlin
[11]: {{ site.url }}/rxjava-observable-and-observer
[12]: {{ site.url }}/rxjava-hot-vs-cold-observable
[13]: {{ site.url }}/rxjava-observable-factories
[14]: {{ site.url }}/rxjava-disposing
[15]: {{ site.url }}/rxjava-supressing-operators
[16]: {{ site.url }}/rxjava-transforming-operators
[17]: {{ site.url }}/rxjava-reducing-operators
[18]: {{ site.url }}/rxjava-collection-operators
[19]: {{ site.url }}/rxjava-recovery-operators
[20]: {{ site.url }}/rxjava-action-operators
[21]: {{ site.url }}/rxjava-combining-observables
[22]: {{ site.url }}/rxjava-multicasting
[23]: {{ site.url }}/rxjava-replaying-and-caching
[24]: {{ site.url }}/rxjava-subjects
[25]: {{ site.url }}/rxjava-concurrency
[26]: {{ site.url }}/rxjava-parallelisation
[27]: {{ site.url }}/rxjava-buffering
[28]: {{ site.url }}/rxjava-windowing
[29]: {{ site.url }}/rxjava-throttling
[30]: {{ site.url }}/rxjava-switching
[31]: {{ site.url }}/rxjava-backpressure
[32]: {{ site.url }}/rxjava-flowable
[33]: {{ site.url }}/rxjava-subscriber
[34]: {{ site.url }}/rxjava-transformers
[35]: {{ site.url }}/rxjava-custom-operators
