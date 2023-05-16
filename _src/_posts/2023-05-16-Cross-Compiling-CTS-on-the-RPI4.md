---
title: "Cross-Compiling CTS for the Raspberry Pi 4"
date: 2023-05-16T09:00:00-03:00
author: Maíra Canal
permalink: /cross-compiling-cts-rpi4/
tags: [igalia, graphics, embedded]
---

This blogpost was actually written partially in November/December 2022 while I was developing IGT tests for the V3D driver.
I ended up leaving it aside for a while and now, I came back and finished the last loose ends.
That's why I'm referencing the time where I was fighting against V3D's noop jobs.

---

Currently, during my [Igalia Coding Experience](https://www.igalia.com/coding-experience/), I'm working on the V3D's IGT tests and therefore, I'm dealing a lot with the Raspberry Pi 4.
During the project, I had a real struggle to design the tests for the `v3d_submit_cl` ioctl, as I was not capable of submit a proper noop job to the GPU.

In order to debug the tests, my mentor [Melissa Wen](https://melissawen.github.io/) suggested to me to run the CTS tests to reproduce a noop job and debug it through Mesa.
I cloned the CTS repository into my Raspberry Pi 4 and I tried to compile, but my Raspberry Pi 4 went OOM.
This sent me on a journey to cross-compile CTS for the Raspberry Pi 4.
I decided to compile this journey into this blogpost.

During this blogpost, I'm using a Raspbian OS with desktop 64-bit.

# Installing Mesa
---
First, you need to install Mesa on the Raspberry Pi 4.
I decided to compile Mesa on the Raspberry Pi 4 itself, but maybe one day, I can write a blogpost about cross-compiling Mesa.

## 1. Installing libdrm

Currently, the Raspbian repositories only provide `libdrm 2.4.104` and Mesa's main branch needs `libdrm >=2.4.109`.
So, first, let's install `libdrm 2.4.109` on the Raspberry Pi 4.

First, let's make sure that you have `meson` installed on your RPi4.
We will need `meson` to build `libdrm` and Mesa.
I'm installing `meson` through `pip3` because we need a `meson` version greater than 0.60 to build Mesa.

```shell
# On the Raspberry Pi 4
$ sudo pip3 install meson
```

Then, you can install `libdrm 2.4.109` on the RPi4.

```shell
# On the Raspberry Pi 4
$ wget https://dri.freedesktop.org/libdrm/libdrm-2.4.114.tar.xz
$ tar xvpf libdrm-2.4.114.tar.xz
$ cd libdrm-2.4.114
$ mkdir build
$ cd build
$ FLAGS="-O2 -march=armv8-a+crc+simd -mtune=cortex-a72" \
    CXXFLAGS="-O2 -march=armv8-a+crc+simd -mtune=cortex-a72" \
    meson -Dudev=true -Dvc4="enabled" -Dintel="disabled" -Dvmwgfx="disabled" \
    -Dradeon="disabled" -Damdgpu="disabled" -Dnouveau="disabled" -Dfreedreno="disabled" \
    -Dinstall-test-programs=true ..
$ sudo ninja install
```

## 2. Going back to Mesa

So, now let's install Mesa.
During this blogpost, I will use `${USER}` as the username on the machine.
Note that, in order to run `sudo apt build-dep mesa`, you will have to uncomment some `deb-src` on the file `/etc/apt/sources.list` and run `sudo apt update`.

```shell
# On the Raspberry Pi 4

# Install Mesa's build dependencies
$ sudo apt build-dep mesa

# Build and Install Mesa
$ git clone https://gitlab.freedesktop.org/mesa/mesa
$ cd mesa
$ mkdir builddir
$ mkdir installdir
$ CFLAGS="-mcpu=cortex-a72" CXXFLAGS="-mcpu=cortex-a72" \
    meson -Dprefix="/home/${USER}/mesa/installdir" -D platforms=x11 \
    -D vulkan-drivers=broadcom \
    -D gallium-drivers=kmsro,v3d,vc4 builddir
$ cd builddir
$ ninja
$ cd ..
$ ninja -C builddir install
```

# Creating the Raspberry Pi's sysroot
---
In order to cross-compile the Raspberry Pi, you need to clone the target sysroot to the host.
For it, we are going to use `rsync`, so the host and the target need to be connected through a network.

## On the Raspberry Pi 4

### 1. Update the system

```bash
$ sudo apt update
$ sudo apt dist-upgrade
```

### 2. Enable rsync with elevated rights

As I said before, we will be using the `rsync` command to sync files between the host and the Raspberry Pi.
For some of these files, root rights is required internally, so let's enable `rsync` with elevated rights.

```bash
$ echo "$USER ALL=NOPASSWD:$(which rsync)" | sudo tee --append /etc/sudoers
```

### 3. Setup important symlinks

Some symbolic links are needed to make the toolchain work properly, so to create all required symbolic link reliably, this bash script is needed.

```bash
$ wget https://raw.githubusercontent.com/abhiTronix/raspberry-pi-cross-compilers/master/utils/SSymlinker
```

Once it is downloaded, you just need to make it executable, and then run it for each path needed.

```bash
$ sudo chmod +x SSymlinker
$ ./SSymlinker -s /usr/include/aarch64-linux-gnu/asm -d /usr/include
$ ./SSymlinker -s /usr/include/aarch64-linux-gnu/gnu -d /usr/include
$ ./SSymlinker -s /usr/include/aarch64-linux-gnu/bits -d /usr/include
$ ./SSymlinker -s /usr/include/aarch64-linux-gnu/sys -d /usr/include
$ ./SSymlinker -s /usr/include/aarch64-linux-gnu/openssl -d /usr/include
$ ./SSymlinker -s /usr/lib/aarch64-linux-gnu/crtn.o -d /usr/lib/crtn.o
$ ./SSymlinker -s /usr/lib/aarch64-linux-gnu/crt1.o -d /usr/lib/crt1.o
$ ./SSymlinker -s /usr/lib/aarch64-linux-gnu/crti.o -d /usr/lib/crti.o
```

## On the host machine

### 1. Setting up the directory structure

First, we need to create a workspace for building CTS, where the Raspberry Pi 4 sysroot is going to be built.

```bash
$ sudo mkdir ~/rpi-vk
$ sudo mkdir ~/rpi-vk/installdir
$ sudo mkdir ~/rpi-vk/tools
$ sudo mkdir ~/rpi-vk/sysroot
$ sudo mkdir ~/rpi-vk/sysroot/usr
$ sudo mkdir ~/rpi-vk/sysroot/usr/share
$ sudo chown -R 1000:1000 ~/rpi-vk
$ cd ~/rpi-vk
```

### 2. Sync Raspberry Pi 4 sysroot

Now, we need to sync up our sysroot folder with the system files from the Raspberry Pi.
We will be using `rsync` that let us sync files from the Raspberry Pi.
To do this, enter the following commands one by one into your terminal and remember to change username and 192.168.1.47 with the IP address of your Raspberry Pi.

```bash
$ rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.1.47:/lib sysroot
$ rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.1.47:/usr/include sysroot/usr
$ rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.1.47:/usr/lib sysroot/usr
$ rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.1.47:/usr/share sysroot/usr
$ rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.1.47:/home/${USER}/mesa/installdir installdir
```

### 3. Fix symbolic links

The files we copied in the previous step still have symbolic links pointing to the file system on the Raspberry Pi.
So, we need to alter this, so that they become relative links from the new `sysroot` directory on the host machine.

There is a Python script available online that can help us.

```bash
$ wget https://raw.githubusercontent.com/abhiTronix/rpi_rootfs/master/scripts/sysroot-relativelinks.py
```

Once it is downloaded, you just need to make it executable and run it.

```bash
$ sudo chmod +x sysroot-relativelinks.py
$ ./sysroot-relativelinks.py sysroot
```

### 4. Installing the Raspberry Pi 64-Bit Cross-Compiler Toolchain

As Raspbian OS 64-bits uses GCC 10.2.0, let's install the proper cross-compiler toolchain on our host machine.
I'm using the toolchain provided by [abhiTronix/raspberry-pi-cross-compilers](https://github.com/abhiTronix/raspberry-pi-cross-compilers), but there are many other around the web that you can use.

We are going to use the `tools` folder to setup our toolchain.

```bash
$ cd ~/rpi-vk/tools
$ wget https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Bonus%20Raspberry%20Pi%20GCC%2064-Bit%20Toolchains/Raspberry%20Pi%20GCC%2064-Bit%20Cross-Compiler%20Toolchains/Bullseye/GCC%2010.2.0/cross-gcc-10.2.0-pi_64.tar.gz/download
$ tar xvf download
$ rm download
```

### 5. Setting up Wayland

If you run all the steps from this tutorial expect this one, you will still get some weird Wayland-related errors when cross-compiling it.
This will happen because probably the `wayland-scanner` version from your host is different from the `wayland-scanner` version of the target.
For example, on Fedora 37, the `wayland-scanner` version is 1.21.0 and the version on the Raspberry Pi 4 is 1.18.0.

In order to build Wayland, you will need the following dependencies:

```shell
$ sudo dnf install expat-devel xmlto
```

So, let's install the proper Wayland version on our sysroot.

```shell
$ wget https://wayland.freedesktop.org/releases/wayland-1.18.0.tar.xz
$ tar xvf wayland-1.18.0.tar.xz
$ cd wayland-1.18.0
$ meson --prefix ~/rpi-vk/sysroot/usr build
$ ninja -C install
```

# Let's cross-compile CTS!
---
Now that we have the hole Raspberry Pi environment set up, we just need to create a toolchain file for CMake and its all set!
So, let's clone the CTS repository.

```shell
$ git clone https://github.com/KhronosGroup/VK-GL-CTS
$ cd VK-GL-CTS
```

To build dEQP, you need first to download sources for zlib, libpng, jsoncpp, glslang, vulkan-docs, spirv-headers, and spirv-tools.
To download sources, run:

```shell
$ python3 external/fetch_sources.py
```

Inside the CTS directory, we are going to create a toolchain file called `cross_compiling.cmake` with the following contents:

```cmake
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Check if the sysroot and toolchain paths are correct
set(tools /home/${USER}/rpi-vk/tools/cross-pi-gcc-10.2.0-64)
set(rootfs_dir $ENV{HOME}/rpi-vk/sysroot)

set(CMAKE_FIND_ROOT_PATH ${rootfs_dir})
set(CMAKE_SYSROOT ${rootfs_dir})

set(ENV{PKG_CONFIG_PATH} "")
set(ENV{PKG_CONFIG_LIBDIR} "${CMAKE_SYSROOT}/usr/lib/pkgconfig:${CMAKE_SYSROOT}/usr/share/pkgconfig")
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_SYSROOT})

set(CMAKE_LIBRARY_ARCHITECTURE aarch64-linux-gnu)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fPIC -Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} -L${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}")
set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} -L${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} -L${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}")

set(WAYLAND_SCANNER ${CMAKE_SYSROOT}/usr/bin/wayland-scanner)

## Compiler Binary
SET(BIN_PREFIX ${tools}/bin/aarch64-linux-gnu)

SET (CMAKE_C_COMPILER ${BIN_PREFIX}-gcc)
SET (CMAKE_CXX_COMPILER ${BIN_PREFIX}-g++ )
SET (CMAKE_LINKER ${BIN_PREFIX}-ld
            CACHE STRING "Set the cross-compiler tool LD" FORCE)
SET (CMAKE_AR ${BIN_PREFIX}-ar
            CACHE STRING "Set the cross-compiler tool AR" FORCE)
SET (CMAKE_NM {BIN_PREFIX}-nm
            CACHE STRING "Set the cross-compiler tool NM" FORCE)
SET (CMAKE_OBJCOPY ${BIN_PREFIX}-objcopy
            CACHE STRING "Set the cross-compiler tool OBJCOPY" FORCE)
SET (CMAKE_OBJDUMP ${BIN_PREFIX}-objdump
            CACHE STRING "Set the cross-compiler tool OBJDUMP" FORCE)
SET (CMAKE_RANLIB ${BIN_PREFIX}-ranlib
            CACHE STRING "Set the cross-compiler tool RANLIB" FORCE)
SET (CMAKE_STRIP {BIN_PREFIX}-strip
            CACHE STRING "Set the cross-compiler tool RANLIB" FORCE)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```

Note that we had to specify our toolchain and also the specify the path to the `wayland-scanner`.
Now that we are all set, we can finally cross-compile CTS.

```shell
$ mkdir build
$ cd build
$ cmake -DCMAKE_BUILD_TYPE=Debug \
	-DCMAKE_LIBRARY_PATH=/home/${USER}/rpi-vk/installdir/lib \
	-DCMAKE_INCLUDE_PATH=/home/${USER}/rpi-vk/installdir/include \
	-DCMAKE_GENERATOR=Ninja \
	-DCMAKE_TOOLCHAIN_FILE=/home/${USER}/VK-GL-CTS/cross_compiling.cmake ..
$ ninja
```

Now, you can transfer the compiled files to the Raspberry Pi 4 and run CTS!

---
This was a fun little challenge of my CE project and it was pretty nice to learn more about CTS.
Running CTS was also a great idea from Melissa as I was able to hexdump the contents of a noop job for the V3DV and fix my noop job on IGT.
So, now I finally have a working noop job on IGT and you can check it [here](https://patchwork.freedesktop.org/series/112363/).

Also, a huge thanks to my friend [Arthur Grillo](https://grillo-0.github.io/blog/) for helping me with resources about cross-compiling for the Raspberry Pi.
