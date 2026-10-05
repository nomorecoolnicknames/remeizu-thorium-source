ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native sensors requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native sensors policy requires U10 or U20)
endif
ifeq ($(strip $(TARGET_MEIZU_MT675X_DEVICE)),)
$(error Native sensors policy requires an exact board)
endif
ifeq ($(TARGET_PRODUCT),lineage_$(TARGET_MEIZU_MT675X_DEVICE))
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/nativehal/sepolicy
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/nativehal/manifest-sensors.xml
# The legacy camera sensor listener used SensorManager from libgui.
# SDK28 provides those symbols in the board's patched libsensor instead.
TARGET_LD_SHIM_LIBS += \
    /system/lib/libcam.utils.sensorlistener.so|libsensor.so \
    /system/lib64/libcam.utils.sensorlistener.so|libsensor.so
endif
