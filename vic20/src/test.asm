#import "kernal.inc.asm"

*= $1001 "Basic Upstart"
BasicUpstart(start)    // 10 sys$1010

*= $1010 "Program"

start:
	lda #$93
	jsr CHROUT

	ldx #02
	lda #2
	sta $1E00
	stx $9600
	jsr WaitVBlank
	lda #2
	sta $1E01
	stx $9601
	jmp *

WaitVBlank:{
vbBottom:
        lda $9004
        bpl vbBottom         // wait bottom half
vbTop:
        lda $9004
        bmi vbTop            // wait top half
	rts
}
