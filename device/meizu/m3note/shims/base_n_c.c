// N-era libcutils and MTK xlog symbols for the MT6755 M3 Note blob set on
// Android 13 — the C half of libm681shim_base (Android.bp).
//
// libm681shim_base is loaded into BOTH the vendor default namespace (composer,
// allocator) and sphal (Mali EGL and gralloc inside SurfaceFlinger, zygote and
// every app), so it may depend only on what sphal reaches: LLNDK (libc, liblog)
// and the sphal -> vndk link (VNDK-SP, plus libbinder/libnetutils on the fleet
// branch of system/linkerconfig, contents/namespace/sphal.cc).  This file needs
// libc and liblog only.
//

// vendor/meizu/m681 against the A13 libraries of the m95 build (report:

// graphics path, both ABIs: hwcomposer.mt6755, gralloc.mt6755, libGLES_mali,
// libged, libgpu_aux, libgralloc_extra, libgui_ext, libui_ext, libbwc,
// libpq_prot, libpqservice.
#include <errno.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include <log/log.h>

// ---- android_atomic_* -------------------------------------------------------
// N libcutils exported the whole <cutils/atomic.h> family: its atomic.c was
// `#define ANDROID_ATOMIC_INLINE` + `#include <cutils/atomic.h>`.  The A13 header
// still carries the bodies (C11 stdatomic, same memory orders as N) but makes
// them static inline (system/core/libcutils/include/cutils/atomic.h:24-26) and
// libcutils exports none of them.  The N trick again: empty macro -> external
// definitions.  Imported by the blobs: acquire_load, release_load,
// release_store, inc, dec, and, or (hwcomposer, libgui_ext, Mali, libged,
// libgpu_aux, libgralloc_extra, camera).  The helper to_atomic_int_least32_t
// is exported as a side effect; no blob imports it.
#define ANDROID_ATOMIC_INLINE
#include <cutils/atomic.h>

// ---- android_memset16 -------------------------------------------------------
// Gone from libcutils since P.  gralloc.mt6755.so (lib and lib64) imports it.
// Old header semantics: count is in BYTES, dst is 2-byte aligned (m95
// device/meizu/m95/shims/utils.cpp, same gralloc generation).
void android_memset16(uint16_t* dst, uint16_t value, size_t count) {
    count /= sizeof(uint16_t);
    while (count-- > 0) *dst++ = value;
}

// ---- __xlog_buf_printf ------------------------------------------------------
// MediaTek xlog, exported by the MTK liblog of the ROMs these blobs came from;
// no AOSP library ever had it, the stock N system/lib* of Flyme 6.2.0.2A does
// not define it either (the symcheck names no provider).  11 importers,
// including hwcomposer, libgui_ext, libui_ext, libbwc, libpqservice.
// Record layout — FACT at a call site: lib64/libgui_ext.so
// GuiExtPoolItem::acquire 0x1a8fc-0x1a910: `add x1, x15, #1960` (record at
// 0x347a8), `mov w0, #0`, vararg in w2; the record is 24 bytes of
// .data.rel.ro = two R_AARCH64_RELATIVE pointers (tag "GuiExt", fmt
// "[GuiExtI]     acquire a pool=%d has no free slot") and int 5
// (ANDROID_LOG_WARN).  Same struct as the LOS16 libxlog shim
// (device/meizu/m3_meizu_m6-common/libxlog/xlog.c).  bufid is a log_id_t
// (0 = main); it is honoured, so RIL lines keep going to the radio buffer.
struct xlog_record {
    const char* tag_str;
    const char* fmt_str;
    int prio;
};

int __xlog_buf_printf(int bufid, const struct xlog_record* rec, ...) {
    if (rec == NULL || rec->fmt_str == NULL) return -EINVAL;
    char buf[1024];  // LOG_BUF_SIZE of __android_log_vprint
    va_list ap;
    va_start(ap, rec);
    vsnprintf(buf, sizeof(buf), rec->fmt_str, ap);
    va_end(ap);
    if (bufid < LOG_ID_MIN || bufid >= LOG_ID_MAX) bufid = LOG_ID_MAIN;
    return __android_log_buf_write(bufid, rec->prio, rec->tag_str, buf);
}
