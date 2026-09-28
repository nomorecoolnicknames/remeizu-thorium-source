# Meizu M6T (m6t) — device.mk (PLANNED stub)
TARGET_MEIZU_MT675X_DEVICE := m6t
LOCAL_PATH := device/meizu/m6t
$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
$(call inherit-product-if-exists, vendor/meizu/m6t/m6t-vendor.mk)
