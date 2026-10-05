ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native fingerprint requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native fingerprint requires an exact U10 or U20 board)
endif
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/nativehal/fingerprint-sepolicy
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/nativehal/manifest-fingerprint.xml
