#import "template.asm"

//2. **Fill Screen** - Fill the entire screen with a single character (like asterisks)
//Screen memory: 1E00-1FFF
//Color memory: 9600-97FF
start:
	ldx #$00 
	lda #$2A // *
charLoop:
	sta $1e00,x // absolute indexing
	sta $1f00,x // absolute indexing
	inx
	bne charLoop

	lda #$06 // blue
colorLoop:
	sta $9600,x
	sta $9700,x
	inx
	bne colorLoop

jmp * // hangs to avoid returning control to CBM BASIC
