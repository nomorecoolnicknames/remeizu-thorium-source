ifeq ($(MEIZU_NATIVE_CAMERA_ABI_VERIFIED),true)
USE_CAMERA_STUB := false
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/nativehal/manifest-camera.xml
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/nativehal/camera-sepolicy
else
$(error Own U10/U20 camera requires compiled GraphicBuffer/Bionic ABI admission)
endif
