#import "template.asm"
.label SCNKEY=$FF9F
.label GETIN=$FFE4
.label CHROUT=$FFD2
.label CHRSET=$9005
.label RASTER_CNT = $9004
.label SCREEN_RAM_START=$1E00
.label COLOR_RAM_START=$9600

.const RED=2
.const PLAYER=83
.const SPACE=32
.const CLRSCR=$93
.const SCREEN_RAM_OFFSET=$00E6
.const KEY_UP=$91
.const KEY_ENTER=13

//5. **Single Character Move** - Display a character that can be moved with keyboard input (WASD or cursor keys)
start:
	jsr clear_scr

	lda #RED
	sta COLOR_RAM_START+SCREEN_RAM_OFFSET

	lda #PLAYER
	sta SCREEN_RAM_START+SCREEN_RAM_OFFSET

getchr: jsr SCNKEY
		jsr GETIN
		cmp #KEY_UP
		beq moveup
		cmp #KEY_ENTER
		beq game_over
		jmp getchr

moveup:	lda #RED
		sta COLOR_RAM_START+SCREEN_RAM_OFFSET-22
		lda #PLAYER
		sta SCREEN_RAM_START+SCREEN_RAM_OFFSET-22
		jmp getchr

game_over: 	ldx #0

			jsr clear_scr

			loop_char: 	lda message,X
						cmp #0
						beq end
						jsr CHROUT

						inx
						jmp loop_char
clear_scr: 	lda #CLRSCR
			jsr CHROUT
			rts

message: 	.text "THANKS FOR PLAYING!"
			.byte 0
end:
	rts
