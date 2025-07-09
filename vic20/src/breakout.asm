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
.const ENTER=13

// Screen codes
.const ROUNDED_BORDER_TOP_LEFT=85
.const ROUNDED_BORDER_TOP_RIGHT=73
.const ROUNDED_BORDER_BOTTOM_LEFT=74
.const ROUNDED_BORDER_BOTTOM_RIGHT=75
.const BORDER_TOP=67
.const BORDER_BOTTOM=70
.const BORDER_LEFT=66
.const BORDER_RIGHT=72
.const BALL_FILLED=81

// Flags
.const FLAG_PAUSED=%0000_0001

.const PaddleRow = $1E00 + 22 * 21

// ZP positions
.var ZP=$00
.const paddleOffset=ZP++
.const screenPointer=ZP++

ballX: .byte 11
ballY: .byte 11
flags: .byte 0

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

	jsr WaitVBlank
	jsr HandleInput

	lda flags
	and #FLAG_PAUSED
	bne MainLoop

	jsr ClearScreen
	jsr DrawPaddle
	jsr DrawBall
	jsr UpdateBallState
	jmp MainLoop
}

ClearScreen: {
	lda #SPACE
	ldx #0

	upper:
		sta $1E00,X
		inx
		bne upper
	
	lower:
		sta $1F00,X
		inx 
		bne lower
	
	rts
	
}

WaitVBlank:{
vbBottom:
        lda $9004
        bpl vbBottom         // wait bottom half
vbTop:
        lda $9004
        bmi vbTop            // wait top half
	rts
}


HandleInput: {

	jsr GETIN
	tax

	lda flags
	and #FLAG_PAUSED
	bne pauseCheck

	txa
	cmp #LEFT
	beq moveLeft
	cmp #RIGHT
	beq moveRight
	pauseCheck:
	txa
	cmp #ENTER
	beq togglePause

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
		jmp return
	togglePause:
		lda flags
		eor #FLAG_PAUSED
		sta flags
	
	return: rts
}


UpdateBallState: {
	ldx ballX
	ldy ballY

	jsr xy_to_index

	stx screenPointer
	sty screenPointer+1

	rts
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

DrawBall: {

	lda #BALL_FILLED
	ldy #0
	sta (screenPointer),Y

	clc
	lda screenPointer+1
	adc #$78
	sta screenPointer+1,Y

	lda #01
	sta (screenPointer),Y

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
	.for (var i = 0; i < paddleWidth; i++) {
		sta PaddleRow,Y
		iny
	}
	lda #ROUNDED_BORDER_BOTTOM_RIGHT
	sta PaddleRow,Y

	return: rts

}

xy_to_index:

	lda #$00
	sta screenPointer

	lda #$1E
	sta screenPointer+1

	tya
	asl // multiply by 2 to get correct index for 16-bit value (0=0,1=2,2=4,3=6,4=8, etc.)
	tay

	clc
	lda y_times_22,Y
	adc screenPointer
	sta screenPointer

	lda y_times_22+1,Y
	adc screenPointer+1
	sta screenPointer+1

	// add X to the index
	txa
	clc 
	adc screenPointer
	tax
	lda #00
	adc screenPointer+1
	tay

	rts
	
y_times_22:
.for (var y = 0; y < 23; y++) {
	.word y * 22 
}
