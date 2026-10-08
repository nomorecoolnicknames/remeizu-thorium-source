LOCAL_PATH := device/meizu/m3note
TARGET_MEIZU_MT675X_DEVICE := m681

$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
# Build Station additive port: this LOS 15.1/Oreo tree does not ship the
# frameworks/native/build/*dalvik-heap.mk presets (m6 also uses if-exists for
# the same path). m681 sets its own dalvik.vm.heap* props in lineage_m681.mk,
# so make this a no-op instead of a hard preflight break.
$(call inherit-product-if-exists, frameworks/native/build/phone-xxhdpi-3072-dalvik-heap.mk)
# Vendor: the m681 LOS16 set for both revisions plus the m681/l681 revision
# profiles (modem, WMT patches, sensors stack, TEE keystore), activated at
# runtime by ro.vendor.meizu.profile -- vendor/meizu/m3note/README.md.
# The L681H stock block of the l681 tree (@7a10a6a, top of its device.mk)
# moved there as profile-l681.mk, with its sha256 gate (L681_STOCK_DIR).
$(call inherit-product, vendor/meizu/m3note/m3note-vendor.mk)

# Sensor rc of both revisions (/dev + sysfs perms of the MTK sensor stack,
# msensord/akmd09911 services); see the file for the per-profile start.
# cpufreq arming rc: on by default, opt-out persist.vendor.m3note.cpufreq_arm=0.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/m3note-sensors.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/m3note-sensors.rc \
    $(LOCAL_PATH)/rootdir/m3note-cpufreq.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/m3note-cpufreq.rc \
    $(LOCAL_PATH)/rootdir/bin/m3note-cpufreq-arm.sh:$(TARGET_COPY_OUT_VENDOR)/bin/m3note-cpufreq-arm.sh \
    $(LOCAL_PATH)/rootdir/m3note-camera.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/m3note-camera.rc

# Panel -> revision list, one file for both readers: libinit_m3note
# (/vendor/etc) and the OTA revision check (install/, see releasetools.py).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/install/m3note-panels.tsv:$(TARGET_COPY_OUT_VENDOR)/etc/m3note-panels.tsv \
    $(LOCAL_PATH)/install/m3note-panels.tsv:install/m3note-panels.tsv \
    $(LOCAL_PATH)/install/bin/m3note-revision.sh:install/bin/m3note-revision.sh \
    $(LOCAL_PATH)/install/bin/m3note-boot-verify.sh:install/bin/m3note-boot-verify.sh

PRODUCT_DEVICE := m3note

# Keep the platform camera metadata library. The extracted Flyme copy shadows
# the AOSP/Lineage one and breaks app_process with a missing C++ symbol.
# `filter-out` patterns only support a single `%` wildcard; use the source-side
# prefix so the wildcard can swallow the trailing `:system/...` destination too.
PRODUCT_COPY_FILES := $(filter-out \
    %:system/lib/libcamera_metadata.so \
    %:system/lib64/libcamera_metadata.so \
    %:system/lib/libcamera_client.so \
    %:system/lib64/libcamera_client.so \
    %:system/lib/libcamera2ndk.so \
    %:system/lib64/libcamera2ndk.so \
    %:system/lib/libcameraservice.so \
    %:system/lib64/libcameraservice.so \
    %:system/lib/libaudioflinger.so \
    %:system/lib/libaudiopolicymanager.so \
    %:system/lib64/libaudiopolicymanager.so \
    %:system/lib/libaudiopolicymanagerdefault.so \
    %:system/lib64/libaudiopolicymanagerdefault.so \
    %:system/lib/libaudiopolicyservice.so \
    %:system/lib64/libaudiopolicyservice.so \
    %:system/lib/libaudiopolicyenginedefault.so \
    %:system/lib64/libaudiopolicyenginedefault.so \
    %:system/lib/libaudioeffect_jni.so \
    %:system/lib64/libaudioeffect_jni.so \
    %:system/etc/audio_policy_configuration.xml \
    %:system/etc/audio_policy_volumes.xml \
    %:system/etc/default_volume_tables.xml \
    %:system/etc/a2dp_audio_policy_configuration.xml \
    %:system/etc/usb_audio_policy_configuration.xml \
    %:system/etc/r_submix_audio_policy_configuration.xml \
    vendor/meizu/m681/proprietary/vendor/app/AtciService/% \
    vendor/meizu/m681/proprietary/vendor/app/AutoDialer/% \
    vendor/meizu/m681/proprietary/vendor/app/BatteryWarning/% \
    vendor/meizu/m681/proprietary/vendor/app/BtTool/% \
    vendor/meizu/m681/proprietary/vendor/app/CalendarImporter/% \
    vendor/meizu/m681/proprietary/vendor/app/DrmProvider/% \
    vendor/meizu/m681/proprietary/vendor/app/EngineerMode/% \
    vendor/meizu/m681/proprietary/vendor/app/Gba/% \
    vendor/meizu/m681/proprietary/vendor/app/LocationEM2/% \
    vendor/meizu/m681/proprietary/vendor/app/MDMLSample/% \
    vendor/meizu/m681/proprietary/vendor/app/MTKLogger/% \
    vendor/meizu/m681/proprietary/vendor/app/MTKThermalManager/% \
    vendor/meizu/m681/proprietary/vendor/app/MiraVision/% \
    vendor/meizu/m681/proprietary/vendor/app/MtkFloatMenu/% \
    vendor/meizu/m681/proprietary/vendor/app/RootPA/% \
    vendor/meizu/m681/proprietary/vendor/app/SelfRegister/% \
    vendor/meizu/m681/proprietary/vendor/app/SensorHub/% \
    vendor/meizu/m681/proprietary/vendor/app/SimRecoveryTestTool/% \
    vendor/meizu/m681/proprietary/vendor/app/YGPS/%,\
    $(PRODUCT_COPY_FILES))

