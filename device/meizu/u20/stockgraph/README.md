# U20 own-stock LOS16 graph input, 2026-09-28

**Current inputs supersede the historical 49-file selection below:** the mapper
now scans top-level `libnativehelper/Android.bp:35`, and preparation/preflight
forbid stock libnativehelper. The current exact subset has **43 ELF files**
(**24 ELF32**, **19 ELF64**) and the unchanged own U20 kernel. Six old
files are removed: libnativehelper, libaed and libmrdump in both architectures;
the latter two were needed only by the old stock JNI-helper closure. Current
private output: `/dev/shm/remeizu-los16-stock-20260928/u20-vendor-stockgraph-r3`.
The old archives remain preserved but are superseded; their earlier Python/hash
preflight was not an Android graph or ABI test. Use current committed evidence:

```sh
python3 tools/u20_stockgraph.py --device u20 \
  --output /dev/shm/remeizu-los16-stock-20260928/u20-vendor-stockgraph-r3 \
  --verify-existing
```

**DIAGNOSTIC:** `lineage_u20_stockgraph-{userdebug,eng}` is a separate product for
the first strict cloud product graph. `lineage_u20` remains the unfinished full
port. This checkpoint supplies real U20 core inputs and does not assert a boot,
radio/camera/audio service bring-up, recovery safety or release readiness.

## Proven inputs

**FACT:** official U20 boot SHA256
`411e2b06494dc2e623f3ddd72bf1cee10c28521666e2ea26e3763e47ecf08997`.
Its ARM64 gzip Image plus appended DTB is pinned as
`5afd87ed09acc4c5b4fe6f9b41261dc749c2a232d64578c2bb0e847f0f625ace`.
The separate graph selects that prebuilt with empty kernel source/config,
which is the supported no-source path in the current LOS16 `kernel.mk`.
It cannot silently compile the existing M6/m681 donor defconfig.

**FACT:** stock fstab uses `11230000.msdc0/by-name`, whereas the old common
recovery fstab uses `11240000.msdc1/by-name`. The core system/data/cache entries,
metadata encryption path, and boot/recovery names here come from the U20 boot
ramdisk. The stock userdata line's trailing empty comma is removed. Stock
partition/image bounds remain in `../BoardConfigStock.mk`; userdata capacity is
unknown. The vendor updater's old `/system/etc/recovery.fstab` contains obsolete
numeric mmcblk paths and is not used as the board geometry authority.

**FACT:** minimal `on fs / mount_all` originates in U20 stock init lines 83–89.
This graph does not copy the stock Android 6 framework init, its tune2fs command,
whole modem daemon list, or the M6 runtime detector. Peripheral/service init and
SELinux mapping are still unimplemented. The two uevent permissions are copied
from U20 stock for the paired Mali/ION userspace/kernel set; no driver is changed.

## Reviewed native skeleton and explicit ABI blockers

**FACT:** private generator selects U20 gralloc, HWC, lights and EGL/Mali for both
native architectures, then their reviewed own-stock dependency closure: **49
ELF files**. Each has a unique build module name, original installed filename,
explicit 32/64-bit class and dependency list. Dependencies with LOS16 providers
reference those source modules. Stock libc/libbinder/libui/libutils/libc++ and
Bluetooth JNI cannot be substituted by the generator. `libgpu_aux.so` is an
additional reviewed Mali dependency with its own stock hash; its NEEDED closure
is also resolved against the earlier full-stock map.

**FACT:** stock 64-bit libbinder SHA256
`c50bfb44d344e8efbaecf50c2dc1db37151fa795d616cd055798fe3ea23f2e98` requests ioctl
`0xc0046209` (BINDER_VERSION) at code `0x36a00–0x36a10` and compares protocol **8**
at `0x36a28`. The 32-bit library SHA256
`7e5c94423354706275799d83aa77dfbfd67bd57b41646d77ecc2ce00d121f791` also compares
protocol **8** at Thumb address `0x23a28` after its version ioctl. This proves
the stock userspace's expected protocol; it is not a live driver probe.

**FACT:** the decompressed pinned kernel contains binder ioctl/transaction names,
but no `IKCFG_ST`, `hwbinder`, `vndbinder` or `binder.devices` strings. A generated
kernel `.config` is unavailable. **INFERENCE:** the old binder protocol width is
consistent with the arm64/compat stock userspace, while Android 9's separate
hardware/vendor binder devices and newer transaction handling remain unproven.
Do not interpret this graph's success as proof that the kernel can boot Pie.

**OPEN ABI GATES:** every selected ELF records its unverified platform dependencies
in `planning/los16-stock/u20-stockgraph-evidence.json`. Stock MTK graphics were
built against Android 6 libui/libutils/libhardware, so symbol/version/structure
compatibility with actual built LOS16 providers still needs verification. HWC1
adaptation and Mali dlopen dependencies require runtime checks. No success shim,
disabled linker check or replacement AOSP/JNI library is introduced here.

