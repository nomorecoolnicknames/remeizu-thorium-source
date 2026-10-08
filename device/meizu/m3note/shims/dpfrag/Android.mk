LOCAL_PATH := $(call my-dir)

# Newer DpFragStream API for libJpgDecPipe of the m681 camera set (dpfrag_shim.c).
include $(CLEAR_VARS)
LOCAL_MODULE := libm3note_dpfrag_shim
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MULTILIB := both
LOCAL_SRC_FILES := dpfrag_shim.c
LOCAL_SHARED_LIBRARIES := liblog
# libdpframework.so is a PRODUCT_COPY_FILES blob, not a module: its
# DpFragStream / DpBasicBufferPool symbols stay undefined here and resolve at
# load time from libJpgDecPipe's own NEEDED libdpframework.so.
LOCAL_ALLOW_UNDEFINED_SYMBOLS := true
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_SHARED_LIBRARY)
