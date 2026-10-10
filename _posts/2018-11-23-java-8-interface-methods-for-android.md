---
title: "Java 8 Interface Methods for Android"
layout: post
date: 2018-11-23 18:07
description: "Explore Java 8 interface features for Android development: default methods, static methods, and functional interfaces with practical examples."
image: /assets/images/blog/android_desugar.png
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

The post follows four steps to show how D8 works:
1. Write Java source (`.java`).
2. Compile it to bytecode (`.class`).
3. Compile the bytecode to a Dalvik executable (`.dex`).
4. Inspect the generated files.

These steps show how D8 desugars Java 8 features such as lambdas and APIs.

I use the same steps to examine `default` and `static` methods in Java 8 interfaces. I recommend reading Jake Wharton's post first.

## Compile Java 8 Code
Consider this code:
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
Compile the Java code:
```
$ javac *.java
$ ls
Java8.java  Java8.class  Java8$Logger.class
```
Running it prints:
```
$ java Java8
Hello!
hello from: default
hello from static
```
Then compile the bytecode to dex with D8:
```
$ $ANDROID_HOME/build-tools/28.0.2/d8 --release --lib $ANDROID_HOME/platforms/android-28/android.jar --output . *.class
$ ls
Java8.java  Java8.class  Java8$Logger.class  classes.dex
```
Our focus here is the `default` and `static` methods in the `Logger` interface.

## Dex Analysis
Use `dexdump` to inspect the interface methods:
```
$ $ANDROID_HOME/build-tools/28.0.2/dexdump -d classes.dex
```
We get a lot of output (the full output can be found [here][3]).

## Default Methods
First, find this output:
```
Class #0            -
  Class descriptor  : 'LJava8$Logger-CC;'
  Access flags      : 0x1011 (PUBLIC FINAL SYNTHETIC)
  Superclass        : 'Ljava/lang/Object;'
  Interfaces        -
  Static fields     -
  Instance fields   -
```
D8 generated `Java8$Logger-CC`, as the `SYNTHETIC` flag shows. It extends `Object`, implements no interfaces, and has no fields.

Now inspect the class methods. The class has two methods, the first one is `$default$log`:
```
Direct methods    -
    #0              : (in LJava8$Logger-CC;)
      name          : '$default$log'
      type          : '(LJava8$Logger;Ljava/lang/String;Ljava/lang/String;)V'
      access        : 0x0009 (PUBLIC STATIC)
```
This static method takes a `Logger` followed by the default method's arguments. Its body is:
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
The bytecode performs the same work as the interface's default method. Equivalent Java code is:
```java
public static void defaultLog(Logger logger, String tag, String s) {
    logger.log(tag + ": " + s);
}
```
D8 moved the default method's body to a static method in the generated `Java8$Logger-CC` class.

## Static Method
The generated `Java8$Logger-CC` class also contains the interface's static `systemOut` method:
```
#1            : (in LJava8$Logger-CC;)
  name        : 'systemOut'
  type        : '()LJava8$Logger;'
  access      : 0x0009 (PUBLIC STATIC)
```
`systemOut` takes no arguments and returns a `Logger`. Its body is:
```
|[00040c] Java8.Logger-CC.systemOut:()LJava8$Logger;
|0000: sget-object v0, Ljava/lang/System;.out:Ljava/io/PrintStream; // field@0002
|0002: invoke-virtual {v0}, Ljava/lang/Object;.getClass:()Ljava/lang/Class; // method@0011
|0005: new-instance v1, L-$$Lambda$teOjDu261Kz9uXGt1wlPvIP5S04; // type@0001
|0007: invoke-direct {v1, v0}, L-$$Lambda$teOjDu261Kz9uXGt1wlPvIP5S04;.<init>:(Ljava/io/PrintStream;)V // method@0004
|000a: return-object v1
```
This code implements `Logger.systemOut()`. The generated lambda class represents the `System.out::println` method reference.

Equivalent Java code is:
```java
public static Logger systemOut() {
    return new Lambda(System.out); //System.out::println
}
```

## Conclusion

This Java code models the transformed class. I changed some names for clarity:
```java
import java.io.PrintStream;

class Java8Desugared {

  interface Logger {
    void log(String s);
    void log(String tag, String s);
  }

  public static final class LoggerCC {

    public static void defaultLog(Logger logger, String tag, String s) {
      logger.log(tag + ": " + s);
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
hello from: default
hello from static
```

## Sources
* [Android’s Java 8 Support][1]
* [Dalvik bytecode][2]

[0]: {{ site.url }}/assets/images/blog/android_desugar.png
[1]: https://jakewharton.com/androids-java-8-support
[2]: https://source.android.com/devices/tech/dalvik/dalvik-bytecode
[3]: https://gist.github.com/Aallam/0e6de2591ece329fb6ade9fb98bef444
