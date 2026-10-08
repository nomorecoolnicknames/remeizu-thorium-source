# SPDX-License-Identifier: Apache-2.0
LOCAL_PATH := device/meizu/m3note
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay
DEVICE_MANIFEST_FILE := $(LOCAL_PATH)/manifest.xml
PRODUCT_PACKAGES += libwpa_client wpa_supplicant hostapd android.hardware.health@2.1-impl android.hardware.health@2.1-service
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.mt6755:$(TARGET_COPY_OUT_RAMDISK)/fstab.mt6755 \
    $(LOCAL_PATH)/rootdir/etc/fstab.mt6755:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.mt6755 \
    $(LOCAL_PATH)/rootdir/etc/init.m3note.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.m3note.rc \
    $(LOCAL_PATH)/keylayout/mtk-kpd.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/mtk-kpd.kl \
    $(LOCAL_PATH)/wifi/wpa_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf \
    $(LOCAL_PATH)/wifi/p2p_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant.conf \
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml
$(call inherit-product, vendor/meizu/m3note/m3note-vendor.mk)

# Board init, USB gadget, device nodes and the MTK service rcs, taken from the M681
# LOS 20 treble tree (meizu-fleet wt/device_m681_treble 7dd224c), whose userspace
# reached HOME/Settings on hardware. Before this the common image had no
# init.mt6755.rc at all: nothing ran mount_all and /data stayed unmounted.
# CONSYS (wmt_*) is still started by hand (vendor.m681.wmt.start=1), see the rc header.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init/hw/init.mt6755.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.mt6755.rc \
    $(LOCAL_PATH)/rootdir/etc/init/hw/init.mt6755.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.mt6755.usb.rc \
    $(LOCAL_PATH)/rootdir/etc/ueventd.mt6755.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc \
    $(LOCAL_PATH)/rootdir/etc/init.m681.spm.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.m681.spm.rc \
    $(LOCAL_PATH)/rootdir/etc/init.m681.wifi.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.m681.wifi.rc \
    $(LOCAL_PATH)/rootdir/etc/init.m681.connectivity.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.m681.connectivity.rc \
    $(LOCAL_PATH)/rootdir/etc/init.m681.sensors.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.m681.sensors.rc \
    $(LOCAL_PATH)/rootdir/etc/init.trustonic.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.trustonic.rc

PRODUCT_PACKAGES += libm3note_n_gui libm3note_n_base libm3note_n_ui libm3note_n_perfservice libm3note_n_region libm3note_n_audio

PRODUCT_PACKAGES += audio.primary.default audio.r_submix.default audio.usb.default audio_policy.stub libdrmclearkeyplugin libmockdrmcryptoplugin libaudiopreprocessing

# Vendor HAL services (full set of the M681 LOS 20 treble tree, wt/device_m681_treble
# 7dd224c device.mk "Vendor HALs"; manifest.xml is that tree's). They wrap the MT6755
# N blobs that the board profile mounts under /vendor. Before this the common image
# had health only: no composer/allocator/mapper, so SurfaceFlinger had no display.
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.mapper@2.0-impl-2.1 \
    android.hardware.memtrack@1.0-impl \
    android.hardware.memtrack@1.0-service \
    android.hardware.renderscript@1.0-impl \
    android.hardware.power@1.0-impl \
    android.hardware.power@1.0-service \
    android.hardware.light@2.0-impl \
    android.hardware.light@2.0-service \
    android.hardware.audio@2.0-impl \
    android.hardware.audio@2.0-service \
    android.hardware.audio.effect@2.0-impl \
    android.hardware.audio@6.0-impl \
    android.hardware.audio.effect@6.0-impl \
    android.hardware.keymaster@3.0-impl \
    android.hardware.keymaster@3.0-service \
    android.hardware.gatekeeper@1.0-service.software \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service \
    android.hardware.drm@1.4-service.clearkey \
    android.hardware.gnss@1.0-impl \
    android.hardware.gnss@1.0-service \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service \
    android.hardware.sensors@1.0-impl \
    android.hardware.sensors@1.0-service \
    android.hardware.wifi@1.0-service \
    libwifi-hal-mt66xx \
    wificond

