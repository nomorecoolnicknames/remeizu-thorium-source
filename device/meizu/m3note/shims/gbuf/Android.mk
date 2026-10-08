LOCAL_PATH := $(call my-dir)

# GraphicBuffer(ANativeWindowBuffer*, bool) for libeffecthal.base of the m681
# camera set (gbuf_shim.cpp).
include $(CLEAR_VARS)
LOCAL_MODULE := libm3note_gbuf_shim
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MULTILIB := both
LOCAL_SRC_FILES := gbuf_shim.cpp
LOCAL_SHARED_LIBRARIES := liblog libui libutils
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_SHARED_LIBRARY)
