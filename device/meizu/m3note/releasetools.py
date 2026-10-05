# releasetools.py -- OTA extension of the common M3 Note Android 9 ROM
# (m681 + l681).  BoardConfig.mk: TARGET_RELEASETOOLS_EXTENSIONS.
#
# The zip carries the standard boot.img (m681 kernel/DTB) and
# install/boot-l681.img (same ramdisk, l681 DTB; build/tasks/m3note-boot-l681.mk).
#  * FullOTA_Assertions -- before anything is written: the revision from the
#    panel LK names in lcm= (install/m3note-panels.tsv, the list libinit also
#    reads), recovery boot mode, by-name/boot = mmcblk0p22.  Any doubt aborts.
#  * FullOTA_InstallEnd -- after the standard WriteRawImage("/boot"): on l681
#    boot-l681.img goes over it through by-name, then a readback check.
# Installed only by hand from OrangeFox/TWRP; no automatic flashing.

import common

BYNAME_BOOT = "/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name/boot"


def FullOTA_Assertions(info):
  info.script.AppendExtra(
      'package_extract_file("install/bin/m3note-revision.sh", "/tmp/m3note-revision.sh");\n'
      'package_extract_file("install/m3note-panels.tsv", "/tmp/m3note-panels.tsv");\n'
      'set_metadata("/tmp/m3note-revision.sh", "uid", 0, "gid", 0, "mode", 0755);\n'
      'run_program("/tmp/m3note-revision.sh", "/tmp/m3note-panels.tsv") == 0 || '
      'abort("E: M3 Note: revision not determined or unsafe to write '
      '(recovery boot mode, lcm= panel m681/l681, by-name/boot); see /tmp/recovery.log. '
      'If TWRP was not started by \\"reboot recovery\\", do that and install again.");')


def FullOTA_InstallEnd(info):
  info.script.AppendExtra(
      'if run_program("/sbin/sh", "-c", "grep -qx l681 /tmp/m3note-revision") == 0 then\n'
      '  ui_print("M3 Note l681: writing boot-l681.img");\n'
      '  package_extract_file("install/boot-l681.img", "%s");\n'
      '  run_program("/tmp/install/bin/m3note-boot-verify.sh", "/tmp/install/boot-l681.img.size-sha256") == 0 || '
      'abort("E: M3 Note l681: boot readback mismatch; boot holds a partial image, reflash from recovery");\n'
      'else\n'
      '  ui_print("M3 Note m681: standard boot.img");\n'
      'endif;' % BYNAME_BOOT)
