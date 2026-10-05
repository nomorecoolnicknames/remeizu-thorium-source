LOCAL_PATH := $(call my-dir)
ifneq ($(filter lineage_u10 lineage_u20,$(TARGET_PRODUCT)),)
include $(CLEAR_VARS)
LOCAL_MODULE := thermal.mt6755
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_VENDOR_MODULE := true
LOCAL_MULTILIB := both
LOCAL_SRC_FILES := thermal.c
LOCAL_HEADER_LIBRARIES := libhardware_headers
LOCAL_CFLAGS := -std=c11 -Wall -Wextra -Werror
include $(BUILD_SHARED_LIBRARY)
endif
