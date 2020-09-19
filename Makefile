
all: 12sectors.dsk

12sectors.dsk: master.dsk src/12sec.bin
	java -jar ac.jar -d master.dsk TEST
	java -jar ac.jar -p master.dsk TEST B 0x8000 < src/12sec.bin

src/12sec.bin: src/12sec.s src/sprite-moon.s
	src/asm6f $<
	ls -l $@

