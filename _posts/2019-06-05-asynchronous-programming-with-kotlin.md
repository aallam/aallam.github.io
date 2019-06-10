---
title: "Asynchronous Programming with Kotlin"
layout: post
date: 2019-06-05 21:06
description:
tag:
- Kotlin
- Coroutines
- Asynchrony
blog: true
jemoji:
---

<div class="text-center">
   <img class="image" src="{{ site.url }}/assets/images/blog/intro_coroutines_header.gif" alt="Kotlin Couroutines" width="75%"/>
   <figcaption class="caption">Banner from <em>kotlin blog</em></figcaption>
</div>
<br/>
  
  
Kotlin coroutines are a way of doing “asynchronous or non-blocking programming”, but what does it mean to be “asynchronous” and “non-blocking” ?

## Asynchrony, Concurrency and Parrallelism
To understand Asynchrony, lets define it along with other terms used in the same context: Concurrency and Parallellism:

### Asynchrony
A simple definition of asynchrony is the following:

> “Asynchrony, in computer programming, refers to the occurrence of events independent of the main program flow and ways to deal with such events”    
> — [Wikipedia](https://en.wikipedia.org/wiki/Asynchrony_(computer_programming))    

Asynchrony, is a programming model where a program starts some tasks, without waiting/blocking for the tasks results. The program continues his work until receiving a signal that the results are available.

### Concurrency
> In programming, concurrency is the _composition_ of independently executing processes (…), [and] dealing _with_ lots of things at once (…).    
> — [Rob Pike](https://blog.golang.org/concurrency-is-not-parallelism)     

Concurrency is about composition: handling multiple tasks being in progress at the same time, but not necessary simultaneously or with specific order. 

### Parallellism
> Parallel computing is a type of computation in which many calculations or the execution of processes are carried out simultaneously    
> — [Wikipedia](https://en.wikipedia.org/wiki/Parallel_computing)    

Parallelism, often mistakenly used for concurrency,  is about simultaneous execution of multiple tasks.

> In programming, (…) parallelism is the simultaneous _execution_ of (possibly related) computations. , [and] _doing_ lots of things at once (…).    
> — [Rob Pike](https://blog.golang.org/concurrency-is-not-parallelism)     

## The problematic
Now that we have defined asynchrony, what is the problem we are trying to solve ? 
Lets consider a simple web-application that:
* Receives request from a client.
* Reads a local file.
* Uploads the file to some server.
* Returns back to the client the URL of the uploaded file.

The picture below shows the application might work in the single-thread mode:
<div class="text-center">
   <img class="image" src="{{ site.url }}/assets/images/blog/intro_coroutines_request.png" alt="Single-thread request handling"/>
</div>
This only works for a single request, when working thread is busy handling a request, it won’t be able to respond to another request in the same time!  

#### Thread by request
A solution might be to have a thread for each request! however, thread creation is expensive and this approach has a limit: number of thread OS can manage concurrently!  

#### Thread Pool
What about using thread pools? A limit here is once all the threads are busy, each new request will have to wait until a thread is available.  

#### Yield and Continue
If a thread is doing nothing but waiting for a I/O operation (file or network), why not just to re-use it? for this to work, we need each request to **yield** the thread to another request instead of keeping the thread and waiting, then **continue** later when the waiting is done. 
<div class="text-center">
   <img class="image" src="{{ site.url }}/assets/images/blog/intro_coroutines_yield_continue.png" alt="Coroutine Yield and Continue handling"/>
</div>
Each function should split into **chunks**, **release** the thread after running a chunk, and **continue** the next chunk once the result it needs is ready. The functions are *cooperating* to use thread effectively and thus approach is called *cooperative* or *non-preemptive* multitasking. This is exactly what coroutines are about!
  
For further understanding, please read this excellent [article][3] and check the sources section below.

## ReactiveX and Coroutines
Rx and Kotlin coroutines are often being compared. The following citation is an excellent answer to this comparaison:
>(…) RxKotlin does not use coroutines yet; the reason is quite simple–both coroutines and Schedulers in RxKotlin share nearly the same internal architecture.    
> — [Reactive Programming in Kotlin][4]
  
In other terms: coroutines and Rx are simply two different layers of abstraction.

- - - -

## Sources
* [Coroutines Guide· GitHub](https://github.com/Kotlin/kotlinx.coroutines/blob/master/coroutines-guide.md)
* [Coroutines in Kotlin · Code for glory](https://blog.alexnesterov.com/post/coroutines/)
* [Kotlin Coroutines Concurrency · Kotlin Expertise Blog](https://kotlinexpertise.com/kotlin-coroutines-concurrency/)

[3]: https://blog.alexnesterov.com/post/coroutines/
[4]: https://www.packtpub.com/application-development/reactive-programming-kotlin
