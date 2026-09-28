# Own-board Soong NVRAM provider after actual U20 cloud failure

Category: PROPER-FIX (diagnostic build input ownership).

Evidence: Forge recipe 8ef5b4cc660b6688028aae594a1405068f0559c88184be5b90157433c49484d6,
lineage_u20_stockgraph-userdebug, Android9/SDK28. First fatal at
vendor/mediatek/hidl/bluetooth/Android.bp:15:1: android.hardware.bluetooth@1.0-service.mtk
depends on undefined module libnvram. The platform parses that global Soong
module even though the diagnostic product does not select the MTK Bluetooth
service. M5s already passes this stage with its own real multilib provider.

Hypothesis: each isolated newcomer source view also needs its own real provider;
a foreign phone library, stub, or missing-dependency bypass would be incorrect.

Change: tools/u20_stockgraph.py verifies the exact full-stock inventory SHA and
ELF class of lib/libnvram.so and lib64/libnvram.so, copies those two inputs and
emits one multilib Android.bp provider. Committed per-board evidence separately
records these global graph providers and their DT_NEEDED lists. Existing native
Make modules and graphics PRODUCT_PACKAGES are unchanged: this does not select
Bluetooth/NVRAM for installation or claim the unverified runtime dependency ABI.
Adding those features later requires their complete dependency/ABI closure.

Validation: all53 source tests pass; actual own-stock prepare and verify pass for
M3s(47 graphics native files+2 graph providers), U10/U20(43+2 each). Wrong board
bytes/ELF class, modified provider declaration and changed private bytes fail.
The full source API classifier correctly identifies android_soong_undefined_module_dep;
authenticated HTTP remains unavailable (existing401). Helper local triage first
retained the generic failed graph node; the pure API classification is retained
next to the original cloud log on the controller.

Expected next marker: the same strict SDK28/userdebug graph proceeds beyond the
undefined libnvram module and retains the exact next failure or a verified Forge
SUCCESS receipt. No kernel or phone runtime acceptance follows from this change.
Rollback: unexpected native-provider overlap, provenance drift or an unintended
installed NVRAM/Bluetooth module blocks progression pending ownership review.

M3s/U10/U20 stock kernels remain diagnostic references only. The target kernels
are custom source trees being reconstructed from stock DT/config/Ghidra evidence.
