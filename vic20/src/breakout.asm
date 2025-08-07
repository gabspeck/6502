// Safe ZP: FB-FE (8 bytes)
*= $FB virtual
// .watch screenPointer,screenPointer+1,"store"
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

// Flags
.const flagMask=%0000_0001
.const FLAG_PAUSED=flagMask
.const FLAG_X_VELOCITY_NEG=flagMask<<1
.const FLAG_Y_VELOCITY_NEG=flagMask<<2

// Numeric constants
.const PADDLE_WIDTH=2
.const INITIAL_UPDATE_INTERVAL=3

// Misc. labels
.label PaddleRow = $1E00 + 22*21

// VARIABLES
// Cache Y multiplication for X/Y to screen pointer conversion
y_times_22:
.for (var y = 0; y < 23; y++) {
	.word y * 22 
}

paddleX: .byte 10
ballX: .word 11
ballY: .word 11
ballUpdateInterval: .byte INITIAL_UPDATE_INTERVAL
ballUpdateCountdown: .byte INITIAL_UPDATE_INTERVAL
flags: .byte 0
ballAngle: .byte 1

start:

	lda #CLRSCR
	jsr CHROUT

	lda #%0000_1001
	sta SCR_COLOR

	jsr DrawBricks

	lda $9124
	and #FLAG_X_VELOCITY_NEG
	sta flags

	jmp MainLoop

DrawBricks: {
	
	.for (var i=0;i<6;i++) {
	drawRow:
		lda #32+128
		sta $1E00,Y
		lda #02+i
		sta $9600,Y
		iny
		cpy #22+i*22
		bne drawRow
	}
	rts

}

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

	cpx #LEFT
	beq moveLeft
	cpx #RIGHT
	beq moveRight
	pauseCheck:
	cpx #ENTER
	beq togglePause

	rts

	moveLeft:
		lda paddleX
		beq return
		dec paddleX
		jmp return
	moveRight:
		lda paddleX
		cmp #22-PADDLE_WIDTH-2
		beq return
		inc paddleX
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
	bne return // no? return
	
	// alright, it's time to move the ball
	
	// reset the countdown timer
	lda ballUpdateInterval
	sta ballUpdateCountdown

	jsr CheckYCollision
	jsr UpdateBallX
	jsr CheckXCollision
	jsr UpdateBallY
	jsr XYCoordsToScreenPointer

	return:
		rts

}

CheckXCollision: {
	lda ballX

	beq invert
	cmp #21
	bcs invert

	jmp return

	invert:
		lda flags
		eor #FLAG_X_VELOCITY_NEG
		sta flags
		lda #1
		sta ballAngle

	return: rts

}

CheckYCollision: {
	lda ballY
	cmp #0
	beq invert

	cmp #21
	bne return

	lda ballX
	sec
	sbc paddleX 
	cmp #0
	beq leftAngle2
	cmp #1
	beq leftAngle1
	cmp #2
	beq rightAngle1
	cmp #3
	beq rightAngle2
	jmp return

	leftAngle2:
		lda #2
		sta ballAngle
		jmp leftAngle
	leftAngle1:
		lda #1
		sta ballAngle
	leftAngle:
		lda flags
		ora #FLAG_X_VELOCITY_NEG
		sta flags
		jmp invert

	rightAngle1:
		lda #1
		sta ballAngle
		jmp rightAngle
	rightAngle2:
		lda #2
		sta ballAngle
		jmp rightAngle
	rightAngle:
		lda flags
		and #~FLAG_X_VELOCITY_NEG
		sta flags

	invert:
		lda flags
		eor #FLAG_Y_VELOCITY_NEG
		sta flags

	return: rts
}

UpdateBallX: {
	lda #FLAG_X_VELOCITY_NEG
	bit flags
	beq goRight

	goLeft:
		lda ballX
		sec
		sbc ballAngle
		jmp return
	goRight:
		lda ballX
		clc
		adc ballAngle

	return: 
		sta ballX
		rts
}

UpdateBallY:{
	lda #FLAG_Y_VELOCITY_NEG
	bit flags
	beq goDown

	goUp:
		dec ballY
		jmp return
	goDown:
		lda ballY
		cmp #22
		beq wrapAround
		inc ballY
		jmp return
		wrapAround:
			lda flags
			eor #FLAG_Y_VELOCITY_NEG
			sta flags
			lda #0
			sta ballY

	return: 
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

	ldy paddleX

	lda #ROUNDED_BORDER_TOP_LEFT
	sta PaddleRow,Y
	iny
	lda #BORDER_TOP
	.for (var i = 0; i < PADDLE_WIDTH; i++) {
		sta PaddleRow,Y
		iny
	}
	lda #ROUNDED_BORDER_TOP_RIGHT
	sta PaddleRow,Y

	tya
	clc
	adc #22-PADDLE_WIDTH-1
	tay

	lda #ROUNDED_BORDER_BOTTOM_LEFT
	sta PaddleRow,Y
	iny
	lda #BORDER_BOTTOM
	.for (var i = 0; i < PADDLE_WIDTH; i++) {
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

	lda ballY
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
	lda ballX
	clc 
	adc screenPointer
	sta screenPointer
	lda #00
	adc screenPointer+1
	sta screenPointer+1
	rts
}
