// android::AudioSystem::getDeviceConnectionState(audio_devices_t, const char*)
// for audio.primary.mt6755.so (Nougat MTK HAL of the M681 profile, both
// ABIs).
//
// FACT (symbol audit 2026-10-05 of the HAL against the u3 image plus the M681
// profile and the vendor libtinyxml/libtinycompress builds): this is the
// HAL's only unresolved import. It comes from the Nougat MTK libmedia; the
// Android 13 libmedia.so the HAL NEEDs has no AudioSystem at all (it moved to
// libaudioclient, and the T form takes a device name and a format), so the
// HAL fails to dlopen and the audio service has no primary module.
//
// Same answer as the m5c A13 shim (wt/device_m5c_treble treble/audiosystem.cpp,
// STATIC/STREAM PCM played there) and LOS 16 before it:
// AUDIO_POLICY_DEVICE_STATE_UNAVAILABLE (0) - the HAL then only believes the
// devices the policy announces through set_parameters. The return type is not
// part of the mangled name; the declaration reproduces the import exactly
// (_ZN7android11AudioSystem24getDeviceConnectionStateEjPKc).
#include <stdint.h>

namespace android {

class AudioSystem {
  public:
    static int getDeviceConnectionState(uint32_t device, const char* address);
};

int AudioSystem::getDeviceConnectionState(uint32_t, const char*) { return 0; }

}  // namespace android
