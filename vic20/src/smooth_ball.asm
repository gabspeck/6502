#import "basic_stub.asm"

.const SLOWDOWN=5

frameCounter: .byte SLOWDOWN
start:

	// clear screen
	lda #$93
	jsr $FFD2
	
	// move charset table pointer to $1C00
	lda $9005
	and #%1111_0000
	ora #%0000_1111
	sta $9005

	lda #0
	sta $1E00
	sta $9600

	loop:
		jsr WaitVBlank
		jsr BallFrame
		jmp loop


BallFrame: {
		dec frameCounter
		bne return

		lda #SLOWDOWN
		sta frameCounter

        ldx #7                  // rows 7‥0
!row:   lda ballGlyph,X         // ❶ fetch row
        lsr                     // ❷ shift right; bit0 → Carry, 0 → bit7
        bcc !noWrap+            // ❸ if bit0 was 0 we’re done
        ora #%1000_0000                // ❹ if bit0 was 1, set bit7
!noWrap:
        sta ballGlyph,X         // ❺ write row back
        dex
        bpl !row-
return:
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

*= $1C00
ballGlyph:
	.byte %00111100,%01111110,%11111111,%11111111,%11111111,%11111111,%01111110,%00111100