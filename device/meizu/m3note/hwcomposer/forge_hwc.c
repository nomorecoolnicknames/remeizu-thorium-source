/*
 * forge_hwc — hwcomposer.forge for the Meizu m681 (M3 Note, MT6755) on the
 * forge 4.9 kernel.  Port of the m5c forge_hwc (device_m5c_treble cf47bbc,
 * forge_hwc.c b32eaef5…); the engine and the HWC1 facade are the m5c code,
 * only the display ABI below differs.  The m5c tear-hunt probes (forge-crc,
 * forge-shear, debug.forgehwc.acqdelay) are left out: they answered an m5c
 * question and stay available in the m5c tree.
 *
 * HWC1 (HWC_DEVICE_API_VERSION_1_1) facade over the mt6755 mtk_disp_mgr
 * session ABI.  The Flyme-era hwcomposer.mt6755 blob does not get a frame
 * out on A13 (FACT, A13v run 2026-09-29: "[DEV] Failed to config M4U
 * port(0)", then "getPrivateHandleInfo err(fffffff9)" on every frame).
 *
 *   prepare(): every layer -> HWC_FRAMEBUFFER by default (SurfaceFlinger
 *              composes everything with GLES into the framebuffer target);
 *              overlays only with debug.forgehwc.overlays=1.
 *   set():     wait the acquire fences here (the legacy frame layout has no
 *              src_fence_fd, the kernel forces it to -1)
 *              -> PREPARE_INPUT_BUFFER(204)  ion_fd -> buff idx + release fence
 *              -> GET_PRESENT_FENCE(216)     -> retire fence + idx
 *              -> FRAME_CONFIG(220)          input layers + present idx + trigger
 *   vsync:     dedicated thread blocking in WAIT_FOR_VSYNC(213).
 *   blank():   FBIOBLANK on fb0 (mtkfb_blank -> primary_display_suspend/resume).
 *
 * Where the mt6755 driver differs from the m5c one (FACT, kernel-mt6755-49
 * 91e69fe3c, drivers/misc/mediatek/video/mt6755):
 *   - SET_INPUT_BUFFER and TRIGGER_SESSION are refused for the PRIMARY
 *     session ("legecy API are not supported!", videox/mtk_disp_mgr.c
 *     __set_input / __trigger_display, -EINVAL).  A primary frame goes out
 *     only through FRAME_CONFIG, which configures the inputs AND triggers
 *     (_ioctl_frame_config -> primary_display_frame_cfg).
 *   - FRAME_CONFIG is DISP_IOW(220, struct disp_session_output_config), but
 *     the handler copies a whole frame struct, in the layout chosen by the
 *     kernel knob forge_frame_cfg_legacy (default 1 = the blob-era layout of
 *     struct disp_frame_cfg_t_legacy, mtk_disp_mgr.c:1400-1450).  This module
 *     reads the knob from sysfs and sends whichever layout the kernel parses.
 *   - The driver compiles against mt6755/include/disp_session.h (8 input
 *     slots, `user` in every struct, u16 geometry, GET_PRESENT_FENCE = 216),
 *     not video/include/disp_session.h; disp_session_uapi.h is a byte copy
 *     of the former (sha256 0205e375…).
 *
 * Buffer handles: ion fd and stride are queried through the vendor
 * libgralloc_extra.so (dlopen, plain C symbol, present in /vendor/lib{,64}).
 * Fallback when unavailable: fd = handle->data[0], stride = dma-buf size /
 * (rows * Bpp) when that lands within 64 px of the width, else the width.
 */

#define LOG_TAG "forge-hwc"

#include <errno.h>
#include <fcntl.h>
#include <stdbool.h>	/* disp_session_uapi.h (kernel copy) uses bool */
#include <malloc.h>
#include <poll.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <dlfcn.h>
#include <sys/ioctl.h>
#include <sys/system_properties.h>
#include <linux/fb.h>

#include <hardware/hardware.h>
#include <hardware/hwcomposer.h>

#include "disp_session_uapi.h"

/* liblog, declared by hand so the module links against libc+liblog+libdl only */
int __android_log_print(int prio, const char *tag, const char *fmt, ...);
#define FLOGI(...) __android_log_print(4 /* INFO */, LOG_TAG, __VA_ARGS__)
#define FLOGW(...) __android_log_print(5 /* WARN */, LOG_TAG, __VA_ARGS__)
#define FLOGE(...) __android_log_print(6 /* ERROR */, LOG_TAG, __VA_ARGS__)

#define DISP_DEV_PATH "/dev/mtk_disp_mgr"
#define FB_DEV_PATH "/dev/graphics/fb0"
#define FRAME_CFG_KNOB "/sys/module/mtk_disp_mgr/parameters/forge_frame_cfg_legacy"

/*
 * Blob-era FRAME_CONFIG payload, copied field for field from the kernel
 * (kernel-mt6755-49 91e69fe3c, videox/mtk_disp_mgr.c:1400-1450,
 * struct disp_input_config_legacy / struct disp_frame_cfg_t_legacy): u32
 * geometry, no fence/dirty-roi tail, `user` LAST.  The kernel translates it
 * with forge_frame_cfg_from_legacy() while forge_frame_cfg_legacy=1.
 */
struct fhwc_input_cfg_legacy {
	unsigned int layer_id;
	unsigned int layer_enable;
	enum DISP_BUFFER_SOURCE buffer_source;
	void *src_base_addr;
	void *src_phy_addr;
	unsigned int src_direct_link;
	enum DISP_FORMAT src_fmt;
	unsigned int src_use_color_key;
	unsigned int src_color_key;
	unsigned int src_pitch;
	unsigned int src_offset_x, src_offset_y;
	unsigned int src_width, src_height;
	unsigned int tgt_offset_x, tgt_offset_y;
	unsigned int tgt_width, tgt_height;
	enum DISP_ORIENTATION layer_rotation;
	enum DISP_LAYER_TYPE layer_type;
	enum DISP_ORIENTATION video_rotation;
	unsigned int isTdshp;
	unsigned int next_buff_idx;
	int identity;
	int connected_type;
	enum DISP_BUFFER_TYPE security;
	unsigned int alpha_enable;
	unsigned int alpha;
	unsigned int sur_aen;
	enum DISP_ALPHA_TYPE src_alpha;
	enum DISP_ALPHA_TYPE dst_alpha;
	unsigned int frm_sequence;
	enum DISP_YUV_RANGE_ENUM yuv_range;
};

struct fhwc_frame_cfg_legacy {
	enum DISP_SESSION_USER setter;
	unsigned int session_id;

	unsigned int input_layer_num;
	struct fhwc_input_cfg_legacy input_cfg[8];
	unsigned int overlap_layer_num;

	unsigned int const_layer_num;
	struct fhwc_input_cfg_legacy const_layer[1];

	int output_en;
	struct disp_output_config output_cfg;

	enum DISP_MODE mode;
	unsigned int present_fence_idx;
	enum EXTD_TRIGGER_MODE tigger_mode;
	enum DISP_SESSION_USER user;
};

#ifdef __LP64__
/* per-layer stride: 144 bytes blob-era vs 160 current (kernel comment above
 * struct disp_input_config_legacy) — a mismatch means a wrong header copy */
