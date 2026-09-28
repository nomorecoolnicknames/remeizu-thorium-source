LOCAL_PATH:= $(call my-dir)

ifneq ($(filter meizu_m6 m2note m681, $(TARGET_DEVICE))$(filter lineage_u20_stockgraph lineage_u10_stockgraph lineage_m3s_stockgraph, $(TARGET_PRODUCT)),)

include $(call first-makefiles-under,$(LOCAL_PATH))

$(shell mkdir -p $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr)

endif
