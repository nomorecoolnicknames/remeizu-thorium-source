// libmtkshim_ui — the library hwcomposer.mt6755.so and libui_ext.so NEED by this
// very name (both ABIs; the LOS16 blobs were built/patched against a LOS16
// module of the same name, vendor/mediatek/symbols/ui.cpp there).  Vendor
// namespace only: it links libui, which sphal cannot see.  Everything the two
// need from libcutils/libutils/libbinder/xlog comes from libm681shim_base,
// NEEDed below, so it is in hwcomposer's local group as well.
//

// (--consumer lib64/hw/hwcomposer.mt6755.so), call sites read with
// llvm-objdump; the base for the bodies is device/meizu/m95/shims/ui.cpp and
// utils.cpp, with the differences marked "m681".
#include <string.h>

#include <log/log.h>
#include <ui/GraphicBufferMapper.h>
#include <ui/Rect.h>
#include <utils/String8.h>

namespace android {

// ---- GraphicBufferMapper singleton ------------------------------------------
// m681: FACT, lib64/hw/hwcomposer.mt6755.so Singleton<BlackBuffer>::getInstance
// 0x33c84-0x33c94 and lib64/libui_ext.so GraphicBufferUtil::dump 0x3184-0x3190:
// the N-inline GraphicBufferMapper::get() does `mov x0, #8; bl _Znwm;
// bl GraphicBufferMapper::GraphicBufferMapper()` when
// Singleton<GraphicBufferMapper>::sInstance is still null.  Both symbols
// resolve to A13 libui, whose constructor needs sizeof = 16 on arm64 (8 on arm;
// compiled probe with the vendor flags of the m95 build, 2026-09-25): an 8-byte
// heap overrun.  Creating the singleton here, from libui's own getInstance(),
// before any blob code runs closes it: sInstance/sLock are libui's exported
// statics, so the blobs' inline get() finds the A13-sized object.  Ordering:
// this library is the FIRST DT_NEEDED of hwcomposer.mt6755 and of libui_ext
// (FACT, readelf -d, lib and lib64), and bionic runs the constructors of a
// library's children, in DT_NEEDED order, before its own — so this one runs
// before any code of those blobs or their other dependencies.
// Side effect: the mapper HAL is opened when hwcomposer is loaded rather than
// on its first lock — the same work, earlier; if no mapper exists A13 aborts
// here instead of in the blob.
__attribute__((constructor)) static void m681_create_mapper_singleton() {
    (void)GraphicBufferMapper::get();
}

// status_t GraphicBufferMapper::lock(buffer_handle_t, int usage, const Rect&,
// void**) — pre-N int usage; not even stock N libui has it (the symcheck finds
// no provider), LOS16 supplied it from libmtkshim_ui.  Importers:
// hwcomposer.mt6755, libui_ext (both ABIs).  A13 lock() takes uint32_t usage
// and two optional out-params; `this` is the singleton above.
status_t m681_GraphicBufferMapper_lock_int(GraphicBufferMapper* self, buffer_handle_t handle,
                                           int usage, const Rect& bounds, void** vaddr)
        __asm__("_ZN7android19GraphicBufferMapper4lockEPK13native_handleiRKNS_4RectEPPv");
status_t m681_GraphicBufferMapper_lock_int(GraphicBufferMapper* self, buffer_handle_t handle,
                                           int usage, const Rect& bounds, void** vaddr) {
    return self->lock(handle, static_cast<uint32_t>(usage), bounds, vaddr);
}

// void String8::setPathName(const char*) — gone from A13 libutils.  Importer on
// the display path: libui_ext (both ABIs); libcam.client too.  N body
// (system/core/libutils/String8.cpp): copy, drop ONE trailing '/'.  setTo(const
// char*, size_t) is still exported (m95 shims/ui.cpp, nm 2026-09-24).
void m681_String8_setPathName(String8* self, const char* name)
        __asm__("_ZN7android7String811setPathNameEPKc");
void m681_String8_setPathName(String8* self, const char* name) {
    size_t len = strlen(name);
    if (len > 0 && name[len - 1] == '/') len--;
    self->setTo(name, len);
}

}  // namespace android

// ---- Fence::~Fence() ----------------------------------------------------------
// Imported by libgui_ext.so (on the hwcomposer path), libshowlogo,
// libMtkOmxVdecEx; A13 libui does not export it.
// m681, differs from m95: A13 Fence is polymorphic — `virtual ~Fence() =
// default` (frameworks/native/libs/ui/include/ui/Fence.h:151), sizeof 16 on
// arm64 / 12 on arm (probe), vptr at 0, LightRefBase::mCount after it.  N Fence
// had no vtable: mCount at 0, fd at 4, 8 bytes; m95's body (close the fd at
// offset 4) was checked against R and is wrong for A13 objects.
// Who calls it — FACT, lib64/libgui_ext.so GuiExtPoolItem::prepareBuffer
// 0x1d03c-0x1d094: N-inline sp<Fence> copies Fence::NO_FENCE, bumps the count
// with android_atomic_inc(obj + 0), and after the call does
// `if (android_atomic_dec(obj + 0) == 1) { ~Fence(obj); operator delete(obj); }`.
// libgui_ext imports no Fence constructor, so every Fence it sees is an A13
// object and its "count at offset 0" is the low half of the vptr: the balanced
// inc/dec leaves it as it was, and the == 1 branch cannot be taken for an
// 8-byte-aligned vtable address.  So this destructor is expected never to run;
// if it does, the object is not what the blob thinks it is and nothing here
// can destroy it correctly — log and leave it (the blob frees the memory).
// The inline refcounting itself is a hazard no symbol shim can fix — design

extern "C" void _ZN7android5FenceD1Ev(void* self) {
    ALOGE("m681: N-ABI Fence::~Fence() reached for %p — unexpected with A13 Fence objects "
          "(see vendor/meizu/m681/shims/ui_n.cpp)", self);
}
