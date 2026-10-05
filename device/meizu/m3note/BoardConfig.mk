DEVICE_PATH := device/meizu/m3note
TARGET_MEIZU_MT675X_DEVICE := m681
BOARD_SECCOMP_POLICY := $(DEVICE_PATH)/seccomp

include device/meizu/mt6755-common/BoardConfigCommon.mk
include vendor/meizu/m681/BoardConfigVendor.mk

TARGET_LD_SHIM_LIBS += \
    /vendor/lib/libcam_utils.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libcam.client.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libcam.camnode.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libeffecthal.base.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libjni_lomoeffect.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libvfb_render.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libMtkOmxVenc.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libmtk_mmutils.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libshowlogo.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libgui_ext.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libui_ext.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib64/libcam_utils.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libcam.client.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libcam.camnode.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libeffecthal.base.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libjni_lomoeffect.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libvfb_render.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libmtk_mmutils.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libgui_ext.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libui_ext.so|/vendor/lib64/libmtkshim_gui.so

# GPS/sensor daemon linker-ABI shims (live-diagnosed crash-loops, capture
# data_crashes_3v18_214541.txt): MPED's libmpe.sensorlistener.so wants N-era
# libgui SensorEventQueue/SensorManager (moved to libsensor in O — shim pulls
# libsensor into the load group); mtk_agpsd wants ICU-56 ucnv_* symbols (tree
# ships ICU 58.2 — shim forwards _56 -> _58). Both daemons are ELF32 only.
# See vendor/mediatek/symbols/{sensor,icu}.cpp.
TARGET_LD_SHIM_LIBS += \
    /vendor/lib/libmpe.sensorlistener.so|/vendor/lib/libmtkshim_sensor.so \
    /vendor/bin/mtk_agpsd|/vendor/lib/libmtkshim_icu.so

TARGET_DEVICE := m3note
TARGET_OTA_ASSERT_DEVICE := m3note,m681,l681,l681h,l91
TARGET_VENDOR := meizu
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/fstab.mt6755

# Revision profile (m681 | l681) from the device-tree compatible, published by
# init before any class starts: libinit/init_m3note.cpp.  It sets
# ro.vendor.meizu.profile, ro.hardware.sensors / ro.hardware.keystore and
# ro.sf.hwrotation; vendor/meizu/m3note/m3note-profile.rc activates the l681
# files.
TARGET_INIT_VENDOR_LIB := libinit_m3note
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 1920
# Old MTK display blobs on this device are far more stable with a 32-bit
# SurfaceFlinger process. The tree already builds both libsurfaceflinger ABIs;
# this only flips the executable path away from the crashing 64-bit binary.
TARGET_32_BIT_SURFACEFLINGER := true
# MTK GuiExt/HWC configures the primary display for three GUI buffers during
# boot. Keep FramebufferSurface aligned with that depth instead of the AOSP
# default 2-buffer queue, which correlates with the current timeline-primary
# fence stall on the first visible frame.
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
# The current black-screen failure is no longer an early SF crash; the late
# display path stalls forever on unsignaled present/retire fences from the
# legacy MTK HWC stack. Run SurfaceFlinger without the sync framework so it
# stops waiting on fences this 3.10 vendor stack never completes correctly.
TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK := true
# M681 is an MTK WMT/conn_soc Wi-Fi device. Kernel diagnostics show wlan0 and
# /dev/wmtWifi are alive; keep framework/HAL build-time paths on MediaTek so
# supplicant uses MTK private driver commands instead of Broadcom bcmdhd ones.
BOARD_WLAN_DEVICE := MediaTek
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_mt66xx
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_mt66xx
WIFI_DRIVER_STATE_CTRL_PARAM := /dev/wmtWifi
WIFI_DRIVER_STATE_ON := 1
WIFI_DRIVER_STATE_OFF := 0
WIFI_DRIVER_OPERSTATE_PATH := /sys/class/net/wlan0/operstate
WIFI_DRIVER_STATE_CTRL_RETRIES := 8
WIFI_DRIVER_STATE_CTRL_RETRY_DELAY_US := 1000000
BOARD_KERNEL_CMDLINE := $(strip $(L681_KERNEL_CMDLINE_EXTRA) bootopt=64S3,32N2,64N2 androidboot.selinux=permissive enforcing=0)

