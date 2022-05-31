---
title: "Getting Started at the Linux Kernel"
date: 2022-03-28T00:00:00+00:00
author: Maíra Canal
layout: post
permalink: /getting-started/
categories: Genel
tags: [linux, kernel]
---

I started my journey with the Linux Kernel in October 2021. At that time, I thought it was impossible for a 19-year-old Brazilian girl to have an approved commit at the kernel. Then, I find out about an extracurricular group at Campinas, LKCAMP. And I found out that undergraduate students were able to contribute to the kernel. Although I couldn´t go to the LKCAMP meetings, this really push me forward, cause I saw that I was able to be a part of the kernel community.

I was a Linux user for about two years, and I became passionate about the system. I was eager to contribute to the community and improve the kernel. But, I was in doubt about where to start. 

So, I started to fly solo and explore all the kernel TODO lists. I didn't really get many of the tasks on the lists, but one, in particular, attracted me: the DRM TODO list. This list has been categorized into different levels: from starter to expert. I picked up a starter task:

**Replace all drm_lock boilerplates for DRM_MODESET_LOCK_ALL_* helpers**

With a lot of git grep, I found a drm_lock boilerplate and code my first Linux Kernel patch. It was small, but it was my first patch and I was extremely excited.

```
As requested in GPU Driver Developers Guide TODO list, replaces all
drm_lock boilerplates for DRM_MODESET_LOCK_ALL_* helpers.

Signed-off-by: Maíra Canal <maira.canal@usp.br>
---
 drivers/gpu/drm/i915/display/intel_display.c | 13 ++-----------
 1 file changed, 2 insertions(+), 11 deletions(-)

diff --git a/drivers/gpu/drm/i915/display/intel_display.c b/drivers/gpu/drm/i915/display/intel_display.c
index 17f44ffea586..71b7ff7b7dea 100644
--- a/drivers/gpu/drm/i915/display/intel_display.c
+++ b/drivers/gpu/drm/i915/display/intel_display.c
@@ -13466,22 +13466,13 @@ void intel_display_resume(struct drm_device *dev)
	if (state)
		state->acquire_ctx = &ctx;
 
-	drm_modeset_acquire_init(&ctx, 0);
-
-	while (1) {
-		ret = drm_modeset_lock_all_ctx(dev, &ctx);
-		if (ret != -EDEADLK)
-			break;
-
-		drm_modeset_backoff(&ctx);
-	}
+	DRM_MODESET_LOCK_ALL_BEGIN(dev, ctx, 0, ret);
 
	if (!ret)
		ret = __intel_display_resume(dev, state, &ctx);
 
	intel_enable_ipc(dev_priv);
-	drm_modeset_drop_locks(&ctx);
-	drm_modeset_acquire_fini(&ctx);
+	DRM_MODESET_LOCK_ALL_END(dev, ctx, ret);
 
	if (ret)
		drm_err(&dev_priv->drm,
```

But my next challenge was to find out how to send my patch. 

I was used to the Pull Request scheme of contribution and didn't really get which mailing list should I send my patch to. After some research, this [tutoral](https://medium.com/@cristianzsh/submitting-your-first-patch-to-the-linux-kernel-e81d2541fac6) introduce me to the `checkpatch.sh` and `get_maintainer.sh` scripts. 

So, I finally send my first patch to the Linux Kernel... And it was **denied**. Another contributor sent the patch ahead of me. It happens...

## Second patch: here we go again

But, I didn't give up on my first denied patch. I tried to send a patch to the power domain system, replacing dev_err() for dev_err_probe() to reduce code size and uniform error handling. But, in my second patch, I didn't really see that the dev_err_probe() should only be used inside the probe function of a driver. So, Greg KH pointed that out and **denied my second patch**.

## Third patch: about to give up

I mean, at that point, I was really thinking of giving up. But I remember something I learned during my undergraduate research: the kernel is currently changing the GPIO interface from GPIO numberspace to GPIO descriptor. I read the TODO list from the GPIO subsystem and found out that one of the work items is: *Convert all consumer drivers to only #include <linux/gpio/consumer.h>*.

This was gold to me! I had experience with the GPIO descriptor consumer interface during my undergraduate research, so converting drivers was an easy task for me.

