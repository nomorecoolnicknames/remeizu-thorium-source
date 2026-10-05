// SPDX-License-Identifier: Apache-2.0
#pragma once
#include <cstddef>
#include <hardware/fingerprint.h>

// Exact own U10/U20 API0x200 device, decoded independently in both ARM64 HALs.
// Each board orders its screen/lockout extensions differently. The canonical SDK28
// fingerprint_device_t is a different layout and must never be used for calls.
struct MeizuFingerprintDevice {
    hw_device_t common;
    fingerprint_notify_t notify;
    int (*set_notify)(MeizuFingerprintDevice*, fingerprint_notify_t);
    uint64_t (*pre_enroll)(MeizuFingerprintDevice*);
    int (*enroll)(MeizuFingerprintDevice*, const hw_auth_token_t*, uint32_t, uint32_t);
    int (*post_enroll)(MeizuFingerprintDevice*);
#if defined(MZ_FP_U10) && !defined(MZ_FP_U20)
    int (*screen_on)(MeizuFingerprintDevice*);
    int (*screen_off)(MeizuFingerprintDevice*);
    int (*lockout)(MeizuFingerprintDevice*);
    int (*lockout_reset)(MeizuFingerprintDevice*);
#elif defined(MZ_FP_U20) && !defined(MZ_FP_U10)
    int (*screen_off)(MeizuFingerprintDevice*);
    int (*screen_on)(MeizuFingerprintDevice*);
#else
#error Select exactly one verified own U10/U20 fingerprint device layout
#endif
    uint64_t (*get_authenticator_id)(MeizuFingerprintDevice*);
    int (*cancel)(MeizuFingerprintDevice*);
    void* unsupported_enumerate; // calloc leaves this slot zero on each board
    int (*remove)(MeizuFingerprintDevice*, uint32_t, uint32_t);
    int (*set_active_group)(MeizuFingerprintDevice*, uint32_t, const char*);
    int (*authenticate)(MeizuFingerprintDevice*, uint64_t, uint32_t);
#if defined(MZ_FP_U20)
    int (*lockout_reset)(MeizuFingerprintDevice*);
    int (*lockout)(MeizuFingerprintDevice*);
#endif
    void* reserved[4];
};
static_assert(sizeof(void*) == 8, "Own Meizu fingerprint adapter supports verified ARM64 ABI only");
static_assert(sizeof(MeizuFingerprintDevice) == 272, "Own HAL device allocation contract");
#define MZ_FP_OFFSET(member, value) static_assert(offsetof(MeizuFingerprintDevice, member) == value, #member " ABI offset")
MZ_FP_OFFSET(notify,120); MZ_FP_OFFSET(set_notify,128); MZ_FP_OFFSET(pre_enroll,136);
MZ_FP_OFFSET(enroll,144); MZ_FP_OFFSET(post_enroll,152);
#if defined(MZ_FP_U10)
MZ_FP_OFFSET(screen_on,160); MZ_FP_OFFSET(screen_off,168); MZ_FP_OFFSET(lockout,176);
MZ_FP_OFFSET(lockout_reset,184); MZ_FP_OFFSET(get_authenticator_id,192); MZ_FP_OFFSET(cancel,200);
MZ_FP_OFFSET(unsupported_enumerate,208); MZ_FP_OFFSET(remove,216);
MZ_FP_OFFSET(set_active_group,224); MZ_FP_OFFSET(authenticate,232);
#else
MZ_FP_OFFSET(screen_off,160); MZ_FP_OFFSET(screen_on,168); MZ_FP_OFFSET(get_authenticator_id,176);
MZ_FP_OFFSET(cancel,184); MZ_FP_OFFSET(unsupported_enumerate,192); MZ_FP_OFFSET(remove,200);
MZ_FP_OFFSET(set_active_group,208); MZ_FP_OFFSET(authenticate,216);
MZ_FP_OFFSET(lockout_reset,224); MZ_FP_OFFSET(lockout,232);
#endif
#undef MZ_FP_OFFSET
static_assert(offsetof(fingerprint_msg_t,data.enroll.finger.gid)==8, "Own callback group offset");
static_assert(offsetof(fingerprint_msg_t,data.enroll.finger.fid)==12, "Own callback finger offset");
static_assert(offsetof(fingerprint_msg_t,data.enroll.samples_remaining)==16, "Own enrollment count offset");
static_assert(offsetof(fingerprint_msg_t,data.authenticated.hat)==16, "Own auth token offset");
static_assert(sizeof(hw_auth_token_t)==69, "Own authentication token length");

inline bool validMeizuFingerprintDevice(const MeizuFingerprintDevice* d) {
    return d && d->common.tag == HARDWARE_DEVICE_TAG && d->common.version == 0x200 &&
        d->common.close && d->set_notify && d->pre_enroll && d->enroll &&
        d->post_enroll && d->get_authenticator_id && d->cancel && d->remove &&
        d->set_active_group && d->authenticate && !d->unsupported_enumerate;
}
