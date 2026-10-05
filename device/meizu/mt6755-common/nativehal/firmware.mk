ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native firmware requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native firmware requires U10 or U20)
endif
$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-nativefirmware/firmware-vendor.mk)
PRODUCT_PACKAGES += meizu-spm-loader
