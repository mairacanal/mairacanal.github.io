---
title: "November Update: Exploring V3D"
date: 2022-12-08
author: Maíra Canal
permalink: /november-update-exploring-v3d/
tags: [igalia, graphics, kernel]
---

It has been a busy couple of months. As I pointed on my last blog post, I finished GSoC and joined the [Igalia Coding Experience](https://www.igalia.com/coding-experience/) mentorship project. In October, I also traveled to Minneapolis for XDC 2022 where I presented to the Linux Graphics community our AMD/KUnit work with my colleagues. So, let's make a summary of the last couple of months.

# XDC 2022

---

Just a small thank you note to X.Org Foundation for sponsoring my travel to Minneapolis. XDC 2022 was a great experience, and I learned quite a lot during the talks. Although I was a newcomer, all developers were very nice to me, and it was great to talk to experienced developers (and meet my mentors in person). Also, I presented the GSoC/XOrg work on the first day of the conference and this talk is available on [YouTube](https://www.youtube.com/watch?v=nbRbM-Ld-44&t=3s&pp=ugMICgJwdBABGAE%3D).

# Working with the Raspberry Pi 4

---

As I mentioned in my last blog post, GSoC was a great learning experience and I'm willing to keep learning about the Linux graphics stack. Fortunately, when I started the Igalia CE, [Melissa Wen](https://melissawen.github.io/) pitched me a project to increase IGT test coverage on DRM/V3D kernel driver. I was pretty glad to hear about the project as it allowed me to learn more about how a GPU works.

## The Project

Currently, V3D only has three basic IGT tests: `v3d_get_bo_offset`, `v3d_get_param`, and `v3d_mmap`. So, the basic goal of my CE project was to add more tests to the V3D driver.

As the general DRM-core tests were in a good shape on the V3D driver, I started to think together with my mentors about more driver-specific tests for the driver.

By checking the V3D UAPI, you can see that the V3D has eleven ioctls, so there is yet a lot to test for the V3D on IGT.

First, there are Buffer Object (BO) related-ioctls: `v3d_create_bo`, `v3d_wait_bo`, `v3d_mmap_bo`, and `v3d_get_bo_offset`. The Buffer Objects are shared-memory objects that are allocated by the GPU to store things like vertex data. Therefore, testing them is important to make sure that memory is being correctly allocated. Different from the VC4, the V3D has an MMU between the GPU and the bus, allowing it to not allocate objects contiguously. Therefore, the idea was to develop tests for `v3d_create_bo` and `v3d_wait_bo`.

Next, there are Performance Monitor (perfmon) related-ioctls: `v3d_perfmon_create`, `v3d_perfmon_destroy`, and `v3d_perfmon_get_values`. Performance Monitors are basically registers that are used for monitoring the performance of the V3D engine. So, tests were designed to assure that the driver was creating perfmons properly and was resilient to incorrect requests, such as trying to get a value from a non-existent perfmon.

And finally, the most interesting type of ioctls: the job submission ioctls. You can use the `v3d_submit_cl` ioctl to submit commands to the 3D engine, which is a tiled engine. When I think about tiled rendering, I always think about a [Super Nintendo](https://www.youtube.com/@RGMechEx), but things can get a bit more complicated than a SNES as you can see [here](https://developer.samsung.com/galaxy-gamedev/resources/articles/gpu-framebuffer.html). The 3D engine is composed of a bin and render pipelines, each has its command list. The binning step maps the tile to a piece of the frame and the rendering step renders the tile based on its mapping.

By testing the v3d_submit_cl ioctl, it is possible to test syncing between jobs and also the [V3D multisync ability](https://melissawen.github.io/blog/2022/05/10/multisync-p1).

Moreover, the V3D has also a TFU (texture formatting unit), and a CSD (compute shader dispatch), which has their ioctls: `v3d_submit_tfu` and `v3d_submit_csd`. The TFU makes format conversions and generated mipmaps and the CSD is responsible for dispatching a compute shader.

So, the idea is to write tests for all those functionalities from V3D, increasing the testability of V3D on IGT. Although things are not yet fully-done, I've been enjoying and working exploring the V3D, IGT, and Mesa. After this experience with Mesa and also XDC, I became more and more interested in Mesa.

## A Noop Job...

In order to test the `v3d_submit_cl` ioctl, it was needed to design a job to be submitted. So, Melissa suggested using Mesa's noop job specification on IGT to perform the tests. The idea was quite simple: submit a noop job and create tests based on it. But, it was not that simple after all...

First, I must say that I'm mostly a kernel developer, so I was not familiar with Mesa. So, maybe it was not that hard to figure out, but I took a while to understand Mesa's packet and how to submit them.

The main problem I faced on submitting a noop job on IGT was: I would copy many and many Mesa files to IGT. And I took a while fighting against this idea, looking for other ways to submit a job to V3D. But, as some experience developers pointed out, packeting is the best option for it.

After some time, I was able to bring the Mesa structure to IGT with a minimal (although not that minimal) overhead. But, I'm still not able to run a successful noop job as the job's fence is not being signaled by the end of the job.

## Series Submitted

Although my noop job has not landed yet, so far, I was able to submit two series to IGT: [one for the V3D driver](https://patchwork.freedesktop.org/series/110681/) and [the other for the VC4 driver](https://patchwork.freedesktop.org/series/110948/).

Apart from cleanups in the drivers, I added tests for the `v3d_create_bo` ioctl and the V3D's and VC4's perfmon ioctls. Moreover, as I was running the VC4 tests on the Raspberry Pi 4, I realized that most of the VC4 tests were failing on V3D, considering the VC4 doesn't have rendering abilities on the Raspberry Pi 4. So, I also created checks to assure that the VC4 tests are not running on V3D.

Those series are being reviewed yet, but I hope to get them merged soon.

# Next Steps

---

My biggest priority now is to run a noop job on IGT and for it, I'm currently running the CTS tests on the Raspberry Pi 4 in order to reproduce a noop job and understand why my current job is resulting in a hang. I added a couple of debug logs (aka `printf`) on Mesa and now I can see the contents of the BOs and the parameters of the submission. So, I hope to get a fully-working noop job now.

After I develop my fully working noop job, I will finish the `v3d_wait_bo` tests, so those only make sense if I submit a job and wait for a BO after it and design the `v3d_submit_cl` tests as well. For this last one, I hope to test the syncing functionalities of V3D especially.

Moreover, I hope to write soon a piece about cross-compiling CTS for the Raspberry Pi 4, which was a fun digression on this CE project.
