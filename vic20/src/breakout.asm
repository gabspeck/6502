#import "basic_stub.asm"
#import "kernal.inc.asm"

.const SCR_COLOR = $0900F

// ASCII codes
.const SPACE=32
.const UP=145
.const DOWN=17
.const LEFT=157
.const RIGHT=29
.const CLRSCR=$93

// Screen codes
.const ROUNDED_BORDER_TOP_LEFT=85
.const ROUNDED_BORDER_TOP_RIGHT=73
.const ROUNDED_BORDER_BOTTOM_LEFT=74
.const ROUNDED_BORDER_BOTTOM_RIGHT=75
.const BORDER_TOP=67
.const BORDER_BOTTOM=70
.const BORDER_LEFT=66
.const BORDER_RIGHT=72

.const PaddleRow = $1E00 + 22 * 21

// ZP positions
.const ZP=$00
.const paddleOffset=ZP

// Numeric constants
.const paddleWidth=2

start:

	lda #%0000_1001
	sta SCR_COLOR

	lda #0
	sta paddleOffset

	jsr SetColors

	jmp MainLoop

MainLoop: {
	jsr HandleInput
	jsr VblankSync
	jsr DrawPaddle
	jmp MainLoop
}

VblankSync: {

	loop:
		lda $9004
		bne loop

	lda #CLRSCR
	jsr CHROUT

	rts
}

HandleInput: {
	jsr GETIN

	cmp #LEFT
	beq moveLeft
	cmp #RIGHT
	beq moveRight
	
	rts

	moveLeft:
		lda paddleOffset
		cmp #00
		beq return
		dec paddleOffset
		jmp return
	moveRight:
		lda paddleOffset
		cmp #22-paddleWidth-2
		beq return
		inc paddleOffset
	
	return: rts
}

SetColors: {
	lda #01
	ldy 0
	loop:
		sta PaddleRow+$7800,Y
		iny
		cpy #(22*2)+1
		bne loop
	rts
}

DrawPaddle: {
	ldy paddleOffset

	lda #ROUNDED_BORDER_TOP_LEFT
	sta PaddleRow,Y
	iny
	lda #BORDER_TOP
	.for (var i = 0; i < paddleWidth; i++) {
		sta PaddleRow,Y
		iny
	}
	lda #ROUNDED_BORDER_TOP_RIGHT
	sta PaddleRow,Y

	tya
	adc #22-paddleWidth-1
	tay

	lda #ROUNDED_BORDER_BOTTOM_LEFT
	sta PaddleRow,Y
	iny
	lda #BORDER_BOTTOM
	sta PaddleRow,Y
	iny
	sta PaddleRow,Y
	iny
	lda #ROUNDED_BORDER_BOTTOM_RIGHT
	sta PaddleRow,Y

	rts

}
