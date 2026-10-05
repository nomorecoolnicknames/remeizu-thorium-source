ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native radio requires exactly one board)
endif
ifeq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),)
$(error Native radio requires U10 or U20)
endif
$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)-nativeradio/radio-vendor.mk)
PRODUCT_PACKAGES += rild libril meizu-calibration-ready
PRODUCT_COPY_FILES += \
    device/meizu/mt6755-common/nativehal/radio/init.radio.rc:root/init.meizu-radio.rc \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml
PRODUCT_PROPERTY_OVERRIDES += \
    ro.radio.noril=false \
    persist.radio.no_ril=0 \
    persist.radio.multisim.config=dsds \
    ro.telephony.sim.count=2 \
    persist.gemini.sim_num=2
