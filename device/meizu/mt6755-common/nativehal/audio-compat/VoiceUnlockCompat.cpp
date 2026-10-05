// SPDX-License-Identifier: Apache-2.0
#include <atomic>
#include <cerrno>
#if defined(__ANDROID__)
#include <log/log.h>
#else
#include <cstdio>
#endif

namespace {
void unavailable() {
    static std::atomic_flag reported = ATOMIC_FLAG_INIT;
    if (!reported.test_and_set()) {
#if defined(__ANDROID__)
        __android_log_print(ANDROID_LOG_WARN, "MeizuAudioCompat",
            "VoiceUnlock backend is unavailable on SDK28; rejecting optional request");
#else
        std::fputs("VoiceUnlock backend is unavailable; rejecting optional request\n", stderr);
#endif
    }
}
}

// The own Flyme libmedia returns TRUE on missing AudioFlinger, and the own
// HAL branches to failure on nonzero getVoiceUnlockDLInstance(). A FALSE
// return here would falsely report an allocated backend and start its reader.
extern "C" bool voiceInstance() asm("_ZN7android11AudioSystem24getVoiceUnlockDLInstanceEv");
extern "C" bool voiceInstance() { unavailable(); return true; }
extern "C" bool voiceStart() asm("_ZN7android11AudioSystem18startVoiceUnlockDLEv");
extern "C" bool voiceStart() { unavailable(); return true; }
extern "C" bool voiceStop() asm("_ZN7android11AudioSystem17stopVoiceUnlockDLEv");
extern "C" bool voiceStop() { unavailable(); return true; }
extern "C" void voiceFree() asm("_ZN7android11AudioSystem25freeVoiceUnlockDLInstanceEv");
extern "C" void voiceFree() {
    // No instance can be allocated through voiceInstance(); no resource to free.
    unavailable();
}
extern "C" int voiceLatency() asm("_ZN7android11AudioSystem23GetVoiceUnlockDLLatencyEv");
extern "C" int voiceLatency() { unavailable(); return -ENOSYS; }
extern "C" int voiceTime(void*) asm("_ZN7android11AudioSystem20GetVoiceUnlockULTimeEPv");
extern "C" int voiceTime(void*) { unavailable(); return -ENOSYS; }
extern "C" int voiceSource(unsigned int, unsigned int) asm("_ZN7android11AudioSystem17SetVoiceUnlockSRCEjj");
extern "C" int voiceSource(unsigned int, unsigned int) { unavailable(); return -ENOSYS; }
extern "C" int voiceRead(void*, unsigned int, void*) asm("_ZN7android11AudioSystem15ReadRefFromRingEPvjS1_");
extern "C" int voiceRead(void*, unsigned int, void*) { unavailable(); return -ENOSYS; }
