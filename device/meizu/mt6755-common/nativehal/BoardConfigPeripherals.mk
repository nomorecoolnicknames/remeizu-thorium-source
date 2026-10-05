ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native peripherals requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native peripherals requires U10 or U20)
endif
ifeq ($(strip $(TARGET_MEIZU_MT675X_DEVICE)),)
$(error Native peripherals requires an exact board)
endif
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/nativehal/peripheral-sepolicy
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/nativehal/manifest-peripherals.xml
