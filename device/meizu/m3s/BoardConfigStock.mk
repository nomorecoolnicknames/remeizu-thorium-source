# Generated from the pinned Flyme boot header and adjacent scatter offsets.
# Not a live GPT readback; userdata capacity deliberately remains unset.
# boot SHA256: f0b4f31d205a2ce052bb8f0118ee89e5bca322fce5bcf2f638f04e4936205e9a
# scatter SHA256: 3aa3292813ca5b473acbabb50496c10b604e425a7f525c5149cf82609e3c608e
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_RAMDISK_OFFSET := 0x45000000
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x40080000 --ramdisk_offset 0x45000000 --second_offset 0x40f00000 --tags_offset 0x44000000
# Stock cmdline (reference; Android release policy stays in common): bootopt=64S3,32N2,64N2
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_CACHEIMAGE_PARTITION_SIZE := 452984832
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 22020096
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2684354560
