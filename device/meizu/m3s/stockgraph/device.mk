# M3s own-stock graph; HALs are mt6750, stock fstab/init are named mt6755.
TARGET_MEIZU_MT675X_DEVICE := m3s
$(call inherit-product, vendor/meizu/m3s/m3s-stockgraph-vendor.mk)

PRODUCT_COPY_FILES += \
    device/meizu/m3s/stockgraph/fstab.mt6755:root/fstab.mt6755 \
    device/meizu/m3s/stockgraph/init.mt6755.rc:root/init.mt6755.rc \
    device/meizu/m3s/stockgraph/ueventd.mt6755.rc:root/ueventd.mt6755.rc

# Own stock build.prop: density 320, Android 5.1 dual-architecture userspace.
PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=320
