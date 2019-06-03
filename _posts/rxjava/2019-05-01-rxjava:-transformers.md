---
title: "RxJava: Transformers"
layout: post
date: 2019-05-02 18:21
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

RxJava provides the possibility to reuse of pieces of `Observable` or `Flowable` chains and consolidate these operators into a new operator. using `ObservableTransformer` and `FlowableTransformer`.

## ObservableTransformer
Lets take the following example:
```kotlin
fun main() {
    // Letters
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .collect(::StringBuilder) { sb, v -> sb.append("$v ") }
        .map(StringBuilder::toString)
        .subscribe { s -> println(s) }

    // Numbers
    Observable.range(1, 15)
        .collect(::StringBuilder) { sb, v -> sb.append("$v ") }
        .map(StringBuilder::toString)
        .subscribe { s -> println(s) }
}
```
```
Alpha Beta Gamma Delta Epsilon 
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 
```
The piece of code that is chaining of the two operators `collect()` and `map()` is exactly the same! Lets enhance the code reusability 
using `ObservableTransformer` and `compose()`:
```kotlin
fun main() {
    // Letters
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .compose(toString())
        .subscribe { l -> println(l) }

    // Numbers
    Observable.range(1, 15)
        .compose(toString())
        .subscribe { l -> println(l) }
}

fun <T> toString(): ObservableTransformer<T, String> {
    return ObservableTransformer { upstream ->
        upstream
            .collect(::StringBuilder) { sb, v -> sb.append("$v ") }
            .map(StringBuilder::toString)
            .toObservable()
    }
}
```
```
Alpha Beta Gamma Delta Epsilon 
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 
```

## FlowableTransformer
The `FlowableTransformer` is not much different from `ObservableTransformer`. Of course, it will support backpressure since it is composed with `Flowables`:
```kotlin
fun main() {
    // Letters
    Flowable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .compose(toString())
        .subscribe { l -> println(l) }

    // Numbers
    Flowable.range(1, 15)
        .compose(toString())
        .subscribe { l -> println(l) }
}

fun <T> toString(): FlowableTransformer<T, String> {
    return FlowableTransformer { upstream ->
        upstream
            .collect(::StringBuilder) { sb, v -> sb.append("$v ") }
            .map(StringBuilder::toString)
            .toFlowable()
    }
}
```
```
Alpha Beta Gamma Delta Epsilon 
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 
```

## Shared States
When creating Transformers (and custom operators), state sharing between more than one subscription can cause unwanted behaviors and side effects.
```kotlin
fun main() {
    val source = Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .compose(withIndex())
    source.subscribe { println("Subscriber 1: $it") }
    source.subscribe { println("Subscriber 1: $it") }
}

fun <T> withIndex(): ObservableTransformer<T, IndexedValue<T>> {
    val indexer = AtomicInteger(-1) // Bad idea!
    return ObservableTransformer { upstream ->
        upstream.map { v ->
            IndexedValue(indexer.incrementAndGet(), v)
        }
    }
}

data class IndexedValue<T>(val index: Int, val value: T)
```
```
Subscriber 1: IndexedValue(index=0, value=Alpha)
Subscriber 1: IndexedValue(index=1, value=Beta)
Subscriber 1: IndexedValue(index=2, value=Gamma)
Subscriber 1: IndexedValue(index=3, value=Delta)
Subscriber 1: IndexedValue(index=4, value=Epsilon)
Subscriber 1: IndexedValue(index=5, value=Alpha) // Oops!
Subscriber 1: IndexedValue(index=6, value=Beta)
Subscriber 1: IndexedValue(index=7, value=Gamma)
Subscriber 1: IndexedValue(index=8, value=Delta)
Subscriber 1: IndexedValue(index=9, value=Epsilon)
```
A single instance (and state) of `AtomicInteger` was shared between both subscriptions. On the second subscription, instead of starting over at 0, it picks up at the index left by the previous subscription and starts at index 5 since the previous subscription ended at 4. 

- - - -
_Note: In Kotlin, instead of using Transformers, it is possible to leverage extension functions to add operators to `Observable` and `Flowable` types._
