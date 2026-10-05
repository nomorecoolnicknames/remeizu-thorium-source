// N-era libbinder symbols for the MT6755 M3 Note blob set on Android 13 — the
// C++ half of libm681shim_base (namespace rules: shims/base_n_c.c).  Needs
// libbinder, which sphal reaches only through the fleet branch of
// system/linkerconfig (sphal.cc, "link libbinder.so from sphal to vndk for
// legacy MTK GPU drivers"); every importer below NEEDs libbinder itself.
#include <binder/IInterface.h>

namespace android {

class String16;

// sp<IBinder> IInterface::asBinder() — the pre-M member, still exported by the
// stock N libbinder; A13 keeps only the static asBinder(const IInterface*) with
// the same body (null -> null, else onAsBinder()).  Importers: libgui_ext,
// libbwc, libpqservice (lib and lib64).  FACT at a call site: lib64/
// libgui_ext.so GuiExtService::regDump 0x12e7c-0x12e8c: x0 = the interface,
// x8 = result slot x29+136 (sret), read back at 0x12e8c.  A free function with
// `self` first has the same register assignment as the member (x8/x0 on arm64,
// r0 = result slot and r1 = this on arm).
sp<IBinder> m681_IInterface_asBinder_legacy(IInterface* self)
        __asm__("_ZN7android10IInterface8asBinderEv");
sp<IBinder> m681_IInterface_asBinder_legacy(IInterface* self) {
    return IInterface::asBinder(self);
}

// static bool PermissionCache::checkCallingPermission(const String16&).
// Importers: libgui_ext, libpqservice, libaal.  The A13 libbinder exports
// PermissionCache only in the system variant; the vendor (VNDK) variant these
// processes get has none — the same wall m95 hit with libpqservice in the Mali
// closure (device/meizu/m95/shims/utils.cpp, 2026-09-06).  Bring-up answer, as
// on m95: grant.  Declared by hand because <binder/PermissionCache.h> is not
// part of the vendor variant.
class PermissionCache {
  public:
    static bool checkCallingPermission(const String16& permission);
};
bool PermissionCache::checkCallingPermission(const String16&) {
    return true;
}

}  // namespace android
