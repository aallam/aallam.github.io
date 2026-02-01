---
title: "RxJava: Switching"
layout: post
date: 2019-03-19 13:27
description: Understand RxJava switchMap operator to cancel previous Observables and switch to the latest emission, preventing stale or redundant processing.
tag:
- ReactiveX
- RxJava
- Java
- Kotlin
blog: true
hidden: true
jemoji:
---

`switchMap()` is an operator like `flatMap()` but with an important difference: it will emit from the **latest** `Observable` derived from the _latest emission_ and _dispose of any previous_ Observables that were processing. In other words, it allows to _cancel an emitting_ `Observable` _and switch to a new one_. This can be really useful to prevent stale or redundant processing. 

In the following example, each emission takes between 0-2 secs to be emitted, and processing all can take up to 20 secs:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota")
        .concatMap { s -> Observable.just(s).delay(Random.nextLong(0, 100), TimeUnit.MILLISECONDS) }
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(20)
}
```
```
Received: Alpha
Received: Beta
Received: Gamma
Received: Delta
Received: Epsilon
Received: Zeta
Received: Eta
Received: Theta
Received: Iota
```

Now, let’s run this process every 5 seconds, but while having each time only the last instance:
```kotlin
fun main() {
    val strings = Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota")
        .concatMap { s -> Observable.just(s).delay(Random.nextLong(2000), TimeUnit.MILLISECONDS) }

    Observable.interval(5, TimeUnit.SECONDS)
        .switchMap { strings.doOnDispose { println("Disposing ! Next..") } }
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(20)
}
```
```
Received: Alpha
Received: Beta
Disposing ! Next..
Received: Alpha
Received: Beta
Received: Gamma
Received: Delta
Received: Epsilon
Received: Zeta
Disposing ! Next..
Received: Alpha
Received: Beta
Received: Gamma
Disposing ! Next..
```

`switchMap()` receives every 5 seconds emissions from the `interval()` operator, the emission going into `switchMap()` will promptly dispose of the currently processing `Observable` (if there are any) and then emit from the new Observable it maps to. 
In other terms, `switchMap()` is like `flatMap()` except that it will cancel any previous Observables and only emit from the latest one. This can be helpful to prevent redundant or stale work.

For better performance, the thread pushing emissions into `switchMap()` should not be occupied doing the work inside `switchMap()`  (by using `observeOn()`, `subscribeOn()`  and `unsubscribeOn()`).
