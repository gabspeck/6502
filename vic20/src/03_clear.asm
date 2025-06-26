#import "template.asm"

// 3. **Clear Screen** - Clear the screen by filling it with spaces

//Screen memory: 1E00-1FFF
//Color memory: 9600-97FF
start:
	ldx #$00 
	lda #$20 // " "
charLoop:
	sta $1e00,x // absolute indexing
	sta $1f00,x // absolute indexing
	inx
	bne charLoop

jmp * // hangs to avoid returning control to CBM BASIC