# VNDK — DISABLED for this A-only semi-treble Nougat-blob device.
# BOARD_VNDK_VERSION := current forces Soong to build `vendor` image variants
# of every vendor_available lib; this tree's frameworks/native has libgui
# (vendor_available) depending on libsensor which is NOT vendor_available, so
# soong_build fails: "dependency libsensor of libgui missing variant image:vendor".
# The proven meizu_m6 product in this same tree sets no BOARD_VNDK_VERSION, and
# m681 is PRODUCT_FULL_TREBLE_OVERRIDE := false (blobs under /system/vendor, no
# vendor partition), so VNDK is inappropriate here. Re-enable only once the
# frameworks vendor_available graph is made consistent.
# BOARD_VNDK_VERSION := current

# --- Treble stage A (2026-08-24): a REAL /vendor partition on custom(p3) ---
# l681 note: the m681 measurements below are the donor's.  For l681, FACT:
# custom is 512 MiB (scatter) and LOS 14.1 mounted it as /custom; its content
# and its number (p3) are INFERENCE -- see rootdir/fstab.mt6755 and README.md.
# p3 is 512 MiB and, measured on the device before this change, held 524 KiB of
# Flyme leftovers out of 496 MiB -- it is free space, not a live partition.  A
# raw gzipped backup of it is kept at
# m681/backups/m681-custom-p3-20260824.img.gz (md5 2b7b4e0cdbc74e4d8256f01ed007b434).
# /system/vendor measures 341 MiB, so it fits with ~170 MiB of headroom.
#
# TARGET_COPY_OUT_VENDOR is what makes the difference: unset it resolves to
# "system/vendor" (build/make/core/envsetup.mk), which is why every blob has
# been landing inside system.img.  Setting it to "vendor" both builds a
# vendor.img and removes the ramdisk /vendor -> /system/vendor symlink.
#
# This is stage A ONLY: PRODUCT_FULL_TREBLE_OVERRIDE stays false and
# PRODUCT_SHIPPING_API_LEVEL stays 25, so VNDK enforcement is NOT turned on.
# VNDK is unreachable for this blob set and is not required for a vendor
# partition -- PRODUCT_USE_VNDK is gated on the shipping API level, not on
# Treble (build/make/core/config.mk).
TARGET_COPY_OUT_VENDOR := vendor
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_PARTITION_SIZE := 536870912

BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
# userdata: INFERENCE.  The scatter gives only its start (0xeb000000); the end
# is the eMMC size minus flashinfo (16 MiB) and the backup GPT.  eMMC HBG4a2 is
# reported as 29.1 GiB; taking the 30535680 KiB of this eMMC class (same label
# measured on m5s, /proc/partitions) gives 27309095936 bytes, floored to the
# 128 KiB flash block.  mt6755-common's 27879521280 does NOT fit on this unit.
# The value only sizes userdata.img, which this project does not flash.
BOARD_USERDATAIMAGE_PARTITION_SIZE := 27308982272

# A-only (non-A/B) — this device has no slot suffix or dynamic partitions.
AB_OTA_UPDATER := false

