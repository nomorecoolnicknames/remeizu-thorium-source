ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native audio capability profile requires U10 or U20)
endif
ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native audio capability profile requires exactly one board)
endif
PRODUCT_PACKAGES += libmeizu_audio_capability_compat
