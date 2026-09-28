# DIAGNOSTIC: own U10 core graph inputs; ABI/runtime remain unverified.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, device/meizu/u10/stockgraph/device.mk)

PRODUCT_NAME := lineage_u10_stockgraph
PRODUCT_DEVICE := u10
PRODUCT_BRAND := Meizu
PRODUCT_MODEL := Meizu U10
PRODUCT_MANUFACTURER := Meizu
PRODUCT_SHIPPING_API_LEVEL := 23
