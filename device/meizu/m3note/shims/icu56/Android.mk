LOCAL_PATH := $(call my-dir)

# ICU 56 -> 60 forwarders for the N libskia.so of the m681 camera set (icu56_shim.cpp).
include $(CLEAR_VARS)
LOCAL_MODULE := libm3note_icu56_shim
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MULTILIB := both
LOCAL_SRC_FILES := icu56_shim.cpp
LOCAL_SHARED_LIBRARIES := libicuuc
LOCAL_C_INCLUDES := external/icu/icu4c/source/common
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_SHARED_LIBRARY)
