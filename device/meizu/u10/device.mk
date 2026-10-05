# Meizu U10 (u10) — LOS16 product wiring; board bring-up remains incomplete
TARGET_MEIZU_MT675X_DEVICE := u10
LOCAL_PATH := device/meizu/u10
$(call inherit-product, device/meizu/u10/stockgraph/device.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/normal-components-base.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/sensors.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/audio.mk)

ifeq ($(TARGET_PRODUCT),lineage_u10)
include device/meizu/u10/early-firmware.mk
endif

$(call inherit-product, device/meizu/mt6755-common/connectivity/connectivity.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/peripherals.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/icu55.mk)

$(call inherit-product, device/meizu/mt6755-common/nativehal/fingerprint.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/radio.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/firmware.mk)

$(call inherit-product, device/meizu/mt6755-common/nativehal/gnss.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/lights.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/thermal.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/fm-prerequisites.mk)

# Bootstrap libc/libui first; admit the camera after compiled ABI verification.
ifeq ($(MEIZU_NATIVE_CAMERA_ABI_VERIFIED),true)
$(call inherit-product, device/meizu/mt6755-common/nativehal/camera.mk)
$(call inherit-product, device/meizu/mt6755-common/nativehal/nvram-agent.mk)
endif