## Next executable gate

1. In an isolated cloud source view, put this branch's `device/meizu/u20` and
   `device/meizu/mt6755-common` at those exact paths. Keep the active local
   buildhome and other cloud jobs untouched.
2. Generate or transfer the private vendor skeleton into
   `ANDROID_TOP/vendor/meizu/u20`. The prepared local directory is
   `/dev/shm/remeizu-los16-stock-20260928/u20-vendor-stockgraph-r2`.
   It contains no complete `u20-vendor.mk`, intentionally: it only supplies
   `u20-stockgraph-vendor.mk` for this diagnostic product.
3. Through the Forge ephemeral LOS16 launcher, with normal writable output and
   scratch mounts, invoke:

```sh
bash THORIUM_ROOT/tools/run_u20_stockgraph.sh ANDROID_TOP THORIUM_ROOT userdebug
```

The command first verifies every private native/kernel hash and exact generated
module/package declarations against committed evidence, then runs
`lunch lineage_u20_stockgraph-userdebug` and `m -j2 nothing` with missing-dependency
suppression unset. `eng` is the explicit alternative. This gate has **not yet been
run** against the complete cloud platform: its first actual Kati/Soong fatal is
the next unknown to capture. No fatal log or successful graph is invented.

Preparation, if private data must be reconstructed:

```sh
python3 tools/u20_stockgraph.py \
  --private-stock /dev/shm/remeizu-los16-stock-20260928/u20 \
  --boot /srv/forge/android/flyme_fw/u20/unpacked/boot.img \
  --output /dev/shm/remeizu-los16-stock-20260928/u20-vendor-stockgraph-r2
```

The output must be absent; an existing output can instead be checked with
`--output PATH --verify-existing`. Only code and metadata are committed.

### Portable source mapping and container command

The private cloud payload has an Android source-root-relative layout:

| Input in this Thorium checkout | Destination inside Android source root |
| --- | --- |
| `device/meizu/u20/` | `device/meizu/u20/` |
| `device/meizu/mt6755-common/` | `device/meizu/mt6755-common/` |
| Private `u20-vendor-stockgraph-r2/` | `vendor/meizu/u20/` |
| Three stockgraph tools and pinned evidence | `.remeizu/u20-tools/` |

Use an isolated source view, then execute through Forge's Android 9 / SDK 28,
JDK 8 container with its writable `OUT_DIR` supplied. For a `/src` source mount:

```sh
bash /src/.remeizu/u20-tools/tools/run_u20_stockgraph.sh \
  /src /src/.remeizu/u20-tools userdebug
```

The runner exports `FORGE_OFFLINE_SOURCE_SNAPSHOT=1` for Forge's explicit offline
roomservice support; that platform patch must be present in the source snapshot.
It does not fetch repositories or hide unresolved modules. Preparation and
verification avoid Python 3.9 string/dictionary APIs so the Focal Python 3.8 host
can execute them. Python 3.8 grammar was checked statically; local unit tests ran
on Python 3.11. The cloud interpreter execution remains the authoritative check.

The runner checks actual `TARGET_PRODUCT`, `TARGET_BUILD_VARIANT` and
`PLATFORM_SDK_VERSION=28` after lunch and before `m nothing`. Only after the graph
exits zero does it publish the unchanged pinned input evidence as
`/workspace/out/u20-stockgraph-evidence.json` and the checked identity as
`/workspace/out/product-config.txt`. The latter explicitly marks
`diagnostic_only=true` and `runtime_verified=false`. Forge retains the full log;
`OUT_DIR` may be scratch and is not assumed to be a published artifact directory.

## Patch rationale and rollback

**Hypothesis:** stock-core packaging can close the known absent kernel/vendor
inputs cheaply enough to expose the next real LOS16 graph failure without
pretending the donor board kernel is U20. **Evidence:** exact boot/ramdisk/native
hashes, U20 fstab controller, both native ELF classes and stock binder checks.
**Files:** new diagnostic product and core rootdir; conditional own-kernel
selection; common module discovery for the U20 graph; private generator,
preflight and tests. **Expected next marker:** verified preflight followed by a
real strict graph log. **Rollback:** any identity/ownership mismatch, unexpected
cross-board dependency, platform library overwrite or source-provider ABI
contradiction. Existing full-product behavior is not a runtime baseline.

**Verification:** six stockgraph tests plus the previous 29 tests pass in this
checkout (35 total); shell syntax passes; actual private preflight verifies all
49 native hashes, the own-kernel hash, exact package/module declarations and the
absence of unexpected vendor files. Cloud Kati/Soong graph execution is pending.
