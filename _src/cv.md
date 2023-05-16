---
title: Curriculum Vitae
permalink: /cv/
---

My interests in computing include free software, software engineering, systems
development, operating systems and compilers.

I started to play around with embedded systems in 2020 and since them, I never
stopped. I felt in love with the Linux operating systems and in 2021, I decided
to start contributing to this exciting operating system. I contributed to a
couple of open-source projects during my journey, but mostly I contribute to the
Linux Kernel, especially the DRM subsystem.

I still enjoy to work with embedded systems and I really like to program in
Rust, C and C++. Moreover, on my spare time, I enjoy programming old-school
embedded systems in assembly. I'm familiar to the x86, ARM and MIPS assembly.

I’m a Computer Engineering student at the São Carlos School of Engineering
(EESC-USP). During my time at the university, I served as an Embedded Systems
Monitor, and I've developed a research paper to analyze the application of
Embedded Linux in soft real-time applications.

Outside of computing, I enjoy listening to vinyls, playing board games, playing
retro games and traveling. I love learning new things and teaching what I know
to others.

## Education

### Computer Engineering (2020 - present)

[University of São Paulo](https://usp.br)

USP is considered to be Brazil's most prestigious university, and is frequently
ranked the top university in Latin America.

I've studied different areas in computing, and gained a lot of hard and soft
skills. Subjects I've particularly enjoyed include Software Engineering,
Data Structures, Compilers, and Operating Systems.

During my graduation, I was part of a extracurricular that develops aerospace
technologies, [Zenith Aerospace](https://zenith.eesc.usp.br/). There I was able
to learn programming skills and be exposed for the first time to open-source.

## Research

### FAPESP Undergraduate Researcher (2021 - 2023)

[A comparison between Linux approaches for soft real-time
applications](https://bv.fapesp.br/en/bolsas/200524/a-comparison-between-linux-approaches-for-soft-real-time-applications/)

I developed a research called "A comparison between Linux approaches for soft
real-time applications" with the sponsorship of The São Paulo Research Foundation
(FAPESP).

The research intended to implement routines in User Space and Kernel Space on a
Linux-based distribution and, also, in Linux real-time patches, such as Xenomai
and PREEMPT RT in order to evaluate the latency time, jitter, and worst-case
response time of the system on the Beaglebone Black.

Also I helped Professor Dr. Glauco Caurin during the first semester of 2021 in
the Embedded Systems Course (SEM 0544) at the University of S ̃ao Paulo and
planned classes involving Linux Device Drivers.

## Open Source Experience

### Igalia Coding Experience (2022 - present)

During the [Igalia Coding
Experience](https://www.igalia.com/coding-experience/),
I worked on increasing the [IGT test coverage on DRM/V3D kernel
driver](https://patchwork.freedesktop.org/series/109011/). This
involved understanding the inner workings of the DRM/V3D kernel driver and,
also, understanding its usage on Mesa.

Also, I improved existing [IGT test for DRM/VC4 kernel
driver](https://patchwork.freedesktop.org/series/110948/) and also created
new tests.

I helped to develop and upstream a device-centered interface for the [DRM’s
debugfs](https://patchwork.freedesktop.org/series/111216/).

The Igalia CE provided me an opportunity to improve my knowledges on DRI
development and made a better open-source developer. I learned a lot of new
graphics concepts and I became more familiar to the Linux graphics stack. The
final report of my experience is provided
[here](/january-update-finishing-my-igalia-ce/).

During the second round of the Igalia CE, I rewrote the [Virtual GEM (VGEM)
driver in Rust](/rust-for-vgem/), helping the Rust
for Linux project to develop more safe abstractions for the Kernel.

### Google Summer of Code (2022)

[Google Summer of Code](https://summerofcode.withgoogle.com/) is a global,
online program focused on bringing new contributors into open source software
development. I was accepted as a X.Org Foundation contributor in GSoC 2022.

I developed unit tests for the display core of the AMDGPU kernel
driver with the use of the KUnit framework. My Final Report is available
[here](/gsoc-final-report/). Moreover, I converted
the [DRM selftests to KUnit unit tests](https://patchwork.freedesktop.org/series/106128/).
I also parameterized the unit tests and fixed build issues.

As I was developing tests, I realized that comparing arrays with KUnit was not
very intuitive. So, I created a [new KUnit Expectation to compare memory
blocks](https://git.kernel.org/pub/scm/linux/kernel/git/shuah/linux-kselftest.git/commit/?h=kunit&id=b8a926bea8b1e790b0afe21359c086e3ee08aee5).

During GSoC, I also tried to help debug and fix AMDGPU bugs reported by users,
such as [use-after-free problems](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=bbca24d0a3c11193bafb9e174f89f52a379006e3).

## Open Source Contributions

### Linux Kernel

I have contributed with more than [80 approved
patches](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/log/?qt=author&q=Ma%C3%ADra+Canal)
to the Linux Kernel in the regulator, SPI, media, IIO, mfd, and DRM subsystems.
The DRM subsystem is the community which I’m most engaged with, where I also
review patches and interact with other contributors on the mailing list. I have
commit rights on the drm-misc tree and I [have
committed](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/log/?qt=committer&q=Ma%C3%ADra+Canal)
specially test-related patches. Also, I'm one of the [Virtual Kernel Mode Setting
(VKMS)](https://dri.freedesktop.org/docs/drm/gpu/vkms.html) maintainers.

### IGT

I have more than 30 [contributions](https://gitlab.freedesktop.org/drm/igt-gpu-tools/-/commits/master?search=Ma%C3%ADra+Canal) to the IGT project, especially on the AMDGPU,
V3D and VC4 tests. Recently, I'm also contributing to some KMS tests in order to
guarantee that the tests are working properly on VKMS.

### Fedora

I maintain a couple of [Fedora
packages](https://src.fedoraproject.org/user/mairacanal) (especially, Rust
packages) and help on Fedora QA test days. Moreover, I help with localization of
many GNOME applications to [Brazilian
Portuguese](https://l10n.gnome.org/users/mairacanal/).

### Other contributions

As I prefer to use open source tools, I frequently hack on them to add a feature
I want or fix a bug; usually upstream the results as PRs. Thanks to this, I know
my way around codebases written on different languages. I have previously
contributed to
[LLVM](https://github.com/llvm/llvm-project/commits?author=mairacanal),
[Mesa](https://gitlab.freedesktop.org/mesa/mesa/-/commits/main?search=Ma%C3%ADra+Canal),
[VK-GL-CTS](https://github.com/KhronosGroup/VK-GL-CTS/commits?author=mairacanal), and
[meta-openembedded](https://lists.openembedded.org/g/openembedded-devel/message/93534)
