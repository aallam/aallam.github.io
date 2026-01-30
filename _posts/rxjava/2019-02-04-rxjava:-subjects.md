---
title: "RxJava: Subjects"
layout: post
date: 2019-02-04 17:38
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

_Erik Meijer_, the creator of ReactiveX, describes Subjects as the "_mutable variables of reactive programming_" . Subjects are both an `Observer` and an `Observable` acting as a _proxy multicasting_ device (like an event bus) .

## PublishSubject
```kotlin
fun main() {
    val subject = PublishSubject.create<String>()
    subject.map(String::length).subscribe { println("Received: $it") }
    subject.onNext("Alpha")
    subject.onNext("Beta")
    subject.onNext("Gamma")
    subject.onComplete()
}
```
```
Received: 5
Received: 4
Received: 5
```

### When to use
Subjects are good to eagerly subscribe to an unknown number of multiple source `Observable`s and consolidate their emissions as a _single_ `Observable`:
```kotlin
fun main() {
    val source1 = Observable.interval(1, TimeUnit.SECONDS).map { "${it + 1} seconds" }
    val source2 = Observable.interval(300, TimeUnit.MILLISECONDS).map { "${(it + 1) * 300} milliseconds" }
    val subject = PublishSubject.create<String>()
    subject.subscribe { println(it) }
    source1.subscribe(subject)
    source2.subscribe(subject)
    TimeUnit.SECONDS.sleep(3)
}
```
```
300 milliseconds
600 milliseconds
900 milliseconds
1 seconds
1200 milliseconds
1500 milliseconds
1800 milliseconds
2 seconds
2100 milliseconds
2400 milliseconds
2700 milliseconds
3 seconds
3000 milliseconds
```

### When goes wrong
Subjects are **hot**, executing the `onNext()` calls before the Observers are subscribed would result in these emissions being missed:
```kotlin
fun main() {
    val subject = PublishSubject.create<String>()
    subject.onNext("Alpha")
    subject.onNext("Beta")
    subject.onNext("Gamma")
    subject.onComplete()
    subject.map(String::length).subscribe { println("Received: $it") }
}
```
```
(No output)
```

### Serialising
In Subjects, the `onSubscribe()`, `onNext()`, `onError()`, and `onComplete()` calls **are not thread-safe**. `toSerialized()` wraps the `Subject` to make it thread-safe:
```kotlin
PublishSubject.create<String>().toSerialized() 
```

## Other Subjects
* `BehaviorSubject`:  replays the last emitted item to each new `Observer` downstream.
* `ReplaySubject`:  similar to `PublishSubject` followed by a `cache()` operator.
* `AsyncSubject`: only pushes the last value it receives, followed by an `onComplete()` event.
* `UnicastSubject`: buffers all the emissions it receives until an `Observer` subscribes to it, and then it releases all these emissions to the `Observer` and clear its cache.
