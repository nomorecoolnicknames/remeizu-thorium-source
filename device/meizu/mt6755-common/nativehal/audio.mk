$(call inherit-product, device/meizu/mt6755-common/nativehal/audio-capability.mk)
$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-nativeaudio/audio-vendor.mk)
# SDK28's standard service falls back to the compatible 2.0 core factory.
# Own HAL offset296 is MTK SetEMParameter, not P's get_microphones.
PRODUCT_PACKAGES += \
    android.hardware.audio@2.0-service \
    android.hardware.audio@2.0-impl \
    android.hardware.audio.effect@4.0-impl

# Own input offset136 and output offset200 hold C++ backing objects,
# not SDK28 capture-position/MMAP callbacks. Ordinary read/write stay active.
PRODUCT_PROPERTY_OVERRIDES += \
    ro.audio.legacy_hal_no_capture_position=true \
    ro.audio.legacy_hal_no_mmap=true
