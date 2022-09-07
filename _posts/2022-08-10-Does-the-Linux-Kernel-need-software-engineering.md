---
title: "Does the Linux Kernel need software engineering?"
date: 2022-08-10
author: Maíra Canal
layout: post
permalink: /does-the-linux-kernel-need-software-engineering/
categories: Genel
tags: [gsoc, linux, kernel, graphics]
---

For those looking for a short answer: yes, it does.

Now, we can dive into a more elaborate answer.

Software engineering is a more systematic approach to software development,
which involves the definition, implementation, measurement, management, change,
and improvement of the software lifecycle. When we think about software through
this lens, we must also think about software requirements, design, construction,
testing, and **maintenance.**

Software engineering improves software maintainability, scalability, and
security. Moreover, makes it easier to add testing to the software stack. This
approach makes the software **more robust**.

> A little glossary for some software engineering terms: \
> **\- Maintainability:** how easy is it to repair, improve or understand a
> software artifact? After finishing your product, you must continue to fix bugs,
> optimize functionalities and refactor code to avoid future problems. \
> **\- Scalability:** how easy is it to grow or shrink a software artifact? \
> **\- Testability:** how easy is it to test a software artifact? Does the function
> has suitable hooks for testing?

Many people might believe that it is not possible to do software engineering on
the Linux Kernel, or even that software engineering is not needed. From what I
see, these beliefs come from two statements:

1. **It is not possible to apply software engineering with C:** sometimes
   software engineering is only associated with Object-Oriented Programming
   languages.
2. **Software engineering is not needed as we are working with drivers:** as
   drivers are theoretically finite, we don't have to think about their
   expansion and maintainability.

If we follow those beliefs, we might end up with poorly designed code. And,
when badly designed code grows, I assure you that we are going to see code
repetition, dead code, insanely large functions, and bugs.

But, the worst of all: when we have a huge codebase with lots of bad code
practices, maintainability becomes hard and software quality will decrease
more and more.

So, let’s first understand why those two beliefs are false.

## Software Engineering with C

---

You might say: how can I use my fancy design patterns, avoid code repetition,
and make beautiful polymorphism when I don’t have classes?

And okay, you are right! Design Patterns in C++ are much easier and more
natural to understand and implement. In C++ you can create a hierarchy
to represent a family of devices, and this feature comes out of the box.
But we can translate those concepts to C.

C is a *structured language,* but we can write object-oriented programs in C. In
this sense, libraries and structs are your main allies. Moreover, you can use
function pointers to create polymorphism in C.

For example, if I want to write a simple queue in C, I can use the following
approach:

```c
#ifndef QUEUE_H_
#define QUEUE_H_

typedef struct Queue Queue;
struct Queue {
	int *buffer;
	int head;
	int size;
	int tail;
	int (*isFull)(Queue* const me);
	int (*isEmpty)(Queue* const me);
	int (*getSize)(Queue* const me);
	void (*insert)(Queue* const me, int k);
	int (*remove)(Queue* const me);
};

/* Constructor and destructors */
void Queue_Init(Queue const me, (*isFullFunction)(Queue* const me),
	(*isEmptyFunction)(Queue* const me), (*getSizeFunction)(Queue* const me),
	(*insertFunction)(Queue* const me, int k), (*removeFunction)(Queue* const me));

void Queue_Cleanup(Queue* const me);

/* Operations */
int Queue_isFull(Queue* const me);
int Queue_isEmpty(Queue* const me);
int Queue_getSize(Queue* const me);
void Queue_insert(Queue* const me, int k);
int Queue_remove(Queue* const me);

Queue *Queue_Create(void);
void Queue_Destroy(Queue* const me);

#endif
```

Notice that I can have polymorphism using this approach. As I can create a new
struct that inherits Queue, such as:

```c
typedef struct CachedQueue CachedQueue;
struct CachedQueue {
	Queue *queue;

	/* new attributes */
	char name[80];
	int numberElementsOnDisk;

	/* aggregation in subclass */
	Queue *outputQueue;

	/* inherited virtual function */
	int (*isFull)(CachedQueue* const me);
	int (*isEmpty)(CachedQueue* const me);
	int (*getSize)(CachedQueue* const me);
	void (*insert)(CachedQueue* const me, int k);
	int (*remove)(CachedQueue* const me);

	/* new virtual functions */
	void (*flush)(CachedQueue* const me);
	int (*load)(CachedQueue* const me);
};
```

