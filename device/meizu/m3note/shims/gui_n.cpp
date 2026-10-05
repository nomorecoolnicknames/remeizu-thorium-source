// N-era libgui/libui symbols for the MT6755 M3 Note blob set on Android 13.
//
// Built into libgui_mt6755fwd, the /vendor/lib{,64}/libgui.so forwarder
// (Android.bp).  The blobs NEED "libgui.so" by that name, so every symbol
// defined here is found in their local group before libgui_vendor.so, which
// the forwarder NEEDs for everything else (bionic binds against the whole
// breadth-first load group).  libsensor_vendor is NEEDed too: N libgui still
// carried SensorManager/SensorEventQueue, which moved to libsensor in O.
//
// What is missing is MEASURED, not guessed: nm -D of every consumer of
// libgui.so in vendor/meizu/m681 against the stock N libgui (Flyme 6.2.0.2A)
// and the A13 libgui_vendor built for m95 — 26 (ELF32) / 23 (ELF64) symbols,

// ones are already exported by libsensor_vendor under the N names; the rest are
// below.  IDumpTunnel::asInterface lived in N libui (stock
// system/lib64/libui.so defines it), A13 libui has none; libgui_ext.so also
// NEEDs libgui.so, so defining it here resolves it.
//
// Every function that hands control back to a blob was checked at the call
// site (llvm-objdump of the m681 blob), per the m95 rule: what the blob
// allocates and what it reads back.  Most of the file is m95's
// device/meizu/m95/shims/{sf,gui,sensor}.cpp (commit 8b1d268 and earlier),
// re-checked against the m681 blobs; the differences are marked "m681".
#include <stdint.h>
#include <sys/eventfd.h>

#include <log/log.h>

namespace android {
class String8;
class String16;
class Rect;
class GraphicBuffer;
class BufferItemConsumer;
class ConsumerBase;
class IGraphicBufferProducer;
class IGraphicBufferConsumer;
class SensorManager;
template <typename T>
class sp;
}  // namespace android

namespace {
// Returned like android::sp<T>: one pointer, but with a user-provided
// destructor, i.e. in memory through the hidden result pointer (x8 on arm64;
// r0 on arm32, before `this`), exactly as the C++ callers expect.  Returning a
// trivially-copyable struct instead would come back in x0/r0 and leave the
// caller's slot unwritten (m95 shims/sf.cpp, getBuiltInDisplay fix).
struct SpRet {
    void* p;
    SpRet() : p(nullptr) {}
    ~SpRet() {}
};

// N/O/P DisplayInfo (frameworks/native/include/ui/DisplayInfo.h of that era),
// 48 bytes on arm and arm64 (int64 members are 8-aligned on both).
struct DisplayInfoN {
    uint32_t w;
    uint32_t h;
    float xdpi;
    float ydpi;
    float fps;
    float density;
    uint8_t orientation;
    bool secure;
    int64_t appVsyncOffset;
    int64_t presentationDeadline;
};
static_assert(sizeof(DisplayInfoN) == 48, "N DisplayInfo is 48 bytes");
}  // namespace

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type-c-linkage"

