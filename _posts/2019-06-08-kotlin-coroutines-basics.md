---
title: "Kotlin Coroutines Basics"
layout: post
date: 2019-06-08 14:52
description:
tag:
- Kotlin
- Coroutines
- Asynchrony
blog: true
jemoji:
---

<div class="text-center" markdown="1">
![Kotlin Couroutines][3]{:width="75%"}
<figcaption class="caption">Banner from <em>kotlin blog</em></figcaption>
</div>
<br/>

Kotlin v1.3 was released bringing coroutines for asynchronous programming. This article is a quick introduction to the core features of `kotlinx.coroutines`.

Let’s say the objective is to say hello asynchronously. Lets start with the following very classic code:
```kotlin
fun main() {
    println("Start")

    Thread {
        Thread.sleep(3000L)
        println("Hello")
    }.start()

    println("Done")
}
```
```
Start
Done
Hello
```
What happened within the 3 seconds when the created `Thread` was sleeping? The answer: nothing!  The thread was occupying memory without being used! This is when coroutines the light-weight threads kick in!

## First Coroutine
The following is a basic way to migrate the previous example to use coroutines:
```kotlin
fun main() {
    println("Start")

    // Start a coroutine
    GlobalScope.launch {
        delay(1000L)
        println("Hello")
    }

    Thread.sleep(2000L)
    println("Done")
}
```
```
Start
Done
Hello
```
The coroutine is launched with `launch` _coroutine builder_ in a context of a `CoroutineScope` (in this case `GlobalScope`).
But what are _coroutine builders_ ? _coroutine contexts_ ?  _coroutine scopes_?

## Coroutine Builders
Coroutine builders are simple functions to create a new coroutine; the following are the main ones:
* `launch`:  used for starting a computation that isn’t expected to return a specific result. `launch` _starts_ a coroutine and _returns_ a `Job`, which represents the coroutine. It is possible to wait until it completes by calling `Job.join()`.
* `async`: like `launch` it starts a new coroutine, but returns a `Deferred`* object instead: it stores a computation, but it _defers_ the final result; it _promises_ the result sometime in the_future_.
* `runBlocking`:  used as a bridge between blocking and non-blocking worlds. It works as an adaptor starting the top-level main coroutine and is intended primarily to be used in _main functions_ and in _tests_. 
*  `withContext`: calls the given code with the specified coroutine context, suspends until it completes, and returns the result. An alternative (but more verbose) way to achieve the same thing would be: `launch(context) { … }.join()`.
  
_*_ `Deffered` _is a generic type which extends_ `Job`.

### Building Coroutines
Lets use coroutines builders to improve the previous example by introducing `runBlocking`:
```kotlin
fun main() {
    println("Start")

    // Start a coroutine
    GlobalScope.launch {
        delay(1000L)
        println("Hello")
    }

    runBlocking {
        delay(2000L)
    }
    println("Done")
}
```
It is possible to do better ? Yes ! By moving the `runBlocking`  to wrap the execution of the main function:
```kotlin
fun main() = runBlocking {
    println("Start")

    GlobalScope.launch {
        delay(1000L)
        println("Hello")
    }

    delay(2000L)
    println("Done")
}
```
But wait a minute, the initial goal of having `delay(2000L)` was to wait for the coroutine to finish ! Let’s explicitly wait for it then:
```kotlin
fun main() = runBlocking {
    println("Start")

    val job = GlobalScope.launch {
        delay(1000L)
        println("Hello")
    }

    job.join()
    println("Done")
}
```

## Structured concurrency
In the previous example,  `GlobalScope.launch` has been used to create a top-level “independent” coroutine. Why “top-level” ? Because `GlobalScope`  is used to launch coroutines which are operating on _the whole application lifetime_.
“_Structured concurrency_” is the mechanism providing the structure of coroutines which gives the following benefits:
* The scope is generally responsible for children coroutines, and their lifetime is attached to the lifetime of the scope.
* The scope can automatically cancel children coroutines in case of the operation canceling or revoke.
* The scope automatically waits for completion of all the children coroutines.
  
Let’s apply this to our example:
```kotlin
fun main() = runBlocking {
    println("Start")

    // Start a coroutine (Child coroutine of runBlocking)
    launch { // or `this.launch`.
        delay(1000L)
        println("Hello")
    }
    println("Done")
}
```

### Using the outer scope’s context
At this point, an option may be to move the inner coroutine to a function:
```kotlin
fun main() = runBlocking {
    println("Start")
    hello(this)
    println("Done")
}

fun hello(scope: CoroutineScope) { // or as extension function 
    scope.launch {
        delay(1000L)
        println("Hello")
    }
}
```
This works, but there is a more elegant way to achieve this: using `suspend` and `coroutineScope`
```kotlin
fun main() = runBlocking {
    println("Start")
    hello()
    println("Done")
}

suspend fun hello() = coroutineScope {
    launch {
        delay(1000L)
        println("Hello")
    }
}
```
The new scope created by `coroutineScope` inherits the context from the outer scope.  

