## linux device tree for the rockpi 4c+

<br/>

**build u-boot images for the rockpi 4c+**
```
sh make_dtb.sh
```

<i>the build will produce the target file rk3399-rock-pi-4c-plus.dtb</i>

<br/>

**optional: create symbolic links**
```
sh make_dtb.sh links
```

<i>convenience links to rk3399.dtsi and rk3399-opp.dtsi will be created in the project directory</i>

<br/>

**optional: clean target**
```
sh make_dtb.sh clean
```
