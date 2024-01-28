---
title: "Adding a Timeout feature to Rustgem"
date: 2023-03-22
author: Maíra Canal
permalink: /adding-timeout-rustgem/
categories: [Tech]
tags: [igalia, graphics]
---

After my last blogpost, I kept developing the Rust version of the VGEM driver,
also known as rustgem for now. Previously, I had developed two important
features of the driver: the ability to attach a fence and the ability to signal
a fence. Still one important feature is still missing: the ability to prevent
hangs. Currently, if the fence is not signaled, the driver will simply hang. So,
we can create a callback that signals the fence when the fence is not signaled
by the user for more than 10 seconds.

In order to create this callback, we need to have a Timer that will trigger it
after the specified amount of time.  Gladly, the Linux kernel provides us with a
Timer that can be set with a callback and a timeout. But, to use it in the Rust
code, we need to have a safe abstraction, that will ensure that the code is safe
under some assumptions.

# First Attempt: writing a Timer abstraction
---

Initially, I was developing an abstraction on my own as I checked the RfL
tree and there were no Timer abstractions available.

The most important question here is "how can we guarantee access to other
objects inside the callback?". The callback only has receives a pointer to the
`struct timer_list` as its single argument. Naturally, we can think about using
a `container_of` macro. In order to make the compatibility layer between
Rust and the C callback, I decided to store the object inside the Timer. Yep, I
didn't like that a lot, but it was the solution I came up with at the time. The
struct looked something like this:

```rust
/// A driver-specific Timer Object
//
// # Invariants
// timer is a valid pointer to a struct timer_list and we own a reference to it.
[repr(C)]
pub struct UniqueTimer<T: TimerOps<Inner = D>, D> {
   timer: *bindings::timer_list,
   inner: D,
   _p: PhantomData<T>,
}
```

Moreover, the second important question I had was "how can the user pass a
callback function to the timer?". There were two possibilities: using a closure
and using a Trait. I decided to go through the trait path. Things would be kind
of similar if I decided to go into the closure path.

```rust
/// Trait which must be implemented by driver-specific timer objects.
pub trait TimerOps: Sized {
    /// Type of the Inner data inside the Timer
    type Inner;

    /// Timer callback
    fn timer_callback(timer: &UniqueTimer<Self, Self::Inner>);
}
```

With those two questions solved, it seems that we are all set and good to go.
So, we can create methods to initialize the timer and modify the timer's
timeout, implement the Drop trait, and use the following callback by default:

```rust
unsafe extern "C" fn timer_callback<T: TimerOps<Inner = D>, D: Sized>(
    timer: *mut bindings::timer_list,
) {
    let timer = crate::container_of!(timer, UniqueTimer<T, D>, timer)
			    as *mut UniqueTimer<T, D>;

    // SAFETY: The caller is responsible for passing a valid timer_list subtype
    T::timer_callback(unsafe { &mut *timer });
}
```

All should work, right? Well... No, I didn't really mention how I was allocating
memory. And let's say I was initially allocating it wrongly and therefore, the
`container_of` macro was pointing to the wrong memory space.

Initially, I was allocating only `timer` with the kernel memory allocator
`krealloc` and allocating the rest of the struct with Rust's memory allocator.
By making such a mess, `container_of` wasn't able to point to the right
memory address.

I had to change things a bit to allocate the whole struct `UniqueTimer` with
the kernel's memory allocator. However, `krealloc` returns a raw pointer and it
would be nice for the final user to get a raw pointer to the object. I wrapped
up inside another struct that could be dereferenced into the `UniqueTimer`
object.

```rust
/// A generic Timer Object
///
/// This object should be instantiated by the end user, as it holds
/// a unique reference to the UniqueTimer struct. The UniqueTimer
/// methods can be used through it.
pub struct Timer<T: TimerOps<Inner = D>, D>(*mut UniqueTimer<T, D>);

impl<T: TimerOps<Inner = D>, D> Timer<T, D> {
    /// Create a timer for its first use
    pub fn setup(inner: D) -> Self {
        let t = unsafe {
            bindings::krealloc(
                core::ptr::null_mut(),
                core::mem::size_of::<UniqueTimer<T, D>>(),
                bindings::GFP_KERNEL | bindings::__GFP_ZERO,
            ) as *mut UniqueTimer<T, D>
        };

        // SAFETY: The pointer is valid, so pointers to members are too.
        // After this, all fields are initialized.
        unsafe {
            addr_of_mut!((*t).inner).write(inner);
            bindings::timer_setup(addr_of_mut!((*t).timer), Some(timer_callback::<T, D>), 0)
        };

        Self(t)
    }
}
```

And then the `container_of` macro started working! Now, I could setup a Timer
for each fence and keep the fence inside the timer. Finally, I could use the
fence inside the timer to signal it when it was not signaled by the user for
more than 10 seconds.

```rust
impl TimerOps for VgemFenceOps {
    type Inner = UniqueFence<Self>;

    fn timer_callback(timer: &UniqueTimer<Self, UniqueFence<Self>>) {
        let _ = timer.inner().signal();
    }
}
```

So, I tested the driver with IGT using the `vgem_slow` test and it was now
passing! All IGT tests were passing and it looked like the driver was
practically completed (some FIXME problems notwithstanding). But, let's see if
this abstraction is really safe...

# Second Attempt: using a Timer abstraction
---

First, let's inspect the `struct timer_list` in the C code.

