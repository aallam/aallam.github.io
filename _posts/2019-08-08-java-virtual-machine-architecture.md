---
title: "JVM Architecture"
layout: post
date: 2019-08-08 16:16
description: "Complete guide to Java Virtual Machine architecture: class loading, memory areas, execution engine, JIT compiler, and garbage collection explained."
image: /assets/images/blog/JVM.png
tag:
- Java
- JVM
blog: true
jemoji:
---

<div class="text-center" markdown="1">
![Java][0]{:width="50%"}
</div>

This article describes the Java 8 JVM specification and the Java 8 HotSpot implementation. Other JVMs can make different implementation choices.

Java source files become portable bytecode when `javac` compiles them. A JVM loads the resulting `.class` files and executes their instructions. HotSpot can interpret bytecode or compile frequently used code into native machine code.

The [JVM specification](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-2.html) defines an abstract machine. It leaves memory layout, garbage collection, and native-code optimization to implementations.

<div class="text-center" markdown="1">
![JVM Architecture][1]{:width="75%"}
<figcaption class="caption">Java 8 JVM architecture overview. The diagram illustrates an implementation. The specification does not require this layout.</figcaption>
</div>

## 1. Class Loader Subsystem

A class must be loaded, linked, and initialized before certain uses. These stages are distinct. Loading can also happen before a class is first used.

### 1.1. Loading

In Java 8 HotSpot, class loaders find class definitions and create their runtime representation:

* The **bootstrap loader** loads core Java classes, commonly from `rt.jar` in a Java 8 installation.
* The **extension loader** searches extension directories after delegating to its parent.
* The **application loader** searches the application class path after delegating to its parent.

You can also define a custom class loader. Parent delegation is the usual pattern, but custom loaders can choose different behavior.

<div class="text-center" markdown="1">
![Java Class Loaders][3]
<figcaption class="caption">Typical Java 8 HotSpot class-loader hierarchy.</figcaption>
</div>

### 1.2. Linking

**Verification** checks that a class file follows the format and bytecode rules. Invalid bytecode can cause a `VerifyError`.

**Preparation** creates static fields with default values. It does not execute their Java initializers.

**Resolution** turns symbolic references into runtime references. A JVM may resolve a reference when it first needs it, rather than resolving every reference during initial linking.

### 1.3. Initialization

Initialization runs the class or interface initialization method, named `<clinit>` in bytecode. The compiler combines static field initializers and `static` blocks into this method. For example, `static int count = 42;` assigns `42` during initialization, after preparation first assigns `0`.

Creating an instance, invoking a static method, or reading or writing a nonconstant static field can trigger class initialization. A class is initialized before its first instance is constructed. Instance field initializers and constructors run for each new object. `<clinit>` runs once per class initialization. Compile-time constant reads can avoid initialization.

The JVM coordinates initialization across threads. See the [initialization rules](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html#jvms-5.5) for precise triggers and ordering.

## 2. Runtime Data Areas

The specification defines shared and per-thread data areas. It does not prescribe their physical layout.

### 2.1 Method Area (Shared)

The method area holds per-class structures, including the runtime constant pool, field and method data, and method code. All JVM threads share it.

**Metaspace** is HotSpot's Java 8 implementation choice for much class metadata. It uses native memory. Do not treat Metaspace as a second method area required by the specification. The exact placement of static field values is an implementation detail.

### 2.2 Heap Area (Shared)

The heap holds class instances and arrays. All JVM threads share it. Each instance has its own instance fields. A class has one set of static fields.

### 2.3. Stack Area (Per thread)

Each JVM thread has its own JVM stack. A method call creates a frame with local variables, an operand stack, and information needed for return and dynamic linking. The frame disappears when the call completes normally or abruptly.

<div class="text-center" markdown="1">
![JVM Stack Configuration][2]
</div>

A stack can have a fixed or dynamic size. Excessive call depth can cause `StackOverflowError`. A JVM can throw `OutOfMemoryError` if it cannot create or expand a stack.

### 2.4. PC Registers  (Per thread)

Each JVM thread has a program-counter register. For a nonnative method, it identifies the current JVM instruction. Its value is undefined while the thread executes a native method.

### 2.5. Native Method Stack (Per thread)

An implementation can use native method stacks for native calls. The specification does not require one operating-system thread or one separate native stack for every Java thread. Java 8 HotSpot commonly maps Java threads to native threads.

## 3. Execution Engine

The JVM executes bytecode instructions using these runtime data areas. The specification defines instruction behavior, while HotSpot chooses how to run it.

### 3.1. Interpreter

HotSpot can interpret bytecode as a method runs. Interpretation avoids an initial compilation cost, but repeated execution can benefit from compiled code.

### 3.2. Just-In-Time (JIT) Compiler

HotSpot profiles running code and compiles selected methods or loops into native code. Compilation has a cost, so HotSpot makes adaptive decisions based on observed execution. Compiled code can later be replaced or deoptimized when assumptions change.

This is an implementation strategy, not a requirement that every JVM use a JIT compiler. Interpretation and compilation have different startup and steady-state costs. Neither makes Java inherently slow.

### 3.3. Garbage Collector

A garbage collector traces references from roots, such as live stack references and static fields. It can reclaim an object when no root can reach it. Two objects that refer only to each other can both be reclaimed if no root reaches their cycle.

The JVM specification leaves the collection algorithm to the implementation. HotSpot's collectors differ in pause times, throughput, and memory use.

## 4. Java Native Interface (JNI)

JNI lets Java code call native libraries and lets native code interact with the JVM. Native code can have platform-specific behavior and needs its own safety checks.

## 5. Native Method Libraries

Native libraries contain platform-specific functions, often written in C or C++. JNI is one way to call them from Java.

## 6. JVM Threads

Application threads execute Java code. The `main` thread starts the program's `main` method, but other application threads need not be created directly by it. A thread pool worker, for example, can create another thread.

Java 8 HotSpot also uses internal threads for work such as compilation and garbage collection. Its exact thread names and counts depend on configuration and collector. The JVM specification does not require the same internal threads in every implementation.

## 7. Conclusion

`javac` compiles source into bytecode. A Java 8 JVM loads and verifies that bytecode, manages runtime data, and executes instructions. HotSpot combines interpretation, JIT compilation, and garbage collection to balance startup, throughput, pauses, and memory use.

## 8. Useful Commands

* `javac`: compile Java source files.
* `javap -c ClassName`: inspect bytecode instructions.
* `jps`: list Java processes visible to the tool.
* `jcmd`: list visible Java processes and send diagnostic commands.
* `jcmd [PID] help`: list commands supported by that JVM.
* `jcmd [PID] GC.heap_dump [PATH]`: write a heap dump.
* `jcmd [PID] Thread.print`: print thread stacks.
* `-XX:+PrintCompilation`: log HotSpot compilation activity.
* `-XX:+PrintInlining`: log HotSpot inlining decisions when diagnostic options permit it.

These commands and `-XX` options describe the Java 8 HotSpot toolchain. Availability can vary by JDK build.

## 9. Sources

* [Java 8 JVM specification: runtime data areas](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-2.html#jvms-2.5)
* [Java 8 JVM specification: loading, linking, and initialization](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html)
* [JVM Internals](http://blog.jamesdbloom.com/JVMInternals.html)

[0]: {{ site.url }}/assets/images/blog/JVM.png
[1]: {{ site.url }}/assets/images/blog/JVM_Architecture.png
[2]: {{ site.url }}/assets/images/blog/JVM_stack_configuration.png
[3]: {{ site.url }}/assets/images/blog/java_class_loaders.png
