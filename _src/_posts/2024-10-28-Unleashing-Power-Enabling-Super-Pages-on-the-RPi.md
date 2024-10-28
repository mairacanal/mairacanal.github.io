---
title: "Unleashing Power: Enabling Super Pages on the RPi"
date: 2024-10-28T09:00:00-03:00
author: Maíra Canal
permalink: /unleashing-power-enabling-super-pages-on-RPi/
categories: [Tech]
tags: [igalia, kernel, graphics, embedded]
---

Unleashing the power of 3D graphics in the Raspberry Pi is a key commitment for
[Igalia](https://www.igalia.com) through its collaboration with [Raspberry
Pi](https://www.raspberrypi.com). The introduction of Super Pages for the
Raspberry Pi 4 and 5 marks another step in this journey, offering some
performance enhancements and more efficient memory usage. In this post, we'll
dive deep into the technical details of Super Pages, discuss the challenges we
faced during implementation, and illustrate the benefits this feature brings to
the Raspberry Pi ecosystem.

## What are Super Pages?

A Memory Management Unit (MMU) is a hardware component responsible for handling
memory access at the system level. It translates virtual addresses used by
programs into physical addresses in main memory, enabling efficient memory
management and protection. The MMU allows the operating system to allocate
memory dynamically, isolating processes from one another to prevent them from
interfering with each other’s memory.

> **Recommendation:** 📚 _Structured computer organization_ by Andrew Tanenbaum

The V3D MMU, which is part of the Broadcom GPU found in the Raspberry Pi 4 and
5, is responsible for translating 32-bit virtual addresses (VA) used by V3D into
40-bit physical addresses used externally to V3D. The MMU relies on a page
table, stored in physical memory, which maps virtual addresses to their
corresponding physical addresses. The operating system manages this page table,
and the MMU uses it to perform address translation during memory access.

A fundamental principle of modern operating systems is that memory is not stored
contiguously. Instead, a contiguous block of memory is divided into smaller
blocks, called "pages", which are scattered across the entire address space.
These pages are typically 4KB in size. This approach enables more efficient
memory management and allows for features like virtual memory and memory
protection.

Over the years, the amount of available memory in computers has increased
dramatically. An early IBM PC had up to 640 KiB of RAM, whereas the ThinkPad I’m
typing on right now has 32 GB of RAM. Naturally, memory demands have grown
alongside this increase. Today, it's common for web browsers to consume several
gigabytes of RAM, and a single shader can take up multiple megabytes.

As memory usage grows, a 4KB page size may become inefficient for managing large
memory blocks. Handling a large number of small pages for a single block means
the MMU must perform multiple address translations, which increases overhead.
This can reduce the effectiveness of the Translation Lookaside Buffer (TLB), as
it must store and handle more entries, potentially leading to more cache misses
and reduced overall performance.

This is why many CPU manufacturers have introduced support for larger page
sizes. For instance, x86 CPUs typically support 4KB and 2MB pages, with 1GB
pages available if supported by the hardware. Similarly, ARM64 CPUs can support
4KB, 16KB, and 64KB page sizes. These larger page sizes help reduce the number
of pages the MMU needs to manage, improving performance by reducing the overhead
of address translation and making more efficient use of the TLB.

**So, if CPUs are using bigger sizes, why shouldn't GPUs do the same?**

By default, V3D supports 4KB pages. However, by setting specific bits in the
page table entry, it is possible to create 64KB "Big Pages" and 1MB "Super
Pages." The issue is that the current V3D driver available in Linux does not
enable the use of Big or Super Pages, meaning this hardware feature is currently
unused.

The advantage of enabling Big and Super Pages is that once an entry for any page
within a Big or Super Page is cached in the MMU, it can be used to translate all
virtual addresses within that page’s range without needing to fetch additional
entries. In theory, this should result in improved performance, especially for
applications with high memory demands, such as those using multiple large buffer
objects (BOs).

As Igalia continually strives to enhance the experience for Raspberry Pi users,
we decided to implement this feature in the upstream kernel. But before diving
into the implementation details, let’s take a look at the real-world results and
see if the theoretical benefits of Super Pages have translated into measurable
improvements for Raspberry Pi users.

## What Does This Feature Mean for RPi Users?

With Super Pages implemented, let's now explore the actual performance
improvements observed on the Raspberry Pi and see how impactful this feature is
for users.

### Benchmarking Super Pages: Traces and FPS Improvements

To measure the impact of Super Pages, we tested a variety of games and demos
traces on the Raspberry Pi 4 and 5, covering genres from action to racing. On
average, we observed a +1.40% FPS improvement on the Raspberry Pi 4 and a +1.30%
improvement on the Raspberry Pi 5.

For instance, on the Raspberry Pi 4, _Warzone 2100_ saw an 8.36% FPS increase,
and on the Raspberry Pi 5, _Quake II_ enjoyed a 3.62% boost. These examples
demonstrate the benefits of Super Pages in resource-demanding applications,
where optimized memory handling becomes critical.

#### Raspberry Pi 4 FPS Improvements

| Trace    | Before Super Pages | After Super Pages | Improvement |
| -------- | :----------------: | :---------------: | :---------: |
| warzone2100.30secs.1024x768.trace                       | 56.39 |61.10 |+8.36%|
| ue4_shooter_game_shooting_low_quality_640x480.gfxr      | 20.71 |21.47 |+3.65%|
| quake3e_capture_frames_1800_through_2400_1920x1080.gfxr | 60.88 |62.50 |+2.67%|
| supertuxkart-menus_1024x768.trace                       | 112.62|115.61|+2.65%|
| ue4_shooter_game_shooting_high_quality_640x480.gfxr     | 20.45 |20.88 |+2.10%|
| quake2-gles3-1280x720.trace                             | 59.76 |60.84 |+1.82%|
| ue4_sun_temple_640x480.gfxr                             | 27.60 |28.03 |+1.54%|
| vkQuake_capture_frames_1_through_1200_1280x720.gfxr     | 54.59 |55.30 |+1.29%|
| ue4_shooter_game_low_quality_640x480.gfxr               | 32.75 |33.08 |+1.00%|
| sponza_demo02_800x600.gfxr                              | 20.90 |21.03 |+0.61%|
| supertuxkart-racing_1024x768.trace                      | 8.58  |8.63  |+0.60%|
| ue4_shooter_game_high_quality_640x480.gfxr              | 19.62 |19.74 |+0.59%|
| serious_sam_trace02_1280x720.gfxr                       | 44.00 |44.21 |+0.50%|
| ue4_vehicle_game-2_640x480.gfxr                         | 12.59 |12.65 |+0.49%|
| sponza_demo01_800x600.gfxr                              | 21.42 |21.46 |+0.19%|
| quake3e-1280x720.trace                                  | 84.45 |84.52 |+0.09%|

#### Raspberry Pi 5 FPS Improvements

| Trace    | Before Super Pages | After Super Pages | Improvement |
| -------- | :----------------: | :---------------: | :---------: |
| quake2-gles3-1280x720.trace                             | 151.77|157.26|+3.62%|
| supertuxkart-menus_1024x768.trace                       | 306.79|313.88|+2.31%|
| warzone2100.30secs.1024x768.trace                       | 140.92|144.03|+2.21%|
| vkQuake_capture_frames_1_through_1200_1280x720.gfxr     | 131.45|134.20|+2.10%|
| ue4_vehicle_game-2_640x480.gfxr                         | 24.42 |24.88 |+1.89%|
| ue4_shooter_game_high_quality_640x480.gfxr              | 32.12 |32.53 |+1.29%|
| ue4_sun_temple_640x480.gfxr                             | 42.05 |42.55 |+1.20%|
| ue4_shooter_game_shooting_high_quality_640x480.gfxr     | 52.77 |53.31 |+1.04%|
| quake3e-1280x720.trace                                  | 238.31|240.53|+0.93%|
| warzone2100.70secs.1024x768.trace                       | 151.09|151.81|+0.48%| 
| sponza_demo02_800x600.gfxr                              | 50.81 |51.05 |+0.46%|
| supertuxkart-racing_1024x768.trace                      | 20.91 |20.98 |+0.33%|
| ue4_shooter_game_low_quality_640x480.gfxr               | 59.68 |59.86 |+0.29%|
| quake3e_capture_frames_1_through_1800_1920x1080.gfxr    | 167.70|168.17|+0.29%|
| ue4_shooter_game_shooting_low_quality_640x480.gfxr      | 53.40 |53.51 |+0.22%|
| quake3e_capture_frames_1800_through_2400_1920x1080.gfxr | 163.37|163.64|+0.17%|
| serious_sam_trace02_1280x720.gfxr                       | 60.00 |60.03 |+0.06%|
| sponza_demo01_800x600.gfxr                              | 45.04 |45.04 |<.01% |

While an average +1% FPS improvement might seem modest, Super Pages can deliver
more noticeable gains in memory-intensive 3D applications and when the GPU is
under heavy usage. Let's see how the Super Pages perform on Mesa CI.

### Benchmarking Super Pages: Mesa CI Job Duration

To avoid introducing regressions in user-space, I usually test my custom kernels
with Mesa CI, focusing on the “broadcom-postmerge” stage to verify that all
Piglit and CTS tests ran smoothly. For Super Pages, I was pleasantly surprised
by the job duration results, as some job durations were reduced by several
minutes.

#### Mesa CI Jobs Duration Improvements

| Job    | Before Super Pages | After Super Pages | 
| -------- | :----------------: | :---------------: | 
| v3d-rpi4-traces:arm64 | ~4m30s | ~3m40s |
| v3d-rpi5-traces:arm64 | ~3m30s | ~2m45s |
| v3d-rpi4-gl-full:arm64 \*/6 | ~24-25 minutes | ~22-23 minutes |
| v3d-rpi5-gl-full:arm64 | ~48 minutes | ~48 minutes |
| v3dv-rpi4-vk-full:arm64 \*/6 | ~44 minutes | ~41 minutes |
| v3dv-rpi5-vk-full:arm64 | ~102 minutes | ~92 minutes |

Seeing these reductions is especially rewarding. For example, the
“v3dv-rpi5-vk-full:arm64” job duration decreased by 10 minutes, meaning more FPS
for users and shorter wait times for Mesa developers.

### Benchmarking Super Pages: PS2 Emulation

After sharing a couple of tables, I’ll admit that showcasing performance
improvements solely through numbers doesn’t always convey the real impact.
Personally, I find it more satisfying to see performance gains in action with
real-world applications.

This led me to explore PlayStation 2 (PS2) emulation on the RPi 5. From watching
YouTube videos, I noticed that PS2 is a popular console for the RPi 5. While the
PlayStation (PS1) emulates well even on the RPi 4, and Nintendo 64 and Sega
Saturn struggle across most hardware, PS2 hits a sweet spot for testing the RPi
5's limits.

Fortunately, I still have my childhood PS2 — my second console after the
Nintendo GameCube, and one of the most successful consoles worldwide, including
in Brazil. With a library packed with titles like _Metal Gear Solid_, _Resident
Evil_, _Tomb Raider_, and _Shadow of the Colossus_, the PS2 remains a great
system for collectors and retro gamers alike.

I selected a few games from my collection to benchmark on the RPi 5 using a PS2
emulator. My emulator of choice was [Aether
SX2](https://github.com/AetherSX2-backup/AetherSX2-builds) with Vulkan support.
Although AetherSX2 is no longer in development, it still performs well on the
RPi.

Initially, many games were barely playable, especially those with large buffer
objects, like Shadow of the Colossus and Gran Turismo 4. However, after enabling
Super Pages support, I noticed immediate improvements. For example, Shadow of
the Colossus wouldn’t even open before Super Pages, and while it’s not fully
playable yet, it does load now. This isn’t a silver bullet, but it’s a step
forward in improving the driver one piece at a time.

I ended up selecting four games for a video comparison: _Burnout 3: Takedown_,
_Metal Gear Solid 3: Snake Eater_, _Resident Evil 4_, and _Tekken 4_.

<video width="100%" controls>
  <source src="/assets/videos/super-pages-rpi5-2024.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

> **Disclaimer:** The BIOS used in the emulator was extracted from my own PS2,
> and I played only games I own, with ROMs I personally extracted. Neither I nor
> Igalia encourage using downloaded BIOS or ROM files from the internet.

From the video, we can see noticeable improvements in all four games. Although
they aren’t perfectly playable yet, the performance gains are evident,
particularly in _Resident Evil 4_, where the gameplay saw a solid 5 FPS boost. I
realize 18 FPS might not satisfy most players, but I still had a lot of fun
playing _Resident Evil 4_ on the RPi 5.

When tracking the FPS for these games, it’s clear that the performance gains go
well beyond the average 1% seen in other benchmarks. Super Pages show their true
potential in high-memory applications like PS2 emulation.

Having seen the performance gains Super Pages can bring to the Raspberry Pi,
let's now dive into the technical aspects of the feature.

## Implementing Super Pages

The first challenge was figuring out how to allocate a contiguous block of
memory using _shmem_. The Shared Memory Virtual Filesystem (_shmem_) is used as
a flexible memory mechanism that allows the GPU and CPU to share access to BOs
through the system's temporary filesystem, _tmpfs_. _tmpfs_ is a volatile
filesystem that stores files in RAM, making it ideal for temporary or high-speed
data that doesn't need to persist on RAM. 

For example, to allocate a 256KB BO across four 64KB pages, we need four
contiguous 64KB memory blocks. However, by default, _tmpfs_ only allocates
memory in `PAGE_SIZE` chunks (as seen in `shmem_file_setup()`), whereas
`PAGE_SIZE` is 4KB on the Raspberry Pi 4 and 16KB on the Raspberry Pi 5. Since
the function `drm_gem_object_init()` — which initializes an allocated
shmem-backed GEM object — relies on `shmem_file_setup()` to back these objects
in memory, we had to consider alternatives, as the default `PAGE_SIZE` would
divide memory into increments that are too small to ensure the large, contiguous
blocks needed by the GPU.

The solution we proposed was to create `drm_gem_object_init_with_mnt()`, which
allows us to specify the _tmpfs_ mountpoint where the GEM object will be
created. This enables us to allocate our BOs in a mountpoint that supports
larger page sizes. Additionally, to ensure that our BOs are allocated in the
correct mountpoint, we introduced `drm_gem_shmem_create_with_mnt()`, which
allows the mountpoint to be specified when creating a new DRM GEM shmem object.

[\[PATCH v6 04/11\] drm/gem: Create a drm_gem_object_init_with_mnt() function](https://lore.kernel.org/dri-devel/20240923141348.2422499-5-mcanal@igalia.com/)

[\[PATCH v6 06/11\] drm/gem: Create shmem GEM object in a given mountpoint](https://lore.kernel.org/dri-devel/20240923141348.2422499-7-mcanal@igalia.com/)

The next challenge was figuring out how to create a new mountpoint that would
allow for different page sizes based on the allocation. Simply creating a new
_tmpfs_ mountpoint with a fixed bigger page size wouldn’t suffice, as we needed
flexibility for various allocations. Inspired by the i915 driver, we decided to
use a _tmpfs_ mountpoint with the "huge=within_size" flag. This flag, which
requires the kernel to be configured with `CONFIG_TRANSPARENT_HUGEPAGE`, enables
the allocation of huge pages.

[Transparent Huge Pages
(THP)](https://docs.kernel.org/admin-guide/mm/transhuge.html) is a kernel
feature that automatically manages large memory pages to improve performance
without needing changes from applications. THP dynamically combines smaller
pages into larger ones, typically 2MB, reducing memory management overhead and
improving cache efficiency.

To support our new allocation strategy, we created a dedicated _tmpfs_
mountpoint for V3D, called gemfs, which provides us an ideal space for managing
these larger allocations.

[\[PATCH v6 05/11\] drm/v3d: Introduce gemfs](https://lore.kernel.org/dri-devel/20240923141348.2422499-6-mcanal@igalia.com/)

With everything in place for contiguous allocations, the next step was configuring V3D to enable Big/Super Page support.

We began by addressing a major source of memory pressure on the Raspberry Pi:
the current 128KB alignment for allocations in the virtual memory space. This
alignment wastes space when handling small BO allocations, especially since the
userspace driver performs a large number of these small allocations.

As a result, we can't fully utilize the 4GB address space available for the GPU
on the Raspberry Pi 4 or 5. For example, we can currently allocate up to 32,000
BOs of 4KB (~140MB) and 3,000 BOs of 400KB (~1.3GB). This becomes a limitation
for memory-intensive applications. By reducing the page alignment to 4KB, we can
significantly increase the number of BOs, allowing up to 1,000,000 BOs of 4KB
(~4GB) and 10,000 BOs of 400KB (~4GB).

Therefore, the first change I made was reducing the VA alignment of all
allocations to 4KB.

[\[PATCH v6 07/11\] drm/v3d: Reduce the alignment of the node allocation](https://lore.kernel.org/dri-devel/20240923141348.2422499-8-mcanal@igalia.com/)

With the alignment issue resolved, we can now implement the code to properly set
the flags on the Page Table Entries (PTE) for Big/Super Pages. Setting these
flags is straightforward — a simple bitwise operation. The challenge lies in
determining which BOs can be allocated in Super Pages. For a BO to be eligible
for a Big Page, its virtual address must be aligned to 64KB, and the same
applies to its physical address. Same thing for Super Pages, but now the
addresses must be aligned to 1MB.

If the BO qualifies for a Big/Super Page, we need to iterate over 16 4KB pages
(for Big Pages) or 256 4KB pages (for Super Pages) and insert the appropriate
PTE.

Additionally, we modified the way we iterate through the BO's memory. This was
necessary because the THP may not always allocate the entire BO contiguously.
For example, it might only allocate contiguously 1MB of a 2MB block. To handle
this, we now iterate over the blocks of contiguous memory scattered across the
scatterlist, ensuring that each segment is properly handled during the
allocation process.

> **What is a scatterlist?** It is a Linux Kernel data structure that manages
> non-contiguous memory as if it were contiguous. It organizes separate memory
> blocks into a single logical buffer, allowing efficient data handling,
> especially in Direct Memory Access (DMA) operations, without needing a
> physically contiguous memory allocation.

[\[PATCH v6 08/11\] drm/v3d: Support Big/Super Pages when writing out PTEs](https://lore.kernel.org/dri-devel/20240923141348.2422499-9-mcanal@igalia.com/)

However, the last few patches alone don’t fully enable the use of Super Pages.
While PATCH 08/11 technically allows for Super Pages, we’re still relying on DRM
GEM shmem objects, meaning allocations are still happening in `PAGE_SIZE`
chunks. Although Big/Super Pages could potentially be used if the system
naturally allocated 1MB or 64KB contiguously, this is quite rare and not our
intended outcome. Our goal is to actively use Big/Super Pages as much as
possible.

To achieve this, we’ll utilize the V3D-specific mountpoint we created earlier
for BO allocation whenever possible. By creating BOs through
`drm_gem_shmem_create_with_mnt()`, we can ensure that large pages are allocated
contiguously when possible, enabling the consistent use of Big/Super Pages.

[\[PATCH v6 09/11\] drm/v3d: Use gemfs/THP in BO creation if available](https://lore.kernel.org/dri-devel/20240923141348.2422499-10-mcanal@igalia.com/)

And there you have it — Big/Super Pages are now fully enabled in V3D. The only
requirement to activate this feature in any given kernel is ensuring that
`CONFIG_TRANSPARENT_HUGEPAGE` is enabled.

## Final Words

You can learn more about ongoing enhancements to the Raspberry Pi driver stack
in this [XDC 2024
talk](https://www.youtube.com/live/d0MP9-hFUZE?si=k6SL8taOo3oBgG-t&t=21888) by
José María "Chema" Casanova Crespo. In the talk, Chema discusses the Super
Pages work I developed, along with other advancements in the driver stack.

Of course, there are still plenty of improvements on the horizon at Igalia. I’m
currently experimenting with 64KB CLE allocations in user-space, and I hope to
share more good news soon.

Finally, I’d like to express my gratitude to [Iago
Toral](https://blogs.igalia.com/itoral/) and [Tvrtko
Ursulin](https://blogs.igalia.com/tursulin/) for their invaluable support in
developing Super Pages for the V3D kernel driver. Thank you both for sharing
your experience with me!

