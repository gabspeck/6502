#import "template.asm"
.label SCNKEY=$FF9F
.label GETIN=$FFE4
.label CHROUT=$FFD2
.label CHRSET=$9005
.label RASTER_CNT = $9004
.label SCREEN_BORDER_COLORS=$900F
.label SCREEN_RAM_START=$1E00
.label COLOR_RAM_START=$9600
.label PLAYER_LO=$01
.label POS_HI=$02
.label COLOR_HI=$03

.const BLACK=0
.const RED=2
.const WHITE_BG_BLK_BRD=%0001_1000
.const ROW_LENGTH=22
.const PLAYER=83
.const SPACE=32
.const CLRSCR=$93
.const KEY_UP=$91
.const KEY_ENTER=13

//5. **Single Character Move** - Display a character that can be moved with keyboard input (WASD or cursor keys)
start:
	jsr clear_scr

	lda #WHITE_BG_BLK_BRD
	sta SCREEN_BORDER_COLORS

	lda $E6
	sta PLAYER_LO

	lda $1E 
	sta POS_HI

	lda $96
	sta COLOR_HI

	ldy COLOR_HI
	lda #RED
	sta (PLAYER_LO),Y

	ldy POS_HI
	lda #PLAYER
	sta (PLAYER_LO),Y


getchr: jsr SCNKEY
		jsr GETIN
		// cmp #KEY_UP
		// beq moveup
		cmp #KEY_ENTER
		beq game_over
		jmp getchr

// moveup:	ldx pos_offset
// 		lda #SPACE
//         sta SCREEN_RAM_START,X
// 		txa 
//         sec
// 		sbc #ROW_LENGTH
// 		tax
// 		stx pos_offset
// 		jsr paint_player
// 		jmp getchr

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