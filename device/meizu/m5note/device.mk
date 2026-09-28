# Meizu M5 Note (m5note) — LOS16 product wiring; board bring-up remains incomplete
TARGET_MEIZU_MT675X_DEVICE := m5note
LOCAL_PATH := device/meizu/m5note
$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
$(call inherit-product, vendor/meizu/m5note/m5note-vendor.mk)
