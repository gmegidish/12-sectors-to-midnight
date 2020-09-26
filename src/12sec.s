;
;   __ ___                _                 _                  _     _       _       _     _
;  /_ |__ \              | |               | |                (_)   | |     (_)     | |   | |
;   | |  ) |___  ___  ___| |_ ___  _ __ ___| |_ ___  _ __ ___  _  __| |_ __  _  __ _| |__ | |_
;   | | / // __|/ _ \/ __| __/ _ \| '__/ __| __/ _ \| '_ ` _ \| |/ _` | '_ \| |/ _` | '_ \| __|
;   | |/ /_\__ \  __/ (__| || (_) | |  \__ \ || (_) | | | | | | | (_| | | | | | (_| | | | | |_
;   |_|____|___/\___|\___|\__\___/|_|  |___/\__\___/|_| |_| |_|_|\__,_|_| |_|_|\__, |_| |_|\__|
;                                                                               __/ |
;                                                                              |___/
;
; A short scroller demo for Apple2
; Written by Gil Megidish (www.megidish.net)
; Written for 12 Sectors to Midnight (https://www.facebook.com/events/2551527591827790/)
; LZ4FH decompression routines by Andy McFadden & Peter Ferrie

ORG $8000

incsrc	"equ.s"

SRCX		EQU	$0000
SRCY		EQU	$0001
SRCW		EQU	$0002
SRCH		EQU	$0003
DSTX		EQU	$0004
DSTY		EQU	$0005
SRC_OFFSET	EQU	$0006
DST_OFFSET	EQU	$0008
HAG_Y_DELAY	EQU	$000a
GREETINGS_LINE	EQU	$0010
HSCROLL_DELAY	EQU	$0011
HAG_Y_LUT	EQU	$0012
GREETINGS_DELAY	EQU	$0013
TEXT_BUFFER	EQU	$0020

start:
	jsr	prepare_screen
	jsr	clear_text_framebuffer

	lda	HIRES
	lda	GR
	lda	SETMIXED
	;lda	CLRMIXED
	lda	CLRPAGE2
	jsr	loop

exit:
	lda	TEXT
	lda	CLRMIXED
	rts

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

	lda	#<compressed_bitmap
	sta	$2fc
	lda	#>compressed_bitmap
	sta	$2fd

	lda	#$00			; unpack directly into page1
	sta	$2fe
	lda	#$20
	sta	$2ff

	jsr	entry			; call lz4fh decompressor
	rts

copy_sprite:
	clc
	ldx	SRCY
	lda	YLO,x
	adc	SRCX
	sta	SRC_OFFSET
	lda	YHI,x
	adc	#0
	sta	SRC_OFFSET+1

	clc
	ldx	DSTY
	lda	YLO,x
	adc	DSTX
	sta	DST_OFFSET
	lda	YHI,x
	adc	#0
	sta	DST_OFFSET+1

	ldy	SRCW
	dey
copy_bytes:
	lda	(SRC_OFFSET),y
	sta	(DST_OFFSET),y
	dey
	bpl	copy_bytes

	inc	SRCY
	inc	DSTY
	dec	SRCH
	bne	copy_sprite
	rts

;=========================
; Prepare current greeting line with random characters (always 0xff)
; but with spaces in the right positions.
;=========================
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

;=========================
; Update greetings with then next frame. Will update all characters, and
; if no characters were updated, will return A=0.
;=========================
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
	lda	SOME_ODD_NUMBERS,y
	adc	TEXT_BUFFER,y
	sta	TEXT_BUFFER,y
	lda	SPEAKER
	ldx	#1
update_2:
	dey
	bpl	update_1
	txa			; return boolean as a
	rts

;=========================
; Copy the current greeting line to text framebuffer.
;=========================
draw_text_buffer:
	ldx	#39
loop_draw_text_buffer:
	lda	TEXT_BUFFER,x
	ora	#$80
	sta	#$6d0,x
	dex
	bpl	loop_draw_text_buffer
	rts

;=========================
; Move pointer to next greeting line
;=========================
next_greetings_line:
	inc	GREETINGS_LINE
	ldx	GREETINGS_LINE
	cpx	#8
	bne	x1
	ldx	#0
	stx	GREETINGS_LINE
x1:
	rts

;=========================
; Horizontal scroll of rows 115-160 (trees)
;=========================
hscroll:
	ldy	#115
	sty	$04			; current line being scrolled

h0:
	ldy	$04
	lda	YLO,y			; calculate row offset
	sta	$00
	lda	YHI,y
	sta	$01

	clc
	lda	YLO,y
	adc	#2
	sta	$02
	lda	YHI,y
	adc	#0
	sta	$03

	ldy	#0			; copy the first byte in this row
	lda	($00),y
	pha				; and push it into stack
	iny
	lda	($00),y
	pha				; copy the second byte

	ldy	#00

h1:
	lda	($02),y
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

	inc	$04
	ldy	$04
	cpy	#160
	bne	h0
	rts

;=========================
; Draw old hag at her position. Takes delay and y-positioning into consideration.
;=========================
draw_hag:
	dec	HAG_Y_DELAY
	bne	draw_hag_2

	lda	#8
	sta	HAG_Y_DELAY

	inc	HAG_Y_LUT
	ldx	HAG_Y_LUT
	lda	HAG_Y,x
	cmp	#127
	bne	draw_hag_2
	lda	#0
	sta	HAG_Y_LUT

	; copy (7,164) 28x19
draw_hag_2:
	lda	#1			; 7/7
	sta	SRCX
	lda	#163
	sta	SRCY
	lda	#4			; 28/7
	sta	SRCW
	lda	#22
	sta	SRCH
	lda	#3
	sta	DSTX			; 21/7
	clc
	ldx	HAG_Y_LUT
	lda	HAG_Y,x
	adc	#21
	sta	DSTY
	jmp	copy_sprite

;=========================
; Main demo loop. This never exits :)
;=========================
loop:
	lda	#0
	sta	GREETINGS_LINE
	sta	GREETINGS_DELAY
	sta	HAG_Y_LUT
	lda	#1
	sta	HSCROLL_DELAY
	sta	HAG_Y_DELAY

loop0:
	jsr	reset_text_buffer
loop1:
	jsr	draw_hag

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

LINE1	db "====== IT'S 12 SECTORS TO MIDNIGHT ====="
LINE2	db "     WISHING YOU A HAPPY QUARANTINE!    "
LINE3	db "         OF SWEET SWEET COVID 19        "
LINE4	db "         NNNNNNAAAAAAAAHHHHHHHH!        "
LINE5	db "  MAY WE ALL BE TRICK OR TREATING SOON! "
LINE6	db " GREETINGS TO THE A2E FACEBOOK GROUP <3 "
LINE7	db "    WEAR SUNSCREEN. VOTE FOR PEDRO.     "
LINE8	db "           SEE YOU IN 2021              "

GREETINGS
	db <LINE1, >LINE1
	db <LINE2, >LINE2
	db <LINE3, >LINE3
	db <LINE4, >LINE4
	db <LINE5, >LINE5
	db <LINE6, >LINE6
	db <LINE7, >LINE7
	db <LINE8, >LINE8

; used for text effect. must be an odd value to ever make it to the right character
SOME_ODD_NUMBERS
	db 1, 3, 5, 7, 9, 11, 13, -5, -3, -1, 1, 3, 5, 7, 9, 11, 13, -5, -3, -1
	db 1, 3, 5, 7, 9, 11, 13, -5, -3, -1, 1, 3, 5, 7, 9, 11, 13, -5, -3, -1

; hag vertical position animation. fake sine wave :)
HAG_Y
	db 0, -1, -2, -2, -3, -3, -3, -2, -2, -1, 0
	db 0, +1, +2, +2, +3, +3, +3, +2, +2, +1, 0
	db 127

incsrc "hires.s"
incsrc "lz4fh6502.s"

compressed_bitmap:
incbin "hagch.lz4"

; uncomment this line to make a perfect 3072 bytes file
; ORG $8000+3072-4
