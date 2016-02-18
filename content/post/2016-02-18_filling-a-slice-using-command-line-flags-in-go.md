+++
Categories = ["码农向"]
Tags = ["golang"]
date = "2016-02-18T15:10:37+08:00"
title = "[转载]filling a slice using command line flags in go"

+++

I wanted to be able to specify a particular command-line flag more than once
in a Go program. I was about to throw my hands up in despair because I didn’t
think that the Go flag package could process multiple instances of a
command-line flag. I was wrong.

<!--more-->

While I was tempted to write my own command-line options parser,
I chose to find the idiomatic way to approach the problem.
If I have learned nothing else from my GoMentors,
I have learned to try to follow the idioms and to try not to reinvent the wheel.

I found an example by visiting <http://golang.org/pkg/flag/> .
I had to search for the string “FlagSet” in my browser.
Immediately under the paragraph where the word “FlagSet” first appears,
is a clickable item labeled “Example”.
Click the example item and take a look at the code.

I copied the code and toyed with it until I thought I understood it.
Then, I tried to simplify it and rewrite it.
My example program will simply accept one or more command-line flags
with the label -i.  Each argument to -i should be an integer.
I want to be able to specify -i multiple times on the command-line.
The program should populate a slice of integers while adhering
to the above command-line syntax.

Here’s my code … flagstuff.go :

``` go
// Copyright 2013 - by Jim Lawless
// License: MIT / X11
// See: http://www.mailsend-online.com/license2013.php
//
// Bear with me ... I'm a Go noob.
 
package main
 
import (
    "flag"
    "fmt"
    "strconv"
)
 
// Define a type named "intslice" as a slice of ints
type intslice []int
 
// Now, for our new type, implement the two methods of
// the flag.Value interface...
// The first method is String() string
func (i *intslice) String() string {
    return fmt.Sprintf("%d", *i)
}
 
// The second method is Set(value string) error
func (i *intslice) Set(value string) error {
    fmt.Printf("%s\n", value)
    tmp, err := strconv.Atoi(value)
    if err != nil {
        *i = append(*i, -1)
    } else {
        *i = append(*i, tmp)
    }
    return nil
}
 
var myints intslice
 
func main() {
    flag.Var(&myints, "i", "List of integers")
    flag.Parse()
    if flag.NFlag() == 0 {
        flag.PrintDefaults()
    } else {
        fmt.Println("Here are the values in 'myints'")
        for i := 0; i < len(myints); i++ {
            fmt.Printf("%d\n", myints[i])
        }
    }
}
```

Let’s dissect the code one section at a time … not necessarily in the order
presented in the source code above.

First, I define a type called intslice that refers to a slice of ints:

``` go
type intslice []int
```

Later, I define a variable named myints of type intslice.

``` go
var myints intslice
```

Later in the code, I’m going to be calling flag.Var() passing in &myints as
the first argument.  The type of the first value to flag.Var() must conform
to the flag.Value interface which is defined as:

``` go
type Value interface {
    String() string
    Set(string) error
}
```

I must now define a String() method and a Set() method for my intslice type:

``` go
func (i *intslice) String() string {
    return fmt.Sprintf("%d", *i)
}
 
func (i *intslice) Set(value string) error {
    fmt.Printf("%s\n", value)
    tmp, err := strconv.Atoi(value)
    if err != nil {
        *i = append(*i, -1)
    } else {
        *i = append(*i, tmp)
    }
    return nil
}
```

The above methods will be called by the parsing engine in the flag package
when I invoke flag.Parse(). In the String() method, I need to return
a string-representation of the argument. In the Set() method,
I then need to append the string value to the specified intslice variable
by first converting value to an int variable named tmp. If an error occurs
during conversion, I append an int value of -1 to the intslice variable.

The main body looks like this:

``` go
func main() {
    flag.Var(&myints, "i", "List of integers")
    flag.Parse()
    if flag.NFlag() == 0 {
        flag.PrintDefaults()
    } else {
        fmt.Println("Here are the values in 'myints'")
        for i := 0; i < len(myints); i++ {
            fmt.Printf("%d\n", myints[i])
        }
    }
}
```

Here are a few sample command-line invocations and the output that they produce
( I’ve added a blank line between each command and the counterpart
response lines for clarity):

No parameters. I’ve added a check to make sure that more than
zero flags are specified.

```
flagstuff
 
  -i=[]: List of integers
```

Let’s specify an invalid flag (-x):

```
flagstuff -x
 
flag provided but not defined: -x
Usage of flagstuff:
  -i=[]: List of integers
```

Let’s specify -i without an argument:

```
flagstuff -i
 
Usage of flagstuff:
  -i=[]: List of integers
```

Now, let’s specify a single -i parameter with an integer value:

```
flagstuff -i 5
 
5
Here are the values in 'myints'
5
```

At each invocation of the intslice.Set() method, I display the string that
has been passed in so that I could observe the mechanics of the parsing process.
In each example that provide arguments for -i, we’ll first see those values,
then we’ll see what the slice contains via the for loop that occurs just
a little later in the code.

Let’s specify a string instead of an int as an argument:

```
flagstuff -i twelve
 
twelve
Here are the values in 'myints'
-1
```

Note that this causes the error condition in the call to strconv.Atoi().
I have chosen to add the value -1 to the slice when the argument
doesn’t cleanly parse as an integer.
You may choose to handle the error differently.

Here is an example with three valid integers:

```
flagstuff -i 5 -i 6 -i 7
 
5
6
7
Here are the values in 'myints'
5
6
7
```

Note that the example at golang.org contains a section that splits
the string value passed to Set() based on the presence of the comma character.
This allows that code to also accept multiple arguments to a single
command-line flag. I have chosen to avoid doing that to simplify my example.

Knowing how to handle multiple occurrences of a given flag without customizing
the command-line parser is going to be very helpful for a couple of programs
that I plan to write. I’m glad that I spent the time going over
the example golang.org code. I hope to tinker with more exotic command-line
processing features of the flag package in the near future.

******

原文地址：<https://lawlessguy.wordpress.com/2013/07/23/filling-a-slice-using-command-line-flags-in-go-golang/>
太长了懒得翻译了，又不是不能看。。。

