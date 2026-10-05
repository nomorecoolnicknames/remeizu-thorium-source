LOCAL_PATH := $(call my-dir)
ifneq ($(filter $(TARGET_DEVICE),u10 u20),)
include $(CLEAR_VARS)
LOCAL_MODULE := meizu.hardware.camera.provider@2.4-service
LOCAL_MODULE_TAGS := optional
LOCAL_MULTILIB := 64
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_INIT_RC := meizu.hardware.camera.provider@2.4-service.rc
LOCAL_SRC_FILES := service.cpp
LOCAL_SHARED_LIBRARIES := libbinder libhardware libcamera_metadata liblog libhidlbase libhidltransport libutils android.hardware.camera.provider@2.4
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_EXECUTABLE)
endif
