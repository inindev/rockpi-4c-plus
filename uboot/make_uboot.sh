#!/bin/sh

set -e

# script exit codes:
#   1: missing utility

main() {
    local utag='v2023.04'
    local atf_url='https://github.com/atf-builds/atf/releases/download/v2.8/rk3399_bl31.elf'
    local atf_sha='adc7cc6088d95537f8509056d21eb45b11d15d704804b0f4a34b52b21bddcb1e'
    local atf_file=$(basename $atf_url)

    # branch name is yyyy.mm
    local branch="$(echo "$utag" | sed -rn 's/.*(20[2-9][3-9]\.[0-1][0-9]).*/\1/p')"
    echo "${bld}branch: $branch${rst}"

    if is_param 'clean' "$@"; then
        rm -f *.img *.itb
        if [ -d u-boot ]; then
            #rm -f u-boot/rk3399_bl31.elf
            rm -f u-boot/simple-bin.fit.*
            make -C u-boot distclean
            git -C u-boot clean -f
            git -C u-boot checkout master
            git -C u-boot branch -D "$branch" 2>/dev/null || true
            git -C u-boot pull --ff-only
        fi
        echo '\nclean complete\n'
        exit 0
    fi

    check_installed 'bc' 'bison' 'flex' 'libssl-dev' 'make' 'python3-dev' 'python3-pyelftools' 'python3-setuptools' 'swig'

    if [ ! -d u-boot ]; then
        git clone https://github.com/u-boot/u-boot.git
        git -C u-boot fetch --tags
    fi

    if ! git -C u-boot branch | grep -q "$branch"; then
        git -C u-boot checkout -b "$branch" "$utag"

        # pci: pcie_dw_rockchip: release resources on failing probe
        # https://github.com/u-boot/u-boot/commit/e04b67a7f4c1c326bf8c9376c0c7ba5ed9e5075d
        git -C u-boot cherry-pick e04b67a7f4c1c326bf8c9376c0c7ba5ed9e5075d

        # nvme: Enable PCI bus mastering
        # https://github.com/u-boot/u-boot/commit/38534712cd4c4d8acdf760ee87ba219f82d738c9
        git -C u-boot cherry-pick 38534712cd4c4d8acdf760ee87ba219f82d738c9

        local patch
        for patch in patches/*.patch; do
            git -C u-boot am "../$patch"
        done
    elif [ "$branch" != "$(git -C u-boot branch --show-current)" ]; then
        git -C u-boot checkout "$branch"
    fi

    [ -f u-boot/$atf_file ] || wget -cP u-boot $atf_url
    if [ "$atf_sha" != $(sha256sum u-boot/$atf_file | cut -c1-64) ]; then
        echo "invalid hash for atf binary: u-boot/$atf_file"
        exit 5
    fi

    # outputs: idbloader.img, u-boot.itb
    rm -f idbloader.img u-boot.itb
    if ! is_param 'inc' "$@"; then
        make -C u-boot distclean
        make -C u-boot rock-4c-plus-rk3399_defconfig
    fi
    make -C u-boot -j$(nproc) BL31=$atf_file
    ln -sfv u-boot/idbloader.img
    ln -sfv u-boot/idbloader-spi.img
    ln -sfv u-boot/u-boot.itb

    # make spi image file
    #dd bs=64K count=64 if=/dev/zero | tr '\000' '\377' > rockpi-4cplus-uboot-spi.img
    #dd bs=4K seek=8 if=u-boot/idbloader-spi.img of=rockpi-4cplus-uboot-spi.img conv=notrunc
    #dd bs=4K seek=512 if=u-boot/u-boot.itb of=rockpi-4cplus-uboot-spi.img conv=notrunc,fsync

    is_param 'cp' "$@" && cp_to_debian

    echo "\n${cya}idbloader and u-boot binaries are now ready${rst}"
    echo "\n${cya}copy images to media:${rst}"
    echo "  ${cya}sudo dd bs=4K seek=8 if=idbloader.img of=/dev/sdX conv=notrunc${rst}"
    echo "  ${cya}sudo dd bs=4K seek=2048 if=u-boot.itb of=/dev/sdX conv=notrunc,fsync${rst}"
    echo
    echo "${blu}optionally, flash to spi (apt install mtd-utils):${rst}"
    echo "    ${blu}sudo flashcp -Av idbloader-spi.img /dev/mtd0${rst}"
    echo "    ${blu}sudo flashcp -Av u-boot.itb /dev/mtd2${rst}"
    echo
}

cp_to_debian() {
    local deb_dist=$(cat "../debian/make_debian_img.sh" | sed -n 's/\s*local deb_dist=.\([[:alpha:]]\+\)./\1/p')
    [ -z "$deb_dist" ] && return
    local cdir="../debian/cache.$deb_dist"
    echo '\ncopying to debian cache...'
    sudo mkdir -p "$cdir"
    sudo cp -v './idbloader.img' "$cdir"
    sudo cp -v './u-boot.itb' "$cdir"
}

check_installed() {
    local item todo
    for item in "$@"; do
        dpkg -l "$item" 2>/dev/null | grep -q "ii  $item" || todo="$todo $item"
    done

    if [ ! -z "$todo" ]; then
        echo "this script requires the following packages:${bld}${yel}$todo${rst}"
        echo "   run: ${bld}${grn}sudo apt update && sudo apt -y install$todo${rst}\n"
        exit 1
    fi
}

is_param() {
    local item match
    for item in "$@"; do
        if [ -z "$match" ]; then
            match="$item"
        elif [ "$match" = "$item" ]; then
            return 0
        fi
    done
    return 1
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

cd "$(dirname "$(realpath "$0")")"
main "$@"

