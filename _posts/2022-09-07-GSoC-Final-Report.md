---
title: "GSoC Final Report"
date: 2022-09-07
author: Maíra Canal
layout: post
permalink: /gsoc-final-report/
categories: Genel
tags: [gsoc, linux, kernel]
---

My journey on the Google Summer of Code project passed by so fast… This is my
last week on the GSoC and those 14 weeks flew by! A lot of stuff happened during
those three months, and as I’m writing this blog post, I feel quite nostalgic
about this three months.

Before I started GSoC, I never thought I would send so many patches to the
mailing list, have an abstract approved on XDC 2022, or have commit rights on
drm-misc.

GSoC was indeed a fantastic experience. It gave me the opportunity to grow as a
developer in an open source community and I believe that I ended up GSoC with a
better understanding of what open source is. I learned more about the community,
how to communicate with them, and who are the actors in this workflow.

So, this is a summary report of all my journey at GSoC 2022.

# Contributions during GSoC 2022
---

First I will kick off with my non-related contributions. I mean, they are
somehow related to my project, but they are not exactly unit tests for AMDGPU.

### kworkflow

[kworkflow](https://github.com/kworkflow/kworkflow) is a tool for reducing the
environment and setup overhead of developing for Linux, which is maintained by
my mentor Rodrigo Siqueira. I use it to manage my config files, deploy to my
testing machine, check code style, and more. Initially, kw didn’t have support
to deploy for Fedora-based machines.

During the Community Bonding Period, I added support to deploy Fedora-based
machines and I wrote a bit about this story in this [blog
post](https://mairacanal.github.io/kernel-development-fedora/).  Moreover, I
fixed a couple of bugs that I spotted while using it.

| Patch | Status |
| :---- | :----: |
| [docs: dependencies: Add pv to Fedora dependencies](https://github.com/kworkflow/kworkflow/pull/601)           | **Accepted** |
| [src: kwlib: check if the context is inside a git worktree](https://github.com/kworkflow/kworkflow/pull/602)   | **Accepted** |
| [Add deploy support to Fedora-based systems](https://github.com/kworkflow/kworkflow/pull/613)                  | **Accepted** |
| [src: help: Fix renaming of configm to kernel-config-manager](https://github.com/kworkflow/kworkflow/pull/649) | **Accepted** |

### IGT

[IGT GPU Tools](https://gitlab.freedesktop.org/drm/igt-gpu-tools) is a
collection of tools for the development and testing of DRM drivers. During GSoC,
I ran the AMDGPU suite a couple of times on my testing machine with a single
display connected through HDMI. With this setup, I was able to detect a couple
of failures on the IGT tests and I reported some of those issues on the [AMD bug
tracker](https://gitlab.freedesktop.org/drm/amd/-/issues), but also I sent two
patches fixing a couple of failures on the test.

| Patch | Status |
| :---- | :----: |
| [\[i-g-t,v2\] tests/amdgpu: Skip multihead MPO tests on single display](https://patchwork.freedesktop.org/patch/495078/)      | **Accepted** |
| [\[i-g-t,v2\] tests/amdgpu/amd_bypass: skip if connector is not DisplayPort](https://patchwork.freedesktop.org/patch/497794/) | On Review    |

### Linux Kernel - KUnit

[KUnit](https://docs.kernel.org/dev-tools/kunit/) is the Kernel Unit Testing
Framework. It is the framework we used for creating unit tests for the AMDGPU
drivers. My patches to KUnit are based on problems that I noticed I could
improve while I was writing unit tests for VBA. First, I fixed a simple
documentation error I spotted when I consulted the docs. The other patches are a
bit more interesting.

While I was writing some tests, I realize I was using a lot of expectations such as:

```c
KUNIT_EXPECT_EQ(test, memcmp(buffer1, buffer2, size), 0);
```

And I also realize that the output of this expectation can be quite non-helpful,
as it only gives the output of the `memcmp` function. So, I created an
expectation macro for analyzing blocks of memory and outputs the hexdump of the
memory.

It was a great community experience to interact with the KUnit developers and
work on their feedback.

| Patch | Status |
| :---- | :----: |
| [Documentation: KUnit: Fix example with compilation error](https://lore.kernel.org/linux-kselftest/20220720185719.273630-1-mairacanal@riseup.net/T/#u) | **Accepted** |
| [kunit: Introduce KUNIT_EXPECT_MEMEQ and KUNIT_EXPECT_MEMNEQ macros](https://lore.kernel.org/linux-kselftest/20220808125237.277126-2-mairacanal@riseup.net/) | **Accepted** |
| [kunit: Add KUnit memory block assertions to the example_all_expect_macros_test](https://lore.kernel.org/linux-kselftest/20220808125237.277126-3-mairacanal@riseup.net/) | **Accepted** |
| [kunit: Use KUNIT_EXPECT_MEMEQ macro](https://lore.kernel.org/linux-kselftest/20220808125237.277126-4-mairacanal@riseup.net/) | **Accepted** |

### Linux Kernel - DRM

In the DRM subsystem, I contributed to the DRM unit tests, which used to be
selftests and I converted them to KUnit during an LKCamp hackathon with other
students. I explained more about those tests in this [blog
post](https://mairacanal.github.io/from-selftests-to-KUnit/).  After those
patches were merged, I dedicated myself to some janitorial duties on the tests
folders: fixing stack warnings, refactoring some tests, and making the naming
more consistent.

Also, this summer, I [applied for commit
rights](https://gitlab.freedesktop.org/freedesktop/freedesktop/-/issues/450) on
the drm-misc repository and it was approved. I got pretty glad to have commit
rights, although I believe it is such a huge responsibility and I plan to use
this right very carefully.  I must thank my mentor Melissa Wen for encouraging
me to ask for commit rights and for sharing her knowledge about the community
and maintainership models (and also for answering a thousand questions I had
about dim).

| Patch | Status |
| :---- | :----: |
| [drm: selftest: convert drm_damage_helper selftest to KUnit](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#m3e0a2a318c5e1689c6a984d2bd4a5679e858eeff) | **Accepted** |
| [drm: selftest: convert drm_cmdline_parser selftest to KUnit](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#mf58d435b607096449365fd5d3819302d3ca548c6) | **Accepted** |
| [drm: selftest: convert drm_rect selftest to KUnit](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#m5f3b4cbaa011ea730d7017fcd193e6b1b7d7bae8) | **Accepted** |
| [drm: selftest: convert drm_format selftest to KUnit](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#m5725eabec8f19609ed68bce362da7239a10e3ff2) | **Accepted** |
| [drm: selftest: convert drm_plane_helper selftest to KUnit](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#m32d0d32fac5f1ef5a67c5844acc6e1793e0b4d53) | **Accepted** |
| [drm: selftest: convert drm_dp_mst_helper selftest to KUnit](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#m0434c83b951ad9db5d6cf99abdb7244191246ebd) | **Accepted** |
| [drm: selftest: convert drm_framebuffer selftest to KUnit](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#m35dddb45de1ee298e1076c44334af736cc881a38) | **Accepted** |
| [drm: selftest: convert drm_buddy selftest to KUnit](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#m54ddcbd30df811ef9ec704cc70fa04c24e0f7f8c) | **Accepted** |
| [drm: selftest: convert drm_mm selftest to KUnit](https://lore.kernel.org/dri-devel/20220708203052.236290-1-maira.canal@usp.br/T/#m25364c46c57f6513cd1c04588fb8c7e35c0eaa63) | **Accepted** |
| [drm/tests: Split up test cases in igt_check_drm_format_min_pitch](https://lore.kernel.org/dri-devel/20220729124726.748221-1-mairacanal@riseup.net/T/#u) | **Accepted** |
| [drm/mm: Reduce stack frame usage in \_\_igt_reserve](https://lore.kernel.org/dri-devel/20220828182543.155415-1-mairacanal@riseup.net/T/#u) | On Review |
| [drm/tests: Split drm_framebuffer_create_test into parameterized tests](https://lore.kernel.org/dri-devel/20220901124210.591994-1-mairacanal@riseup.net/T/#mf7a08ad198b95199a4beec1cdbe4c25b24771f72) | On Review |
| [drm/tests: Change "igt_" prefix to "test_drm_"](https://lore.kernel.org/dri-devel/20220901124210.591994-1-mairacanal@riseup.net/T/#mfded29eaff1d5209f5a9c27ab952a367121520d4) | On Review |

### Linux Kernel - AMDGPU

Most of my patches to the AMDGPU branch were ideas that I had while writing the
unit tests on VBA. The `display_mode_vba` files were automatically generated,
which means that the code might not be the most readable one. During the summer,
I had a couple of ideas for cleaning up a bit of the VBA files and some of those
ideas are documented in this [blog
post](https://mairacanal.github.io/does-the-linux-kernel-need-software-engineering/).
And most of my patches are related to this matter.

But, most of the patches I sent related to the VBA files weren’t merged and
there was also no feedback on the patches. Some were sent multiple times, but I
didn’t get an answer. The DML is a very sensitive part of the AMDGPU driver, so
big changes might not be suitable for them.

Moreover, there are a couple of fixes. My favorite one is the `drm/amdgpu: Fix
use-after-free on amdgpu_bo_list mutex`, which was a fix to a use-after-free
problem that appeared in the [mailing
list](https://lore.kernel.org/dri-devel/CABXGCsM58-8fxVKAVkwsshg+33B_1_t_WesG160AtVBe1ZvKiw@mail.gmail.com/).
It was fun to read the output provided in the mailing-list and then track the
bug based on the trace. Also, it was a really nice interaction with other
developers on the mailing list.

| Patch | Status |
| :---- | :----: |
| [drm/amd/display: Remove return value of Calculate256BBlockSizes](https://lore.kernel.org/amd-gfx/20220630185005.908140-1-mairacanal@riseup.net/T/#u) | **Accepted** |
| [drm/amd/display: Remove duplicate code across dcn30 and dcn31](https://lore.kernel.org/amd-gfx/20220630201741.991501-1-mairacanal@riseup.net/T/#u) | **Accepted** |
| [drm/amd/display: Remove unused variables from vba_vars_st](https://lore.kernel.org/amd-gfx/20220630215316.1078841-1-mairacanal@riseup.net/T/#u) | **Accepted** |
| [drm/amdgpu: Write masked value to control register](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#m329c95bbd613b7d3368a7a675a1dd90b3cce70af) | **Accepted** |
| [drm/amd/display: Change get_pipe_idx function scope](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#m4c0a16330b7574782a201f10b67d5ea744b601a4) | **Accepted** |
| [drm/amd/display: Remove unused clk_src variable](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#mcfd965e613d064800a6a82a54e064e8e3e949cc3) | **Accepted** |
| [drm/amd/display: Remove unused dml32_CalculatedoublePipeDPPCLKAndSCLThroughput function](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#m1f2614742170fe4b2238427cf36dcb98f06b05e5) | **Accepted** |
| [drm/amd/display: Remove unused NumberOfStates variable](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#m2eb569fdabada2d7ae430770bd84ae5c5021cef5) | **Accepted** |
| [drm/amd/display: Remove unused variables from dml_rq_dlg_get_dlg_params](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#mf1cd1a70ece1c995a9fef2481a0d4524df92ee3f) | **Accepted** |
| [drm/amd/display: Remove unused value0 variable](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#m96df7c5e1ee5fcbb05c157cce660540920d42579) | On Review |
| [drm/amd/display: Remove unused variables from dcn10_stream_encoder](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#m5406d98a3e27102d07028c2059a151be8bff04d5) | **Accepted** |
| [drm/amd/display: Remove unused MaxUsedBW variable](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#m4dbd50a2e1006e0544da24d523c8fd9b4efa22b4) | **Accepted** |
| [drm/amd/display: Remove parameters from dml30_CalculateWriteBackDISPCLK](https://lore.kernel.org/amd-gfx/94dad704-d81a-7dc2-423d-1f728bcb5548@riseup.net/T/#m64fe69263faf9c3d434c4d757857e3e8937272f2) | Rejected |
| [drm/amd/display: Drop dm_sw_gfx7_2d_thin_l_vp and dm_sw_gfx7_2d_thin_gl](https://lore.kernel.org/amd-gfx/aaf722ef-7ead-9d88-ec66-0ab269b65a8f@igalia.com/T/#m1a29f8055054a95f03d47932ac3f303ab24ce7c1) | On Review |
| [drm/amd/display: Remove duplicated CalculateWriteBackDISPCLK](https://lore.kernel.org/amd-gfx/aaf722ef-7ead-9d88-ec66-0ab269b65a8f@igalia.com/T/#m2738ab7461b351dd06e74f2787ddd9134c5a9388) | On Review |
| [drm/amd/display: Remove parameters from rq_dlg_get_dlg_reg](https://lore.kernel.org/amd-gfx/aaf722ef-7ead-9d88-ec66-0ab269b65a8f@igalia.com/T/#m9e24bbe5084ccc37117a58e72e2afd6d2a419f1f) | On Review |
| [drm/amd/display: Rewrite CalculateWriteBackDISPCLK function](https://lore.kernel.org/amd-gfx/aaf722ef-7ead-9d88-ec66-0ab269b65a8f@igalia.com/T/#ma7a739d910814895f6d98c6374d1f1dca24ee1b4) | On Review |
| [drm/amd/display: Remove unused struct freesync_context](https://lore.kernel.org/amd-gfx/13140020-8139-64f9-51b1-2b71c9b673af@amd.com/T/#m81d3f8826c1247bd0b737f3469943881f0d6484f) | **Accepted** |
| [\[PATCH 00/16\] Remove entries from struct vba_vars_st](https://lore.kernel.org/amd-gfx/20220728182047.264825-1-mairacanal@riseup.net/T/#m50433ff9ec6f795bf0564ac0edb90c1a8d7e56e4) | On Review |
| [drm/amd/display: Drop XFCEnabled parameter from CalculatePrefetchSchedule](https://lore.kernel.org/amd-gfx/20220801124006.89027-1-mairacanal@riseup.net/T/#u) | On Review |
| [drm/amdgpu: Fix use-after-free on amdgpu_bo_list mutex](https://lore.kernel.org/amd-gfx/20220815113931.53226-1-mairacanal@riseup.net/T/#u) | **Accepted** |
| [drm/amd/display: Include missing header](https://lore.kernel.org/dri-devel/20220818132730.399334-1-mairacanal@riseup.net/T/#u) | **Accepted** |

# The KUnit AMDGPU Tests
---

After this huge tangent, let’s jump into the real milestones of the GSoC
project. Making a small recapitulation of the idea of my project:

> The Display Mode Library (DML) is a fundamental part of the AMDGPU driver. It
> involves lots of complex calculations and a large number of parameters. That
> said, it points to itself as a great candidate for the implementation of unit
> tests. Unit tests will help graphic developers recognize bugs before they are
> merged into the mainline and make it possible for a future code refactor. This
> project intends to implement unit testing in the Display Mode VBA libraries,
> especially the Display Mode VBA public API and the DCN20's Display Mode VBA
> functions.
> 

In my project, the deliverables were:

- Eleven unit tests for all the public functions on `display_mode_vba` and `display_mode_vba20`.
- Five blog posts on the progress, problems, concepts, and all.
- Run the unit tests on the AMDGPU Radeon RX 5700 XT.
- Write documentation for the tests.

So, let’s discuss point by point the milestones of this summer.

### The Unit Tests and Documentation

First, I had the intention to write unit tests for all the public functions on
`display_mode_vba` and `display_mode_vba20`, which are eleven functions in
total. Initially, it seems like a good idea to test only the public functions,
which is usually recommended by Software Engineering authors.

I started following this plan, but as I was learning more about unit testing, I
started questioning the feasibility of tests for some functions. I mean, a couple
of functions had **more than 45 input parameters** and **more than a thousand
lines**. Checking all the possible code branches of those tests seemed to me
unfeasible because there were a lot of variables to be considered.

> As the function size and the number of parameters grow, the complexity of the
> tests grows exponentially.
> 

So, I ended up writing tests for some static VBA functions. In the end, I wrote
more than eleven unit tests but the functions for which they were written are
not the same as planned initially.

The functions were chosen by two means. First, I was trying to identify
functions with a more suitable behavior for unit tests. Basically, functions
with no more than 10 parameters and 100 lines. Also, I was looking for functions
that were used a lot in the code, in order to increase the coverage and the
relevance of the tests. But also, sometimes,  Siqueira would suggest some
functions outside of VBA, such as the `dc_dmub_srv` case, which was inspired on
a regression.

Moreover, I also wrote documentation for the tests, giving instructions on how
to run the tests and how to add more tests to the AMDGPU driver.

The patches with the test suites and documentation are listed here:

| Patch | Status |
| :---- | :----: |
| [drm/amd/display: Introduce KUnit tests to the bw_fixed library](https://lore.kernel.org/dri-devel/20220831172239.344446-1-mairacanal@riseup.net/T/#m3a62416af08cd8cef240508798f6072722200573) | On Review |
| [drm/amd/display: Introduce KUnit tests to the display_mode_vba library](https://lore.kernel.org/dri-devel/20220831172239.344446-1-mairacanal@riseup.net/T/#m55ea9a62f44c3dcf65542078e1c3acbc03dd792d) | On Review |
| [drm/amd/display: Introduce KUnit to dcn20/display_mode_vba_20 library](https://lore.kernel.org/dri-devel/20220831172239.344446-1-mairacanal@riseup.net/T/#mcc325378f9ff07c2666f3a0b4d0eb4160d9d8ace) | On Review |
| [drm/amd/display: Introduce KUnit tests to dc_dmub_srv library](https://lore.kernel.org/dri-devel/20220831172239.344446-1-mairacanal@riseup.net/T/#mbd33411310664d71abe907c6b21688c498e8e680) | On Review |
| [Documentation/gpu: Add Display Core Unit Test documentation](https://lore.kernel.org/dri-devel/20220831172239.344446-1-mairacanal@riseup.net/T/#m9973c9d5a7f45ce223fc9724fa548e7ef570a0d1) | On Review |

The tests are not merged yet and are currently on the second version, but there
are some good changes that the tests will be merged soon to the mainline.

Moreover, I was able to run all the unit tests developed on the AMDGPU Radeon RX
5700 XT, and also with the kunit-tool.

### The Blog Posts

During the summer, I wrote five blog posts about challenges that I found
interesting in my journey. All blog posts are listed here:

| Date | Post |
| :----: | :----: |
| May 26, 2022 | [I'm in GSoC '22](https://mairacanal.github.io/gsoc-22/) |
| Jun 11, 2022 | [Linux Kernel Developing with Fedora](https://mairacanal.github.io/kernel-development-fedora/) |
| Jul 11, 2022 | [About Kernel Symbol Table, Compilation, and more](https://mairacanal.github.io/kernel-symbol-table-compilation-more/) |
| Jul 19, 2022 | [From Selftests to KUnit](https://mairacanal.github.io/from-selftests-to-KUnit/) |
| Aug 10, 2022 | [Does the Linux Kernel need software engineering?](https://mairacanal.github.io/does-the-linux-kernel-need-software-engineering/) |

# More than just code
---

During this summer, I was able to evolve my community skills also. Before I
joined GSoC, I didn’t though I had enough knowledge to review code from others
or even read the mailing list. Now, I have more confidence to review and test
some patches (and even commit a patch).

During GSoC, I developed the habit to read the mailing list daily. Although I
don’t really get everything that is going on there, I read a couple of threads
and try to understand what is being discussed. And it became a fun part of my
day to open Thunderbird and read the mailing lists from AMDGPU, DRM, KUnit, and
Fedora Devel.

Moreover, during my mailing list readings, I was able to find some discussions
that I could contribute to and even review patches. Initially, I didn’t have
confidence enough to send a Reviewed-by, so I used to send just a Tested-by.
But, now I feel more courage to send a Reviewed-by and make an argument for my
points on the mailing lists.

I made more than a dozen interactions on the mailing list, so I will just list
the more relevant ones:

1. **My first Tested-by:** This was after some interaction with David Gow on the
   AMDGPU Unit Tests RFC. I stated the need for enabling tests to link to the
   AMDGPU module and this culminated in some patches for it, where I sent my
   [Tested-by](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=3d6e44623841c8b82c2157f2f749019803fb238a).
   Also this discussion was the inspiration for this [blog
   post](https://mairacanal.github.io/kernel-symbol-table-compilation-more/).
2. **Documentation Reviews on KUnit:** I reviewed a couple of KUnit
   documentation patches, such as
   [1](https://lore.kernel.org/lkml/Yt+wq+xo2Tp6oEF%2F@debian.me/T/) and
   [2](https://lore.kernel.org/all/20220822022646.98581-1-tales.aparecida@gmail.com/).
3. **Spot an error in an IGT patch:** This is a [simple
   one](https://patchwork.freedesktop.org/patch/491515/), but it make me realize
   that I was about to help with my reviews.
4. **Reported a failing KUnit test:** I was checking LKFT some day, and I
   realized that some KUnit tests were failing in all architectures. So, I [sent
   an
   email](https://lore.kernel.org/all/346cb279-8e75-24b0-7d12-9803f2b41c73@riseup.net/)
   reporting the failure to the tests’s author and [he fixed the
   tests](https://lore.kernel.org/all/cover.1661234636.git.sander@svanheule.net/).
5. **PowerPC Compilation Fixes:** On the same day I sent a patch fixing a
   PowerPC warning on the DRM tests, Melissa asked me how I cross-compiled for
   PPC on IRC as she was working on a PPC warning. I was happy I could help her
   with this ~~after some hours of failing to cross-compile for PPC.~~ This resulted
   in other
   [review](https://lore.kernel.org/lkml/20220720193208.1131493-1-mwen@igalia.com/T/)
   and also a great interaction. 

Moreover, I also
[committed](https://cgit.freedesktop.org/drm/drm-misc/log/?qt=committer&q=Ma%C3%ADra+Canal)
two patches on `drm-misc-next`. I reviewed to patches for improving the DRM
KUnit tests and by the end of the review, I usually wait for someone to push the
patches into `drm-misc-next`, but as those patches were on the list for a while,
I decided to push it myself. I was pretty afraid of doing something wrong, but
all went fine with a bit of help from Melissa.

# Next Steps
---

Well, I’m pretty excited about the next couple of months for many reasons.
First, I, [Magali Lemes](https://magalilemes.github.io/), and [Isabella
Basso](https://crosscat.me/) will be attending XDC 2022. It is going to be very
exciting to participate in an in-place conference and also to make a
presentation on the main track.

We are going to talk about the “KUnit sorcery and the uncanny nature of FPU in
the DRM” on October 4th, presenting a bit of our GSoC project. So, currently,
I’m training a lot to make a good presentation in October.

Moreover, I intend to keep contributing to the DRM subsystem, and currently, I
have some ideas for some code refactors of the DRM KUnit tests. Also, I would
like to expand my contributions on the DRM to not only test-related. Although I
do like to write unit tests, I want to learn more about planes, CRTC, color
management, memory management, and more. Currently, most of my contributions are
related to janitorial duties and I would like to contribute to implementing new
features on the DRM or improving the DRM core.

Finally, by the end of GSoC, I’ll be joining another mentorship project on the
Linux Graphics Stack, the [Igalia Coding
Experience](https://www.igalia.com/coding-experience/), in which I will be learning
more about the DRM subsystem and IGT in the next months. This is making me very
excited, as I will continue to contribute with open source, especially the Linux
kernel, with the help of my great mentors Melissa Wen and André Almeida, who are
software engineers on Igalia.

# **Acknowledgment**
---

First, I would like to thank my mentors Rodrigo Siqueira, Melissa Wen, and André
Almeida. They really believed in our potential, encouraged us to talk to the
community, and show us some great opportunities. They were an amazing team of
mentors and I will always be thankful to them. Without them, I would probably
never would had submitted a project to GSoC.

Also, I would like to thank the X.Org Foundation for accepting
my proposal to GSoC and also helping us with funding for XDC 2022.

Moreover, I would like to thank AMD for donating hardware for us. During the
project, I used a Radeon RX 5700 XT donated by them, so I’m also very thankful
to them. Moreover, I would like to thank all AMD engineers that took their time
to review my patches and send feedback.

Finally, I would like to thank the DRI community for reviewing my patches and
giving me constructive feedback. Also, the KUnit community, especially David
Gow, Daniel Latypov, and Brendan Higgins, review a lot of my patches and took
their time to meet with us this summer.

Last, but not least, I thank the companionship of my colleagues Isabella Basso,
Magali Lemes, and Tales Aparecida during this summer. It was great to have some
companions to solve problems this summer and to share knowledge.
