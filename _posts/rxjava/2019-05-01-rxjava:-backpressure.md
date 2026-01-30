---
title: "RxJava: Backpressure"
layout: post
date: 2019-05-01 14:18
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

In a reactive world, there is the case where a source is producing emissions _faster_ than the downstream can _process_ them. A solution of such case is to proactively make _the source slow down_ in the first place and emit at a pace that agrees with the downstream operations. This is known as **backpressure** or flow control. 

Lets take the following example:
```kotlin
class Item(val id: Int) {
    init {
        println("Constructing item $id")
    }
}
```
```kotlin
fun main() {
    Observable.range(1, 999_999_999)
        .map(::Item)
        .subscribe {
            TimeUnit.MILLISECONDS.sleep(50)
            println("Received item ${it.id}")
        }
}
```
The output is the following:
```
Constructing item 1
Received item 1
Constructing item 2
Received item 2
Constructing item 3
Received item 3
Constructing item 4
Received item 4
...
```
The work  is done in a single thread, which explains the synchronous processing of each emission from the source all the way to the terminal `Observer`. 
Now let’s switch threads, here is what happens:
```kotlin
fun main() {
    Observable.range(1, 999_999_999)
        .map(::Item)
        .observeOn(Schedulers.io())
        .subscribe {
            TimeUnit.MILLISECONDS.sleep(50)
            println("Received item ${it.id}")
        }

    TimeUnit.SECONDS.sleep(Long.MAX_VALUE)
}
```
```
...
Constructing Item 3486554
Constructing Item 3486555
Constructing Item 3486556
Received item 259
Constructing Item 3486557
Constructing Item 3486558
Constructing Item 3486559
...
```
This previous output is just a section of the console output. 
When Item **3486556** is created, the `Observer` is still processing the Item **259**! The emissions are being pushed much _faster_ than the `Observer` can _process_ them. This could lead to many problems like `OutOfMemoryError` exceptions. 
