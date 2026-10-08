LOCAL_PATH := $(call my-dir)

# HWC1 wrapper: real panel power-down on screen off (hwcwrap.c header).
include $(CLEAR_VARS)
LOCAL_MODULE := hwcomposer.m3note
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MULTILIB := both
LOCAL_SRC_FILES := hwcwrap.c
LOCAL_HEADER_LIBRARIES := libhardware_headers
LOCAL_SHARED_LIBRARIES := liblog libdl
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_SHARED_LIBRARY)
