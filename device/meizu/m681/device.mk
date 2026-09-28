# Meizu M3 Note (China, M681) — device.mk
TARGET_MEIZU_MT675X_DEVICE := m681
LOCAL_PATH := device/meizu/m681

$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
$(call inherit-product-if-exists, vendor/meizu/m681/m681-vendor.mk)

# China modem / regional blobs come from vendor/meizu/m681.
