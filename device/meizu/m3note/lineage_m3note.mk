# SPDX-License-Identifier: Apache-2.0
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, device/meizu/m3note/device.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
PRODUCT_NAME := lineage_m3note
PRODUCT_DEVICE := m3note
PRODUCT_BRAND := Meizu
PRODUCT_MODEL := M3 Note
PRODUCT_MANUFACTURER := Meizu
PRODUCT_SHIPPING_API_LEVEL := 22
PRODUCT_FULL_TREBLE_OVERRIDE := false
PRODUCT_CHARACTERISTICS := nosdcard
TARGET_BOOT_ANIMATION_RES := 1080
PRODUCT_BUILD_USERDATA_IMAGE := false
PRODUCT_BUILD_CACHE_IMAGE := false
PRODUCT_BUILD_RECOVERY_IMAGE := false
