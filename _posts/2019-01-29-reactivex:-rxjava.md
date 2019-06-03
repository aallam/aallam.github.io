---
title: "Reactive Extensions: RxJava"
layout: post
date: 2019-01-29 23:06
description:
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

I always has been interested by Reactive Extensions (ReactiveX) and RxJava (and RxKotlin).  
Recently, I enjoyed reading the excellent book: [Learning RxJava][1] by Thomas Nield, and the following are my notes.

## Why RxJava ?
* Concurrency, event handling, obsolete data states, and exception recovery.
* Maintainable, reusable, and evolvable.
* Allows applications to be tactical and evolvable while maintaining stability in production.

## Quick Start
In ReactiveX, the core type is the `Observable` which essentially pushes things. A given `Observable<T>` pushes things of type `T` through a series of operators until it arrives at an `Observer` that consumes the items. 
The following is an example of an `Observable<String>` that will push three `String` objects:
```kotlin
fun main() {
    val observable = Observable.just("Hello", "world", "!")
}
```
However, running this `main` method is not going to do anything other than declare a `Observable<String>`. To make this `Observable` actually push (or emit) these three strings, we need an `Observer` to _subscribe_ to it and receive the items:
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
Hello world ! 
```
What happened here is that our `Observable<String>` pushed each `String` object once at a time to the `Observer` (the lambda).

It’s possible to use several operators between `Observable` and `Observer` to transform each pushed item or manipulate them, the following is an example of `map()`:
```kotlin
fun main() {
    val observable = Observable.just("Hello", "world", "!")
    observable.map { it.toUpperCase() }.subscribe { print("$it ") }
}
```
The output should be:
```
HELLO WORLD !
```

## RxJava vs Java 8 Streams
How `Observable` is any different from Java 8 _Streams_ or Kotlin _sequences_? The key difference is that `Observable` _pushes_ the items while Streams and sequences _pull_ the items. 

## Advanced RxJava
The following are more detailed notes for a deeper understanding of RxJava:

* [Observable & Observer][11]
* [Hot vs Cold Observable][12]
* [Observable Factories][13]
* [Disposing][14]
* [Supressing][15], [Transforming][16], [Reducing][17], [Collection][18], [Recovery][19] and [Action][20] Operators.
* [Combining Observables][21]
* [Multicasting][22], [Replaying and Caching][23] and [Subjects][24]
* [Concurrency][25] and [Parallelisation][26]
* [Buffering][27], [Windowing][28], [Throttling][29] and [Switching][30]
* [Backpressure][31], [Flowable][32] and [Subscriber][33]
* [Transformers][34] and [Custom Operators][35]

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
