# Meizu U20 (u20) — PLANNED. mt6755. Bring up on the m681 base (same platform).
# Stock boot/partition bounds are pinned in BoardConfigStock.mk; live board runtime is UNVERIFIED.
LOCAL_PATH := device/meizu/u20
TARGET_MEIZU_MT675X_DEVICE := u20

include device/meizu/mt6755-common/BoardConfigCommon.mk
include device/meizu/u20/BoardConfigStock.mk

# Required per-board vendor; apply after common so board values are not lost.
include vendor/meizu/u20/BoardConfigVendor.mk

TARGET_BOARD_PLATFORM := mt6755
TARGET_BOOTLOADER_BOARD_NAME := mt6755
BOARD_NAME := u20
TARGET_OTA_ASSERT_DEVICE := u20 U20

# TODO: finish this board kernel/DCT/DTB port; the existing defconfig is a donor.
TARGET_KERNEL_SOURCE := kernel/meizu/mt6755
TARGET_KERNEL_CONFIG := u20_defconfig   # TODO

# DIAGNOSTIC: separate source-graph product, never the M6/m681 donor kernel.
# A strict graph can evaluate this pinned U20 prebuilt without a kernel compile.
ifeq ($(TARGET_PRODUCT),lineage_u20_stockgraph)
TARGET_KERNEL_SOURCE :=
TARGET_KERNEL_CONFIG :=
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_PREBUILT_KERNEL := vendor/meizu/u20/proprietary/boot/Image.gz-dtb
TARGET_RECOVERY_FSTAB := device/meizu/u20/stockgraph/recovery.fstab
BOARD_EGL_CFG := device/meizu/u20/stockgraph/egl.cfg
endif
