# Meizu M3 Note — China (M91 / m681). MT6755 (full Helio P10). WIP: 3.18 m6-graft.
# Today the only bootable m681 base is the 3.10.72 stocktruth kernel (LOS 14.1);
# this device entry targets the unified 3.18.140 base (the m6-graft convergence).
LOCAL_PATH := device/meizu/m681
TARGET_MEIZU_MT675X_DEVICE := m681

-include vendor/meizu/m681/BoardConfigVendor.mk
include device/meizu/mt6755-common/BoardConfigCommon.mk

# Full MT6755 — override the common's M6/mt6750 default
TARGET_BOARD_PLATFORM := mt6755
TARGET_BOOTLOADER_BOARD_NAME := mt6755
BOARD_NAME := m681
TARGET_OTA_ASSERT_DEVICE := m681

# Kernel — Phase 1 target: 3.18.140 (m6-graft). Current bootable fallback = 3.10.72.
TARGET_NO_KERNEL := false
TARGET_KERNEL_SOURCE := kernel/meizu/mt6755
TARGET_KERNEL_CONFIG := m681_defconfig        # TODO: 3.18 defconfig from the m6-graft branch
# Panel is in-kernel: CONFIG_CUSTOM_KERNEL_LCM="ili9885_fhd_dsi_vdo_txd1 ..."
# BOARD_MKBOOTIMG_ARGS += --board <m681 id>   # TODO: confirm stock M3 Note boot id

# eMMC layout (M3 Note) — TODO: confirm exact sizes
BOARD_BOOTIMAGE_PARTITION_SIZE     := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 2684354560
BOARD_USERDATAIMAGE_PARTITION_SIZE := 11683216896   # TODO: confirm M3 Note eMMC
BOARD_CACHEIMAGE_PARTITION_SIZE    := 452984832     # TODO: confirm M3 Note eMMC

TARGET_SYSTEM_PROP := $(LOCAL_PATH)/system.prop
TARGET_RELEASETOOLS_EXTENSIONS := $(LOCAL_PATH)
BOARD_PROVIDES_RILD := true
ADD_RADIO_FILES := true
