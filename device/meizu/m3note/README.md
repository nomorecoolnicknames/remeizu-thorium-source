# Meizu M3 Note · Android 11

Unified LineageOS 18.1 device configuration for M681 and L681, with a common Linux 4.4 core and independently identified board DTBs/vendor profiles. The current source adapts the shared device product to Android 11. Compilation and earlier board observations do not establish complete two-board operation for this source selection.

| Component | Source / integration | Acceptance boundary |
|---|---|---|
| Board identity | libinit and per-board vendor profiles | Both revisions require independent profile validation |
| Boot / filesystems | First-stage by-name fstab, board init, kernel identity checks | Matching source-built images supplied separately |
| Graphics / camera / audio | Common source shims and legacy vendor HAL integration | Full Android11 component validation pending |
| Modem / connectivity / sensors | Per-board services and vendor firmware | Calls, data, RF and individual sensors require physical tests |
| USB / ADB | Android11 default properties and FunctionFS compatibility | AIO compatibility configured for the legacy kernel |
| Security | Development SELinux policy | Permissive; enforcing operation not accepted |

Use a matching LineageOS 18.1 platform and `lineage_m3note-userdebug`. Supply the corresponding source-built board kernels and lawfully obtained vendor profiles/firmware. Kernel checks retain the selected image hashes; no binary kernel, stock profile or device identity is distributed here. Shared kernel source is maintained on ReMeizu/android_kernel_meizu_mt675x, branch m3note-4.4; a newer kernel source tip is not automatically the exact image selected by this branch.

Android9 and Android13 configurations are maintained separately on lineage-16.0 and lineage-20.0. Other inherited common/thin directories in this branch retain their original integration state and do not establish Android11 support for every model.