```c
struct timer_list {
    struct hlist_node   entry;
    unsigned long       expires;
    void            (*function)(struct timer_list *);
    u32         flags;
};
```

By looking at this struct, we can see a problem in my abstraction: a timer
can point to a timer through a list. If you are not familiar with Rust, this can
seem normal, but self-referential types can lead to undefined behavior (UB).

Let's say we have an example type with two fields: `u32` and a pointer to this
`u32` value. Initially, everything looks fine, the pointer field points to the
value field in memory address A, which contains a valid `u32`, and all pointers
are **valid**. But Rust has the freedom to move values around memory. For
example, if we pass this struct into another function, it might get moved to a
different memory address. So, the once valid pointer is no longer valid, because
when we move the struct, the struct's fields change their address, but not their
value. Now, the pointer fields still point to the memory address A, although the
value field is located at the memory address B now. This is really bad and can
lead to UB.

The solution is to make `timer_list` implement the `!Unpin` trait. This means
that to use this type safely, we can't use regular pointers for self-reference.
Instead, we use special pointers that "pin" their values into place, ensuring
they can't be moved.

Still looking at the `struct timer_list`, it is possible to notice that a timer
can queue itself in the timer function. This functionality is not covered by my
current abstraction.

Moreover, I was using jiffies to modify the timeout duration and I was adding a
`Duration` to the jiffies. This is problematic, because it can cause a data
races. Reading jiffies and adding a duration to them should be an atomic
operation.

> Huge thanks to the RfL folks that pointed the errors in my implementation!

With all these problems pointed out, it is time to fix them! I could have
reimplemented my safe abstraction, but the RfL folks pointed me to a Timer
abstraction that they are developing in a [downstream
tree](https://github.com/fbq/linux-rust/commits/rust-dev). Therefore, I decided
to use their Timer abstraction.

There were two options to implement a Timer abstraction:

1. To implement the `Timeout` trait to the `VgemFence` struct
2. To use the `FnTimer` abstraction

In the end, I decided to go with the second approach. The `FnTimer` receives a
closure that will be executed at the timeout. The closure can return an enum that
indicated if the timer is done or if it should be rescheduled.

When implementing the timer, I had **a lot** of borrow checker problems.  See...
I need to use the `Fence` object inside the callback and also move the `Fence`
object at the end of the function. So, I got plenty of "cannot move out of
`fence` because it is borrowed" errors. Also, I needed the Timer to be dropped
at the same time as the fence, so I needed to store the Timer inside the
`VgemFence` struct.

The solution to the problems: smart pointers! I boxed the `FnTimer` and the closure
inside the `FnTimer` so that I could store it inside the `VgemFence` struct.
Then, the second problem got fixed. But, I still cannot use the fence inside the
closure, because it wasn't encapsulated inside a smart pointer. So, I used an
`Arc` to box `Fence`, clone it, and move it to the scope of the closure.

```rust
pub(crate) struct VgemFence {
	fence: Arc<UniqueFence<Fence>>,
	_timer: Box<FnTimer<Box<dyn FnMut() -> Result<Next> + Sync>>>,
}

impl VgemFence {
	pub(crate) fn create() -> Result<Self> {
		let fence_ctx = FenceContexts::new(1, QUEUE_NAME, &QUEUE_CLASS_KEY)?;
		let fence = Arc::try_new(fence_ctx.new_fence(0, Fence {})?)?;

		// SAFETY: The caller calls [`FnTimer::init_timer`] before using the timer.
		let t = Box::try_new(unsafe {
			FnTimer::new(Box::try_new({
				let fence = fence.clone();
				move || {
					let _ = fence.signal();
					Ok(Next::Done)
				}
			})? as Box<_>)
		})?;

		// SAFETY: As FnTimer is inside a Box, it won't be moved.
		let ptr = unsafe { core::pin::Pin::new_unchecked(&*t) };

		timer_init!(ptr, 0, "vgem_timer");

		// SAFETY: Duration.as_millis() returns a valid total number of whole milliseconds.
		let timeout =
			unsafe { bindings::msecs_to_jiffies(Duration::from_secs(10).as_millis().try_into()?) };

		// We force the fence to expire within 10s to prevent driver hangs
		ptr.raw_timer().schedule_at(jiffies_later(timeout));

		Ok(Self { fence, _timer: t })
	}
}
```

You can observe in this code that the initialization of the `FnTimer` uses an
`unsafe` operation. This happens because we still don't have [Safe Pinned
Initialization](https://y86-dev.github.io/blog/safe-pinned-initialization/overview.html).
But the RfL folks are working hard to land this feature and improve ergonomics
when using `Pin`.

Now, running again the `vgem_slow` IGT test, you can see that all IGT tests are
now passing!

# Next Steps
---

During this time, many improvements landed in the driver: all the objects are
being properly dropped, including the DRM device; all error cases are returning
the correct error; the SAFETY comments are properly written and most importantly,
the timeout feature was introduced. With that, all IGT tests are passing and the
driver is functional!

Now, the driver is in a good shape, apart from one FIXME problem: currently, the
IOCTL abstraction doesn't support any drivers that the IOCTLs don't start in
0x00 and the VGEM driver starts its IOCTLs with 0x01. I don't know yet how to
bypass this problem without adding a dummy IOCTL as 0x00, but I hope to get a
solution to it soon.

The progress of this project can be followed in this
[PR](https://github.com/mairacanal/linux/pull/11) and I hope to see this project
being integrated upstream in the future.
