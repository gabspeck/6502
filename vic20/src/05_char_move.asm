#import "template.asm"
.label SCNKEY=$FF9F
.label GETIN=$FFE4
.label CHROUT=$FFD2
.label CLRSCR=$93
.label PLAYER=83
.label CHRSET=$9005
.label RASTER_CNT = $9004
.label RED=2

//5. **Single Character Move** - Display a character that can be moved with keyboard input (WASD or cursor keys)
start:
	lda #CLRSCR
	jsr CHROUT 

	lda #RED
	sta $96E6

	lda #PLAYER
	sta $1EE6

getchr: jsr SCNKEY
		jsr GETIN
		cmp #13
		bne getchr

jmp *

