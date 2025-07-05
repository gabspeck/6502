#import "basic_stub.asm"

// KERNAL Routines
.label CHROUT=$FFD2
.label GETIN=$FFE4
.label SCNKEY=$FF9F

// ASCII codes
.const SPACE=32
.const UP=145
.const DOWN=17
.const LEFT=157
.const RIGHT=29
.const CLRSCR=$93

// Screen codes
.const HEART=83

//Color codes
.const RED=$02

// Zero page positions
.const ZP=$00
.const SCR_PTR=ZP
.const COLOR_PTR=ZP+2
.const SCR_X=ZP+4
.const SCR_Y=ZP+5
.const SCR_INDEX=ZP+6
.const TEMP_1=$FF
.const TEMP_2=TEMP_1-1

start:
	lda #CLRSCR
	jsr CHROUT

	lda #11
	sta SCR_X
	lda #11
	sta SCR_Y

main_loop:
	jsr draw
	
	jmp handle_input
	
	jmp main_loop
	
handle_input:
	jsr GETIN
	
	cmp #UP
		beq move_up
	cmp #DOWN
		beq move_down
	cmp #LEFT
		beq move_left
	cmp #RIGHT
		beq move_right
	
	jmp main_loop

	move_up:
		lda SCR_Y
		cmp #00
		beq main_loop
		jsr clear
		dec SCR_Y
		jmp main_loop
	move_down:
		lda SCR_Y
		cmp #22
		beq main_loop
		jsr clear
		inc SCR_Y
		jmp main_loop
	move_left:
		lda SCR_X
		cmp #0
		beq main_loop
		jsr clear
		dec SCR_X
		jmp main_loop
	move_right:
		lda SCR_X
		cmp #21
		beq main_loop
		jsr clear
		inc SCR_X
		jmp main_loop
		
clear:
	ldy #0
	lda #SPACE
	sta (SCR_PTR),Y 
	rts

draw:
	// translate X and Y coordinates to linear index to the screen memory (0-505)
	jsr xy_to_index
	
	// initialize high byte of screen memory
	lda #$1E
	sta SCR_PTR+1

	// initialize high byte of color memory
	lda #$96
	sta COLOR_PTR+1
	
	// since the memories start at 00, we can load the low byte of the index to screen 
	// and color memories directly into the pointer
	lda SCR_INDEX
	sta SCR_PTR
	sta COLOR_PTR

	// add the high byte of the index to the screen pointer in case it overflowed to a second byte
	lda SCR_INDEX+1
	clc
	adc SCR_PTR+1
	sta SCR_PTR+1

	// to get the high byte of the color pointer, we simply add $96-$1E to the high byte of the 
	// screen pointer
	clc	
	adc #$78 // delta between high bytes of screen memory and color memory
	sta COLOR_PTR+1
	
	// even though we store the full address in the pointer, we need the Y register for 
	// indrect addressing, so we just set it to 0
	ldy #0


	// and, finally, load the heart character into the correct screen pointer...
	lda #HEART
	sta (SCR_PTR),Y

	// ...and set it's color to red
	lda #RED
	sta (COLOR_PTR),Y

	rts

xy_to_index:

	lda SCR_Y
	asl // multiply by 2 to get correct index for 16-bit value (0=0,1=2,2=4,3=6,4=8, etc.)
	tay

	// retrieve and store LOW byte
	lda y_times_22,Y
	sta SCR_INDEX 

	// retrieve and store HIGH byte
	lda y_times_22+1,Y
	sta SCR_INDEX+1

	// add X to the index
	lda SCR_X
	clc 
	adc SCR_INDEX
	sta SCR_INDEX
	lda #00
	adc SCR_INDEX+1
	sta SCR_INDEX+1

	rts
	
y_times_22:
.for (var y = 0; y < 23; y++) {
	.word y * 22 
}