Okay, this is incredible! It is **POLYMORPHISM** in C. And there is much more on
this topic in the book [“Design Patterns for Embedded Systems in C”](https://www.amazon.com.br/Design-Patterns-Embedded-Systems-Engineering/dp/1856177076),
by Bruce Powel Douglass. I love this book and I learned a lot from with it. Moreover,
there is an awesome talk by Renato Geh and Matheus Tavares in the Linux Developer
Conference Brazil 2019 about ["Object Oriented Techniques in C: A Case Study on
Git and Linux"](https://www.youtube.com/watch?v=x0ELqk2lCcI).

So, you can see that fancy software architecture can be done on C. And don’t get
me wrong, there are some beautiful abstractions in Linux that use these
concepts, such as the Virtual File System (VFS). Moreover, some libraries
provide great APIs, such as the DRM subsystem.

But sometimes this is not used in the implementation of drivers. And this takes
us to the next point: yes, drivers need to be properly designed on the software
side.

## Drivers should be designed as pieces of software

---

Here I must say that: my opinion is extremely biased by the Display Mode VBA
library. For the last month, I have been writing unit tests for this library as
part of my GSoC project. I got quite impressed (maybe not in a good way) with
the amount of code repetition in the code and also with the **huge** functions.

And this is not a roast on AMDGPU code: AMD does a great job for the free
software community and it is incredible that we have an open-source driver for a
major graphics retailer. Moreover, I’m sure that this problem also exists in
other parts of the kernel, so, I believe it is a good point to discuss.

Let’s start from the premise that drivers are finite: you can grab the
datasheet, code the hardware to the end of its features and finish the driver.
And I might even say that you are right: drivers are finite. But, hardware
companies don’t usually create one single product with singular characteristics:
they usually create a product line, and sometimes product lines have children:
another product line with some upgrades on the previous one.

> 💡 Product lines having children… For an OOP programmer, this sounds like a
> beautiful case for inheritance.

So, if you have a product line, are you going to create a file for each product?
And for the product with a couple of features added, are you going to paste the
previous driver and change a couple of hundreds of lines? This doesn’t seem like
a great option, for a couple of reasons:

1. **Duplicate Code:** you are duplicating the code and **the bugs as well**.
2. **Test Coverage:** are you going to duplicate the tests also?
3. **Maintainability:** especially in the maintenance phase of a project, the
   less code the better.

You see, it all comes down to **maintainability.**

As a great example of code reuse, you can check out the IIO subsystem.
Hardware manufacturers such as Maxim and Analog Devices Inc usually have
chips that share the same register map or share functionalities. Instead of
creating a driver for each chip, developers write one single driver and add
the compatible device IDs on the Device Table. For example, you can check the
Maxim MAX1027 ADC driver, which is compatible with the MAX1027, MAX1029,
MAX1031, MAX1227, MAX1229, and MAX1231. So we have one single driver for six
devices: this is great for maintainability!

In this case, if I find a bug, I can make one single modification, and send
one single patch, the maintainer will review one single time, and all runs
smoothly.

Now, let’s take a look at the DML folder from the AMD’s Display Core, more
specifically the `display_mode_vba` files from DCN20 and DCN21. See that
these product lines are pretty similar, so maybe we can reuse a lot of the
code.

But, if you check the directory, you can see that we have three different
files: `display_mode_vba_20.c`, `display_mode_vba_20v2.c` and
`display_mode_vba_21.c`.

> 💡  You can check the difference between the files through: \
> 	  **$ diff drivers/gpu/drm/amd/display/dc/dml/dcn20/display_mode_vba_20.c drivers/gpu/drm/amd/display/dc/dml/dcn20/display_mode_vba_20v2.c**

And much of the code is identical: I mean there are functions that don’t
change a line! This hits pretty hard on maintainability.

Now, if I find a bug, I need to make three modifications. Moreover, I might
not even know that the code is duplicated, so I might only fix the bug in one
place and leave the other files untouched. Then another developer might find
the same bug once again, and will have to send it to the maintainer, who will
have to review it one more time. **This is a lot of rework!**

And if I could guess a reason for AMD to copy and paste the code so many
times, I would point out another maintainability issue: **the functions are
huge!** Some functions from the VBA files have more than a thousand lines.

These huge functions from the VBA files implicate that if you want to change
a couple of lines for your new product lines you need to copy and paste the
whole function.

Ideally, from the principles of the Clean Code book, we would like to have
small functions that should be simple and do one thing only. And I know: this
is not applicable in 100% of the cases, but I cannot find a good reason for a
function to be so huge and have dozens of parameters.

> 💡 Other than the readability, those huge functions also hurt the stack pretty badly.

Huge functions really hurt the readability, understandability, and testability
of the code. Moreover, they make it difficult to avoid code duplication as the
function has dozens of side effects.

> More glossary for some software engineering terms: \
> **\- Readability:** how easily a software artifact can be read? \
> **\- Understandability:** how easily a software artifact can be comprehend?

But this is not a dead end for the AMDGPU's DML code: I mean, the AMDGPU driver
works awesomely on Linux, and code refactoring is always an option.

## We can think about software!

---

At this moment, we might conclude that as the AMDGPU driver is open-source, then
we can fix those issues in the code. But it is definitely not safe to simply
tear down the code and rewrite it in one single patch set, as the AMDGPU driver
has to remain functional on Linux.

One way to fix this is through unit testing to ensure the code is properly
refactored. Though, throughout my GSoC project, I ended up noticing that it is
not possible to write a unit test for a thousand-line function. A huge function
has many side effects and testing each one of them is not feasible.

Maybe for Display Mode VBA unit testing is not the only way to go. We probably
could first break the functions into smaller, self-contained pieces, as this
will help to create better tests, to improve readability, and to reduce the
stack size.

Now with smaller functions, it is more feasible to share code across the [DCNs](https://docs.kernel.org/gpu/amdgpu/display/dcn-overview.html)
and create a common interface for them.

This refactor can lead to the use of those design patterns I talked about
earlier and make the DML more maintainable and readable. We can think about the
use of inheritance where we have a base library, from which DCN20 can extend,
and then DCN21 can extend from DCN20. And this is how those three huge files can
become three small files.

And this refactor can start piece by piece:

1. **Unifying the parameters:** don’t pass the parameters by copying if the
   parameters are in the common struct. The stack will thank this change!
2. **Splitting the functions:** make smaller, more readable functions.
3. **Writing tests for the functions**
4. **Creating a common interface:** here is where the design patterns come
in.

This way we can make a safer refactor as unit testing is not viable. This
doesn’t mean that we are not going to introduce any bugs in the process, but
having a structured plan will help us avoid them.

---

I must say: this is the opinion of someone that came straight out of the
university, thinking about well-structured code. So, I might be utopian about
software engineering. I understand that the developers at AMD are doing their
best and are working hard to provide the best features for us, Linux users.

But thinking of software is the best way to ensure the maintainability of our
code, and bad code practices will prove costly one day or another.
