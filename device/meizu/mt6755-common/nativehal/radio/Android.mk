LOCAL_PATH := $(call my-dir)
ifneq ($(filter $(TARGET_DEVICE),u10 u20),)
include $(CLEAR_VARS)
LOCAL_MODULE := meizu-calibration-ready
LOCAL_SRC_FILES := CalibrationReady.cpp
LOCAL_SHARED_LIBRARIES := libcutils
LOCAL_CFLAGS := -Wall -Wextra -Werror
LOCAL_MULTILIB := 64
include $(BUILD_EXECUTABLE)
endif
