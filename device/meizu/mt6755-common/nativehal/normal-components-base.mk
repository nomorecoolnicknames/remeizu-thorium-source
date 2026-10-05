# Preserve the exact normal LOS16 baseline's legacy dual-architecture phone base.
ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native normal product requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native normal product requires U10 or U20)
endif
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
PRODUCT_SHIPPING_API_LEVEL := 23
# No vendor partition/VNDK opt-in: SDK28 rootdir creates /vendor -> /system/vendor
# and chooses ld.config.legacy.txt, whose default namespace is not isolated.
# Each component owns its service and init_rc; do not import the M6 rootdir.
PRODUCT_PACKAGES += audio.usb.default audio.r_submix.default
# Rebuild SDK clients against separate SDK helper SONAMEs; own HAL imports keep
# their exact stock providers. The component-only source patch owns the split.
PRODUCT_PACKAGES += libtinycompress libtinyxml libcurl librilutils
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.output.xml:system/etc/permissions/android.hardware.audio.output.xml \
    device/meizu/mt6755-common/configs/android.hardware.microphone.xml:system/etc/permissions/android.hardware.microphone.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:system/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml

$(call inherit-product, device/meizu/mt6755-common/nativehal/graphics.mk)
