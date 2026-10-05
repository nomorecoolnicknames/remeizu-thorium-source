ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native peripherals requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native peripherals requires U10 or U20)
endif
ifeq ($(strip $(TARGET_MEIZU_MT675X_DEVICE)),)
$(error Native peripherals requires an exact board)
endif
$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-native-peripherals/peripherals-vendor.mk)
PRODUCT_PACKAGES += \
    meizu.hardware.power@1.0-service \
    android.hardware.power@1.0-impl-meizu-legacy \
    android.hardware.vibrator@1.0-service \
    android.hardware.vibrator@1.0-impl
PRODUCT_COPY_FILES += \
    vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-native-peripherals/peripherals-permissions.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/meizu-peripherals-permissions.rc
