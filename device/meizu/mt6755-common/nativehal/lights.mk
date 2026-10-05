ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native lights requires exactly one early board identity)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native lights requires U10 or U20)
endif
$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-native-lights/lights-vendor.mk)
PRODUCT_PACKAGES += \
    android.hardware.light@2.0-service \
    android.hardware.light@2.0-impl \
    meizu-light-legacy-abi-check

# Enable only with the separately accepted own mx-led kernel for this board.
ifeq ($(MEIZU_NATIVE_MX_LED_KERNEL_VERIFIED),true)
PRODUCT_COPY_FILES += \
    device/meizu/mt6755-common/nativehal/mx-led-permissions.rc:system/vendor/etc/init/meizu-mx-led-permissions.rc
endif
