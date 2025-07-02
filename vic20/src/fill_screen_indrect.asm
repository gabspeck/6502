#import "basic_stub.asm"

.label CHROUT=$FFD2

.const CLRSCR=$93
.const COLOR_PTR=$00
.const POS_PTR=$02

start:

lda #CLRSCR
jsr CHROUT

/* lda/sta(addr),Y will read a **16-bit** pointer at addr, low byte first, so e.g.
$1E00 must be stored $00, $1E at addr and addr+1 respectively
it's a dynamic equivalent to X-indexed addressing i.e. 
sta $1E00,X
*/
ldy #$00 // address offset

lda #$00
sta COLOR_PTR
lda #$96
sta COLOR_PTR+1

lda #$00
sta POS_PTR
lda #$1E
sta POS_PTR+1

loop:
	jsr paint_player
	iny
	bne loop
	lda COLOR_PTR+1
	cmp #$97
	beq end
	inc COLOR_PTR+1
	inc POS_PTR+1
	jmp loop

end: jmp *

paint_player:

lda #$02
sta (COLOR_PTR),Y

lda #83
sta (POS_PTR),Y

rts

