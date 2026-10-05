/* SPDX-License-Identifier: Apache-2.0 */
#define LOG_TAG "meizu-nvramagent-binder-compat"
#include "LegacyServiceManager.h"
#include <dlfcn.h>
#include <log/log.h>
#include <mutex>
#include <cstring>

// Return type is deliberately the old interface. Both the native declaration
// and own call site use an indirect by-value sp return, with the output in x8.
android::sp<meizu::LegacyServiceManager> meizuLegacyDefaultServiceManager()
    __asm__("_ZN7android21defaultServiceManagerEv");

android::sp<meizu::LegacyServiceManager> meizuLegacyDefaultServiceManager() {
    static std::mutex mutex;
    static android::sp<meizu::LegacyServiceManager> facade;
    std::lock_guard<std::mutex> lock(mutex);
    if (facade != nullptr) return facade;

    // libbinder is a declared dependency and must already be mapped. A lookup
    // in its own exact handle bypasses our interposed defaultServiceManager.
    void* handle = dlopen("/system/lib64/libbinder.so", RTLD_NOW | RTLD_NOLOAD);
    if (handle == nullptr) {
        ALOGE("native libbinder is not loaded: %s", dlerror());
        return nullptr;
    }
    void* symbol = dlsym(handle, "_ZN7android21defaultServiceManagerEv");
    Dl_info owner{};
    if (symbol == nullptr || dladdr(symbol, &owner) == 0 || owner.dli_fname == nullptr ||
        std::strcmp(owner.dli_fname, "/system/lib64/libbinder.so") != 0) {
        ALOGE("defaultServiceManager did not resolve to the native libbinder owner");
        dlclose(handle);
        return nullptr;
    }
    auto nativeDefault = reinterpret_cast<meizu::NativeDefaultManager>(symbol);
    auto native = nativeDefault();
    if (native == nullptr) {
        ALOGE("native defaultServiceManager failed");
        dlclose(handle);
        return nullptr;
    }
    facade = new meizu::ServiceManagerFacade(native);
    dlclose(handle); // The executable retains its genuine libbinder dependency.
    return facade;
}
