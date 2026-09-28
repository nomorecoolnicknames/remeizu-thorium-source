# DIAGNOSTIC: own M3s graph inputs; stock Android 5.1 ABI remains unverified.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, device/meizu/m3s/stockgraph/device.mk)

PRODUCT_NAME := lineage_m3s_stockgraph
PRODUCT_DEVICE := m3s
PRODUCT_BRAND := Meizu
PRODUCT_MODEL := Meizu M3s
PRODUCT_MANUFACTURER := Meizu
PRODUCT_SHIPPING_API_LEVEL := 22
