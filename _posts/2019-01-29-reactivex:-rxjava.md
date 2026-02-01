---
title: "Reactive Programming with RxJava"
layout: post
date: 2019-01-29 23:06
description: "Introduction to RxJava and reactive programming. Learn the fundamentals of ReactiveX for building asynchronous, event-based applications in Java."
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

> **Update Note**: This RxJava series was written for RxJava 2.x (2019). RxJava 3.x introduced breaking changes and improvements. Core concepts remain the same, but some APIs have changed. Refer to the [RxJava 3.x migration guide](https://github.com/ReactiveX/RxJava/wiki/What's-different-in-3.0) for differences.

Interested in Reactive Extensions and RxJava, I enjoyed reading the excellent book: [Learning RxJava][1] by Thomas Nield, and the following are my notes.

## Why RxJava?
* Concurrency, event handling, obsolete data states, and exception recovery.
* Maintainable, reusable, and evolvable.
* Allows applications to be tactical and evolvable while maintaining stability in production.

## Quickstart
In ReactiveX, the core type is the `Observable` which essentially pushes things. A given `Observable<T>` pushes things of type `T` through a series of operators until it arrives at an `Observer` that consumes the items.
The following is an example of an `Observable<String>` that pushes three `String` objects:
```kotlin
fun main() {
    val observable = Observable.just("Hello", "world", "!")
}
```
Running this `main` method isn't doing anything other than declare a `Observable<String>`. To make this `Observable` actually emit these three strings, an `Observer` need to _subscribe_ to it and receive the items:
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
Hello world! 
```
What happened here is that `Observable<String>` pushed each `String` object once at a time to the `Observer` lambda.

It’s possible to use several operators between `Observable` and `Observer` to transform each pushed item or manipulate them, the following is an example of `map()`:
```kotlin
fun main() {
    val observable = Observable.just("Hello", "world", "!")
    observable.map { it.uppercase() }.subscribe { print("$it ") }
}
```
The output should be:
```
HELLO WORLD!
```

## RxJava vs Java 8 streams
How `Observable` is any different from Java 8 _Streams_ or Kotlin _sequences_? The key difference is that `Observable` _pushes_ the items while Streams and sequences _pull_ the items.

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

_Note: code examples in this article are written in Kotlin to showcase the interoperability between Java and Kotlin, however, for Kotlin projects, it is most likely better to use [RxKotlin][5]._

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