_Static_assert(sizeof(struct fhwc_input_cfg_legacy) == 144, "legacy input cfg");
_Static_assert(sizeof(struct disp_input_config) == 160, "mt6755 input cfg");
#endif

/* gralloc_extra_query attribute ids (device/meizu/m5c/libgem/inc/gralloc_extra.h) */
#define GE_GET_ION_FD 1
#define GE_GET_WIDTH 10
#define GE_GET_HEIGHT 11
#define GE_GET_STRIDE 12
#define GE_GET_FORMAT 15

/* Startup loader evidence retained for dump(), independent of log rotation. */
struct fhwc_loader_diag {
	int shim_loaded, ge_loaded, query_found;
	int shim_atomic_found, default_atomic_found;
	char shim_error[384], ge_error[384], query_error[384];
	char shim_atomic_error[192], default_atomic_error[192];
	char shim_atomic_provider[192], default_atomic_provider[192];
	char query_provider[192];
};

struct forge_hwc {
	hwc_composer_device_1_t base;	/* must stay first */
	const hwc_procs_t *procs;

	int disp_fd;
	int fb_fd;
	unsigned int session;
	int session_ok;
	unsigned int nslots;	/* input slots sent per frame, <= maxLayerNum */
	int frame_legacy;	/* kernel parses the blob-era frame layout */

	unsigned int width, height;
	unsigned int vsync_period_ns;
	unsigned int xdpi_1000, ydpi_1000;	/* dpi * 1000, HWC1 convention */

	int (*ge_query)(buffer_handle_t handle, int attribute, void *out);
	void *ge_lib;
	void *shim_lib;	/* libm681shim_base, RTLD_GLOBAL for libgralloc_extra */
	struct fhwc_loader_diag loader;

	pthread_t vsync_thread;
	pthread_mutex_t lock;
	pthread_cond_t cond;
	volatile int vsync_on;
	volatile int stop;

	/* stats for dump() */
	unsigned int frames;
	unsigned int prepare_fail;
	unsigned int trigger_fail;
	unsigned int acquire_timeouts;
	/*
	 * Acquire-fence counters (from the m5c fence probe): whether set()
	 * had to wait for the producer, and for how long.  A share of waits
	 * near zero under load means the fences signal before set() is even
	 * called (FACT m681 2026-09-29, boot animation: presig 8115, waited 0).
	 * In dump() and, every 300 frames, in the log.
	 */
	unsigned int acq_presignaled;
	unsigned int acq_waited;
	unsigned int acq_nofence;	/* SF handed us NO fence (fd = -1):
					 * with mali lacking native fence
					 * support every plane lands here and
					 * nothing orders the GPU against the
					 * scan-out - a content tear needs no
					 * other explanation then */
	unsigned int acq_wait_us_max;
	unsigned long long acq_wait_us_total;
	unsigned int last_buff_idx;
	unsigned int last_pf_idx;
	int fmt_override;	/* debug.forgehwc.fmt, 0 = RGBA8888 */

	/* overlay stats */
	unsigned int ovl_frames;	/* frames with >=1 promoted layer */
	unsigned int gles_frames;	/* frames composed via FBT only */
	unsigned int promoted_total;	/* cumulative promoted layers */
	unsigned int last_novl;		/* planes in last frame */
	int last_fbt_used;
};

/* one plane handed to the kernel OVL */
struct fhwc_plane {
	buffer_handle_t handle;
	int acquire;		/* fence fd, consumed by submit */
	int fmt;		/* DISP_FORMAT_* */
	int32_t blending;	/* HWC_BLENDING_*, 0 for the FBT */
	uint16_t sx, sy, sw, sh;	/* source crop, pixels */
	uint16_t tx, ty;	/* dest offset */
	int release_fd;		/* out: per-plane release fence */
};

static int prop_int(const char *name, int def)
{
	char v[PROP_VALUE_MAX];

	if (__system_property_get(name, v) > 0)
		return atoi(v);
	return def;
}

/*
 * Duplicate the load-bearing markers into dmesg: logcat gets rotated and
 * restarted with the framework, dmesg is what every capture script here
 * already collects.
 *
 * m681: every line also goes to logcat.  A13 first-stage init creates
 * /dev/kmsg as 0600 root and this tree's ueventd.rc has no entry for it, so
 * the composer (user system) most likely cannot open it (INFERENCE, not yet
 * checked on the device); logcat is then the only copy.
 */
static void kmsg_log(const char *fmt, ...)
{
	char line[256];
	va_list ap;
	int fd, n;

	va_start(ap, fmt);
	n = vsnprintf(line, sizeof(line), fmt, ap);
	va_end(ap);
	if (n <= 0)
		return;
	FLOGI("%s", line);
	fd = open("/dev/kmsg", O_WRONLY | O_CLOEXEC);
	if (fd < 0)
		return;
	write(fd, line, (size_t)(n < (int)sizeof(line) ? n : (int)sizeof(line)));
	close(fd);
}

static void loader_error(char *out, size_t size, const char *error)
{
	snprintf(out, size, "%s", error ? error : "no dlerror");
}

static void loader_provider(void *symbol, char *out, size_t size)
{
	Dl_info info;

	memset(&info, 0, sizeof(info));
	snprintf(out, size, "%s", symbol && dladdr(symbol, &info) && info.dli_fname ?
		 info.dli_fname : "unavailable");
}

/* Read-only symbol probes: no vendor query, atomic operation or hardware call. */
static int loader_symbol_probe(void *handle, const char *name,
			       char *error, size_t error_size,
			       char *provider, size_t provider_size)
{
	void *symbol;
	const char *reason;

	dlerror();
	symbol = dlsym(handle, name);
	reason = dlerror();
	if (!symbol || reason) {
		loader_error(error, error_size, reason);
		return 0;
	}
	loader_provider(symbol, provider, provider_size);
	return 1;
}

static void fhwc_load_gralloc(struct forge_hwc *hwc)
{
	struct fhwc_loader_diag *d = &hwc->loader;
	const char *reason;

	/* Preserve the existing order and flags; isolate each dlerror stage. */
	dlerror();
	hwc->shim_lib = dlopen("libm681shim_base.so", RTLD_NOW | RTLD_GLOBAL);
	reason = dlerror();
	d->shim_loaded = hwc->shim_lib != NULL;
	if (!d->shim_loaded) {
		loader_error(d->shim_error, sizeof(d->shim_error), reason);
		FLOGW("libm681shim_base: %s", d->shim_error);
	}

	dlerror();
	hwc->ge_lib = dlopen("libgralloc_extra.so", RTLD_NOW | RTLD_LOCAL);
	reason = dlerror();
	d->ge_loaded = hwc->ge_lib != NULL;
	if (!d->ge_loaded) {
		loader_error(d->ge_error, sizeof(d->ge_error), reason);
	} else {
		dlerror();
		hwc->ge_query = (int (*)(buffer_handle_t, int, void *))
			dlsym(hwc->ge_lib, "gralloc_extra_query");
		reason = dlerror();
		d->query_found = hwc->ge_query != NULL;
		if (!d->query_found)
			loader_error(d->query_error, sizeof(d->query_error), reason);
		else
			loader_provider((void *)hwc->ge_query, d->query_provider,
					sizeof(d->query_provider));
	}
	FLOGI("gralloc_extra: %s: %s", hwc->ge_query ? "loaded" : "unavailable, using fallback",
	      d->ge_loaded ? (d->query_found ? d->query_provider : d->query_error) : d->ge_error);

	/* These run after the original load sequence, so cannot repair relocation. */
	if (hwc->shim_lib)
		d->shim_atomic_found = loader_symbol_probe(hwc->shim_lib,
			"android_atomic_acquire_load", d->shim_atomic_error,
			sizeof(d->shim_atomic_error), d->shim_atomic_provider,
			sizeof(d->shim_atomic_provider));
	d->default_atomic_found = loader_symbol_probe(RTLD_DEFAULT,
		"android_atomic_acquire_load", d->default_atomic_error,
		sizeof(d->default_atomic_error), d->default_atomic_provider,
		sizeof(d->default_atomic_provider));
}

