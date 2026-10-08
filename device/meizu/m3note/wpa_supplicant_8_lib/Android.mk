ifneq ($(filter m3note, $(TARGET_DEVICE)),)

LOCAL_PATH := device/meizu/m3_meizu_m6-common/wpa_supplicant

include $(CLEAR_VARS)
LOCAL_MODULE := lib_driver_cmd_mt66xx
LOCAL_SHARED_LIBRARIES := libc libcutils
LOCAL_SRC_FILES := mediatek_driver_cmd_nl80211.c
LOCAL_C_INCLUDES := \
    external/wpa_supplicant_8/src \
    external/wpa_supplicant_8/src/common \
    external/wpa_supplicant_8/src/drivers \
    external/wpa_supplicant_8/src/l2_packet \
    external/wpa_supplicant_8/src/utils \
    external/wpa_supplicant_8/src/wps \
    external/wpa_supplicant_8/wpa_supplicant \
    external/libnl/include
LOCAL_CFLAGS := \
    -DANDROID_P2P \
    -DCONFIG_ACS \
    -DCONFIG_ANDROID_LOG \
    -DCONFIG_AP \
    -DCONFIG_BACKEND_FILE \
    -DCONFIG_CTRL_IFACE \
    -DCONFIG_CTRL_IFACE_HIDL \
    -DCONFIG_CTRL_IFACE_UNIX \
    -DCONFIG_DRIVER_NL80211 \
    -DCONFIG_DRIVER_NL80211_QCA \
    -DCONFIG_GAS \
    -DCONFIG_HIDL \
    -DCONFIG_HMAC_SHA256_KDF \
    -DCONFIG_HS20 \
    -DCONFIG_IEEE80211AC \
    -DCONFIG_IEEE80211N \
    -DCONFIG_IEEE80211R \
    -DCONFIG_IEEE80211W \
    -DCONFIG_INTERWORKING \
    -DCONFIG_IPV6 \
    -DCONFIG_LIBNL20 \
    -DCONFIG_NO_ACCOUNTING \
    -DCONFIG_NO_RADIUS \
    -DCONFIG_NO_RANDOM_POOL \
    -DCONFIG_NO_ROAMING \
    -DCONFIG_NO_VLAN \
    -DCONFIG_OFFCHANNEL \
    -DCONFIG_P2P \
    -DCONFIG_SHA256 \
    -DCONFIG_SMARTCARD \
    -DCONFIG_SME \
    -DCONFIG_TDLS \
    -DCONFIG_WIFI_DISPLAY \
    -DCONFIG_WNM \
    -DCONFIG_WPS \
    -DCONFIG_WPS_ER \
    -DCONFIG_WPS_NFC \
    -DCONFIG_WPS_OOB \
    -DCONFIG_WPS_UPNP \
    -DEAP_AKA \
    -DEAP_AKA_PRIME \
    -DEAP_GTC \
    -DEAP_LEAP \
    -DEAP_MD5 \
    -DEAP_MSCHAPv2 \
    -DEAP_OTP \
    -DEAP_PEAP \
    -DEAP_PWD \
    -DEAP_SERVER \
    -DEAP_SERVER_IDENTITY \
    -DEAP_SERVER_WSC \
    -DEAP_SIM \
    -DEAP_TLS \
    -DEAP_TLS_OPENSSL \
    -DEAP_TTLS \
    -DEAP_WSC \
    -DIEEE8021X_EAPOL \
    -DNEED_AP_MLME \
    -DPKCS12_FUNCS \
    -DWPA_IGNORE_CONFIG_ERRORS
include $(BUILD_STATIC_LIBRARY)

endif
