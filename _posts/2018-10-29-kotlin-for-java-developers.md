---
title: "Kotlin For Java Developers"
layout: post
date: 2018-10-29 14:29
description:
tag:
blog: true
jemoji:
---

<style type="text/css">
  pre.highlight {
    margin: 0;
  }
</style>

<div class="text-center" markdown="1">
![Kotlin][0]
</div>

The following are my notes for the course: [Kotlin for Java Developers][1].<br/>
This course is given by Svetlana Isakova and Andrey Breslav from JetBrains.

## Basics
JVM annotations are useful for Kotlin code which will be called from Java code.
* `@JvmName` : The class name for first class functions (by default it’s the file name).
* `@JvmOverloads` : Generate overloads for a function with named parameters (Not all combinations though).

### Types
* Everything is an object in the sense that we can call member functions and properties on any variable.
* Types can be inferred from the context ( `val i: Int = 3` can be replaced by `val i = 3`).

## Operators & Conditions
* In Kotlin, there is **no** ternary operator.
* `if` is an expression in Kotlin.

## Loops
* `for (i in list)` is equivalent to `for (i:Int in list)` .
* We can iterate over a map : `for ((key, value) in map)`.
* There is no full form of `for` .
* `for (i in 1..9)` is equivalent to `for (i in 1 until 9)`.
* Reverse : `for (i in 9 downTo 1)`.
* Reverse and step : `for (i in 9 downTo 1 step 2)`.
* We can iterate over Strings (chars in a string).

## Operator “in”
* `i in 1..9` is equivalent `i <= 9 && i>=9`.
* Not in : `!in` .
* `"ball" in "a".."k"` is equivalent to `"a" <= "ball" && "ball" <= "k"` which is equivalent to `"a".compareTo("ball") <= 0 && "ball".compareTo("k") <= 0` _(String are compared alphabetically)_.

## Exceptions
* There is no checked exceptions in Kotlin.
* `throw` result can be assigned to variables.
* `try` is an expression in Kotlin.
* `@throws` annotation is for checked exceptions (to be catchable in Java).

## Extension Functions
* `for String.lastChar() = this.get(this.length - 1)` ,  `String` (and `this` ) in this expression is  called: **Receiver**. `this` can be omitted , the expression becomes `for String.lastChar() = get(tlength - 1)`.
* Extension functions needs to be _imported_.
* From Java, extensions are called as static methods.
* An expression can’t call the private members of the receiver.
* Kotlin Standard Library = Java Standard Library (JDK) + Extensions.
* `infix` allow us to omit the dot. Example: `infix fun Int.until(to: Int): IntRange`  can be called `1.until(10)` or `1 until 10`
* `until`, `to` …etc are simply extensions.
* Extensions **can’t** _override_ functions, but **can** _overload_ them.
* Member functions have higher priority than extensions.

## Nullability
* The idea is to move nullability exceptions (at runtime) to compile time errors.
* Non nullable variable : `var s1: String`, nullable variable : `var s2: String?`
* Dealing with nullable can done by either an _explicit_ check  `(s != null) s.length` or safe access `s?.length`.
* Safe access example: `s?.length` -> in the case where `s == null` then the expression returns `null` , in the other case where `s != null` then `s.length` is returned. 
* `val length: Int = if (s != null) s.length else 0` is equivalent to `val length: Int = s?.length ?: 0`
* `?:` called _Elvis operator_ .
* If we check nullability and fail if it so, no null check later is needed:
```kotlin
val s: String?
if (s == null) fail() //or return
s.length
```
* `s!!` throw NPE if null.
* Nullable types are implemented using `@Nullable` and `@NonNull`.
*  `List<T?>` means the list elements are nullable, while `List<T>?` means the list itself is nullable.
* Kotlin operator `is` is an analog to `instanceof`  operator from Java.
* The operator `as` used for casting, safe cast can be done using `as?`. `val s: String? = a as? String` is equivalent to `val s = if (a is String) s else null` .

