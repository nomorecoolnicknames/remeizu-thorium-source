# Admission requires both compiled source providers and own camera ABI closure.
ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native camera requires exactly one board)
endif
ifneq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),$(TARGET_MEIZU_MT675X_DEVICE))
$(error Native camera requires U10 or U20)
endif
ifeq ($(MEIZU_NATIVE_CAMERA_ABI_VERIFIED),true)
PRODUCT_PACKAGES += \
    meizu.hardware.camera.provider@2.4-service \
    android.hardware.camera.provider@2.4-impl \
    camera.device@1.0-impl \
    camera.device@3.2-impl \
    camera.device@3.3-impl \
    camera.device@3.4-impl
$(call inherit-product,vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-native-camera/camera-vendor.mk)
# Both own stock permission sets declare rear/front, autofocus and flash.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml
else
$(error Own U10/U20 camera requires compiled GraphicBuffer/Bionic ABI admission)
endif
