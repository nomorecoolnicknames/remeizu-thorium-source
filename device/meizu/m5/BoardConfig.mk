# Meizu M5 (m5) — PLANNED. mt6750. Bring up on the meizu_m6 base (same platform).
LOCAL_PATH := device/meizu/m5
TARGET_MEIZU_MT675X_DEVICE := m5

include device/meizu/mt6755-common/BoardConfigCommon.mk

# Required per-board vendor; apply after common so board values are not lost.
include vendor/meizu/m5/BoardConfigVendor.mk

TARGET_BOOTLOADER_BOARD_NAME := mt6750
BOARD_NAME := m5
TARGET_OTA_ASSERT_DEVICE := m5

# TODO: clone the meizu_m6 kernel config/DTB/panel + partition sizes once bring-up starts.
TARGET_KERNEL_SOURCE := kernel/meizu/mt6755
TARGET_KERNEL_CONFIG := m5_defconfig   # TODO
TARGET_BOARD_PLATFORM := mt6750
