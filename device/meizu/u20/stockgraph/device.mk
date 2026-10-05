# This graph imports U20 inputs directly; no M6/m681 runtime dispatch or blobs.
TARGET_MEIZU_MT675X_DEVICE := u20
$(call inherit-product, vendor/meizu/u20/u20-stockgraph-vendor.mk)

ifeq ($(TARGET_PRODUCT),lineage_u20)
PRODUCT_COPY_FILES += \
    device/meizu/u20/native/fstab.mt6755:root/fstab.mt6755 \
    device/meizu/u20/native/init.mt6755.rc:root/init.mt6755.rc \
    device/meizu/u20/native/ueventd.mt6755.rc:root/ueventd.mt6755.rc
else
PRODUCT_COPY_FILES += \
    device/meizu/u20/stockgraph/fstab.mt6755:root/fstab.mt6755 \
    device/meizu/u20/stockgraph/init.mt6755.rc:root/init.mt6755.rc \
    device/meizu/u20/stockgraph/ueventd.mt6755.rc:root/ueventd.mt6755.rc
endif

# Stock build.prop: LCD density 480; dual 64/32-bit userspace. No stock libc/JNI.
PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=480
