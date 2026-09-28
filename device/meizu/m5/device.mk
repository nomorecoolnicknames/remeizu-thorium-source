# Meizu M5 (m5) — LOS16 product wiring; board bring-up remains incomplete
TARGET_MEIZU_MT675X_DEVICE := m5
LOCAL_PATH := device/meizu/m5
$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
$(call inherit-product, vendor/meizu/m5/m5-vendor.mk)
