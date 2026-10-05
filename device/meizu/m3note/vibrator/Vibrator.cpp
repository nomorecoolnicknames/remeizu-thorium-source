// SPDX-License-Identifier: Apache-2.0
// IVibrator (AIDL V2) over the LED-class vibrator of the M3 Note 4.9 kernel:
// /sys/class/leds/vibrator/duration (ms), then activate=1; off is activate=0.
// Only on/off and four fixed-length effects; no amplitude, composition or PWLE.

#include <aidl/android/hardware/vibrator/BnVibrator.h>
#include <android-base/file.h>
#include <android-base/logging.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>

#include <thread>

namespace aidl::android::hardware::vibrator {
namespace {

constexpr char kActivate[] = "/sys/class/leds/vibrator/activate";
constexpr char kDuration[] = "/sys/class/leds/vibrator/duration";

ndk::ScopedAStatus Unsupported() {
    return ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
}

bool Write(const char* path, const std::string& value) {
    if (::android::base::WriteStringToFile(value, path)) return true;
    PLOG(ERROR) << "write " << value << " > " << path;
    return false;
}

int32_t EffectMs(Effect effect) {
    switch (effect) {
        case Effect::TICK: return 15;
        case Effect::CLICK: return 30;
        case Effect::HEAVY_CLICK: return 50;
        case Effect::DOUBLE_CLICK: return 60;
        default: return -1;
    }
}

void NotifyLater(int32_t ms, const std::shared_ptr<IVibratorCallback>& callback) {
    if (!callback) return;
    std::thread([ms, callback] {
        usleep(ms * 1000);
        if (!callback->onComplete().isOk()) LOG(ERROR) << "onComplete failed";
    }).detach();
}

}  // namespace

class Vibrator : public BnVibrator {
  public:
    ndk::ScopedAStatus getCapabilities(int32_t* caps) override {
        *caps = IVibrator::CAP_ON_CALLBACK | IVibrator::CAP_PERFORM_CALLBACK;
        return ndk::ScopedAStatus::ok();
    }
    ndk::ScopedAStatus off() override {
        return Write(kActivate, "0") ? ndk::ScopedAStatus::ok()
                                     : ndk::ScopedAStatus::fromExceptionCode(EX_SERVICE_SPECIFIC);
    }
    ndk::ScopedAStatus on(int32_t ms, const std::shared_ptr<IVibratorCallback>& cb) override {
        if (ms <= 0) return off();
        if (!Write(kDuration, std::to_string(ms)) || !Write(kActivate, "1"))
            return ndk::ScopedAStatus::fromExceptionCode(EX_SERVICE_SPECIFIC);
        NotifyLater(ms, cb);
        return ndk::ScopedAStatus::ok();
    }
    ndk::ScopedAStatus perform(Effect effect, EffectStrength, const std::shared_ptr<IVibratorCallback>& cb,
                               int32_t* ms) override {
        const int32_t length = EffectMs(effect);
        if (length < 0) return Unsupported();
        auto status = on(length, cb);
        if (status.isOk()) *ms = length;
        return status;
    }
    ndk::ScopedAStatus getSupportedEffects(std::vector<Effect>* effects) override {
        *effects = {Effect::TICK, Effect::CLICK, Effect::HEAVY_CLICK, Effect::DOUBLE_CLICK};
        return ndk::ScopedAStatus::ok();
    }
    ndk::ScopedAStatus setAmplitude(float) override { return Unsupported(); }
    ndk::ScopedAStatus setExternalControl(bool) override { return Unsupported(); }
    ndk::ScopedAStatus getCompositionDelayMax(int32_t*) override { return Unsupported(); }
    ndk::ScopedAStatus getCompositionSizeMax(int32_t*) override { return Unsupported(); }
    ndk::ScopedAStatus getSupportedPrimitives(std::vector<CompositePrimitive>* p) override {
        p->clear();
        return ndk::ScopedAStatus::ok();
    }
    ndk::ScopedAStatus getPrimitiveDuration(CompositePrimitive, int32_t*) override { return Unsupported(); }
    ndk::ScopedAStatus compose(const std::vector<CompositeEffect>&,
                               const std::shared_ptr<IVibratorCallback>&) override { return Unsupported(); }
    ndk::ScopedAStatus getSupportedAlwaysOnEffects(std::vector<Effect>* e) override {
        e->clear();
        return ndk::ScopedAStatus::ok();
    }
    ndk::ScopedAStatus alwaysOnEnable(int32_t, Effect, EffectStrength) override { return Unsupported(); }
    ndk::ScopedAStatus alwaysOnDisable(int32_t) override { return Unsupported(); }
    ndk::ScopedAStatus getResonantFrequency(float*) override { return Unsupported(); }
    ndk::ScopedAStatus getQFactor(float*) override { return Unsupported(); }
    ndk::ScopedAStatus getFrequencyResolution(float*) override { return Unsupported(); }
    ndk::ScopedAStatus getFrequencyMinimum(float*) override { return Unsupported(); }
    ndk::ScopedAStatus getBandwidthAmplitudeMap(std::vector<float>*) override { return Unsupported(); }
    ndk::ScopedAStatus getPwlePrimitiveDurationMax(int32_t*) override { return Unsupported(); }
    ndk::ScopedAStatus getPwleCompositionSizeMax(int32_t*) override { return Unsupported(); }
    ndk::ScopedAStatus getSupportedBraking(std::vector<Braking>* b) override {
        b->clear();
        return ndk::ScopedAStatus::ok();
    }
    ndk::ScopedAStatus composePwle(const std::vector<PrimitivePwle>&,
                                   const std::shared_ptr<IVibratorCallback>&) override { return Unsupported(); }
};

}  // namespace aidl::android::hardware::vibrator

int main() {
    ABinderProcess_setThreadPoolMaxThreadCount(0);
    auto vibrator = ndk::SharedRefBase::make<aidl::android::hardware::vibrator::Vibrator>();
    const std::string name = std::string() + aidl::android::hardware::vibrator::Vibrator::descriptor + "/default";
    CHECK_EQ(AServiceManager_addService(vibrator->asBinder().get(), name.c_str()), STATUS_OK);
    ABinderProcess_joinThreadPool();
    return EXIT_FAILURE;
}
