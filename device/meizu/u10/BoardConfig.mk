# Meizu U10 (u10) — PLANNED. mt6750. Bring up on the meizu_m6 base (same platform).
# Stock boot/partition bounds are pinned in BoardConfigStock.mk; live board runtime is UNVERIFIED.
LOCAL_PATH := device/meizu/u10
TARGET_MEIZU_MT675X_DEVICE := u10

include device/meizu/mt6755-common/BoardConfigCommon.mk
include device/meizu/u10/BoardConfigStock.mk

# Required per-board vendor; apply after common so board values are not lost.
include vendor/meizu/u10/BoardConfigVendor.mk
include device/meizu/mt6755-common/nativehal/BoardConfigSensors.mk
include device/meizu/mt6755-common/nativehal/BoardConfigAudio.mk

TARGET_BOOTLOADER_BOARD_NAME := mt6750
BOARD_NAME := u10
TARGET_OTA_ASSERT_DEVICE := u10,U10

TARGET_SCREEN_WIDTH := 720
TARGET_SCREEN_HEIGHT := 1280

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

ifeq ($(TARGET_PRODUCT),lineage_u10)
include device/meizu/u10/native-kernel.mk
endif

ifeq ($(TARGET_PRODUCT),lineage_u10)
TARGET_RECOVERY_FSTAB := device/meizu/u10/stockgraph/recovery.fstab
BOARD_EGL_CFG := device/meizu/u10/stockgraph/egl.cfg
include device/meizu/mt6755-common/nativehal/BoardConfigPeripherals.mk
include device/meizu/mt6755-common/nativehal/BoardConfigIcu55.mk
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/connectivity/sepolicy
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/connectivity/manifest-connectivity.xml
endif

ifeq ($(TARGET_PRODUCT),lineage_u10)
include device/meizu/mt6755-common/nativehal/BoardConfigFingerprint.mk
include device/meizu/mt6755-common/nativehal/BoardConfigRadio.mk
endif

ifeq ($(TARGET_PRODUCT),lineage_u10)
include device/meizu/mt6755-common/nativehal/BoardConfigGnss.mk
include device/meizu/mt6755-common/nativehal/BoardConfigGraphics.mk
include device/meizu/mt6755-common/nativehal/BoardConfigLights.mk
include device/meizu/mt6755-common/nativehal/BoardConfigThermal.mk
include device/meizu/mt6755-common/nativehal/BoardConfigFirmware.mk
ifeq ($(MEIZU_NATIVE_CAMERA_ABI_VERIFIED),true)
include device/meizu/mt6755-common/nativehal/BoardConfigCamera.mk
include device/meizu/mt6755-common/nativehal/BoardConfigNvramAgent.mk
endif
endif