## Lambdas
* Lambdas always go in curly braces `{ }`. In IDEA, lambdas braces are highlighted (in bold). Lambda example `{ i: Int, j: Int -> i + j}`
* If the lambda is the last parameter of a function, we can move it away of the function parameters `List.any({ i: Int -> i + 1})` is equivalent to `List.any() { i: Int -> i + 1}`. If a function have only one parameter as lambda parameter, we can omit the parentheses: `List.any { i: Int -> i + 1}`.
* Lambdas parameters types can be inferred, `List.any { i: Int -> i + 1}` can become `List.any { i -> i + 1}`. If the lambda have only one parameter, we can replace it with **it** : `List.any { it + 1}`.
* In case of multiline lambda, the last line is the returned result.
* If a lambda parameter is not used, we can replace it with **_** _(underscore)_,  `map.mapValues{ (_, value) -> "$value" }`.
* Destructing  argument can be used to replace `Map.Entry` or `Pair`.

### Extensions on Collections
* `filter`: filters out the content of a list and keeps only the elements satisfying the predicate. 
* `map`: transforms each element in a collection.  
* `any` (`all`, `none`): checks if the elements satisfies a predicate.
* `find` (`firstOrNull`): finds an element satisfying a predicate and returns it, if none is found,  `null` is returned.
* `first`: finds the first element to satisfy a predicate, if no result found, and exception is thrown.
* `count`: count’s the element satisfying the predicate.
* `partition`: devices a collection to two collections: one with elements satisfying the predicate and the other the ones that do not.
* `groupBy`:  group elements by a provided key.
* `assosiateBy`: it performs grouping, but for unique elements, duplicates are removed.
* `zip`: return a list which its elements  (pair) are the combination of two lists elements.(Like a zipper :D).
* `flatMap`: performs two actions: _first_ it **maps**”the collection (from a `String` to `Char` list for example), _then_ **flatten** them to return a single list with all mapped elements from all collections.

## Functional Programming
* Lambdas can be stored in variables : `val isEven: (int) -> Boolean = { i: Int -> i % 2 == 0 }`, we can omit the types to become `val isEven = { i: Int -> i % 2 == 0 }`,. 
* It’s possible to pass stored lambdas whenever the expression of function type is expected : `list.any(isEven)`.
* It’s possible to call stored lambdas : `isEven(42)`.
* Lambdas can be run directly : `{ println("hi!") }()`, another more convenient way to run lambdas is using `run` instead of `()` : `run { println("hi!") }`.
* Autogenerated Java SAM constructors can be used to create instances : `Runnable { println(42) }`.
* To call a function stored in a nullable variable, there is two possible ways :  `if (f != null) f()` or  `f?.invoke()`.
* Functions can’t be stored in variables, but their reference can : `val predicate = ::isDigit`, which is an analogue `val predicate = { i: Int -> isDigit(i) }`.
* Storing the reference of a class function reference is called Non-Bounded reference: `val isOlderPredicate = Person::isOlder`, _isOlderPredicate_ is of type `(Person, Int) -> Boolean`.
* Storing the reference of a specific instance function reference is called Bounded reference:`val alice: Person()` and `val isOlderPredicate = alice::isOlder`, _isOlderPredicate_ is of type `(Int) -> Boolean`.
* Calling `return` from inside a lambda will end the function calling it. To return only from the lambda, we use _labelled return_: `return@flatMap`. Another way is to use local functions and _return_ from them.

## Properties
* Property  = field + accessor(s).
* Read-Only Property (val) = field + getter.
* Mutable Property (var) = field + getter + setter
* Accessors (get/set) are used to access variables under the hood in Kotlin.
* Backing field might be absent (defining getter/setter without any field)
* Fields can be accessed but _only_ inside the accessors using the keyword `field`.
* In some cases, the access to properties may be optimised by the compiler inside the classes of the properties.
* It’s possible to change the visibility of accessors:
```kotlin
var counter: Int = 0
    private set
```
* Properties can be defined in interfaces, under the hood, a property becomes only a getter, which can be overridden by the implementations of the class:
```kotlin
interface User {
    val nickname: String
}
class FacebookUser(val account: Int): User {
    // Calculated once
    override val nickname = getName(account)
}
class Subscriber(val email: String); User {
    // Calculated for each access
    override val nickname: String
        get() = email.substringBefore('@')
}
```
* Interfaces’s properties are always open (not final), and open properties can’t be smart casted.
* Extension properties are possible:
```kotlin
val String.lastIndex: Int
    get() = this.length - 1 // with `this`
    set(value: Char) {
        this.setCharAt(length - 1, value) // without `this`
    }
```

