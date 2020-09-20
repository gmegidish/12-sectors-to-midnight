
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
TEXT_BUFFER	EQU	$0040

start:
	lda	HIRES
	lda	GR
	lda	SETMIXED
	lda	CLRMIXED
	lda	CLRPAGE2
	;jsr	paint_moon
	jsr	prepare_screen
	jmp	loop

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


paint_moon:
	lda	#6
	sta	ZP_WIDTH
	lda	#39
	sta	ZP_HEIGHT
	lda	#00
	sta	ZP_X
	lda	#00
	sta	ZP_Y
;	lda	#<SPRITE0
;	sta	SRC_START_LO
;	lda	#>SPRITE0
;	sta	SRC_START_HI
	jmp	draw_sprite

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
	ldx	#39
copy_1:
	lda	GREETINGS,x
	cmp	#$20
	beq	copy_2
	lda	#$ff
copy_2:
	sta	TEXT_BUFFER,x
	dex
	bpl	copy_1
	rts

odds
	db	1, 3, 5, 7, 9, 11, 13, 15, 17, 19
	db	1, 3, 5, 7, 9, 11, 13, 15, 17, 19
	db	1, 3, 5, 7, 9, 11, 13, 15, 17, 19
	db	1, 3, 5, 7, 9, 11, 13, 15, 17, 19

update_text_buffer:
	ldy	#0		; have we updated any characters?
	ldx	#39
update_1:
	lda	TEXT_BUFFER,x
	cmp	GREETINGS,x
	beq	update_2

	clc
	lda	odds,x
	adc	TEXT_BUFFER,x
	sta	TEXT_BUFFER,x
	ldy	#1
update_2:
	dex
	bpl	update_1
	tya			; return boolean as A
	rts


draw_text_buffer:
	ldx	#39
loop_draw_text_buffer:
	lda	TEXT_BUFFER,x
	ora	#$80
	sta	#$650,x
	dex
	bpl	loop_draw_text_buffer
	rts

delay:
rts
	ldx	#$50
d1	ldy	#$20
d2	dey
	bpl	d2
	dex
	bne	d1
	rts

next_greetings_line:
	ldx	GREETINGS_LINE
	inx
	cpx	#6
	bcs	x1
	ldx	#0
x1:
	stx	GREETINGS_LINE
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

h1:
	iny
	lda	($00),y
	dey
	sta	($00),y
	iny
	cpy	#40
	bne	h1

	dey
	pla
	sta	($00),y

	inc	$02
	ldy	$02
	cpy	#160
	bne	h0
	rts

loop:
	lda	#0
	sta	GREETINGS_LINE

loop0:
	jsr	reset_text_buffer
loop1:
	jsr	vblank
	jsr	hscroll
;	jsr	delay
	jsr	draw_text_buffer
	jsr	update_text_buffer
	bne	loop1

	jsr	next_greetings_line
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

GREETINGS
;	db "1234567890123456789012345678901234567890"
;	db "            EEEEEEEEEEEEEEK!!!!         "
;	db "        IT'S 12 SECTORS TO MIDNIGHT     "
	db "     WISHING YOU A HAPPY QUARANTINE!    "
	db "         OF SWEET SWEET COVID 19        "
	db " NNNAAAAAHHHH! MAY THIS ALL END SOON!   "
	db "     AND WE ALL BE TRICK OR TREATIN'    "

;incsrc "sprite-moon.s"

compressed_bitmap:
incbin "HAGCH.BIN"

; ORG $8000+3072-4