## Coroutine Context and Dispatchers
Coroutines always execute in some `CoroutineContext`. The coroutine context is a set of various elements. The main elements are the `Job` of the coroutine and its `CoroutineDispatcher`.

### Dispatchers
`CoroutineContext` _includes_ a `CoroutineDispatcher` that determines what thread or threads the corresponding coroutine uses for its execution. Coroutine dispatcher can confine coroutine execution to a _specific thread_, dispatch it to a _thread pool,_ or let it run _unconfined_.  

Coroutine builders `launch`, `async`  and `withContext` accept an `CoroutineContext` parameter that can be used to explicitly specify the _dispatcher_ for new coroutine (and other context elements).

Here is  various implementations of `CoroutineDispatcher`:
* `Dispatchers.Default`: the default dispatcher, that is used when coroutines are launched in `GlobalScope`. Uses shared background pool of threads,  appropriate for _compute-intensive_ coroutines.
* `Dispatchers.IO`: Uses a shared pool of on-demand created thread. Designed for IO-intensive _blocking_ operations.
* `Dispatchers.Unconfined`: Unrestricted to any specific thread or pool. Can be useful for some really special cases, but should not be used in general code.

```kotlin
fun main() = runBlocking {
    log("Start")
    hello()
    log("Done")
}

private suspend fun hello() = coroutineScope {
    launch {
        // context of the parent, main runBlocking coroutine
        println("[${Thread.currentThread().name}] from parent dispatcher")
    }

    launch(Dispatchers.Default) {
        // will get dispatched to DefaultDispatcher
        println("[${Thread.currentThread().name}] Dispatchers.Default")
    }

    launch(Dispatchers.IO) {
        // will get dispatched to IO
        println("[${Thread.currentThread().name}] Dispatchers.IO")
    }

    launch(Dispatchers.Unconfined) {
        // not confined -- will work with main thread
        println("[${Thread.currentThread().name}] Dispatchers.Unconfined")
    }
}
```
```
[main] Start
[DefaultDispatcher-worker-2] Dispatchers.Default
[DefaultDispatcher-worker-1] Dispatchers.IO
[main] Dispatchers.Unconfined
[main] from parent dispatcher
[main] Done
```
(`Dispatcher.IO` _dispatcher shares threads with_ `Dispatchers.Default`)

## Coroutine Scope
Each coroutine run inside a _scope_. A scope can be application wide or specific. But why this is needed ?  
Contexts and jobs lifecycles are often tied to objects who are not coroutines (_Android activities for example_). Managing coroutines lifecycles can be done by keeping references and handling them manually. However, a better approach is to use `CoroutineScope`.  
Best way to create a `CoroutineScope` is using:
* `CoroutineScope()`: creates a general-purpose scope.
* `MainScope()`: creates scope for UI applications and uses `Dispatchers.Main` as default dispatcher.


```kotlin
fun main() {
    println("Start")
    val activity = Activity()
    activity.doLotOfThings()
    Thread.sleep(2000)
    activity.destroy()
    println("Done")
}

private class Activity {
    private val mainScope = CoroutineScope(Dispatchers.Default)

    fun doLotOfThings() {
        mainScope.launch {
            repeat(1_000) {
                delay(400)
                doThing()
            }
        }
    }

    private fun doThing() {
        println("[${Thread.currentThread().name}] doing something...")
    }

    fun destroy() {
        mainScope.cancel()
    }
}
```
```
Start
[DefaultDispatcher-worker-1] doing something...
[DefaultDispatcher-worker-3] doing something...
[DefaultDispatcher-worker-2] doing something...
[DefaultDispatcher-worker-2] doing something...
Done
```
Only the first four coroutines had printed a message and the others were cancelled by a single invocation of `CoroutineScope.cancel()` in `Activity.destroy()`.

Alternatively, we can implement `CoroutineScope` interface in this `Activity` class, and use delegation with default factory function:
```kotlin
fun main() {
    println("Start")
    val activity = Activity()
    activity.doLotOfThings()
    Thread.sleep(2000)
    activity.destroy()
    println("Done")
}

class Activity : CoroutineScope by CoroutineScope(Dispatchers.Default) {

    fun doLotOfThings() {
        launch {
            repeat(1_000) {
                delay(400)
                doThing()
            }
        }
    }

    private fun doThing() {
        println("[${Thread.currentThread().name}] doing something...")
    }

    fun destroy() {
        cancel()
    }
}
```

## Tips
* `-Dkotlinx.coroutines.debug` as VM parameter for debugging.
* `CoroutineName` as parameter to coroutine builders for debugging purposes.
* Combining context element can be using `+` operator: `launch(Dispatchers.Default + CoroutineName("test")) { … }`.

## Sources
* [Coroutines Guide · Kotlin/kotlinx.corou tines · GitHub][1]
* [Introduction to Coroutines and Channels · Kotlin Playground][2]

[1]: https://github.com/Kotlin/kotlinx.coroutines/blob/master/coroutines-guide.md
[2]: https://play.kotlinlang.org/hands-on/Introduction%20to%20Coroutines%20and%20Channels/01_Introduction
[3]: {{ site.url }}/assets/images/blog/kotlin_coroutines_banner.png
