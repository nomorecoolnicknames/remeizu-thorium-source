ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error ICU55 compatibility requires U10 or U20)
endif
ifeq ($(strip $(TARGET_MEIZU_MT675X_DEVICE)),)
$(error ICU55 compatibility requires an exact board)
endif

PRODUCT_PACKAGES += libmeizu_icu55
