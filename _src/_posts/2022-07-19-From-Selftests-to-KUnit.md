---
title: "From Selftests to KUnit"
date: 2022-07-19
author: Maíra Canal
permalink: /from-selftests-to-KUnit/
tags: [gsoc, linux, kernel, graphics]
---

Last week, the [series](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#t) with DRM Kernel Selftests conversion to KUnit tests was merged into `drm-misc-next` and will probably be on the mainline on 5.20.

This series was developed during an [LKCAMP](https://lkcamp.dev/) hackathon in October 2021 and is the combined effort of seven Linux Kernel beginners. In this hackathon, we learned about the KUnit Framework and also learned a bit about DRM.

The series took quite a while to come out, as it was just a side-project to most of us, but, in June, I finally prepared the patches and transformed them into a mergeable series.

So, let’s understand the differences between kselftests and KUnit tests and learn some about the KUnit framework.

## Testing… Testing… Testing…

---

Tests are not all the same. We create different kinds of tests for different purposes. So, let’s clarify some kinds of tests that will be quoted in this blogpost:

1. **Unit Testing:** tests individual units or components with the purpose to validate each unit of the software code and check whether they are performing as expected. A unit test should be the finest granularity of testing and as such should allow all possible code paths to be tested in the code under test.
2. **Functional Testing:** validates the software system against functional requirements. So, basically, the system is tested against the function requirement/specification.
3. **Regression Testing:** tests that ensure that a code change does not affect the functionality of the existing software product.

## What is Kselftest?

---

[Linux Kernel Selftests (kselftest)](https://docs.kernel.org/dev-tools/kselftest.html) is a set of features functional and regression tests developed to avoid regressions on the Linux Kernel. The idea is that the developer will find a regression, fix it, and then write a test so that the Kernel won’t have this regression again.

The kselftests use shell scripts and C programs to load the tests into the kernel and have support for hardware-dependent tests. It doesn’t support workload or application tests, as its idea is primarily to increase the breadth and depth test coverage on the Kernel.

Although not designed for it, unit tests can also be developed with kselftests. But noticed that it is not a Unit Test Framework, such as JUnit, Google Test, or PyTest.

kselftest has C interfaces for reporting test results using the Test Anything Protocol (TAP) and a test harness for running tests.

## What is KUnit?

---

[KUnit (Kernel Unit Testing Framework)](https://docs.kernel.org/dev-tools/kunit/index.html) is the Unit Testing Framework for the Linux Kernel. KUnit makes it possible to run test suites on kernel boot or load the tests as a module. It reports all test case results through a TAP (Test Anything Protocol) in the kernel log.

KUnit follows the white-box testing approach, which allows testers to inspect and verify the inner workings of a software system. So, it can test any kernel component and is not restricted to userspace.

KUnit doesn’t require installing the kernel on a test machine or in a VM. It addresses the problem of being able to run tests without needing a virtual machine or actual hardware with User Mode Linux.

KUnit provides facilities for defining unit test cases, grouping related test cases into test suites, providing common infrastructure for running tests, and much more.

## How to choose a framework?

---

Each one of the frameworks has its place and importance, as both kinds of tests are important to improve Kernel's reliability and robustness.

The main difference between kselftest and KUnit is that **KUnit is a unit testing framework** and **kselftest is not**. kselftest requires installing the kernel on a test machine or in a VM and require tests to be written in userspace and run on the kernel under test. On the other side, KUnit does not.

So, when it comes to testing a single unit of code in isolation, you’ll definitely go with KUnit. Otherwise, you’ll have to check the kselftests or autotests frameworks.

## Why DRM selftests were plausible for a conversion?

---

First, I must point out that the DRM selftests are not kselftests. They work very similarly, but the DRM subsystem developed a unique structure for running their unit tests, which was available on `drm_selftests.h`. For a general idea, they had simple `FAIL_ON(expression)` assertions, indicating that the test would fail if the expression was true, and each test was a module initialized by `run_selftests`.

So, let’s check a DRM selftest function and analyze it to check if it’s plausible for conversion. Take this function from `drivers/gpu/drm/selftests/drm_cmdline_selftests.h`:

```c
static int drm_cmdline_test_force_D_only_not_digital(void *ignored)
{
	struct drm_cmdline_mode mode = { };

	FAIL_ON(!drm_mode_parse_command_line_for_connector("D",
							   &no_connector,
							   &mode));
	FAIL_ON(mode.specified);
	FAIL_ON(mode.refresh_specified);
	FAIL_ON(mode.bpp_specified);

	FAIL_ON(mode.rb);
	FAIL_ON(mode.cvt);
	FAIL_ON(mode.interlace);
	FAIL_ON(mode.margins);
	FAIL_ON(mode.force != DRM_FORCE_ON);

	return 0;
}
```

This test function is testing a single function `drm_mode_parse_command_line_for_connector` and using test assertion to check if it behaves as expected. Can we agree that this is testing a single unit of code in isolation? So, this is a unit test!

If you look through the other files, you are going to find out that they are very similar to this function. So, they are all unit tests.

As they are unit tests, it is more suitable to use a Unit Test Framework, such as KUnit, on these tests. Moreover, converting these tests to KUnit would make them smaller and provide a userspace tool for developers to test with.

There is also one more reason to convert the DRM selftests. As DRM selftests created a whole structure to run their unit tests, converting the tests would mean deleting this structure and promoting code reuse.

## Converting the tests

---

KUnit has multiple test expectation expressions. The most used ones are:

- `KUNIT_EXPECT_TRUE (test, condition)`: causes a test failure when the expression is not true.
- `KUNIT_EXPECT_FALSE (test, condition)`: causes a test failure when the expression is not false.
- `KUNIT_EXPECT_EQ (test, left, right)`: expects that **left** and **right** are equal.
- `KUNIT_EXPECT_NE (test, left, right)`: expects that **left** and **right** are not equal.

There are a couple more and all of them can be seen on the [KUnit documentation](https://docs.kernel.org/dev-tools/kunit/api/test.html).

Examining again the  `drm_mode_parse_command_line_for_connector` function, we can see that the test expectation expression used is `FAIL_ON`. This means that the test will fail when the expression inside it is true. Checking the test expectation expressions listed above, we can say the equivalent of `FAIL_ON` is `KUNIT_EXPECT_FALSE`, right?

So, we can just adjust the function to the KUnit signature and change all `FAIL_ON` for `KUNIT_EXPECT_FALSE`. The result will be something like this:

```c
static void drm_cmdline_test_force_D_only_not_digital(struct kunit *test)
{
	struct drm_cmdline_mode mode = { };

	KUNIT_EXPECT_FALSE(test, !drm_mode_parse_command_line_for_connector("D",
							   &no_connector,
							   &mode));
	KUNIT_EXPECT_FALSE(test, mode.specified);
	KUNIT_EXPECT_FALSE(test, mode.refresh_specified);
	KUNIT_EXPECT_FALSE(test, mode.bpp_specified);

	KUNIT_EXPECT_FALSE(test, mode.rb);
	KUNIT_EXPECT_FALSE(test, mode.cvt);
	KUNIT_EXPECT_FALSE(test, mode.interlace);
	KUNIT_EXPECT_FALSE(test, mode.margins);
	KUNIT_EXPECT_FALSE(test, mode.force != DRM_FORCE_ON);
}
```

After this, our test already works with the KUnit tool. But, there is still some improvement to be made. Check out the first assertion:

```c
KUNIT_EXPECT_FALSE(test, !drm_mode_parse_command_line_for_connector("D",
							   &no_connector,
							   &mode));
```

Observe that the condition has a logical NOT operator, so, for the condition to be false, the function must return true. So, we can change the assertion to be more readable to:

```c
KUNIT_EXPECT_TRUE(test, drm_mode_parse_command_line_for_connector("D",
							   &no_connector,
							   &mode));
```

The last assertion can also be changed. We can change the comparative logical operator for the `KUNIT_EXPECT_EQ` expression.

So, the final look of our unit test would be:

```c
static void drm_cmdline_test_force_D_only_not_digital(struct kunit *test)
{
	struct drm_cmdline_mode mode = { };

	KUNIT_EXPECT_TRUE(test, drm_mode_parse_command_line_for_connector("D",
							   &no_connector,
							   &mode));
	KUNIT_EXPECT_FALSE(test, mode.specified);
	KUNIT_EXPECT_FALSE(test, mode.refresh_specified);
	KUNIT_EXPECT_FALSE(test, mode.bpp_specified);

	KUNIT_EXPECT_FALSE(test, mode.rb);
	KUNIT_EXPECT_FALSE(test, mode.cvt);
	KUNIT_EXPECT_FALSE(test, mode.interlace);
	KUNIT_EXPECT_FALSE(test, mode.margins);
	KUNIT_EXPECT_EQ(test, mode.force, DRM_FORCE_ON);
}
```

This is just a small bit of the work done! I and other LKCAMP participants converted tests across nine files. And the result can be seen on this [mailing list thread](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#t).

---

Working on these tests over the last month was pretty satisfying. The series had five iterations over the mailing list and talking to the maintainers is very rewarding. Also, it was great to remember the Saturday that I spend with three very dear friends (thanks to Arthur, Matheus, and Carlos). Seeing the patches go to the mainline was great!

After adding the DRM KUnit tests to the upstream, we must maintain it working properly and try checking the reported bugs. For example, Guenter Roeck reported problems running tests on PowerPC, so I worked on a new [patch](https://lore.kernel.org/dri-devel/20220717184336.1197723-1-mairacanal@riseup.net/T/#u) to fix it in order to make things run smoothly. So, that's about it for now!
