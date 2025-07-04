#import "basic_stub.asm"

// KERNAL Routines
.label CHROUT=$FFD2
.label GETIN=$FFE4
.label SCNKEY=$FF9F

.const CLRSCR=$93
.const COLOR_PTR=$00
.const POS_PTR=$02
.const POS_X=$04
.const POS_Y=$05
.const INDEX=$06
.const TEMP_1=$FF
.const TEMP_2=$FE

start:

lda #CLRSCR
jsr CHROUT

lda #$00
sta COLOR_PTR
lda #$96
sta COLOR_PTR+1


lda #$00
sta POS_PTR
lda #$1E
sta POS_PTR+1

lda #11
sta POS_X
lda #11
sta POS_Y

jsr draw
jmp *

draw:
	jsr xy_to_index

	lda #0
	sta COLOR_PTR
	sta POS_PTR
	lda #$96
	sta COLOR_PTR+1
	lda #$1E
	sta POS_PTR+1

	lda INDEX
	clc
	adc COLOR_PTR
	sta COLOR_PTR
	lda INDEX+1
	adc COLOR_PTR+1
	sta COLOR_PTR+1

	lda INDEX
	clc
	adc POS_PTR
	sta POS_PTR
	lda INDEX+1
	adc POS_PTR+1
	sta POS_PTR+1

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