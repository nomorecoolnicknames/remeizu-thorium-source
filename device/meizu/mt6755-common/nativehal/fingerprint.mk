ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native fingerprint requires an exact U10 or U20 board)
endif
ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native fingerprint requires exactly one board)
endif
$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-native-fingerprint/fingerprint-vendor.mk)
PRODUCT_PACKAGES += meizu.hardware.biometrics.fingerprint@2.1-service
PRODUCT_COPY_FILES += \
    vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-native-fingerprint/fingerprint-daemons.rc:system/etc/init/meizu-fingerprint-daemons.rc
