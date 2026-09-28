# Product kernel-header output path on Android9

Category: PROPER-FIX.

Evidence: actual U20 a4 recipe
86e4f74bd33a13b120ba8e00be662e4677ba40c49a926ca1dbfc778adf5d9750
passed the corrected flyme-res API check, then Kati stopped at the common
Android.mk:7: OUT is obsolete. Complete log and helper-first local triage are
retained privately in cloud_oss_builds/build/evidence/u20-graph-a4.
The source API classifier initially returned no issue for this exact error.

Cause: the old mkdir reads envsetup's interactive OUT alias. Pinned Android9
build/make/envsetup.sh:288-289 assigns it to ANDROID_PRODUCT_OUT, derived from
PRODUCT_OUT. build/make/core/config.mk:65 rejects OUT in Make modules.
build/make/core/envsetup.mk:499-501 defines TARGET_OUT_INTERMEDIATES as the
product's obj directory (obj_asan when appropriate). OUT_DIR is the whole
build-output root, so blindly substituting OUT_DIR would change the target path.

Change: use TARGET_OUT_INTERMEDIATES/KERNEL_OBJ/usr for the existing directory
creation. This retains product isolation and correctly follows ASAN's obj path.
It does not invent headers, generate success stubs, or bypass Kati enforcement.
No package selection or kernel source/binary changes.

Validation: exact pinned envsetup/core definitions reviewed; source diff clean.
Next integration check is a new immutable SDK28/userdebug cloud graph. No graph
or compilation success is claimed at this source checkpoint.

Expected next marker: common Android.mk parses and the next actual graph error
or Forge SUCCESS is retained. Rollback: path ownership differs from the product
intermediate directory; fix the module owner, never disable obsolete-var checks.
