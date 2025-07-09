// Safe ZP: FB-FE (8 bytes)
*= $FB virtual
.zp {
	screenPointer: .word 0 //$FBFC
	prevScreenPointer: .word 0 //$FDFE
}

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
.const FRAMES_BETWEEN_UPDATES=3

// Flags
.const flagMask=%0000_0001
.const FLAG_PAUSED=flagMask
.const FLAG_X_VELOCITY_SIGN=flagMask<<1
.const FLAG_Y_VELOCITY_NEG=flagMask<<2

// Numeric constants
.const paddleWidth=2


// Misc. labels
.label PaddleRow = $1E00 + 22*21

// VARIABLES
// Cache Y multiplication for X/Y to screen pointer conversion
y_times_22:
.for (var y = 0; y < 23; y++) {
	.word y * 22 
}

paddleOffset: .byte 0
ballX: .byte 11
ballY: .byte 11
velocityX: .byte 1
velocityY: .byte 1
ballUpdateCountdown: .byte 3
flags: .byte 0

start:

	lda #CLRSCR
	jsr CHROUT

	lda #%0000_1001
	sta SCR_COLOR

	jsr SetColors

	jmp MainLoop

MainLoop: {

	jsr WaitVBlank

	jsr HandleInput

	lda #FLAG_PAUSED
	bit flags
	bne MainLoop

	jsr ClearPaddleArea
	jsr DrawPaddle
	jsr UpdateBallState
	jsr DrawBall

	jmp MainLoop
}

ClearPaddleArea: {
	lda #SPACE
	ldy #0

	loop:
		sta PaddleRow,Y
		iny
		bne loop
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

	lda #FLAG_PAUSED
	bit flags
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

	// decrease frame counter
	dec ballUpdateCountdown

	// is it zero yet?
	lda ballUpdateCountdown
	bne return // no? return
	
	// alright, it's time to move the ball
	
	// reset the countdown timer
	lda #FRAMES_BETWEEN_UPDATES
	sta ballUpdateCountdown

	// is the Y velocity negative?
	lda #FLAG_Y_VELOCITY_NEG
	bit flags
	bne goUp // if so, move the ball upward

	goDown:
		clc
		lda ballY
		adc velocityY

		// ballY <= 20?
		cmp #20
		bcc storeBallY // yes: no need to flip the sign, just update the pointer

		// this is as low as it can go, so reverse vertical direction
		lda flags
		ora #FLAG_Y_VELOCITY_NEG
		sta flags
		lda #20
		jmp storeBallY
	
	goUp:
		sec
		lda ballY
		sbc velocityY

		bcs storeBallY // carry is set, subtraction did not underflow, so we are within bounds

		lda flags
		and #~FLAG_Y_VELOCITY_NEG
		sta flags
		lda #0
	
	storeBallY: tay

	sty ballY
	ldx ballX

	jsr XYCoordsToScreenPointer

	return: rts
}

SetColors: {
	lda #01
	ldy 0
	upper:
		sta $9600
		iny
		bne upper
	lower:
		sta $9700
		iny
		bne lower
	rts
}

DrawBall: {
	ldy #0

	lda #SPACE
	sta (prevScreenPointer),Y

	lda #BALL_FILLED
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
	clc
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

XYCoordsToScreenPointer: {

	lda screenPointer
	sta prevScreenPointer

	lda screenPointer+1
	sta prevScreenPointer+1

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

	// add X to the index and update the pointer
	txa
	clc 
	adc screenPointer
	sta screenPointer
	lda #00
	adc screenPointer+1
	sta screenPointer+1
	rts
}
