ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native GNSS requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native GNSS requires U10 or U20)
endif
$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-nativegnss/gnss-vendor.mk)
PRODUCT_PACKAGES += android.hardware.gnss@1.0-service android.hardware.gnss@1.0-impl
PRODUCT_COPY_FILES += \
    device/meizu/mt6755-common/nativehal/service/meizu-gnss.rc:system/etc/init/meizu-gnss.rc \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml
