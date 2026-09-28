# Android 9 API declaration for the Flyme resource extension

Category: PROPER-FIX.

Evidence: actual U20 cloud recipe
ebb537f3a5053b16701003d6f13b102ea636922aa8c84d2fb4fac399cd4c7db1
passed the prior Soong libnvram frontier, then Kati failed at
device/meizu/mt6755-common/flyme/res/Android.mk with
`flyme-res: Must specify LOCAL_SDK_VERSION or LOCAL_PRIVATE_PLATFORM_APIS`.
The raw log is retained privately in cloud_oss_builds/build/evidence/u20-graph-a3.
Helper-first local triage completed; the pure API classifier returned no issues
for this new error. Authenticated HTTP credentials remain unavailable; no reset.

Cause: the old framework resource extension predates Android9's explicit API
selection check in build/make/core/sdk_check.mk. Its manifest declares coreApp,
android.uid.system and framework-only application attributes; its resources are
exported using extending IDs and installed alongside framework libraries.
Selecting a public application SDK would misdescribe that module.

Change: declare LOCAL_PRIVATE_PLATFORM_APIS=true in this module only. No global
SDK enforcement bypass, warning downgrade or package-list change is made.

Validation: source diff and the exact pinned SDK check reviewed. The next strict
cloud Kati graph is the integration check; it has not passed at this checkpoint.
No kernel, firmware bytes, device configuration or runtime result changes.

Expected next marker: Kati proceeds beyond flyme-res SDK selection and retains
the next actual error or a verified graph SUCCESS.
Rollback: module API ownership disproved or a conflicting explicit SDK appears;
correct the owning module instead of disabling SDK enforcement globally.
