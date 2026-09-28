# Meizu M3s (m3s) — LOS16 product wiring; board bring-up remains incomplete
TARGET_MEIZU_MT675X_DEVICE := m3s
LOCAL_PATH := device/meizu/m3s
$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
$(call inherit-product, vendor/meizu/m3s/m3s-vendor.mk)
