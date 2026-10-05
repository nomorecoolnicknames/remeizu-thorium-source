# Build Station additive port into the meizu_m6 LineageOS 15.1 tree.
# Single clean lineage_m3note product (one ROM for m681 + l681, fork of the l681 LOS16 tree); the legacy CM-14.1 lane is dropped (its
# product makefile is not shipped here) so no foreign-prefixed product registers.
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_m3note.mk

COMMON_LUNCH_CHOICES := \
    lineage_m3note-userdebug \
    lineage_m3note-eng
