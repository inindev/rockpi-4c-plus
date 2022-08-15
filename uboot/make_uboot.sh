#!/bin/sh

set -e

tag='v2022.07'
atf_url='https://github.com/atf-builds/atf/releases/download/v2.6/rk3399_bl31.elf'
atf_file=$(basename $atf_url)


if [ 'clean' = "$1" ]; then
    rm -f rksd_loader.img u-boot.itb
    rm -f u-boot/rk3399_bl31.elf
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
        for patch in patches/*.patch; do
            git -C u-boot am "../$patch"
        done
elif [ uboot-$tag != "$(git -C u-boot branch | sed -n -e 's/^\* \(.*\)/\1/p')" ]; then
    git -C u-boot checkout uboot-$tag
fi

if [ ! -f u-boot/$atf_file ]; then
    wget -cP u-boot $atf_url
fi

make -C u-boot distclean
make -C u-boot rock-pi-4c-plus-rk3399_defconfig
make -C u-boot -j$(nproc) BL31=$atf_file

# outputs: rksd_loader.img & u-boot.itb
u-boot/tools/mkimage -n rk3399 -T rksd -d u-boot/tpl/u-boot-tpl.bin rksd_loader.img
cat u-boot/spl/u-boot-spl.bin >> rksd_loader.img
cp u-boot/u-boot.itb .

echo '\nu-boot and spl binaries are now ready'
echo '\ncopy images to media:'
echo '  dd bs=4K seek=8 if=rksd_loader.img of=/dev/sdX conv=notrunc'
echo '  dd bs=4K seek=2048 if=u-boot.itb of=/dev/sdX conv=notrunc'
echo '  sync\n'
