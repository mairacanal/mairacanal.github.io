---
title: "Rust for VGEM"
date: 2023-02-28
author: Maíra Canal
permalink: /rust-for-vgem/
categories: [Tech]
tags: [igalia, graphics]
---

In the last blog post, I pointed out that I didn't know exactly what it would be
my next steps for the near future. Gladly, I had the amazing opportunity to
start a new [Igalia Coding
Experience](https://www.igalia.com/coding-experience/) with a new project.

This time [Melissa Wen](https://melissawen.github.io/) pitched me with the idea
to play around with Rust for Linux in order to rewrite the VGEM driver in Rust.
The Rust for Linux project is growing fast with new bindings and abstractions
being introduced in the downstream RfL kernel. Also, some basic functionalities
were introduced in Linux 6.1. Therefore, it seems like a great timing to start
exploring Rust in the DRM subsystem!

# Why Rust?
---
As mentioned by the Rust website, using Rust means **Performance**,
**Reliability**, and **Productivity**. Rust is a blazingly fast and
memory-efficient language with its powerful **ownership model**. No more looking
for use-after-free and memory leaks, as Rust guarantees memory safety and thread
safety, eliminating a handful of bugs at compile-time.

Moreover, Rust provides a new way of programming. The language provides
beautiful features such as traits, enums, and error handling, that can
make us feel empowered by the language. We can use a lot of concepts from
functional programming and mix them with concepts from OOP, for example.

Although I'm an absolute beginner in Rust, I can see the major advantages of the
Rust programming language. From the start, it was a bit tough to enjoy the
language, as I was fighting with the compiler most of the time. But now that I
have a more firm foundation on Rust, it is possible to appreciate the beauty in
Rust and I don't see myself starting a new project in C++ for a long while.

Bringing Rust to the Linux Kernel is a ambitious idea, but it can lead to
great changes. We can think about a world where no developers are looking for
memory leaks and use-after-free bugs due to the safety that Rust can provide us.

# Rust on DRM
---
Now, what about Rust for DRM? I mean, I'm not the first one to think about it.
[Asahi Lina](https://twitter.com/LinaAsahi) is making a fantastic work on the
Apple M1 GPU and things are moving quite fast there. She already had great safe
abstractions for the DRM bindings and provides us the very basis for anyone who
is willing to start a new DRM driver in Rust, which is my case.

That said, why not make use of Lina's excellent bindings to build a new driver?

# Rust for VGEM
---
VGEM (Virtual GEM Provider) is a minimal non-hardware backed GEM (Graphics
Execution Manager) service. It is used with non-native 3D hardware for buffer
sharing between the X server and DRI. It is a fairly simple driver with about
400 lines of code and it uses the DMA Fence API to handle attaching and
signaling the fences.

So, to rewrite VGEM in Rust, some bindings are needed, e.g. bindings for
platform device, for XArray, and for dealing with DMA fence and DMA
reservations. Furthermore, many DRM abstractions are needed as well.

In this sense, a lot of the DRM abstractions are already developed by Lina and
also she is developing abstractions for DMA fence. So, in this project, I'll be
focusing on the bindings that Lina and the RfL folks haven't developed yet.

After developing the bindings, it is a matter of developing the driver, which
it'll be quite simple after all DMA abstractions are set, because most of the
driver consists of fence manipulation.

# Current Status
---
I have developed the main platform device registration of the driver. As VGEM is
a virtual device, the standard probe initialization is not useful, as a virtual
device cannot be probed by the pseudo-bus that holds the platform devices. So,
as VGEM is not a usual hotplugged device, we need to use the legacy platform
device initialization. This made me develop my first binding for legacy
registration:

```rust
/// Add a platform-level device and its resources
pub fn register(name: &'static CStr, id: i32) -> Result<Self> {
	let pdev = from_kernel_err_ptr(unsafe {
		bindings::platform_device_register_simple(name.as_char_ptr(), id,
			core::ptr::null(), 0)
	})?;

	Ok(Self {
		ptr: pdev,
		used_resource: 0,
		is_registered: true,
	})
}
```

For sure, the registration must follow the unregistration of the device, so I
implemented a Drop trait for the struct Device in order to guarantee the proper
device removal without explicitly calling it.

```rust
impl Drop for Device {
	fn drop(&mut self) {
		if self.is_registered {
			// SAFETY: This path only runs if a previous call to `register`
			// completed successfully.
			unsafe { bindings::platform_device_unregister(self.ptr) };
		}
	}
}
```

After those, I also developed bindings for a couple of more functions and
together with Lina's bindings, I could initialize the platform device and
register the DRM device under a DRM minor!

```
[   38.825684] vgem: vgem_init: platform_device with id -1
[   38.826505] [drm] Initialized vgem 1.0.0 20230201 for vgem on minor 0
[   38.858230] vgem: Opening...
[   38.862377] vgem: Closing...
[   41.543416] vgem: vgem_exit: drop
```

Next, I focused on the development of the two IOCTLs: `drm_vgem_fence_attach`
and `drm_vgem_fence_signal`. The first is responsable for creating and attaching
a fence to the VGEM handle, while the second signals and consumes a fence
earlier attached to a VGEM handle.

In order to add a fence, bindings to DMA reservation are needed. So, I started
by creating a safe abstraction for `struct dma_resv`.

```rust
/// A generic DMA Resv Object
///
/// # Invariants
/// ptr is a valid pointer to a dma_resv and we own a reference to it.
pub struct DmaResv {
    ptr: *mut bindings::dma_resv,
}

impl DmaResv {
	
    [...]
	
    /// Add a fence to the dma_resv object
    pub fn add_fences(
        &self,
        fence: &dyn RawDmaFence,
        num_fences: u32,
        usage: bindings::dma_resv_usage,
    ) -> Result {
        unsafe { bindings::dma_resv_lock(self.ptr, core::ptr::null_mut()) };

        let ret = self.reserve_fences(num_fences);
        match ret {
            Ok(_) => {
                // SAFETY: ptr is locked with dma_resv_lock(), and dma_resv_reserve_fences()
                // has been called.
                unsafe {
                    bindings::dma_resv_add_fence(self.ptr, fence.raw(), usage);
                }
            }
            Err(_) => {}
        }
        
        unsafe { bindings::dma_resv_unlock(self.ptr) };

        ret
    }
}
```

With that step, I could simply write the IOCTLs based on the new `DmaResv`
abstraction and Lina's fence abstractions.

To test the IOCTLs, I used some already available IGT tests: `dmabuf_sync_file`
and `vgem_basic`. Those tests use VGEM as it base, so if the tests pass, it
means that the IOCTLs are working properly. And, after some debugging and rework
in the IOCTLs, I managed to get most of the tests to pass!

```
[root@fedora igt-gpu-tools]# ./build/tests/dmabuf_sync_file
IGT-Version: 1.27-gaa16e812 (x86_64) (Linux: 6.2.0-rc3-asahi-02441-g6c8eda039cfb-dirty x86_64)
Starting subtest: export-basic
Subtest export-basic: SUCCESS (0.000s)
Starting subtest: export-before-signal
Subtest export-before-signal: SUCCESS (0.000s)
Starting subtest: export-multiwait
Subtest export-multiwait: SUCCESS (0.000s)
Starting subtest: export-wait-after-attach
Subtest export-wait-after-attach: SUCCESS (0.000s)
```

You can check out the current progress of this project on this
[pull request](https://github.com/mairacanal/linux/pull/11).

# Next Steps
---
Although most of the IGT tests are now passing, two tests aren't working yet:
`vgem_slow`, as I haven't introduced the timeout yet, and `vgem_basic@unload`,
as I still need to debug why the `Drop` trait from `drm::drv::Registration` is
not being called.

After bypassing those two problems, I still need to rework some of my code, as,
for example, I'm using a dummy IOCTL as IOCTL number 0x00, as the current macro
`kernel::declare_drm_ioctl` doesn't support any drivers for which the IOCTL doesn't
start in 0x00.

So, there is a lot of work yet to be done!
