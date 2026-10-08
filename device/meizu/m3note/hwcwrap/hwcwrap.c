#define LOG_TAG "hwcomposer.m3note"

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/system_properties.h>
#include <unistd.h>

#include <hardware/hardware.h>
#include <hardware/hwcomposer.h>
#include <log/log.h>

#if defined(__LP64__)
#define REAL_HWC "/vendor/lib64/hw/hwcomposer.mt6755.so"
#else
#define REAL_HWC "/vendor/lib/hw/hwcomposer.mt6755.so"
#endif
#define FB_DEV "/dev/graphics/fb0"

static int (*real_set_power_mode)(struct hwc_composer_device_1 *dev, int disp, int mode);
static int (*real_blank)(struct hwc_composer_device_1 *dev, int disp, int blank);

static int blank_enabled(void)
{
    char value[PROP_VALUE_MAX] = "";

    __system_property_get("persist.vendor.m3note.hwc_blank", value);
    return strcmp(value, "0") != 0;
}

static int fb_ioctl_blank(int fd, int blank)
{
    if (ioctl(fd, FBIOBLANK, blank ? FB_BLANK_POWERDOWN : FB_BLANK_UNBLANK) == 0) {
        ALOGI("FBIOBLANK %s", blank ? "POWERDOWN" : "UNBLANK");
        return 0;
    }
    ALOGE("FBIOBLANK %s: %s", blank ? "POWERDOWN" : "UNBLANK", strerror(errno));
    return -1;
}

static void fb_blank(int blank)
{
    int fd;

    if (!blank_enabled())
        return;
    fd = open(FB_DEV, O_RDWR | O_CLOEXEC);
    if (fd < 0) {
        ALOGE("open %s: %s (behaving like the blob)", FB_DEV, strerror(errno));
        return;
    }
    /* A failed UNBLANK risks a black screen: retry once. */
    if (fb_ioctl_blank(fd, blank) < 0 && !blank) {
        usleep(20000);
        fb_ioctl_blank(fd, blank);
    }
    close(fd);
}

static int wrap_set_power_mode(struct hwc_composer_device_1 *dev, int disp, int mode)
{
    int ret;

    if (disp != HWC_DISPLAY_PRIMARY)
        return real_set_power_mode(dev, disp, mode);
    if (mode == HWC_POWER_MODE_OFF) {
        ret = real_set_power_mode(dev, disp, mode);
        fb_blank(1);
        return ret;
    }
    fb_blank(0);
    return real_set_power_mode(dev, disp, mode);
}

static int wrap_blank(struct hwc_composer_device_1 *dev, int disp, int blank)
{
    int ret;

    if (disp != HWC_DISPLAY_PRIMARY)
        return real_blank(dev, disp, blank);
    if (blank) {
        ret = real_blank(dev, disp, blank);
        fb_blank(1);
        return ret;
    }
    fb_blank(0);
    return real_blank(dev, disp, blank);
}

static int wrap_open(const struct hw_module_t *module, const char *name, struct hw_device_t **device)
{
    void *handle;
    struct hw_module_t *real;
    struct hwc_composer_device_1 *dev;
    int ret;

    (void) module;
    handle = dlopen(REAL_HWC, RTLD_NOW);
    if (!handle) {
        ALOGE("dlopen %s: %s", REAL_HWC, dlerror());
        return -ENOENT;
    }
    real = (struct hw_module_t *) dlsym(handle, HAL_MODULE_INFO_SYM_AS_STR);
    if (!real || !real->methods || !real->methods->open) {
        ALOGE("%s: no %s", REAL_HWC, HAL_MODULE_INFO_SYM_AS_STR);
        return -EINVAL;
    }
    ret = real->methods->open(real, name, device);
    if (ret || !*device || strcmp(name, HWC_HARDWARE_COMPOSER))
        return ret;

    dev = (struct hwc_composer_device_1 *) *device;
    if (dev->common.version >= HWC_DEVICE_API_VERSION_1_4 && dev->setPowerMode) {
        real_set_power_mode = dev->setPowerMode;
        dev->setPowerMode = wrap_set_power_mode;
        ALOGI("wrapped setPowerMode of %s (HWC %x)", REAL_HWC, dev->common.version);
    } else if (dev->blank) {
        real_blank = dev->blank;
        dev->blank = wrap_blank;
        ALOGI("wrapped blank of %s (HWC %x)", REAL_HWC, dev->common.version);
    }
    return 0;
}

static struct hw_module_methods_t wrap_methods = {
    .open = wrap_open,
};

hwc_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = HWC_MODULE_API_VERSION_0_1,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = HWC_HARDWARE_MODULE_ID,
        .name = "M3 Note HWC wrapper (FBIOBLANK on power off)",
        .author = "m3note",
        .methods = &wrap_methods,
    },
};
