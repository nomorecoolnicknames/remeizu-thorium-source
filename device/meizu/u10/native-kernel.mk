# Compiled own U10 kernel; include after the normal BoardConfig.mk.
ifneq ($(TARGET_PRODUCT),lineage_u10)
$(error wrong product for u10 native kernel)
endif
ifeq ($(wildcard source-private/u10/kernel/Image.gz-dtb),)
$(error missing verified own u10 kernel)
endif
TARGET_KERNEL_SOURCE :=
TARGET_KERNEL_CONFIG :=
TARGET_KERNEL_ADDITIONAL_FLAGS :=
TARGET_KERNEL_ARCH := arm64
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_PREBUILT_KERNEL := source-private/u10/kernel/Image.gz-dtb
