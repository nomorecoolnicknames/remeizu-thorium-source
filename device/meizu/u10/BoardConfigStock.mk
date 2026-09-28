# Generated from the pinned Flyme boot header and adjacent scatter offsets.
# Not a live GPT readback; userdata capacity deliberately remains unset.
# boot SHA256: 03bde51ce54248ac380d47adf8f37bc8a3de374b480a5bc9ef2d536682538188
# scatter SHA256: 9660ead56b033e3e47a67d67c6652d3a72ab9d8cddf2f7ff7bed5e77103ae172
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_RAMDISK_OFFSET := 0x45000000
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x40080000 --ramdisk_offset 0x45000000 --second_offset 0x40f00000 --tags_offset 0x44000000
# Stock cmdline (reference; Android release policy stays in common): bootopt=64S3,32N2,64N2
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_CACHEIMAGE_PARTITION_SIZE := 452984832
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 31457280
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2684354560
