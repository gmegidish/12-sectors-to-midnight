# 12 Sectors To Midnight

![](12-sectors-to-midnight-screenshot.png)

## What's this?

A short scroller demo for Apple II (48k and up)

Written by Gil Megidish (www.megidish.net)

For the [*12 Sectors to Midnight Programming Exhibition*](https://www.facebook.com/events/2551527591827790/)

[fhpack](https://github.com/fadden/fhpack/) (lz4) decompression routines by Peter Ferrie & Andy McFadden

[Download disk image](https://github.com/gmegidish/12-sectors-to-midnight/raw/master/src/MASTER.DSK)

### Stuff you should know

Complete code is provided in this git. You can see that I used photoshop to design the looks. I used `b2d`, and
`bucketshot` to handle the graphics. Photoshop to Apple2.

The sprite of the hag was taken from the game Cauldron for the C64, and modified to match Apple II limitations.

Technically, 12 sectors is 3072 bytes. Each file on disk has an extra sector for file allocation lookups, so this demo had to fit in 2816 bytes, and ended up being 2799 bytes big.

### Improvements

- Major speed improvement could be achieved by unrolling the horizontal scroller loop. Even unrolling just 4 times would yield major frame rate improvement.

- The greetings could be compressed by lz4, this would reduce file size by about 140 bytes

- The Y line offset lookup table can be generated in runtime, or can be compressed by lz4. This would reduce by 100 bytes.

- Not all Y lines are being used, so we can reduce that as well :)

- The entire binary can be compressed with lz4 :)))))

But, it was all written in one day over the weekend.
