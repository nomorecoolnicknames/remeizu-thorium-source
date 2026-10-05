LOCAL_PATH := $(call my-dir)
ifneq ($(filter $(TARGET_DEVICE),u10 u20),)
include $(CLEAR_VARS)
LOCAL_MODULE := meizu-spm-loader
LOCAL_MODULE_TAGS := optional
LOCAL_MULTILIB := 32
LOCAL_SRC_FILES := spm_loader.c
LOCAL_SHARED_LIBRARIES := liblog
LOCAL_CFLAGS := -Wall -Wextra -Werror
LOCAL_INIT_RC := init.meizu-spm.rc
include $(BUILD_EXECUTABLE)
endif
