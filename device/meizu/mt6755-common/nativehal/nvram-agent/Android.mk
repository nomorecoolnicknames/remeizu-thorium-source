LOCAL_PATH := $(call my-dir)
ifneq ($(filter $(TARGET_DEVICE),u10 u20),)
include $(CLEAR_VARS)
LOCAL_MODULE := libmeizu_nvramagent_binder_compat
LOCAL_MODULE_TAGS := optional
LOCAL_MULTILIB := 64
LOCAL_SRC_FILES := ServiceManagerFacade.cpp
LOCAL_SHARED_LIBRARIES := libbinder libutils libc++ libdl liblog
LOCAL_CFLAGS := -Wall -Wextra -Werror
LOCAL_CPPFLAGS := -std=c++14
include $(BUILD_SHARED_LIBRARY)
endif