### Lazy/late Initialisation
* Lazy property is a property which values are compiled only on the _first access_.
* Lazy properties can be defined using the `by lazy` syntax : `val lazyValue: String by lazy`.
* Sometimes, properties needs to be initialised later, not in the constructor, in this case `lateinit` can be used: `lateinit var data: Data` .
* `lateinit` can be applied to `var` only, and the property type can’t be nullable or primitive.
* An exception is thrown if a `lateinit` variable is accessed without being initialised.

## Oriented-Object Programming

### Visibility Modifiers
* All declaration and `public` and `final` by default.
* To mark a declaration as non final,  mark it with `open`.
* No _package_ visibility in Kotlin.
*  `internal` is  for module visibility. A module is a set of kotlin files compiled together _(Maven project, Gradle source set..)_.
* `protected` is visible inside the package in Java but not in Kotlin, only to the class and it subclasses.
* `private` top-level declaration is visible in the file.
* `package` name don’t have to match the directory structure.

### Constructors
* Primary constructor : `class Person(val name: String)`
* `init` block can be used as the constructor body, and use the constructor  as parameters entry: `class Person(name: String)` (no `val` here).
* Changing the constructor visibility:
```kotlin
class Person
internal constructor(name: String) {
    // ...
}
```
* `constructor` can be used to declare secondary constructor, however a primary constructor must be called: `constructor (side: Int) : this(side, side) { ... }`.
* `extends` and `implements` are replaced by semicolon in Kotlin `:`.
* The parentheses are used for class inheritance (constructor), but not for interfaces: `class Alice: Person()`.

### Class Modifiers
* `enum` modifier is for creating Enumerations classes: `enum class Color { RED, GREEN, BLUE }`.
* `data` modifier generates: _equals_, _hashCode_,  _copy_, _toString_ and some other methods. 
*  `==` calls `equals()`, and `===` checks reference equality.
* `sealed` modifier restrict class hierarchy: all the subclasses must be located in the same file (protects against having a class subclassed somewhere else).
* In Kotlin, nested classes are by default static classes, `inner` modifier is to declare inner classes. An inner class keeps a reference to it parent class:
```kotlin
class A {
    class B // static class
    inner class C {
        ..this@A... // access using label name
    }
}
```
* Class delegation:  `by` modifier means _by delegating to the following instance_: `class Controller (repository: Repository, logger: Logger) : Repository by repository, Logger by logger`.

### Objects
* `object` is a singleton in Kotlin: `object class KSingleton { fun foo () }`. Class members can be accessed directly: `KSingleton.foo()`. In java, it corresponds to the static singleton with private constructor pattern in Java. To access the singleton from Java we use _INSTANCE_: `KSingleton.INSTANCE.foo()`.
* `object` keyword can be used to create anonymous classes,  an instance is created each time though : 
```kotlin
view.addListener(
    object: MouseAdapter() {
        override fun mouseClicked(e: MouseEvent) {/*...*/}
        override fun mouseEntered(e: MouseEvent) {/*...*/}
    }
)
```
* There is no static members in Kotlin.`companion object` is a special object inside a class which might be a replacement for static members.
* `companion object` can implement interfaces: `companion object: Factory<A> { /*...*/ }`.
* `companion object` can be receiver of extension functions: `fun Person.Companion.create(): Person { /*...*/ }`, afterward the extension can be called as functions on class name: `Person.create()`.
* To access `companion object` members from java: `@JvmStatic` annotation can be used :
```kotlin
// Kotlin
class C {
    companion object {
        @JvmStatic fun foo() {/*...*/}
        fun bar() {/*...*/}
    }
}
// Java
C.Companion.foo() // In case of `object` we use INSTANCE
C.Companion.bar() // instead of `Companion`
C.foo()
```
* `object` can be nested, but can’t be `inner`.

### Constants
* `const` -> for primitive types and strings.
* Using `const` means that the value is inlined: at compile time, the constant will be substituted in the code by its actual value.
* `@JvmField` -> for objects, eliminates accessors. It’s the same as defining a static final field.
* Using `@JvmStatic` on a property exposes only its getter.

