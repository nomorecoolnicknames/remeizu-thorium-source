/* SPDX-License-Identifier: Apache-2.0 */
#pragma once
#include <binder/IServiceManager.h>
#include <binder/IInterface.h>
#include <binder/Binder.h>
#include <utils/RefBase.h>
#include <utils/String16.h>
#include <utils/Vector.h>
#include <type_traits>

namespace meizu {
// Own Android 6 callers use these exact four virtual slots. The extra SDK28
// dumpsys arguments must be supplied by a native caller, not read from an
// uninitialized argument register in the proprietary caller.
class LegacyServiceManager : public android::IInterface {
public:
    virtual const android::String16& getInterfaceDescriptor() const = 0;
    virtual android::sp<android::IBinder> getService(const android::String16&) const = 0;
    virtual android::sp<android::IBinder> checkService(const android::String16&) const = 0;
    virtual android::status_t addService(const android::String16&,
                                         const android::sp<android::IBinder>&,
                                         bool allowIsolated) = 0;
    virtual android::Vector<android::String16> listServices() = 0;
protected:
    ~LegacyServiceManager() override = default;
};

class ServiceManagerFacade final : public LegacyServiceManager {
public:
    explicit ServiceManagerFacade(const android::sp<android::IServiceManager>& native)
        : mNative(native), mBinder(android::IInterface::asBinder(native)) {}
    const android::String16& getInterfaceDescriptor() const override {
        return android::IServiceManager::descriptor;
    }
    android::sp<android::IBinder> getService(const android::String16& name) const override {
        return mNative->getService(name);
    }
    android::sp<android::IBinder> checkService(const android::String16& name) const override {
        return mNative->checkService(name);
    }
    android::status_t addService(const android::String16& name,
                                 const android::sp<android::IBinder>& service,
                                 bool allowIsolated) override {
        return mNative->addService(name, service, allowIsolated,
                                  android::IServiceManager::DUMP_FLAG_PRIORITY_DEFAULT);
    }
    android::Vector<android::String16> listServices() override {
        return mNative->listServices(android::IServiceManager::DUMP_FLAG_PRIORITY_ALL);
    }
protected:
    android::IBinder* onAsBinder() override { return mBinder.get(); }
private:
    android::sp<android::IServiceManager> mNative;
    android::sp<android::IBinder> mBinder;
};

// Exact own allocation: interface at0, BBinder at8, shared RefBase at32, 48B.
// This abstract layout owner tests the real native bases without inventing a
// proprietary NvRAMAgent method implementation or altering native Binder.
class LegacyNvramBinderLayout : public android::IInterface, public android::BBinder {};
using NativeDefaultManager = android::sp<android::IServiceManager> (*)();
static_assert(std::is_same<decltype(&android::defaultServiceManager), NativeDefaultManager>::value,
              "native defaultServiceManager by-value strong pointer return ABI");
#if defined(__aarch64__) || defined(MEIZU_BINDER_HOST_CONTRACT_TEST)
// The explicitly named host test validates language/header contracts only.
// Actual Android admission requires this same source compiled for ARM64.
static_assert(sizeof(android::RefBase) == 16, "own RefBase prefix");
static_assert(sizeof(android::IInterface) == 24, "own interface prefix");
static_assert(sizeof(android::BBinder) == 40, "own BBinder prefix");
static_assert(sizeof(LegacyNvramBinderLayout) == 48, "own NvRAMAgent allocation");
static_assert(sizeof(LegacyServiceManager) == 24, "own legacy manager interface prefix");
static_assert(sizeof(android::sp<LegacyServiceManager>) == 8, "own indirect return slot");
static_assert(sizeof(android::sp<android::IServiceManager>) == 8, "native indirect return slot");
static_assert(android::IServiceManager::DUMP_FLAG_PRIORITY_DEFAULT == 8, "native add flag");
static_assert(android::IServiceManager::DUMP_FLAG_PRIORITY_ALL == 15, "native list flags");
#else
#error This adapter is admitted only for the exact own ARM64 NvRAMAgent executable
#endif
} // namespace meizu
