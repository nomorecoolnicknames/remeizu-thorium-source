LOCAL_PATH := $(call my-dir)

# JpgEncHal::setEncSize 4-argument shim for the m681 camera set (jpgenc_shim.c).
include $(CLEAR_VARS)
LOCAL_MODULE := libm3note_jpgenc_shim
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MULTILIB := both
LOCAL_SRC_FILES := jpgenc_shim.c
# libJpgEncPipe.so is a PRODUCT_COPY_FILES blob, not a module: the 3-argument
# symbol stays undefined here and resolves at load time from libfeatureio's
# own NEEDED libJpgEncPipe.so (the shim is linked into libfeatureio's group).
LOCAL_ALLOW_UNDEFINED_SYMBOLS := true
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_SHARED_LIBRARY)
