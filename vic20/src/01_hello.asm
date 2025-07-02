#import "basic_stub.asm"

start:
	lda #$08 // H
	sta $1e00
	lda #$05 // E
	sta $1e01
	lda #$0C // L
	sta $1e02
	lda #$0C // L
	sta $1e03
	lda #$0F // O
	sta $1e04
	rts
