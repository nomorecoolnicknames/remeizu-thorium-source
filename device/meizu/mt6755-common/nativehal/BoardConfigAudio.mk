ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native audio requires exactly one board)
endif
ifeq ($(TARGET_MEIZU_MT675X_DEVICE),u10)
MEIZU_NATIVE_AUDIO_PLATFORM := mt6750
else ifeq ($(TARGET_MEIZU_MT675X_DEVICE),u20)
MEIZU_NATIVE_AUDIO_PLATFORM := mt6755
else
$(error Native audio profile requires U10 or U20)
endif
# Actual SDK28 linker.cpp uses exact realpath|shim-basename pairs.
ifeq ($(TARGET_PRODUCT),lineage_$(TARGET_MEIZU_MT675X_DEVICE))
TARGET_LD_SHIM_LIBS += \
    /system/vendor/lib/hw/audio.primary.$(MEIZU_NATIVE_AUDIO_PLATFORM).so|libmeizu_audio_capability_compat.so \
    /system/vendor/lib64/hw/audio.primary.$(MEIZU_NATIVE_AUDIO_PLATFORM).so|libmeizu_audio_capability_compat.so
# The preserved board ramdisks resolve /vendor to /system/vendor.
AUDIOSERVER_MULTILIB := 64
# Own Flyme audio routes use the supported SDK28 legacy policy parser.
USE_XML_AUDIO_POLICY_CONF := 0
BOARD_SEPOLICY_DIRS += device/meizu/mt6755-common/nativehal/audio-sepolicy
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/nativehal/manifest-audio.xml
endif
