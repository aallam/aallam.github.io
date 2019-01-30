---
title: "RxJava: Collection Operators"
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

It’s possible to consider Collection operators as a reducing operators since they _consolidate emissions into a single one_. Collection operators will accumulate all emissions into a collection (`List`, `map`, `set`…).

## toList()
For a given `Observable<T>`, this operator will collect incoming emissions into a `List<T>` and then push it as a single emission (`Single<List<T>>`):
```kotlin
fun main() {
    Observable.just(1, 2, 3, 4)
        .toList() // Receives first emission at 1 sec
        .subscribe { l -> println("Received: $l") }
} 
```
```
Received: [1, 2, 3, 4]
```
It’s possible to specify the `List<T>` implementation:
```kotlin
fun main() {
    Observable.just(1, 2, 3, 4)
        .toList { CopyOnWriteArrayList<Int>() }
        .subscribe { l -> println("Received: ${l.javaClass}") }
}
```
```
Received: class java.util.concurrent.CopyOnWriteArrayList
```

## toSortedList()
This operator will collect the emissions into a `List` that sorts the items naturally based on their `Comparator` implementation:
```kotlin
fun main() {
    Observable.just("Beta", "Alpha", "Delta", "Gamma", "Zeta", "Eta")
        .toSortedList()
        .subscribe { l -> println("Received: $l") }
}
```
```
Received: [Alpha, Beta, Delta, Eta, Gamma, Zeta]
```
It’s possible to provide a `Comparator` as an argument to apply a different sorting logic. 

## toMap()
This operator will collect emissions into `Map<K,T>` for a given `Observable<T>`, where `K` is the key type derived of a lambda `Function<T,K>` :
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta")
        .toMap { s -> s[0] }
        .subscribe { m -> println("Received: $m") }
}
```
```
Received: {A=Alpha, B=Beta, D=Delta, E=Epsilon, G=Gamma}
```

It’s possible to yield a _different value_ other than the emission to associate with the key _by providing a second lambda_ argument that maps each emission to a different value:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta")
        .toMap({ s -> s[0] }, { s -> s.length })
        .subscribe { m -> println("Received: $m") }
}
```
```
Received: {A=5, B=4, D=5, E=7, G=5, Z=4}
```

By default, `toMap()` will use `HashMap`. It’s possible to provide a _third lambda_ argument that provides a _different map_ implementation : 
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta")
        .toMap({ s -> s[0] }, { s -> s.length }, { ConcurrentHashMap() })
        .subscribe { m -> println("Received: ${m.javaClass}") }
}
```
```
Received: class java.util.concurrent.ConcurrentHashMap
```

## toMultiMap()
For the  operator `toMap()` , if a key maps to multiple emissions, the last emission for that key is going to replace subsequent ones:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta")
        .toMap { s -> s.length }
        .subscribe { m -> println("Received: $m") }
}
```
```
Received: {4=Zeta, 5=Delta, 7=Epsilon}
```

However, it’s possible to map to the same key multiple values using `toMultimap()`:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta")
        .toMultimap { s -> s.length }
        .subscribe { m -> println("Received: $m") }
}
```
```
Received: {4=[Beta, Zeta], 5=[Alpha, Gamma, Delta], 7=[Epsilon]}
```

## collect()
When no collector has what is needed, it’s possible to use the `collect()` operator to specify a different type to collect items into:
```kotlin
fun main() {
    Observable.just("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta")
        .collect({ HashSet<String>() }, { s, v -> s.add(v) })
        .subscribe { s -> println("Received: ${s.javaClass} : $s") }
}
```
```
Received: class java.util.HashSet : [Gamma, Zeta, Delta, Alpha, Epsilon, Beta]
```
When putting emissions into a mutable object seed, it’s better to use `collect()` instead of `reduce()`. 
