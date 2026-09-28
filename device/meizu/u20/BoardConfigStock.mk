# Generated from the pinned Flyme boot header and adjacent scatter offsets.
# Not a live GPT readback; userdata capacity deliberately remains unset.
# boot SHA256: 411e2b06494dc2e623f3ddd72bf1cee10c28521666e2ea26e3763e47ecf08997
# scatter SHA256: 19a9ff5900fec31f7c6f87a6338399295d9c13d9cb783608d5065f752330bf34
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_RAMDISK_OFFSET := 0x45000000
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x40080000 --ramdisk_offset 0x45000000 --second_offset 0x40f00000 --tags_offset 0x44000000
# Stock cmdline (reference; Android release policy stays in common): bootopt=64S3,32N2,64N2
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_CACHEIMAGE_PARTITION_SIZE := 452984832
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2684354560
