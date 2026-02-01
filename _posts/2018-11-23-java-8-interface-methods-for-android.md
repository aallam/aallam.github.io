---
title: "Java 8 Interface Methods for Android"
layout: post
date: 2018-11-23 18:07
description: "Explore Java 8 interface features for Android development: default methods, static methods, and functional interfaces with practical examples."
tag:
- Java
- Android
blog: true
jemoji:
---

<div class="text-center" markdown="1">
![Java 8 language feature support using desugar bytecode transformations.][0]{:width="75%"}
<figcaption class="caption">Java 8 language feature support using desugar bytecode transformations.</figcaption>
</div>
<br/>

Recently, I enjoyed reading a [blog post][1] by Jake Wharton about how Android supports Java 8 features using D8.

The blog post goes through the following processes to understand how D8 works: 
1. Write Java code. (.java) 
2. Compile to ByteCode.(.class) 
3. Compile to Dalvik Executable. (.dex) 
4. Analysis of the generated files.

In the blog post, the above process allows us to understand what happens under the hood when some Java 8 features (Lambdas and APIs) are desugared using D8.

In this post, we will use the same process to understand how `default` methods and `static` methods in Java 8 interfaces are desugared using D8. To better understand this post, I heavily recommend reading Jake Wharton's post first.

## Compile Java 8 Code
We will try to analyse the following code : 
```java
class Java8 {

  interface Logger {
    void log(String s);

    default void log(String tag, String s) {
      log(tag + ": " + s);
    }

    static Logger systemOut() {
      return System.out::println;
    }
  }

  public static void main(String... args) {
    sayHi(s -> System.out.println(s));
    Logger.systemOut().log("hello from static");
  }

  private static void sayHi(Logger logger) {
    logger.log("Hello!");
    logger.log("hello from", "default");
  }
}
```
We compile the java code:
```
$ javac *.java
$ ls
Java8.java  Java8.class  Java8$Logger.class
```
Executing the above code gives the following output:
```
$ java Java8
Hello!
hello from: default
hello from static
```
Then we compile the bytecode to dex using D8:
```
$ $ANDROID_HOME/build-tools/28.0.2/d8 --release --lib $ANDROID_HOME/platforms/android-28/android.jar --output . *.class
$ ls
Java8.java  Java8.class  Java8$Logger.class  classes.dex
```
Our focus here is the `default` and `static` methods in the `Logger` interface.

## Dex Analysis
To see how D8 desugared interface’s `static` and `default` methods, we will use `dexdump`:
```
$ $ANDROID_HOME/build-tools/28.0.2/dexdump -d classes.dex
```
We get a lot of output (the full output can be found [here][3]).

## Default Methods
Firs, we find the following output:
```
Class #0            -
  Class descriptor  : 'LJava8$Logger-CC;'
  Access flags      : 0x1011 (PUBLIC FINAL SYNTHETIC)
  Superclass        : 'Ljava/lang/Object;'
  Interfaces        -
  Static fields     -
  Instance fields   -
```
A new class `Java8$Logger-CC` has been generated! (We know it’s generated because of the `SYNTHETIC` flag). This class has `Object` as superclass and doesn’t implement any interfaces and have no static or instance fields.

Now let’s check these class methods. The class has two methods, the first one is `$default$log`:
```
Direct methods    -
    #0              : (in LJava8$Logger-CC;)
      name          : '$default$log'
      type          : '(LJava8$Logger;Ljava/lang/String;Ljava/lang/String;)V'
      access        : 0x0009 (PUBLIC STATIC)
```
We can read that this method is a `static` method and takes as arguments a `Logger` plus the same arguments as our default method in our `Logger` interface! 
The content of the method is:
```
[000434] Java8.Logger-CC.$default$log:(LJava8$Logger;Ljava/lang/String;Ljava/lang/String;)V
|0000: new-instance v0, Ljava/lang/StringBuilder; // type@000c
|0002: invoke-direct {v0}, Ljava/lang/StringBuilder;.<init>:()V // method@0012
|0005: invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;.append:(Ljava/lang/String;)Ljava/lang/StringBuilder; // method@0013
|0008: const-string v2, ": " // string@0001
|000a: invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;.append:(Ljava/lang/String;)Ljava/lang/StringBuilder; // method@0013
|000d: invoke-virtual {v0, v3}, Ljava/lang/StringBuilder;.append:(Ljava/lang/String;)Ljava/lang/StringBuilder; // method@0013
|0010: invoke-virtual {v0}, Ljava/lang/StringBuilder;.toString:()Ljava/lang/String; // method@0014
|0013: move-result-object v2
|0014: invoke-interface {v1, v2}, LJava8$Logger;.log:(Ljava/lang/String;)V // method@0009
|0017: return-void
```
Even though the output looks complicated, the code here is actually simple and its logic is equivalent to the implementation of the `default` method in `Logger` interface!
The equivalent Java code of the method can be the following :
```java
public static void defaultLog(Logger logger, String tag, String s) {
    logger.log(tag + ":" + s);
}
```
We can conclude that the `default` method in interfaces are desugared to `static` methods in a newly generated utility class (`Loger-CC`).

