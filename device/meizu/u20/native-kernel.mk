# Compiled own U20 kernel; include after the normal BoardConfig.mk.
ifneq ($(TARGET_PRODUCT),lineage_u20)
$(error wrong product for u20 native kernel)
endif
ifeq ($(wildcard source-private/u20/kernel/Image.gz-dtb),)
$(error missing verified own u20 kernel)
endif
TARGET_KERNEL_SOURCE :=
TARGET_KERNEL_CONFIG :=
TARGET_KERNEL_ADDITIONAL_FLAGS :=
TARGET_KERNEL_ARCH := arm64
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_PREBUILT_KERNEL := source-private/u20/kernel/Image.gz-dtb