# HWC1 module for composer@2.1 (forge_hwc, hwcomposer/, from wt/device_m681_hwc_loader
# aae68cf: gralloc_extra through the RTLD_GLOBAL base shim), selected by
# ro.hardware.hwcomposer=forge in vendor.prop.
PRODUCT_PACKAGES += hwcomposer.forge

# Libraries the N blobs NEED that are not in the image otherwise (same closure as the
# M681 treble tree: libcamera_client compat, tinyxml/tinycompress/alsautils for
# audio.primary.mt6755, libstdc++.vendor for the 85 blobs that NEED libstdc++.so; with
# BOARD_VNDK_VERSION the vendor namespace cannot see /system/lib*/libstdc++.so).
PRODUCT_PACKAGES += \
    libcamera_client_vendor \
    libstdc++.vendor \
    libtinyxml \
    libalsautils \
    libtinycompress

PRODUCT_PACKAGES += gralloc.default

# Vibrator: AIDL service over the LED-class /sys/class/leds/vibrator (vibrator/,
# kernel side m3note-components c3).
PRODUCT_PACKAGES += android.hardware.vibrator-service.m3note

# Fingerprint (Goodix GF516M + Trustonic 302c): the HIDL @2.0 service ported
# from MX6 (device/meizu/m95/fingerprint), the N daemon/HAL/libgf_* as the
# profile "derived" set, its init rc and the key layout. Kernel side: fp1
# (m681-bat1k-comp 49e6b9412). The device structure is 272 bytes on m681 too
# (disassembly of the 6.2.0.2A blob: malloc 0x110, notify@120,
# set_active_group@224, authenticate@232), so the m95 static_asserts hold.
PRODUCT_PACKAGES += android.hardware.biometrics.fingerprint@2.0-service.m3note
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.goodixfpd.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.goodixfpd.rc \
    $(LOCAL_PATH)/keylayout/fp-keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/fp-keys.kl \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml

# Feature declarations of the M3 Note (M681 treble tree list, both revisions have this
# hardware; fingerprint left out until a fingerprint HAL exists), the TEE symlinks
# (Android.mk). The TEMPORARY adb-without-key-dialog of the treble tree is in vendor.prop.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml
PRODUCT_PACKAGES += m3note_vendor_symlinks

# Audio policy (Android 13 reads XML only; the profiles carry just the stock
# Nougat audio_policy.conf, so AudioPolicyManager had no module and
# system_server would log "listAudioPorts error -19" as on m5c before its XML).
# One file per board under /vendor/etc/audio/sku_<board>, picked by
# ro.boot.product.vendor.sku (set by libinit from the verified board); the
# M681 variant (no speaker) is also the plain /vendor/etc fallback. Volumes,
# usb, r_submix and the effects list are the AOSP files, as on m5c.
AUDIO_POLICY_CFG_DIR := frameworks/av/services/audiopolicy/config
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_policy_configuration_m681.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_m681/audio_policy_configuration.xml \
    $(LOCAL_PATH)/audio/audio_policy_configuration_l681.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_l681/audio_policy_configuration.xml \
    $(LOCAL_PATH)/audio/audio_policy_configuration_m681.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(AUDIO_POLICY_CFG_DIR)/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    $(AUDIO_POLICY_CFG_DIR)/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    $(AUDIO_POLICY_CFG_DIR)/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    $(AUDIO_POLICY_CFG_DIR)/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    $(AUDIO_POLICY_CFG_DIR)/surround_sound_configuration_5_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/surround_sound_configuration_5_0.xml \
    frameworks/av/media/libeffects/data/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml

# Keymaster per revision (libvintf reads /vendor/etc/vintf/manifest_<sku>.xml instead of
# manifest.xml; libinit sets ro.boot.product.vendor.sku to the verified board):
# both revisions now declare the AOSP software keymaster 4.0 (M681 manifest kept
# separate for when MobiCore works on 4.9: u6 on m681 had keymaster 3.0 stuck on
# "McDriverClient: No route to host" and keystore2 waiting for it). On L681 A9 the M681 TEE keymaster did
# not work (A9 inventory 87c1fef); a declared HAL that never registers would block
# keystore and the boot.
PRODUCT_PACKAGES += android.hardware.keymaster@4.0-service
# The SKU manifests themselves: DEVICE_MANIFEST_SKUS in BoardConfig.mk (the build refuses
# VINTF files in PRODUCT_COPY_FILES).
