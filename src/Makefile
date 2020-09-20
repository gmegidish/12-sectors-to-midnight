
all: 12sectors.dsk

FHPACK="/usr/local/bin/fhpack"
ASM6F="/usr/local/bin/asm6f"
B2D="/Applications/buckshot.app/Contents/MacOS/b2d"

12sectors.dsk: master.dsk 12sec.bin
	java -jar ac.jar -d master.dsk TEST
	java -jar ac.jar -p master.dsk TEST B 0x8000 < 12sec.bin

hag.bmp: hag.png
	convert hag.png -colorspace RGB -type truecolor hag.bmp

hagch.bin: hag.bmp
	$(B2D) $< H Z50 R99 D7 V0

hagch.lz4: hagch.bin
	$(FHPACK) -9 -c hagch.bin hagch.lz4

12sec.bin: 12sec.s lz4fh6502.s hires.s hagch.lz4
	$(ASM6F) 12sec.s
	ls -l $@

clean:
	rm -f 12sec.bin hagch.lz4 hagch.bin
