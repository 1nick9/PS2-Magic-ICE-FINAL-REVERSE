# PS2-Magic-ICE-FINAL-REVERSE
This is a project to reverse and resource the PS2 Magic ICE Final code.

Still WIP stage first focusing on SX28 before linking to compile from resource for SX48.

This is a first coding project for me so please bare with the learning process ontop of the reversing side.

SRC is SX ASM formart. for use directly with SX-Key Editor (official SDK for SX)

some noted differences between ice final and h2o is the ps1 support on ntsc consoles. ice will display ntsc games correctly but no yfix or colour fix for ntsc. h2o all besides 75k fall to pal import fix which make logo and ntsc/pal display incorrectly on ntsc consoles, works properly ntsc/pal on pal consoles (odd boot yfix doesnt take, put in standby and wait 10sec then force ps1 mode and usually takes).
first edit of h2o is to make flow as ice final does pal/ntsc consoles as same patches just missing jump to skip the pal console only patches for ntsc consoles, tested on jap console only so far n operates as ice final now, pal should do as intended as simple snb edit.

v8jap support added. only tested restbump on the v8jap so far but rest should be as noted.
only needed for these versions of mechacon. only CXP103049-003GG tested but assumption is 403GG will function same.
3.08_0    (0x080300) | CXP103049-003GG | G-chassis SCPH-39000 (Japan), late units
3.08_4    (0x080304) | CXP103049-403GG | G-chassis SCPH-39005/6/7 (Asia), late units
this is the last rev of spu which only found in late model jap console and requires the patch level of dragon in protection. wire with abghi vs prior v7 and lower jap abhi only. the label on the mechacon displays this and motherboard rev was gm-022 for me to discover this issue. short same jumper as v14usa support for restbump which is f to flipflop r (pin 2) or pin 8 and 9 on sx28.
mods that dont work with this are infinity based. so this is a nice improvement to add support for a low supported hardware modchip wise :)

Sources:
Original ICE team site (maybe just mirror)
https://www.angelfire.com/clone/magicfriend/

Angelica SX Disassembler (archive.org capture as long down)
https://web.archive.org/web/20110816110647/http://online.dip.jp/angelica/index_e.html

SX ASM Instructions
www.sxlist.com/techref/scenix/inst.htm

Official SX Documents
https://www.parallax.com/package/sx-key-usb-downloads/
