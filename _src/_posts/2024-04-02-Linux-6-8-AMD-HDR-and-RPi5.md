---
title: "Linux 6.8: AMD HDR and Raspberry Pi 5"
date: 2024-04-02T08:00:00-03:00
author: Maíra Canal
permalink: /linux-6-8-AMD-HDR-and-raspberry-pi-5/
categories: [Tech]
tags: [igalia, kernel]
---

The Linux kernel 6.8 came out on March 10th, 2024, bringing brand-new features
and plenty of performance improvements on different subsystems. As part of
[Igalia](https://www.igalia.com/), I'm happy to be an active part of many
features that are released in this version, and today I'm going to review some
of them.

Linux 6.8 is packed with a lot of great features, performance optimizations, and
new hardware support. In this release, we can check the Intel Xe DRM driver
experimentally, further support for AMD Zen 5 and other upcoming AMD hardware,
initial support for the Qualcomm Snapdragon 8 Gen 3 SoC, the Imagination PowerVR
DRM kernel driver, support for the Nintendo NSO controllers, and much more.

Igalia is widely known for its contributions to Web Platforms, Chromium, and
Mesa. But, we also make significant contributions to the Linux kernel. This
release shows some of the great work that Igalia is putting into the kernel and
strengthens our desire to keep working with this great community.

Let's take a deep dive into Igalia's major contributions to the 6.8 release:

## AMD HDR & Color Management

You may have seen the release of a new Steam Deck last year, the Steam Deck
OLED. What you may not know is that Igalia helped bring this product to life by
putting some effort into the AMD driver-specific color management properties
implementation. [Melissa Wen](https://www.igalia.com/team/mwen), together with
Joshua Ashton (Valve), and Harry Wentland (AMD), implemented several
driver-specific properties to allow Gamescope to manage color features provided
by the AMD hardware to fit HDR content and improve gamers' experience.

She has explained all features implemented in the AMD display kernel driver in
two blog posts and a 2023 XDC talk:

- [AMD Driver-specific Properties for Color Management on Linux (Part 1)](https://melissawen.github.io/blog/2023/08/21/amd-steamdeck-colors)
- [AMD Driver-specific Properties for Color Management on Linux (Part 2)](https://melissawen.github.io/blog/2023/11/07/amd-steamdeck-colors-p2)
- [The Rainbow Treasure Map Talk: Advanced color management on Linux with AMD/Steam Deck](https://melissawen.github.io/blog/2023/12/20/xdc2023-colors-talk)

## Async Flip

[André Almeida](https://www.igalia.com/team/tonyk) worked together with Simon
Ser (SourceHut) to provide support for asynchronous page-flips in the atomic
API. This feature targets users who want to present a new frame immediately,
even if after missing a V-blank. This feature is particularly useful for
applications with high frame rates, such as gaming.

## Raspberry Pi 5

Raspberry Pi 5 was officially released on October 2023 and Igalia was ready to
bring top-notch graphics support for it. Although we still can't use the RPi 5
with the mainline kernel, it is superb to see some pieces coming upstream. [Iago
Toral](https://www.igalia.com/team/itoral) worked on implementing all the kernel
support needed for the V3D 7.1.x driver.

With the kernel patches, by the time the RPi 5 was released, it already included
a fully 3.1 OpenGL ES and Vulkan 1.2 compliant driver implemented by Igalia.

## GPU stats and CPU jobs for the Raspberry Pi 4/5

Apart from the release of the Raspberry Pi 5, Igalia is still working on
improving the whole Raspberry Pi environment. I worked, together with [José
Maria "Chema" Casanova](https://www.igalia.com/team/chema), implementing the
support for GPU stats on the V3D driver. This means that RPi 4/5 users now can
access the usage percentage of the GPU and they can access the statistics by
process or globally.

I also worked, together with [Melissa](https://www.igalia.com/team/mwen),
implementing CPU jobs for the V3D driver. As the Broadcom GPU isn't capable of
performing some operations, the Vulkan driver uses the CPU to compensate for it.
In order to avoid stalls in the job submission, now CPU jobs are part of the
kernel and can be easily synchronized though with synchronization objects.

If you are curious about the CPU job implementation, you can check this [blog
post](https://mairacanal.github.io/introducing-cpu-jobs-to-the-rpi/).

## Other Contributions & Fixes

Sometimes we don't contribute to a major feature in the release, however we can
help improving documentation and sending fixes.
[André](https://www.igalia.com/team/tonyk) also contributed to this release by
documenting the different AMD GPU reset methods, making it easier to understand
by future users.

During Igalia's efforts to improve the general users' experience on the Steam
Deck, [Guilherme G. Piccoli](https://www.igalia.com/team/gpiccoli) noticed a
message in the kernel log and readily provided a fix for this PCI issue.

Outside of the Steam Deck world, we can check some of Igalia's work on the
Qualcomm Adreno GPUs. Although most of our Adreno-related work is located at the
user-space, [Danylo Piliaiev](https://www.igalia.com/team/dpiliaiev) sent a
couple of kernel fixes to the msm driver, fixing some hangs and some CTS tests.

We also had contributions from our 2023 Igalia CE student, Nia Espera. Nia's
project was related to mobile Linux and she managed to write a couple of patches
to the kernel in order to add support for the OnePlus 9 and OnePlus 9 Pro
devices.

> If you are a student interested in open-source and would like to have a first
> exposure to the professional world, check if we have openings for the [Igalia
> Coding Experience](https://www.igalia.com/coding-experience/). I was a CE
> student myself and being mentored by a Igalian was a incredible experience.

## Check the complete list of Igalia's contributions for the 6.8 release

### Authored (57):

#### André Almeida (2)

* [drm: Refuse to async flip with atomic prop changes](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=0e26cc72c71cb98e951716a6596060cd04b0ba6b)
* [drm/amd: Document device reset methods](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=613ecd6563d2716192e69624105fe1939d104663)

#### Danylo Piliaiev (2)

* [drm/msm/a6xx: Add missing BIT(7) to REG_A6XX_UCHE_CLIENT_PF](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=cf1aaa7d4a719f0bdd9c246c0fac8247cb54ddd7)
* [drm/msm/a690: Fix reg values for a690](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=07e6de738aa6f0e873463e9ca88bdb7081c4bfd4)

#### Guilherme G. Piccoli (1)

* [PCI: Only override AMD USB controller if required](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e585a37e5061f6d5060517aed1ca4ccb2e56a34c)

#### Iago Toral Quiroga (4)

* [drm/v3d: update UAPI to match user-space for V3D 7.x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=1118d10f5e5ab544c489fad4da373f9988416ece)
* [drm/v3d: fix up register addresses for V3D 7.x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=0ad5bc1ce4634ce9b5eaf017b01399ec5e49a03d)
* [dt-bindings: gpu: v3d: Add BCM2712's compatible](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=ebb2f6eea688b9ffa46527c3e7570b2c347497b8)
* [drm/v3d: add brcm,2712-v3d as a compatible V3D device](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6fd9487147c4f18ad77eea00bd8c9189eec74a3e)

#### Maíra Canal (17)

* [drm/v3d: wait for all jobs to finish before unregistering](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=79d94360d50fcd487edcfe118a47a2881534923f)
* [drm/v3d: Implement show_fdinfo() callback for GPU usage stats](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=09a93cc4f7d1893777f6b788bffe60d64e4d5df7)
* [drm/v3d: Expose the total GPU usage stats on sysfs](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=509433d8146c64ca9e0bcc370ec910821fffe80c)
* [MAINTAINERS: Add Maira to V3D maintainers](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=c400eb4d6f5f603f4f3f6cc4b6fdacd416ff142e)
* [drm/v3d: Don't allow two multisync extensions in the same job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6893deb881ab7da1691bd05045ffcc0c806319b9)
* [drm/v3d: Decouple job allocation from job initiation](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=464c61e76de851a216e667c91332172c68ffed54)
* [drm/v3d: Use v3d_get_extensions() to parse CPU job data](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=c5195d001f4c122032a9ce90c6b88d772673fa35)
* [drm/v3d: Create tracepoints to track the CPU job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=1fe0879efc8f623816c7a825d853d2140c88cb2d)
* [drm/v3d: Enable BO mapping](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=7c13132c4073628b5fe23b5188ac583a2882a6b0)
* [drm/v3d: Create a CPU job extension for a indirect CSD job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=18b8413b25b7070fa2e55858a2c808e6909581d0)
* [drm/v3d: Create a CPU job extension for the timestamp query job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9ba0ff3e083f6a4a0b6698f06bfff74805fefa5f)
* [drm/v3d: Create a CPU job extension for the reset timestamp job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=34a101e64296c736b14ce27e647fcebd70cb7bf8)
* [drm/v3d: Create a CPU job extension to copy timestamp query to a buffer](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6745f3e44a20ac18e7e5a40a3c7f62225983d544)
* [drm/v3d: Create a CPU job extension for the reset performance query job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=bae7cb5d68001a8d4ceec5964dda74bb9aab7220)
* [drm/v3d: Create a CPU job extension for the copy performance query job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=209e8d2695ee7a67a5b0487bbd1aa75e290d0f41)
* [drm/v3d: Fix support for register debugging on the RPi 4](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=89fe46019a62bc1d0cb49c9615cb3520096c4bc1)
* [drm/v3d: Free the job and assign it to NULL if initialization fails](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=2ad62d16cd24b5e2f18318e97e1f06bef9f1ce7d)

#### Melissa Wen (27)

* [drm/v3d: Remove unused function header](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=780b9463ce66a9efb18e3b5d35cd011fb918d741)
* [drm/v3d: Move wait BO ioctl to the v3d_bo file](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=a8ad9d63a160f6b93f6958a5a0ded1a6abb15815)
* [drm/v3d: Detach job submissions IOCTLs to a new specific file](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9032d5f633ed7b5c726971dc7e2372045bf27f40)
* [drm/v3d: Simplify job refcount handling](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=8288faaa8b3817c2fcdbacc720527bb8df2b57b1)
* [drm/v3d: Add a CPU job submission](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=aafc1a2bea67460c41a289e8bb1e4dc6d016fe11)
* [drm/v3d: Detach the CSD job BO setup](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=369b05961731925e4a43608ea1e7884df200f0bd)
* [drm/drm_mode_object: increase max objects to accommodate new color props](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=1e13c5644c443dee727ac1330bc118c909a1cf07)
* [drm/drm_property: make replace_property_blob_from_id a DRM helper](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=601603105325ad4ec62db95c9bc428202ece2c8f)
* [drm/drm_plane: track color mgmt changes per plane](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=24013b9301349881c9fcd27e7edacc672e0bf6d3)
* [drm/amd/display: add driver-specific property for plane degamma LUT](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9342a9ae54ef299ffe5e4ce3d0be6a4da5edba0e)
* [drm/amd/display: explicitly define EOTF and inverse EOTF](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=5a3b965b5810bd602d2c7d8ea79ffe8c6e81268d)
* [drm/amd/display: document AMDGPU pre-defined transfer functions](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e4cddd51bfab2a40529a4af35bd2c912b5a0c239)
* [drm/amd/display: add plane 3D LUT driver-specific properties](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=671994e3bf33a414dc6a8c147969dae3a15ba9de)
* [drm/amd/display: add plane shaper LUT and TF driver-specific properties](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=f545d82479b46368bf00d0bfecf33fa914bd5f8f)
* [drm/amd/display: add CRTC gamma TF driver-specific property](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=0f5afa190b890052cae187496f660699f00067ef)
* [drm/amd/display: add comments to describe DM crtc color mgmt behavior](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=98fbb52772063ad2547d6d1b80ff99bc26761e79)
* [drm/amd/display: encapsulate atomic regamma operation](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=8b6b3f668f31a24b5406661388b9a69202e83e9d)
* [drm/amd/display: decouple steps for mapping CRTC degamma to DC plane](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=73e5ea616a9f8c261d07e63b421947949ad6cbce)
* [drm/amd/display: reject atomic commit if setting both plane and CRTC degamma](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=ef113a3b1964b40dd87287806865b947d70f7df5)
* [drm/amd/display: add plane shaper LUT support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=aba8b76baabde681ab4ff686452005d80d949345)
* [drm/amd/display: add plane shaper TF support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=99de686115b00e765a5e9345e10c9d7312e4c7ea)
* [drm/amd/display: add plane 3D LUT support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=486c95af5d76047d5cb50727270b1961dacb9380)
* [drm/amd/display: fix documentation for dm_crtc_additional_color_mgmt()](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=c6ef0a2265c518aa6699b64d10a7e5a9049ac96a)
* [drm/amd/display: fix bandwidth validation failure on DCN 2.1](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=3a0fa3bc245ef92838a8296e0055569b8dff94c4)
* [drm/amd/display: cleanup inconsistent indenting in amdgpu_dm_color](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=7075893d1d68b2b3517be250a02d86e76554ed22)
* [drm/amd/display: fix null-pointer dereference on edid reading](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9671761792156f2339627918bafcd713a8a6f777)
* [drm/amd/display: check dc_link before dereferencing](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e9098cc9aef13bd56e821f628c83f709d3347af1)

#### Nia Espera (4)

* [dt-bindings: iio: adc: qcom: Add Qualcomm smb139x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=7bf421f44549cd0bca32bd0b4cf6e4cfe5b4f865)
* [arm64: dts: qcom: sm8350: Fix DMA0 address](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=01a9e9eb6cdbce175ddea3cbe1163daed6d54344)
* [arm64: dts: qcom: pm8350k: Remove hanging whitespace](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e70537717146b380e18f0c92669d968af4acb8a7)
* [arm64: dts: qcom: sm8350: Fix remoteproc interrupt type](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=54ee322f845c7f25fbf6e43e11147b6cae8eff56)

### Signed-off-by (88):

#### André Almeida (4)

* [drm: Refuse to async flip with atomic prop changes](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=0e26cc72c71cb98e951716a6596060cd04b0ba6b)
* [drm: allow DRM_MODE_PAGE_FLIP_ASYNC for atomic commits](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=4b4af74ab9719d17538a97f43137e93296ec7437)
* [drm: introduce DRM_CAP_ATOMIC_ASYNC_PAGE_FLIP](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e4d983acffff270ccee417445a69b9ed198658b1)
* [drm/amd: Document device reset methods](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=613ecd6563d2716192e69624105fe1939d104663)

#### Danylo Piliaiev (2)

* [drm/msm/a6xx: Add missing BIT(7) to REG_A6XX_UCHE_CLIENT_PF](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=cf1aaa7d4a719f0bdd9c246c0fac8247cb54ddd7)
* [drm/msm/a690: Fix reg values for a690](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=07e6de738aa6f0e873463e9ca88bdb7081c4bfd4)

#### Guilherme G. Piccoli (1)

* [PCI: Only override AMD USB controller if required](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e585a37e5061f6d5060517aed1ca4ccb2e56a34c)

#### Iago Toral Quiroga (4)

* [drm/v3d: update UAPI to match user-space for V3D 7.x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=1118d10f5e5ab544c489fad4da373f9988416ece)
* [drm/v3d: fix up register addresses for V3D 7.x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=0ad5bc1ce4634ce9b5eaf017b01399ec5e49a03d)
* [dt-bindings: gpu: v3d: Add BCM2712's compatible](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=ebb2f6eea688b9ffa46527c3e7570b2c347497b8)
* [drm/v3d: add brcm,2712-v3d as a compatible V3D device](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6fd9487147c4f18ad77eea00bd8c9189eec74a3e)

#### Jose Maria Casanova Crespo (2)

* [drm/v3d: Implement show_fdinfo() callback for GPU usage stats](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=09a93cc4f7d1893777f6b788bffe60d64e4d5df7)
* [drm/v3d: Expose the total GPU usage stats on sysfs](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=509433d8146c64ca9e0bcc370ec910821fffe80c)

#### Maíra Canal (28)

* [drm/v3d: wait for all jobs to finish before unregistering](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=79d94360d50fcd487edcfe118a47a2881534923f)
* [drm/v3d: update UAPI to match user-space for V3D 7.x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=1118d10f5e5ab544c489fad4da373f9988416ece)
* [drm/v3d: fix up register addresses for V3D 7.x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=0ad5bc1ce4634ce9b5eaf017b01399ec5e49a03d)
* [dt-bindings: gpu: v3d: Add BCM2712's compatible](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=ebb2f6eea688b9ffa46527c3e7570b2c347497b8)
* [drm/v3d: add brcm,2712-v3d as a compatible V3D device](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6fd9487147c4f18ad77eea00bd8c9189eec74a3e)
* [drm/v3d: Implement show_fdinfo() callback for GPU usage stats](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=09a93cc4f7d1893777f6b788bffe60d64e4d5df7)
* [drm/v3d: Expose the total GPU usage stats on sysfs](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=509433d8146c64ca9e0bcc370ec910821fffe80c)
* [MAINTAINERS: Drop Emma Anholt from all M lines.](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=89d04995f76ce8318fe752feb33b1a45893b1a38)
* [MAINTAINERS: Add Maira to V3D maintainers](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=c400eb4d6f5f603f4f3f6cc4b6fdacd416ff142e)
* [drm/v3d: Remove unused function header](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=780b9463ce66a9efb18e3b5d35cd011fb918d741)
* [drm/v3d: Move wait BO ioctl to the v3d_bo file](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=a8ad9d63a160f6b93f6958a5a0ded1a6abb15815)
* [drm/v3d: Detach job submissions IOCTLs to a new specific file](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9032d5f633ed7b5c726971dc7e2372045bf27f40)
* [drm/v3d: Simplify job refcount handling](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=8288faaa8b3817c2fcdbacc720527bb8df2b57b1)
* [drm/v3d: Don't allow two multisync extensions in the same job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6893deb881ab7da1691bd05045ffcc0c806319b9)
* [drm/v3d: Decouple job allocation from job initiation](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=464c61e76de851a216e667c91332172c68ffed54)
* [drm/v3d: Add a CPU job submission](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=aafc1a2bea67460c41a289e8bb1e4dc6d016fe11)
* [drm/v3d: Use v3d_get_extensions() to parse CPU job data](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=c5195d001f4c122032a9ce90c6b88d772673fa35)
* [drm/v3d: Create tracepoints to track the CPU job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=1fe0879efc8f623816c7a825d853d2140c88cb2d)
* [drm/v3d: Detach the CSD job BO setup](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=369b05961731925e4a43608ea1e7884df200f0bd)
* [drm/v3d: Enable BO mapping](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=7c13132c4073628b5fe23b5188ac583a2882a6b0)
* [drm/v3d: Create a CPU job extension for a indirect CSD job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=18b8413b25b7070fa2e55858a2c808e6909581d0)
* [drm/v3d: Create a CPU job extension for the timestamp query job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9ba0ff3e083f6a4a0b6698f06bfff74805fefa5f)
* [drm/v3d: Create a CPU job extension for the reset timestamp job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=34a101e64296c736b14ce27e647fcebd70cb7bf8)
* [drm/v3d: Create a CPU job extension to copy timestamp query to a buffer](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6745f3e44a20ac18e7e5a40a3c7f62225983d544)
* [drm/v3d: Create a CPU job extension for the reset performance query job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=bae7cb5d68001a8d4ceec5964dda74bb9aab7220)
* [drm/v3d: Create a CPU job extension for the copy performance query job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=209e8d2695ee7a67a5b0487bbd1aa75e290d0f41)
* [drm/v3d: Fix support for register debugging on the RPi 4](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=89fe46019a62bc1d0cb49c9615cb3520096c4bc1)
* [drm/v3d: Free the job and assign it to NULL if initialization fails](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=2ad62d16cd24b5e2f18318e97e1f06bef9f1ce7d)

#### Melissa Wen (43)

* [drm/v3d: Remove unused function header](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=780b9463ce66a9efb18e3b5d35cd011fb918d741)
* [drm/v3d: Move wait BO ioctl to the v3d_bo file](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=a8ad9d63a160f6b93f6958a5a0ded1a6abb15815)
* [drm/v3d: Detach job submissions IOCTLs to a new specific file](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9032d5f633ed7b5c726971dc7e2372045bf27f40)
* [drm/v3d: Simplify job refcount handling](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=8288faaa8b3817c2fcdbacc720527bb8df2b57b1)
* [drm/v3d: Add a CPU job submission](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=aafc1a2bea67460c41a289e8bb1e4dc6d016fe11)
* [drm/v3d: Detach the CSD job BO setup](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=369b05961731925e4a43608ea1e7884df200f0bd)
* [drm/v3d: Create a CPU job extension for a indirect CSD job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=18b8413b25b7070fa2e55858a2c808e6909581d0)
* [drm/drm_mode_object: increase max objects to accommodate new color props](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=1e13c5644c443dee727ac1330bc118c909a1cf07)
* [drm/drm_property: make replace_property_blob_from_id a DRM helper](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=601603105325ad4ec62db95c9bc428202ece2c8f)
* [drm/drm_plane: track color mgmt changes per plane](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=24013b9301349881c9fcd27e7edacc672e0bf6d3)
* [drm/amd/display: add driver-specific property for plane degamma LUT](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9342a9ae54ef299ffe5e4ce3d0be6a4da5edba0e)
* [drm/amd/display: add plane degamma TF driver-specific property](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=d5a348d96e4e2b924fa83e729f8791c03a4f8e24)
* [drm/amd/display: explicitly define EOTF and inverse EOTF](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=5a3b965b5810bd602d2c7d8ea79ffe8c6e81268d)
* [drm/amd/display: document AMDGPU pre-defined transfer functions](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e4cddd51bfab2a40529a4af35bd2c912b5a0c239)
* [drm/amd/display: add plane HDR multiplier driver-specific property](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=ec7b2a55463ea50401a8146793b61ee590255a45)
* [drm/amd/display: add plane 3D LUT driver-specific properties](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=671994e3bf33a414dc6a8c147969dae3a15ba9de)
* [drm/amd/display: add plane shaper LUT and TF driver-specific properties](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=f545d82479b46368bf00d0bfecf33fa914bd5f8f)
* [drm/amd/display: add plane blend LUT and TF driver-specific properties](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=0ef47454dc82358b62a424b37c7520a84f307edb)
* [drm/amd/display: add CRTC gamma TF driver-specific property](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=0f5afa190b890052cae187496f660699f00067ef)
* [drm/amd/display: add comments to describe DM crtc color mgmt behavior](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=98fbb52772063ad2547d6d1b80ff99bc26761e79)
* [drm/amd/display: encapsulate atomic regamma operation](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=8b6b3f668f31a24b5406661388b9a69202e83e9d)
* [drm/amd/display: add CRTC gamma TF support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6bd20f0f165f444c1d8184ebd238dd92966c9dca)
* [drm/amd/display: set sdr_ref_white_level to 80 for out_transfer_func](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=88d26ea639a8e9d314e6bffef5f382167e7203e2)
* [drm/amd/display: mark plane as needing reset if color props change](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6bed9d550e51534415a56f8de33f5b9d4e728e53)
* [drm/amd/display: decouple steps for mapping CRTC degamma to DC plane](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=73e5ea616a9f8c261d07e63b421947949ad6cbce)
* [drm/amd/display: add plane degamma TF and LUT support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=980f8710075acaeb226a94cde6dda8ffad30123c)
* [drm/amd/display: reject atomic commit if setting both plane and CRTC degamma](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=ef113a3b1964b40dd87287806865b947d70f7df5)
* [drm/amd/display: add dc_fixpt_from_s3132 helper](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=889044f9e04f0829dd92640c551941bbe77bc0ea)
* [drm/amd/display: add HDR multiplier support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=4bc59ddf57c1f68ea035c4f242108f29d91797fd)
* [drm/amd/display: add plane shaper LUT support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=aba8b76baabde681ab4ff686452005d80d949345)
* [drm/amd/display: add plane shaper TF support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=99de686115b00e765a5e9345e10c9d7312e4c7ea)
* [drm/amd/display: add plane 3D LUT support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=486c95af5d76047d5cb50727270b1961dacb9380)
* [drm/amd/display: handle empty LUTs in \_\_set_input\_tf](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=8d26795ae61a5f64ba7db4f3240dc9ab2138d361)
* [drm/amd/display: add plane blend LUT and TF support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=783ed4460fe55b01ff32a7c6ad8239974874a16a)
* [drm/amd/display: allow newer DC hardware to use degamma ROM for PQ/HLG](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=f81996637000a050477d597ef99e832079f99bd2)
* [drm/amd/display: copy 3D LUT settings from crtc state to stream_update](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=cb19dc4a64598ffbfd4354083f809fae082fa4c3)
* [drm/amd/display: add plane CTM driver-specific property](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=b8b92c1bd7788b1f13d547ee2ce8a93baf55b814)
* [drm/amd/display: add plane CTM support](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=3dad69090743c5f4642aeb628b8542a1e335dded)
* [drm/amd/display: fix documentation for dm_crtc_additional_color_mgmt()](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=c6ef0a2265c518aa6699b64d10a7e5a9049ac96a)
* [drm/amd/display: fix bandwidth validation failure on DCN 2.1](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=3a0fa3bc245ef92838a8296e0055569b8dff94c4)
* [drm/amd/display: cleanup inconsistent indenting in amdgpu_dm_color](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=7075893d1d68b2b3517be250a02d86e76554ed22)
* [drm/amd/display: fix null-pointer dereference on edid reading](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9671761792156f2339627918bafcd713a8a6f777)
* [drm/amd/display: check dc_link before dereferencing](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e9098cc9aef13bd56e821f628c83f709d3347af1)

#### Nia Espera (4)

* [dt-bindings: iio: adc: qcom: Add Qualcomm smb139x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=7bf421f44549cd0bca32bd0b4cf6e4cfe5b4f865)
* [arm64: dts: qcom: sm8350: Fix DMA0 address](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=01a9e9eb6cdbce175ddea3cbe1163daed6d54344)
* [arm64: dts: qcom: pm8350k: Remove hanging whitespace](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e70537717146b380e18f0c92669d968af4acb8a7)
* [arm64: dts: qcom: sm8350: Fix remoteproc interrupt type](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=54ee322f845c7f25fbf6e43e11147b6cae8eff56)

### Acked-by (4):

#### Jose Maria Casanova Crespo (2)

* [drm/v3d: Implement show_fdinfo() callback for GPU usage stats](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=09a93cc4f7d1893777f6b788bffe60d64e4d5df7)
* [drm/v3d: Expose the total GPU usage stats on sysfs](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=509433d8146c64ca9e0bcc370ec910821fffe80c)

#### Maíra Canal (1)

* [MAINTAINERS: Drop Emma Anholt from all M lines.](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=89d04995f76ce8318fe752feb33b1a45893b1a38)

#### Melissa Wen (1)

* [MAINTAINERS: Add Maira to V3D maintainers](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=c400eb4d6f5f603f4f3f6cc4b6fdacd416ff142e)

### Reviewed-by (30):

#### André Almeida (1)

* [drm: introduce DRM_CAP_ATOMIC_ASYNC_PAGE_FLIP](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=e4d983acffff270ccee417445a69b9ed198658b1)

#### Christian Gmeiner (1)

* [drm/etnaviv: Convert to platform remove callback returning void](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=d437dab5b06e3dc73f6a58a6c9fd0b13d1ed80e1)

#### Iago Toral Quiroga (20)

* [drm/v3d: wait for all jobs to finish before unregistering](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=79d94360d50fcd487edcfe118a47a2881534923f)
* [drm/v3d: Remove unused function header](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=780b9463ce66a9efb18e3b5d35cd011fb918d741)
* [drm/v3d: Move wait BO ioctl to the v3d_bo file](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=a8ad9d63a160f6b93f6958a5a0ded1a6abb15815)
* [drm/v3d: Detach job submissions IOCTLs to a new specific file](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9032d5f633ed7b5c726971dc7e2372045bf27f40)
* [drm/v3d: Simplify job refcount handling](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=8288faaa8b3817c2fcdbacc720527bb8df2b57b1)
* [drm/v3d: Don't allow two multisync extensions in the same job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6893deb881ab7da1691bd05045ffcc0c806319b9)
* [drm/v3d: Decouple job allocation from job initiation](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=464c61e76de851a216e667c91332172c68ffed54)
* [drm/v3d: Add a CPU job submission](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=aafc1a2bea67460c41a289e8bb1e4dc6d016fe11)
* [drm/v3d: Use v3d_get_extensions() to parse CPU job data](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=c5195d001f4c122032a9ce90c6b88d772673fa35)
* [drm/v3d: Create tracepoints to track the CPU job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=1fe0879efc8f623816c7a825d853d2140c88cb2d)
* [drm/v3d: Detach the CSD job BO setup](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=369b05961731925e4a43608ea1e7884df200f0bd)
* [drm/v3d: Enable BO mapping](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=7c13132c4073628b5fe23b5188ac583a2882a6b0)
* [drm/v3d: Create a CPU job extension for a indirect CSD job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=18b8413b25b7070fa2e55858a2c808e6909581d0)
* [drm/v3d: Create a CPU job extension for the timestamp query job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=9ba0ff3e083f6a4a0b6698f06bfff74805fefa5f)
* [drm/v3d: Create a CPU job extension for the reset timestamp job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=34a101e64296c736b14ce27e647fcebd70cb7bf8)
* [drm/v3d: Create a CPU job extension to copy timestamp query to a buffer](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6745f3e44a20ac18e7e5a40a3c7f62225983d544)
* [drm/v3d: Create a CPU job extension for the reset performance query job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=bae7cb5d68001a8d4ceec5964dda74bb9aab7220)
* [drm/v3d: Create a CPU job extension for the copy performance query job](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=209e8d2695ee7a67a5b0487bbd1aa75e290d0f41)
* [drm/v3d: Fix support for register debugging on the RPi 4](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=89fe46019a62bc1d0cb49c9615cb3520096c4bc1)
* [drm/v3d: Free the job and assign it to NULL if initialization fails](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=2ad62d16cd24b5e2f18318e97e1f06bef9f1ce7d)

#### Maíra Canal (4)

* [drm/v3d: update UAPI to match user-space for V3D 7.x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=1118d10f5e5ab544c489fad4da373f9988416ece)
* [drm/v3d: fix up register addresses for V3D 7.x](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=0ad5bc1ce4634ce9b5eaf017b01399ec5e49a03d)
* [dt-bindings: gpu: v3d: Add BCM2712's compatible](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=ebb2f6eea688b9ffa46527c3e7570b2c347497b8)
* [drm/v3d: add brcm,2712-v3d as a compatible V3D device](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=6fd9487147c4f18ad77eea00bd8c9189eec74a3e)

#### Melissa Wen (4)

* [drm/v3d: Implement show_fdinfo() callback for GPU usage stats](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=09a93cc4f7d1893777f6b788bffe60d64e4d5df7)
* [drm/v3d: Expose the total GPU usage stats on sysfs](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=509433d8146c64ca9e0bcc370ec910821fffe80c)
* [drm/v3d: Fix missing error code in v3d_submit_cpu_ioctl()](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=dce94061f0d02f5ab355390a6e63d3dbea938b72)
* [drm/amd/display: fix documentation for amdgpu_dm_verify_lut3d_size()](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=8b881b5d6fe9ebb7736097f37103c9b07ea45642)

### Tested-by (1):

#### Guilherme G. Piccoli (1)

* [pstore/ram: Fix crash when setting number of cpus to an odd number](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?h=v6.8&id=d49270a04623ce3c0afddbf3e984cb245aa48e9c)
