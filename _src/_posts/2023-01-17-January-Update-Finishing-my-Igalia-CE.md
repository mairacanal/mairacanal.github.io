---
title: "January Update: Finishing my Igalia CE"
date: 2023-01-17
author: Maíra Canal
permalink: /january-update-finishing-my-igalia-ce/
categories: [Tech]
tags: [igalia, graphics]
---

2022 really passed by fast and after I completed the GSoC 2022, I'm now
completing another milestone: my project in the [Igalia Coding
Experience](https://www.igalia.com/coding-experience/) and I
had the best experience during those four months. I learned tremendously about
the Linux graphics stack and now I can say for sure that I would love to keep
working in the DRM community.

While GSoC was, for me, an experience to get a better understanding of what open
source is, Igalia CE was an opportunity for me to mature my knowledge of
technical concepts.

So, this is a summary report of my journey at the Igalia CE.

# [IGT](https://gitlab.freedesktop.org/drm/igt-gpu-tools) tests to V3D
---

Initially, V3D only had three basic IGT tests: `v3d_get_bo_offset`,
`v3d_get_param`, and `v3d_mmap`. So, the basic goal of my CE project was to add
more tests to the V3D driver.

V3D is the driver that supports the Broadcom V3D 3.3 and 4.1 OpenGL ES GPUs, and
is the driver that provides 3D rendering to the Raspberry Pi 4. V3D is composed
of a tiled renderer, a TFU (Texture Formatting Unit), and a CSD (Compute Shader
Dispatch).

During the CE, I was able to develop tests for almost all eleven V3D ioctls
(except `v3d_submit_tfu`). I began writing tests to the `v3d_create_bo` ioctl
and *Performance Monitor* (perfmon) related ioctls. I developed tests that check
the basic functionality of the ioctls and I inspected the kernel code to
understand situations where the ioctl should fail.

After those tests, I got the biggest challenge that I had on my CE project:
performing a Mesa's no-op job on IGT. A no-op job is one of the simplest jobs
that can be submitted to the V3D. It is a 3D rendering job, so it is a job
submitted through the `v3d_submit_cl` ioctl, and performing this job on IGT was
fundamental to developing good tests for the `v3d_submit_cl` ioctl.

The main problem I faced on submitting a no-op job on IGT was: I would copy many
and many Mesa files to IGT. And I took a while fighting against this idea,
looking for other ways to submit a job to V3D. But, as some experience developers
pointed out, packeting is the best option for it. So indeed, the final solution
I came in with was to copy a couple of files from Mesa, but just three of them,
which sounds reasonable.

So, after some time, I was able to bring the Mesa structure to IGT with minimal
overhead. But, I was still not able to run a successful no-op job as the job’s
fence wasn't being signaled by the end of the job. Then, Melissa Wen guided me
to experiment running CTS tests to inspect the no-op job. With the CTS tests, I
was able to hexdump the contents of the packet and understand what was going on
wrong in my no-op job.

Running the CTS in the Raspberry Pi 4 was a fun side-quest of the project and
ended up resulting in a commit to the CTS repository, as CTS wasn't handling
appropriately the `wayland-scanner` for cross-compiling. CTS was picking the
`wayland-scanner` from the host computer instead of picking the
`wayland-scanner` executable available in the target sysroot. This was fixed
with this simple patch:

[**Allow override of wayland_scanner executable**](https://github.com/KhronosGroup/VK-GL-CTS/commit/6dfa0b69b46e69bdabd213ec2cf915bcd6e689f3)

When I finally got a successful no-op job, I was able to write the tests for the
`v3d_submit_cl` and `v3d_wait_bo` ioctls. On these tests, I tested primarily job
synchronization with single syncobjs and multiple syncobjs. In this part of the
project, I had the opportunity to learn a lot about syncobjs and different forms
of synchronization in the kernel and userspace.

Having done the `v3d_submit_cl` tests, I developed the `v3d_submit_csd` tests in
a similar way, as the job submission process is kind of similar. For submitting
a CSD job, it is necessary to make a valid submission with a pipeline assembly
shader and as IGT doesn't have a shader compiler, so I hard-coded the assembly
of an empty shader in the code. In this way, I was able to get a simple CSD job
submitted, and having done that, I could now play around with mixing CSD and CL
jobs.

In these tests, I could test the synchronization between two job queues and see,
for example, if they were proceeding independently.

So, by the end of the review process, I will add 66 new sub-tests to V3D, having
in total 72 IGT sub-tests! Those tests are checking invalid parameters,
synchronization, and the proper behavior of the functionalities.

| Patch/Series | Status |
| :---- | :----: |
| [\[PATCH 0/7\] V3D IGT Tests Updates](https://patchwork.freedesktop.org/series/110681/)           | **Accepted** |
| [\[PATCH 0/2\] Tests for V3D/VC4 Mmap BO IOCTLs](https://patchwork.freedesktop.org/series/112215/)| **Accepted** |
| [\[PATCH 0/4\] Make sure v3d/vc4 support performance monitor](https://patchwork.freedesktop.org/series/112370/) | In Review |
| [\[PATCH 0/6\] V3D Job Submission Tests](https://patchwork.freedesktop.org/series/112363/)        | In Review |
| [\[PATCH 0/3\] V3D Mixed Job Submission Tests](https://patchwork.freedesktop.org/series/112805/)  | In Review |

## [Mesa](https://gitlab.freedesktop.org/mesa/mesa)

Apart from reading a lot of kernel code, I also started to explore some of the
Mesa code, especially the `v3dv` driver. On Mesa, I was trying to understand the
userspace use of the ioctls in order to create useful tests. While I was
exploring the `v3dv`, I was able to make two very simple contributions to Mesa:
fixing typos and initializing a variable in order to assure proper error
handling.

| Patch | Status |
| :---- | :----: |
| [v3dv: fix multiple typos](https://gitlab.freedesktop.org/mesa/mesa/-/commit/d34f3a1db594c778e0c6bae7a5798742edb9635d)                               | **Accepted** |
| [v3dv: initialize fd variable for proper error handling](https://gitlab.freedesktop.org/mesa/mesa/-/commit/a2252adde8235d5c4d78d9347527cd7914bb905a) | **Accepted** |

# [IGT](https://gitlab.freedesktop.org/drm/igt-gpu-tools) tests to VC4
---

VC4 and V3D share some similarities in their basic 3D rendering implementation.
VC4 contains a 3D engine, and a display output pipeline that supports different
outputs. The display part of the VC4 is used on the Raspberry Pi 4 together with
the V3D driver.

Although my main focus was on the V3D tests, as the VC4 and V3D drivers are kind
of similar, I was able to bring some improvements to the VC4 tests as well. I
added tests for perfmons and the `vc4_mmap` ioctl and improved a couple of
things in the tests, such as moving it a separate folder and creating a check to
skip the VC4 tests if they are running on a Raspberry Pi 4.

| Patch/Series | Status |
| :---- | :----: |
| [\[PATCH 0/5\] VC4 IGT Tests Updates](https://patchwork.freedesktop.org/series/110948/)                         | **Accepted** |
| [\[PATCH 0/2\] Tests for V3D/VC4 Mmap BO IOCTLs](https://patchwork.freedesktop.org/series/112215/)              | **Accepted** |
| [\[PATCH 0/4\] Make sure v3d/vc4 support performance monitor](https://patchwork.freedesktop.org/series/112370/) | In Review |
| [tests/vc4_purgeable_bo: Fix conditional assertion](https://patchwork.freedesktop.org/patch/516737/)            | In Review |

# [Linux Kernel](https://cgit.freedesktop.org/drm/drm-misc/)
---

## V3D/VC4 drivers

During this process of writing tests to IGT, I ended up reading a lot of kernel
code from V3D in order to evaluate possible userspace scenarios. While
inspecting some of the V3D code, I could find a couple of small things that
could be improved, such as using the DRM-managed API for mutexes and replacing
open-coded implementations with their DRM counterparts.

| Patch | Status |
| :---- | :----: |
| [drm/v3d: switch to drmm_mutex_init](https://patchwork.freedesktop.org/series/110634/)                                  | **Accepted** |
| [drm/v3d: add missing mutex_destroy](https://patchwork.freedesktop.org/series/110634/)                                  | **Accepted** |
| [drm/v3d: replace open-coded implementation of drm_gem_object_lookup](https://patchwork.freedesktop.org/series/112257/) | **Accepted** |

Although I didn't explore the VC4 driver as much as the V3D driver, I also took
a look at the driver, and I was able to detect a small thing that could be
improved: using the DRM-core helpers instead of open-code. Moreover, after a
report on the mailing list, I bisected a deadlock and I was able to fix it after
some study about the KMS locking system.

| Patch | Status |
| :---- | :----: |
| [drm/vc4: drop all currently held locks if deadlock happens](https://patchwork.freedesktop.org/series/112299/)                                    | **Accepted** |
| [drm/vc4: replace drm_gem_dma_object for drm_gem_object in vc4_exec_info](https://patchwork.freedesktop.org/patch/516491/?series=112347&rev=1)    | In Review |
| [drm/vc4: replace obj lookup steps with drm_gem_objects_lookup](https://patchwork.freedesktop.org/patch/516490/?series=112347&rev=1)              | In Review |

## The debugfs side-quest

The debugfs side-quest was a total coincidence during this project. I had some
spare time and was looking for something to develop. While looking at the DRM
TODO list, I bumped into the debugfs clean-up task and found it interesting to
work on. So, I started to work on this task based on the previous work from
Wambui Karuga, who was a Outreachy mentee and worked on this feature during her
internship. By chance, when I talked to Melissa about it, she told me that she
had knowledge of this project due to a past Outreachy internship that she was
engaged on, and she was able to help me figure out the last pieces of
this side-quest.

After submitting the first patch, introducing the debugfs device-centered
functions, and converting a couple of drivers to the new structure, I decided to
remove the `debugfs_init` hook from a couple of drivers in order to get closer
to the goal of removing the `debugfs_init` hook. Moreover, during my last week
in the CE, I tried to write a debugfs infrastructure for the KMS objects, which
was another task in the TODO list, although I still need to do some rework on
this series.

| Patch/Series | Status |
| :----------- | :----: |
| [\[PATCH 0/7\] Introduce debugfs device-centered functions](https://patchwork.freedesktop.org/series/111216/)                             | **Accepted** |
| [drm/debugfs: use octal permissions instead of symbolic permissions](https://patchwork.freedesktop.org/patch/517186/?series=112451&rev=1) | **Accepted** |
| [drm/debugfs: add descriptions to struct parameters](https://patchwork.freedesktop.org/patch/517185/?series=112451&rev=1)                 | **Accepted** |
| [\[PATCH 0/7\] Convert drivers to the new debugfs device-centered functions](https://patchwork.freedesktop.org/series/112233/)            | **Accepted** |
| [\[PATCH 0/13\] drm/debugfs: Create a debugfs infrastructure for kms objects](https://patchwork.freedesktop.org/series/112684/)           | In Review |

## More side-quests

By the end of the CE, I was on my summer break from university, so I had some
time to take a couple of side-quests in this journey.

The first side-quest that I got into originated in a failed IGT test on the VC4,
the "addfb25-bad-modifier" IGT test. Initially, I proposed a fix only for the
VC4, but after some discussion in the mailing list, I decided to move forward
with the idea to create the check for valid modifiers in the DRM core. The
series is still in review, but I had some great interactions during the
iterations.

The second side-quest was to understand why the IGT test `kms_writeback` was
causing a kernel oops in vkms. After some bisecting and some study about KMS's
atomic API, I was able to detect the problem and write a solution for it. It was
pretty exciting to deal with vkms for the first time and to get some notion
about the display side of things.

| Patch/Series | Status |
| :----------- | :----: |
| [drm/tests: Split drm_test_dp_mst_calc_pbn_mode into parameterized tests](https://patchwork.freedesktop.org/patch/505760/?series=109345&rev=1)           | **Accepted** |
| [drm/tests: Split drm_test_dp_mst_sideband_msg_req_decode into parameterized tests](https://patchwork.freedesktop.org/patch/505761/?series=109345&rev=1) | **Accepted** |
| [tests/kms_addfb_basic: Avoid open-coded expressions](https://patchwork.freedesktop.org/series/516047/)                                                  | **Accepted** |
| [\[PATCH 0/3\] Check for valid framebuffer's format](https://patchwork.freedesktop.org/series/112546/)                                                   | In Review |
| [drm/vkms: reintroduce prepare_fb and cleanup_fb functions](https://patchwork.freedesktop.org/series/112487/)                                            | **Accepted** |

# Next Steps
---

A bit different from the end of GSoC, I'm not really sure what are going to be
my next steps in the next couple of months. The only thing I know for sure is
that I will keep contributing to the DRM subsystem and studying more about DRI,
especially the 3D rendering and KMS.

The DRI infrastructure is really fascinating and there is so much to be learn!
Although I feel that I improved a lot in the last couple of months, I still feel
like a newbie in the community. I still want to have more knowledge of the DRM
core helpers and understand how everything glues together.

Apart from the DRM subsystem, I'm also trying to take some time to program more
in Rust and maybe contribute to other open-source projects, like Mesa.

# Acknowledgment
---

I would like to thank my great mentors [Melissa
Wen](https://melissawen.github.io/) and [André
Almeida](https://andrealmeid.com/) for helping me through this journey. I
wouldn't be able to develop this project without their great support and
encouragement. They were an amazing duo of mentors and I thank them for
answering all my questions and helping me with all the challenges.

Also, I would like to thank the DRI community for reviewing my patches and
giving me constructive feedback. Especially, I would like to thank Daniel Vetter
for answering patiently every single question that I had about the debugfs
clean-up and to thank Jani Nikula, Maxime Ripard, Thomas Zimmermann, Javier
Martinez Canillas, Emma Anholt, Simon Ser, Iago Toral, Kamil Konieczny and
many others that took their time to review my patches, answer my questions and
provide me constructive feedback.