# Split system/vendor build properties (Oreo requirement).
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# SELinux policy version: the Pie default (30) is kept, deliberately.
# The m681 donor note said "stock 3.10.72 kernel caps at policyvers 29".  That
# was about the m681 STOCK 3.10 kernel.  For THIS kernel it is REJECTED:
# FACT: the decompressed prebuilt-kernel/Image.gz-dtb (3.10.72+ #56) contains
# the policydb_compat[] table byte-for-byte with 16 entries, versions 15..30
# (table taken from l681-out/src/target/product/l681/obj/KERNEL_OBJ/security/
# selinux/ss/policydb.o, .data @0x5300, 0xc0 bytes; searched in the image).
# 30 = POLICYDB_VERSION_XPERMS_IOCTL, i.e. the allowxperm rules Pie emits load.
# FACT, for completeness: the LOS 14.1 ramdisk that booted on #56 carried a
# version-29 policy (header of its /sepolicy: f97cff8c "SE Linux" 29) -- that
# shows 29 loads, not that 30 does not.
# If boot stops at "SELinux: Could not load policy" (init reboots to bootloader
# in Pie), pin POLICYVERS := 29 AND drop allowxperm, as the donor note says.
# POLICYVERS := 29

# Oreo sepolicy split: platform policy (system partition) goes in
# BOARD_PLAT_SEPOLICY_DIRS; vendor policy goes in BOARD_SEPOLICY_DIRS.
# For this semi-treble build both reside in the device tree.
BOARD_PLAT_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/plat
BOARD_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy \
    $(DEVICE_PATH)/sepolicy/vendor
# Boot geometry -- FACT, read from the ANDROID! header of the image that last
# booted this unit (see the cmdline note above):
#   kernel_addr 0x40080000  ramdisk_addr 0x45000000  second_addr 0x40f00000
#   tags_addr   0x44000000  page_size 2048  name "" (empty)  header_version 0
# base 0x40078000 + mkbootimg's default kernel_offset 0x8000 = 0x40080000, and
# the three offsets below land ramdisk/second/tags on the same absolute
# addresses.  Same numbers as the m681 donor EXCEPT --board: the donor passes
# --board 1480869018, the booted l681 image has an EMPTY name field, so no
# --board is given (inventing a board id is inventing an artifact).
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x04f88000 --second_offset 0x00e88000 --tags_offset 0x03f88000
BOARD_RAMDISK_OFFSET := 0x04f88000
BOARD_SECOND_OFFSET := 0x00e88000
BOARD_TAGS_OFFSET := 0x03f88000

# Build Station: target device identity override
TARGET_OTA_ASSERT_DEVICE := m3note,m681,l681,l681h,l91
BOARD_NAME := m3note
TARGET_SYSTEM_PROP := device/meizu/m3note/system.prop

TARGET_NO_KERNEL := false
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_SOURCE := kernel/meizu/meizu_m6/kernel-3.18
TARGET_KERNEL_CONFIG :=
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt-kernel/Image.gz-dtb-m681
M3NOTE_L681_KERNEL := $(DEVICE_PATH)/prebuilt-kernel/Image.gz-dtb-l681
BOARD_KERNEL_IMAGE_NAME := kernel
PRODUCT_COPY_FILES += \
    $(TARGET_PREBUILT_KERNEL):kernel

# Prebuilt-kernel gate (port of the m5c LOS16 gate): a hand-placed kernel
# silently goes stale or gets swapped; this makes a mismatch fail the build.
# Empty output = the file matches its prebuilt-kernel/EXPECTED-<rev>.txt.
m3note_kernel_check := $(strip \
    $(shell $(DEVICE_PATH)/tools/check_prebuilt_kernel.sh \
        $(TARGET_PREBUILT_KERNEL) $(DEVICE_PATH)/prebuilt-kernel/EXPECTED-m681.txt) \
    $(shell $(DEVICE_PATH)/tools/check_prebuilt_kernel.sh \
        $(M3NOTE_L681_KERNEL) $(DEVICE_PATH)/prebuilt-kernel/EXPECTED-l681.txt))
ifneq ($(m3note_kernel_check),)
$(error $(m3note_kernel_check))
endif

# OTA: device extension (revision check before any write, boot-l681.img on l681).
TARGET_RELEASETOOLS_EXTENSIONS := $(DEVICE_PATH)

TARGET_SPECIFIC_HEADER_PATH := vendor/mediatek/include
BOARD_PROVIDES_RILD := true
BOARD_PROVIDES_LIBRIL := true
