PRODUCT_PROPERTY_OVERRIDES += \
    ro.forge.meizu.codename=meizu_m6 \
    ro.forge.meizu.panel=ili9881p_hd_dsi_txd \
    ro.forge.meizu.touch=ft5x0x \
    ro.forge.meizu.charger=bq24157 \
    ro.forge.meizu.kernel=3.18.140

# M6-only display/audio/bt props (moved here from common device-common).
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=320 \
    ro.sf.hwrotation=180 \
    ro.hardware.bluetooth=blueangel \
    ro.hardware.audio.primary=mt6750

# M6-only fs_mgr blobs (moved here from common; vendor path is device-specific).
PRODUCT_COPY_FILES += \
    vendor/meizu/meizu_m6/proprietary/lib/libfs_mgr.so:system/lib/libfs_mgr.so \
    vendor/meizu/meizu_m6/proprietary/lib64/libfs_mgr.so:system/lib64/libfs_mgr.so \
    vendor/meizu/meizu_m6/proprietary/lib/libfs_mgr.so:system/vendor/lib/libfs_mgr.so \
    vendor/meizu/meizu_m6/proprietary/lib64/libfs_mgr.so:system/vendor/lib64/libfs_mgr.so
