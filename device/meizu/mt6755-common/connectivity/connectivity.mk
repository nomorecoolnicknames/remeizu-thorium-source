# PROPER-FIX: own-board WMT firmware/services and a real stock Bluetooth vendor ABI.
ifneq ($(words $(TARGET_MEIZU_MT675X_DEVICE)),1)
$(error Native connectivity requires exactly one board)
endif
ifeq ($(filter $(TARGET_MEIZU_MT675X_DEVICE),u10 u20),)
$(error Native connectivity requires U10 or U20)
endif

$(call inherit-product, vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)/connectivity/connectivity-vendor.mk)
PRODUCT_PACKAGES += \
    android.hardware.wifi@1.0-service \
    wpa_supplicant \
    hostapd \
    android.hardware.bluetooth@1.0-impl:32 \
    meizu.hardware.bluetooth@1.0-service
PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0 \
    wifi.direct.interface=p2p0 \
    wifi.tethering.interface=ap0
PRODUCT_COPY_FILES += \
    device/meizu/mt6755-common/connectivity/wpa_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf \
    device/meizu/mt6755-common/connectivity/init.connectivity.rc:root/init.meizu-connectivity.rc \
    vendor/meizu/$(TARGET_MEIZU_MT675X_DEVICE)/connectivity/ueventd.connectivity.rc:root/ueventd.meizu-connectivity.rc \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:system/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml
