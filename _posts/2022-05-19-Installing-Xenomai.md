---
title: "Installing Xenomai on the Beaglebone Black"
date: 2022-05-19T00:00:00+00:00
author: Maíra Canal
layout: post
permalink: /install-xenomai-beaglebone-black/
categories: Genel
tags: [linux, embedded]
---

There are many ways to bring Real-Time to Linux. A standard Linux distribution can provide a reasonable latency to a soft real-time application. But, if you are dealing with applications with harsh timing restrictions, you might be unsatisfied with the results provided by a standard Linux distro.

There are basically 3 options for building a Linux Real-Time system:

1. **Dual-Kernel/Hypervisor approach:** A combination between a micro-kernel and the Linux Kernel, where the micro-kernel has priority over the Linux Kernel and manages the real-time tasks. This approach has a major disadvantage: the need to maintain the microkernel, doubling the work to develop and maintain drivers, and architecture-specific software.

2. **Heterogeneous Asymmetric Multi-Core System:** A system where a Linux and a deterministic kernel, such as FreeRTOS, run independently on different cores. The deterministic kernel is then responsible for the real-time tasks.

3. **Single-Kernel approach:** Make the Linux Kernel more real-time capable by improving its preemptiveness.

Xenomai has two options to deliver real-time: a dual-kernel approach and a single-kernel approach.

The dual-kernel approach is named Cobalt. The Cobalt extension is built into the Linux kernel and deals with all real-time tasks by scheduling real-time threads. The Cobalt core has a higher priority over the Linux kernel native activities.

Moreover, Xenomai also provides the Mercury core, which relies on the real-time capabilities of the native Linux kernel.

As I was setting up a system for my undergraduate research, I have been trying to install Xenomai on the Beaglebone Black. I found a bunch of tutorials online, but a huge part of them was outdated and some simply did not work for me. So, I decided to synthesize all my work installing Xenomai on the Beaglebone Black.

There are two ways to install Xenomai on the Beaglebone Black:

1. By recompiling the Linux Kernel and applying the appropriate patches.

2. By using a precompiled kernel with the Xenomai patches already applied.

