# Olimex ARM-USB-JTAG series related settings & files

## Supported ARM targets working in voltage range

- ARM-USB-OCD    : 2.0  – 5.0 V DC
- ARM-USB-OCD-H  : 1.65 – 5.0 V DC
- ARM-USB-OCD-HL : 0.65 - 5.5 V DC

## Power supply jumper

ARM-USB-OCD has two jumpers that can enable 9V DC voltage output or 12V DC voltage output.
The power supply jumpers are on right side of the 2×10 pin JTAG connector.
- If both jumpers are open the output voltage is 12VDC
- If right jumper is closed the output voltage is 9VDC
- If left jumper is closed the output voltage is 5VDC (this is the default setting)

## Install driver

There are two interfaces in this device. Interface 0 is used for JTAG, and interface 1 is used for UART.

### JTAG driver

Install WinUSB using [zadig](http://zadig.akeo.ie/) for interface 0.

### UART driver

If you don't use UART, and not care for yellow bang on device manager, do not install driver.

Or, download latest VCP driver from [FTDI](https://ftdichip.com/drivers/vcp-drivers/) and add following lines to `ftdibus.inf` & `ftdiport.inf`. (Do not add section name, which already exists.)

- `ftdibus.inf`
```
[FtdiHw]
%USB\VID_15ba&PID_0003&MI_00.DeviceDesc%=FtdiBus.NT,USB\VID_15ba&PID_0003&MI_00
%USB\VID_15ba&PID_0003&MI_01.DeviceDesc%=FtdiBus.NT,USB\VID_15ba&PID_0003&MI_01
%USB\VID_15ba&PID_0004&MI_00.DeviceDesc%=FtdiBus.NT,USB\VID_15ba&PID_0004&MI_00
%USB\VID_15ba&PID_0004&MI_01.DeviceDesc%=FtdiBus.NT,USB\VID_15ba&PID_0004&MI_01
%USB\VID_15ba&PID_002a&MI_00.DeviceDesc%=FtdiBus.NT,USB\VID_15ba&PID_002a&MI_00
%USB\VID_15ba&PID_002a&MI_01.DeviceDesc%=FtdiBus.NT,USB\VID_15ba&PID_002a&MI_01
%USB\VID_15ba&PID_002b&MI_00.DeviceDesc%=FtdiBus.NT,USB\VID_15ba&PID_002b&MI_00
%USB\VID_15ba&PID_002b&MI_01.DeviceDesc%=FtdiBus.NT,USB\VID_15ba&PID_002b&MI_01
```
```
[FtdiHw.NTamd64]
%USB\VID_15ba&PID_0003&MI_00.DeviceDesc%=FtdiBus.NTamd64,USB\VID_15ba&PID_0003&MI_00
%USB\VID_15ba&PID_0003&MI_01.DeviceDesc%=FtdiBus.NTamd64,USB\VID_15ba&PID_0003&MI_01
%USB\VID_15ba&PID_0004&MI_00.DeviceDesc%=FtdiBus.NTamd64,USB\VID_15ba&PID_0004&MI_00
%USB\VID_15ba&PID_0004&MI_01.DeviceDesc%=FtdiBus.NTamd64,USB\VID_15ba&PID_0004&MI_01
%USB\VID_15ba&PID_002a&MI_00.DeviceDesc%=FtdiBus.NTamd64,USB\VID_15ba&PID_002a&MI_00
%USB\VID_15ba&PID_002a&MI_01.DeviceDesc%=FtdiBus.NTamd64,USB\VID_15ba&PID_002a&MI_01
%USB\VID_15ba&PID_002b&MI_00.DeviceDesc%=FtdiBus.NTamd64,USB\VID_15ba&PID_002b&MI_00
%USB\VID_15ba&PID_002b&MI_01.DeviceDesc%=FtdiBus.NTamd64,USB\VID_15ba&PID_002b&MI_01
```
```
[Strings]
USB\VID_15ba&PID_0003&MI_00.DeviceDesc="USB Serial Converter A"
USB\VID_15ba&PID_0003&MI_01.DeviceDesc="USB Serial Converter B"
USB\VID_15ba&PID_0004&MI_00.DeviceDesc="USB Serial Converter A"
USB\VID_15ba&PID_0004&MI_01.DeviceDesc="USB Serial Converter B"
USB\VID_15ba&PID_002a&MI_00.DeviceDesc="USB Serial Converter A"
USB\VID_15ba&PID_002a&MI_01.DeviceDesc="USB Serial Converter B"
USB\VID_15ba&PID_002b&MI_00.DeviceDesc="USB Serial Converter A"
USB\VID_15ba&PID_002b&MI_01.DeviceDesc="USB Serial Converter B"
```

- `ftdiport.inf`
```
[FtdiHw]
%VID_15ba&PID_0003.DeviceDesc%=FtdiPort.NT,FTDIBUS\COMPORT&VID_15ba&PID_0003
%VID_15ba&PID_0004.DeviceDesc%=FtdiPort.NT,FTDIBUS\COMPORT&VID_15ba&PID_0004
%VID_15ba&PID_002a.DeviceDesc%=FtdiPort.NT,FTDIBUS\COMPORT&VID_15ba&PID_002a
%VID_15ba&PID_002b.DeviceDesc%=FtdiPort.NT,FTDIBUS\COMPORT&VID_15ba&PID_002b
%VID_15ba&PID_0000.DeviceDesc%=FtdiPort.NT,FTDIBUS\COMPORT&VID_15ba&PID_0000
```
```
[FtdiHw.NTamd64]
%VID_15ba&PID_0003.DeviceDesc%=FtdiPort.NTamd64,FTDIBUS\COMPORT&VID_15ba&PID_0003
%VID_15ba&PID_0004.DeviceDesc%=FtdiPort.NTamd64,FTDIBUS\COMPORT&VID_15ba&PID_0004
%VID_15ba&PID_002a.DeviceDesc%=FtdiPort.NTamd64,FTDIBUS\COMPORT&VID_15ba&PID_002a
%VID_15ba&PID_002b.DeviceDesc%=FtdiPort.NTamd64,FTDIBUS\COMPORT&VID_15ba&PID_002b
%VID_15ba&PID_0000.DeviceDesc%=FtdiPort.NTamd64,FTDIBUS\COMPORT&VID_15ba&PID_0000
```
```
[Strings]
VID_15ba&PID_0003.DeviceDesc="OLIMEX ARM-USB-OCD"
VID_15ba&PID_0004.DeviceDesc="OLIMEX ARM-USB-TINY"
VID_15ba&PID_002a.DeviceDesc="OLIMEX ARM-USB-TINY-H"
VID_15ba&PID_002b.DeviceDesc="OLIMEX ARM-USB-OCD-H"
VID_15ba&PID_0000.DeviceDesc="OLIMEX Serial Port"
```

After modification, driver will not be installed in normal way. Restart Windows with "Disable driver signature enforcement", and connect JTAG to USB and manually update driver by assigning directory contains VCP driver, and reboot.

## Further informations

The manual and other useful information can be found [here](https://www.olimex.com/Products/ARM/JTAG/ARM-USB-OCD-H/).