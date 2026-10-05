LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libmeizu_icu55
LOCAL_SRC_FILES := Icu55.cpp
LOCAL_MULTILIB := both
LOCAL_C_INCLUDES := external/icu/icu4c/source/common
LOCAL_SHARED_LIBRARIES := libicuuc
LOCAL_CFLAGS := -Wall -Wextra -Werror
include $(BUILD_SHARED_LIBRARY)
