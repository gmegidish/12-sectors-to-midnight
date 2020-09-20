
all: 12sectors.dsk

b2d="/Applications/buckshot.app/Contents/MacOS/b2d"

12sectors.dsk: master.dsk 12sec.bin
	java -jar ac.jar -d master.dsk TEST
	java -jar ac.jar -p master.dsk TEST B 0x4000 < 12sec.bin

hag.bmp: hag.png
	convert hag.png -colorspace RGB -type truecolor hag.bmp

HAGCH.BIN: hag.bmp
	$(b2d) $< H Z50 R99 D7 V0

HAGCH.lz4: HAGCH.BIN
	fhpack -9 -c HAGCH.BIN HAGCH.lz4

12sec.bin: 12sec.s HAGCH.lz4
	./asm6f $<
	ls -l $@

