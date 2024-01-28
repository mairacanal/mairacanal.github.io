---
title: "Linux Kernel Developing with Fedora"
date: 2022-06-11T00:00:00+00:00
author: Maíra Canal
permalink: /kernel-development-fedora/
categories: [Tech]
tags: [gsoc, kernel]
---

I’m a Fedora fan. I mean: I have two laptops for development, and all of them run Fedora. I also have a deployment machine. Guess what? It runs Fedora. Stickers? The Fedora Logo sticked forever on my laptop.

So, by now, you know: I’m **really** a Fedora fan.

So, when I started working with Linux Kernel, I really wanted to develop in a Fedora environment. But, without any kind of script, the work of a Linux Kernel developer is ungrateful. I mean, do you want to deploy to a remote machine? Be ready for network configurations, grub configurations, generate *initramfs* image, and tons of commands. Do you want to manage your config files? Basically, you are back to the ancient times when many save tons of config files on folders.

So, it’s a tremendous setup overhead. But, there is a tool to unify all this infrastructure: the [kworkflow](https://github.com/kworkflow/kworkflow).

Kworkflow is great. It unifies all tools for sending email, managing configs, debugging, and deploying. The Problem? It didn’t use to have support for Fedora.

As a defender of the Fedora ecosystem, I couldn’t let that go, I had a mission: bring support for Fedora to kw.

## Why use Fedora for development?

Ok, first of all, you need to understand my case of love for Fedora.

My first Linux distribution was [Pop_OS!](https://pop.system76.com). It was great until they made the update to Cosmic. And I hated Cosmic with all my guts. I felt cheated by System76 (and if you check Reddit, you gonna see that it wasn’t only me). My computer was now slow, crashing and I simply hated all those buttons. I missed my classic and simple GNOME and I couldn’t understand how a company could go so against its community.

So, I ended up changing it for Fedora 34. Yes, my first Fedora…

And it was simply perfect: simple and plain GNOME 40 and moreover, Fedora is a bleeding-edge distribution. Fedora is always on the rollout for the latest Linux features, driver updates, and software. It is very innovative: Fedora comes with Wayland and Pipewire out-of-the-box, for example. And, although it is very innovative, it is incredibly stable.

But, we didn’t solve up the problem of Red Hat simply making a disgusting change and the community simply hate it. In fact, we did! Fedora is incredibly democratic. The Fedora community is the most important part of the development of another version and any change is submitted to the community through a proposal.

And that’s why I love Fedora so much: stability, innovation, and a great community.

But, if none of that convinced you to move to Fedora, maybe Linus Torvalds does. It is a pretty known fact that the creator of Linux is a Fedora user.

## Implementing kw deploy for Fedora

Fedora is great, but… It didn’t use to have kw support. I couldn’t let that go. So, I started to work on the kw support for Fedora.

First of all, we needed to make it possible to install kw on a Fedora system with the `setup.sh` script. This was pretty simple after all: I just needed to add a package dependency list to the kw files and specify how to install those packages, so basically `dnf`.

To get the dependencies, I based myself on the Arch Linux dependency list. If you are willing to check more on this feature, check the [PR](https://github.com/kworkflow/kworkflow/pull/564).

So, now the biggest challenge for me: introduce kw deploy for Fedora.

The first step was to learn how to install a custom kernel in a Fedora distribution manually, how to generate the initramfs and what was the default bootloader and how to update it.

Fedora has great documentation, so I check out the guide [Building a Custom Kernel](https://asamalik.fedorapeople.org/tmp-docs-preview/quick-docs/kernel/build-custom-kernel/).

On Fedora, to build the kernel, you run:

```bash
make oldconfig
make bzImage
make modules
```

And them, to install the kernel, you run:

```bash
sudo make modules_install
sudo make install
```

But, there is a small detail: we don´t want simply to install the kernel on your local system, we want to deploy remotely.

So, we must generate the initramfs, and send it to the remote machine. The mechanism to send the modules and the initramfs was already coded on kw. So, I had only one task: find out how Fedora generates its initramfs.

I found out an [article](https://fedoramagazine.org/initramfs-dracut-and-the-dracut-emergency-shell/) from Fedora Magazine that explained how Fedora uses `dracut` to generate the initramfs. To generate the initramfs, it is as simple as running:

```bash
dracut --force --kver {KERNEL_NAME}
```

Next step, check out the default bootloader for Fedora. Fedora uses GRUB2, as is can be seen in this [article](https://docs.fedoraproject.org/en-US/quick-docs/bootloading-with-grub2/). So, it looked straightly simple for me as kw already had GRUB support.

But, all the GRUB support on kw was based on the `grub-mkconfig` command and Fedora comes with the `grub2-mkconfig` command. So, the first thing I had to work on was adding support to the `grub2-mkconfig` command on kw, as I found it unfair to simply install another GRUB package on the system of the kw user.

That said, I based myself on the Debian deployment script and wrote the Fedora deployment script with the specific Fedora tools: `dracut` and `dnf`.

But a new problem arrived: GRUB menu didn't seem to show up on my machine. And I found out that Fedora comes with GRUB hidden by default. To display GRUB, you must run:

```bash
grub2-editenv - unset menu_auto_hide
```

Ok, now GRUB showed up, but the newly compiled kernel didn't show up in the GRUB menu. So, I found out that Fedora comes with GRUB_ENABLE_BLSCFG set by default. It was pretty simple to fix this, simply run:

```bash
sed -i -e 's/GRUB_ENABLE_BLSCFG=true/GRUB_ENABLE_BLSCFG=false/g' /etc/default/grub
```

And that's it! Now, `kw d` worked like a charm with Fedora. I tested on my local machine with Fedora 35 and remotely with Fedora 35 and Fedora 36.

If you wanna check this feature out, take a look at this [PR](https://github.com/kworkflow/kworkflow/pull/613).

## My workflow with Fedora

As I said, I have two development laptops: a Lenovo IdeaPad and a Dell Inspiron 15. Lenovo is my less powerful notebook, so I basically always carry him in my backpack. And the Dell Inspiron is my precious baby: it is an Intel Core i7, with 16 GB DRAM and Nvidia graphics.

Moreover, I have a testing machine, with an AMD Radeon RX 5700 XT 50th Anniversary. This is where I run my kernel tests (especially, graphics tests) and run IGT GPU Tools.

The problem? Setup up a network with three machines without becoming a cable hell. That's why I use [Tailscale](https://tailscale.com) to connect all my machines through a network. It's a great tool for people with multiple machines.

Next step: make deployment easy and simple. Basically, I want to compile the Kernel on my Dell Inspiron 15 and deploy it to my testing machine through the network.

First thing: have a good config file.

I manage my config files through `kw configm` and I have three config files: `STD_DCN_CONFIG`, `KUNIT_CONFIG`, and `STD_CONFIG`.

The `STD_DCN_CONFIG` has enabled AMDGPU drivers and DCN stuff, with the addition of TCP configurations to make Tailscale work properly. Also, I use BTRFS as my Filesystem (as it comes out of the box with Fedora), so I also had to configure the FS.

The `KUNIT_CONFIG` is almost the same as `STD_DCN_CONFIG`, but with the addition of the `KUNIT` module. As I'm working in GSoC, this is my go-to config recently.

And the `STD_CONFIG` is the config that comes with Fedora. I don't use it that much. It's pretty loaded with modules and it takes too long to compile.

Ok, now it's time to compile it. kw has a great tool to build Linux images, `kw b`, but it doesn't support clang yet (but, [Isa](https://crosscat.me) is working on it). So, as I like to use the LLVM system and use ccache to speed up builds, I run:

```bash
make CC="ccache clang" -j8
```

Great! Now we have a `vmlinuz` image. But, we still need to deploy it. Now, kw really shines for me. I simply run `kw d` with reboot setup on my `kworkflow.config` and, that's it. I simply go to my deployment machine and choose a kernel to boot from.

It is incredibly simple, right?

## Next Steps

Hope I have inspired you to try out [Fedora 36](https://getfedora.org) and kw! These great tools will make your development simple and fast.

My next step with Fedora: **introduce kw to the dnf package manager.** But that's a talk to another post.