I used the second approach because it is slightly faster. But, if you want to stick with the first approach, I recommend checking on the [Xenomai documentation](https://source.denx.de/Xenomai/xenomai/-/wikis/Installing_Xenomai_3).

So, let's install Xenomai.

## Installing Xenomai

### 1. Install Debian on the Beaglebone Black

If you already have Debian installed on your Beaglebone Black, then just skip this step.

Otherwise, you can follow the [tutorial](http://derekmolloy.ie/write-a-new-image-to-the-beaglebone-black/) from Derek Molloy on how to write a Debian Image to the Beaglebone Black. 

### 2. Install the Cobalt Core

First, we need to access the Beaglebone Black through SSH.

```
ssh debian@192.168.7.2
```

In order to keep the repositories and packages updated before we start the Cobalt core installation, we can run:

```
sudo apt update
sudo apt upgrade
```

To install the Cobalt core, first, we need to know the version of the Linux image we will install. A couple of pre-compiled kernel versions are provided by Beagleboard for Debian Buster and they are listed [here](http://repos.rcn-ee.net/latest/buster-armhf/LATEST-ti-xenomai).

After deciding on the kernel version, we can just run the following command to install and update the kernel.

```
sudo apt install linux-image-{KERNEL TAGFORM}
```

I installed the 4.19.94-ti-xenomai-r64 version, so I ran:

```
sudo apt install linux-image-4.19.94-ti-xenomai-r64
```

To load the new kernel, we need to reboot the machine and reconnect through SSH.

```
sudo reboot
ssh debian@192.168.7.2
```

To check that the kernel was properly installed, we can check the kernel version with:

```
uname -r
```

The output must be the kernel tag form that you selected previously. In my case, the output was 4.19.94-ti-xenomai-r64.

We can also check the kernel log and search for Xenomai references. Looking at `dmesg`, we will find something like this:

```
debian@beaglebone:~$ dmesg | grep -i xenomai
[    0.000000] Linux version 4.19.94-ti-xenomai-r64 (voodoo@rpi4b4g-06) (gcc version 8.3.0 (Debian 8.3.0-6)) #1buster SMP PREEMPT Sat May 22 01:02:28 UTC 2021
[    1.220506] [Xenomai] scheduling class idle registered.
[    1.220521] [Xenomai] scheduling class rt registered.
[    1.220676] I-pipe: head domain Xenomai registered.
[    1.225554] [Xenomai] Cobalt v3.1
[    1.753962] usb usb1: Manufacturer: Linux 4.19.94-ti-xenomai-r64 musb-hcd
```

Look that we are running Cobalt v3.1 and this version is extremely important to the next step.

### 3. Install Xenomai userspace tools and bindings

First, we need to install the appropriate Xenomai bindings. From the kernel log, I could check that I'm running Cobalt v3.1, so I'm going to download the Xenomai 3.1 tarball.

```
wget https://xenomai.org/downloads/xenomai/stable/xenomai-3.1.tar.bz2
```

If you are running another version of Cobalt, you can just change the version tag from the URL.

Next, we can decompress the tarball and get inside the Xenomai folder.

```
tar xf xenomai-3.1.tar.bz2
cd xenomai-3.1
```

Now, it is time to build and install the Xenomai binding. First, we need to configure the built environment by running:

```
./configure --enable-smp
```

Although the Beaglebone Black has a single-core processor, the flag `--enable-smp` is important, because the precompiled kernel versions from Beagleboard enable CONFIG_SMP by default.

Then, finally, we can build and install Xenomai.

```
make
sudo make install
```

And then, you are done!

You can test the real-time system by running:

```
sudo su
/usr/xenomai/bin/latency
```

The output will be similar to this:

```
== Sampling period: 1000 us
== Test mode: periodic user-mode task
== All results in microseconds
warming up...
RTT|  00:00:01  (periodic user-mode task, 1000 us period, priority 99)
RTH|----lat min|----lat avg|----lat max|-overrun|---msw|---lat best|--lat worst
RTD|      7.875|     13.579|     50.625|       0|     0|      7.875|     50.625
RTD|     11.458|     15.983|     53.958|       0|     0|      7.875|     53.958
RTD|     11.458|     13.997|     50.750|       0|     0|      7.875|     53.958
RTD|     11.541|     15.578|     55.999|       0|     0|      7.875|     55.999
RTD|     11.416|     13.186|     52.208|       0|     0|      7.875|     55.999
RTD|     11.499|     14.507|     57.249|       0|     0|      7.875|     57.249
RTD|     11.499|     13.787|     48.707|       0|     0|      7.875|     57.249
RTD|     11.540|     13.694|     50.582|       0|     0|      7.875|     57.249
RTD|     11.456|     15.118|     49.498|       0|     0|      7.875|     57.249
RTD|     11.373|     13.618|     51.290|       0|     0|      7.875|     57.249
RTD|     11.498|     15.844|     48.914|       0|     0|      7.875|     57.249
RTD|     11.539|     17.654|     55.581|       0|     0|      7.875|     57.249
RTD|     11.539|     15.403|     52.622|       0|     0|      7.875|     57.249
RTD|     11.539|     12.955|     51.580|       0|     0|      7.875|     57.249
RTD|     10.747|     13.254|     52.163|       0|     0|      7.875|     57.249
^C---|-----------|-----------|-----------|--------|------|-------------------------
RTS|      7.875|     14.543|     57.249|       0|     0|    00:00:15/00:00:15
```

This command displays a message every second with minimum, maximum, and average latency values. Notice that all the latencies are in the order of microseconds.

So, now, you can go on and build a real-time application with the Xenomai userspace API on the Beaglebone Black.
