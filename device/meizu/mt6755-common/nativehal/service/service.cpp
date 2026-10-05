// SPDX-License-Identifier: Apache-2.0
#include <android/hardware/sensors/1.0/ISensors.h>
#include <hidl/LegacySupport.h>

int main() {
    using android::hardware::sensors::V1_0::ISensors;
    return android::hardware::defaultPassthroughServiceImplementation<ISensors>(2);
}