extern "C" {

// ---- SurfaceComposerClient / SurfaceControl (N global-transaction API) -----
// Callers: libaal, libshowlogo, thermalindicator (and libgui_ext/libperfservice
// for the display queries).  A vendor process cannot reach SurfaceFlinger at
// all: vendor libgui talks to /dev/vndbinder, where SF is not registered, and
// ComposerService would wait for it forever (m95 shims/sf.cpp).  So these are
// inert: no surface is ever created, the transaction calls are no-ops.

// static void openGlobalTransaction()
void _ZN7android21SurfaceComposerClient21openGlobalTransactionEv() {}

// static void closeGlobalTransaction(bool synchronous)
void _ZN7android21SurfaceComposerClient22closeGlobalTransactionEb(bool /*synchronous*/) {}

// sp<SurfaceControl> createSurface(const String8&, uint32_t w, uint32_t h,
//                                  PixelFormat, uint32_t flags)  -> null
// m681: returned through the result slot (m95 returned it in x0, which only
// satisfied dlopen); a caller that uses the value now sees a real null sp.
SpRet _ZN7android21SurfaceComposerClient13createSurfaceERKNS_7String8Ejjij(
        void* /*self*/, const android::String8& /*name*/, uint32_t /*w*/, uint32_t /*h*/,
        int32_t /*format*/, uint32_t /*flags*/) {
    return SpRet();
}

// static void setDisplayProjection(const sp<IBinder>&, uint32_t orientation,
//                                  const Rect& layerStackRect, const Rect& displayRect)
void _ZN7android21SurfaceComposerClient20setDisplayProjectionERKNS_2spINS_7IBinderEEEjRKNS_4RectES8_(
        const void* /*token*/, uint32_t /*orientation*/, const android::Rect& /*layerStack*/,
        const android::Rect& /*display*/) {}

// SurfaceControl: status_t setLayer(uint32_t), show(), hide(),
// setSize(uint32_t, uint32_t) -> NO_ERROR; void clear().
// Only ever reached through a null SurfaceControl (createSurface above).
int32_t _ZN7android14SurfaceControl8setLayerEj(void* /*self*/, uint32_t /*layer*/) { return 0; }
int32_t _ZN7android14SurfaceControl4showEv(void* /*self*/) { return 0; }
int32_t _ZN7android14SurfaceControl4hideEv(void* /*self*/) { return 0; }
int32_t _ZN7android14SurfaceControl7setSizeEjj(void* /*self*/, uint32_t /*w*/, uint32_t /*h*/) {
    return 0;
}
void _ZN7android14SurfaceControl5clearEv(void* /*self*/) {}

// m681: sp<Surface> SurfaceControl::getSurface() const -> null (not in m95's
// list; libaal, libshowlogo and thermalindicator import it).
SpRet _ZNK7android14SurfaceControl10getSurfaceEv(const void* /*self*/) {
    return SpRet();
}

// static sp<IBinder> getBuiltInDisplay(int32_t id) -> null sp through the
// result slot.  FACT (m681 lib64/libperfservice.so getDisplayResolution
// 0x8c4c-0x8ca0): result slot x8 = sp+56, then `ldr x8,[sp,#56]; cbz x8` —
// null is handled; lib64/libgui_ext.so GuiExtPool::alloc 0x1d688-0x1d68c
// passes x8 = x29+200 the same way.
SpRet _ZN7android21SurfaceComposerClient17getBuiltInDisplayEi(int32_t /*id*/) {
    return SpRet();
}

// static status_t getDisplayInfo(const sp<IBinder>&, DisplayInfo*) — gone in S.
// FACT (m681 blobs): both callers read only w and h back —
//   lib64/libperfservice.so 0x8c70-0x8c78: x1 = sp (a 56-byte area below the
//     result slot at sp+56), then `ldp w3, w4, [sp]`;
//   lib64/libgui_ext.so 0x1d69c-0x1d6b4: x1 = x29+232, then
//     `ldr w16,[x29,#232]; ldr w17,[x29,#236]`.
// Values, m681: 1080 x 1920 (BoardConfig.mk TARGET_SCREEN_*, FACT);
//   fps 57.16 — what SurfaceFlinger paced at on LOS16 from the LK atag
//   `fps=5716` (m681/docs/M681_DISPLAY_KNOWLEDGE_INDEX.md:22);
//   density 3.0 = ro.sf.lcd_density 480 / 160 (stock build.prop, FACT);
//   xdpi/ydpi 480.0 — INFERENCE, copied from the density because no m681 HWC
//   dump of the real dpi is on disk; no caller reads them (above);
//   appVsyncOffset / presentationDeadline — m95's values (INFERENCE, same MTK
//   HWC generation), likewise unread.
int32_t _ZN7android21SurfaceComposerClient14getDisplayInfoERKNS_2spINS_7IBinderEEEPNS_11DisplayInfoE(
        const void* /*display*/, DisplayInfoN* info) {
    if (info == nullptr) return -22;  // BAD_VALUE
    info->w = 1080;
    info->h = 1920;
    info->xdpi = 480.0f;
    info->ydpi = 480.0f;
    info->fps = 57.16f;
    info->density = 3.0f;
    info->orientation = 0;
    info->secure = true;
    info->appVsyncOffset = 1000000;
    info->presentationDeadline = 16567262;
    return 0;  // NO_ERROR
}

// static sp<IDumpTunnel> IDumpTunnel::asInterface(const sp<IBinder>&) -> null.
// FACT: defined by N libui (stock system/lib64/libui.so), absent from A13
// libui; imported by libgui_ext.so (needed by hwcomposer.mt6755.so).  Caller
// BnGuiExtService::onTransact 0x11360-0x113b0: result slot x8 = x29+104, then
// `ldr x6,[x29,#104]; cbz x6` — null handled.
SpRet _ZN7android11IDumpTunnel11asInterfaceERKNS_2spINS_7IBinderEEE(const void* /*binder*/) {
    return SpRet();
}

// ---- BufferQueue / consumers ------------------------------------------------
// A13 implementations (libgui_vendor, exports checked with nm on the m95 build).
void _ZN7android11BufferQueue17createBufferQueueEPNS_2spINS_22IGraphicBufferProducerEEEPNS1_INS_22IGraphicBufferConsumerEEEb(
        android::sp<android::IGraphicBufferProducer>*, android::sp<android::IGraphicBufferConsumer>*,
        bool);
void _ZN7android12ConsumerBase7setNameERKNS_7String8E(android::ConsumerBase*,
                                                      const android::String8&);
SpRet _ZNK7android10GLConsumer16getCurrentBufferEPi(const void* self, int* outSlot);

// N: static void createBufferQueue(sp<IGBP>*, sp<IGBC>*, const sp<IGraphicBufferAlloc>&).
// Out-parameters only, nothing allocated by the caller; the allocator argument
// is dropped (A13 allocates internally).  Callers: libgui_ext, libeffecthal.base.
void _ZN7android11BufferQueue17createBufferQueueEPNS_2spINS_22IGraphicBufferProducerEEEPNS1_INS_22IGraphicBufferConsumerEEERKNS1_INS_19IGraphicBufferAllocEEE(
        android::sp<android::IGraphicBufferProducer>* outProducer,
        android::sp<android::IGraphicBufferConsumer>* outConsumer, const void* /*allocator*/) {
    _ZN7android11BufferQueue17createBufferQueueEPNS_2spINS_22IGraphicBufferProducerEEEPNS1_INS_22IGraphicBufferConsumerEEEb(
            outProducer, outConsumer, false);
}

// N: BufferItemConsumer::setName — A13 keeps ConsumerBase::setName only;
// BufferItemConsumer derives from it as its first, non-virtual base.
void _ZN7android18BufferItemConsumer7setNameERKNS_7String8E(android::BufferItemConsumer* self,
                                                            const android::String8& name) {
    _ZN7android12ConsumerBase7setNameERKNS_7String8E(
            reinterpret_cast<android::ConsumerBase*>(self), name);
}

// N: sp<GraphicBuffer> GLConsumer::getCurrentBuffer() const; A13 takes int* outSlot.
// Result slot handed straight through (C++17 guaranteed copy elision).
SpRet _ZNK7android10GLConsumer16getCurrentBufferEv(const void* self) {
    return _ZNK7android10GLConsumer16getCurrentBufferEPi(self, nullptr);
}

// m681: N BufferItemConsumer(const sp<IGBC>&, uint32_t usage, int bufferCount,
// bool controlledByApp) is NOT forwarded to the A13 constructor, unlike m95.
// FACT: the blob allocates the object itself with the N size —
// lib64/libeffecthal.base.so EffectHalClient::addBufferQueue 0x259a8:
// `mov w0, #1640; bl _Znwm` — while sizeof(A13 BufferItemConsumer) is 1704 on
// arm64 (compiled probe with the vendor flags of the m95 build, 2026-09-25).
// Constructing into that block overruns the heap by 64 bytes.  Abort loudly;
// only the camera effect path (EffectHalClient) reaches it.
void _ZN7android18BufferItemConsumerC1ERKNS_2spINS_22IGraphicBufferConsumerEEEjib(
        void* /*self*/, const void* /*consumer*/, uint32_t /*usage*/, int /*bufferCount*/,
        bool /*controlledByApp*/) {
    LOG_ALWAYS_FATAL("m681: legacy BufferItemConsumer(sp<IGBC>, uint32_t, int, bool) called "
                     "(camera effect HAL); the N-sized allocation (1640 B on arm64) cannot "
                     "hold an A13 BufferItemConsumer (1704 B)");
}

// N: Surface(const sp<IGraphicBufferProducer>&, bool controlledByApp) — same
// story, as on m95.  FACT: lib64/libeffecthal.base.so allocates 3536 bytes
// before the call (0x27370, 0x291e0: `mov w0, #3536; bl _Znwm`), A13
// sizeof(Surface) is 8168 on arm64 (same probe).
void _ZN7android7SurfaceC1ERKNS_2spINS_22IGraphicBufferProducerEEEb(
        void* /*self*/, const void* /*bufferProducer*/, bool /*controlledByApp*/) {
    LOG_ALWAYS_FATAL("m681: legacy Surface(sp<IGraphicBufferProducer>, bool) called "
                     "(camera effect HAL); the N-sized allocation (3536 B on arm64) cannot "
                     "hold an A13 Surface (8168 B)");
}

// ---- Sensors (N libgui, O+ libsensor) ---------------------------------------
// libsensor_vendor (hardware/lineage/compat) already exports under the N names:
// SensorManager::getInstanceForPackage, getDefaultSensor,
// createEventQueue(String8, int), SensorEventQueue::read/enableSensor/
// disableSensor/setEventRate (nm, m95 build).  Two are missing:

// int SensorEventQueue::getFd() const.  The compat queue wraps an opaque NDK
// ASensorEventQueue and has no descriptor; -1 crashed m95's camera sensor
// listener inside Looper::pollInner (tombstone 2026-09-24 21:22).  A valid
// descriptor that never becomes readable: the Looper accepts it, the listener
// gets no events, nothing crashes (m95 shims/sensor.cpp, verbatim logic).
// Callers here: lib{,64}/libcam.utils.sensorlistener.so, lib/libmpe.sensorlistener.so.
int _ZNK7android16SensorEventQueue5getFdEv(const void* /*self*/) {
    static const int fd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
    ALOGW("m681: SensorEventQueue::getFd() has no real descriptor on the compat libsensor, "
          "returning a silent eventfd (%d)", fd);
    return fd;
}

// m681: SensorManager::SensorManager(const String16& opPackageName), N public
// constructor; the compat class only has a private default one, exported as
// _ZN7android13SensorManagerC1Ev.  Caller: lib/libmpe.sensorlistener.so (ELF32,
// MPED), which builds its own per-package map.  FACT (llvm-objdump
// --triple=thumbv7 of that blob, 0x3334-0x333e): `movs r0, #40; blx _Znwj;
// ... blx <this ctor>` — 40 bytes; sizeof(compat SensorManager) is 16 on arm
// (and 64 on arm64; compiled probe, hardware/lineage/compat/libsensor/
// SensorManager.h), so the compat object fits.  The package name is dropped:
// the compat manager is not per-package.  No 64-bit caller exists.
void _ZN7android13SensorManagerC1Ev(android::SensorManager* self);
void _ZN7android13SensorManagerC1ERKNS_8String16E(android::SensorManager* self,
                                                  const android::String16& /*opPackageName*/) {
    _ZN7android13SensorManagerC1Ev(self);
}

}  // extern "C"

#pragma clang diagnostic pop
