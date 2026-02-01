---
title: "RxJava: Subscriber"
layout: post
date: 2019-05-01 14:18
description: Understand RxJava Subscriber for Flowable consumption. Learn how to use Subscription and request method for backpressure-aware stream handling.
tag:
- ReactiveX
- RxJava
- Java
- Kotlin
blog: true
hidden: true
jemoji:
---

To consume emissions, `Flowable` uses a `Subscriber` instead of an `Observer`, and return a `Subscription` instead of a `Disposable`.
The `Subscription` can communicate upstream how many items are wanted using its `request()` method.

A simple way to subscribe to a `Flowable` is by using lambdas in the `subscribe()` method:
```kotlin
fun main() {
    Flowable.range(1, 1_000)
        .doOnNext { println("Source pushed: $it") }
        .observeOn(Schedulers.io())
        .map { intenseCalculation(it) }
        .subscribe({ i -> println("Received $i") }, Throwable::printStackTrace, { println("Done !") })

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
Another way, is to pass a `Subscriber` as a parameter to the `subscribe()` method. However unlike `Observer`, the method `request()` must be called on `Subscription` to request emissions at the right moments.
The fastest way to do this, is by calling `request(Long.MAX_VALUE)`:
```kotlin
fun main() {
    val subscriber = object : Subscriber<Int> {
        override fun onSubscribe(subscription: Subscription?) {
            subscription?.request(Long.MAX_VALUE)
        }

        override fun onNext(value: Int?) {
            TimeUnit.MILLISECONDS.sleep(5)
            println("Subscriber received: $value")
        }

        override fun onError(throwable: Throwable?) {
            throwable?.printStackTrace()
        }

        override fun onComplete() {
            println("Done!")
        }
    }

    Flowable.range(1, 1_000)
        .doOnNext { println("Source pushed: $it") }
        .observeOn(Schedulers.io())
        .map { intenseCalculation(it) }
        .subscribe(subscriber)

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
 This means no backpressure will exist between the last operator and the `Subscriber`. This is usually fine since the upstream operators will constrain the flow anyway.
If the goal is to establish an explicit backpressured relationship with the operator preceding the `Subscriber`, the method `request()` should be called to change the pace of emissions: 
```kotlin
fun main() {
    val subscriber = object : Subscriber<Int> {

        var subscription: Subscription? = null
        var count = AtomicInteger(0)

        override fun onSubscribe(subscription: Subscription?) {
            this.subscription = subscription
            println("Requesting 40 items")
            subscription?.request(40)
        }

        override fun onNext(value: Int?) {
            TimeUnit.MILLISECONDS.sleep(5)
            println("Subscriber received: $value")
            if (count.incrementAndGet() % 20 == 0 && count.get() >= 40) {
                println("Requesting 20 items")
                subscription?.request(20)
            }
        }

        override fun onError(throwable: Throwable?) {
            throwable?.printStackTrace()
        }

        override fun onComplete() {
            println("Done!")
        }
    }

    Flowable.range(1, 1_000)
        .doOnNext { println("Source pushed: $it") }
        .observeOn(Schedulers.io())
        .map { intenseCalculation(it) }
        .subscribe(subscriber)

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
```
Requesting 40 items
Source pushed: 1
Source pushed: 2
Source pushed: 3
...
Source pushed: 127
Source pushed: 128
Subscriber received: 1
Subscriber received: 2
...
Subscriber received: 39
Subscriber received: 40
Requesting 20 items
Subscriber received: 41
Subscriber received: 42
...
```
In the previous example the `Subscriber` will request 40 emissions initially and then request 20 emissions at a time after that. Note that the `request()` calls do not go all the way upstream, they only go to the preceding operator, which decides how to relay that request upstream.
