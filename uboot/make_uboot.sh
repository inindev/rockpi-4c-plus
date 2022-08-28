#!/bin/sh

set -e

tag='v2022.07'
atf_url='https://github.com/atf-builds/atf/releases/download/v2.6/rk3399_bl31.elf'
atf_file=$(basename $atf_url)


if [ 'clean' = "$1" ]; then
    rm -f idbloader*.img u-boot.itb
#    rm -f u-boot/rk3399_bl31.elf
    make -C u-boot distclean
    git -C u-boot clean -f
    git -C u-boot checkout master
    git -C u-boot branch -D uboot-$tag
    git -C u-boot pull --ff-only
    exit 0
fi

if [ ! -d u-boot ]; then
    git clone https://github.com/u-boot/u-boot.git
    git -C u-boot fetch --tags
fi

if ! git -C u-boot branch | grep -q uboot-$tag; then
    git -C u-boot checkout -b uboot-$tag $tag
        cp -v files/rock-pi-4c-plus-rk3399_defconfig u-boot/configs
        cp -v files/rock-pi-4c-plus-rk3399_spiflash_defconfig u-boot/configs
        cp -v files/rk3399-rock-pi-4c-plus.dts u-boot/arch/arm/dts
        cp -v files/rk3399-rock-pi-4c-plus-u-boot.dtsi u-boot/arch/arm/dts
elif [ uboot-$tag != "$(git -C u-boot branch | sed -n -e 's/^\* \(.*\)/\1/p')" ]; then
    git -C u-boot checkout uboot-$tag
fi

if [ ! -f u-boot/$atf_file ]; then
    wget -cP u-boot $atf_url
fi

# outputs: idbloader.img & u-boot.itb
make -C u-boot distclean
make -C u-boot rock-pi-4c-plus-rk3399_defconfig
make -C u-boot -j$(nproc) BL31=$atf_file
cp u-boot/idbloader.img .
cp u-boot/u-boot.itb .

# outputs: idbloader-spi.img & u-boot.itb
make -C u-boot rock-pi-4c-plus-rk3399_spiflash_defconfig
make -C u-boot -j$(nproc) BL31=$atf_file
u-boot/tools/mkimage -n rk3399 -T rkspi -d u-boot/tpl/u-boot-tpl.bin:u-boot/spl/u-boot-spl.bin idbloader-spi.img

# make spi image file
#dd bs=64K count=64 if=/dev/zero | tr '\000' '\377' > rockpi-4cplus-uboot-spi.img
#dd bs=4K seek=8 if=u-boot/idbloader-spi.img of=rockpi-4cplus-uboot-spi.img conv=notrunc
#dd bs=4K seek=512 if=u-boot/u-boot.itb of=rockpi-4cplus-uboot-spi.img conv=notrunc

echo '\nidb loader and u-boot binaries are now ready'
echo '\ncopy images to media:'
echo '  dd bs=4K seek=8 if=idbloader.img of=/dev/sdX conv=notrunc'
echo '  dd bs=4K seek=2048 if=u-boot.itb of=/dev/sdX conv=notrunc,fsync'
echo
echo 'flash to spi (optional):'
echo '  flash_erase /dev/mtd0 0 0'
echo '  nandwrite /dev/mtd0 idbloader-spi.img'
echo '  flash_erase /dev/mtd2 0 0'
echo '  nandwrite /dev/mtd2 u-boot.itb'
echo
