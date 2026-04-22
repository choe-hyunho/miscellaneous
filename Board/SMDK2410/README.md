# [SMDK2410](https://aijisystem.en.ec21.com/High-end_Mobile_System_Reference_Board_%28SMDK2410%29--150259_282306.html) related settings & files

![Aiji System SMDK2410](https://image.ec21.com/image/aijisystem/oimg_GC00150259_CA00282306/High%2Dend-Mobile-System-Reference-Board-SMDK2410-.jpg?v=171053)

## Operation Mode jumper setting

OM[1:0] - J33=OM[0] & J34=OM[1]
- 00 : NAND BOOT			- For SMC NAND FLASH
- 01 : Half Word (16Bit)    - For E28F128J3A150 NOR FLASH
- 10 : Word (32Bit)			- For AM29LV800BB NOR FLASH
- 11 : TEST MODE

## Notable Memory Map
```
 0x00000000 : Flash (NOR mode) or 4K SRAM(NAND mode)
 0x30000000 - 0x37FFFFFF : SDRAM
 0x48000000 - 0x5FFFFFFF : Register Area
```

## How to write NOR Flash
```
.\openocd-0.12.0\bin\openocd.exe -f .\openocd-0.12.0\openocd\scripts\interface\ftdi\olimex-arm-usb-ocd.cfg -f .\openocd-0.12.0\openocd\scripts\board\smdk2410.cfg -c "program .\\u-boot.bin reset exit"
```

## NAND Information

- Default NAND Partition
```
  0x000000000000-0x000000004000 : "Boot Agent"
  0x000000000000-0x000000200000 : "S3C2410 flash partition 1" (2M)
  0x000000400000-0x000000800000 : "S3C2410 flash partition 2" (4M)
  0x000000800000-0x000000a00000 : "S3C2410 flash partition 3" (2M)
  0x000000a00000-0x000000e00000 : "S3C2410 flash partition 4" (4M)
  0x000000e00000-0x000001800000 : "S3C2410 flash partition 5" (10M)
  0x000001800000-0x000003000000 : "S3C2410 flash partition 6" (24M)
  0x000003000000-0x000004000000 : "S3C2410 flash partition 7" (16M)
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
```
docker run -it -h buildroot -v $(pwd):/work -w /work buildroot/base
```

## Buildroot

- Use [buildroot-2019.05.3](https://buildroot.org/downloads/buildroot-2019.05.3.tar.gz).

- Buildroot configuration file: [smdk2410-buildroot.config](smdk2410-buildroot.config)

- Linux Kernel configuration file (Addition to defconfig): [smdk2410-kernel.config](smdk2410-kernel.config)

- Linux Kernel patch file: [smdk2410-kernel.patch](smdk2410-kernel.patch)

- Build with the following commands:
```shell
cd buildroot-2019.05.3
cp ../smdk2410-buildroot.config .config
make olddefconfig
make all 
```
