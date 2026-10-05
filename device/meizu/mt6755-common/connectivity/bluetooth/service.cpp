// SPDX-License-Identifier: Apache-2.0
#include <android/hardware/bluetooth/1.0/IBluetoothHci.h>
#include <hidl/LegacySupport.h>

int main() {
    using android::hardware::bluetooth::V1_0::IBluetoothHci;
    return android::hardware::defaultPassthroughServiceImplementation<IBluetoothHci>(5);
}
