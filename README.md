# PS2-Magic-ICE-FINAL-REVERSE
This is a project to reverse and resource the PS2 Magic ICE Final code.

Have tidied up the repo. 

FINAL-REVERSE-define-restbump.s is the reverse i initially did and left behind for moving onto h2o reverse as summ0ne supplied the source for it as FINAL.asm.

H2O code was only supplied in compiled form for sx28 and sources for redesign port for ax1001 (found in sources/h2o). Has now been resourced and ablity to cross compile with sx28/sx48 from one source via defines along with other define options reversed (ps1drv on fat ps2 isnt set as define as bug not feature alt so won't want it off).

WIP dirs have the WIP of both h2o and sx48 port in different stages. sx48 was buggy cross compiled mess hence took me abit to work out how to complie for both as cleaned it up first. (turns out I'd forgot had fixed the regs and sx48 2x extra io as biggest issue, idiot of me lol)

This is a first coding project for me so please bare with the learning process ontop of the reversing side.

s/asm to be used with SX-Key Editor (official SDK for SX). Requires renaming extension to .src for it to open then just set defines and complie as wish. if have sxkey flash directly in device option, if using fluffy2 go devices and save sxh and use with icprog. sx28 still set to compile with cp enabled. can disable for easier verifying with fluffy2 (will fail verifying with enabled and fluffy2 can sometimes write wrong unlike sxkey will give clear error if does)

Current features implemented:

- PS1/2/DVD auto boot
- PS1/2 region free and backups
- Pal ps2 consoles has ps1 import fix which is superior to infinity/dms (modbo/mars) method working with all games (infinity/dms method some games y screen fix doesnt work). ps1 logo is shown too than modbo.
- Dev1
- Macrovision off and green fix
- v8 Asian console support which no mods currently available do (dms does but poorly)
- v1-90k (though 75k+ decka models is poor preformance at this point, better in pal fat consoles)
- Disable mode

at its core is simple functions but all need and want out of a chip. dvd9 backups require to be prepatched with toxic patcher (found in tools for pc)

old notes on readme for reverse

some noted differences between ice final and h2o is the ps1 support on ntsc consoles. ice will display ntsc games correctly but no yfix or colour fix for ntsc. h2o all besides 75k fall to pal import fix which make logo and ntsc/pal display incorrectly on ntsc consoles, works properly ntsc/pal on pal consoles (odd boot yfix doesnt take, put in standby and wait 10sec then force ps1 mode and usually takes).
first edit of h2o is to make flow as ice final does pal/ntsc consoles as same patches just missing jump to skip the pal console only patches for ntsc consoles, tested on jap console only so far n operates as ice final now, pal should do as intended as simple snb edit.

v8jap support added. only tested restbump on the v8jap so far but rest should be as noted.
only needed for these versions of mechacon. only CXP103049-003GG tested but assumption is 403GG will function same.

- 3.08_0    (0x080300) | CXP103049-003GG | G-chassis SCPH-39000 (Japan), late units
- 3.08_4    (0x080304) | CXP103049-403GG | G-chassis SCPH-39005/6/7 (Asia), late units

this is the last rev of spc mechacon which only found in late model jap console and requires the patch level of dragon in protection. wire with abghi vs prior v7 and lower jap abhi only. the label on the mechacon displays this and motherboard rev was gm-022 for me to discover this issue. short same jumper as v14usa support for restbump which is f to flipflop r (sx28=pin 2 sx48=13 different flipflop in my cads) or pin 8 and 9 on sx28 or pin 9 and 10 sx48.
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