static void loader_dump(const struct fhwc_loader_diag *d, char *buff, int buff_len)
{
	if (!buff || buff_len <= 0)
		return;
	snprintf(buff, (size_t)buff_len,
		 "forge-ge-loader: shim=%d ge=%d query=%d\n"
		 " shim_dlopen: %s\n ge_dlopen: %s\n query_dlsym: %s\n"
		 " query_provider: %s\n"
		 " atomic_shim=%d provider=%s error=%s\n"
		 " atomic_default=%d provider=%s error=%s\n",
		 d->shim_loaded, d->ge_loaded, d->query_found,
		 d->shim_error[0] ? d->shim_error : "-",
		 d->ge_error[0] ? d->ge_error : "-",
		 d->query_error[0] ? d->query_error : "-",
		 d->query_provider[0] ? d->query_provider : "-",
		 d->shim_atomic_found,
		 d->shim_atomic_provider[0] ? d->shim_atomic_provider : "-",
		 d->shim_atomic_error[0] ? d->shim_atomic_error : "-",
		 d->default_atomic_found,
		 d->default_atomic_provider[0] ? d->default_atomic_provider : "-",
		 d->default_atomic_error[0] ? d->default_atomic_error : "-");
}

/* ============================ engine ============================ */

static int engine_wait_fence(struct forge_hwc *hwc, int fd, int timeout_ms)
{
	struct pollfd p;
	int ret;

	if (fd < 0)
		return 0;
	p.fd = fd;
	p.events = POLLIN | POLLERR;
	do {
		ret = poll(&p, 1, timeout_ms);
	} while (ret == -1 && (errno == EINTR || errno == EAGAIN));
	if (ret == 0) {
		hwc->acquire_timeouts++;
		FLOGW("acquire fence %d timed out after %d ms", fd, timeout_ms);
	}
	return ret;
}

/*
 * Which FRAME_CONFIG layout does the kernel parse?  1 = blob-era (the
 * kernel default), 0 = current header.  No knob at all means a kernel
 * without the forge translation, i.e. the current layout.
 */
static int engine_frame_layout(void)
{
	char v[8] = { 0 };
	int fd = open(FRAME_CFG_KNOB, O_RDONLY | O_CLOEXEC);

	if (fd < 0) {
		FLOGW("%s: %s, assuming the current frame layout", FRAME_CFG_KNOB,
		      strerror(errno));
		return 0;
	}
	if (read(fd, v, sizeof(v) - 1) <= 0)
		v[0] = '1';	/* knob present but unreadable: its default */
	close(fd);
	return v[0] != '0';
}

static int engine_open_session(struct forge_hwc *hwc)
{
	struct disp_session_config cfg;
	struct disp_session_info info;

	memset(&cfg, 0, sizeof(cfg));
	cfg.type = DISP_SESSION_PRIMARY;
	cfg.device_id = 0;
	cfg.mode = DISP_SESSION_DIRECT_LINK_MODE;
	cfg.user = SESSION_USER_HWC;

	if (ioctl(hwc->disp_fd, DISP_IOCTL_CREATE_SESSION, &cfg) < 0) {
		FLOGE("CREATE_SESSION failed: %s", strerror(errno));
		return -errno;
	}
	hwc->session = cfg.session_id;

	memset(&info, 0, sizeof(info));
	info.session_id = hwc->session;
	if (ioctl(hwc->disp_fd, DISP_IOCTL_GET_SESSION_INFO, &info) < 0) {
		FLOGE("GET_SESSION_INFO failed: %s", strerror(errno));
		return -errno;
	}

	hwc->width = info.displayWidth;
	hwc->height = info.displayHeight;
	/*
	 * FRAME_CONFIG rejects input_layer_num > the kernel's max_layer
	 * (-EINVAL), and maxLayerNum is that value (minus the AEE layer when
	 * DAL is on).  Up to 4 slots are sent every frame so that a layer used
	 * by the previous owner (LK logo, the blob) is switched off explicitly.
	 */
	hwc->nslots = info.maxLayerNum < 4 ? info.maxLayerNum : 4;
	if (!hwc->nslots)
		hwc->nslots = 1;
	/*
	 * MTK convention (measured on device, not guessed): vsyncFPS comes
	 * back as fps*100 — 5850 here, i.e. 58.50 Hz.  Values <= 1000 are
	 * treated as plain Hz just in case another kernel returns those.
	 */
	if (info.vsyncFPS > 1000)
		hwc->vsync_period_ns =
		    (unsigned int)(100000000000ULL / info.vsyncFPS);
	else if (info.vsyncFPS)
		hwc->vsync_period_ns = 1000000000u / info.vsyncFPS;
	else
		hwc->vsync_period_ns = 16666666u;
	if (info.physicalWidthUm && info.physicalHeightUm) {
		hwc->xdpi_1000 = (unsigned int)
		    ((uint64_t)info.displayWidth * 25400000ULL / info.physicalWidthUm);
		hwc->ydpi_1000 = (unsigned int)
		    ((uint64_t)info.displayHeight * 25400000ULL / info.physicalHeightUm);
	}
	if (!hwc->xdpi_1000)
		hwc->xdpi_1000 = hwc->ydpi_1000 =
		    (unsigned int)prop_int("ro.sf.lcd_density", 320) * 1000u;

	/* be explicit about the mode; the vendor HAL did the same (12x mode=1) */
	memset(&cfg, 0, sizeof(cfg));
	cfg.type = DISP_SESSION_PRIMARY;
	cfg.mode = DISP_SESSION_DIRECT_LINK_MODE;
	cfg.session_id = hwc->session;
	cfg.user = SESSION_USER_HWC;
	cfg.present_fence_idx = (unsigned int)-1;
	if (ioctl(hwc->disp_fd, DISP_IOCTL_SET_SESSION_MODE, &cfg) < 0)
		FLOGW("SET_SESSION_MODE failed: %s (continuing)", strerror(errno));

	hwc->frame_legacy = engine_frame_layout();

	hwc->session_ok = 1;
	FLOGI("session 0x%x: %ux%u vsyncFPS=%u period=%uns maxLayer=%u vsync=%u dpi=%u.%03u frame=%s",
	      hwc->session, hwc->width, hwc->height, info.vsyncFPS,
	      hwc->vsync_period_ns, info.maxLayerNum,
	      info.isHwVsyncAvailable, hwc->xdpi_1000 / 1000, hwc->xdpi_1000 % 1000,
	      hwc->frame_legacy ? "legacy" : "current");
	kmsg_log("forge-hwc: session 0x%x %ux%u vsyncFPS=%u period=%uns maxLayer=%u slots=%u frame=%s",
		 hwc->session, hwc->width, hwc->height, info.vsyncFPS,
		 hwc->vsync_period_ns, info.maxLayerNum, hwc->nslots,
		 hwc->frame_legacy ? "legacy" : "current");
	return 0;
}

