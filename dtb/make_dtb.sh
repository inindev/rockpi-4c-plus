#!/bin/sh

set -e

# prerequisites: build-essential device-tree-compiler
# kernel.org linux version

main() {
    local lv='5.18.17'

    if [ 'clean' = "$1" ]; then
        rm -f *.dtb *-top.dts
        rm -rf "linux-$lv"
        echo '\nclean complete\n'
        exit 0
    fi

    if [ ! -f "linux-$lv.tar.xz" ]; then
        wget "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$lv.tar.xz"
    fi

    local lrcp="linux-$lv/arch/arm64/boot/dts/rockchip"
    if [ ! -d "linux-$lv" ]; then
        tar "xavf" "linux-$lv.tar.xz" "linux-$lv/include/dt-bindings" "linux-$lv/include/uapi" "$lrcp"
        ln -s '../../../../../../rk3399-rock-pi-4c-plus.dts' "$lrcp"
    fi

    if [ 'links' = "$1" ]; then
        ln -sf "$lrcp/rk3399.dtsi"
        ln -sf "$lrcp/rk3399-opp.dtsi"
        echo '\nlinks created\n'
        exit 0
    fi

    # build
    gcc -I "linux-$lv/include" -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o rk3399-rock-pi-4c-plus-top.dts "$lrcp/rk3399-rock-pi-4c-plus.dts"
    dtc -@ -I dts -O dtb -o rk3399-rock-pi-4c-plus.dtb rk3399-rock-pi-4c-plus-top.dts

    echo '\nbuild complete: rk3399-rock-pi-4c-plus.dtb\n'
}

main "$1"
