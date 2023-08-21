
LDIST ?= $(shell cat "debian/make_debian_img.sh" | sed -n 's/\s*local deb_dist=.\([[:alpha:]]\+\)./\1/p')


all: uboot dtb debian
	@echo "all binaries ready"

debian: uboot dtb debian/mmc_2g.img
	@echo "debian image ready"

dtb: dtb/rk3399-rock-4c-plus.dtb
	@echo "device tree binaries ready"

uboot: uboot/idbloader.img uboot/u-boot.itb
	@echo "u-boot binaries ready"

package-%: all
	@echo "building package for version $*"

	@rm -rfv distfiles
	@mkdir -v distfiles

	@cp -v uboot/idbloader.img uboot/u-boot.itb distfiles
	@cp -v dtb/rk3399-rock-4c-plus.dtb distfiles
	@cp -v debian/mmc_2g.img distfiles/rockpi-4c-plus_$(LDIST)-$*.img
	@xz -zve8 distfiles/rockpi-4c-plus_$(LDIST)-$*.img

	@cd distfiles ; sha256sum * > sha256sums.txt

clean:
	@rm -rfv distfiles
	sudo sh debian/make_debian_img.sh clean
	sh dtb/make_dtb.sh clean
	sh uboot/make_uboot.sh clean
	@echo "all targets clean"

debian/mmc_2g.img:
	sudo sh debian/make_debian_img.sh nocomp

dtb/rk3399-rock-4c-plus.dtb:
	sh dtb/make_dtb.sh cp

uboot/idbloader.img uboot/u-boot.itb:
	sh uboot/make_uboot.sh cp


.PHONY: debian dtb uboot all package-* clean

