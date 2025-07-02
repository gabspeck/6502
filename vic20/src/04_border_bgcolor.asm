#import "basic_stub.asm"

// 4. **Color Change** - Change the border and background colors using VIC registers
/*
900F Screen and border color register
bits 4-7 select background color
bits 0-2 select border color
bit 3 selects inverted or normal mode
*/
// BEQ will perform a jump if Zero flag is 1.
// BNE will perform a jump if Zero flag is 0.

// This will loop through all possible values for border color

.const SCR_COLOR = $900F
.const RASTER_CNT = $9004
.const BORDER_RESET = %1111_1000
.const FRAMES_PER_COLOR = 25
.const COUNTER = $FB
.const FRAMECOUNTER = $FC

start:  lda #0
		sta COUNTER
		lda #FRAMES_PER_COLOR
		sta FRAMECOUNTER
nextframe:
wait0: 	lda RASTER_CNT
		bne wait0 // wait until raster counter rolls over to zero
wait1: 	lda RASTER_CNT
		beq wait1 // wait until raster counter is non-zero again

dec FRAMECOUNTER
bne nextframe

lda FRAMES_PER_COLOR
sta FRAMECOUNTER

loop: lda SCR_COLOR // load the current screen color byte into the accumulator
	  and #BORDER_RESET // set all the border color bits to 0
	  inc COUNTER // increase the color bit counter to get the next color
	  ora COUNTER // 
	  sta SCR_COLOR
	  and #%0000_0111
	  cmp #%111
	  bne nextframe
	  jmp start
