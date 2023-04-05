#!/bin/sh

set -e

main() {
    local linux='https://git.kernel.org/torvalds/t/linux-6.3-rc5.tar.gz'

    local lf=$(basename $linux)
    local lv=$(echo $lf | sed -nE 's/linux-(.*)\.tar\..z/\1/p')

    if [ '_clean' = "_$1" ]; then
        rm -f *.dtb *-top.dts *.dtsi
        rm -rf linux-$lv
        echo '\nclean complete\n'
        exit 0
    fi

    check_installed 'device-tree-compiler' 'gcc' 'wget' 'xz-utils'

    [ -f $lf ] || wget $linux

    local rkpath=linux-$lv/arch/arm64/boot/dts/rockchip
    if ! [ -d linux-$lv ]; then
        tar xavf $lf linux-$lv/include/dt-bindings linux-$lv/include/uapi $rkpath
        ln -sf '../../../../../../rk3399-rock-pi-4c-plus.dts' $rkpath
    fi

    if [ '_links' = "_$1" ]; then
        ln -sfv $rkpath/rk3399-t-opp.dtsi
        ln -sfv $rkpath/rk3399.dtsi
        echo '\nlinks created\n'
        exit 0
    fi

    # build
    local dt=rk3399-rock-pi-4c-plus
    gcc -I linux-$lv/include -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o ${dt}-top.dts $rkpath/${dt}.dts
    dtc -@ -I dts -O dtb -o ${dt}.dtb ${dt}-top.dts
    echo "\n${cya}device tree ready: ${dt}.dtb${rst}\n"
}

check_installed() {
    local todo
    for item in "$@"; do
        dpkg -l "$item" 2>/dev/null | grep -q "ii  $item" || todo="$todo $item"
    done

    if [ ! -z "$todo" ]; then
        echo "this script requires the following packages:${bld}${yel}$todo${rst}"
        echo "   run: ${bld}${grn}sudo apt update && sudo apt -y install$todo${rst}\n"
        exit 1
    fi
}

rst='\033[m'
bld='\033[1m'
red='\033[31m'
grn='\033[32m'
yel='\033[33m'
blu='\033[34m'
mag='\033[35m'
cya='\033[36m'
h1="${blu}==>${rst} ${bld}"

main $@