/* HAL pixel format -> DISP_FORMAT for the overlay path; 0 = not supported */
static int map_hal_format(int hal_fmt)
{
	switch (hal_fmt) {
	case 1:		/* HAL_PIXEL_FORMAT_RGBA_8888 */
		return DISP_FORMAT_RGBA8888;
	case 2:		/* HAL_PIXEL_FORMAT_RGBX_8888 */
		return DISP_FORMAT_RGBX8888;
	case 4:		/* HAL_PIXEL_FORMAT_RGB_565 */
		return DISP_FORMAT_RGB565;
	case 5:		/* HAL_PIXEL_FORMAT_BGRA_8888 */
		return DISP_FORMAT_BGRA8888;
	default:
		return 0;
	}
}

/*
 * Blending -> OVL alpha controls.  Kernel encoding (FACT, mt6755
 * dispsys/ddp_ovl.c:796-798 at 91e69fe3c, same as mt6735m on m5c):
 * sur_aen -> bit 15, src/dst_alpha -> the 2-bit blend factor selectors.
 * PREMULT: out = src + (1-a_s)*dst -> factors ONE / SRC_INVERT;
 * COVERAGE: SRC / SRC_INVERT.  Used only by overlays (off by default).
 */
static void fill_blending(struct disp_input_config *c, int32_t blending)
{
	if (blending == 0x0105 /* HWC_BLENDING_PREMULT */) {
		c->alpha_enable = 1;
		c->sur_aen = 1;
		c->src_alpha = DISP_ALPHA_ONE;
		c->dst_alpha = DISP_ALPHA_SRC_INVERT;
	} else if (blending == 0x0405 /* HWC_BLENDING_COVERAGE */) {
		c->alpha_enable = 1;
		c->sur_aen = 1;
		c->src_alpha = DISP_ALPHA_SRC;
		c->dst_alpha = DISP_ALPHA_SRC_INVERT;
	} else {	/* HWC_BLENDING_NONE / FBT: opaque */
		c->alpha_enable = 0;
		c->sur_aen = 0;
		c->src_alpha = DISP_ALPHA_ONE;
		c->dst_alpha = DISP_ALPHA_ONE;
	}
	c->alpha = 0xff;
}

static void input_to_legacy(struct fhwc_input_cfg_legacy *d,
			    const struct disp_input_config *s)
{
	d->layer_id = s->layer_id;
	d->layer_enable = s->layer_enable;
	d->buffer_source = s->buffer_source;
	d->src_base_addr = s->src_base_addr;
	d->src_phy_addr = s->src_phy_addr;
	d->src_direct_link = s->src_direct_link;
	d->src_fmt = s->src_fmt;
	d->src_use_color_key = s->src_use_color_key;
	d->src_color_key = s->src_color_key;
	d->src_pitch = s->src_pitch;
	d->src_offset_x = s->src_offset_x;
	d->src_offset_y = s->src_offset_y;
	d->src_width = s->src_width;
	d->src_height = s->src_height;
	d->tgt_offset_x = s->tgt_offset_x;
	d->tgt_offset_y = s->tgt_offset_y;
	d->tgt_width = s->tgt_width;
	d->tgt_height = s->tgt_height;
	d->layer_rotation = s->layer_rotation;
	d->layer_type = s->layer_type;
	d->video_rotation = s->video_rotation;
	d->isTdshp = s->isTdshp;
	d->next_buff_idx = s->next_buff_idx;
	d->identity = s->identity;
	d->connected_type = s->connected_type;
	d->security = s->security;
	d->alpha_enable = s->alpha_enable;
	d->alpha = s->alpha;
	d->sur_aen = s->sur_aen;
	d->src_alpha = s->src_alpha;
	d->dst_alpha = s->dst_alpha;
	d->frm_sequence = s->frm_sequence;
	d->yuv_range = s->yuv_range;
}

/* FRAME_CONFIG in the layout the kernel parses; <0 with errno set on failure */
static int engine_frame_config(struct forge_hwc *hwc,
			       const struct disp_frame_cfg_t *fc)
{
	struct fhwc_frame_cfg_legacy *lg;
	unsigned int i;
	int ret;

	if (!hwc->frame_legacy)
		return ioctl(hwc->disp_fd, DISP_IOCTL_FRAME_CONFIG, fc);

	lg = calloc(1, sizeof(*lg));
	if (!lg) {
		errno = ENOMEM;
		return -1;
	}
	lg->setter = fc->setter;
	lg->session_id = fc->session_id;
	lg->input_layer_num = fc->input_layer_num;
	for (i = 0; i < 8; i++)
		input_to_legacy(&lg->input_cfg[i], &fc->input_cfg[i]);
	lg->overlap_layer_num = fc->overlap_layer_num;
	lg->mode = fc->mode;
	lg->present_fence_idx = fc->present_fence_idx;
	lg->tigger_mode = fc->tigger_mode;
	lg->user = fc->user;
	ret = ioctl(hwc->disp_fd, DISP_IOCTL_FRAME_CONFIG, lg);
	free(lg);
	return ret;
}

/*
 * Hand n planes (bottom -> top == OVL layer 0 -> n-1) to the kernel in one
 * FRAME_CONFIG.  Consumes every plane's acquire fence; fills each plane's
 * release_fd and *retire_fence (all owned by the caller).
 */
