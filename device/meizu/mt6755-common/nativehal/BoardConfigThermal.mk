ifneq ($(filter $(TARGET_PRODUCT),lineage_u10 lineage_u20),)
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/nativehal/manifest-thermal.xml
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/nativehal/thermal-sepolicy
endif