ifneq ($(strip $(M681_PREBUILT_KERNEL)),)
$(error l681: M681_PREBUILT_KERNEL задан ($(M681_PREBUILT_KERNEL)) — ядро m681 в boot.img l681 недопустимо; снимите переменную)
endif
M681_EFFECTIVE_KERNEL_PREBUILT := $(strip $(TARGET_PREBUILT_KERNEL))
ifneq ($(M681_EFFECTIVE_KERNEL_PREBUILT),)
PRODUCT_COPY_FILES += \
    $(M681_EFFECTIVE_KERNEL_PREBUILT):kernel
endif

# audio (Виолетта) — start
# libaudio_param_parser.so searches these paths in order:
#   /sdcard/.audio_param/  /odm/etc/audio_param/  /vendor/etc/audio_param/  /system/etc/audio_param/
# vendor.mk already copies the calibration set to system/vendor/etc/audio_param/
# (= /vendor/etc/audio_param/ via the /vendor -> /system/vendor symlink).
# Do not create an early /odm symlink in init just for this; mirror to
# system/etc/audio_param/ as the safe fallback path instead.
M681_AUDIO_PARAM_SRC := $(wildcard vendor/meizu/m681/proprietary/vendor/etc/audio_param/*)
PRODUCT_COPY_FILES += \
    $(foreach f,$(M681_AUDIO_PARAM_SRC),$(f):system/etc/audio_param/$(notdir $(f)))
# Legacy MTK audio_policy.conf — also needed at /system/etc/ for policy
# managers that probe that path before /vendor/etc/.
PRODUCT_COPY_FILES += \
    vendor/meizu/m681/proprietary/vendor/etc/audio_policy.conf:system/etc/audio_policy.conf
# audio (Виолетта) — end

PRODUCT_COPY_FILES += \
    vendor/meizu/m681/proprietary/vendor/lib/libcurl.so:$(TARGET_COPY_OUT_VENDOR)/lib/libcurl.so \
    vendor/meizu/m681/proprietary/vendor/lib/libvmp_render.so:$(TARGET_COPY_OUT_VENDOR)/lib/libvmp_render.so \
    vendor/meizu/m681/proprietary/lib/libcamera_client.so:$(TARGET_COPY_OUT_VENDOR)/lib/libcamera_client.so \
    vendor/meizu/m681/proprietary/lib/libcamera_metadata.so:$(TARGET_COPY_OUT_VENDOR)/lib/libcamera_metadata.so \
    vendor/meizu/m681/proprietary/vendor/data/misc/ProjectConfig.mk:$(TARGET_COPY_OUT_VENDOR)/data/misc/ProjectConfig.mk \
    vendor/meizu/m681/proprietary/lib/libfilter_effects.so:system/lib/libfilter_effects.so \
    vendor/meizu/m681/proprietary/lib64/libfilter_effects.so:system/lib64/libfilter_effects.so \
    vendor/meizu/m681/proprietary/bin/goodixfingerprintd:system/bin/goodixfingerprintd \
    vendor/meizu/m681/proprietary/lib/libcamera_client_mtk.so:system/lib/libcamera_client_mtk.so \
    vendor/meizu/m681/proprietary/lib64/libcamera_client_mtk.so:system/lib64/libcamera_client_mtk.so \
    vendor/meizu/m681/proprietary/vendor/lib/libMcClient.so:system/lib/libMcClient.so \
    vendor/meizu/m681/proprietary/lib/libgf_ca.so:system/lib/libgf_ca.so \
    vendor/meizu/m681/proprietary/vendor/lib64/libvmp_render.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libvmp_render.so \
    vendor/meizu/m681/proprietary/lib64/libcamera_client.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libcamera_client.so \
    vendor/meizu/m681/proprietary/lib64/libcamera_metadata.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libcamera_metadata.so \
    vendor/meizu/m681/proprietary/vendor/lib64/libMcClient.so:system/lib64/libMcClient.so \
    vendor/meizu/m681/proprietary/lib64/libgf_hal.so:system/lib64/libgf_hal.so \
    vendor/meizu/m681/proprietary/lib64/libgf_ca.so:system/lib64/libgf_ca.so \
    vendor/meizu/m681/proprietary/lib64/libgf_algo.so:system/lib64/libgf_algo.so \
    vendor/meizu/m681/proprietary/vendor/bin/fuelgauged_static:system/bin/fuelgauged_static \
    $(LOCAL_PATH)/keylayout/fp-keys.kl:system/usr/keylayout/fp-keys.kl \
    $(LOCAL_PATH)/keylayout/mtk-kpd.kl:system/usr/keylayout/mtk-kpd.kl \
    $(LOCAL_PATH)/keylayout/ACCDET.kl:system/usr/keylayout/ACCDET.kl

# modem: per revision, in vendor/meizu/m3note -- the m681 donor block
# (modem_1_ulwctg_n.img / dsp_1_ulwctg_n.bin / boot_3_3g_n.rom) is
# profile-m681.mk, the L681H set profile-l681.mk (bind-mounted over the same
# names on l681).  ccci_mdinit probes /custom/etc/firmware then
# /vendor/firmware by variant name (donor note), so the file NAMES are the
# same on both revisions -- only the content differs.
# IMEI lives in NVRAM, not here: back up nvram/nvdata/proinfo before flashing.

PRODUCT_PROPERTY_OVERRIDES += \
    rild.libpath=mtk-ril.so \
    ril.first.md=1 \
    ril.active.md=12 \
    ril.current.share_modem=2 \
    ril.external.md=0 \
    ril.flightmode.poweroffMD=0 \
    ril.radiooff.poweroffMD=0 \
    ril.specific.sm_cause=0 \
    ril.telephony.mode=0 \
    ro.telephony.sim.count=2 \
    ro.telephony.default_network=9,9 \
    persist.m681.ril.no_ia=1 \
    persist.radio.default.sim=0 \
    persist.radio.mobile.data=1,1 \
    persist.radio.mobile.enable=1,1 \
    persist.radio.multisim.config=dsds \
    persist.radio.flashless.fsm=0 \
    persist.radio.flashless.fsm_cst=0 \
    persist.radio.flashless.fsm_rw=0 \
    persist.radio.fd.counter=15 \
    persist.radio.fd.off.counter=5 \
    persist.radio.fd.r8.counter=15 \
    persist.radio.fd.off.r8.counter=5 \
    persist.radio.mtk_dsbp_support=1 \
    persist.radio.mtk_ps2_rat=W/G \
    wifi.interface=wlan0 \
    wifi.direct.interface=wlan0 \
    wifi.tethering.interface=ap0 \
    ro.mtk.no_conn_autostart=true \
    qemu.hw.mainkeys=0 \
    ro.mediatek.wlan.wsc=1 \
    ro.mediatek.wlan.p2p=0 \
    ro.mediatek.gemini_support=true \
    ro.mediatek.chip_ver=S01 \
    ro.mediatek.version.sdk=4 \
    ro.mtk_agps_app=1 \
    ro.mtk_bt_support=1 \
    ro.mtk_c2k_support=0 \
    ro.mtk.c2k.om.mode=none \
    ro.mtk.c2k.slot2.support=0 \
    ro.mtk_dhcpv6c_wifi=1 \
    ro.mtk_eap_sim_aka=1 \
    ro.mtk_enable_md1=1 \
    ro.mtk_enable_md3=0 \
    ro.mtk_external_sim_support=0 \
    ro.mtk_gemini_support=1 \
    ro.mtk_gemini_enhancement=1 \
    ro.mtk_gps_support=1 \
    ro.mtk_lte_support=1 \
    ro.mtk_md_world_mode_support=1 \
    ro.mtk_modem_monitor_support=1 \
    ro.mtk_srlte_support=1 \
    ro.mtk_sim_hot_swap=1 \
    ro.mtk_sim_hot_swap_common_slot=1 \
    ro.mtk_trustonic_tee_support=1 \
    ro.mtk_wapi_support=1 \
    ro.mtk_wlan_support=1 \
    ro.mtk_world_phone=1 \
    ro.mtk_world_phone_policy=0 \
    ro.mtk_audio_ape_support=1 \
    ro.mtk_deinterlace_support=1 \
    ro.mtk_flv_playback_support=1 \
    ro.mtk_widevine_drm_l3_support=1 \
    ro.mtk_wmv_playback_support=1 \
    ro.mtk_wfd_support=1 \
    ro.mtk_wfd_sink_support=1 \
    ro.mtk_wfd_sink_uibc_support=1 \
    persist.mtk.datashaping.support=1 \
    persist.mtk.wcn.combo.chipid=-1 \
    persist.mtk.wcn.dynamic.dump=0 \
    persist.mtk.wcn.fwlog.status=no

# Android 7 PackageManager aborts early if any compiler-filter property is
# empty. Keep this in the common m681 product path so both cm_m681 and
# lineage_m681 inherit the same validated defaults.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    pm.dexopt.first-boot=verify-at-runtime \
    pm.dexopt.boot=verify-at-runtime \
    pm.dexopt.install=interpret-only \
    pm.dexopt.bg-dexopt=speed-profile \
    pm.dexopt.ab-ota=speed-profile \
    pm.dexopt.nsys-library=speed \
    pm.dexopt.shared-apk=speed \
    pm.dexopt.forced-dexopt=speed \
    pm.dexopt.core-app=speed

PRODUCT_PROPERTY_OVERRIDES += \
    persist.m681.cam.no_torch=0 \
    persist.m681.cam.force640=0 \
    persist.m681.cam.no_fullraw=1 \
    persist.m681.cam.p1path=2 \
    persist.m681.cam.pre_p1magic=1 \
    persist.m681.cam.sync_tuning=1 \
    persist.m681.cam.deq_retry=0 \
    persist.m681.cam.deq_us=50000 \
    persist.m681.cam.deq_to=100 \
    camera.disable_zsl_mode=1 \
    camera.zsdmode=0 \
    debug.featurepipe.enable=0 \
    debug.tworunpass2.enable=0 \
    debug.lowPowerVR.enable=0 \
    debug.forceFPS.enable=0 \
    debug.pass1.pdafon=0 \
    debug.pass1.rawtype=0 \
    debug.mtk_cam_zsdmfb_support=0 \
    debug.mtk_cam_zsdhdr_support=0 \
    debug.camera.vfb.disable=1 \
    debug.camera.eis.disable=1 \
    debug.eis.EMEnabled=0 \
    debug.eis.dump=0 \
    debug.eisDrv.dump=0 \
    debug.eis.disable=1 \
    persist.camera.eis.enable=0 \
    persist.camera.eis.disable=1 \
    persist.camera.vfb.enable=0 \
    persist.camera.vfb.disable=1 \
    cam.dumpnpipelog.enable=0 \
    camera.featurepipe.dumpvfb=0

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:system/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.telephony.cdma.xml:system/etc/permissions/android.hardware.telephony.cdma.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.autofocus.xml:system/etc/permissions/android.hardware.camera.autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:system/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:system/etc/permissions/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:system/etc/permissions/android.hardware.fingerprint.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:system/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.software.backup.xml:system/etc/permissions/android.software.backup.xml \
    frameworks/native/data/etc/android.software.print.xml:system/etc/permissions/android.software.print.xml \
    frameworks/native/data/etc/android.software.sip.xml:system/etc/permissions/android.software.sip.xml \
    packages/wallpapers/LivePicker/android.software.live_wallpaper.xml:system/etc/permissions/android.software.live_wallpaper.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_configuration.xml:system/etc/audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:system/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:system/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:system/etc/a2dp_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:system/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:system/etc/r_submix_audio_policy_configuration.xml \
    hardware/broadcom/wlan/bcmdhd/config/p2p_supplicant_overlay.conf:system/etc/wifi/p2p_supplicant_overlay.conf \
    hardware/broadcom/wlan/bcmdhd/config/wpa_supplicant_overlay.conf:system/etc/wifi/wpa_supplicant_overlay.conf \
    $(LOCAL_PATH)/wifi/wifi_concurrency_cfg.txt:system/etc/wifi/wifi_concurrency_cfg.txt \
    vendor/meizu/m681/proprietary/vendor/firmware/WMT_SOC.cfg:system/etc/firmware/WMT_SOC.cfg \
    $(LOCAL_PATH)/gps/gps.conf:system/etc/gps.conf \
    $(LOCAL_PATH)/media/media_codecs.xml:system/etc/media_codecs.xml \
    $(LOCAL_PATH)/media/media_codecs_performance.xml:system/etc/media_codecs_performance.xml \
    $(LOCAL_PATH)/media/media_codecs_mediatek_audio.xml:system/etc/media_codecs_mediatek_audio.xml \
    $(LOCAL_PATH)/media/media_codecs_mediatek_video.xml:system/etc/media_codecs_mediatek_video.xml \
    $(LOCAL_PATH)/media/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
    $(LOCAL_PATH)/media/media_codecs_google_video_le.xml:system/etc/media_codecs_google_video_le.xml \
    $(LOCAL_PATH)/media/media_profiles.xml:system/etc/media_profiles.xml \
    $(LOCAL_PATH)/rootdir/default.prop:root/default.prop \
    $(LOCAL_PATH)/rootdir/FWUpgradeInit.rc:root/FWUpgradeInit.rc \
    $(LOCAL_PATH)/sepolicy/file_contexts:root/file_contexts \
    $(LOCAL_PATH)/rootdir/fstab.mt6755:root/fstab.mt6755 \
    $(LOCAL_PATH)/rootdir/init.aee.rc:root/init.aee.rc \
    $(LOCAL_PATH)/rootdir/init.c2k.rc:root/init.c2k.rc \
    $(LOCAL_PATH)/rootdir/init.common_svc.rc:root/init.common_svc.rc \
    $(LOCAL_PATH)/rootdir/init.connectivity.rc:root/init.connectivity.rc \
    $(LOCAL_PATH)/rootdir/init.epdg.rc:root/init.epdg.rc \
    $(LOCAL_PATH)/rootdir/init.fon.rc:root/init.fon.rc \
    $(LOCAL_PATH)/rootdir/init.microtrust.rc:root/init.microtrust.rc \
    $(LOCAL_PATH)/rootdir/init.modem.rc:root/init.modem.rc \
    $(LOCAL_PATH)/rootdir/init.mt6755.rc:root/init.mt6755.rc \
    $(LOCAL_PATH)/rootdir/init.mt6755.usb.rc:root/init.mt6755.usb.rc \
    $(LOCAL_PATH)/rootdir/init.no_ssd.rc:root/init.no_ssd.rc \
    $(LOCAL_PATH)/rootdir/init.nvdata.rc:root/init.nvdata.rc \
    $(LOCAL_PATH)/rootdir/init.preload.rc:root/init.preload.rc \
    $(LOCAL_PATH)/rootdir/init.project.rc:root/init.project.rc \
    $(LOCAL_PATH)/rootdir/init.recovery.mt6755.rc:root/init.recovery.mt6755.rc \
    $(LOCAL_PATH)/rootdir/init.rilproxy.rc:root/init.rilproxy.rc \
    $(LOCAL_PATH)/rootdir/init.ssd.rc:root/init.ssd.rc \
    $(LOCAL_PATH)/rootdir/init.ssd_nomuser.rc:root/init.ssd_nomuser.rc \
    $(LOCAL_PATH)/rootdir/init.trace.rc:root/init.trace.rc \
    $(LOCAL_PATH)/rootdir/init.trustonic.rc:root/init.trustonic.rc \
    $(LOCAL_PATH)/rootdir/init.usb.configfs.rc:root/init.usb.configfs.rc \
    $(LOCAL_PATH)/rootdir/init.volte.rc:root/init.volte.rc \
    $(LOCAL_PATH)/rootdir/init.xlog.rc:root/init.xlog.rc \
    $(LOCAL_PATH)/rootdir/init.zygote32.rc:root/init.zygote32.rc \
    $(LOCAL_PATH)/rootdir/init.zygote64_32.rc:root/init.zygote64_32.rc \
    $(LOCAL_PATH)/rootdir/property_contexts:root/property_contexts \
    $(LOCAL_PATH)/rootdir/seapp_contexts:root/seapp_contexts \
    $(LOCAL_PATH)/rootdir/service_contexts:root/service_contexts \
    $(LOCAL_PATH)/rootdir/ueventd.mt6755.rc:root/ueventd.mt6755.rc \
    $(LOCAL_PATH)/rootdir/ueventd.rc:root/ueventd.rc \
    $(LOCAL_PATH)/rootdir/bin/pstore-preserve.sh:root/sbin/pstore-preserve.sh \
    $(LOCAL_PATH)/rootdir/bin/forge-nvram-fstab.sh:root/sbin/forge-nvram-fstab.sh \
    $(LOCAL_PATH)/rootdir/bin/forge-wifi-conf.sh:root/sbin/forge-wifi-conf.sh \
    $(LOCAL_PATH)/wifi/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
    $(LOCAL_PATH)/rootdir/bin/bootdiag-mark.sh:root/sbin/bootdiag-mark.sh \
    $(LOCAL_PATH)/rootdir/bin/mcregistry-setup.sh:root/sbin/mcregistry-setup.sh \
    $(LOCAL_PATH)/rootdir/bin/repair-userde.sh:root/sbin/repair-userde.sh \
    $(LOCAL_PATH)/rootdir/bin/m681_connectivity_autostart.sh:root/sbin/m681_connectivity_autostart.sh \
    $(LOCAL_PATH)/rootdir/bin/m681_wifi_kick.sh:system/bin/m681_wifi_kick.sh \
    $(LOCAL_PATH)/rootdir/bin/forge-ril-kick.sh:system/bin/forge-ril-kick.sh \
    $(LOCAL_PATH)/rootdir/forge-ril-kick.rc:system/etc/init/forge-ril-kick.rc \
    $(LOCAL_PATH)/rootdir/forge-diag.rc:system/etc/init/forge-diag.rc \
    $(LOCAL_PATH)/rootdir/bin/m681_mdtype_fix.sh:system/bin/m681_mdtype_fix.sh \
    $(LOCAL_PATH)/rootdir/bin/m681_postboot_recover.sh:system/bin/m681_postboot_recover.sh

PRODUCT_PACKAGES += \
    libfs_mgr \
    libion \
    libwifi-hal-mt66xx \
    libtinycompress \
    libtinyxml \
    libtinyxml_32 \
    libxml2 \
    m681_nvram_wifi_repair \
    org.apache.http.legacy \
    sgdisk \
    m681_vendor_hal_symlinks \
    m3note_keystore_profile \
    wpa_supplicant \
    wpa_supplicant.conf

# Build Station 15.1 port: MTK framework resources + VoLTE/VoWiFi + diag,
# re-added as BUILD_PREBUILT modules (vendor/meizu/m681/Android.mk). Flyme
# DataProtection deliberately excluded.
PRODUCT_PACKAGES += \
    mediatek-res \
    CustomPropInterface \
    ImsService \
    WfoService \
    CDS_INFO

# === Build Station 2026-06-28 (v206): restore Treble HAL-service backbone ===
# m681 LOS 15.1 shipped WITHOUT any android.hardware.*@*-service binaries in
# /vendor/bin/hw (only cas/configstore/omx/rild/wpa_supplicant were present).
# system_server therefore loops forever on `Waiting for service
# android.hardware.power@1.0::IPower/default`; audioserver SIGHUP-restarts every
# second on `Failed to obtain IDevicesFactory service`. Block mirrors
# meizu_m6/device_meizu_m6.mk:140–287 (same SoC family, same Nougat blobs).
# The .mtk-service source variants already live in vendor/mediatek/hidl/*; the
# generic packages compile from hardware/interfaces/*. The m6 HAL filter-out
# block (device_meizu_m6.mk:209–237) is NOT copied here — m681's
# PRODUCT_COPY_FILES already filters goldfish/default variants separately and
# ships only the mt6755 vendor blobs (m681-vendor.mk).

# Core HAL/service plumbing (m6:140–146)
PRODUCT_PACKAGES += \
    hwservicemanager \
    vndservicemanager \
    servicemanager \
    mediaserver

# Graphics/display (m6:149–161)
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.composer@2.1-impl \
    android.hardware.graphics.mapper@2.0-impl \
    android.hardware.memtrack@1.0-impl \
    android.hardware.renderscript@1.0-impl \
    libmtkshim_gui \
    libmtkshim_ui \
    libmtkshim_sensor \
    libmtkshim_icu

# Thermal / power / lights (m6:167–175)
PRODUCT_PACKAGES += \
    android.hardware.health@1.0-impl \
    android.hardware.health@1.0-service \
    android.hardware.thermal@1.0-impl \
    android.hardware.thermal@1.0-service \
    android.hardware.power@1.0-impl \
    power.default

PRODUCT_PACKAGES += \
    android.hardware.light@2.0-service \
    android.hardware.light@2.0-impl

PRODUCT_PACKAGES += \
    android.hardware.vibrator@1.0-service.mtk

# Audio (m6:178–192) — .mtk-service from vendor/mediatek/hidl/audio
PRODUCT_PACKAGES += \
    android.hardware.audio@2.0-impl \
    android.hardware.audio@2.0-service.mtk \
    android.hardware.audio.effect@2.0-impl \
    libaudiopolicymanagerdefault \
    libaudio-resampler \
    libnbaio \
    libtinyalsa \
    libtinycompress \
    libtinyxml \
    libfs_mgr

# Sensors (m6:199–201) — wrappers around the blob HAL, hw_get_module("sensors").
# m681: sensors.mt6755.so = m681 InvenSense MPL HAL (m681-vendor.mk).
# l681: sensors.l681.so = L681H stock hwmsen HAL (vendor/meizu/m3note
# profile-l681.mk), picked first through ro.hardware.sensors=l681 (libinit).
PRODUCT_PACKAGES += \
    android.hardware.sensors@1.0-impl.mtk \
    android.hardware.sensors@1.0-service.mtk

# Keymaster/DRM (m6:261–264)
PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-impl \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service

PRODUCT_PACKAGES += \
    android.hardware.gnss@1.0-impl \
    android.hardware.gnss@1.0-service \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service \
    libstagefright_soft_avcenc \
    libstagefright_soft_aacdec \
    libstagefright_soft_aacenc \
    libstagefright_soft_amrdec \
    libstagefright_soft_amrnbenc \
    libstagefright_soft_amrwbenc \
    libstagefright_soft_avcdec \
    libstagefright_soft_flacdec \
    libstagefright_soft_flacenc \
    libstagefright_soft_g711dec \
    libstagefright_soft_gsmdec \
    libstagefright_soft_hevcdec \
    libstagefright_soft_mp3dec \
    libstagefright_soft_mpeg2dec \
    libstagefright_soft_mpeg4dec \
    libstagefright_soft_mpeg4enc \
    libstagefright_soft_opusdec \
    libstagefright_soft_rawdec \
    libstagefright_soft_vorbisdec \
    libstagefright_soft_vpxdec \
    libstagefright_soft_vpxenc \
    libcurl \
    libandroid_net

PRODUCT_PACKAGES += \
    android.hardware.biometrics.fingerprint@2.0-service

# WLAN/BT (m6:99–111). libwifi-hal-mt66xx already above; rest from m6.
PRODUCT_PACKAGES += \
    android.hardware.wifi@1.0 \
    android.hardware.wifi@1.0-service \
    lib_driver_cmd_mt66xx \
    hostapd \
    wificond \
    wmt_loader \
    android.hardware.bluetooth@1.0-service.mtk

# sensors — use the stock vendor HAL for now.  The source-built
# sensors.lineage_m681 HAL crashes system_server in libinvensense_hal.so
# (MPLSensor ctor / impossible mounting orientation), which cascades into UI
# instability.  Keep the blob sensors.mt6755.so until the mount matrix and
# calibration path are fixed source-side.

# Build Station: keep Android 7 platform init.usb.rc
# Ship system/core/rootdir/init.usb.rc so service adbd exists; MTK USB triggers stay in init.<platform>.usb.rc.

# ---------------------------------------------------------------------------
# LineageOS 15.1 / Oreo — VINTF manifest + compatibility matrix
# These are installed to /system/manifest.xml and
# /system/compatibility_matrix.xml for the A-only semi-treble build.
# The manifest declares the HAL interfaces the Nougat vendor blobs expose
# (via legacy HIDL shims); the compatibility_matrix declares what the
# framework requires.  Both files live under sepolicy/ in this tree.
# ---------------------------------------------------------------------------
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/sepolicy/manifest.xml:system/manifest.xml \
    $(LOCAL_PATH)/sepolicy/compatibility_matrix.xml:system/compatibility_matrix.xml

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/sepolicy/manifest.xml:$(TARGET_COPY_OUT_VENDOR)/manifest.xml

# Oreo media_profiles renamed; keep the V1_0 suffix copy as well so
# legacy codecs that probe the old path still find it.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/media_profiles.xml:system/etc/media_profiles_V1_0.xml

# Build Station: target device identity override
PRODUCT_NAME := lineage_m3note
PRODUCT_DEVICE := m3note
PRODUCT_BRAND := meizu
PRODUCT_MANUFACTURER := Meizu
PRODUCT_MODEL := M3 Note
PRODUCT_RELEASE_NAME := m3note
TARGET_OTA_ASSERT_DEVICE := m3note,m681,l681,l681h,l91
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=lineage_m3note \
    PRODUCT_DEVICE=m3note \
    TARGET_DEVICE=m3note
# Build Station: keep Oreo platform init.rc
# Ship system/core/rootdir/init.rc; device triggers stay in init.${ro.hardware}.rc.

# Build Station: early ADB bring-up defaults
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.secure=0 \
    ro.debuggable=1 \
    ro.adb.secure=0
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.secure=0 \
    ro.debuggable=1 \
    ro.adb.secure=0 \
    persist.sys.usb.config=adb \
    persist.service.adb.enable=1 \
    persist.sys.adb.shell=/system/bin/sh

# v206 fix: libalsautils.so was MISSING from m681 (audioserver dlopen failed ->
# AudioFlinger RecordThread SIGSEGV). Sourced from the meizu_m6 Nougat blobs
# (same MT675x family; deps are all standard Oreo libs). Installs to
# /system/vendor/lib[64] where the MTK audio HAL searches.
PRODUCT_COPY_FILES += \
    vendor/meizu/m681/proprietary/vendor/lib/libalsautils.so:$(TARGET_COPY_OUT_VENDOR)/lib/libalsautils.so \
    vendor/meizu/m681/proprietary/vendor/lib64/libalsautils.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libalsautils.so

PRODUCT_COPY_FILES += \
    vendor/meizu/m681/proprietary/lib/libkeymaster1.so:system/lib/libkeymaster1.so \
    vendor/meizu/m681/proprietary/lib64/libkeymaster1.so:system/lib64/libkeymaster1.so

PRODUCT_COPY_FILES += \
    vendor/meizu/m681/proprietary/lib64/libsoftkeymaster.so:system/lib64/libsoftkeymaster.so

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/goodixfpd.rc:system/etc/init/goodixfpd.rc

PRODUCT_PROPERTY_OVERRIDES += ro.zygote.disable_gl_preload=true

# v206: SystemServer/PackageManagerService FATAL "PMS compiler filter settings
# are bad" — this tree doesn't inherit the AOSP phone-*.mk preset, so the
# pm.dexopt.* compiler-filter props are EMPTY and PackageManagerServiceCompilerMapping
# .checkProperties() throws IllegalStateException. Provide the Oreo 8.1 defaults.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    pm.dexopt.first-boot=quicken \
    pm.dexopt.boot=verify \
    pm.dexopt.install=quicken \
    pm.dexopt.bg-dexopt=speed-profile \
    pm.dexopt.ab-ota=speed-profile \
    pm.dexopt.inactive=verify \
    pm.dexopt.shared=speed

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    log.tag.McClient=S \
    log.tag.McDriverClient=S \
    log.tag.TeeSyCommonClient=S \
    log.tag.TeeSyMcClient=S \
    log.tag.vndksupport=S

PRODUCT_COPY_FILES += \
    device/meizu/m3note/seccomp/mediacodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy

ENABLE_VENDOR_RIL_SERVICE := true

PRODUCT_PACKAGES += \
    rild

PRODUCT_PACKAGES += \
    librilmtk \
    mtk-ril

# vendor/mediatek/ril/rild/Android.mk:65 has `#LOCAL_INIT_RC := rild.rc`
# commented out, so the MTK rild installs no init rc, and the AOSP rild that
# would have provided one is no longer built. Drop any inherited rild.rc and
# install ours. Mirrors meizu_m6/lineage.mk:167-175.
PRODUCT_COPY_FILES := $(filter-out %:$(TARGET_COPY_OUT_VENDOR)/etc/init/rild.rc, \
    $(PRODUCT_COPY_FILES))
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rild-mtk-hidl.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/rild.rc

PRODUCT_PACKAGES_DEBUG += \
    tinymix \
    tinycap \
    tinyplay

# HWC1 wrapper (hwcwrap/): the m681 HWC blob never powers the panel down
# (DispDevice::setPowerMode is an empty stub), so screen-off left the display
# pipeline running.  The wrapper adds FBIOBLANK around the blob's
# setPowerMode; selected by ro.hardware.hwcomposer=m3note (system.prop).
PRODUCT_PACKAGES += \
    hwcomposer.m3note

# Camera ABI shims for the m681 N set (shims/*, BoardConfig TARGET_LD_SHIM_LIBS).
PRODUCT_PACKAGES += \
    libm3note_jpgenc_shim \
    libm3note_icu56_shim \
    libm3note_dpfrag_shim \
    libm3note_gbuf_shim
