# Goodix direct loader runs before mounted system/vendor is available.
ifneq ($(TARGET_PRODUCT),lineage_u10)
$(error wrong product for U10 early firmware)
endif
ifeq ($(wildcard source-private/u10/runtime/goodix/u10.bin),)
$(error missing exact private U10 early firmware)
endif
ifneq ($(strip $(foreach cf,$(PRODUCT_COPY_FILES),$(filter root/lib/firmware/goodix/u10.bin,$(word 2,$(subst :, ,$(cf)))))),)
$(error conflicting or duplicate U10 early firmware destination)
endif
PRODUCT_COPY_FILES += source-private/u10/runtime/goodix/u10.bin:root/lib/firmware/goodix/u10.bin
