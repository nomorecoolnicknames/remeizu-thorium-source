# SPDX-License-Identifier: Apache-2.0
LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),m3note)
# Vendor symlinks of the M681 blob set, as m681_vendor_symlinks in the M681 LOS 20
# treble tree (vendor/meizu/m681/Android.mk): keymaster 3.0 / gatekeeper load
# keystore.<platform>.so / gatekeeper.<platform>.so, which in the N set are the MobiCore
# TEE libraries; MobiCore looks for its registry under /vendor/app. The targets are
# profile-mounted files. A FAKE module has no installed file, so systemimage never
# built it (u4, 2026-10-05): the links hang off a small installed text file instead.
include $(CLEAR_VARS)
LOCAL_MODULE := m3note_vendor_symlinks
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_VENDOR_MODULE := true
LOCAL_SRC_FILES := vendor_symlinks.txt
LOCAL_MODULE_STEM := m3note_vendor_symlinks.txt
LOCAL_POST_INSTALL_CMD := \
    for lib in lib lib64; do \
        mkdir -p $(TARGET_OUT_VENDOR)/$$lib/hw; \
        for n in mt6755 mz6755_66_n; do \
            ln -sf libMcGatekeeper.so $(TARGET_OUT_VENDOR)/$$lib/hw/gatekeeper.$$n.so; \
            ln -sf libMcTeeKeymaster.so $(TARGET_OUT_VENDOR)/$$lib/hw/keystore.$$n.so; \
        done; \
    done; \
    mkdir -p $(TARGET_OUT_VENDOR)/app; \
    rm -rf $(TARGET_OUT_VENDOR)/app/mcRegistry; \
    ln -sf ../etc/mcRegistry $(TARGET_OUT_VENDOR)/app/mcRegistry
include $(BUILD_PREBUILT)
endif
