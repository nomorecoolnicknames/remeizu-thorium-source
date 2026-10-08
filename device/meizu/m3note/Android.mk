LOCAL_PATH:= $(call my-dir)

ifneq ($(filter m3note, $(TARGET_DEVICE)),)

# l681 reuses three makefile sets that are gated on the DEVICE NAME and name
# m681 but not l681.  Without the includes below every module they define is
# silently absent for lineage_l681, and ckati stops on the first consumer
# (e.g. "libreference-ril missing libril", "wpa_supplicant missing
# lib_driver_cmd_mt66xx", "PRODUCT_PACKAGES mtk-ril: no such module").
# Nothing outside this tree is edited; each include reproduces exactly what the
# m681 product gets.  If one of those repos later adds l681 to its own filter,
# the duplicate definition fails the parse loudly -- then delete the matching
# include here.

# 1. This tree's own subdirectory makefiles: nvram/ (m681_nvram_wifi_repair).
#    Keep first, while LOCAL_PATH is still ours (m681 donor note: without it the
#    module finder stops at this Android.mk and nvram/ silently vanishes).
include $(call first-makefiles-under,$(LOCAL_PATH))

MTK_SYMBOLS_GUI_ONLY := true
include vendor/mediatek/symbols/Android.mk
MTK_SYMBOLS_GUI_ONLY :=
include vendor/mediatek/combo_loader/Android.mk
include vendor/mediatek/wlan/wifi_hal/Android.mk
include vendor/mediatek/ril/Android.mk

include device/meizu/m3_meizu_m6-common/flyme/res/Android.mk
include device/meizu/m3_meizu_m6-common/libbt-vendor-mtk/Android.mk
include device/meizu/m3_meizu_m6-common/libxlog/Android.mk
$(shell mkdir -p $(PRODUCT_OUT)/obj/KERNEL_OBJ/usr)

m3note_saved_target_device := $(TARGET_DEVICE)
TARGET_DEVICE := m681
include vendor/meizu/m681/Android.mk
TARGET_DEVICE := $(m3note_saved_target_device)
m3note_saved_target_device :=
ifeq ($(ALL_MODULES.mtk-ril.PATH),)
$(error m3note: vendor/meizu/m681/Android.mk defined no mtk-ril module -- its TARGET_DEVICE guard changed; see device/meizu/m3note/Android.mk step 4)
endif

include $(CLEAR_VARS)
LOCAL_PATH := device/meizu/m3note
LOCAL_MODULE := m3note_keystore_profile
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR_ETC)
LOCAL_SRC_FILES := keystore/m3note_keystore_profile.txt
LOCAL_REQUIRED_MODULES := m681_vendor_hal_symlinks
LOCAL_POST_INSTALL_CMD := \
    rm -f $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.mt6755.so \
          $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.mz6755_66_n.so \
          $(2ND_TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.mt6755.so \
          $(2ND_TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.mz6755_66_n.so && \
    ln -sf libMcTeeKeymaster.so $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.m681tee.so && \
    ln -sf libMcTeeKeymaster.so $(2ND_TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.m681tee.so
include $(BUILD_PREBUILT)

endif
