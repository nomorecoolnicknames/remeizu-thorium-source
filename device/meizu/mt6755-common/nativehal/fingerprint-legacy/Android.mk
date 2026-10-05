LOCAL_PATH := $(call my-dir)
ifneq ($(filter $(TARGET_DEVICE),u10 u20),)
include $(CLEAR_VARS)
LOCAL_MODULE := meizu.hardware.biometrics.fingerprint@2.1-service
LOCAL_MODULE_TAGS := optional
LOCAL_MULTILIB := 64
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_INIT_RC := meizu.hardware.biometrics.fingerprint@2.1-service.rc
LOCAL_SRC_FILES := BiometricsFingerprint.cpp service.cpp
LOCAL_SHARED_LIBRARIES := libbinder libcutils liblog libhidlbase libhidltransport libhardware libutils android.hardware.biometrics.fingerprint@2.1
LOCAL_CFLAGS := -Wall -Werror
ifeq ($(TARGET_DEVICE),u10)
LOCAL_CFLAGS += -DMZ_FP_U10
else
LOCAL_CFLAGS += -DMZ_FP_U20
endif
include $(BUILD_EXECUTABLE)
endif
