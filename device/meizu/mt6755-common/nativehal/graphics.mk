# Standard SDK28 providers adapt the exact own HWC1.5 and gralloc0.1 drivers.
ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native graphics requires exactly one board)
endif
ifeq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),)
$(error Native graphics requires U10 or U20)
endif
PRODUCT_PACKAGES += \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.composer@2.1-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.mapper@2.0-impl \
    libmeizu_egl_legacy_compat