So, I git grep `#include <linux/of_gpio.h>` and choose the `media/i2c/s5c73m3/s5c73m3-core.c` driver to convert. I send my patch and... Nothing. Really, nobody answered me for more than a month. And was anxious to have an approved patch.

## Fourth patch: my first approved patch

So, I picked up the `regulator/lp872x.c` driver and converted also. Then, on my fourth try, **my patch was finally approved**. Mark Brown approved my patch and applied. My patch was merged to the mainstream in Linux v5.17.

```
Removing all linux/gpio.h and linux/of_gpio.h dependencies and replacing
them with the gpiod interface

Signed-off-by: Maíra Canal <maira.canal@usp.br>
---
drivers/regulator/lp872x.c       | 38 +++++++++++++-------------------
include/linux/regulator/lp872x.h | 14 ++++++------
2 files changed, 22 insertions(+), 30 deletions(-)

diff --git a/drivers/regulator/lp872x.c b/drivers/regulator/lp872x.c
index e84be29533f4..1dba5dbcd461 100644
--- a/drivers/regulator/lp872x.c
+++ b/drivers/regulator/lp872x.c
@@ -10,13 +10,12 @@
#include <linux/i2c.h>
#include <linux/regmap.h>
#include <linux/err.h>
-#include <linux/gpio.h>
+#include <linux/gpio/consumer.h>
#include <linux/delay.h>
#include <linux/regulator/lp872x.h>
#include <linux/regulator/driver.h>
#include <linux/platform_device.h>
#include <linux/of.h>
-#include <linux/of_gpio.h>
#include <linux/regulator/of_regulator.h>

/* Registers : LP8720/8725 shared */
@@ -250,12 +249,12 @@ static int lp872x_regulator_enable_time(struct regulator_dev *rdev)
}

static void lp872x_set_dvs(struct lp872x *lp, enum lp872x_dvs_sel dvs_sel,
-			int gpio)
+			struct gpio_desc *gpio)
{
	enum lp872x_dvs_state state;

	state = dvs_sel == SEL_V1 ? DVS_HIGH : DVS_LOW;
-	gpio_set_value(gpio, state);
+	gpiod_set_value(gpio, state);
	lp->dvs_pin = state;
}

@@ -321,7 +320,7 @@ static int lp872x_buck_set_voltage_sel(struct regulator_dev *rdev,
	u8 addr, mask = LP872X_VOUT_M;
	struct lp872x_dvs *dvs = lp->pdata ? lp->pdata->dvs : NULL;

-	if (dvs && gpio_is_valid(dvs->gpio))
+	if (dvs && dvs->gpio)
		lp872x_set_dvs(lp, dvs->vsel, dvs->gpio);

	addr = lp872x_select_buck_vout_addr(lp, buck);
@@ -675,7 +674,6 @@ static const struct regulator_desc lp8725_regulator_desc[] = {

static int lp872x_init_dvs(struct lp872x *lp)
{
-	int ret, gpio;
	struct lp872x_dvs *dvs = lp->pdata ? lp->pdata->dvs : NULL;
	enum lp872x_dvs_state pinstate;
	u8 mask[] = { LP8720_EXT_DVS_M, LP8725_DVS1_M | LP8725_DVS2_M };
@@ -684,15 +682,15 @@ static int lp872x_init_dvs(struct lp872x *lp)
	if (!dvs)
		goto set_default_dvs_mode;

-	gpio = dvs->gpio;
-	if (!gpio_is_valid(gpio))
+	if (!dvs->gpio)
		goto set_default_dvs_mode;

	pinstate = dvs->init_state;
-	ret = devm_gpio_request_one(lp->dev, gpio, pinstate, "LP872X DVS");
-	if (ret) {
-		dev_err(lp->dev, "gpio request err: %d\n", ret);
-		return ret;
+	dvs->gpio = devm_gpiod_get_optional(lp->dev, "ti,dvs", pinstate);
+
+	if (IS_ERR(dvs->gpio)) {
+		dev_err(lp->dev, "gpio request err: %ld\n", PTR_ERR(dvs->gpio));
+		return PTR_ERR(dvs->gpio);
	}

	lp->dvs_pin = pinstate;
@@ -706,20 +704,17 @@ static int lp872x_init_dvs(struct lp872x *lp)

static int lp872x_hw_enable(struct lp872x *lp)
{
-	int ret, gpio;
-
	if (!lp->pdata)
		return -EINVAL;

-	gpio = lp->pdata->enable_gpio;
-	if (!gpio_is_valid(gpio))
+	if (!lp->pdata->enable_gpio)
		return 0;

	/* Always set enable GPIO high. */
-	ret = devm_gpio_request_one(lp->dev, gpio, GPIOF_OUT_INIT_HIGH, "LP872X EN");
-	if (ret) {
-		dev_err(lp->dev, "gpio request err: %d\n", ret);
-		return ret;
+	lp->pdata->enable_gpio = devm_gpiod_get_optional(lp->dev, "enable", GPIOD_OUT_HIGH);
+	if (IS_ERR(lp->pdata->enable_gpio)) {
+		dev_err(lp->dev, "gpio request err: %ld\n", PTR_ERR(lp->pdata->enable_gpio));
+		return PTR_ERR(lp->pdata->enable_gpio);
	}

	/* Each chip has a different enable delay. */
@@ -844,13 +839,10 @@ static struct lp872x_platform_data
	if (!pdata->dvs)
		return ERR_PTR(-ENOMEM);

-	pdata->dvs->gpio = of_get_named_gpio(np, "ti,dvs-gpio", 0);
	of_property_read_u8(np, "ti,dvs-vsel", (u8 *)&pdata->dvs->vsel);
	of_property_read_u8(np, "ti,dvs-state", &dvs_state);
	pdata->dvs->init_state = dvs_state ? DVS_HIGH : DVS_LOW;

-	pdata->enable_gpio = of_get_named_gpio(np, "enable-gpios", 0);
-
	if (of_get_child_count(np) == 0)
		goto out;

diff --git a/include/linux/regulator/lp872x.h b/include/linux/regulator/lp872x.h
index d780dbb8b423..8e7e0343c6e1 100644
--- a/include/linux/regulator/lp872x.h
+++ b/include/linux/regulator/lp872x.h
@@ -10,7 +10,7 @@

#include <linux/regulator/machine.h>
#include <linux/platform_device.h>
-#include <linux/gpio.h>
+#include <linux/gpio/consumer.h>

#define LP872X_MAX_REGULATORS		9

@@ -41,8 +41,8 @@ enum lp872x_regulator_id {
};

enum lp872x_dvs_state {
-	DVS_LOW  = GPIOF_OUT_INIT_LOW,
-	DVS_HIGH = GPIOF_OUT_INIT_HIGH,
+	DVS_LOW  = GPIOD_OUT_LOW,
+	DVS_HIGH = GPIOD_OUT_HIGH,
};

enum lp872x_dvs_sel {
@@ -52,12 +52,12 @@ enum lp872x_dvs_sel {

/**
* lp872x_dvs
- * @gpio       : gpio pin number for dvs control
+ * @gpio       : gpio descriptor for dvs control
* @vsel       : dvs selector for buck v1 or buck v2 register
* @init_state : initial dvs pin state
*/
struct lp872x_dvs {
-	int gpio;
+	struct gpio_desc *gpio;
	enum lp872x_dvs_sel vsel;
	enum lp872x_dvs_state init_state;
};
@@ -78,14 +78,14 @@ struct lp872x_regulator_data {
* @update_config     : if LP872X_GENERAL_CFG register is updated, set true
* @regulator_data    : platform regulator id and init data
* @dvs               : dvs data for buck voltage control
- * @enable_gpio       : gpio pin number for enable control
+ * @enable_gpio       : gpio descriptor for enable control
*/
struct lp872x_platform_data {
	u8 general_config;
	bool update_config;
	struct lp872x_regulator_data regulator_data[LP872X_MAX_REGULATORS];
	struct lp872x_dvs *dvs;
-	int enable_gpio;
+	struct gpio_desc *enable_gpio;
};

#endif
```

Really recommend to any kernel newbie to start contributing to any subsystem maintained by Mark Brown. He is really helpful and very responsive. 

So, this was my path to my first approved patch on the kernel. Since then, I had more than 10 patches approved in different kernel subsystems. Currently, I'm thinking of establishing myself in a subsystem, the DRM, so that I can learn more deeply about a subsystem.
