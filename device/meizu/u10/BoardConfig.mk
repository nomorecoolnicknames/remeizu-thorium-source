# Meizu U10 (u10) — PLANNED. mt6750. Bring up on the meizu_m6 base (same platform).
# Stock boot/partition bounds are pinned in BoardConfigStock.mk; live board runtime is UNVERIFIED.
LOCAL_PATH := device/meizu/u10
TARGET_MEIZU_MT675X_DEVICE := u10

include device/meizu/mt6755-common/BoardConfigCommon.mk
include device/meizu/u10/BoardConfigStock.mk

# Required per-board vendor; apply after common so board values are not lost.
include vendor/meizu/u10/BoardConfigVendor.mk

TARGET_BOOTLOADER_BOARD_NAME := mt6750
BOARD_NAME := u10
TARGET_OTA_ASSERT_DEVICE := u10 U10

# TODO: finish this board kernel/DCT/DTB port; the existing defconfig is a donor.
TARGET_KERNEL_SOURCE := kernel/meizu/mt6755
TARGET_KERNEL_CONFIG := u10_defconfig   # TODO
TARGET_BOARD_PLATFORM := mt6750

# DIAGNOSTIC: own U10 kernel and board core inputs, independent of M6/U20 donors.
ifeq ($(TARGET_PRODUCT),lineage_u10_stockgraph)
TARGET_KERNEL_SOURCE :=
TARGET_KERNEL_CONFIG :=
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_PREBUILT_KERNEL := vendor/meizu/u10/proprietary/boot/Image.gz-dtb
TARGET_RECOVERY_FSTAB := device/meizu/u10/stockgraph/recovery.fstab
BOARD_EGL_CFG := device/meizu/u10/stockgraph/egl.cfg
endif
