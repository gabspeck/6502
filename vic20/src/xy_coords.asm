#import "basic_stub.asm"

// KERNAL Routines
.label CHROUT=$FFD2
.label GETIN=$FFE4
.label SCNKEY=$FF9F

// Key codes
.const CLRSCR=$93

// Zero page positions
.const ZP=$00
.const POS_PTR=ZP
.const COLOR_PTR=ZP+2
.const POS_X=ZP+4
.const POS_Y=ZP+5
.const INDEX=ZP+6
.const TEMP_1=$FF
.const TEMP_2=TEMP_1-1

start:

lda #CLRSCR
jsr CHROUT

lda #21
sta POS_X
lda #11
sta POS_Y

jsr draw
jmp *

draw:
	// translate X and Y coordinates to linear index to the screen memory (0-505)
	jsr xy_to_index

	lda #$1E
	sta POS_PTR+1

	lda #$96
	sta COLOR_PTR+1
	
	lda INDEX
	sta POS_PTR
	sta COLOR_PTR

	lda INDEX+1
	clc
	adc POS_PTR+1
	sta POS_PTR+1
	
	lda INDEX+1
	clc
	adc COLOR_PTR+1
	sta COLOR_PTR+1

	ldy #0

	lda #$02
	sta (COLOR_PTR),Y

	lda #83
	sta (POS_PTR),Y

	rts

xy_to_index:

	lda POS_Y
	asl // multiply by 2 to get correct index for 16-bit value (0=0,1=2,2=4,3=6,4=8, etc.)
	tay

	// retrieve and store LOW byte
	lda y_times_22,Y
	sta INDEX 

	// retrieve and store HIGH byte
	lda y_times_22+1,Y
	sta INDEX+1

	// add X to the index
	lda POS_X
	clc 
	adc INDEX
	sta INDEX
	lda #00
	adc INDEX+1
	sta INDEX+1

	rts

y_times_22:
.for (var y = 0; y < 23; y++) {
	.word y * 22 
}