static int engine_submit(struct forge_hwc *hwc, struct fhwc_plane *planes,
			 int n, int *retire_fence)
{
	struct disp_buffer_info buf;
	struct disp_present_fence pf;
	struct disp_frame_cfg_t *fc;
	int i, k, ret;

	*retire_fence = -1;
	if (n > (int)hwc->nslots)
		return -EINVAL;

	/* the kernel does not wait src_fence_fd: wait here, then submit */
	for (k = 0; k < n; k++) {
		if (planes[k].acquire >= 0) {
			/* forge fence-probe: distinguish "producer was
			 * already done" from "we actually had to wait" */
			struct pollfd fp;
			int pr;

			fp.fd = planes[k].acquire;
			fp.events = POLLIN | POLLERR;
			pr = poll(&fp, 1, 0);
			if (pr > 0) {
				hwc->acq_presignaled++;
			} else {
				struct timespec a, b;
				unsigned int us;

				hwc->acq_waited++;
				clock_gettime(CLOCK_MONOTONIC, &a);
				engine_wait_fence(hwc, planes[k].acquire, 1200);
				clock_gettime(CLOCK_MONOTONIC, &b);
				us = (unsigned int)((b.tv_sec - a.tv_sec) * 1000000LL +
						    (b.tv_nsec - a.tv_nsec) / 1000);
				hwc->acq_wait_us_total += us;
				if (us > hwc->acq_wait_us_max)
					hwc->acq_wait_us_max = us;
			}
			close(planes[k].acquire);
		} else {
			hwc->acq_nofence++;
			/* rare (13 per session in the 2026-08-27 capture):
			 * say WHICH plane arrives fenceless - the geometry
			 * tells status bar / app / transition surface apart */
			kmsg_log("forge-nofence: #%u plane=%d/%d fmt=%d src=%ux%u dst+%u+%u",
				 hwc->acq_nofence, k, n, planes[k].fmt,
				 planes[k].sw, planes[k].sh,
				 planes[k].tx, planes[k].ty);
		}
		planes[k].acquire = -1;
		planes[k].release_fd = -1;
	}

	fc = calloc(1, sizeof(*fc));
	if (!fc)
		return -ENOMEM;
	fc->setter = SESSION_USER_HWC;
	fc->session_id = hwc->session;
	fc->user = SESSION_USER_HWC;
	fc->input_layer_num = hwc->nslots;
	for (i = 0; i < (int)hwc->nslots; i++) {
		fc->input_cfg[i].layer_id = (unsigned int)i;
		fc->input_cfg[i].layer_enable = 0;
		fc->input_cfg[i].src_fence_fd = -1;
	}

	for (k = 0; k < n; k++) {
		struct disp_input_config *c = &fc->input_cfg[k];
		struct fhwc_plane *p = &planes[k];
		int ion_fd = -1;
		int stride_px = (int)hwc->width;

		int ge_ok = 0;
		off_t dma_sz = 0;

		if (hwc->ge_query) {
			if (hwc->ge_query(p->handle, GE_GET_ION_FD, &ion_fd) != 0)
				ion_fd = -1;
			ge_ok = (hwc->ge_query(p->handle, GE_GET_STRIDE,
					       &stride_px) == 0);
		}
		if (ion_fd < 0 && p->handle->numFds > 0)
			ion_fd = p->handle->data[0];
		/*
		 * m681: the panel is 1080 wide, which a 16/32-px aligning
		 * allocator pads to 1088, so the width is a poor fallback here
		 * (on the 720-wide m5c it happened to be right).  Without
		 * gralloc_extra, take the pitch from the dma-buf size: whole
		 * rows of p->sh lines, accepted only within 64 px of the width.
		 * Bytes per pixel are the low byte of the DISP_FORMAT id.
		 */
		if (!ge_ok && ion_fd >= 0 && p->sh && (p->fmt & 0xff)) {
			dma_sz = lseek(ion_fd, 0, SEEK_END);
			lseek(ion_fd, 0, SEEK_SET);
			if (dma_sz > 0) {
				unsigned int s = (unsigned int)((size_t)dma_sz /
				    ((size_t)p->sh * (unsigned int)(p->fmt & 0xff)));

				if (s >= p->sw && s < (unsigned int)p->sw + 64u)
					stride_px = (int)s;
			}
		}
		/*
		 * forge: say what pitch each plane is actually given.
		 *
		 * A staircase along horizontal edges is what a wrong line
		 * stride looks like, and the fallback here silently uses the
		 * panel width when the gralloc query fails — which is wrong
		 * for any buffer the allocator padded. Print it once per
		 * plane per second so the answer is data, not assumption.
		 */
		{
			static unsigned int fseq;

			if ((fseq++ % 60) == 0)
				kmsg_log("forge-pitch: plane%d ge=%d stride_px=%d dma=%lld fmt=%d w=%d h=%d ion=%d numFds=%d",
					 k, ge_ok, stride_px, (long long)dma_sz,
					 p->fmt, p->sw, p->sh, ion_fd,
					 p->handle->numFds);
		}
		if (ion_fd < 0) {
			FLOGE("plane %d: no ion fd (numFds=%d)", k, p->handle->numFds);
			continue;	/* leave the plane disabled */
		}

		memset(&buf, 0, sizeof(buf));
		buf.session_id = hwc->session;
		buf.layer_id = (unsigned int)k;
		buf.layer_en = 1;
		buf.ion_fd = ion_fd;
		buf.cache_sync = 0;
		buf.fence_fd = -1;
		buf.interface_fence_fd = -1;
		if (ioctl(hwc->disp_fd, DISP_IOCTL_PREPARE_INPUT_BUFFER, &buf) < 0) {
			hwc->prepare_fail++;
			FLOGE("PREPARE(l%d) failed: %s (ion=%d)", k,
			      strerror(errno), ion_fd);
			continue;
		}
		hwc->last_buff_idx = buf.index;
		p->release_fd = buf.fence_fd;

		c->layer_enable = 1;
		c->buffer_source = DISP_BUFFER_ION;
		c->security = DISP_NORMAL_BUFFER;
		c->src_fmt = (enum DISP_FORMAT)p->fmt;
		c->next_buff_idx = buf.index;
		c->src_pitch = (unsigned int)stride_px;
		c->src_offset_x = p->sx;
		c->src_offset_y = p->sy;
		c->src_width = p->sw;
		c->src_height = p->sh;
		c->tgt_offset_x = p->tx;
		c->tgt_offset_y = p->ty;
		c->tgt_width = p->sw;
		c->tgt_height = p->sh;
		c->frm_sequence = hwc->frames;
		fill_blending(c, p->blending);
	}

	/*
	 * m681: the present fence signals only on a real IF_VSYNC after the
	 * frame (present_fence_worker, primary_display.c:3585); without vsync
	 * it stays pending and SurfaceFlinger holds back every later frame.
	 * debug.forgehwc.present=0 hands SF no retire fence at all instead.
	 */
	memset(&pf, 0, sizeof(pf));
	pf.session_id = hwc->session;
	pf.present_fence_fd = -1;
	pf.present_fence_index = (unsigned int)-1;
	if (prop_int("debug.forgehwc.present", 1) &&
	    ioctl(hwc->disp_fd, DISP_IOCTL_GET_PRESENT_FENCE, &pf) < 0) {
		FLOGW("GET_PRESENT_FENCE failed: %s", strerror(errno));
		pf.present_fence_fd = -1;
		pf.present_fence_index = (unsigned int)-1;
	}
	hwc->last_pf_idx = pf.present_fence_index;

	fc->overlap_layer_num = (unsigned int)n;
	fc->mode = DISP_SESSION_DIRECT_LINK_MODE;
	fc->present_fence_idx = pf.present_fence_index;
	fc->tigger_mode = TRIGGER_NORMAL;
	ret = engine_frame_config(hwc, fc);
	free(fc);
	if (ret < 0) {
		hwc->trigger_fail++;
		FLOGE("FRAME_CONFIG failed: %s", strerror(errno));
		goto fail;
	}

	hwc->frames++;
	hwc->last_novl = (unsigned int)n;
	if (hwc->frames <= 8 || (hwc->frames % 600) == 0)
		FLOGI("frame #%u: planes=%d pf_idx=%u", hwc->frames, n,
		      pf.present_fence_index);
	if ((hwc->frames % 300) == 0)
		kmsg_log("forge-fence: presig=%u waited=%u nofence=%u wait_avg_us=%llu wait_max_us=%u",
			 hwc->acq_presignaled, hwc->acq_waited, hwc->acq_nofence,
			 hwc->acq_waited ?
			     hwc->acq_wait_us_total / hwc->acq_waited : 0,
			 hwc->acq_wait_us_max);

	*retire_fence = pf.present_fence_fd;
	return 0;

fail:
	if (pf.present_fence_fd >= 0)
		close(pf.present_fence_fd);
	for (k = 0; k < n; k++) {
		if (planes[k].release_fd >= 0) {
			close(planes[k].release_fd);
			planes[k].release_fd = -1;
		}
	}
	return -errno;
}

