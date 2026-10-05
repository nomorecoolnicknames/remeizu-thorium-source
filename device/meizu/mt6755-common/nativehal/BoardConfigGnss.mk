ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native GNSS requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native GNSS requires U10 or U20)
endif
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/nativehal/manifest-gnss.xml
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/nativehal/gnss-sepolicy
