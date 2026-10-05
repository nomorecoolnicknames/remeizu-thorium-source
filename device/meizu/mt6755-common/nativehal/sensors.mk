ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native sensors requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native sensors profile requires U10 or U20)
endif
ifeq ($(strip $(TARGET_MEIZU_MT675X_DEVICE)),)
$(error Native sensors profile requires an exact board)
endif

$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-nativehal/sensors-vendor.mk)
PRODUCT_PACKAGES += \
    meizu.hardware.sensors@1.0-service \
    android.hardware.sensors@1.0-impl-meizu-legacy
PRODUCT_COPY_FILES += \
    vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-nativehal/sensors-permissions.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/meizu-sensors-permissions.rc
$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-sensordaemon/daemon-vendor.mk)
PRODUCT_COPY_FILES += \
    device/meizu/mt6755-common/nativehal/service/meizu-magnetometer.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/meizu-magnetometer.rc