### Operator Overload
* In Kotlin, it’s possible to overload arithmetic operators: plus (`+`), minus (`-`), div (`/`), mod (`%`). There is no restriction on parameter type.
```kotlin
operator fun Point.plus(other: Point): Point = Point(x + other.x, y + other.y)
```
* Unary operations can be overloaded too: unaryPlus (`+a`), unaryMinus (`-a`), not (`!`), inc (`++a`, `a++`), dec (`--a`, `a--`).
* For the case of `a += b` , there is two options : if `a` is mutable then `a = a.plus(b)` is called, if `a.plusAssign(b)` is available, then it’s possible to bridge off to it instead.
* Using plus (`+`) for lists: if the list is immutable then a _new list_ is created as result of the operation, if the list is mutable, then the _list itself_ is modified.
```kotlin
var list = listOf(1,2,3)
list += 4 // new list is created: list = list + 4 
```

### Conventions
* Comparisons: `a > b` is translated to `a.compareTo(b) > 0`, `a >= b` is translated to `a.compareTo(b) >= 0`… and so on.
* `a == b` calls `equals`, and correctly handles nullable values `null == "abc"`.
* `map[a, b]` calls `map.get(a, b)`, and  `map[a, b] = c` calls `map.set(a, b, c)`. Therefore, it’s possible de define extensions on the `get` and `set` functions.
* `in` calls under the hood `contains` : `a in c` -> `c.constains(a)`.
* Range `..` calls `rangeTo`: `start..end` -> `start.rangeTo(end)`.
* `iterator` is a convention too: `operator fun CharSequence.iterator(): CharIteraror` -> `for (c in "abc") { }`.
* Destructing declaration : `val (a, b) = p` -> `val a = p.component1()` and `val b = p.component2()`.
* Any `data class` can be represented as destructing declaration:
```kotlin
data class Contact (
    val name: String,
    val email: String,
    val phone: String
) 
// A `contact` object can be then destructed:
val (name, _, phone) = contact
```
* Elements that define member or extension operator function `compareTo` (with the right signature) can use the comparison operators.

## Inline functions
* `run`: runs the block of code (lambda) and returns the last expression as the result:
```kotlin
val foo = run {
    println("Calculating...")
    "foo"
}
```
* `let`: allows to check the argument for being non-null, not only the receiver.  `if (email != null) sendEmail(email)` can be replaced by `email?.let { e -> sendEmail(e) }` or `getEmail()?.let { sendEmail(it) }`. Notice the safe access usage `?` before `let`.
* `takeIf`: returns the receiver object if it satisfies the given predicate, otherwise returns null.
* `takeUnless`: returns the receiver object if it _does not_ satisfies the given predicate, otherwise returns null.
* `repeat` repeats an action for a given number of times.
* `withLock`: is an extension to call an object in a `synchronized` fashion.
* `use`: to use a resource with `try-with-resources`.

### Inlining
* `inline` function: the compiler substitutes the body of the function instead if calling it, as result we have no performance overhead of creating an anonymous  class and an object for the lambda:
```kotlin
inline fun <R> run(block: () -> R): R = block()
val name = "kotlin"
run { println("hi, $name") }
```
```kotlin
// the generated bytecode :
val name = "kotlin"
println("hi, $name")
```
* `@kotlin.internal.InlineOnly`: specifies that a function should not be called directly without inlining (therefore, can’t be called from java).
* The disadvantage of inlining: the size of resulting application, therefore, _inlining should be used with a lot of care_.

## Sequences
* Sequences are similar to java streams: they perform in lazy manner, have intermediate and terminal operations.
* To convert a list to sequence: `asSequence()` 
* `generateSequence`: generates an infinite sequence:
```kotlin
val numbers = generateSequence(0) { it + 1}
numbers.take(5).toList() //[0, 1, 2, 3, 4]
```
* To prevent integer overflow while using `generateSequence` , `BigInteger` can be used instead of `Int`.
* A way to generate a finite sequence is to return `null` at some point:
```kotlin
val numbers = generateSequence(0) { n -> (n + 1).takeIf (it < 3) }
numbers.toList() //[0, 1, 2]
```
* `yield`: yields a value to the Iterator being built.

### Library functions
* `people.filter { it.age < 21 }.size` -> `people.count { it.age < 21 }`
* `people.sortedBy { it.age }.reversed()` -> `people.sortedByDescending { it.age }` 
* `mapNotNull`: call `map` in a _list_ then filtering the only the non-null values.
* `getOrPut`: get at value from a map by a key, if the entry doesn’t exist then put a default value: `map.getOrPut(person.name) { mutableListOf }`.

