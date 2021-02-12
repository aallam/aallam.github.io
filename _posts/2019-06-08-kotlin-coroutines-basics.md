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

<div class="text-center">
   <img class="image" src="{{ site.url }}/assets/images/blog/kotlin_coroutines_banner.png" alt="Kotlin Couroutines" width="75%"/>
   <figcaption class="caption">Banner from <em>kotlin blog</em></figcaption>
</div>
<br/>

Kotlin v1.3 was released, bringing coroutines for asynchronous programming. This article is a quick introduction to the core features of `kotlinx.coroutines`.

Let’s say the objective is to say hello asynchronously. Let's start with the following classic code snippet:
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
What happened within the 3 seconds when the created `Thread` was sleeping? The answer: nothing! The thread was occupying memory without being used! This is when coroutines the light-weight threads kick in!

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
But what are _coroutine builders_? _coroutine contexts_?  _coroutine scopes_?

## Coroutine Builders
Coroutine builders are simple functions to create a new coroutine; the following are the main ones:
* `launch`:  used for starting a computation that isn’t expected to return a specific result. `launch` _starts_ a coroutine and _returns_ a `Job`, which represents the coroutine. It is possible to wait until it completes by calling `Job.join()`.
* `async`: like `launch` it starts a new coroutine but returns a `Deferred`* object instead: it stores a computation, but it _defers_ the final result; it _promises_ the result sometime in the_future_.
* `runBlocking`: used as a bridge between blocking and non-blocking worlds. It works as an adaptor starting the top-level main coroutine and is intended primarily to be used in _main functions_ and _tests_. 
*  `withContext`: calls the given code with the specified coroutine context, suspends until it completes, and returns the result. An alternative (but more verbose) way to achieve the same thing would be: `launch(context) { … }.join()`.
  
_*_ `Deffered` _is a generic type which extends_ `Job`.

### Building Coroutines
Let's use coroutines builders to improve the previous example by introducing `runBlocking`:
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
It is possible to do better? Yes! By moving the `runBlocking`  to wrap the execution of the main function:
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
But wait a minute, the initial goal of having `delay(2000L)` was to wait for the coroutine to finish! Let’s explicitly wait for it then:
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
In the previous example,  `GlobalScope.launch` has been used to create a top-level “independent” coroutine. Why “top-level”? Because `GlobalScope`  is used to launch coroutines that are operating on _the whole application lifetime_.
“_Structured concurrency_” is the mechanism providing the structure of coroutines which gives the following benefits:
* The scope is generally responsible for children coroutines, and their lifetime is attached to the lifetime of the scope.
* The scope can automatically cancel children coroutines in case of the operation canceling or revoke.
* The scope automatically waits for completion of all the children coroutines.
  
<div class="text-center">
   <img class="image" src="{{ site.url }}/assets/images/blog/job_lifecycle.svg" alt="Job lifecycle" width="75%"/>
   <figcaption class="caption">Coroutine (Job) Lifecycle</figcaption>
</div>

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
```
[main] Start
[DefaultDispatcher-worker-1] Hello1
[main] Done
```
The new scope created by `coroutineScope` inherits the context from the outer scope.

### CoroutineScope extension vs suspend
The previous example (using `suspend`) can be rewritten using `CoroutineScope` extension:
```kotlin
fun main() = runBlocking {
    log("Start")
    hello()  // not suspendable, no waiting!
    log("Done")
}


private fun CoroutineScope.hello() = launch(Dispatchers.Default) {
    delay(1000L)
    log("Hello1")
}
```
```
[main] Start
[main] Done
[DefaultDispatcher-worker-1] Hello1
```
The output is not the same! why? Here are the rules:
* `suspend`: function do something long and waits for it to complete without blocking.
* Extension of `CoroutineScope`: function launch new coroutines and quickly return without waiting for them.

## Coroutine Context and Dispatchers
Coroutines always execute in some `CoroutineContext`. The coroutine context is a set of various elements. The main elements are the `Job` of the coroutine and its `CoroutineDispatcher`.

### Dispatchers
`CoroutineContext` _includes_ a `CoroutineDispatcher` that determines what thread or threads the corresponding coroutine uses for its execution. Coroutine dispatcher can confine coroutine execution to a _specific thread_, dispatch it to a _thread pool,_ or let it run _unconfined_.  

Coroutine builders `launch`, `async`  and `withContext` accept a `CoroutineContext` parameter that can be used to explicitly specify the _dispatcher_ for new coroutine (and other context elements).

Here are various implementations of `CoroutineDispatcher`:
* `Dispatchers.Default`: the default dispatcher, that is used when coroutines are launched in `GlobalScope`. Uses shared background pool of threads,  appropriate for _compute-intensive_ coroutines.
* `Dispatchers.IO`: Uses a shared pool of on-demand created threads. Designed for IO-intensive _blocking_ operations.
* `Dispatchers.Unconfined`: Unrestricted to any specific thread or pool. Can be useful for some special cases, but should not be used in general code.

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
Each coroutine runs inside a _scope_. A scope can be application-wide or specific.
Contexts and jobs lifecycles are often tied to objects who are not coroutines (_Android activities for example_). Managing coroutines lifecycles can be done by keeping references and handling them manually. However, a better approach is to use `CoroutineScope`.  
The best way to create a `CoroutineScope` is using:
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
Only the first four coroutines had printed a message and the others were canceled by a single invocation of `CoroutineScope.cancel()` in `Activity.destroy()`.

Alternatively, we can implement `CoroutineScope` interface in this `Activity` class, and use delegation with the default factory function:
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

## Conclusion
Coroutines are a very good way to achieve [asynchronous programming with kotlin][4].  
The following is an (over)simplified diagram of coroutines structure while keeping in mind each `Element` *is* a `CoroutineContext` by its own:

<div class="text-center">
   <img class="image" src="{{ site.url }}/assets/images/blog/coroutines_structure.svg" alt="coroutines structure" width="50%"/>
   <figcaption class="caption">(over)simplified coroutines structure</figcaption>
</div>

For more advanced topics like [composing suspending functions][4], [exception handling, and supervision][5], the main [coroutines guide][1] is the way to go!

## Tips
* `-Dkotlinx.coroutines.debug` as VM parameter for debugging.
* `CoroutineName` as a parameter to coroutine builders for debugging purposes.
* Combining context element can be using `+` operator: `launch(Dispatchers.Default + CoroutineName("test")) { … }`.

## Sources
* [Coroutines Guide][1]
* [Introduction to Coroutines and Channels][2]
* [Kotlin Coroutines in Practice by Roman Elizarov][3]
* [KEEP Kotlin Coroutines][6]

[1]: https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/coroutines-guide.md
[2]: https://play.kotlinlang.org/hands-on/Introduction%20to%20Coroutines%20and%20Channels/01_Introduction
[3]: https://www.youtube.com/watch?v=a3agLJQ6vt8
[4]: https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/composing-suspending-functions.md
[5]: https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/exception-handling.md
[6]: https://github.com/Kotlin/KEEP/blob/master/proposals/coroutines.md
