# ReMeizu Thorium

Shared Android device configuration for Meizu phones based on **MT6750 and
MT6755**, targeting **LineageOS 16.0 / Android 9**. The common tree contains
init configuration, compatibility libraries, overlays and framework patches;
small device trees select the board, vendor inputs and kernel configuration.

**Current milestone:** M3s, U10 and U20 have passed stock-backed product/dependency
checks. Their custom-kernel ROMs and hardware operation are still in development.
This repository contains device sources, not a complete Android checkout or a
universal kernel for every Meizu phone.

## Devices

| Device | Platform | Product / source | State in this repository |
|---|---|---|---|
| M3s | MT6750 | [`lineage_m3s`](device/meizu/m3s) | Stock-backed graph product available; custom board port pending |
| U10 | MT6750 | [`lineage_u10`](device/meizu/u10) | Stock-backed graph product available; custom board port pending |
| U20 | MT6755 | [`lineage_u20`](device/meizu/u20) | Stock-backed graph product available; custom board port pending |
| M6 | MT6750 | [`lineage_meizu_m6`](device/meizu/meizu_m6) | Shared configuration and M6-specific integration present |
| M3 Note M681 | MT6755 | [`lineage_m681`](device/meizu/m681) | Shared configuration and M681-specific integration present |
| M3 Note L681 | MT6755 | [`lineage_l681`](device/meizu/l681) | Thin product present; newer tested kernel work is maintained separately |
| M5 | MT6750 | [`lineage_m5`](device/meizu/m5) | Initial product; board parameters and kernel port incomplete |
| M5 Note | MT6755 | [`lineage_m5note`](device/meizu/m5note) | Initial product; board parameters and kernel port incomplete |
| M6T | MT6750 | [`lineage_m6t`](device/meizu/m6t) | Initial product; board integration incomplete |

