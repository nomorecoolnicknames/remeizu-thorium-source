# U10 own-stock LOS16 graph input, 2026-09-28

**Current inputs supersede the historical 49-file selection below:** the mapper
now scans top-level `libnativehelper/Android.bp:35`, and preparation/preflight
forbid stock libnativehelper. The current exact subset has **43 ELF files**
(**24 ELF32**, **19 ELF64**) and the unchanged own U10 kernel. Six old
files are removed: libnativehelper, libaed and libmrdump in both architectures;
the latter two were needed only by the old stock JNI-helper closure. Current
private output: `/dev/shm/remeizu-los16-stock-20260928/u10-vendor-stockgraph-r2`.
The old archives remain preserved but are superseded; their earlier Python/hash
preflight was not an Android graph or ABI test. Use current committed evidence:

```sh
python3 tools/u20_stockgraph.py --device u10 \
  --output /dev/shm/remeizu-los16-stock-20260928/u10-vendor-stockgraph-r2 \
  --verify-existing
```

**DIAGNOSTIC:** `lineage_u10_stockgraph-{userdebug,eng}` supplies own U10
kernel, core mount inputs and a reviewed native graphics/lights subset to a
strict cloud product graph. It is not a verified bootable ROM. The normal
`lineage_u10` product still needs a completed board kernel/vendor port.

## Exact board inputs

**FACT:** official U10 boot SHA256 is
`03bde51ce54248ac380d47adf8f37bc8a3de374b480a5bc9ef2d536682538188`.
Its ARM64 gzip Image plus appended DTB SHA256 is
`4631f9ba2ace6e3134eff743814d6ac58855fba1d1670eabf1359eda39628d85`;
the image identifies Linux **3.18.22+**, built 2018-04-12. This diagnostic product
clears donor kernel source/config and selects that exact U10 prebuilt.

**FACT:** U10 stock uses `ro.board.platform=mt6750`, HAL filenames such as
`gralloc.mt6750.so` and density **320**. Its own boot ramdisk nevertheless names
fstab/init/ueventd **mt6755**. These names are recorded independently; no U20
kernel, HAL, density or partition size is substituted. U10's ramdisk fstab uses
`11230000.msdc0/by-name`. Stock boot is bounded by 16 MiB and recovery by 30 MiB,
as pinned in `../BoardConfigStock.mk`; userdata capacity remains unknown.

The core fstab retains U10's system/data/cache entries and metadata encryption,
with the trailing empty comma removed. The recovery skeleton also includes its
own named boot/recovery paths. Minimal `mount_all /fstab.mt6755` comes from U10
stock init lines 103–106; `/dev/mali` and `/dev/ion` permissions come from U10
ueventd lines 107/110. Other stock services/actions require individual ABI and
SELinux review and are not packaged by this core graph. This is not a live
confirmation of init selection or safe recovery behavior.

## Native and binder gates

The private selection contains **49** own-stock ELF files, starting with both
architectures of U10's gralloc, HWC, lights and Mali EGL. The reviewed dependency
closure has unique U10 module names, explicit ELF classes, original installation
names and declared source/native providers. Only 11 selected hashes happen to
match U20 files at the same relative path; all 49 are verified against U10's
complete stock inventory. No stock libc, libbinder, libui, JNI or other forbidden
platform replacement is accepted.

**FACT:** stock 64-bit libbinder SHA256
`b66f758358a509ae155db1a09cce9a7723e64008419ceb50c1f4ae6dca65de27`
requests BINDER_VERSION ioctl `0xc0046209` at `0x36a10` and compares protocol 8
at `0x36a28`. Its 32-bit counterpart SHA256
`7e5c94423354706275799d83aa77dfbfd67bd57b41646d77ecc2ce00d121f791`
compares protocol 8 at Thumb address `0x23a28`. Read-only disassembly of the
actual U10 files confirms userspace expectations, not live driver support.

**FACT:** the exact kernel has binder ioctl/transaction strings but no IKCONFIG,
hwbinder/vndbinder/binder.devices strings. **INFERENCE:** 64-bit binder ABI is
consistent with the stock userspace; Android 9's newer binder transactions and
separate hardware/vendor devices remain unproven. The committed evidence keeps
`stock_binder_abi_verified=false` and `runtime_verified=false`.

**OPEN:** Android 6 MTK graphics have unverified symbol/structure compatibility
with the actual LOS16 providers. HWC1 adaptation, Mali dlopen dependencies,
init/services, SELinux and radio/audio/camera are separate gates. No linker
checks or missing dependency errors are disabled.

## Exact cloud gate

Extract the private payload only into an isolated Android source view:

| This checkout or private input | Android source-root destination |
| --- | --- |
| `device/meizu/u10/` | `device/meizu/u10/` |
| `device/meizu/mt6755-common/` | `device/meizu/mt6755-common/` |
| Private `u10-vendor-stockgraph-r1/` | `vendor/meizu/u10/` |
| Required tools and pinned evidence only | `.remeizu/u10-tools/` |

Run through Forge's Android 9 / SDK 28, JDK 8 container with its writable
`OUT_DIR`. For the `/src` mount:

```sh
bash /src/.remeizu/u10-tools/tools/run_u10_stockgraph.sh \
  /src /src/.remeizu/u10-tools userdebug
```

The shared private preparation/preflight implementation retains the name
`tools/u20_stockgraph.py` for compatibility; U10 explicitly passes `--device u10`.
It verifies the U10 evidence, every native/kernel hash and exact makefiles before
lunch. The runner exports `FORGE_OFFLINE_SOURCE_SNAPSHOT=1`, so the explicit
Forge offline roomservice platform patch must be installed. It verifies product,
variant and SDK 28, unsets missing-dependency suppression, then runs `m -j2 nothing`.
Only a zero exit writes `/workspace/out/u10-stockgraph-evidence.json` and
`/workspace/out/product-config.txt`; Forge keeps the full log. Identity explicitly
marks diagnostic-only and runtime-unverified. This cloud graph has not yet run.

Reconstruct the private skeleton from preserved official inputs, using an absent
output directory:

```sh
python3 tools/u20_stockgraph.py --device u10 \
  --private-stock /dev/shm/remeizu-los16-stock-20260928/u10 \
  --boot /srv/forge/android/flyme_fw/u10/unpacked/boot.img \
  --output /dev/shm/remeizu-los16-stock-20260928/u10-vendor-stockgraph-r1
```

For an existing skeleton use `--device u10 --output PATH --verify-existing`.
Private ELF/kernel bytes remain outside Git.

## Patch rationale

**Hypothesis:** packaging exact U10 core inputs exposes the next real LOS16 graph
failure without selecting a donor board kernel. **Evidence:** complete U10
inventory, own boot/ramdisk hashes, native classes/dependencies and binder
disassembly. **Files:** diagnostic product, rootdir/fstab, board overrides,
scoped common module discovery, shared board-aware preparation and strict runner.
**Expected next marker:** checked input identity followed by a strict cloud graph
log. **Rollback:** board identity mismatch, cross-board provider, platform library
replacement, incompatible geometry or proven ABI contradiction. Runtime support
must be measured after graph/compile gates; graph success cannot establish it.

**Validation:** 37 isolated tests pass, including rejection of cross-board HAL
selection and evidence. U10's actual private preflight verifies all 49 native
files, own kernel and generated makefiles; the unchanged U20 private output also
passes the shared implementation. Both runner shell syntax and Python 3.8 static
grammar pass. No local Android build, cloud graph or runtime test is claimed.
