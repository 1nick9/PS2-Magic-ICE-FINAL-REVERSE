# PS2-Magic-ICE-FINAL-REVERSE
This is a project to reverse and resource the PS2 Magic ICE Final code.

Still WIP stage first focusing on SX28 before linking to compile from resource for SX48.

This is a first coding project for me so please bare with the learning process ontop of the reversing side.

SRC is SX ASM formart. for use directly with SX-Key Editor (official SDK for SX)

some noted differences between ice final and h2o is the ps1 support on ntsc consoles. ice will display ntsc games correctly but no yfix or colour fix for ntsc. h2o all besides 75k fall to pal import fix which make logo and ntsc/pal display incorrectly on ntsc consoles, works properly ntsc/pal on pal consoles (odd boot yfix doesnt take, put in standby and wait 10sec then force ps1 mode and usually takes).
first edit of h2o is to make flow as ice final does pal/ntsc consoles as same patches just missing jump to skip the pal console only patches for ntsc consoles, tested on jap console only so far n operates as ice final now, pal should do as intended as simple snb edit.


Sources:
Original ICE team site (maybe just mirror)
https://www.angelfire.com/clone/magicfriend/

Angelica SX Disassembler (archive.org capture as long down)
https://web.archive.org/web/20110816110647/http://online.dip.jp/angelica/index_e.html

SX ASM Instructions
www.sxlist.com/techref/scenix/inst.htm

Official SX Documents
https://www.parallax.com/package/sx-key-usb-downloads/
