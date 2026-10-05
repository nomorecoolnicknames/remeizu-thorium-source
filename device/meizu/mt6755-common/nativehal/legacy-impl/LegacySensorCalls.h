// SPDX-License-Identifier: Apache-2.0
#pragma once
#include <cerrno>
#include <cstdint>

namespace meizu {
inline int sensorPollResult(int result, int capacity) {
    if (capacity <= 0) return -EINVAL;
    return result > capacity ? -EPROTO : result;
}

template <typename NativeBatch, typename SetDelay>
int sensorBatch(bool nativeAvailable, int64_t periodNs, int64_t latencyNs,
                NativeBatch nativeBatch, SetDelay setDelay) {
    if (periodNs < 0 || latencyNs < 0) return -EINVAL;
    if (nativeAvailable) return nativeBatch();
    if (latencyNs != 0) return -ENOSYS;
    return setDelay();
}

template <typename NativeFlush>
int sensorFlush(bool nativeAvailable, NativeFlush nativeFlush) {
    return nativeAvailable ? nativeFlush() : -ENOSYS;
}
}
