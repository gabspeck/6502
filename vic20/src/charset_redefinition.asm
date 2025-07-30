#import "kernal.inc.asm"
.const CLRSCR=$93

 *= $FB virtual 
 .zp {
 	srcPtr: .word 0
	dstPtr: .word 0
 }

*= $1001 "Basic Upstart"
BasicUpstart(start)    // 10 sys$1010

*= $1010 "Program"
start:
	// // increase screen width to 27 characters
	// lda $9002
	// and #%1000_0000
	// ora #%0001_1011
	// sta $9002

	// lda $9000
	// and #%1000_0000
	// ora #%0000_0111
	// sta $9000

	jsr CopyCharset

	lda $9005
	and #%1111_0000
	ora #%0000_1111
	sta $9005

	jmp *

CopyCharset: {

	// full charset uses 8 pages, but on unexpanded memory at this location only 2 fit
	ldx #2
	ldy #0
	lda #$00
	sta srcPtr
	lda #$80
	sta srcPtr+1
	lda #$00
	sta dstPtr
	lda #$1C
	sta dstPtr+1

	loop:
		lda (srcPtr),Y
		sta (dstPtr),Y
		iny
		bne loop
		inc srcPtr+1
		inc dstPtr+1
		dex
		bne loop
			
	rts
}

