---
title: "RxJava: Hot vs Cold Observable"
layout: post
date: 2019-01-29 23:47
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

Observables  can be **cold** or **hot**, which defines how they behave when there are multiple Observers.

## Cold Observables
_Cold_ Observables will replay the emissions to each `Observer`, ensuring that all Observers get all the data.  
Usually, most _data-driven_ (finite datasets) Observables are _cold_ (including `Observable.just` and `Observable.fromIterable`), example:
```kotlin
fun main() {
    val source: Observable<String> = Observable.just("Alpha", "Beta", "Charlie", "Delta", "Epsilon")

    // First observer
    source.map { it.length }.subscribe{ println("[Observer1] Received: $it") }

    // Second observer
    source.subscribe{ println("[Observer2] Received: $it") }
}
```
```
[Observer1] Received: 5
[Observer1] Received: 4
[Observer1] Received: 7
[Observer1] Received: 5
[Observer1] Received: 7
[Observer2] Received: Alpha
[Observer2] Received: Beta
[Observer2] Received: Charlie
[Observer2] Received: Delta
[Observer2] Received: Epsilon
```
Both Observers receive the same datasets by getting two separate streams each.

## Hot Observables
_Hot_ Observables often represent events rather than finite datasets. The events can carry data with them, but there is a _time-sensitive_ component where _late_ observers _can miss previously emitted data_. 
UI events or server requests, for example, can be represented as a _hot_ `Observable`.
The following is an example of a JavaFX UI with a `Togglebutton` and a `Label`, It creates an `Observable` which emits toggling actions, the subscribed `Observer` consumes this information and changes the `Label` accordingly:
```kotlin
class App : Application() {
    override fun start(primaryStage: Stage?) {
        // ...
        toggleButton.selectedProperty().toObservable()
            .map { if (it) "DOWN" else "UP" }
            .subscribe { label.text = it }
        // ...
    }
}

private fun <T> ObservableValue<T>.toObservable(): Observable<T> {
    return Observable.create { observableEmitter ->
        //emit initial state
        observableEmitter.onNext(value)
        //emit value changes uses a listener
        addListener { _, _, newValue -> observableEmitter.onNext(newValue) }
    }
}
```
If there was new Observers to this `ToggleButton`’s events after emissions have occurred, those new Observers _will have missed_ these emissions.  
While many hot Observables are indeed infinite, they do not have to be. They just have to share emissions to all Observers simultaneously and not replay missed emissions for tardy Observers.

### ConnectableObservable 
`ConnectableObservable` takes any `Observable` (even if it is _cold_) and makes it _hot_, so that all emissions are played to all Observers at once.  
Calling `publish()`  on any `Observable` returns a `ConnectableObservable`. Subscribing to the `ConnectableObservable` won’t start the emissions, `connect()`  must be called to start firing them:
```kotlin
fun main() {
    val source: ConnectableObservable<String> = Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon").publish()
    //Set up observer 1
    source.subscribe { println("Observer 1: $it") }
    //Set up observer 2
    source.map { it.length }.subscribe { println("Observer 2: $it") }
    //Fire!
    source.connect()
}
```
```
Observer 1: Alpha
Observer 2: 5
Observer 1: Beta
Observer 2: 4
Observer 1: Gamma
Observer 2: 5
Observer 1: Delta
Observer 2: 5
Observer 1: Epsilon
Observer 2: 7
```
Using `ConnectableObservable` allows the set up all Observers beforehand and force each emission to go to all Observers simultaneously (_multicasting_).
