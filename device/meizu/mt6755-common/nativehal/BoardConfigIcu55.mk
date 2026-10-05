ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error ICU55 compatibility requires U10 or U20)
endif
ifeq ($(strip $(TARGET_MEIZU_MT675X_DEVICE)),)
$(error ICU55 compatibility requires an exact board)
endif

# Exact consumer paths only; the platform ICU implementation remains selected.
TARGET_LD_SHIM_LIBS += \
    /system/vendor/lib/libaudio_param_parser.so|libmeizu_icu55.so \
    /system/vendor/lib64/libaudio_param_parser.so|libmeizu_icu55.so \
    /system/bin/mtk_agpsd|libmeizu_icu55.so