## Lambda with Receiver
* Lambda with receiver = Extension function + Lambda.
* The old name of lambda with receiver is _extension lambdas_.
* Regular function vs Extension function:
```kotlin
val isEven: (Int) -> Boolean = { it % 2 == 0 }
val isOdd: Int.() -> Boolean = { this % 2 == 1 }
isEven(0) // Calling as regular function.
1.isOdd() // Calling as extension function.
```
* `with` declaration as a use case of lambda with receiver:
```kotlin
inline fun <T, R> with(receiver T, block: T.() -> R) : R = receiver.block()
```
* Lambdas  with receiver are used to create Kotlin DSL’s, gradle build script…etc.

### Useful library functions
* To omit repeatedly using an element name to call it inner elements, we can use:  `with`. `with` takes the receiver as a parameter and use it inside the lambda as `this` .
* `run` is like `with` but as extension: `windowById["main"]?.run { width = 200 }`.
* `with` and `run` both return the last expression as a result.
* `apply` returns receiver as result: `windowById["main"]?.apply { width = 200 }`.
* `also` is similar to `apply`, it return the receiver as well, however, it take a regular lambda not a lambda with receiver as an argument : `windowById["main"]?.also { showWindow(it) }`

#### Recap
* `run ` -> return _result of the lambda_ and take _lambda with receiver_ as parameter.
* `let ` -> return _result of the lambda_, take _regular lambda_ as parameter.
* `apply ` -> return _receiver_, take _lambda with receiver_ as parameter.
* `also ` -> return _receiver_, take _regular lambda_ as parameter.

## Types
* There is no primitives in the language.
* Non-nullable Kotlin primitive types (`Int`) corresponds to Java primitives (`int)`
* Nullable Kotlin primitives  (`Int?`) corresponds the Java wrappers (`java.lang.Integer`). 
* When non-nullable primitive is used as generic (`List<Int>`), it will be compiled to wrapper type (`List<Integer>`). 
* Arrays with generics are converted to wrappers (`Array<Int>` -> `Integer[]`). To use primitive arrays, we use `IntArray`, `DoubleArray`, `LongArray`…etc.
*  `kotlin.String` corresponds to `java.lang.String` with some changes in it API.
* `Any` corresponds to `java.lang.Object`, however it’s a super type of all references, including primitives.
* `contentEquals`: to compare primitive arrays (`IntArray`, `DoubleArray)`…).

### Types Hiarchy
* `Unit` under the hood corresponds to Java `void`: a type that allow only one value and thus can hold no information -> the function **completes** successfully.
*  `Nothing`  is a subtype of all other types,  and means: this function will never return: a type that has no value -> the function **never** completes (_by error; or never completes: infinite loop for example_). 
* Under the hood `Nothing` corresponds to Java `void` because we don’t have `Nothing` in the JVM.
* Taking nullable in consideration, `Any?` is the super type of all types, and `Nothing?` is the subtype of all types.
* The simplest expression of `Nothing?`  type is `null`: `var n: Nothing? = null`.

### Nullabe Types
* Platform type `Type!` -> unknown nullability. It’s a notation, not syntax: can’t declare such type in kotlin.
* To prevent NPEs when using java code: annotate java types (`@Nullable` and `@NotNull`) and/or specify types explicitly in kotlin.
* Specifying a default annotation in java code can be done with JSR-305:
```java
@javax.annotation.Nonnull
@TypeQualifierDefault(ElementType.Parameter, ...)
annotation class MyNonnullByDefault
// Use the annotation with package
@MyNonnullByDefault
package mypackage;
```

### Collections Types
* `kotlin.List`  (and `kotlin.MutableList`) -> `java.util.List` 
* `kotlin.MutableList` extends the interface `kotlin.List`.
* Read-only ≠ Immutable:  RO interface just lacks mutating methods, the actual list still can be changed by another reference.
* `java.util.List<String>` -> `(Mutable) List<String!>`.

## Misc.
* Triple quotes (called also multiline strings) are good for regex strings.
* Expressions precedence ([documentation][3])

---

### Sources
* [Kotlin for Java Developers][1]
* [Kotlin Grammar][4]

[0]: {{ site.url }}/assets/images/blog/kotlin_logo.png
[1]: https://www.coursera.org/learn/kotlin-for-java-developers
[2]: {{ site.url }}/assets/images/blog/kotlin_precedence.png
[3]: https://kotlinlang.org/docs/reference/grammar.html#precedence
[4]: https://kotlinlang.org/docs/reference/grammar.html