## Static Method
Based on what we already saw before, we can have a guess how `static` methods in interfaces are desugared! Let’s check!
The generated class `Loger-CC` have a second `static` method! And without surprise, its name is `systemOut`:
```
#1            : (in LJava8$Logger-CC;)
  name        : 'systemOut'
  type        : '()LJava8$Logger;'
  access      : 0x0009 (PUBLIC STATIC)
```
The method `systemOut` in `Logger-CC` take no arguments and returns a `Logger` !
The body of the method is:
```
|[00040c] Java8.Logger-CC.systemOut:()LJava8$Logger;
|0000: sget-object v0, Ljava/lang/System;.out:Ljava/io/PrintStream; // field@0002
|0002: invoke-virtual {v0}, Ljava/lang/Object;.getClass:()Ljava/lang/Class; // method@0011
|0005: new-instance v1, L-$$Lambda$teOjDu261Kz9uXGt1wlPvIP5S04; // type@0001
|0007: invoke-direct {v1, v0}, L-$$Lambda$teOjDu261Kz9uXGt1wlPvIP5S04;.<init>:(Ljava/io/PrintStream;)V // method@0004
|000a: return-object v1
```
Without surprise, the code is equivalent to our implementation of the `static` method in `systemOut` in the interface `Logger` (`$Lambda$teOjDu261Kz9uXGt1wlPvIP5S04` is a class that corresponds to the lambda `System.out::println` in our implementation).

The equivalent java code can be:
```java
public static Logger systemOut() {
    return new Lambda(System.out); //System.out::println
}
```

## Conclusion

The following Java code is an equivalent of our `Java8` class above (PS: I changed some methods/classes names for clarity) :
```java
import java.io.PrintStream;

class Java8Desugared {

  interface Logger {
    void log(String s);
    void log(String tag, String s);
  }

  public static final class LoggerCC {

    public static void defaultLog(Logger logger, String tag, String s) {
      logger.log(tag + ":" + s);
    }

    public static Logger systemOut() {
      return new LambdaSystemOut(System.out);
    }
  }

  public static final class LambdaSystemOut implements Logger {
    private PrintStream ps;

    public LambdaSystemOut(PrintStream ps) {
      this.ps = ps;
    }

    @Override public void log(String s) {
      ps.println(s);
    }

    @Override public void log(String tag, String s) {
      LoggerCC.defaultLog(this, tag, s);
    }
  }

  public static void main(String... args) {
    sayHi(LambdaSayHi.INSTANCE);
    LoggerCC.systemOut().log("hello from static");
  }

  private static void sayHi(Logger logger) {
    logger.log("Hello!");
    logger.log("hello from", "default");
  }

  public static final class LambdaSayHi implements Logger {
    static final LambdaSayHi INSTANCE = new LambdaSayHi();

    private LambdaSayHi() {}

    @Override public void log(String s) {
      lambdaContent(s);
    }

    @Override public void log(String tag, String s) {
      LoggerCC.defaultLog(this, tag, s);
    }
  }

  static void lambdaContent(String s) {
    System.out.println(s);
  }
}
```
Compiling and running the above code gives the same output as our `Java8` class:
```
$ javac Java8Desugared.java
$ java Java8Desugared
Hello!
hello from:default
hello from static
```

## Sources
* [Android’s Java 8 Support][1]
* [Dalvik bytecode][2]

[0]: {{ site.url }}/assets/images/blog/android_desugar.png
[1]: https://jakewharton.com/androids-java-8-support
[2]: https://source.android.com/devices/tech/dalvik/dalvik-bytecode
[3]: https://gist.github.com/Aallam/0e6de2591ece329fb6ade9fb98bef444
