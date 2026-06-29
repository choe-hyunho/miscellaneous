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
