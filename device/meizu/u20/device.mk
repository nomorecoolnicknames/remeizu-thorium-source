# Meizu U20 (u20) — LOS16 product wiring; board bring-up remains incomplete
TARGET_MEIZU_MT675X_DEVICE := u20
LOCAL_PATH := device/meizu/u20
$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
$(call inherit-product, vendor/meizu/u20/u20-vendor.mk)
