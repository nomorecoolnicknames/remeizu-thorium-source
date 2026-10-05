ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native radio requires exactly one board)
endif
ifeq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),)
$(error Native radio requires U10 or U20)
endif
BOARD_PROVIDES_LIBRIL := true
ENABLE_VENDOR_RIL_SERVICE := true
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/nativehal/radio/manifest-radio.xml
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/nativehal/radio-sepolicy
