# Meizu M3 Note — Global (L91 / l681). Same MT6755 hardware as m681; differs in
# modem / regional blobs and the single-DTB route. WIP (same 3.18 graft target).
LOCAL_PATH := device/meizu/l681
TARGET_MEIZU_MT675X_DEVICE := l681

-include vendor/meizu/l681/BoardConfigVendor.mk
include device/meizu/mt6755-common/BoardConfigCommon.mk

TARGET_BOARD_PLATFORM := mt6755
TARGET_BOOTLOADER_BOARD_NAME := mt6755
BOARD_NAME := l681
TARGET_OTA_ASSERT_DEVICE := l681

TARGET_NO_KERNEL := false
TARGET_KERNEL_SOURCE := kernel/meizu/mt6755
TARGET_KERNEL_CONFIG := l681_defconfig        # TODO: single-dtb 3.18 defconfig
# Same panel as m681 (ili9885 TXD1).

BOARD_BOOTIMAGE_PARTITION_SIZE     := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 2684354560
BOARD_USERDATAIMAGE_PARTITION_SIZE := 11683216896   # TODO: confirm M3 Note eMMC
BOARD_CACHEIMAGE_PARTITION_SIZE    := 452984832     # TODO: confirm M3 Note eMMC

TARGET_SYSTEM_PROP := $(LOCAL_PATH)/system.prop
TARGET_RELEASETOOLS_EXTENSIONS := $(LOCAL_PATH)
BOARD_PROVIDES_RILD := true
ADD_RADIO_FILES := true
