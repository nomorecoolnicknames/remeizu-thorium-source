# Meizu M6T (m6t) — PLANNED. mt6750. Bring up on the meizu_m6 base (same platform).
LOCAL_PATH := device/meizu/m6t
TARGET_MEIZU_MT675X_DEVICE := m6t

-include vendor/meizu/m6t/BoardConfigVendor.mk
include device/meizu/mt6755-common/BoardConfigCommon.mk

TARGET_BOOTLOADER_BOARD_NAME := mt6750
BOARD_NAME := m6t
TARGET_OTA_ASSERT_DEVICE := m6t

# TODO: clone the meizu_m6 kernel config/DTB/panel + partition sizes once bring-up starts.
TARGET_KERNEL_SOURCE := kernel/meizu/mt6755
TARGET_KERNEL_CONFIG := m6t_defconfig   # TODO
TARGET_BOARD_PLATFORM := mt6750
