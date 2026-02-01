---
title: "RxJava: Suppressing Operators"
layout: post
date: 2019-01-29 23:47
description: "RxJava suppressing operators: filter, take, skip, distinct, elementAt for controlling which emissions pass through the chain."
tag:
- ReactiveX
- RxJava
- Java
- Kotlin
blog: true
hidden: true
jemoji:
---

The operators that will suppress emissions that fail to meet a specified criterion are _Suppressing operators_.

## filter()
The `filter()` operator accepts a lambda that qualifies each emission by mapping it to a `Boolean` value, and emissions with `false` will not go forward:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .filter { it.length != 5 }
        .subscribe { println("Received: $it") }
}
```
```
Received: Beta
Received: Epsilon
```

## take()
This operator has two overloads. The first will take a specified number of emissions and then call `onComplete()` after it captures all of them:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .take(3)
        .subscribe { println("Received: $it") }
}
```
```
Received: Alpha
Received: Beta
Received: Gamma
```

The other _overload_ of `take()` will take emissions within a _specific time duration_ and then call `onComplete()`:
```kotlin
fun main() {
    Observable.interval(300, TimeUnit.MILLISECONDS)
        .take(1, TimeUnit.SECONDS)
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(5)
}
```
```
Received: 0
Received: 1
Received: 2
```

There is also a `takeLast()` operator, which will take the last specified number of emissions (or time duration) before the `onComplete()` is called.

## skip()
`skip()` is the opposite of `take()` operator. It will _ignore_ the specified number of emissions and then emit the ones that follow:
```kotlin
fun main() {
    Observable.range(1, 10)
        .skip(7)
        .subscribe { println("Received: $it") }
}
```
```
Received: 8
Received: 9
Received: 10
```
Like the `take()` operator, there is also an _overload_ accepting a _time duration_ and a `skipLast()` operator.

## takeWhile() & takeUntil()
`takeWhile()` operator is a variant of the `take()` operator: _it takes emissions while a condition is true_. Once the condition is not satisfied, `onComplete()` is called:
```kotlin
fun main() {
    Observable.range(1, 10)
        .takeWhile { it < 5 }
        .subscribe { println("Received: $it") }
}
```
```
Received: 1
Received: 2
Received: 3
Received: 4
```

The `takeUntil()` operator is similar to `takeWhile()`, but it accepts another `Observable` as a parameter. It will _keep taking emissions_ until that other `Observable` _pushes_ an emission:
```kotlin
fun main() {
    val observable = Observable.interval(1, TimeUnit.SECONDS)

    // Will start emissions at 300 milliseconds
    Observable.interval(300, TimeUnit.MILLISECONDS)
        .takeUntil(observable) // Receives first emission at 1 sec
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(3)
}
```
```
Received: 0
Received: 1
Received: 2
```

## skipWhile() & skipUntil()
This operator will _keep skipping_ emissions while _the condition is satisfied_. Once the condition no longer qualifies, the emissions will start going through:
```kotlin
fun main() {
    Observable.range(1, 10)
        .skipWhile { it <= 7 }
        .subscribe { println("Received: $it") }
}
```
```
Received: 8
Received: 9
Received: 10
```

The `skipUntil()` operator accepts another `Observable` as an argument but it will _keep skipping_ until the other Observable emits something:
```kotlin
fun main() {
    val observable = Observable.interval(1, TimeUnit.SECONDS)

    // Will start emissions at 300 milliseconds
    Observable.interval(300, TimeUnit.MILLISECONDS)
        .skipUntil(observable) // Receives first emission at 1 sec
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(2)
}
```
```
Received: 3
Received: 4
Received: 5
```

## distinct()
The `distinct()` operator will emit each unique emission and suppress any duplicates that follow. Equality is based on `hashCode()`/`equals()` implementation of the emitted objects:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .map { it.length }
        .distinct()
        .subscribe { println("Received: $it") }
}
```
```
Received: 5
Received: 4
Received: 7
```

It’s possible to add a _lambda_ argument that maps each emission to a key used for equality logic. This allows the emissions, but not the key, to go forward while using the key for distinct logic:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .distinct { it.length }
        .subscribe { println("Received: $it") }
}
```
```
Received: Alpha
Received: Beta
Received: Epsilon
```

## distinctUntilChanged()
This operator function will _ignore duplicate consecutive emissions_. All the duplicates will be ignored until a new value is emitted : 

```kotlin
fun main() {
    Observable.just(1, 1, 1, 2, 2, 3, 3, 2, 1, 1)
        .distinctUntilChanged()
        .subscribe { println("Received: $it") }
}
```
```
Received: 1
Received: 2
Received: 3
Received: 2
Received: 1
```

It’s possible to provide a _lambda_ to map the emissions and use the result as key:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Zeta", "Eta", "Gamma", "Delta")
        .distinctUntilChanged { s -> s.length }
        .subscribe { println("Received: $it") }
}
```
```
Received: Alpha
Received: Beta
Received: Eta
Received: Gamma
```

## elementAt()
It’s possible to get a specific emission by its index specified by a `Long`, starting at 0. When the item is found and emitted, `onComplete()` will be called and dispose of the subscription. 
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Zeta", "Eta", "Gamma", "Delta")
        .elementAt(3)
        .subscribe { println("Received: $it") }
}
```
```
Received: Eta
```

There are other flavours of `elementAt()`:
* `elementAtOrError()`: return a `Single` and will emit an error if an element at that index is not found.
*  `singleElement()` : turn an `Observable` into a `Maybe`, but will produce an error if there is anything beyond one element.
* `firstElement()` and `lastElement()` : return `Maybe` emitting the first or last emission, respectively.
