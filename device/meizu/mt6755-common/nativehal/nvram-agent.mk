ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error NvRAMAgent requires an exact own U10 or U20 identity)
endif
ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error NvRAMAgent requires exactly one own board)
endif
$(call inherit-product,vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-native-nvram-agent/nvram-agent-vendor.mk)
PRODUCT_PACKAGES += libmeizu_nvramagent_binder_compat
PRODUCT_COPY_FILES += \
    device/meizu/mt6755-common/nativehal/nvram-agent/init.nvram-agent.rc:system/etc/init/meizu-nvram-agent.rc
