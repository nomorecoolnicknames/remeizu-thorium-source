# Select this fragment only for the own normal products, never diagnostics.
ifeq ($(TARGET_PRODUCT),lineage_$(TARGET_MEIZU_MT675X_DEVICE))
DEVICE_MANIFEST_FILE += device/meizu/mt6755-common/nativehal/manifest-graphics.xml
# Exact own baseline SYSTEM consumer and realpath, matching SDK28 LD_SHIM_LIBS.
TARGET_LD_SHIM_LIBS += \
    /system/lib/libgem.so|libmeizu_egl_legacy_compat.so \
    /system/lib64/libgem.so|libmeizu_egl_legacy_compat.so
endif
