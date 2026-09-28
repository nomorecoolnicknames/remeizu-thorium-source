# Meizu M5 Note (m5note) — PLANNED. mt6755. Bring up on the m681 base (same platform).
LOCAL_PATH := device/meizu/m5note
TARGET_MEIZU_MT675X_DEVICE := m5note

include device/meizu/mt6755-common/BoardConfigCommon.mk

# Required per-board vendor; apply after common so board values are not lost.
include vendor/meizu/m5note/BoardConfigVendor.mk

TARGET_BOARD_PLATFORM := mt6755
TARGET_BOOTLOADER_BOARD_NAME := mt6755
BOARD_NAME := m5note
TARGET_OTA_ASSERT_DEVICE := m5note

# TODO: clone the m681 kernel config/DTB/panel + partition sizes once bring-up starts.
TARGET_KERNEL_SOURCE := kernel/meizu/mt6755
TARGET_KERNEL_CONFIG := m5note_defconfig   # TODO
