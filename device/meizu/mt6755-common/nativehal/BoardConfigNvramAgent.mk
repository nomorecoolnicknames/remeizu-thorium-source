# Only the two proven own ARM64 Android 6 service-manager callers.
TARGET_LD_SHIM_LIBS += \
    /system/bin/nvram_agent_binder|libmeizu_nvramagent_binder_compat.so \
    /system/bin/goodixfingerprintd|libmeizu_nvramagent_binder_compat.so
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/nativehal/nvram-agent-sepolicy
