# DIAGNOSTIC: U20 own-stock kernel/core-input graph, not a release product.
# Normal missing dependency checks remain enabled.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, device/meizu/u20/stockgraph/device.mk)

PRODUCT_NAME := lineage_u20_stockgraph
PRODUCT_DEVICE := u20
PRODUCT_BRAND := Meizu
PRODUCT_MODEL := Meizu U20
PRODUCT_MANUFACTURER := Meizu
PRODUCT_SHIPPING_API_LEVEL := 23
