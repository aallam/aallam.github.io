---
title: "RxJava: Transforming Operators"
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

Transforming operators are a series of operators in an `Observable` chain to transform emissions.

## map()
The `map()` operator will transform a `T` emission for a given `Observable<T>`  into an `R` emission using _the provided lambda_:

```kotlin
fun main() {
    val dateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")
    Observable.just("01/01/2019", "31/03/2020", "07/07/2018")
        .map { LocalDate.parse(it, dateTimeFormatter) }
        .subscribe { println("Received: $it") }
}
```
```
Received: 2019-01-01
Received: 2020-03-31
Received: 2018-07-07
```
The `map()` operator in this previous example transforms a `String` to a `LocalDate` object.  
The `map()` operator does a one-to-one conversion. To do a one-to-many conversion `flatMap()` or `concatMap()` are more appropriate.

## cast()
This operator is to cast each emission to a different type:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma")
        .cast(CharSequence::class.java)
        .subscribe { println("Received: $it") }
}
```
The `Observer` will receive `CharSequence` emissions.

## startWith()
The `startWith()` operator allows to insert a `T` emission that precedes all the other emissions in a given `Observable<T>`:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma")
        .startWith("GREEK ALPHABET:")
        .subscribe { println("Received: $it") }
}
```
```
Received: GREEK ALPHABET:
Received: Alpha
Received: Beta
Received: Gamma
```

There is also the operator `startWithArray()` : to start with more than one emission, it accepts `vararg` parameter:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma")
        .startWithArray("GREEK ALPHABET:", "---------------")
        .subscribe { println("Received: $it") }
}
```
```
Received: GREEK ALPHABET:
Received: ---------------
Received: Alpha
Received: Beta
Received: Gamma
```

The operators `concat()` and `concatWith()` are good to have an entire emissions of `Observable` to precede emissions of another `Observable`.

## defaultIfEmpty()
The operator `defaultIfEmpty()` is to get a single emission if a given `Observable` comes out empty:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .filter { it.length < 3 }
        .defaultIfEmpty("None")
        .subscribe { println("Received: $it") }
}
```
```
Received: None
```

## switchIfEmpty()
`switchIfEmpty()` specifies a _different_ `Observable` to emit values from if the source `Observable` _is empty_:
```kotlin
fun main() {
    val altObservable = Observable.just("Zeta", "Eta", "Theta")
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
        .filter { it.startsWith("Z") }
        .switchIfEmpty(altObservable)
        .subscribe { i -> println("RECEIVED: $i") }
} 
```
```
Received: Zeta
Received: Eta
Received: Theta
```

## sorted()
In case of a _finite_ `Observable<T>` emitting items that implement `Comparable<T>`,  the operator `sorted()` can sort the emissions. Internally, it will _collect all the emissions_ and re-emit them sorted:
```kotlin
fun main() {
    Observable.just(4, 3, 1, 2, 1)
        .sorted()
        .subscribe { print("$it ") }
}
```
```
1 1 2 3 4 
```

It’s possible to provide a `Comparator` (as object or lambda) to specify the sorting criterion:
```kotlin
fun main() {
    Observable.just(4, 3, 1, 2, 1)
        .sorted(Comparator.reverseOrder())
        .subscribe { print("$it ") }
}
```
```
4 3 2 1 1 
```

## delay()
`delay()` operator postpones emissions, holds any received emissions and delay each one for the specified time period:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma")
        .delay(3, TimeUnit.SECONDS)
        .subscribe { println("Received: $it") }

    TimeUnit.SECONDS.sleep(5)
}
```
```
Received: Alpha
Received: Beta
Received: Gamma
```
It’s possible to pass another `Observable` as argument  to `delay()`, and it will delay emissions until that other `Observable` emits something.

## repeat()
The `repeat()` operator will repeat subscription upstream after `onComplete()` a specified number of times. If no number is provided, it will repeat infinitely, forever re-subscribing after every `onComplete()`
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Epsilon")
        .repeat(2)
        .subscribe { println("Received: $it") }
}
```
```
Received: Alpha
Received: Beta
Received: Epsilon
Received: Alpha
Received: Beta
Received: Epsilon
```
There is also a `repeatUntil()` operator to keep repeating until the passed `Boolean` supplier yields `false`.

## scan()
The `scan()` operator is a rolling aggregator. It will emit after each upstream emission the new accumulation:
```kotlin
fun main() {
    Observable.just(1, 1, 2, 3, 5)
        .scan { accumulator, next -> accumulator + next }
        .subscribe { println("Received: $it") }
}
```
```
Received: 1
Received: 2
Received: 4
Received: 7
Received: 12
```
It’s possible to provide an _initial value_ for the first argument and aggregate into a different type than what is being emitted.
