$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# The gps config appropriate for this device
$(call inherit-product, device/common/gps/gps_us_supl.mk)

COMMON_PATH := device/meizu/mt6755-common

# --- Per-device variant dispatch + runtime detect (folded in from family layer) ---
ifneq ($(TARGET_MEIZU_MT675X_DEVICE),)
$(call inherit-product-if-exists, $(COMMON_PATH)/configs/$(TARGET_MEIZU_MT675X_DEVICE).mk)
endif

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/meizu_mt675x_devices.json:system/etc/meizu_mt675x_devices.json \
    $(COMMON_PATH)/rootdir/init.meizu_mt675x.rc:root/init.meizu_mt675x.rc \
    $(COMMON_PATH)/rootdir/init.meizu_mt675x.meizu_m6.rc:root/init.meizu_mt675x.meizu_m6.rc \
    $(COMMON_PATH)/rootdir/init.meizu_mt675x.m681.rc:root/init.meizu_mt675x.m681.rc \
    $(COMMON_PATH)/rootdir/init.meizu_mt675x.l681.rc:root/init.meizu_mt675x.l681.rc \
    $(COMMON_PATH)/rootdir/sbin/meizu_mt675x_detect.sh:root/sbin/meizu-detect.sh

DEVICE_PACKAGE_OVERLAYS += $(COMMON_PATH)/overlay

# MTK's XLog needed for Engineer Mode
PRODUCT_PACKAGES += \
    libxlog

# Bluetooth
PRODUCT_PACKAGES += \
    libbt-vendor

# Keyboard layout
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/keylayout/mtk-kpd.kl:system/usr/keylayout/mtk-kpd.kl \
    $(COMMON_PATH)/keylayout/ACCDET.kl:system/usr/keylayout/ACCDET.kl \
    $(COMMON_PATH)/keylayout/AVRCP.kl:system/usr/keylayout/AVRCP.kl \
    $(COMMON_PATH)/keylayout/AW9201_ts.kl:system/usr/keylayout/AW9201_ts.kl \
    $(COMMON_PATH)/keylayout/mtk-tpd.kl:system/usr/keylayout/mtk-tpd.kl

# Build Station: Android 7 uses system/core/rootdir/init.rc; MTK hooks stay in init.mt6755.rc.
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/rootdir/enableswap.sh:root/enableswap.sh \
    $(COMMON_PATH)/rootdir/init.mt6755.rc:root/init.mt6755.rc \
    $(COMMON_PATH)/rootdir/init.ssd.rc:root/init.ssd.rc \
    $(COMMON_PATH)/rootdir/init.xlog.rc:root/init.xlog.rc \
    $(COMMON_PATH)/rootdir/init.mt6755.usb.rc:root/init.mt6755.usb.rc \
    $(COMMON_PATH)/rootdir/init.aee.rc:root/init.aee.rc \
    $(COMMON_PATH)/rootdir/init.project.rc:root/init.project.rc \
    $(COMMON_PATH)/rootdir/init.modem.rc:root/init.modem.rc \
    $(COMMON_PATH)/rootdir/init.trace.rc:root/init.trace.rc \
    $(COMMON_PATH)/rootdir/fstab.mt6755:root/fstab.mt6755 \
    $(COMMON_PATH)/rootdir/init.nvdata.rc:root/init.nvdata.rc \
    $(COMMON_PATH)/rootdir/ueventd.mt6755.rc:root/ueventd.mt6755.rc \
    $(COMMON_PATH)/configs/media_codecs.xml:system/etc/media_codecs.xml \
    $(COMMON_PATH)/configs/media_codecs_performance.xml:system/etc/media_codecs_performance.xml \
    $(COMMON_PATH)/configs/mtk_omx_core.cfg:system/vendor/etc/mtk_omx_core.cfg \
    $(COMMON_PATH)/configs/media_codecs.xml:system/vendor/etc/media_codecs.xml \
    $(COMMON_PATH)/configs/media_codecs_performance.xml:system/vendor/etc/media_codecs_performance.xml \
    $(COMMON_PATH)/configs/media_profiles.xml:system/etc/media_profiles.xml \
    $(COMMON_PATH)/configs/android.hardware.microphone.xml:system/etc/permissions/android.hardware.microphone.xml \
    $(COMMON_PATH)/configs/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
    $(COMMON_PATH)/configs/audio_policy.conf:system/etc/audio_policy.conf \
    $(COMMON_PATH)/configs/audio_device.xml:system/etc/audio_device.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:system/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.hardware.audio.output.xml:system/etc/permissions/android.hardware.audio.output.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:system/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.faketouch.xml:system/etc/permissions/android.hardware.faketouch.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:system/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml 

# RIL
PRODUCT_PACKAGES += \
    gsm0710muxd

PRODUCT_PACKAGES += \
    Torch

# Early boot diagnostics. These land in the boot ramdisk, not the system image,
# so adbd can run a shell and basic commands even if /system is not mounted.
PRODUCT_PACKAGES += \
    emergency_sh \
    emergency_toybox

# Wifi
PRODUCT_PACKAGES += \
    libwpa_client \
    hostapd \
    dhcpcd.conf \
    wpa_supplicant \
    wpa_supplicant.conf

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/hostapd_default.conf:system/etc/hostapd/hostapd_default.conf \

# Audio components from source. Primary is the stock MTK vendor HAL.
PRODUCT_PACKAGES += \
    audio.usb.default \
    audio.r_submix.default

# Build Station bring-up: force AOSP software keymaster until MTK UT keymaster node works.
PRODUCT_PACKAGES += \
    keystore.default

# Build Station: scrcpy/media/audio bring-up. Keep ROM-built helper libraries
# in /system so MTK vendor blobs do not fail early dlopen.
PRODUCT_PACKAGES += \
	libtinyxml \
	libtinycompress \
	libstagefright_soft_avcenc \
	libstagefright_soft_vpxenc

# NOTE: M6-specific fs_mgr blobs moved to configs/meizu_m6.mk — that vendor path
# (vendor/meizu/meizu_m6) does not exist for m681/l681 and would break their builds.
# Per-device variant configs are the right home for such device-only copies.

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)

PRODUCT_CHARACTERISTICS := phone

ADDITIONAL_DEFAULT_PROPERTIES += ro.secure=0 \
    ro.allow.mock.location=1 \
    ro.debuggable=1 \
    ro.adb.secure=0 \
    persist.service.acm.enable=0 \
    persist.sys.usb.config=mtp,adb \
    ro.mount.fs=EXT4 \
    debug.hwui.render_dirty_regions=false \
    persist.radio.multisim.config=dsds \
    ro.mtk_lte_support=1 \
    ro.telephony.ril_class=MediaTekRIL \
    ro.telephony.ril.config=fakeiccid \
    ro.telephony.sim.count=2 \
    persist.gemini.sim_num=2 \
    ril.current.share_modem=2 \
    ro.mtk_gps_support=1 \
    ro.mtk_agps_app=1 \
    persist.debug.xlog.enable=1 

 \
    sys.usb.config=adb \
    persist.mediatek.fg.disable=1 \
    ro.hardware.keystore=default \
    persist.mtk.aee.aed=on \
    ro.radio.noril=true \
    persist.radio.no_ril=1

# (dev-only boot-diag copy removed — not shipped)
