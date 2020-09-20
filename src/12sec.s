
ORG $4000

GR       	EQU	$C050
CLRMIXED	EQU	$C052
SETMIXED	EQU	$C053
CLRPAGE2	EQU	$C054
HIRES    	EQU	$C057

ZP_WIDTH	EQU	$0000
ZP_HEIGHT	EQU	$0001
ZP_X		EQU	$0002
ZP_Y		EQU	$0003
SRC_START_LO	EQU	$0004
SRC_START_HI	EQU	$0005
DST_START_LO	EQU	$0006
DST_START_HI	EQU	$0007
SRC_OFFSET	EQU	$0008
DST_OFFSET	EQU	$0009
GREETINGS_LINE	EQU	$0010
HSCROLL_DELAY	EQU	$0011
GREETINGS_DELAY	EQU	$0012
TEXT_BUFFER	EQU	$0020

start:
	jsr	clear_text_framebuffer
	jsr	prepare_screen

	lda	HIRES
	lda	GR
	lda	SETMIXED
	;lda	CLRMIXED
	lda	CLRPAGE2
	jmp	loop

clear_text_framebuffer:
	ldx	#39
	lda	#$a0		; 0x20 (whitespace) | 0x80 (no inverse)
c0:
	sta	$650,x
	sta	$6d0,x
	sta	$750,x
	sta	$7d0,x
	dex
	bpl	c0
	rts

prepare_screen:
	lda #<compressed_bitmap
	sta $00
	lda #>compressed_bitmap
	sta $01

	lda #$00
	sta $02
	lda #$20
	sta $03

	; copy 8192 bytes (32 pages)
	ldx #32

loop_copy_row:
	ldy	#0
loop_copy:
	lda	($00),y
	sta	($02),y
	dey
	bne	loop_copy

	inc	$01
	inc	$03
	dex
	bne	loop_copy_row
	rts

draw_sprite:
	ldy	#00
	sty	SRC_OFFSET

next_row:
	ldx	ZP_Y
	lda	YLO,x
	sta	DST_START_LO
	lda	YHI,x
	sta	DST_START_HI
	ldy	#00
	sty	DST_OFFSET
	ldx	ZP_WIDTH

copy_row_bytes:
	dex
	ldy	SRC_OFFSET
	lda	(SRC_START_LO),y

	ldy	DST_OFFSET
	sta	(DST_START_LO),y

	inc	SRC_OFFSET
	inc	DST_OFFSET

	cpx	#00
	bne	copy_row_bytes

	dec	ZP_HEIGHT
	beq	draw_sprites_exit
	inc	ZP_Y
	jmp	next_row

draw_sprites_exit:
	rts

reset_text_buffer:

	lda	GREETINGS_LINE	; find the greetings line we're referring
	asl
	tax
	lda	GREETINGS,x
	sta	$00
	inx
	lda	GREETINGS,x
	sta	$01

	ldy	#39
copy_1:
	lda	($00),y
	cmp	#$20
	beq	copy_2
	lda	#$ff
copy_2:
	sta	TEXT_BUFFER,y
	dey
	bpl	copy_1
	rts

odds:
	db	1, 3, 5, 7, 9, 11, 13, -5, -3, -1
	db	1, 3, 5, 7, 9, 11, 13, -5, -3, -1
	db	1, 3, 5, 7, 9, 11, 13, -5, -3, -1
	db	1, 3, 5, 7, 9, 11, 13, -5, -3, -1

update_text_buffer:

	lda	GREETINGS_LINE	; find the greetings line we're referring
	asl
	tax
	lda	GREETINGS,x
	sta	$00
	inx
	lda	GREETINGS,x
	sta	$01

	ldx	#0		; have we updated any characters?
	ldy	#39		; how many characters to run through

update_1:
	lda	TEXT_BUFFER,y
	cmp	($00),y
	beq	update_2

	clc
	lda	odds,y
	adc	TEXT_BUFFER,y
	sta	TEXT_BUFFER,y
	ldx	#1
update_2:
	dey
	bpl	update_1
	txa			; return boolean as a
	rts


draw_text_buffer:
	ldx	#39
loop_draw_text_buffer:
	lda	TEXT_BUFFER,x
	ora	#$80
	sta	#$6d0,x
	dex
	bpl	loop_draw_text_buffer
	rts

delay:
	ldx	#$50
d1	ldy	#$20
d2	dey
	bpl	d2
	dex
	bne	d1
	rts

next_greetings_line:
	inc	GREETINGS_LINE
	ldx	GREETINGS_LINE
	cpx	#9
	bne	x1
	ldx	#0
	stx	GREETINGS_LINE
x1:
	rts

hscroll:
	ldy	#115
	sty	$02			; current line being scrolled

h0:
	ldy	$02
	lda	YLO,y			; calculate row offset
	sta	$00
	lda	YHI,y
	sta	$01

	ldy	#0			; copy the first byte in this row
	lda	($00),y
	pha				; and push it into stack
	iny
	lda	($00),y
	pha				; copy the second byte

	ldy	#00

