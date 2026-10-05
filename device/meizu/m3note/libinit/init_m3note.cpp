#include "profile.h"

#include <android-base/file.h>
#include <android-base/logging.h>
#include <cerrno>
#include <cstdint>
#include <unistd.h>

// LOS20 exports this in libinit; the socket property service is not running
// yet when vendor_load_properties is called from PropertyInit.
namespace android::init {
uint32_t InitPropertySet(const std::string&, const std::string&);
}

void vendor_load_properties() {
    std::string compatible;
    if (!android::base::ReadFileToString("/proc/device-tree/compatible", &compatible))
        android::base::ReadFileToString("/sys/firmware/devicetree/base/compatible", &compatible);
    // The common kernel publishes the factory-verified board here. A single-board
    // kernel (the M681 4.9 bring-up line: bat1/bat1k) has no m3note_board module at
    // all; its boot image carries only its own DTB, so the DT compatible is the board.
    // A present but unverified handoff is still refused below.
    constexpr char kIdentity[] = "/sys/module/m3note_board/parameters/identity";
    std::string board, source;
    if (access(kIdentity, F_OK) == 0) {
        std::string handoff;
        android::base::ReadFileToString(kIdentity, &handoff);
        board = meizu::BoardFromHandoff(handoff);
        source = "factory";
    } else if (errno == ENOENT) {
        board = meizu::BoardFromCompatible(compatible);
        source = "dt";
    }
    std::string error;
    if (board.empty() || board != meizu::BoardFromCompatible(compatible) ||
        !meizu::ActivateProfile("/system/vendor", board, &error)) {
        if (error == "profile rollback failed")
            LOG(FATAL) << "M3 Note vendor profile rollback failed";
        LOG(ERROR) << "M3 Note vendor profile unavailable: " << error;
        android::init::InitPropertySet("ro.vendor.meizu.profile", "unknown");
        android::init::InitPropertySet("ro.vendor.meizu.profile_ready", "0");
        return;
    }
    if (android::init::InitPropertySet("ro.vendor.meizu.profile", board) == 0)
        android::init::InitPropertySet("ro.vendor.meizu.profile_ready", "1");
    android::init::InitPropertySet("ro.vendor.meizu.profile_source", source);
    // Board-specific audio configuration: audio_get_configuration_paths()
    // (system/media audio_config.h) searches /vendor/etc/audio/sku_<sku> first.
    android::init::InitPropertySet("ro.boot.product.vendor.sku", board);
}
