/*
 * Copyright 2026 ReMeizu contributors
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 */
#define LOG_TAG "meizu.hardware.camera.provider@2.4-service"
#include <android/hardware/camera/provider/2.4/ICameraProvider.h>
#include <binder/ProcessState.h>
#include <hidl/LegacySupport.h>
#include <hardware/camera_common.h>
#include <stddef.h>
#include <log/log.h>

// Own constructors initialize this standard module prefix and an opaque tail.
// Reject a platform header with a different loader/function-slot contract.
#if defined(__LP64__)
static_assert(sizeof(camera_module_t) == 344, "camera module ARM64 prefix");
static_assert(offsetof(camera_module_t, get_number_of_cameras) == 248, "camera count slot");
static_assert(offsetof(camera_module_t, get_camera_info) == 256, "camera info slot");
static_assert(offsetof(camera_module_t, set_callbacks) == 264, "callback slot");
static_assert(offsetof(camera_module_t, get_vendor_tag_ops) == 272, "vendor-tag slot");
static_assert(offsetof(camera_module_t, open_legacy) == 280, "legacy open slot");
static_assert(offsetof(camera_module_t, set_torch_mode) == 288, "torch slot");
static_assert(offsetof(camera_module_t, init) == 296, "optional init slot");
#else
static_assert(sizeof(camera_module_t) == 176, "camera module ARM32 prefix");
static_assert(offsetof(camera_module_t, get_number_of_cameras) == 128, "camera count slot");
static_assert(offsetof(camera_module_t, get_camera_info) == 132, "camera info slot");
static_assert(offsetof(camera_module_t, set_callbacks) == 136, "callback slot");
static_assert(offsetof(camera_module_t, get_vendor_tag_ops) == 140, "vendor-tag slot");
static_assert(offsetof(camera_module_t, open_legacy) == 144, "legacy open slot");
static_assert(offsetof(camera_module_t, set_torch_mode) == 148, "torch slot");
static_assert(offsetof(camera_module_t, init) == 152, "optional init slot");
#endif

int main() {
    // Own pre-Treble camera uses framework libbinder (including sensorservice).
    // HIDL still uses hwbinder. Registration follows the real provider factory.
    android::ProcessState::initWithDriver("/dev/binder");
    android::ProcessState::self()->startThreadPool();
    return android::hardware::defaultPassthroughServiceImplementation<
        android::hardware::camera::provider::V2_4::ICameraProvider>("legacy/0", 6);
}
