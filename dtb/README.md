## linux device tree for the rockpi 4c+

<br/>

**build device tree images for the rockpi 4c+**
```
sh make_dtb.sh
```

<i>the build will produce the target file rk3399-rock-pi-4c-plus.dtb</i>

<br/>

**optional: create symbolic links**
```
sh make_dtb.sh links
```

<i>convenience link to rk3399.dtsi will be created in the project directory</i>

<br/>

**optional: clean target**
```
sh make_dtb.sh clean
```
