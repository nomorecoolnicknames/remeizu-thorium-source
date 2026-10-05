# Meizu M3 Note · Android 9

Unified device configuration for **M681 and L681** on **LineageOS 16.0**, using a shared native **Linux 4.4.15** core with each revision's own appended DTB. This is a development source selection. It is separate from the Android 13 / Linux 4.9 port; that older port's observations do not establish support for this source pair.

The board profile is selected from device-tree compatible strings, bootloader panel identity and an optional explicit board property. Conflicting or missing identity selects `unknown` rather than borrowing the other board's firmware profile. The two DTBs and matching vendor profiles remain distinct. The goal is one installable ROM for both revisions; the current boot packaging retains per-board kernel/DTB identities and verification.

| Component | Source / integration | Status for this unified source selection |
|---|---|---|
| Board identity | `libinit/init_m3note.cpp`, revision selector and panel map | Host logic checked; physical profile acceptance pending |
| Kernel / boot | `prebuilt-kernel/EXPECTED-m681.txt`, `EXPECTED-l681.txt`, boot verification | Common 4.4 core and own DTBs selected; binaries supplied separately |
| Display / GPU | Shared vendor graphics and rotation profile | Per-board rotation selected; full unified hardware pass pending |
| Touch / keys | Kernel input and `keylayout/` | Layout integration present; both-revision validation pending |
| Modem / Wi-Fi / BT / GNSS | Board-specific firmware profiles and shared Android services | Integration present; external vendor inputs required; unified runtime pending |
| Audio | Vendor primary HAL, policy and compile-time ABI guard | Integration present; unified playback/recording pending |
| Sensors | Per-revision HAL selection and service configuration | M681/L681 bindings differ; all sensors need physical validation |
| Fingerprint / TEE | Revision-specific keystore selection, external vendor TA/HAL | Integration present; enrollment/authentication unverified |
| Camera | Legacy vendor HAL and provider | Kernel camera support incomplete; no working unified camera claimed |
| Charging / suspend / thermal | Health services and board kernel drivers | Development configuration; physical acceptance pending |
| USB / recovery | Init/FunctionFS configuration and legacy fstab | Source integration present; both-revision recovery/USB validation pending |
| Security | Development SELinux configuration | Permissive; enforcing operation not validated |

## Building

Use the matching LineageOS 16.0 platform and this common repository at the Android source root. Supply `vendor/meizu/m681`, the corresponding `vendor/meizu/m3note` board profiles, firmware, native kernel images and required platform compatibility patches. Binaries and restricted vendor inputs are not included. Kernel checksum gates retain the actual per-board expected inputs.

```sh
source build/envsetup.sh
lunch lineage_m3note-userdebug
mka bacon
```

Keep boot verification enabled and verify the target revision before installation. Compiled images and host profile tests do not prove physical operation. Original copyright and license notices are retained; vendor libraries and firmware have separate terms.
