# [SMDK2410](https://aijisystem.en.ec21.com/High-end_Mobile_System_Reference_Board_%28SMDK2410%29--150259_282306.html) related settings & files

![Aiji System SMDK2410](https://image.ec21.com/image/aijisystem/oimg_GC00150259_CA00282306/High%2Dend-Mobile-System-Reference-Board-SMDK2410-.jpg?v=171053)

## Operation Mode jumper setting

OM[1:0] - J33=OM[0] & J34=OM[1]
- 00 : NAND BOOT          - For SMC NAND FLASH
- 01 : Half Word (16Bit)  - For E28F128J3A150 NOR FLASH
- 10 : Word (32Bit)       - For AM29LV800BB NOR FLASH
- 11 : TEST MODE
> [!CAUTION]
> 0 means jumper short, and 1 means jumper open. See [schemetics](Schematic/SMDK2410_REV13.pdf).

## About Steppingstone

Generally, the boot code will copy NAND flash content to SDRAM. Using hardware ECC, the NAND flash data
validity will be checked. Upon the completion of the copy, the main program will be executed on the SDRAM.

AUTO BOOT MODE SEQUENCE

1. Reset is completed.
2. When the auto boot mode is enabled, the first 4 KBytes of NAND flash memory is copied onto Steppingstone
4-KB internal buffer.
3. The Steppingstone is mapped to nGCS0.
4. CPU starts to execute the boot code on the Steppingstone 4-KB internal buffer.

> [!NOTE]
> In the auto boot mode, ECC is not checked. So, The first 4 KBytes of NAND flash should have no bit error.

## Notable Memory Map
```
 0x00000000 : Flash (NOR mode) or 4K SRAM(NAND mode)
 0x30000000 - 0x37FFFFFF : SDRAM
 0x48000000 - 0x5FFFFFFF : Register Area
```

## How to write NOR Flash
```sh
.\openocd-0.12.0\bin\openocd.exe -f .\openocd-0.12.0\openocd\scripts\interface\ftdi\olimex-arm-usb-ocd.cfg -f .\openocd-0.12.0\openocd\scripts\board\smdk2410.cfg -c "program .\\u-boot.bin reset exit"
```

## NAND Information

- NAND Partition Table
```
  0x000000000000-0x000000200000 : "u-boot"
  0x000000200000-0x000000800000 : "kernel"
  0x000000800000-0x000004000000 : "rootfs"
```

- NAND Device Information
```
Device 0: nand0, sector size 16 KiB
  Page size       512 b
  OOB size         16 b
  Erase size    16384 b
```

## Supported Versions(known latest)
- U-Boot : 2016.11
- Linux : 6.2.16
- GCC : 4.9.x (static inline issues in >= 5.x)

## Docker command for buildroot
```sh
docker run -it -h buildroot -v $(pwd):/work -w /work buildroot/base
```

## Buildroot

- Use [buildroot-2019.05.3](https://buildroot.org/downloads/buildroot-2019.05.3.tar.gz).

- Buildroot configuration file: [smdk2410-buildroot-2019.05.3.config](smdk2410-buildroot-2019.05.3.config)

- Linux Kernel configuration file (Addition to defconfig): [smdk2410-linux-5.1.21.config](smdk2410-linux-5.1.21.config)

- Linux Kernel patch file: [smdk2410-linux-5.1.21.patch](smdk2410-linux-5.1.21.patch)

- U-Boot patch file: [smdk2410-u-boot-2012.04.01.patch](smdk2410-u-boot-2012.04.01.patch)

- Build with the following commands:
```sh
cd buildroot-2019.05.3
cp ../smdk2410-buildroot-2019.05.3.config .config
make olddefconfig
make all 
```

## U-Boot

- Write `u-boot.bin` to NOR Flash
```sh
tftpboot 0x30000000 u-boot.bin
protect off 0x00000000 0x000fffff
erase 0x00000000 0x000fffff
cp.b 0x30000000 0x00000000 ${filesize}
```

- Write `u-boot-nand.bin` to NAND Flash
```sh
tftpboot 0x30000000 u-boot-nand.bin
nand erase 0x0 0x200000
nand write 0x30000000 0x0 ${filesize}
```

- Write `u-boot-spl.bin` to NAND Flash
```sh
tftpboot 0x30000000 u-boot-spl.bin
nand erase 0x0 0x4000
nand write 0x30000000 0x0 ${filesize}
```

- Write `u-boot.bin` to NAND Flash
```sh
tftpboot 0x30000000 u-boot.bin
nand erase 0x4000 0x1fc000
nand write 0x30000000 0x4000 ${filesize}
```

- Write `uImage` to NAND Flash
```sh
tftpboot 0x30000000 uImage
nand erase 0x200000 0x600000
nand write 0x30000000 0x200000 ${filesize}
```

- Write `root.ubi` to NAND Flash
```sh
tftpboot 0x30000000 rootfs.ubi
nand erase 0x800000 0x3800000
nand write 0x30000000 0x800000 ${filesize}
```

- Boot Environment
```sh
setenv mtdids nand0=NAND
setenv mtdparts mtdparts=NAND:2m(u-boot),6m(kernel),-(rootfs)
setenv bootargs console=ttySAC0,115200 cs89x0_media=rj45 ${mtdparts} ubi.mtd=2 root=ubi0:rootfs rootfstype=ubifs rw
setenv bootcmd nand read 0x30000000 0x200000 0x600000\; bootm 0x30000000
saveenv
```

## Linux

- Network Environment
```sh
setenv ethaddr 00:0E:3A:24:10:01
setenv ipaddr 192.168.1.251
setenv serverip 192.168.1.200
setenv netmask 255.255.255.0
setenv gatewayip 192.168.1.1
saveenv
```

- Network Test in Shell
```sh
ifconfig eth0 down
ifconfig eth0 hw ether 00:0E:3A:24:10:01
ifconfig eth0 192.168.1.250 netmask 255.255.255.0 up
route add default gw 192.168.1.1
```

- Network Configuration (`/etc/network/interfaces`)
```sh
auto eth0
iface eth0 inet dhcp
    hwaddress ether 00:0E:3A:24:10:01
```

## GDB

- [GDB setup example](smdk2410-setup.gdb)
```sh
target remote 192.168.1.200:3333
monitor reset init
set confirm off
set architecture armv4t
set output-radix 16
set disassemble-next-line on
#restore nand_spl/u-boot-spl.bin binary 0x0
#add-symbol-file nand_spl/u-boot-spl 0x0
set $pc = 0x0
x/10i $pc
```

- GDB command line
```sh
gdb-multiarch -x ../smdk2410-setup.gdb nand_spl/u-boot-spl
```

- Frequently used GDB commands
```
[c]ontinue
[s]tep
[n]ext
[b]reak​ <function name or filename:line# or *memory address>
[b]ack[t]race
[q]uit
```

## Build from Scratch

### crosstool-ng

- Config for ARMv4T

Use this [config](smdk2410-crosstool.config).

- How to build
```sh
apt install autoconf texinfo help2man libtool-bin
git clone https://github.com/crosstool-ng/crosstool-ng
bash -c 'cd crosstool-ng && ./bootstrap'
bash -c 'cd crosstool-ng && ./configure --enable-local'
make -C crosstool-ng
bash -c 'cd crosstool-ng && DEFCONFIG=../smdk2410-crosstool.config ./ct-ng defconfig'
bash -c 'cd crosstool-ng && CT_PREFIX=.. ./ct-ng build'
cp -a arm-unknown-linux-gnueabi/arm-unknown-linux-gnueabi/sysroot .
```

- How to save current config
```sh
./ct-ng arm-unknown-linux-gnueabi
DEFCONFIG=../smdk2410-crosstool.config ./ct-ng savedefconfig
```

### u-boot-2016.11

- Patch for NAND boot

Apply this [patch](smdk2410-u-boot-2016.11.patch).

- How to build
```sh
git clone https://source.denx.de/u-boot/u-boot.git
git -C u-boot checkout v2016.11
git -C u-boot apply ../smdk2410-u-boot-2016.11.patch
CROSS_COMPILE=$PWD/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi- make -C u-boot smdk2410_nand_config
CROSS_COMPILE=$PWD/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi- make -C u-boot all
```

- Write `u-boot-with-spl.bin` to NAND Flash
```sh
tftpboot 0x30000000 u-boot-with-spl.bin
nand erase 0x0 0x200000
nand write 0x30000000 0x0 ${filesize}
```

### linux-5.18.19

- Config for additional features

Apply this [config](smdk2410-linux-5.18.19.config).

- Patch for various problems

Apply this [patch](smdk2410-linux-5.18.19.patch).

- How to build
```sh
git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux
git -C linux checkout v5.18.19
git -C linux apply ../smdk2410-linux-5.18.19.patch
ARCH=arm CROSS_COMPILE=$PWD/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi- make -C linux s3c2410_defconfig
./linux/scripts/kconfig/merge_config.sh -O linux -m linux/.config smdk2410-linux-5.18.19.config
ARCH=arm CROSS_COMPILE=$PWD/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi- make -C linux olddefconfig
ARCH=arm CROSS_COMPILE=$PWD/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi- make -C linux uImage LOADADDR=0x30108000
ARCH=arm CROSS_COMPILE=$PWD/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi- make -C linux modules
#ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- make -C linux modules_install INSTALL_MOD_PATH=../sysroot
```
### busybox

- Default config

Apply this [config](smdk2410-busybox.config).

- How to build
```sh
git clone https://git.busybox.net/busybox/
cp smdk2410-busybox.config busybox/.config
ARCH=arm CROSS_COMPILE=$PWD/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi- make -C busybox oldconfig
ARCH=arm CROSS_COMPILE=$PWD/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi- make -C busybox all
#ARCH=arm CROSS_COMPILE=$PWD/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi- make -C busybox install CONFIG_PREFIX=../sysroot
```

### mkroot.sh

To build root filesystem, use this [script](mkroot.sh).

### tflite-micro

- How to build
```sh
git clone https://github.com/tensorflow/tflite-micro.git
make -f tensorflow/lite/micro/tools/make/Makefile TARGET=arm920t microlite
```

### flatbuffers

- How to build
```sh
git clone https://github.com/google/flatbuffers.git
git -C flatbuffers checkout v25.9.23
mkdir -p flatbuffers/build
cmake -B flatbuffers/build/ flatbuffers/
cmake --build flatbuffers/build/
```

### tensorflow

- How to build
```sh
apt install protobuf-compiler
git clone https://github.com/tensorflow/tensorflow.git
mkdir -p tensorflow/tflite-build
cmake -B tensorflow/tflite-build $PWD/tensorflow/tensorflow/lite -DCMAKE_TOOLCHAIN_FILE=$PWD/arm-unknown-linux-gnueabi/toolchain.cmake -DTFLITE_HOST_TOOLS_DIR=$PWD/flatbuffers/build/ -DTFLITE_ENABLE_XNNPACK=OFF -DTFLITE_ENABLE_GPU=OFF -DCMAKE_C_FLAGS="-D_GNU_SOURCE" -DCMAKE_CXX_FLAGS="-D_GNU_SOURCE" -DTENSORFLOW_SOURCE_DIR=$PWD/tensorflow -DCMAKE_CXX_COMPILE_OBJECT="<CMAKE_CXX_COMPILER> <DEFINES> <INCLUDES> <FLAGS> -URUY_HAVE_CPUINFO -o <OBJECT> -c <SOURCE>"
cmake --build tensorflow/tflite-build/
```