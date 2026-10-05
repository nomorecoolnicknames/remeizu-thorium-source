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

# 2. vendor/mediatek -- a copy of the m681 branch of vendor/mediatek/Android.mk
#    (revision 6dd7c54b "lane-telephony-head", the gunwest m6rom16 state, lines
#    19-47): the GUI-only symbol shims (libmtkshim_gui/ui/sensor/icu), the
#    generic wmt_loader, libwifi-hal-mt66xx.  Plus ril/, which the m681 device
#    Android.mk includes itself (libril + rild of the MTK Oreo HIDL RIL, gated
#    inside on BOARD_PROVIDES_LIBRIL / ENABLE_VENDOR_RIL_SERVICE).
MTK_SYMBOLS_GUI_ONLY := true
include vendor/mediatek/symbols/Android.mk
MTK_SYMBOLS_GUI_ONLY :=
include vendor/mediatek/combo_loader/Android.mk
include vendor/mediatek/wlan/wifi_hal/Android.mk
include vendor/mediatek/ril/Android.mk

# 3. device/meizu/m3_meizu_m6-common -- its Android.mk:3 admits only
#    "meizu_m6 m2note m681 M6T".  FACT: m681 takes lib_driver_cmd_mt66xx
#    (wpa_supplicant/), libbt-vendor (libbt-vendor-mtk/), libxlog and flyme-res
#    from there; its own device/meizu/m681/wpa_supplicant_8_lib is dead (never
#    defines the module) and is not carried into this tree.  The inner
#    makefiles guard only against m2note, so they parse for l681.
#    The mkdir mirrors that Android.mk too (prebuilt-kernel header path).
include $(call first-makefiles-under,device/meizu/m3_meizu_m6-common)
$(shell mkdir -p $(PRODUCT_OUT)/obj/KERNEL_OBJ/usr)

m3note_saved_target_device := $(TARGET_DEVICE)
TARGET_DEVICE := m681
include vendor/meizu/m681/Android.mk
TARGET_DEVICE := $(m3note_saved_target_device)
m3note_saved_target_device :=
ifeq ($(ALL_MODULES.mtk-ril.PATH),)
$(error m3note: vendor/meizu/m681/Android.mk defined no mtk-ril module -- its TARGET_DEVICE guard changed; see device/meizu/m3note/Android.mk step 4)
endif

# 5. m3note_keystore_profile -- the Trustonic keystore HAL per revision.
#    m681_vendor_hal_symlinks (step 4) links keystore.mt6755.so and
#    keystore.mz6755_66_n.so -> libMcTeeKeymaster.so; hw_get_module would find
#    them on every phone through ro.hardware=mt6755.  They are removed, and the
#    same TEE module is linked as keystore.m681tee.so, which only
#    ro.hardware.keystore=m681tee selects -- libinit sets it on m681 only.
#    l681 thus keeps the software keymaster it booted with (FACT, see
#    keystore/m3note_keystore_profile.txt); m681 keeps its Trustonic keymaster
#    as in the m681 donor.
#    LOCAL_REQUIRED_MODULES makes this module's install order-only-depend on
#    the m681 module's installed file (build/make/core/main.mk
#    add-required-deps), so the rm/ln below run after the m681 ln -sf.
#    LOCAL_PATH is spelled out: the includes above reassigned it.
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
