#!/bin/sh -e


# Use the daisy board and snow device tree
BOARD=daisy
FDT=snow

# Build things now that we've patched it up
#USE="cros_ec" emerge-${BOARD} chromeos-ec chromeos-u-boot chromeos-bootimage
USE="cros_ec" emerge-${BOARD} chromeos-u-boot chromeos-bootimage

# Produce U_BOOT file and find the text_start
dump_fmap -x /build/${BOARD}/firmware/nv_image-${FDT}.bin U_BOOT
TEXT_START=$(awk '$NF == "__text_start" { printf "0x"$1 }' \
/build/${BOARD}/firmware/System.map)

# Make it look like an image U-Boot will like:
# The "-a" and "-e" here are the "CONFIG_SYS_TEXT_BASE" from
# include/configs/exynos5-common.h
sudo mkimage \
-A arm \
-O linux \
-T kernel \
-C none \
-a "${TEXT_START}" -e "${TEXT_START}" \
-n "Non-verified u-boot" \
-d U_BOOT /build/${BOARD}/firmware/nv_uboot-snow.uimage

MY_BINARY=/build/${BOARD}/firmware/nv_uboot-snow.uimage

# Sign the uimage
echo blah > dummy.txt
sudo vbutil_kernel \
--pack /build/${BOARD}/firmware/nv_uboot-snow.kpart \
--keyblock /usr/share/vboot/devkeys/kernel.keyblock \
--signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
--version 1 \
--vmlinuz ${MY_BINARY} \
--bootloader dummy.txt \
--config dummy.txt \
--arch arm

KPART=/build/${BOARD}/firmware/nv_uboot-snow.kpart

echo " "
echo "Now run:"
echo "sudo dd if=$KPART of=/dev/<sd_card_part_1>"

