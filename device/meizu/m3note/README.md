# Meizu M3 Note · Android 13

Experimental unified **LineageOS 20.0** device configuration for **M681 and L681**, targeting one Linux 4.9 core with separate board DTBs and vendor profiles. This source tip includes board selection from the device tree, per-revision VINTF manifests and corrected vendor symlink installation. The earlier complete ROM build used source revision `89a7e734`; later source changes do not establish a new complete build or hardware acceptance.

| Component | Source / integration | Current status |
|---|---|---|
| Board profile | `libinit/`, per-revision VINTF and init | DT/board selection implemented; both-board acceptance pending |
| Boot / installer | `installer/`, Linux board/factory UAPI | Common system and own-DTB boots; verification/readback logic present; public factory table empty, installation disabled |
| Display / graphics | `hwcomposer/`, Nougat ABI shims and external Mali/gralloc | Source integration present; common graphics closure pending |
| Touch / keys | Per-board kernel resources and input configuration | M681 lifecycle work present; L681 resource ownership incomplete |
| Wi-Fi / BT / modem / GNSS | Selected vendor profile, init and legacy compatibility | Integration present; complete two-board runtime acceptance pending |
| Audio | Vendor primary HAL and source compatibility | Integration present; full playback/recording/routing acceptance pending |
| Sensors / vibrator | Per-revision service selection and source vibrator | Source integrated; individual physical tests pending |
| TEE / fingerprint | Board-specific vendor services and manifest selection | Different TEE providers; enrollment/authentication acceptance pending |
| Camera | Legacy provider and external vendor camera stack | Complete common camera support pending |
| Power / charging / thermal | Board-specific PMIC/charger drivers and health integration | No unified daily-operation or thermal acceptance claimed |
| Security | Development SELinux policy and guarded deployment | Permissive; enforcing/encryption not accepted |

## Build inputs

Use a matching LineageOS 20.0 platform with this directory at `device/meizu/m3note`. Supply the corresponding source-built common kernel and generated headers, two independently identified vendor profiles and compatible platform libraries/patches. The public source contains no vendor blob, kernel image, capture or physical device identity. The default public installer factory-pair table is empty and admits no deployment. Guarded diagnostic build scope does not bypass source or profile checks.

The current source product is `lineage_m3note-userdebug`. Matching platform integration and independently verified private build inputs are required before a complete build can be attempted. Android-generated OTA output is intermediate: the common package tooling must supply both own-DTB boots and verify target identity, boot geometry and readback. A successful compiler exit does not establish installation safety or working hardware.

Android 9 and native Linux 4.4 are maintained separately on [lineage-16.0](https://github.com/nomorecoolnicknames/remeizu-thorium-source/tree/lineage-16.0/device/meizu/m3note). Original copyright and license notices are retained. Restricted vendor libraries and firmware are separate inputs.

## Current integration

The unified tree now selects per-board VNDK/keymaster configuration, starts the Trustonic daemon only when its device node exists, and contains a source fingerprint service with per-board bindings. Init creates the MTP/PTP gadget functions. Fingerprint enrollment, modem operation and complete two-revision hardware acceptance remain pending. Board profiles and derived vendor inputs are external; this public source includes no extracted firmware or proprietary archive. The guarded public installer still requires independently verified device inputs.
