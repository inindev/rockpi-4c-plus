## u-boot 2022.07 for the rockpi 4c+

<i>Note: This script is intended to be run from a 64 bit arm device such as an odroid m1 or a raspberry pi4.</i>

<br/>

**1. build u-boot images for the rockpi 4c+**
```
sh make_uboot.sh
```

<i>the build will produce the target files idbloader.img, idbloader-spi.img, u-boot.itb, and u-boot-spi.itb</i>

<br/>

**2. copy u-boot to mmc or file image**
```
dd bs=4K seek=8 if=idbloader.img of=/dev/sdX conv=notrunc
dd bs=4K seek=2048 if=u-boot.itb of=/dev/sdX conv=notrunc
sync
```

<br/>

**3. optional: flash to spi**
```
apt install mtd-utils

flash_erase /dev/mtd0 0 0
nandwrite /dev/mtd0 idbloader-spi.img
flash_erase /dev/mtd2 0 0
nandwrite /dev/mtd2 u-boot-spi.itb
```

<i><sub><b>The flash_erase operations take up to a minute and the % progress does not update along the way. The idbloader write is 84 blocks, and the u-boot write is 268 blocks.</b></sub></i>

<br/>

**4. optional: clean target**
```
sh make_uboot.sh clean
```