M1 Note is a separate MT6752 platform: there is no build product for it here.
M2/M5c, M2 Note/M5s, MX6 and Qualcomm devices also use other platform trees.
For current hardware results from the wider project, see
[ReMeizu device status](https://github.com/nomorecoolnicknames/remeizu/blob/main/PROJECT_STATUS.md).
Those results do not establish that every common-tree product below works.

## Components

“Included” describes the checked-in build rules; “verified” describes the test
result. The normal products inherit `device-common.mk`. The three `stockgraph`
products use a smaller, separate set of inputs and do not exercise the whole
normal product. Common library discovery is currently selected for M6, M681
and the three stockgraph products; extending other normal products still needs
build integration. The module rules also contain a legacy M2 Note selector,
without a corresponding device product in this repository.

| Component | Implementation / source | Included or enabled | Verified state |
|---|---|---|---|
| Kernel, boot and recovery | Per-device `BoardConfig.mk`, [`BoardConfigStock.mk`](device/meizu/u20/BoardConfigStock.mk), [recovery fstab](device/meizu/mt6755-common/recovery/recovery.fstab) | Normal targets expect external `kernel/meizu/mt6755`; stockgraph selects the matching stock prebuilt | Stock boot layout parsed for M3s/U10/U20; custom board kernels remain unfinished |
| Dependency checks | [`u20_stockgraph.py`](tools/u20_stockgraph.py), [`run_u20_stockgraph.sh`](tools/run_u20_stockgraph.sh), corresponding M3s/U10 runners | Separate `lineage_*_stockgraph` products; missing-dependency checks retained | M3s/U10/U20 product and `m nothing` checks passed; no boot result |
| Display and GPU | [EGL configuration](device/meizu/mt6755-common/configs/egl.cfg), [MTK graphics headers](device/meizu/mt6755-common/include/hardware/include), [framework patches](device/meizu/mt6755-common/patches/frameworks_native) | OpenGL renderer selected; device kernel, HWC and EGL implementations supplied separately | Integration sources present; display/GPU behavior needs per-device testing |
| Wi-Fi | [`lib_driver_cmd_mt66xx`](device/meizu/mt6755-common/wpa_supplicant/mediatek_driver_cmd_nl80211.c), [supplicant build rules](device/meizu/mt6755-common/wpa_supplicant/Android.mk) | NL80211 supplicant/hostapd backend selected where common modules are included | Host command backend present; firmware, association and suspend not validated by graph checks |
| Bluetooth | [`libbt-vendor-mtk.c`](device/meizu/mt6755-common/libbt-vendor-mtk/libbt-vendor-mtk.c) | `BOARD_HAVE_BLUETOOTH_MTK` selects `libbt-vendor`; controller support remains external | Vendor interface source present; radio operation unverified for this branch |
| Audio | [Audio policy](device/meizu/mt6755-common/configs/audio_policy.conf), [device routing](device/meizu/mt6755-common/configs/audio_device.xml), [`device-common.mk`](device/meizu/mt6755-common/device-common.mk) | USB and remote-submix HALs requested; primary HAL comes from device vendor inputs | Routing configuration present; playback, recording and calls need device tests |
| Camera | [MTK camera headers](device/meizu/mt6755-common/include/hardware/include/mtkcam), [camera feature XML](device/meizu/mt6755-common/configs/android.hardware.camera.xml) | `USE_CAMERA_STUB := true` in common board config; vendor HAL and sensors are external | Feature declarations are not camera support; capture unverified |
| Sensors and GNSS | [Service declarations](device/meizu/mt6755-common/rootdir/init.mt6755.rc), [AGPS configuration](device/meizu/mt6755-common/configs/agps_profiles_conf2.xml) | Common init declares vendor daemons; availability depends on each vendor/kernel set | Configuration present; sensor events and location fixes unverified for this branch |
| Modem and RIL | [Modem init](device/meizu/mt6755-common/rootdir/init.modem.rc), [RIL proxy init](device/meizu/mt6755-common/rootdir/init.rilproxy.rc), `gsm0710muxd` package request | Dual-SIM/LTE properties coexist with bring-up `noril` settings; review before a full build | No voice/data/IMS acceptance from common-tree graph tests |
| Keystore | [`device-common.mk`](device/meizu/mt6755-common/device-common.mk) selects `keystore.default` | Software keystore requested; hardware TEE/keymaster not provided here | Hardware-backed key storage not established |
| Keys and display hooks | [Key layouts](device/meizu/mt6755-common/keylayout), [CM hardware hooks](device/meizu/mt6755-common/cmhw) | Common key layouts copied; hooks selected through `BOARD_HARDWARE_CLASS` | Source integration present; mBack, calibration and physical keys need board tests |
| Media codecs | [Codec configuration](device/meizu/mt6755-common/configs/media_codecs.xml), [MTK OMX configuration](device/meizu/mt6755-common/configs/mtk_omx_core.cfg) | Codec declarations and software encoder modules requested | Hardware codec libraries remain external; playback/recording unverified here |
| Power and charging | [Power profile](device/meizu/mt6755-common/overlay/frameworks/base/core/res/res/xml/power_profile.xml), [init services](device/meizu/mt6755-common/rootdir/init.mt6755.rc) | Framework profile and vendor power services declared; charging drivers live in the kernel | No battery, charging or suspend acceptance from this tree alone |
| Board identification | [`meizu_mt675x_detect.sh`](device/meizu/mt6755-common/rootdir/sbin/meizu_mt675x_detect.sh), [init entry](device/meizu/mt6755-common/rootdir/init.meizu_mt675x.rc) | Imported by common init; explicit M6/M681/L681 cases only | Sets identification properties; does not discover or initialize new hardware |
| SELinux | [Common contexts](device/meizu/mt6755-common/sepolicy/common), [M6 policy](device/meizu/mt6755-common/sepolicy/meizu_m6), [`BoardConfigCommon.mk`](device/meizu/mt6755-common/BoardConfigCommon.mk) | Common and per-device policy directories selected; permissive boot command line remains | Enforcing operation is not validated |

## What is shared

- A 64-bit ARM primary ABI with 32-bit userspace compatibility.
- Common init, overlays, MTK logging/Bluetooth/Wi-Fi interfaces and compatibility
  headers, with per-device vendor and board selections.
- Separate stock-backed dependency checks for M3s, U10 and U20, so each uses its
  own boot image and extracted inputs instead of another phone's kernel.

Panel, touch, camera, PMIC, charger and partition layouts remain board-specific.
The model registry is background information, not an automatic hardware probe.
MT6750 and MT6755 products are not interchangeable.

## Build and check

Use a LineageOS 16.0 platform with Java 8. Place this repository's `device/meizu/`
entries at the corresponding paths in the Android checkout. Normal products also
need matching `vendor/meizu/<device>` inputs, a completed kernel configuration,
and the platform compatibility changes required by their selected components.
The kernel and vendor payloads are not included in this repository. Review the
[framework patch set](device/meizu/mt6755-common/patches) against the chosen
platform revision before applying it.

For the existing U20 dependency-check workflow, prepare inputs from the matching
stock extraction and boot image into a **new** output directory:

```sh
python3 tools/u20_stockgraph.py --device u20 \
  --private-stock "$STOCK_EXTRACT" --boot "$STOCK_BOOT" --output "$VENDOR_OUTPUT"
python3 tools/u20_stockgraph.py --device u20 \
  --output "$VENDOR_OUTPUT" --verify-existing
```

The expected hashes and module inputs are in [`planning/los16-stock`](planning/los16-stock).
Place the verified output at `vendor/meizu/u20` in the Android checkout. Inside
the project's Android 9 build container, with writable `OUT_DIR` and the
[offline roomservice patch](planning/los16-stock/patches/0003-vendorsetup-offline-snapshot.patch), run:

```sh
bash tools/run_u20_stockgraph.sh "$ANDROID_TOP" "$THORIUM_ROOT" userdebug
```

This checks product, variant, SDK 28 and `m nothing`; it does **not** build a ROM
or test hardware. [M3s](device/meizu/m3s/stockgraph/README.md) and
[U10](device/meizu/u10/stockgraph/README.md) have equivalent instructions.
The normal `lineage_<device>` targets are separate from these graph products.

## Credits

[ReMeizu contributors](https://github.com/nomorecoolnicknames/remeizu),
[AOSP](https://source.android.com/) and [LineageOS](https://github.com/LineageOS),
including the CyanogenMod and MediaTek compatibility work retained in these
sources. The common/thin-device layout was inspired by Mi-Thorium’s MSM8937
unified device tree. Existing per-file copyright and license notices apply.
