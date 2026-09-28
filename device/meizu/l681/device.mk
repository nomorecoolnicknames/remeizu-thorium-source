# Meizu M3 Note (Global, L681) — device.mk
TARGET_MEIZU_MT675X_DEVICE := l681
LOCAL_PATH := device/meizu/l681

$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
$(call inherit-product-if-exists, vendor/meizu/l681/l681-vendor.mk)

# Global modem / regional blobs come from vendor/meizu/l681.