h1:
	iny
	iny
	lda	($00),y
	dey
	dey
	sta	($00),y
	iny
	cpy	#40
	bne	h1

	pla
	ldy	#39
	sta	($00),y
	pla
	dey
	sta	($00),y

	inc	$02
	ldy	$02
	cpy	#160
	bne	h0
	rts

loop:
	lda	#0
	sta	GREETINGS_LINE
	sta	GREETINGS_DELAY
	lda	#1
	sta	HSCROLL_DELAY

loop0:
	jsr	reset_text_buffer
loop1:
	jsr	vblank

	dec	HSCROLL_DELAY
	bne	skip_hscroll
	jsr	hscroll
	lda	#15
	sta	HSCROLL_DELAY
skip_hscroll:

	lda	GREETINGS_DELAY
	bne	delay_on_text

	jsr	draw_text_buffer
	jsr	update_text_buffer
	bne	loop1

text_buffer_complete:
	lda	#$ff
	sta	GREETINGS_DELAY

	jsr	next_greetings_line
	jmp	loop0

delay_on_text:
	dec	GREETINGS_DELAY
	jmp	loop0

dead:
	jmp	dead

vsync:
	lda	$c019
	bmi	vblank
	rts

vblank:
	lda	$c019
	bpl	vblank
	rts

YLO	hex 00 00 00 00 00 00 00 00 80 80 80 80 80 80 80 80
	hex 00 00 00 00 00 00 00 00 80 80 80 80 80 80 80 80
	hex 00 00 00 00 00 00 00 00 80 80 80 80 80 80 80 80
	hex 00 00 00 00 00 00 00 00 80 80 80 80 80 80 80 80

	hex 28 28 28 28 28 28 28 28 A8 A8 A8 A8 A8 A8 A8 A8
	hex 28 28 28 28 28 28 28 28 A8 A8 A8 A8 A8 A8 A8 A8
	hex 28 28 28 28 28 28 28 28 A8 A8 A8 A8 A8 A8 A8 A8
	hex 28 28 28 28 28 28 28 28 A8 A8 A8 A8 A8 A8 A8 A8

	hex 50 50 50 50 50 50 50 50 D0 D0 D0 D0 D0 D0 D0 D0
	hex 50 50 50 50 50 50 50 50 D0 D0 D0 D0 D0 D0 D0 D0
	hex 50 50 50 50 50 50 50 50 D0 D0 D0 D0 D0 D0 D0 D0
	hex 50 50 50 50 50 50 50 50 D0 D0 D0 D0 D0 D0 D0 D0

YHI	hex 20 24 28 2C 30 34 38 3C 20 24 28 2C 30 34 38 3C
	hex 21 25 29 2D 31 35 39 3D 21 25 29 2D 31 35 39 3D
	hex 22 26 2A 2E 32 36 3A 3E 22 26 2A 2E 32 36 3A 3E
	hex 23 27 2B 2F 33 37 3B 3F 23 27 2B 2F 33 37 3B 3F

	hex 20 24 28 2C 30 34 38 3C 20 24 28 2C 30 34 38 3C
	hex 21 25 29 2D 31 35 39 3D 21 25 29 2D 31 35 39 3D
	hex 22 26 2A 2E 32 36 3A 3E 22 26 2A 2E 32 36 3A 3E
	hex 23 27 2B 2F 33 37 3B 3F 23 27 2B 2F 33 37 3B 3F

	hex 20 24 28 2C 30 34 38 3C 20 24 28 2C 30 34 38 3C
	hex 21 25 29 2D 31 35 39 3D 21 25 29 2D 31 35 39 3D
	hex 22 26 2A 2E 32 36 3A 3E 22 26 2A 2E 32 36 3A 3E
	hex 23 27 2B 2F 33 37 3B 3F 23 27 2B 2F 33 37 3B 3F

LINE1	db "            EEEEEEEEEEEEEEK!!!!         "
LINE2	db "====== IT'S 12 SECTORS TO MIDNIGHT ====="
LINE3	db "     WISHING YOU A HAPPY QUARANTINE!    "
LINE4	db "         OF SWEET SWEET COVID 19        "
LINE5	db "         NNNNNNAAAAAAAAHHHHHHHH!        "
LINE6   db "         MAY THIS ALL END SOON..        "
LINE7	db "     AND WE ALL BE TRICK OR TREATING    "
LINE8	db " GREETINGS TO THE A2E FACEBOOK GROUP <3 "
LINE9	db " -------------------------------------- "

GREETINGS
	db <LINE1, >LINE1
	db <LINE2, >LINE2
	db <LINE3, >LINE3
	db <LINE4, >LINE4
	db <LINE5, >LINE5
	db <LINE6, >LINE6
	db <LINE7, >LINE7
	db <LINE8, >LINE8
	db <LINE9, >LINE9

;incsrc "sprite-moon.s"

compressed_bitmap:
incbin "HAGCH.BIN"

; ORG $8000+3072-4
