// Exact decoded own U10/U20 legacy lights ABI, checked against actual SDK headers.
#include <cstddef>
#include <hardware/lights.h>

static_assert(sizeof(light_state_t) == 20, "Own lights reads a 20-byte state");
static_assert(offsetof(light_state_t, color) == 0, "Own color offset");
static_assert(offsetof(light_state_t, flashMode) == 4, "Own flash mode offset");
static_assert(offsetof(light_state_t, flashOnMS) == 8, "Own flash on offset");
static_assert(offsetof(light_state_t, flashOffMS) == 12, "Own flash off offset");
static_assert(offsetof(light_state_t, brightnessMode) == 16, "Own brightness mode offset");
static_assert(offsetof(hw_module_t, id) == 8, "Own module ID offset");
static_assert(offsetof(hw_device_t, module) == 8, "Own device module offset");

#ifdef __LP64__
static_assert(sizeof(hw_module_t) == 248, "Own ARM64 HMI allocation");
static_assert(offsetof(hw_module_t, methods) == 32, "Own ARM64 method table");
static_assert(sizeof(hw_device_t) == 120, "Own ARM64 common device");
static_assert(offsetof(hw_device_t, close) == 112, "Own ARM64 close callback");
static_assert(offsetof(light_device_t, set_light) == 120, "Own ARM64 set_light callback");
static_assert(sizeof(light_device_t) == 128, "Own ARM64 open allocates 128 bytes");
#else
static_assert(sizeof(hw_module_t) == 128, "Own ARM32 HMI allocation");
static_assert(offsetof(hw_module_t, methods) == 20, "Own ARM32 method table");
static_assert(sizeof(hw_device_t) == 64, "Own ARM32 common device");
static_assert(offsetof(hw_device_t, close) == 60, "Own ARM32 close callback");
static_assert(offsetof(light_device_t, set_light) == 64, "Own ARM32 set_light callback");
static_assert(sizeof(light_device_t) == 68, "Own ARM32 open allocates 68 bytes");
#endif
