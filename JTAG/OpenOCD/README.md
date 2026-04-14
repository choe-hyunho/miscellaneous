# [Open On-Chip Debugger(OpenOCD)](https://openocd.org/) related settings & files

## Documentation

See [here](http://openocd.org/doc-release/html/index.html) online.

## Supported JTAG

See [here](http://openocd.org/doc/html/Debug-Adapter-Hardware.html#Debug-Adapter-Hardware).

## Binary Downloads

See [here](https://github.com/xpack-dev-tools/openocd-xpack/releases).

## S3C2410/SMDK2410 config files

- Overwrite [samsung_s3c2410.cfg](samsung_s3c2410.cfg) to openocd/scripts/target

- Copy [smdk2410.cfg](smdk2410.cfg) to openocd/scripts/board

## Command Examples

- Connect to target

```
.\openocd-0.12.0\bin\openocd.exe -c "bindto 0.0.0.0" -f .\openocd-0.12.0\openocd\scripts\interface\ftdi\olimex-arm-usb-ocd.cfg -f .\openocd-0.12.0\openocd\scripts\board\smdk2410.cfg
```

```
xPack Open On-Chip Debugger 0.12.0+dev-02228-ge5888bda3-dirty (2025-10-04-22:44)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Warn : DEPRECATED: auto-selecting transport "jtag". Use 'transport select jtag' to suppress this message.
Info : Listening on port 6666 for tcl connections
Info : Listening on port 4444 for telnet connections
Warn : An adapter speed is not selected in the init scripts. OpenOCD will try to run the adapter at very low speed (100 kHz).
Warn : To remove this warnings and achieve reasonable communication speed with the target, set "adapter speed" or "jtag_rclk" in the init scripts.
Info : clock speed 100 kHz
Info : JTAG tap: s3c2410.cpu tap/device found: 0x0032409d (mfg: 0x04e (Samsung), part: 0x0324, ver: 0x0)
Info : Embedded ICE version 2
Info : s3c2410.cpu: hardware has 2 breakpoint/watchpoint units
Info : [s3c2410.cpu] Examination succeed
Info : [s3c2410.cpu] starting gdb server on 3333
Info : Listening on port 3333 for gdb connections
```

- Write to NOR Flash

```
.\openocd-0.12.0\bin\openocd.exe -f .\openocd-0.12.0\openocd\scripts\interface\ftdi\olimex-arm-usb-ocd.cfg -f .\openocd-0.12.0\openocd\scripts\board\smdk2410.cfg -c "program .\\u-boot.bin reset exit"
```
