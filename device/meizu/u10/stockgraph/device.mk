# U10 own-stock graph inputs; platform HALs are mt6750, stock rootdir is mt6755.
TARGET_MEIZU_MT675X_DEVICE := u10
$(call inherit-product, vendor/meizu/u10/u10-stockgraph-vendor.mk)

ifeq ($(TARGET_PRODUCT),lineage_u10)
PRODUCT_COPY_FILES += \
    device/meizu/u10/native/fstab.mt6755:root/fstab.mt6755 \
    device/meizu/u10/native/init.mt6755.rc:root/init.mt6755.rc \
    device/meizu/u10/native/ueventd.mt6755.rc:root/ueventd.mt6755.rc
else
PRODUCT_COPY_FILES += \
    device/meizu/u10/stockgraph/fstab.mt6755:root/fstab.mt6755 \
    device/meizu/u10/stockgraph/init.mt6755.rc:root/init.mt6755.rc \
    device/meizu/u10/stockgraph/ueventd.mt6755.rc:root/ueventd.mt6755.rc
endif

# Own stock build.prop density and original Android 6 dual-architecture userspace.
PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=320