static void *vsync_thread_fn(void *arg)
{
	struct forge_hwc *hwc = arg;
	struct disp_session_vsync_config vs;
	struct timespec ts_now;
	int64_t ts, last_ts = 0;

	while (1) {
		pthread_mutex_lock(&hwc->lock);
		while (!hwc->vsync_on && !hwc->stop)
			pthread_cond_wait(&hwc->cond, &hwc->lock);
		pthread_mutex_unlock(&hwc->lock);
		if (hwc->stop)
			break;

		memset(&vs, 0, sizeof(vs));
		vs.session_id = hwc->session;
		if (ioctl(hwc->disp_fd, DISP_IOCTL_WAIT_FOR_VSYNC, &vs) < 0) {
			usleep(16666);
			continue;
		}
		ts = (int64_t)vs.vsync_ts;
		if (ts == 0) {
			/* DISP_SLEPT / lcm-disconnected path returns immediately */
			clock_gettime(CLOCK_MONOTONIC, &ts_now);
			ts = (int64_t)ts_now.tv_sec * 1000000000LL + ts_now.tv_nsec;
			usleep(16666);
		}
		if (ts == last_ts) {	/* did not advance: don't spin */
			usleep(16666);
			continue;
		}
		last_ts = ts;
		if (hwc->vsync_on && hwc->procs && hwc->procs->vsync)
			hwc->procs->vsync(hwc->procs, 0, ts);
	}
	return NULL;
}

/* ============================ HWC1 facade ============================ */

static struct forge_hwc *to_hwc(hwc_composer_device_1_t *dev)
{
	return (struct forge_hwc *)dev;
}

/*
 * Can this layer go to a hardware overlay as-is?  Conservative: the OVL has
 * no scaler and no rotator, so any doubt means GLES (always correct).
 * Returns the DISP_FORMAT, or 0 for "compose with GLES".
 */
static int layer_fits_overlay(struct forge_hwc *hwc, hwc_layer_1_t *l)
{
	int hal_fmt = 0, fmt;
	int sw, sh, dw, dh;

	if (l->flags & HWC_SKIP_LAYER)
		return 0;
	if (!l->handle)
		return 0;	/* dim layers / sideband / not yet latched */
	if (l->transform != 0)
		return 0;	/* no rotator */
	if (l->blending != HWC_BLENDING_NONE &&
	    l->blending != HWC_BLENDING_PREMULT &&
	    l->blending != HWC_BLENDING_COVERAGE)
		return 0;

	/* integer, unscaled, fully on-screen */
	sw = l->sourceCropi.right - l->sourceCropi.left;
	sh = l->sourceCropi.bottom - l->sourceCropi.top;
	dw = l->displayFrame.right - l->displayFrame.left;
	dh = l->displayFrame.bottom - l->displayFrame.top;
	if (sw <= 0 || sh <= 0 || sw != dw || sh != dh)
		return 0;	/* scaled (or empty) */
	if (l->sourceCropi.left < 0 || l->sourceCropi.top < 0)
		return 0;
	if (l->displayFrame.left < 0 || l->displayFrame.top < 0 ||
	    l->displayFrame.right > (int)hwc->width ||
	    l->displayFrame.bottom > (int)hwc->height)
		return 0;	/* would need clipping */

	if (!hwc->ge_query)
		return 0;
	if (hwc->ge_query(l->handle, GE_GET_FORMAT, &hal_fmt) != 0)
		return 0;
	fmt = map_hal_format(hal_fmt);
	return fmt;
}

/*
 * Promotion rule: overlays are taken only as a contiguous run from the TOP
 * of the z-ordered list, so the GLES-composed remainder (bottom of the
 * stack) is exactly what the single FBT plane at OVL 0 can represent.
 * If everything fits and there are at most 4 layers, no FBT is used at all.
 */
static int fhwc_prepare(hwc_composer_device_1_t *dev, size_t numDisplays,
			hwc_display_contents_1_t **displays)
{
	struct forge_hwc *hwc = to_hwc(dev);
	hwc_display_contents_1_t *d;
	int i, nlayers, top_run, budget, first_ovl;
	/*
	 * m681: overlays default OFF.  The mt6755 OVL path (layer count, HRT,
	 * 1080p fetch bandwidth) is untested with this module; the first frame
	 * has to come through the single FBT plane.  debug.forgehwc.overlays=1
	 * enables the m5c promotion rule below.
	 */
	int overlays_on = prop_int("debug.forgehwc.overlays", 0);

	if (!numDisplays || !displays || !displays[0])
		return 0;
	d = displays[0];

	/* indexes of real layers (the FBT is not a candidate) */
	nlayers = 0;
	for (i = 0; i < (int)d->numHwLayers; i++)
		if (d->hwLayers[i].compositionType != HWC_FRAMEBUFFER_TARGET)
			nlayers++;

	/* how many contiguous layers from the top fit an overlay */
	top_run = 0;
	if (overlays_on) {
		for (i = (int)d->numHwLayers - 1; i >= 0; i--) {
			hwc_layer_1_t *l = &d->hwLayers[i];

			if (l->compositionType == HWC_FRAMEBUFFER_TARGET)
				continue;
			if (!layer_fits_overlay(hwc, l))
				break;
			top_run++;
		}
	}

	if (top_run == nlayers && nlayers > 0 && nlayers <= (int)hwc->nslots)
		budget = nlayers;	/* everything on OVL, no FBT */
	else	/* OVL 0 = FBT */
		budget = top_run < (int)hwc->nslots - 1 ? top_run : (int)hwc->nslots - 1;

	/*
	 * forge: cap the number of planes fetched concurrently.
	 *
	 * Each overlay plane has its own fetch FIFO, and with three
	 * full-screen planes live all three underflow: OVL0_INTSTA came back
	 * 0xe03 under a fast animation, bits 9/10/11 being the per-layer
	 * RDMA FIFO underflow of layers 0, 1 and 2. On a single plane the
	 * same register reads 0x3. The picture breaks up toward the bottom
	 * of the frame, where the accumulated fetch deficit shows.
	 *
	 * Demoting a layer does not save the bytes it read — the GLES
	 * remainder arrives as a full-screen FBT plane instead — so what is
	 * being bought here is fewer concurrent fetch streams, not less
	 * traffic. debug.forgehwc.maxplanes exists to find the point where
	 * the underflow bits stop appearing without a rebuild.
	 */
	{
		int maxp = prop_int("debug.forgehwc.maxplanes", (int)hwc->nslots);

		if (maxp < 0)
			maxp = 0;
		if (budget > maxp)
			budget = maxp;
		/* demoted layers bring the FBT back: keep FBT + overlays <= slots */
		if (budget < nlayers && budget > (int)hwc->nslots - 1)
			budget = (int)hwc->nslots - 1;
	}

	/* first (lowest-z) real layer that gets an overlay */
	first_ovl = nlayers - budget;

	nlayers = 0;
	for (i = 0; i < (int)d->numHwLayers; i++) {
		hwc_layer_1_t *l = &d->hwLayers[i];

		if (l->compositionType == HWC_FRAMEBUFFER_TARGET)
			continue;
		if (nlayers >= first_ovl && budget > 0)
			l->compositionType = HWC_OVERLAY;
		else
			l->compositionType = HWC_FRAMEBUFFER;
		nlayers++;
	}
	return 0;
}

