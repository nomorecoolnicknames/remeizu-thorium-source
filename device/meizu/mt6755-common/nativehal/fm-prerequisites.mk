# This optional successor fragment only supplies U10 own receiver prerequisites.
# It requires a private profile produced by tools/native_fm_prerequisites.py.
# No app/JNI, transmitter capability, or runtime receiver acceptance is implied.
ifeq ($(strip $(TARGET_MEIZU_MT675X_DEVICE)),u10)
$(call inherit-product, vendor/meizu/u10-native-fm-prerequisites/fm-prerequisites-vendor.mk)
endif
