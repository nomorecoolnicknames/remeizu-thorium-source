# Meizu M3s (m3s) — PLANNED. mt6750. Bring up on the meizu_m6 base (same platform).
# Stock boot/partition bounds are pinned in BoardConfigStock.mk; live board runtime is UNVERIFIED.
LOCAL_PATH := device/meizu/m3s
TARGET_MEIZU_MT675X_DEVICE := m3s

include device/meizu/mt6755-common/BoardConfigCommon.mk
include device/meizu/m3s/BoardConfigStock.mk

# Required per-board vendor; apply after common so board values are not lost.
include vendor/meizu/m3s/BoardConfigVendor.mk

TARGET_BOOTLOADER_BOARD_NAME := mt6750
BOARD_NAME := m3s
TARGET_OTA_ASSERT_DEVICE := m3s M3s

# TODO: finish this board kernel/DCT/DTB port; the existing defconfig is a donor.
TARGET_KERNEL_SOURCE := kernel/meizu/mt6755
TARGET_KERNEL_CONFIG := m3s_defconfig   # TODO
TARGET_BOARD_PLATFORM := mt6750

# DIAGNOSTIC: exact M3s/Y15 stock 3.10 kernel; no donor kernel build.
ifeq ($(TARGET_PRODUCT),lineage_m3s_stockgraph)
TARGET_KERNEL_SOURCE :=
TARGET_KERNEL_CONFIG :=
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_PREBUILT_KERNEL := vendor/meizu/m3s/proprietary/boot/Image.gz-dtb
TARGET_RECOVERY_FSTAB := device/meizu/m3s/stockgraph/recovery.fstab
BOARD_EGL_CFG := device/meizu/m3s/stockgraph/egl.cfg
endif
