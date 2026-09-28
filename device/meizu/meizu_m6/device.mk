# Meizu M6 — device.mk
TARGET_MEIZU_MT675X_DEVICE := meizu_m6
LOCAL_PATH := device/meizu/meizu_m6

$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
$(call inherit-product-if-exists, vendor/meizu/meizu_m6/meizu_m6-vendor.mk)

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/system.prop:system/build.prop.device

# device-only deltas (BT cfg, gps.conf, fp/microtrust rc) live here
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/gps.conf:system/etc/gps.conf
