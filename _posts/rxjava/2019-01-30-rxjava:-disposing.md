---
title: "RxJava: Disposing"
layout: post
date: 2019-01-29 23:47
description: "Understanding Disposable in RxJava: how to properly manage resources, stop emissions, and prevent memory leaks with CompositeDisposable."
tag:
- ReactiveX
- RxJava
- Java
- Kotlin
blog: true
hidden: true
jemoji:
---

The `Disposable` is a link between an `Observable` and an active `Observer`, calling its `dispose()` method stops the emissions and dispose of all resources used for that `Observer`:
```kotlin
fun main() {
    val seconds = Observable.interval(1, TimeUnit.SECONDS)
    val disposable = seconds.subscribe { println("Received: $it") }
    TimeUnit.SECONDS.sleep(5)
    // Dispose and stop emissions.
    disposable.dispose()
    // Sleep 5 secs: no new emissions.
    TimeUnit.SECONDS.sleep(5)
}
```
```
Received: 0
Received: 1
Received: 2
Received: 3
Received: 4
```

## Disposable within an Observer
An `Observer` receives its own `Disposable` when subscribing as an argument of `onSubscribe(d: Disposable)`.
The following is an example of an `Observer` self-disposing after consuming an emission: 
```kotlin
fun main() {
    val seconds = Observable.interval(1, TimeUnit.SECONDS)
    seconds.subscribe(MyObserver())
    TimeUnit.SECONDS.sleep(5)

}

class MyObserver<T> : Observer<T> {
    private lateinit var disposable: Disposable

    override fun onSubscribe(disposable: Disposable) {
        this.disposable = disposable
    }

    override fun onNext(t: T) {
        println("Received: $t")
        disposable.dispose() // Self dispose
    }

    override fun onError(e: Throwable) {
        e.printStackTrace()
    }

    override fun onComplete() {
        println("Done !")
    }
}

```
```
Received: 0
```

By default, calling `subscribe()` with an `Observer` instance doesn't return a `Disposable`, but it's possible to get it by extending `ResourceObserver` and subscribing using `subscribeWith()`:
```kotlin
fun main() {
    val seconds = Observable.interval(1, TimeUnit.SECONDS)
    val disposable: Disposable = seconds.subscribeWith(MyResourceObserver())
    TimeUnit.SECONDS.sleep(5)
    // Dispose and stop emissions.
    disposable.dispose()
    // Sleep 5 secs: no new emissions.
    TimeUnit.SECONDS.sleep(5)
}

class MyResourceObserver<T> : ResourceObserver<T>() {
    override fun onNext(t: T) {
        println("Received: $t")
    }

    override fun onError(e: Throwable) {
        e.printStackTrace()
    }

    override fun onComplete() {
        println("Done !")
    }
}
```
```
Received: 0
Received: 1
Received: 2
Received: 3
Received: 4
```

## CompositeDisposable
To manage and dispose of several subscriptions, `CompositeDisposable` is useful:
```kotlin
fun main() {
    val disposables = CompositeDisposable()
    val seconds = Observable.interval(1, TimeUnit.SECONDS)
    // Subscribe and capture disposables
    val disposable1 = seconds.subscribe { println("Observer 1: $it") }
    val disposable2 = seconds.subscribe { println("Observer 2: $it") }
    // Put disposables into CompositeDisposable
    disposables.addAll(disposable1, disposable2)
    // Sleep 5 secs
    TimeUnit.SECONDS.sleep(3)
    //dispose all disposables
    disposables.dispose()
    //sleep 5 seconds: no emissions.
    TimeUnit.SECONDS.sleep(3)
}
```
```
Observer 1: 0
Observer 2: 0
Observer 1: 1
Observer 2: 1
Observer 1: 2
Observer 2: 2
```

## Disposal with Observable.create()
In case of an  `Observable.create()` returning a _long-running or infinite_ `Observable`, ideally, the emitter’s `isDisposed()` should checked regularly to see whether to keep sending emissions:
```kotlin
fun main() {
    val source: Observable<Int> = Observable.create { observableEmitter ->
        try {

            for (i in 0..1_000_000) {
                if (observableEmitter.isDisposed)
                    return@create
                observableEmitter.onNext(i)
            }
            observableEmitter.onComplete()

        } catch (e: Exception) {
            observableEmitter.onError(e)
        }
    }
}
```

In case `Observable.create()` is wrapped around some resource, the disposal of that resource _must be handled_ to prevent leaks. `ObservableEmitter` has the `setCancellable() `and `setDisposable()` methods for that:
```kotlin
fun <T> valuesOf(fxObservable: ObservableValue<T>): Observable<T> {
    return Observable.create { observableEmitter ->
        // Emit initial state
        observableEmitter.onNext(fxObservable.value)
        // Emit value changes uses a listener
        val listener = ChangeListener<T> { _, _, current -> observableEmitter.onNext(current) }
        // Add listener to ObservableValue
        fxObservable.addListener(listener)
        // Handle disposing by specifying cancellable
        observableEmitter.setCancellable { fxObservable.removeListener(listener) }
    }
}
```