static int fhwc_set(hwc_composer_device_1_t *dev, size_t numDisplays,
		    hwc_display_contents_1_t **displays)
{
	struct forge_hwc *hwc = to_hwc(dev);
	hwc_display_contents_1_t *d;
	hwc_layer_1_t *fbt = NULL;
	hwc_layer_1_t *src[4];
	struct fhwc_plane planes[4];
	size_t i;
	int n = 0, gles_used = 0, ret_f = -1;

	if (!numDisplays || !displays || !displays[0])
		return 0;
	d = displays[0];
	d->retireFenceFd = -1;

	for (i = 0; i < d->numHwLayers; i++) {
		hwc_layer_1_t *l = &d->hwLayers[i];

		if (l->compositionType == HWC_FRAMEBUFFER_TARGET)
			fbt = l;
		else if (l->compositionType == HWC_FRAMEBUFFER)
			gles_used = 1;
	}

	memset(planes, 0, sizeof(planes));

	/* OVL 0 = the GLES result, when anything was left to GLES */
	if (gles_used) {
		if (!fbt || !fbt->handle) {
			/* nothing usable this frame */
			if (fbt && fbt->acquireFenceFd >= 0) {
				close(fbt->acquireFenceFd);
				fbt->acquireFenceFd = -1;
			}
			return 0;
		}
		src[n] = fbt;
		planes[n].handle = fbt->handle;
		planes[n].acquire = fbt->acquireFenceFd;
		planes[n].fmt = hwc->fmt_override ?
		    hwc->fmt_override : DISP_FORMAT_RGBA8888;
		planes[n].blending = 0;	/* opaque */
		planes[n].sw = (uint16_t)hwc->width;
		planes[n].sh = (uint16_t)hwc->height;
		n++;
	}

	/* promoted layers, in z order (list order is bottom -> top) */
	for (i = 0; i < d->numHwLayers && n < (int)hwc->nslots; i++) {
		hwc_layer_1_t *l = &d->hwLayers[i];
		int fmt;

		if (l->compositionType != HWC_OVERLAY)
			continue;
		fmt = layer_fits_overlay(hwc, l);
		if (!fmt) {
			/* changed between prepare and set: should not happen */
			FLOGW("overlay layer no longer eligible, dropping frame plane");
			if (l->acquireFenceFd >= 0) {
				close(l->acquireFenceFd);
				l->acquireFenceFd = -1;
			}
			continue;
		}
		src[n] = l;
		planes[n].handle = l->handle;
		planes[n].acquire = l->acquireFenceFd;
		planes[n].fmt = fmt;
		planes[n].blending = l->blending;
		planes[n].sx = (uint16_t)l->sourceCropi.left;
		planes[n].sy = (uint16_t)l->sourceCropi.top;
		planes[n].sw = (uint16_t)(l->sourceCropi.right - l->sourceCropi.left);
		planes[n].sh = (uint16_t)(l->sourceCropi.bottom - l->sourceCropi.top);
		planes[n].tx = (uint16_t)l->displayFrame.left;
		planes[n].ty = (uint16_t)l->displayFrame.top;
		n++;
	}

	/* FBT unused this frame: its acquire fence is still ours to close */
	if (!gles_used && fbt && fbt->acquireFenceFd >= 0) {
		close(fbt->acquireFenceFd);
		fbt->acquireFenceFd = -1;
	}

	if (n == 0)
		return 0;

	engine_submit(hwc, planes, n, &ret_f);

	for (i = 0; i < (size_t)n; i++) {
		src[i]->acquireFenceFd = -1;	/* consumed by engine_submit */
		src[i]->releaseFenceFd = planes[i].release_fd;
	}
	d->retireFenceFd = ret_f;

	hwc->last_fbt_used = gles_used;
	if (n > (gles_used ? 1 : 0)) {
		hwc->ovl_frames++;
		hwc->promoted_total += (unsigned int)(n - (gles_used ? 1 : 0));
	} else {
		hwc->gles_frames++;
	}
	return 0;
}

static int fhwc_event_control(hwc_composer_device_1_t *dev, int disp,
			      int event, int enabled)
{
	struct forge_hwc *hwc = to_hwc(dev);

	if (disp != 0 || event != HWC_EVENT_VSYNC)
		return -EINVAL;
	pthread_mutex_lock(&hwc->lock);
	hwc->vsync_on = !!enabled;
	pthread_cond_signal(&hwc->cond);
	pthread_mutex_unlock(&hwc->lock);
	return 0;
}

static int fhwc_blank(hwc_composer_device_1_t *dev, int disp, int blank)
{
	struct forge_hwc *hwc = to_hwc(dev);
	int arg = blank ? FB_BLANK_POWERDOWN : FB_BLANK_UNBLANK;

	if (disp != 0)
		return -EINVAL;
	if (hwc->fb_fd < 0)
		return -ENODEV;
	FLOGI("blank(%d)", blank);
	if (ioctl(hwc->fb_fd, FBIOBLANK, arg) < 0) {
		FLOGE("FBIOBLANK(%d) failed: %s", arg, strerror(errno));
		return -errno;
	}
	return 0;
}

static int fhwc_query(hwc_composer_device_1_t *dev, int what, int *value)
{
	struct forge_hwc *hwc = to_hwc(dev);

	switch (what) {
	case HWC_BACKGROUND_LAYER_SUPPORTED:
		*value = 0;
		return 0;
	case HWC_DISPLAY_TYPES_SUPPORTED:
		*value = HWC_DISPLAY_PRIMARY_BIT;
		return 0;
	case HWC_VSYNC_PERIOD:
		*value = (int)hwc->vsync_period_ns;
		return 0;
	default:
		return -EINVAL;
	}
}

static void fhwc_register_procs(hwc_composer_device_1_t *dev,
				const hwc_procs_t *procs)
{
	to_hwc(dev)->procs = procs;
}

static void fhwc_dump(hwc_composer_device_1_t *dev, char *buff, int buff_len)
{
	struct forge_hwc *hwc = to_hwc(dev);
	int written;

	if (!buff || buff_len <= 0)
		return;
	written = snprintf(buff, (size_t)buff_len,
		 "forge-hwc: session=0x%x %ux%u period=%uns frames=%u prepare_fail=%u "
		 "trigger_fail=%u acq_timeout=%u last_idx=%u last_pf=%u "
		 "vsync_on=%d ge=%s "
		 "ovl_frames=%u gles_frames=%u promoted=%u last: planes=%u fbt=%d "
		 "acq: presig=%u waited=%u nofence=%u wait_avg_us=%llu wait_max_us=%u\n",
		 hwc->session, hwc->width, hwc->height, hwc->vsync_period_ns, hwc->frames,
		 hwc->prepare_fail, hwc->trigger_fail, hwc->acquire_timeouts,
		 hwc->last_buff_idx, hwc->last_pf_idx, hwc->vsync_on,
		 hwc->ge_query ? "yes" : "no",
		 hwc->ovl_frames, hwc->gles_frames, hwc->promoted_total,
		 hwc->last_novl, hwc->last_fbt_used,
		 hwc->acq_presignaled, hwc->acq_waited, hwc->acq_nofence,
		 hwc->acq_waited ? hwc->acq_wait_us_total / hwc->acq_waited : 0,
		 hwc->acq_wait_us_max);
	if (written >= 0 && written < buff_len)
		loader_dump(&hwc->loader, buff + written, buff_len - written);
}

