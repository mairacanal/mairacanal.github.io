---
title: "Introducing CPU jobs to the Raspberry Pi"
date: 2024-01-11T10:30:00-03:00
author: Maíra Canal
permalink: /introducing-cpu-jobs-to-the-rpi/
categories: [Tech]
tags: [igalia, graphics, embedded]
---

[Igalia](https://www.igalia.com) is always working hard to improve 3D rendering
drivers of the Broadcom VideoCore GPU, found in Raspberry Pi devices. One of our
most recent efforts in this sense was the implementation of CPU jobs from the
Vulkan driver to the V3D kernel driver.

## What are CPU jobs and why do we need them?

In the V3DV driver, there are some Vulkan commands that cannot be performed by
the GPU alone, so we implement those as CPU jobs on Mesa. A CPU job is a job
that requires CPU intervention to be performed. For example, in the Broadcom
VideoCore GPUs, we don't have a way to calculate the timestamp. But we need the
timestamp for Vulkan [timestamp
queries](https://docs.vulkan.org/samples/latest/samples/api/timestamp_queries/README.html).
Therefore, we need to calculate the timestamp on the CPU.

A CPU job in userspace also implies CPU stalling. Sometimes, we need to hold
part of the command submission flow in order to correctly synchronize their
execution. This waiting period caused the CPU to stall, thereby preventing the
continuous submission of jobs to the GPU. To mitigate this issue, we decided to
move CPU job mechanisms from the V3DV driver to the V3D kernel driver.

In the V3D kernel driver, we have different kinds of jobs: RENDER jobs, BIN
jobs, CSD jobs, TFU jobs, and CLEAN CACHE jobs. For each of those jobs, we have
a DRM scheduler instance that helps us to synchronize the jobs.

> If you want to know more about the different kinds of V3D jobs, check out this
> [November Update: Exploring
> V3D](https://mairacanal.github.io/november-update-exploring-v3d/) blogpost,
> where I explain more about all the V3D
> [IOCTLs](https://en.wikipedia.org/wiki/Ioctl) and jobs.

Jobs of the same kind are submitted, dispatched, and processed in the same order
they are executed, using a standard first-in-first-out (FIFO) queue system. We
can synchronize different jobs across different queues using DRM syncobjs. More
about the V3D synchronization framework and user extensions can be learned in
[this two-part blog
post](https://melissawen.github.io/blog/2022/05/10/multisync-p1) from Melissa
Wen.

> From the kernel documentation, a DRM syncobj (synchronisation objects) are
> containers for stuff that helps sync up GPU commands. They're super handy
> because you can use them in your own programs, share them with other programs,
> and even use them across different DRM drivers. Mostly, they're used for
> making Vulkan fences and semaphores work.

By moving the CPU job from userspace to the kernel, we can make use of the DRM
schedule queues and all the advantages it brings with it. For this, we created a
new type of job in the V3D kernel driver, a CPU job, which also means creating a
new DRM scheduler instance and a CPU job queue. Now, instead of stalling the
submission thread waiting for the GPU to idle, we can use DRM syncobjs to
synchronize both CPU and GPU jobs in a submission, providing more efficient
usage of the GPU.

## How did we implement the CPU jobs in the kernel driver?

After we decided to have a CPU job implementation in the kernel space, we could
think about two possible implementations for this job: creating an IOCTL for
each type of CPU job or using a user extension to provide a polymorphic behavior
to a single CPU job IOCTL.

We have different types of CPU jobs (indirect CSD jobs, timestamp query jobs,
copy query results jobs...) and each of them has a common infrastructure
of allocation and synchronization but performs different operations. Therefore,
we decided to go with the option to use user extensions.

On [Melissa's blogpost](https://melissawen.github.io/blog/2022/05/10/multisync-p1), she digs
deep into the implementation of generic IOCTL extensions in the V3D kernel
driver. But, to put it simply, instead of expanding the data struct for each
IOCTL every time we need to add a new feature, we define a user extension chain
instead. As we add new optional interfaces to control the IOCTL, we define a new
extension struct that can be linked to the IOCTL data only when required by the
user.

Therefore, we created a new IOCTL, `drm_v3d_submit_cpu`, which is used to submit
any type of CPU job. This single IOCTL can be extended by a user extension,
which allows us to reuse the common infrastructure - avoiding code
repetition - and yet use the user extension ID to identify the type of job
and depending on the type of job, perform a certain operation.

```c
struct drm_v3d_submit_cpu {
        /* Pointer to a u32 array of the BOs that are referenced by the job.
         *
         * For DRM_V3D_EXT_ID_CPU_INDIRECT_CSD, it must contain only one BO,
         * that contains the workgroup counts.
         *
         * For DRM_V3D_EXT_ID_TIMESTAMP_QUERY, it must contain only one BO,
         * that will contain the timestamp.
         *
         * For DRM_V3D_EXT_ID_CPU_RESET_TIMESTAMP_QUERY, it must contain only
         * one BO, that contains the timestamp.
         *
         * For DRM_V3D_EXT_ID_CPU_COPY_TIMESTAMP_QUERY, it must contain two
         * BOs. The first is the BO where the timestamp queries will be written
         * to. The second is the BO that contains the timestamp.
         *
         * For DRM_V3D_EXT_ID_CPU_RESET_PERFORMANCE_QUERY, it must contain no
         * BOs.
         *
         * For DRM_V3D_EXT_ID_CPU_COPY_PERFORMANCE_QUERY, it must contain one
         * BO, where the performance queries will be written.
         */
        __u64 bo_handles;

        /* Number of BO handles passed in (size is that times 4). */
        __u32 bo_handle_count;

        __u32 flags;

        /* Pointer to an array of ioctl extensions*/
        __u64 extensions;
};
```

Now, we can create a CPU job and submit it with a CPU job user extension.

And which extensions are available?

1. [`DRM_V3D_EXT_ID_CPU_INDIRECT_CSD`](https://cgit.freedesktop.org/drm/drm-misc/commit/?id=18b8413b25b7070fa2e55858a2c808e6909581d0):
this CPU job allows us to submit an indirect CSD job. An indirect CSD job is a
job that, when executed in the queue, will map an indirect buffer, read the
dispatch parameters, and submit a regular dispatch. This CPU job is used in
Vulkan calls like `vkCmdDispatchIndirect()`.
2. [`DRM_V3D_EXT_ID_CPU_TIMESTAMP_QUERY`](https://cgit.freedesktop.org/drm/drm-misc/commit/?id=9ba0ff3e083f6a4a0b6698f06bfff74805fefa5f):
this CPU job calculates the query timestamp and updates the query availability
by signaling a syncobj. This CPU job is used in Vulkan calls like `vkCmdWriteTimestamp()`.
3. [`DRM_V3D_EXT_ID_CPU_RESET_TIMESTAMP_QUERY`](https://cgit.freedesktop.org/drm/drm-misc/commit/?id=34a101e64296c736b14ce27e647fcebd70cb7bf8):
this CPU job resets the timestamp queries based on the value offset of the first
query. This CPU job is used in Vulkan calls like `vkCmdResetQueryPool()` for timestamp queries.
4. [`DRM_V3D_EXT_ID_CPU_COPY_TIMESTAMP_QUERY`](https://cgit.freedesktop.org/drm/drm-misc/commit/?id=6745f3e44a20ac18e7e5a40a3c7f62225983d544):
this CPU job copies the complete or partial result of a query to a buffer.
This CPU job is used in Vulkan calls like `vkCmdCopyQueryPoolResults()` for timestamp queries.
5. [`DRM_V3D_EXT_ID_CPU_RESET_PERFORMANCE_QUERY`](https://cgit.freedesktop.org/drm/drm-misc/commit/?id=bae7cb5d68001a8d4ceec5964dda74bb9aab7220):
this CPU job resets the performance queries by resetting the values of the
perfmons. This CPU job is used in Vulkan calls like `vkCmdResetQueryPool()` for performance queries.
6. [`DRM_V3D_EXT_ID_CPU_COPY_PERFORMANCE_QUERY`](https://cgit.freedesktop.org/drm/drm-misc/commit/?id=209e8d2695ee7a67a5b0487bbd1aa75e290d0f41):
similar to `DRM_V3D_EXT_ID_CPU_COPY_TIMESTAMP_QUERY`, this CPU job copies the
complete or partial result of a query to a buffer. This CPU job is used in Vulkan
calls like `vkCmdCopyQueryPoolResults()` for performance queries.

The CPU job IOCTL structure is similar to any other V3D job. We allocate the job
struct, parse all the extensions, init the job, look up the BOs and lock its
reservations, add the proper dependencies, and push the job to the DRM scheduler
entity.

When running a CPU job, we execute the following code:

```c
static const v3d_cpu_job_fn cpu_job_function[] = {
        [V3D_CPU_JOB_TYPE_INDIRECT_CSD] = v3d_rewrite_csd_job_wg_counts_from_indirect,
        [V3D_CPU_JOB_TYPE_TIMESTAMP_QUERY] = v3d_timestamp_query,
        [V3D_CPU_JOB_TYPE_RESET_TIMESTAMP_QUERY] = v3d_reset_timestamp_queries,
        [V3D_CPU_JOB_TYPE_COPY_TIMESTAMP_QUERY] = v3d_copy_query_results,
        [V3D_CPU_JOB_TYPE_RESET_PERFORMANCE_QUERY] = v3d_reset_performance_queries,
        [V3D_CPU_JOB_TYPE_COPY_PERFORMANCE_QUERY] = v3d_copy_performance_query,
};

static struct dma_fence *
v3d_cpu_job_run(struct drm_sched_job *sched_job)
{
        struct v3d_cpu_job *job = to_cpu_job(sched_job);
        struct v3d_dev *v3d = job->base.v3d;

        v3d->cpu_job = job;

        if (job->job_type >= ARRAY_SIZE(cpu_job_function)) {
                DRM_DEBUG_DRIVER("Unknown CPU job: %d\n", job->job_type);
                return NULL;
        }

        trace_v3d_cpu_job_begin(&v3d->drm, job->job_type);

        cpu_job_function[job->job_type](job);

        trace_v3d_cpu_job_end(&v3d->drm, job->job_type);

        return NULL;
}
```

The interesting thing is that each CPU job type executes a completely different operation.

The complete kernel implementation has already landed in drm-misc-next and can
be seen right
[here](https://lore.kernel.org/dri-devel/20231130164420.932823-2-mcanal@igalia.com/T/).

## What did we change in Mesa-V3DV to use the new kernel-V3D CPU job?

After landing the kernel implementation, I needed to accommodate the new CPU job
approach in the userspace.

A fundamental rule is not to cause regressions, i.e., to keep backwards
userspace compatibility with old versions of the Linux kernel. This means we
cannot break new versions of Mesa running in old kernels. Therefore, we needed
to create two paths: one preserving the old way to perform CPU jobs and the
other using the kernel to perform CPU jobs.

So, for example, the indirect CSD job used to add two different jobs to the
queue: a CPU job and a CSD job. Now, if we have the CPU job capability in the
kernel, we only add a CPU job and the CSD job is dispatched from within the
kernel.

```diff
-   list_addtail(&csd_job->list_link, &cmd_buffer->jobs);
+
+   /* If we have a CPU queue we submit the CPU job directly to the
+    * queue and the CSD job will be dispatched from within the kernel
+    * queue, otherwise we will have to dispatch the CSD job manually
+    * right after the CPU job by adding it to the list of jobs in the
+    * command buffer.
+    */
+   if (!cmd_buffer->device->pdevice->caps.cpu_queue)
+      list_addtail(&csd_job->list_link, &cmd_buffer->jobs);
```

Furthermore, now we can use syncobjs to sync the CPU jobs. For example, in the
timestamp query CPU job, we used to stall the submission thread and wait for
completion of all work queued before the timestamp query. Now, we can just add a
barrier to the CPU job and it will be properly synchronized by the syncobjs
without stalling the submission thread.

```c
   /* The CPU job should be serialized so it only executes after all previously
    * submitted work has completed
    */
   job->serialize = V3DV_BARRIER_ALL;
```

We were able to test the implementation using multiple CTS tests, such as
`dEQP-VK.compute.pipeline.indirect_dispatch.*`,
`dEQP-VK.pipeline.monolithic.timestamp.*`, `dEQP-VK.synchronization.*`,
`dEQP-VK.query_pool.*` and `dEQP-VK.multiview.*`.

The userspace implementation has already landed in Mesa and the full
implementation can be checked in this
[MR](https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/26448).

---

More about the on-going challenges in the Raspberry Pi driver stack can be
checked during this [XDC 2023 talk](https://www.youtube.com/watch?v=Gk49xj4jds4)
presented by Iago Toral, Juan Suárez and myself. During this talk, Iago
mentioned the CPU job work that we have been doing.

Also I cannot finish this post without thanking [Melissa
Wen](https://melissawen.github.io/) and [Iago
Toral](https://blogs.igalia.com/itoral/author/itoral/) for all the help while
developing the CPU jobs for the V3D kernel driver.

