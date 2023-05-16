---
title: "Rotating Planes on VKMS"
date: 2023-05-08
author: Maíra Canal
permalink: /rotating-planes-vkms/
tags: [igalia, kernel, graphics]
---

In my last blog post, I described a bit of my previous work on the `rustgem` project, and after that, as I had finished the VGEM features, I sent a [RFC](https://lore.kernel.org/dri-devel/20230317121213.93991-1-mcanal@igalia.com/T/) to the mailing list.
Although I still need to work on some `rustgem` feedback, I started to explore more of the KMS (Kernel Mode Setting) and its properties.

I talked to my mentor [Melissa Wen](https://melissawen.github.io/), one of the VKMS maintainers, and she proposed implementing plane rotation capabilities to VKMS.
The VKMS (Virtual Kernel Mode Setting) is a software-only KMS driver that is quite useful for testing and running X (or similar compositors) on headless machines.
It sounded like a great idea, as I would like to explore a bit more of the KMS side of things.

# What is Plane Rotation?
---
In order to have an image on a display, we need to go through the whole Kernel Mode Setting (KMS) Display Pipeline.
The pipeline has a couple of different objects, such as framebuffers, planes, and CRTCs, and the relationship between them can be quite complicated.
If you are interested in the KMS Display Pipeline, I recommend reading the great [KMS documentation](https://docs.kernel.org/gpu/drm-kms.html).
But here we are focused in only one of those abstractions, the plane.

In the context of graphics processing, a plane refers to an image source that can be superimposed or blended on top of a CRTC during the scanout process.
The plane itself specifies the cropping and scaling of that image, and where it is placed on the visible area of the CRTC.
Moreover, planes may possess additional attributes that dictate pixel positioning and blending, such as rotation or Z-positioning.

Rotation is an optional KMS property of the DRM plane object, which we use to specify the rotation amount in degrees in counter-clockwise direction.
The rotation is applied to the image sampled from the source rectangle, before scaling it to fit in the destination rectangle.
So, basically, the rotation property adds a rotation and a reflection step between the source and destination rectangles.

```
		|*********|$$$$$$$$$|              |$$$$$$$$$|@@@@@@@@@|
		|*********|$$$$$$$$$|  --------->  |$$$$$$$$$|@@@@@@@@@|
		|#########|@@@@@@@@@|     90º      |*********|#########|
		|#########|@@@@@@@@@|              |*********|#########|
```

The possible rotation values are `rotate-0`, `rotate-90`, `rotate-180`, `rotate-270`, `reflect-x` and `reflect-y`.

Now that we understand what plane rotation is, we can think about how to implement the rotation property on VKMS.

# Rotation on VKMS
---
VKMS has some really special driver attributes, as all its composition happens by software operations.
The rotation is usually an operation that is performed on the user-space, but the hardware can also perform it.
In order for the hardware to perform it, the driver will set some registers, change some configurations, and indicate to the hardware that the plane should be rotated.
This doesn't happen on VKMS, as the composition is essentially a software loop.
So, we need to modify this loop to perform the rotation.

First, we need a brief notion of how the composition happens in VKMS.
The composition in VKMS happens line-by-line.
Each line is represented by a staging buffer, which contains the composition for one plane, and an output buffer, which contains the composition of all planes in z-pos order.
For each line, we query an array by the first pixel of the line and go through the whole source array linearly, performing the proper pixel conversion.
The composition of the line can be summarized by:

```c
void vkms_compose_row(struct line_buffer *stage_buffer, struct vkms_plane_state *plane, int y)
{
	struct pixel_argb_u16 *out_pixels = stage_buffer->pixels;
	struct vkms_frame_info *frame_info = plane->frame_info;
	u8 *src_pixels = get_packed_src_addr(frame_info, y);
	int limit = min_t(size_t, drm_rect_width(&frame_info->dst), stage_buffer->n_pixels);

	for (size_t x = 0; x < limit; x++, src_pixels += frame_info->cpp)
		plane->pixel_read(src_pixels, &out_pixels[x]);
}
```

Here we can see that we have the line, represented by the stage buffer and the y coordinate, and the source pixels.
We read each source pixel in a linear manner, through the for-loop, and we place it on the stage buffer in the appropriate format.

With that in mind, we can think that rotating a plane is a matter of changing how we read and interpret the lines.
Let's think about the `reflect-x` operation.

```
		|*********|$$$$$$$$$|                |$$$$$$$$$|*********|
		|*********|$$$$$$$$$|  ----------->  |$$$$$$$$$|*********|
		|#########|@@@@@@@@@|   reflect-x    |@@@@@@@@@|#########|
		|#########|@@@@@@@@@|                |@@@@@@@@@|#########|
```

Thinking that the VKMS composition happens line-by-line, we can describe the operation as a read in reverse order.
So, instead of start reading the pixels from left to right, we need to start reading the pixels from right to left.
We can implement this by getting the limit of the line and subtracting the current `x` position:

```c
static int get_x_position(const struct vkms_frame_info *frame_info, int limit, int x)
{
	if (frame_info->rotation & DRM_MODE_REFLECT_X)
		return limit - x - 1;
	return x;
}
```

For the `reflect-y` operation, we need to start reading the plane from the last line, instead of reading it from the first line.

```
		|*********|$$$$$$$$$|                |#########|@@@@@@@@@|
		|*********|$$$$$$$$$|  ----------->  |#########|@@@@@@@@@|
		|#########|@@@@@@@@@|   reflect-y    |*********|$$$$$$$$$|
		|#########|@@@@@@@@@|                |*********|$$$$$$$$$|
```

This can be performed by changing the `y` on the external composition loop.
Similarly from the `reflect-x` case, we can get the `y` limit and subtract the current `y` position.

```c
static int get_y_pos(struct vkms_frame_info *frame_info, int y)
{
	if (frame_info->rotation & DRM_MODE_REFLECT_Y)
		return drm_rect_height(&frame_info->rotated) - y - 1;
	return y;
}
```

So, to implement the rotation in VKMS, we need to change how we interpret the boundaries of the plane and read accordingly.

This might seem odd because we could just rotate the `src` rectangle by using `drm_rect_rotate`, but this wouldn't work as the composition in VKMS is performed line-by-line and the pixels are accessed linearly.
However, `drm_rect_rotate` is of great help for us on the `rotate-90` and `rotate-270` cases.
Those cases demand scaling and `drm_rect_rotate` helps us tremendously with it.
Basically, what it does is:

```
		                                              |$$|@@|
		                                              |$$|@@|
		|*********|$$$$$$$$$|                         |$$|@@|
		|*********|$$$$$$$$$|  -------------------->  |$$|@@|
		|#########|@@@@@@@@@|   drm_rect_rotate(90)   |**|##|
		|#########|@@@@@@@@@|                         |**|##|
		                                              |**|##|
		                                              |**|##|
```

After the `drm_rect_rotate` operation, we need to read the columns as lines and the lines as columns.
See that even for a case like `rotate-90`, it is just a matter of changing the point of view and reading the lines differently.

---
The complete implementation of all rotation modes is available [here](https://patchwork.freedesktop.org/series/116189/).
Together with the rotation feature, I sent a patch to reduce the code repetition in the code by isolating the pixel conversion functionality.
This patch was already merged, but the rest of the series is still pending a Reviewed-by.

Rotating planes on VKMS was a fun challenge of my [Igalia Coding Experience](https://www.igalia.com/coding-experience/) and I hope to keep working on VKMS to bring more and more features.