static int fhwc_get_display_configs(hwc_composer_device_1_t *dev, int disp,
				    uint32_t *configs, size_t *numConfigs)
{
	(void)dev;
	if (disp != 0)
		return -EINVAL;
	if (*numConfigs > 0) {
		configs[0] = 0;
		*numConfigs = 1;
	}
	return 0;
}

static int fhwc_get_display_attributes(hwc_composer_device_1_t *dev, int disp,
				       uint32_t config, const uint32_t *attributes,
				       int32_t *values)
{
	struct forge_hwc *hwc = to_hwc(dev);
	int i;

	if (disp != 0 || config != 0)
		return -EINVAL;
	for (i = 0; attributes[i] != HWC_DISPLAY_NO_ATTRIBUTE; i++) {
		switch (attributes[i]) {
		case HWC_DISPLAY_VSYNC_PERIOD:
			values[i] = (int32_t)hwc->vsync_period_ns;
			break;
		case HWC_DISPLAY_WIDTH:
			values[i] = (int32_t)hwc->width;
			break;
		case HWC_DISPLAY_HEIGHT:
			values[i] = (int32_t)hwc->height;
			break;
		case HWC_DISPLAY_DPI_X:
			values[i] = (int32_t)hwc->xdpi_1000;
			break;
		case HWC_DISPLAY_DPI_Y:
			values[i] = (int32_t)hwc->ydpi_1000;
			break;
		default:
			values[i] = 0;
			break;
		}
	}
	return 0;
}

static int fhwc_close(hw_device_t *dev)
{
	struct forge_hwc *hwc = (struct forge_hwc *)dev;
	struct disp_session_config cfg;

	pthread_mutex_lock(&hwc->lock);
	hwc->stop = 1;
	pthread_cond_signal(&hwc->cond);
	pthread_mutex_unlock(&hwc->lock);
	pthread_join(hwc->vsync_thread, NULL);

	if (hwc->session_ok) {
		memset(&cfg, 0, sizeof(cfg));
		cfg.type = DISP_SESSION_PRIMARY;
		cfg.session_id = hwc->session;
		ioctl(hwc->disp_fd, DISP_IOCTL_DESTROY_SESSION, &cfg);
	}
	if (hwc->fb_fd >= 0)
		close(hwc->fb_fd);
	if (hwc->disp_fd >= 0)
		close(hwc->disp_fd);
	if (hwc->ge_lib)
		dlclose(hwc->ge_lib);
	if (hwc->shim_lib)
		dlclose(hwc->shim_lib);
	free(hwc);
	return 0;
}

static int fhwc_open(const struct hw_module_t *module, const char *name,
		     struct hw_device_t **device)
{
	struct forge_hwc *hwc;
	int err;

	if (strcmp(name, HWC_HARDWARE_COMPOSER))
		return -EINVAL;

	hwc = calloc(1, sizeof(*hwc));
	if (!hwc)
		return -ENOMEM;

	hwc->disp_fd = open(DISP_DEV_PATH, O_RDWR);
	if (hwc->disp_fd < 0) {
		err = -errno;
		FLOGE("cannot open %s: %s", DISP_DEV_PATH, strerror(errno));
		free(hwc);
		return err;
	}
	hwc->fb_fd = open(FB_DEV_PATH, O_RDWR);
	if (hwc->fb_fd < 0)
		FLOGW("cannot open %s: %s (blank() disabled)", FB_DEV_PATH,
		      strerror(errno));

	err = engine_open_session(hwc);
	if (err) {
		/* leave the system on the fbdev fallback rather than limp */
		if (hwc->fb_fd >= 0)
			close(hwc->fb_fd);
		close(hwc->disp_fd);
		free(hwc);
		return err;
	}

	/*
	 * m681: the N-era libgralloc_extra imports android_atomic_acquire_load,
	 * which A13's libcutils no longer exports (FACT, llvm-nm of the built
	 * vendor/lib64: of its undefined symbols only this one is found in none
	 * of its NEEDED libraries, and libm681shim_base.so defines it).  The
	 * TARGET_LD_SHIM_LIBS entry of vendor/meizu/m681 pairs that shim with
	 * gralloc.mt6755 only, so a plain dlopen here cannot bind it — the
	 * A13 run of 2026-09-29 logged "unavailable" and lost overlays.  Load the
	 * shim RTLD_GLOBAL first. Actual relocation visibility also depends on
	 * ELF global flags and the local dependency group. Preserve each load
	 * result in dump() so the exact failure survives log rotation.
	 */
	fhwc_load_gralloc(hwc);

	hwc->fmt_override = prop_int("debug.forgehwc.fmt", 0);

	pthread_mutex_init(&hwc->lock, NULL);
	pthread_cond_init(&hwc->cond, NULL);
	err = pthread_create(&hwc->vsync_thread, NULL, vsync_thread_fn, hwc);
	if (err) {
		FLOGE("vsync thread: %s", strerror(err));
		close(hwc->disp_fd);
		if (hwc->fb_fd >= 0)
			close(hwc->fb_fd);
		free(hwc);
		return -err;
	}

	hwc->base.common.tag = HARDWARE_DEVICE_TAG;
	hwc->base.common.version = HWC_DEVICE_API_VERSION_1_1;
	hwc->base.common.module = (struct hw_module_t *)module;
	hwc->base.common.close = fhwc_close;
	hwc->base.prepare = fhwc_prepare;
	hwc->base.set = fhwc_set;
	hwc->base.eventControl = fhwc_event_control;
	hwc->base.blank = fhwc_blank;
	hwc->base.query = fhwc_query;
	hwc->base.registerProcs = fhwc_register_procs;
	hwc->base.dump = fhwc_dump;
	hwc->base.getDisplayConfigs = fhwc_get_display_configs;
	hwc->base.getDisplayAttributes = fhwc_get_display_attributes;

	*device = &hwc->base.common;
	FLOGI("forge-hwc up (HWC1.1, mt6755 FRAME_CONFIG, %s layout)",
	      hwc->frame_legacy ? "legacy" : "current");
	return 0;
}

static struct hw_module_methods_t fhwc_module_methods = {
	.open = fhwc_open,
};

hwc_module_t HAL_MODULE_INFO_SYM = {
	.common = {
		.tag = HARDWARE_MODULE_TAG,
		.module_api_version = HWC_MODULE_API_VERSION_0_1,
		.hal_api_version = HARDWARE_HAL_API_VERSION,
		.id = HWC_HARDWARE_MODULE_ID,
		.name = "forge hwcomposer for m681 (mt6755, 4.9 kernel)",
		.author = "forge",
		.methods = &fhwc_module_methods,
	},
};
