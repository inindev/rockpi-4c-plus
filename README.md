# rockpi-4c-plus
#### *Stock Debian ARM64 Linux for the Radxa ROCK (Pi) 4C+*

This stock Debian ARM64 Linux image is built directly from official packages using the official Debian [Debootstrap](https://wiki.debian.org/Debootstrap) utility, see: https://github.com/inindev/rockpi-4c-plus/blob/main/debian/make_debian_img.sh#L139

Being an official unmodified Debian build, patches are directory available from the Debian repos using the stock **apt** package manager, see: https://github.com/inindev/rockpi-4c-plus/blob/main/debian/make_debian_img.sh#L368-L378

If you want to run true up-stream Debian Linux on your ARM64 device, this is the way to do it.

<br/>

---
### debian bookworm setup

<br/>

**1. download image**
```
wget https://github.com/inindev/rockpi-4c-plus/releases/download/v12.0.1/rockpi-4c-plus_bookworm-1201.img.xz
```

<br/>

**2. determine the location of the target micro sd card**

 * before plugging-in device
```
ls -l /dev/sd*
ls: cannot access '/dev/sd*': No such file or directory
```

 * after plugging-in device
```
ls -l /dev/sd*
brw-rw---- 1 root disk 8, 0 Sep  8 20:58 /dev/sda
```
* note: for mac, the device is ```/dev/rdiskX```

<br/>

**3. in the case above, substitute 'a' for 'X' in the command below (for /dev/sda)**
```
sudo sh -c 'xzcat rockpi-4c-plus_bookworm-1201.img.xz > /dev/sdX && sync'
```

#### when the micro sd has finished imaging, eject and use it to boot the rock 4c+ to finish setup

<br/>

**4. login account**
```
user: debian
pass: debian
```

<br/>

**5. take updates**
```
sudo apt update
sudo apt upgrade
```

<br/>

**6. create account & login as new user**
```
sudo adduser <youruserid>
echo '<youruserid> ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/<youruserid>
sudo chmod 440 /etc/sudoers.d/<youruserid>
```

<br/>

**7. lockout and/or delete debian account**
```
sudo passwd -l debian
sudo chsh -s /usr/sbin/nologin debian
```

```
sudo deluser --remove-home debian
sudo rm /etc/sudoers.d/debian
```

<br/>

**8. change hostname (optional)**
```
sudo nano /etc/hostname
sudo nano /etc/hosts
```

<br/>


---
### building debian bookworm arm64 for the rock 4c+ from scratch

<br/>

The build script builds native arm64 binaries and thus needs to be run from an arm64 device such as a raspberry pi4 running a 64 bit arm linux. The initial build of this project used a debian arm64 raspberry pi4, but now uses a rock 5b running stock debian trixie arm64.

<br/>

**1. clone the repo**
```
git clone https://github.com/inindev/rockpi-4c-plus.git
cd rockpi-4c-plus
```

<br/>

**2. run the debian build script**
```
cd debian
sudo sh make_debian_img.sh
```
* note: edit the build script to change various options: ```nano make_debian_img.sh```

<br/>

**3. the output if the build completes successfully**
```
mmc_2g.img.xz
```

<br/>

---
### _note: bypassing spi flash boot_

If the SPI flash contains a u-boot image, the flash will need to be disabled to boot from MMC. To disable the flash, short [SPI1_CLK pin 23](https://wiki.radxa.com/Rockpi4/hardware/gpio) to ground as outlined on the [radxa wiki](https://wiki.radxa.com/Rockpi4/dev/spi-install#Case_2:_Update_SPI_flash_with_bootloader_inside). Once the MMC has been bootstrapped, the jumper can carefully be removed to reenable the SPI flash so it can be accessed by the booted image.

<br/>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src="https://wiki.radxa.com/mw/images/c/c4/Spi_clk_gnd.jpg" alt="spi flash bypass" width="300"/>

<br/>
