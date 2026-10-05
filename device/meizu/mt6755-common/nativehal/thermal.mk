ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native thermal telemetry requires exactly one own board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native thermal telemetry requires U10 or U20)
endif
PRODUCT_PACKAGES += thermal.mt6755 android.hardware.thermal@1.0-service android.hardware.thermal@1.0-impl
# Both own kernels use MTK_PLATFORM=mt6755; class-specific lookup is intentional.
PRODUCT_PROPERTY_OVERRIDES += ro.hardware.thermal=mt6755
