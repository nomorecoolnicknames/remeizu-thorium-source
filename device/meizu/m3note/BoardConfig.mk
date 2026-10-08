# SPDX-License-Identifier: Apache-2.0
DEVICE_PATH := device/meizu/m3note
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a53
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53
TARGET_USES_64_BIT_BINDER := true
TARGET_BOARD_PLATFORM := mt6755
TARGET_BOOTLOADER_BOARD_NAME := mt6755
TARGET_BOARD_PLATFORM_GPU := mali-t860mp2
TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true
BOARD_NAME := m3note
TARGET_OTA_ASSERT_DEVICE := m3note,m681,l681
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 1920
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2684354560
BOARD_CACHEIMAGE_PARTITION_SIZE := 452984832
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
AB_OTA_UPDATER := false
BOARD_USES_RECOVERY_AS_BOOT := false
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false
TARGET_COPY_OUT_VENDOR := system/vendor
BOARD_VNDK_VERSION := current
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x04f88000
BOARD_SECOND_OFFSET := 0x00e88000
BOARD_TAGS_OFFSET := 0x03f88000
BOARD_MKBOOTIMG_ARGS := --board 1480869018 --ramdisk_offset $(BOARD_RAMDISK_OFFSET) --second_offset $(BOARD_SECOND_OFFSET) --tags_offset $(BOARD_TAGS_OFFSET)
BOARD_BOOT_HEADER_VERSION := 0
BOARD_INCLUDE_DTB_IN_BOOTIMG :=
BOARD_INCLUDE_RECOVERY_DTBO :=
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 androidboot.hardware=mt6755 androidboot.selinux=permissive androidboot.usb.config=adb buildvariant=userdebug clk_ignore_unused
TARGET_NO_KERNEL := false
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
# Kernel source only for generated_kernel_includes (libtinycompress); the boot kernel
# is the prebuilt common Image. kernel/meizu/m681 -> wt/kernel_m681_49_headers (4.9,
# headers_install for both ABIs); kernel/meizu/mt6755 does not exist in los20.
TARGET_KERNEL_SOURCE := kernel/meizu/m681
TARGET_KERNEL_CONFIG := m681_49_defconfig
TARGET_KERNEL_VERSION := 4.9
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image-m681.gz-dtb
TARGET_FORCE_PREBUILT_KERNEL := true
BOARD_KERNEL_IMAGE_NAME := kernel
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.mt6755
# Mount points of the MTK data partitions in fstab.mt6755 (labels: sepolicy/vendor/file_contexts).
BOARD_ROOT_EXTRA_FOLDERS := nvdata protect_f protect_s
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_CHARGER_SHOW_PERCENTAGE := true
BOARD_WLAN_DEVICE := MediaTek
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_mt66xx
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_mt66xx
WIFI_DRIVER_STATE_CTRL_PARAM := /dev/wmtWifi
WIFI_DRIVER_STATE_ON := 1
WIFI_DRIVER_STATE_OFF := 0
SELINUX_IGNORE_NEVERALLOWS := true
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
BOARD_USES_QCOM_HARDWARE := false
TARGET_USES_QCOM_BSP := false
TARGET_SYSTEM_PROP := $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Per-revision VINTF manifests (/vendor/etc/vintf/manifest_<sku>.xml, assembled like
# manifest.xml; libvintf picks them by ro.boot.product.vendor.sku): keymaster differs.
DEVICE_MANIFEST_SKUS := m681 l681
DEVICE_MANIFEST_M681_FILES := $(DEVICE_PATH)/vintf/manifest_m681.xml
DEVICE_MANIFEST_L681_FILES := $(DEVICE_PATH)/vintf/manifest_l681.xml

# N-ABI shims of the M681 blob set, preloaded into the blobs that need them (same
# wiring as vendor/meizu/m681/BoardConfigVendor.mk of the treble tree; the shim
# modules here are shims/ libm3note_n_* with those stems), plus liblog for the MTK
# loaders (treble BoardConfig.mk). /vendor is /system/vendor here, so each pair is
# listed with both prefixes in case the linker matches the real path.
TARGET_LD_SHIM_LIBS += \
    /vendor/lib/egl/libGLES_mali.so|/vendor/lib/libm681shim_base.so \
    /vendor/lib64/egl/libGLES_mali.so|/vendor/lib64/libm681shim_base.so \
    /vendor/lib/hw/gralloc.mt6755.so|/vendor/lib/libm681shim_base.so \
    /vendor/lib64/hw/gralloc.mt6755.so|/vendor/lib64/libm681shim_base.so \
    /vendor/lib/libgui_ext.so|/vendor/lib/libmtkshim_ui.so \
    /vendor/lib64/libgui_ext.so|/vendor/lib64/libmtkshim_ui.so \
    /vendor/bin/spm_loader|liblog.so \
    /vendor/bin/wmt_loader|liblog.so \
    /vendor/bin/wmt_launcher|liblog.so \
    /vendor/lib/hw/audio.primary.mt6755.so|/vendor/lib/libm3note_n_audio.so \
    /vendor/lib64/hw/audio.primary.mt6755.so|/vendor/lib64/libm3note_n_audio.so \
    /system/vendor/lib/egl/libGLES_mali.so|/system/vendor/lib/libm681shim_base.so \
    /system/vendor/lib64/egl/libGLES_mali.so|/system/vendor/lib64/libm681shim_base.so \
    /system/vendor/lib/hw/gralloc.mt6755.so|/system/vendor/lib/libm681shim_base.so \
    /system/vendor/lib64/hw/gralloc.mt6755.so|/system/vendor/lib64/libm681shim_base.so \
    /system/vendor/lib/libgui_ext.so|/system/vendor/lib/libmtkshim_ui.so \
    /system/vendor/lib64/libgui_ext.so|/system/vendor/lib64/libmtkshim_ui.so \
    /system/vendor/bin/spm_loader|liblog.so \
    /system/vendor/bin/wmt_loader|liblog.so \
    /system/vendor/bin/wmt_launcher|liblog.so \
    /system/vendor/lib/hw/audio.primary.mt6755.so|/system/vendor/lib/libm3note_n_audio.so \
    /system/vendor/lib64/hw/audio.primary.mt6755.so|/system/vendor/lib64/libm3note_n_audio.so

# Compile an explicitly experimental common image; deployment gates are separate.
ifneq ($(M3NOTE_BUILD_SCOPE),two-unit-diagnostic)
$(error M3 Note requires the explicit two-unit-diagnostic build scope)
endif
ifeq ($(wildcard $(DEVICE_PATH)/prebuilt/common-kernel-proof.json),)
$(error Source-built common Image and both own DTBs must be admitted first)
endif
ifeq ($(wildcard vendor/meizu/m3note/profile-proof.json),)
$(error Both isolated vendor profiles are required; single-board fallback is forbidden)
endif
include $(DEVICE_PATH)/BoardConfigProfiles.mk
TARGET_RECOVERY_DEVICE_MODULES += m3note_probe
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_DUP_RULES := true
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/config.fs
