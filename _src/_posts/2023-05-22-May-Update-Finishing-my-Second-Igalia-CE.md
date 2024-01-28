---
title: "May Update: Finishing my Second Igalia CE"
date: 2023-05-22T09:30:00-03:00
author: Maíra Canal
permalink: /may-update-finishing-my-second-igalia-ce/
categories: [Tech]
tags: [igalia, graphics]
---

After finishing up my first [Igalia Coding Experience](https://www.igalia.com/coding-experience/) in January, I got the amazing opportunity to keep working in the DRI community by extending my Igalia CE to a second round.
Huge thanks to [Igalia](https://www.igalia.com/) for providing me with this opportunity!

Another four months passed by and here I am completing another milestone with Igalia.
Previously, in the last final reports, I described GSoC as "an experience to get a better understanding of what open source is" and the first round of the Igalia CE as "an opportunity for me to mature my knowledge of technical concepts".
My second round of the Igalia CE was a period for broadening my horizons.

I had the opportunity to deepen my knowledge of a new programming language and learn more about Kernel Mode Setting (KMS).
I took my time learning more about Vulkan and the Linux graphics stack.
All of this new knowledge about the DRM infrastructure fascinated me and made me excited to keep developing.

So, this is a summary report of my journey at my second Igalia CE.

# Wrapping Up
---

First, I took some time to wrap up the contributions of my previous Igalia CE.
In my [January Update](/january-update-finishing-my-igalia-ce/), I described the journey to include IGT tests for V3D.
But at the time, I hadn't yet sent the final versions of the tests.
Right when I started my second Igalia CE, I sent the final versions of the V3D tests, which were accepted and merged.

| Series | Status |
| :---- | :----: |
| [[PATCH i-g-t 0/6] V3D Job Submission Tests](https://patchwork.freedesktop.org/series/112363/)       | **Accepted**|
| [[PATCH i-g-t 0/3] V3D Mixed Job Submission Tests](https://patchwork.freedesktop.org/series/112805/) | **Accepted**|

# Rustgem
---

The first part of my Igalia CE was focused on rewriting the VGEM driver in Rust.
VGEM (Virtual GEM Provider) is a minimal non-hardware-backed GEM (Graphics Execution Manager) service.
It is used with non-native 3D hardware for buffer sharing between the X server and DRI.

The goal of the project was to explore Rust in the DRM subsystem and have a working VGEM driver written in Rust.
Rust is a blazingly fast and memory-efficient language with its powerful **ownership model**.
It was really exciting to learn more about Rust and implement from the beginning a DRM driver.

During the project, I wrote two blog posts describing the technical aspects of `rustgem` driver.
If you are interested in this project, check them out!

| Date | Blogpost |
| :----: | :----: |
| 28th February | [Rust for VGEM](/rust-for-vgem/) |
| 22th March    | [Adding a Timeout feature to Rustgem](/adding-timeout-rustgem/) |

By the end of the first half of the Igalia CE, I sent an RFC patch with the `rustgem` driver.
Thanks to Asahi Lina, the Rust for Linux folks, and Daniel Vetter for all the feedback provided during the development of the driver.
I still need to address some feedback and rebase the series on top of the new pin-init API, but I hope to see this driver upstream soon.
You can check the driver's current status in this [PR](https://github.com/mairacanal/linux/pull/11).

| Series | Status |
| :---- | :----: |
| [[RFC PATCH 0/9] Rust version of the VGEM driver](https://lore.kernel.org/dri-devel/20230317121213.93991-1-mcanal@igalia.com/T/) | In Review |

Apart from rewriting the VGEM driver, I also sent a couple of improvements to the C version of the VGEM driver and its IGT tests.
I found a missing `mutex_destroy` on the code and also an unused struct.

| Patches | Status |
| :---- | :----: |
| [[PATCH] drm/vgem: add missing mutex_destroy](https://lore.kernel.org/dri-devel/20230202125517.427976-1-mcanal@igalia.com/T/)       | **Accepted** |
| [[PATCH] drm/vgem: Drop struct drm_vgem_gem_object](https://lore.kernel.org/dri-devel/20230222160617.171429-1-mcanal@igalia.com/T/) | **Accepted** |

On the IGT side, I added some new tests to the VGEM tests.
I wanted to ensure that my driver returned the correct values for all possible error paths, so I wrote this IGT test.
Initially, it was just for me, but I decided to submit it upstream.

| Series | Status |
| :---- | :----: |
| [[PATCH v3 i-g-t 0/2] Add negative tests to VGEM](https://patchwork.freedesktop.org/series/114912/) | **Accepted** |

# Virtual Kernel Mode Setting (VKMS)
---

Focusing on the VKMS was the major goal of the second part of my Igalia CE.
[Melissa Wen](https://melissawen.github.io/) is one of the maintainers of the VKMS, and she provided me with a fantastic opportunity to learn more about the VKMS.
So far, I haven't dealt with displays, and learning new concepts in the graphics stack was great.

## Rotating Planes

VKMS is a software-only KMS driver that is quite useful for testing and running X (or similar compositors) on headless machines.
At the time, the driver didn't have any support for optional plane properties, such as rotation and blend mode.
Therefore, my goal was to implement the first plane property of the driver: rotation.
I described the technicalities of this challenge in this [blog post](/rotating-planes-vkms/), but I can say that it was a nice challenge of this mentorship project.

In the end, we have the first plane property implemented for the VKMS and it is already committed.
Together with the VKMS part, I sent a series to the IGT mailing list with some improvements to the `kms_rotation_crc` tests.
These improvements included adding new tests for rotation with offset and reflection and the isolation of some Intel-specific tests.

| Series | Status |
| :---- | :----: |
| [[PATCH v4 0/6] drm/vkms: introduce plane rotation property](https://lore.kernel.org/dri-devel/20230418130525.128733-1-mcanal@igalia.com/T/) | **Accepted** |
| [[PATCH 1/2] drm/vkms: Add kernel-doc to the function vkms_compose_row()](https://lore.kernel.org/dri-devel/20230508220030.434118-1-mcanal@igalia.com/T/) | In Review |
| [[PATCH i-g-t 0/4] kms_rotation_crc improvements and generalization](https://patchwork.freedesktop.org/series/116025/) | In Review |

## Improvements

As I was working with the rotation series, I discovered a couple of things that could be improved in the VKMS driver.
Last year, Igor Torrente sent a series to VKMS that changed the composition work in the driver.
Before his series, the plane composition was executed on top of the primary plane.
Now, the plane composition is executed on top of the CRTC.

Although his series was merged, some parts of the code still considered that the composition was executed on top of the primary plane, limiting the VKMS capabilities.
So I sent a couple of patches to the mailing list, improving the handling of the primary plane and allowing full alpha blending on all planes.

Moreover, I sent a series that added a module parameter to set a background color to the CRTC.
This work raised an interesting discussion about the need for this property by the user space and whether this parameter should be a KMS property.

Apart from introducing the rotation property to the VKMS driver, I also took my time to implement two other properties: alpha and blend mode.
This series is still awaiting review, but it would be a nice addition to the VKMS, increasing its IGT test coverage rate.

Finally, I found a bug in the RGB565 conversion.
The RGB565 conversion to ARGB16161616 involves some fixed-point operations and, when running the `pixel-format` IGT test, I verified that the RGB565 test was failing.
So, some of those fixed-point operations were returning erroneous values.
I checked that the RGB coefficients weren't being rounded when converted from fixed-point to integers.
But, this should happen in order to provided the proper coefficient values.
Therefore, the fix was: implement a new helper that rounds the fixed-point value when converting it to a integer.

After performing all this work on the VKMS, I sent a patch adding myself as a VKMS maintainer, which was acked by Javier Martinez and Melissa Wen.
So now, I'm working together with Melissa, [Rodrigo Siqueira](https://siqueira.tech/) and all DRI community to improve and maintain the VKMS driver.

| Series | Status |
| :---- | :----: |
| [[PATCH v2 0/2] Update the handling of the primary plane](https://lore.kernel.org/dri-devel/20230324164226.256084-1-mcanal@igalia.com/T/)                 | **Accepted** |
| [[PATCH v2 1/2] drm/vkms: allow full alpha blending on all planes](https://lore.kernel.org/dri-devel/20230420232228.273340-1-mcanal@igalia.com/T/)        | **Accepted** |
| [[PATCH v2] drm/vkms: add module parameter to set background color](https://lore.kernel.org/dri-devel/20230410125435.128689-1-mcanal@igalia.com/T/)       | In Review |
| [[PATCH] drm/vkms: Implement all blend mode properties](https://lore.kernel.org/dri-devel/20230428122751.24271-1-mcanal@igalia.com/T/)                    | In Review |
| [[PATCH v3 1/2] drm: Add fixed-point helper to get rounded integer values](https://lore.kernel.org/dri-devel/20230512104044.65034-1-mcanal@igalia.com/T/) | **Accepted** |

## Virtual Hardware

A couple of years ago, Sumera Priyadarsini, an Outreachy intern, worked on a Virtual Hardware functionality for the VKMS.
The idea was to add a Virtual Hardware or vblank-less mode as a kernel parameter to enable VKMS to emulate virtual devices.
This means no vertical blanking events occur and page flips are completed arbitrarily when required for updating the frame.
Unfortunately, she wasn't able to wrap things up and this ended up never being merged into VKMS.

Melissa suggested rebasing this series and now we can have the Virtual Hardware functionality working on the current VKMS.
This was a great work by Sumera and my work here was just to adapt her changes to the new VKMS code.

| Series | Status |
| :---- | :----: |
| [[PATCH 0/2] drm/vkms: Enable Virtual Hardware support](https://lore.kernel.org/dri-devel/20230509150501.81875-1-mcanal@igalia.com/T/) | In Review |

## Bug Fixing!

Finally, I was in the last week of the project, just wrapping things up, when I decided to run the VKMS CI.
I had recently committed the rotation series and I had run the CI before, but to my surprise, I got the following output:

```shell
[root@fedora igt-gpu-tools]# ./build/tests/kms_writeback
IGT-Version: 1.27.1-gce51f539 (x86_64) (Linux: 6.3.0-rc4-01641-gb8e392245105-dirty x86_64)
(kms_writeback:1590) igt_kms-WARNING: Output Writeback-1 could not be assigned to a pipe
Starting subtest: writeback-pixel-formats
Subtest writeback-pixel-formats: SUCCESS (0.000s)
Starting subtest: writeback-invalid-parameters
Subtest writeback-invalid-parameters: SUCCESS (0.001s)
Starting subtest: writeback-fb-id
Subtest writeback-fb-id: SUCCESS (0.020s)
Starting subtest: writeback-check-output
(kms_writeback:1590) CRITICAL: Test assertion failure function get_and_wait_out_fence, file ../tests/kms_writeback.c:288:
(kms_writeback:1590) CRITICAL: Failed assertion: ret == 0
(kms_writeback:1590) CRITICAL: Last errno: 38, Function not implemented
(kms_writeback:1590) CRITICAL: sync_fence_wait failed: Timer expired
Stack trace:
  #0 ../lib/igt_core.c:1963 __igt_fail_assert()
  #1 [get_and_wait_out_fence+0x83]
  #2 ../tests/kms_writeback.c:337 writeback_sequence()
  #3 ../tests/kms_writeback.c:360 __igt_unique____real_main481()
  #4 ../tests/kms_writeback.c:481 main()
  #5 ../sysdeps/nptl/libc_start_call_main.h:74 __libc_start_call_main()
  #6 ../csu/libc-start.c:128 __libc_start_main@@GLIBC_2.34()
  #7 [_start+0x25]
Subtest writeback-check-output failed.
**** DEBUG ****
(kms_writeback:1590) CRITICAL: Test assertion failure function get_and_wait_out_fence, file ../tests/kms_writeback.c:288:
(kms_writeback:1590) CRITICAL: Failed assertion: ret == 0
(kms_writeback:1590) CRITICAL: Last errno: 38, Function not implemented
(kms_writeback:1590) CRITICAL: sync_fence_wait failed: Timer expired
(kms_writeback:1590) igt_core-INFO: Stack trace:
(kms_writeback:1590) igt_core-INFO:   #0 ../lib/igt_core.c:1963 __igt_fail_assert()
(kms_writeback:1590) igt_core-INFO:   #1 [get_and_wait_out_fence+0x83]
(kms_writeback:1590) igt_core-INFO:   #2 ../tests/kms_writeback.c:337 writeback_sequence()
(kms_writeback:1590) igt_core-INFO:   #3 ../tests/kms_writeback.c:360 __igt_unique____real_main481()
(kms_writeback:1590) igt_core-INFO:   #4 ../tests/kms_writeback.c:481 main()
(kms_writeback:1590) igt_core-INFO:   #5 ../sysdeps/nptl/libc_start_call_main.h:74 __libc_start_call_main()
(kms_writeback:1590) igt_core-INFO:   #6 ../csu/libc-start.c:128 __libc_start_main@@GLIBC_2.34()
(kms_writeback:1590) igt_core-INFO:   #7 [_start+0x25]
****  END  ****
Subtest writeback-check-output: FAIL (1.047s)
```

🫠 🫠 🫠 🫠 🫠 🫠 🫠 🫠 🫠 🫠 🫠 🫠 🫠 🫠 🫠 🫠

Initially, I thought I had introduced the bug with my rotation series.
Turns out, I just had made it more likely to happen.
This bug has been hidden in VKMS for a while, but it happened just on rare occasions.
Yeah, I'm talking about a race condition...
The kind of bug that just stays hidden in your code for a long while.

When I started to debug, I thought it was a performance issue.
But then, I increased the timeout to 10 seconds and even then the job wouldn't finish.
So, I thought that it could be a deadlock.
But after inspecting the DRM internal locks and the VKMS locks, it didn't seem the case.

Melissa pointed me to a hint: there was one framebuffer being leaked when removing the driver.
I discovered that it was the writeback framebuffer.
It meant that the writeback job was being queued, but it wasn't being signaled.
So, the problem was inside the VKMS locking mechanism.

After tons of GDB and ftrace, I was able to find out that the composer was being set twice without any calls to the composer worker.
I changed the internal locks a bit and I was able to run the test repeatedly for minutes!
I sent the fix for review and now I'm just waiting for a Reviewed-by.

| Patches | Status |
| :---- | :----: |
| [[PATCH] drm/vkms: Fix race-condition between the hrtimer and the atomic commit](https://lore.kernel.org/dri-devel/20230515134133.108780-1-mcanal@igalia.com/T/) | In Review |

While debugging, I found some things that could be improved in the VKMS writeback file.
So, I decided to send a series with some minor improvements to the code.

| Series | Status |
| :---- | :----: |
| [[PATCH 0/3] drm/vkms: Minor Improvements](https://lore.kernel.org/dri-devel/20230515135204.115393-1-mcanal@igalia.com/T/) | In Review |

# Improving IGT tests
---

If you run all IGT KMS tests on the VKMS driver, you will see that some tests will fail.
That's not what we would expect: we would expect that all tests would pass or skip.
The tests could fail due to errors in the VKMS driver or be wrong exceptions on the IGT side.
So, on the final part of my Igalia CE, I inspected a couple of IGT failures and sent fixes to address the errors.

## Linux Kernel

This patch is a revival of a series I sent in January to fix the IGT test `kms_addfb_basic@addfb25-bad-modifier`.
This test also failed in VC4, and I investigated the reason in January.
I sent a patch to guarantee that the test would pass and after some feedback, I came down to a dead end.
So, I left this patch aside for a while and decided to recapture it now.
Now, with this patch being merged, we can guarantee that the test  `kms_addfb_basic@addfb25-bad-modifier` is passing for multiple drivers.

| Patches | Status |
| :---- | :----: |
| [[PATCH] drm/gem: Check for valid formats](https://lore.kernel.org/dri-devel/20230412142923.136707-1-mcanal@igalia.com/T/) | **Accepted** |

## IGT

On the IGT side, I sent a couple of improvements to the tests.
The failure was usually just a scenario that the test didn't consider.
For example, the `kms_plane_scaling` test was failing in VKMS, because it didn't consider the case in which the driver did not have the rotation property.
As VKMS didn't use to have the rotation property, the tests were failing instead of skipping.
Therefore, I just developed a path for drivers without the rotation property for the tests to skip.

I sent improvements to the `kms_plane_scaling`, `kms_flip`, and `kms_plane` tests, making the tests pass or skip on all cases for the VKMS.

| Patches | Status |
| :---- | :----: |
| [[PATCH i-g-t] tests/kms_plane_scaling: negative tests can return -EINVAL or -ERANGE](https://patchwork.freedesktop.org/patch/533643/?series=116907&rev=1) | **Accepted** |
| [[PATCH i-g-t] tests/kms_plane_scaling: fix variable misspelling](https://patchwork.freedesktop.org/patch/533645/?series=116907&rev=1)                     | **Accepted** |
| [[PATCH i-g-t] tests/kms_plane_scaling: remove unused parameters](https://patchwork.freedesktop.org/patch/533644/?series=116907&rev=1)                     | **Accepted** |
| [[PATCH i-g-t] tests/kms_plane_scaling: Only set rotation if rotation != rotate-0](https://patchwork.freedesktop.org/series/117250/)                       | **Accepted** |
| [[PATCH v2 i-g-t] tests/kms_flip: Check if is Intel device before doing all the setup](https://patchwork.freedesktop.org/series/117246/)                   | **Accepted** |
| [[PATCH i-g-t v2] tests/kms_plane: allow pixel-format tests to run on drivers without legacy LUT](https://patchwork.freedesktop.org/patch/533753/)         | In Review |


## VKMS CI List

One important thing to VKMS is creating a baseline of generic KMS tests that should pass.
This way, we can test new contributions against this baseline and avoid introducing regressions in the codebase.
I sent a patch to IGT to create a testlist for the VKMS driver with all the KMS tests that must pass on the VKMS driver. This is great for maintenance, as we can run the testlist to ensure that the VKMS functionalities are preserved.

With new features being introduced in VKMS, it is important to keep the test list updated.
So, I verified the test results and updated this test list during my time at the Igalia CE.
I intend to keep this list updated as long as I can.

| Series | Status |
| :---- | :----: |
| [[PATCH i-g-t] tests/vkms: Create a testlist to the vkms DRM driver](https://patchwork.freedesktop.org/series/112972/) | **Accepted** |
| [[PATCH i-g-t 0/3] tests/vkms: Update VKMS's testlist](https://patchwork.freedesktop.org/series/116316/)               | **Accepted** |

# Acknowledgment
---
First, I would like to thank my great mentor [Melissa Wen](https://melissawen.github.io/).
Melissa and I are completing a year together as mentee and mentor and it has been an amazing journey.
Since GSoC, Melissa has been helping me by answering every single question I have and providing me with great encouragement.
I have a lot of admiration for her and I'm really grateful for having her as my mentor during the last year.

Also, I would like to thank [Igalia](https://www.igalia.com/) for giving me this opportunity to keep working in the DRI community and learning more about this fascinating topic.
Thanks to all Igalians that helped through this journey!

Moreover, I would like to thank the DRI community for reviewing my patches and giving me constructive feedback.
Especially, I would like to thank Asahi Lina, Daniel Vetter and the Rust for Linux folks for all the help with the `rustgem` driver.

