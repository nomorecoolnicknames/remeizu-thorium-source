# Meizu U10 (u10) — LOS16 product wiring; board bring-up remains incomplete
TARGET_MEIZU_MT675X_DEVICE := u10
LOCAL_PATH := device/meizu/u10
$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
$(call inherit-product, vendor/meizu/u10/u10-vendor.mk)
