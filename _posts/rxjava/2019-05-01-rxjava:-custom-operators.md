---
title: "RxJava: Custom Operators"
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

Creating custom operators is the last resort when existing operators and/or transformers can’t do (or can’t easily do) a specific task. 

## ObservableOperator
Lets create the custom `doOnEmpty()` operator: it will execute an `Action` when `onComplete()` is called and no emissions have occurred. 

To do so, lets implement `ObservableOperator<Downstream,Upstream>` and its `apply()` method. This method accepts an `Observer<Downstream>` observer argument and returns an `Observer<Upstream>`:
```kotlin
fun <T> doOnEmpty(action: Action): ObservableOperator<T, T> {
    return ObservableOperator { observer ->
        object : DisposableObserver<T>() {
            var empty = true

            override fun onComplete() {
                if (empty) {
                    try {
                        action.run()
                    } catch (e: Exception) {
                        onError(e)
                        return
                    }
                }
                observer.onComplete()
            }

            override fun onNext(t: T) {
                this.empty = false
                observer.onNext(t)
            }

            override fun onError(e: Throwable) {
                observer.onError(e)
            }

        }
    }
}
```
Now lets use this `ObservableOperator` by calling it in the `lift()`:
```kotlin
fun main() {
    Observable.range(1, 3)
        .lift(doOnEmpty(Action { println("Source 1 : Empty!!") }))
        .subscribe { println("Received: $it") }

    Observable.empty<Int>()
        .lift(doOnEmpty(Action { println("Source 2: Empty!!") }))
        .subscribe { println("Received: $it") }
} 
```
```
Received: 1
Received: 2
Received: 3
Source 2: Empty!!
```

_Note: when creating custom operators, sharing states between subscriptions should be avoided unless it is really the wanted behavior._

There are a couple of rules in the `Observable` contract that must  be followed, breaking them can have unintended consequences downstream : 
* `onComplete()` never to be called after `onError()` (or vice versa). 
* `onNext()` never to be called after `onComplete()` or `onError()`.
* Not call any events after disposal.

Also, the event calls can be manipulated and mixed as needed:
```kotlin
fun main() {
    Observable.range(1, 3)
        .lift(toImmutableList())
        .subscribe { println("Received: $it") }

    Observable.empty<Int>()
        .lift(toImmutableList())
        .subscribe { println("Received: $it") }
}

fun <T> toImmutableList(): ObservableOperator<List<T>, T> {
    return ObservableOperator { observer ->
        object : DisposableObserver<T>() {
            val mutableList = mutableListOf<T>()

            override fun onNext(t: T) {
                this.mutableList.add(t)
            }

            override fun onError(e: Throwable) {
                observer.onError(e)
            }

            override fun onComplete() {
                observer.onNext(mutableList.toList())
                observer.onComplete()
            }
        }
    }
}
```
```
Received: [1, 2, 3]
Received: []
```

## FlowableOperator
`FlowableOperator` is implemented in a similar manner to `ObservableOperator`, example:
```kotlin
fun main() {
    Flowable.range(1, 3)
        .lift(toImmutableList())
        .subscribe { println("Received: $it") }

    Flowable.empty<Int>()
        .lift(toImmutableList())
        .subscribe { println("Received: $it") }
}

private fun <T> toImmutableList(): FlowableOperator<List<T>, T> {
    return FlowableOperator { observer ->
        object : DisposableSubscriber<T>() {
            val mutableList = mutableListOf<T>()

            override fun onNext(t: T) {
                this.mutableList.add(t)
            }

            override fun onError(e: Throwable) {
                observer.onError(e)
            }

            override fun onComplete() {
                observer.onNext(mutableList.toList())
                observer.onComplete()
            }
        }
    }
}
```
```
Received: [1, 2, 3]
Received: []
```
The  `Subscriber` passed via `apply()`  _(the lambda)_ receives events for the downstream, and the implemented `Subscriber` receives events from the upstream, which it relays to the downstream. 

## Singles, Maybes, and Completables
There are Transformer and operator counterparts for `Single`, `Maybe`, and `Completable`:
* `Single` -> `SingleTransformer` and `SingleOperator`.
* `Maybe` -> `MaybeTransformer` and `MaybeOperator`.
* `Completable` -> `CompletableTransformer`/`CompletableOperator`.
The implementation of `apply()` for all of these should largely the same experience by using `SingleObserver`, `MaybeObserver`, and `CompletableObserver` to proxy the upstream and downstream. 

- - - -
_Implementing operators is something to be conservative about and only to be pursued when all other options have been exhausted._
_It may be worthwhile to explore the [RxJava2-Extras][1] and [RxJava2Extensions][2] libraries for additional operators beyond what RxJava provides._

[1]: https://github.com/davidmoten/rxjava2-extras
[2]: https://github.com/akarnokd/RxJava2Extensions
