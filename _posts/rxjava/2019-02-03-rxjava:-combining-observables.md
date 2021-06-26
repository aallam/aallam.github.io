---
title: "RxJava: Combining Observables"
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

## Merging
Merges multiple Observables to one `Observable`.
The merged Observables can be cold or hot, and there is no rule about the ordering between the merged Observables.
Operators:
* `Observable.merge()`
* `Observable.mergeArray()`
* `mergeWith()`
* …

```kotlin
fun main() {
    val letters1 = Observable.just("Alpha", "Beta")
    val letters2 = Observable.just("Gamma", "Delta")
    val letters3 = Observable.just("Epsilon", "Digamma")
    val symbols1 = Observable.just("α", "β")
    val symbols2 = Observable.just("γ", "δ")
    val symbols3 = Observable.just("ε", "ϝ")
    val list = listOf(letters1, letters2, letters3, symbols1, symbols2, symbols3)
    Observable.merge(list)
        .subscribe {i ->println("Received: $i") }
}
```
```
Received: Alpha
Received: Beta
Received: Gamma
Received: Delta
Received: Epsilon
Received: Digamma
Received: α
Received: β
Received: γ
Received: δ
Received: ε
Received: ϝ
```

### flatMap()
This operator maps emissions to Observables (cold or hot) (the new `Observable` can empty or emit one or many emissions).
Operators:
* `flatMap()`
* `flatMapIterable()`
* `flatMapSingle()`
* …

```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .flatMap { Observable.fromArray(*it.toCharArray().toTypedArray()) } // String to Array<Char>
        .subscribe { i -> println("Received: $i") }
}
```
```
Received: A
Received: l
Received: p
Received: h
Received: a
Received: B
Received: e
...
```

## Concatenation
Concatenation will fire elements of each provided Observable sequentially and in the order specified. It will not move on to the next Observable until the current one calls `onComplete()`.
Concatenation should be preferred when order matters, otherwise, prefer merging instead.
Operators:
* `Observable.concat()`
* `Observable.concatArray()`
* `concatWith()`
* …

```kotlin
fun main() {
    val letters = Observable.just("Alpha", "Beta", "Gamma")
    val symbols = Observable.just("α", "β", "γ")
    Observable.concat(letters, symbols)
        .subscribe { i -> println("Received: $i") }
}
```
```
Received: Alpha
Received: Beta
Received: Gamma
Received: α
Received: β
Received: γ
```

### concatMap
This operator behaves almost like `flatMap()` with the difference that it cares about ordering:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .concatMap { Observable.fromArray(*it.toCharArray().toTypedArray()) } // String to Array<Char>
        .subscribe { i -> println("Received: $i") }
}
```
```
Received: A
Received: l
Received: p
Received: h
Received: a
Received: B
Received: e
...
```

## Ambiguous
The `Observable.amb()` factory (**amb**stands for **ambiguous**) accepts an `Iterable<Observable<T>>` and emit the emissions of _the first `Observable` that emits_, while the others are disposed of.
Operators:
* `Observable.amb()`
* `Observable.ambArray()`
* `ambWith()`

```kotlin
fun main() {
    // Emit every 1s
    val source1 = Observable.interval(1, TimeUnit.SECONDS)
        .map { it + 1 }
        .map { "Source1: $it" }

    // Emit every 500ms.
    val source2 = Observable.interval(500, TimeUnit.MILLISECONDS)
        .map { (it + 1) * 500 }
        .map { "Source2: $it" }

    val sources = listOf(source1, source2)
    Observable.amb(sources)
        .subscribe { i -> println("Received: $i") }

    TimeUnit.SECONDS.sleep(3)
}
```
```
Received: Source2: 500
Received: Source2: 1000
Received: Source2: 1500
Received: Source2: 2000
Received: Source2: 2500
Received: Source2: 3000
```

## Zipping
`Zip` takes an emissions from each `Observable` source and combine it into a single emission.
Operators:
* `Observable.zip()`
* `Observable.zipArray()`
* `zipWith()`
* …

```kotlin
fun main() {
    val symbols = Observable.just('α', 'β', 'γ')
    val letters = Observable.just("Alpha", "Beta", "Gamma", "Delta")
    Observable.zip(symbols, letters, BiFunction { s: Char, l: String -> s to l }) //RxJava BiFunction
        .subscribe { println("Receive: $it") }
}
```
```
Receive: (α, Alpha)
Receive: (β, Beta)
Receive: (γ, Gamma)
```

## Combine Latest
When one source fires, it couples with the latest emissions from the others:
```kotlin
fun main() {
    val source1 = Observable.interval(500, TimeUnit.MILLISECONDS)
    val source2 = Observable.interval(1, TimeUnit.SECONDS)
    Observable.combineLatest(source1, source2, BiFunction { s1: Long, s2: Long -> s1 to s2 }) //RxJava BiFunction
        .subscribe { println("Receive: $it") }
    TimeUnit.SECONDS.sleep(3)
}
```
```
Receive: (1, 0)
Receive: (2, 0)
Receive: (2, 1)
Receive: (3, 1)
Receive: (4, 1)
Receive: (5, 1)
Receive: (5, 2)
```

### withLatestFrom()
It will map each  emission with the latest values from other Observables and combine them (only take _one_emission from each): 
```kotlin
fun main() {
    val source1 = Observable.interval(500, TimeUnit.MILLISECONDS)
    val source2 = Observable.interval(1, TimeUnit.SECONDS)
    source2.withLatestFrom(source1, BiFunction { s1: Long, s2: Long -> s1 to s2 })
        .subscribe { println("Receive: $it") }
    TimeUnit.SECONDS.sleep(3)
}
```
```
Receive: (0, 1)
Receive: (1, 2)
Receive: (2, 4)
```

## Grouping
Group emissions by a specified key into separate Observables:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .groupBy { it.length }
        .flatMapSingle { it.toList() }
        .subscribe { println("Receive: $it") }
}
```
```
Receive: [Beta]
Receive: [Alpha, Gamma, Delta]
Receive: [Epsilon]
```
