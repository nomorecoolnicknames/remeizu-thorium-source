# m3note-boot-l681.mk -- the l681 boot image of the common M3 Note ROM.
# Included by build/make/core/Makefile:3588 (device/*/*/build/tasks/*.mk) AFTER
# the standard boot.img rule, so INTERNAL_BOOTIMAGE_ARGS and friends exist.
# Same ramdisk, cmdline, geometry and mkbootimg as boot.img; only the kernel is
# Image.gz-dtb-l681 (BoardConfig.mk M3NOTE_L681_KERNEL).  Output lands in
# $(PRODUCT_OUT)/install, which core/Makefile:2842 puts into target-files as
# INSTALL/ and ota_from_target_files CopyInstallTools into the zip as install/.
ifeq ($(TARGET_DEVICE),m3note)

M3NOTE_BOOT_L681 := $(PRODUCT_OUT)/install/boot-l681.img
M3NOTE_BOOT_L681_ARGS := $(subst --kernel $(INSTALLED_KERNEL_TARGET),--kernel $(M3NOTE_L681_KERNEL),$(INTERNAL_BOOTIMAGE_ARGS))
ifeq ($(M3NOTE_BOOT_L681_ARGS),$(INTERNAL_BOOTIMAGE_ARGS))
$(error m3note: could not replace the kernel in INTERNAL_BOOTIMAGE_ARGS for boot-l681.img)
endif

$(M3NOTE_BOOT_L681): PRIVATE_ARGS := $(M3NOTE_BOOT_L681_ARGS) $(INTERNAL_MKBOOTIMG_VERSION_ARGS) $(BOARD_MKBOOTIMG_ARGS)
$(M3NOTE_BOOT_L681): $(MKBOOTIMG) $(M3NOTE_L681_KERNEL) $(filter-out $(INSTALLED_KERNEL_TARGET),$(INTERNAL_BOOTIMAGE_FILES))
	$(call pretty,"Target boot image (l681): $@")
	$(hide) mkdir -p $(dir $@)
	$(hide) $(MKBOOTIMG) $(PRIVATE_ARGS) --output $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_BOOTIMAGE_PARTITION_SIZE))
	$(hide) echo "$$(stat -c %s $@) $$(sha256sum $@ | cut -d' ' -f1)" > $@.size-sha256

# target-files must also see the installer helpers (device.mk PRODUCT_COPY_FILES
# into $(PRODUCT_OUT)/install) when it copies install/ as INSTALL/.
$(BUILT_TARGET_FILES_PACKAGE): $(M3NOTE_BOOT_L681) \
    $(addprefix $(PRODUCT_OUT)/install/,m3note-panels.tsv bin/m3note-revision.sh bin/m3note-boot-verify.sh)
droidcore: $(M3NOTE_BOOT_L681)

.PHONY: m3note-boot-l681
m3note-boot-l681: $(M3NOTE_BOOT_L681)

endif
