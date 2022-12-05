---
title: "Cross-Compiling CTS for Raspberry Pi 4"
date: 2022-12-05
author: Maíra Canal
layout: post
permalink: /cross-compiling-cts-rpi4/
categories: Genel
tags: [igalia, graphics, embedded]
---

Currently, during my [Igalia Coding Experience](https://www.igalia.com/coding-experience/),
I'm working on the V3D's IGT tests and therefore, I'm dealing a lot with the Raspberry
Pi 4. During the project, I had a real strugle to design the tests for the
`v3d_submit_cl` ioctl, as I was not capable of submit a proper noop job to the
GPU.

In order to debug the tests, my mentor [Melissa Wen]() suggested me to run the
CTS tests to reproduce a noop job and debug it through Mesa. I cloned the CTS
repository into my Raspberry Pi 4 and I tried to compile, but my Raspberry Pi 4
went OOM. This sent me on a journey to cross-compiling CTS for the Raspberry
Pi 4. I decided to compile this journey into this blogpost.

During this blogpost, I'm using a Raspbian OS with desktop 64-bit.

# Installing Mesa

First, you need to install Mesa on the Raspberry Pi 4. I decided to compile
Mesa on the Raspberry Pi 4 itself, but maybe one day, I can write a blogpost
about cross-compiling Mesa.

## Installing libdrm

Currently, the Raspbian repositories only provide `libdrm 2.4.104` and Mesa's
main branch needs `libdrm >=2.4.109`. So, first, let's install `libdrm 2.4.109`
on the Raspberry Pi 4.

```bash
# On the Raspberry Pi 4
$ wget https://dri.freedesktop.org/libdrm/libdrm-2.4.114.tar.xz
$ tar xvpf libdrm-2.4.114.tar.xz
$ mkdir build
$ cd build
$ FLAGS="-O2 -march=armv8-a+crc+simd -mtune=cortex-a72" \
    CXXFLAGS="-O2 -march=armv8-a+crc+simd -mtune=cortex-a72" \
    meson -Dudev=true -Dvc4="enabled" -Dintel="disabled" -Dvmwgfx="disabled" \
    -Dradeon="disabled" -Damdgpu="disabled" -Dnouveau="disabled" -Dfreedreno="disabled" \
    -Dinstall-test-programs=true ..
$ sudo ninja install
```

## Going back to Mesa

So, now let's install Mesa.

```bash
# On the Raspberry Pi 4
$ git clone https://gitlab.freedesktop.org/mesa/mesa
$ cd mesa
$ mkdir builddir
$ mkdir installdir
$ CFLAGS="-mcpu=cortex-a72" CXXFLAGS="-mcpu=cortex-a72" \
    meson -Dprefix="/home/${USER}/mesa/installdir" -D platforms=x11 \
    -D vulkan-drivers=broadcom -D dri-drivers= \
    -D gallium-drivers=kmsro,v3d,vc4 builddir
```

# Creating the Raspberry Pi's sysroot

In order to cross-compile the Raspberry Pi, you need to clone the target 
sysroot to the host. For it, we are going to use `rsync`, so the host and
the target need to be conected through a network.

## On the Raspberry Pi 4

### 1. Update the system 

```bash
sudo apt update
sudo apt dist-upgrade
```

### 2. Enable rsync with elevated rights

As I said before, we will be using the `rsync` command to sync files between
the host and the Raspberry Pi. For some of these files, root rights is required
internally, so let's enable `rsync` with elevated rights.

```bash
echo "$USER ALL=NOPASSWD:$(which rsync)" | sudo tee --append /etc/sudoers
```

### 3. Setup important symlinks

Some symbolic links are needed to make the toolchain work properly, so to 
create all required symbolic link reliably, this bash script is needed.

```bash
wget https://raw.githubusercontent.com/abhiTronix/raspberry-pi-cross-compilers/master/utils/SSymlinker
```

Once it is downloaded, you just need to make it executable, and then run it
for each path needed.

```bash
sudo chmod +x SSymlinker
./SSymlinker -s /usr/include/aarch64-linux-gnu/asm -d /usr/include
./SSymlinker -s /usr/include/aarch64-linux-gnu/gnu -d /usr/include
./SSymlinker -s /usr/include/aarch64-linux-gnu/bits -d /usr/include
./SSymlinker -s /usr/include/aarch64-linux-gnu/sys -d /usr/include
./SSymlinker -s /usr/include/aarch64-linux-gnu/openssl -d /usr/include
./SSymlinker -s /usr/lib/aarch64-linux-gnu/crtn.o -d /usr/lib/crtn.o
./SSymlinker -s /usr/lib/aarch64-linux-gnu/crt1.o -d /usr/lib/crt1.o
./SSymlinker -s /usr/lib/aarch64-linux-gnu/crti.o -d /usr/lib/crti.o
```

# On the host machine

### 1. Setting up the directory structure

First, we need to create a workspace for building CTS, where the Raspberry Pi 4
sysroot is going to be built.

```bash
sudo mkdir ~/rpi-vk
sudo mkdir ~/rpi-vk/installdir
sudo mkdir ~/rpi-vk/tools
sudo mkdir ~/rpi-vk/sysroot
sudo mkdir ~/rpi-vk/sysroot/usr
sudo chown -R 1000:1000 ~/rpi-vk
cd ~/rpi-vk
```

### 2. Sync Raspberry Pi 4 sysroot

```bash
rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.1.47:/lib sysroot
rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.1.47:/usr/include sysroot/usr
rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.1.47:/usr/lib sysroot/usr
```
