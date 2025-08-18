// VIC-20 Breakout (unexpanded) — KickAssembler syntax
// Keys: Z = left, X = right, R = restart
// Loads with BASIC autostart at $1001. No RAM expansion required.

* = $1001
BasicUpstart2(start)

// ------------------------------------------------------------
// Constants / hardware
// ------------------------------------------------------------
.const VIC_BASE    = $9000
.const SCR_BASE    = $1E00          // 22x23 character screen
.const COL_BASE    = $9600
.const CHR_RAM     = $1C00          // 2 KB character set in RAM
.const CHR_ROM     = $8000          // character ROM (CPU-readable on VIC-20)
.const ROWS        = 23
.const COLS        = 22

.const REG_MEMPTR  = VIC_BASE+$05    // screen/charset pointer (hi/lo nibble)

// PETSCII / tiles
.const TILE_SPACE  = $20
.const TILE_BRICK  = $60
.const TILE_WALL   = $61
.const TILE_PADDLE = $62
.const TILE_BALL   = $63

// Colors 0..15
.const COL_BG      = 0   // black
.const COL_TEXT    = 1   // white
.const COL_BRICK   = 7   // yellow
.const COL_WALL    = 6   // blue
.const COL_PADDLE  = 1   // white
.const COL_BALL    = 2   // red

// Gameplay tuning
.const PADDLE_W    = 5
.const PADDLE_Y    = ROWS-1
.const BALL_SPEED  = 2               // frames per ball step
.const LEVEL_ROWS  = 5               // brick rows
.const LEVEL_TOP   = 3               // first brick row (0=top line)

// KERNAL
.const CHROUT      = $FFD2
.const GETIN       = $FFE4

// TI$ jiffy clock (low byte)
.const TI_LO       = $A0

// ------------------------------------------------------------
// Zero page pointers (must be ZP for (zp),X addressing!)
// ------------------------------------------------------------
* = $00F3
srcPtrLo:  .byte 0
srcPtrHi:  .byte 0
dstPtrLo:  .byte 0
dstPtrHi:  .byte 0
scrPtrLo:  .byte 0
scrPtrHi:  .byte 0
colPtrLo:  .byte 0
colPtrHi:  .byte 0

// ------------------------------------------------------------
// Variables (regular RAM)
// ------------------------------------------------------------
* = *
ballX:          .byte 11
ballY:          .byte 12
ballDX:         .byte 1     // +1 or $FF (-1)
ballDY:         .byte $FF
ballTick:       .byte BALL_SPEED
prevBallX:      .byte 11
prevBallY:      .byte 12
underChar:      .byte TILE_SPACE
underColor:     .byte COL_TEXT

paddleX:        .byte (COLS/2 - PADDLE_W/2)
oldPaddleX:     .byte 0

lives:          .byte 3
scoreLo:        .byte 0
scoreHi:        .byte 0

brickCountLo:   .byte 0
brickCountHi:   .byte 0

// ------------------------------------------------------------
// Row offset tables (screen & color)
// ------------------------------------------------------------
rowLo:
.fill ROWS, <(SCR_BASE + i*COLS)
rowHi:
.fill ROWS, >(SCR_BASE + i*COLS)

crowLo:
.fill ROWS, <(COL_BASE + i*COLS)
crowHi:
.fill ROWS, >(COL_BASE + i*COLS)

// ------------------------------------------------------------
// Code start
// ------------------------------------------------------------
start:
    jsr InitScreen
    jsr InitCharset
    jsr ResetGame
MainLoop:
    jsr WaitFrame
    jsr HandleInput
    jsr UpdateBall
    jmp MainLoop

// ------------------------------------------------------------
// Initialization
// ------------------------------------------------------------
InitScreen:
    lda #$93               // clear screen via CHROUT
    jsr CHROUT
    lda #COL_BG            // background color
    sta $900F
    rts

InitCharset:
    // Point VIC to $1C00 character RAM (lower nibble = $1C00/512 = 14)
    lda REG_MEMPTR
    and #%11110000
    ora #%00001110
    sta REG_MEMPTR

    // Copy 2KB character ROM $8000->$1C00 using (zp),Y pointers
    lda #<CHR_ROM
    sta srcPtrLo
    lda #>CHR_ROM
    sta srcPtrHi

    lda #<CHR_RAM
    sta dstPtrLo
    lda #>CHR_RAM
    sta dstPtrHi

    ldx #8                 // 8 pages * 256 = 2048 bytes
@page:
    ldy #0
@cpy:
    lda (srcPtrLo),y
    sta (dstPtrLo),y
    iny
    bne @cpy
    inc srcPtrHi
    inc dstPtrHi
    dex
    bne @page

    // Overwrite custom tiles
    ldx #0
@brk:
    lda BrickGlyph,x
    sta CHR_RAM + TILE_BRICK*8, x
    inx
    cpx #8
    bne @brk

    ldx #0
@wal:
    lda WallGlyph,x
    sta CHR_RAM + TILE_WALL*8, x
    inx
    cpx #8
    bne @wal

    ldx #0
@pad:
    lda PaddleGlyph,x
    sta CHR_RAM + TILE_PADDLE*8, x
    inx
    cpx #8
    bne @pad

    ldx #0
@bal:
    lda BallGlyph,x
    sta CHR_RAM + TILE_BALL*8, x
    inx
    cpx #8
    bne @bal

    rts

// Reset level/board and draw everything
ResetGame:
    // reset score/lives/ball/paddle
    lda #0
    sta scoreLo
    sta scoreHi
    lda #3
    sta lives

    lda #(COLS/2 - PADDLE_W/2)
    sta paddleX
    sta oldPaddleX

    lda #11
    sta ballX
    lda #12
    sta ballY
    lda #1
    sta ballDX
    lda #$FF
    sta ballDY
    lda #BALL_SPEED
    sta ballTick

    // zero brick counter
    lda #0
    sta brickCountLo
    sta brickCountHi

    // clear playfield rows 0..ROWS-1
    ldy #0
@clr:
    jsr DrawClearRow
    iny
    cpy #ROWS
    bne @clr

    jsr DrawHud
    jsr DrawWalls
    jsr DrawBricks
    jsr DrawPaddle
    jsr DrawBall_FirstTime
    rts

// DrawClearRow: Y=row index; clears row to spaces with text color
DrawClearRow:
    // compute ptrs
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi

    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    ldx #0
@loop:
    lda #TILE_SPACE
    sta (scrPtrLo),x
    lda #COL_TEXT
    sta (colPtrLo),x
    inx
    cpx #COLS
    bne @loop
    rts

DrawHud:
    // top row text: SCORE and LIVES
    ldy #0
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    ldx #0
@hudtxt:
    lda HudStr,x
    beq @done
    sta (scrPtrLo),x
    lda #COL_TEXT
    sta (colPtrLo),x
    inx
    bne @hudtxt
@done:
    jsr UpdateHudScore
    jsr UpdateHudLives
    rts

// Draw side walls (x=0 and x=COLS-1) and top wall at row=1 under HUD
DrawWalls:
    // left & right walls for rows 1..ROWS-1
    ldy #1
@rloop:
    // set row pointers
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    // left at x=0
    ldx #0
    lda #TILE_WALL
    sta (scrPtrLo),x
    lda #COL_WALL
    sta (colPtrLo),x

    // right at x=COLS-1
    ldx #COLS-1
    lda #TILE_WALL
    sta (scrPtrLo),x
    lda #COL_WALL
    sta (colPtrLo),x

    iny
    cpy #ROWS
    bne @rloop

    // top inner wall at row=1 across columns 1..COLS-2
    ldy #1
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    ldx #1
@top:
    lda #TILE_WALL
    sta (scrPtrLo),x
    lda #COL_WALL
    sta (colPtrLo),x
    inx
    cpx #COLS-1
    bne @top

    rts

DrawBricks:
    // bricks in LEVEL_ROWS rows starting at LEVEL_TOP, across columns 1..COLS-2
    ldy #LEVEL_TOP
@row:
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    ldx #1
@col:
    lda #TILE_BRICK
    sta (scrPtrLo),x
    lda #COL_BRICK
    sta (colPtrLo),x

    // brickCount++
    inc brickCountLo
    bne @nohi
    inc brickCountHi
@nohi:

    inx
    cpx #COLS-1
    bne @col

    iny
    cpy #(LEVEL_TOP+LEVEL_ROWS)
    bne @row

    rts

DrawPaddle:
    // erase old if moved
    lda oldPaddleX
    cmp paddleX
    beq @draw
    tax
    jsr ErasePaddleAtX
@draw:
    lda paddleX
    sta oldPaddleX
    tax
    jsr DrawPaddleAtX
    rts

ErasePaddleAtX:
    // X = left column
    ldy #PADDLE_Y
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    ldy #0
@loop1:
    lda #TILE_SPACE
    sta (scrPtrLo),x
    lda #COL_TEXT
    sta (colPtrLo),x
    inx
    iny
    cpy #PADDLE_W
    bne @loop1
    rts

DrawPaddleAtX:
    // X = left column
    ldy #PADDLE_Y
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    ldy #0
@loop2:
    lda #TILE_PADDLE
    sta (scrPtrLo),x
    lda #COL_PADDLE
    sta (colPtrLo),x
    inx
    iny
    cpy #PADDLE_W
    bne @loop2
    rts

DrawBall_FirstTime:
    lda ballX
    sta prevBallX
    lda ballY
    sta prevBallY
    lda #TILE_SPACE
    sta underChar
    lda #COL_TEXT
    sta underColor
    jsr DrawBallHere
    rts

DrawBallHere:
    // draw ball at (ballX,ballY)
    ldy ballY
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    ldx ballX
    lda #TILE_BALL
    sta (scrPtrLo),x
    lda #COL_BALL
    sta (colPtrLo),x
    rts

ErasePreviousBall:
    // restore underChar/color at (prevBallX,prevBallY)
    ldy prevBallY
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    ldx prevBallX
    lda underChar
    sta (scrPtrLo),x
    lda underColor
    sta (colPtrLo),x
    rts

// ------------------------------------------------------------
// Input & timing
// ------------------------------------------------------------
WaitFrame:
    lda TI_LO
@w: cmp TI_LO
    beq @w
    rts

HandleInput:
    jsr GETIN
    beq @done1
    cmp #'Z'
    beq @left
    cmp #'z'
    beq @left
    cmp #'X'
    beq @right
    cmp #'x'
    beq @right
    cmp #'R'
    beq @restart
    cmp #'r'
    beq @restart
    bne @done1
@left:
    lda paddleX
    cmp #1
    beq @done1
    dec paddleX
    jsr DrawPaddle
    jmp @done1
@right:
    lda paddleX
    cmp #(COLS-1-PADDLE_W)
    bcs @done1
    inc paddleX
    jsr DrawPaddle
    jmp @done1
@restart:
    jsr ResetGame
@done1:
    rts

// ------------------------------------------------------------
// Ball update & collisions
// ------------------------------------------------------------
UpdateBall:
    // pace the ball
    dec ballTick
    bne @done1
    lda #BALL_SPEED
    sta ballTick

    // erase previous ball
    jsr ErasePreviousBall

    // compute tentative next position newX,newY
    lda ballX
    clc
    adc ballDX
    sta newX

    lda ballY
    clc
    adc ballDY
    sta newY

    // check wall collisions (left/right)
    lda newX
    cmp #1
    bcs @chkRight
    jsr NegDX
    lda ballX
    clc
    adc ballDX
    sta newX
    jmp @chkTop
@chkRight:
    cmp #(COLS-1)
    bcc @chkTop
    jsr NegDX
    lda ballX
    clc
    adc ballDX
    sta newX

@chkTop:
    // top wall under HUD is at row 1
    lda newY
    cmp #1
    bcs @chkBricks
    jsr NegDY
    lda ballY
    clc
    adc ballDY
    sta newY

@chkBricks:
    // if next cell is a brick, remove and bounce Y
    ldx newX
    ldy newY
    jsr ReadCharXY      // A=char
    cmp #TILE_BRICK
    bne @chkPaddle
    // erase brick
    lda #TILE_SPACE
    jsr WriteCharXY_A
    lda #COL_TEXT
    jsr WriteColorXY_A
    // score++
    inc scoreLo
    bne @noscorehi
    inc scoreHi
@noscorehi:
    jsr UpdateHudScore
    // brickCount--
    lda brickCountLo
    bne @decLo
    dec brickCountHi
@decLo:
    dec brickCountLo
    // bounce
    jsr NegDY
    lda ballY
    clc
    adc ballDY
    sta newY

@chkPaddle:
    // if moving up, skip paddle check
    lda ballDY
    cmp #$FF
    beq @apply
    // moving down (+1)
    lda newY
    cmp #PADDLE_Y
    bne @apply
    // check X overlap
    lda newX
    sec
    sbc paddleX
    cmp #PADDLE_W
    bcs @miss
    // hit: bounce up, set DX based on hit side
    jsr NegDY
    // decide DX
    lda newX
    sec
    sbc paddleX
    cmp #(PADDLE_W/2)
    bcc @setLeft
    lda #1
    sta ballDX
    bne @apply
@setLeft:
    lda #$FF
    sta ballDX
    // fall through to apply

@miss:
@apply:
    // read what's under target cell -> save for erase later
    ldx newX
    ldy newY
    jsr ReadCharXY
    sta underChar
    // choose underColor
    cmp #TILE_WALL
    bne @notwall
    lda #COL_WALL
    bne @stcol
@notwall:
    cmp #TILE_BRICK
    bne @notbrick
    lda #COL_BRICK
    bne @stcol
@notbrick:
    lda #COL_TEXT
@stcol:
    sta underColor

    // draw ball at new pos
    lda newX
    sta prevBallX
    sta ballX
    lda newY
    sta prevBallY
    sta ballY
    jsr DrawBallHere

    // check death (ball below bottom)
    lda ballY
    cmp #ROWS
    bcc @maybeLevel
    jsr LoseLife

@maybeLevel:
    lda brickCountLo
    ora brickCountHi
    bne @end
    jsr NextLevel
@end:
    rts

@skipMove:
    rts

// Lose one life and reset ball/paddle
LoseLife:
    lda lives
    beq GameOver
    dec lives
    jsr UpdateHudLives
    // reset ball in center above paddle
    lda #(COLS/2)
    sta ballX
    lda #(PADDLE_Y-1)
    sta ballY
    lda #1
    sta ballDX
    lda #$FF
    sta ballDY
    lda #BALL_SPEED
    sta ballTick
    lda #TILE_SPACE
    sta underChar
    lda #COL_TEXT
    sta underColor
    jsr DrawBallHere
    rts

GameOver:
    jsr DrawGameOver
@wait:
    jsr GETIN
    beq @wait
    jsr ResetGame
    rts

NextLevel:
    // simple: rebuild bricks and speed up slightly
    jsr DrawBricks
    lda ballTick
    cmp #1
    beq @done2
    dec ballTick
@done2:
    rts

// ------------------------------------------------------------
// HUD helpers
// ------------------------------------------------------------
UpdateHudScore:
    // write score as 4 hex digits at HUD positions (after "SCORE:")
    // positions: column 7..10 on row 0
    ldy #0
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    // scoreHi, scoreLo
    lda scoreHi
    ldx #7
    jsr WriteHexNibblePair
    lda scoreLo
    ldx #9
    jsr WriteHexNibblePair
    rts

// A=byte, X=start column
WriteHexNibblePair:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr NibToChar
    sta (scrPtrLo),x
    lda #COL_TEXT
    sta (colPtrLo),x
    inx
    pla
    and #$0F
    jsr NibToChar
    sta (scrPtrLo),x
    lda #COL_TEXT
    sta (colPtrLo),x
    rts

NibToChar:
    // A = 0..15 => '0'..'9','A'..'F'
    cmp #10
    bcc @digit
    clc
    adc #$37   // +55 to go from 10->'A'
    rts
@digit:
    clc
    adc #$30   // +48
    rts

UpdateHudLives:
    // write lives at end of HUD string (column after "LIVES:")
    ldy #0
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    lda lives
    clc
    adc #$30
    ldx #HudLivesCol
    sta (scrPtrLo),x
    lda #COL_TEXT
    sta (colPtrLo),x
    rts

DrawGameOver:
    // center a short message on middle row
    ldy #(ROWS/2)
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi

    ldx #0
@g:
    lda GameOverStr,x
    beq @done3
    sta (scrPtrLo),x
    lda #COL_TEXT
    sta (colPtrLo),x
    inx
    cpx #COLS
    bcc @g
@done3:
    rts

// ------------------------------------------------------------
// Low-level helpers
// ------------------------------------------------------------
NegDX:
    lda ballDX
    eor #$FF
    clc
    adc #1
    sta ballDX
    rts
NegDY:
    lda ballDY
    eor #$FF
    clc
    adc #1
    sta ballDY
    rts

// Read char at (X=newX, Y=newY) -> A
ReadCharXY:
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    lda (scrPtrLo),x
    rts

// Write char/color at (X,Y)
WriteCharXY_A:
    pha
    lda rowLo,y
    sta scrPtrLo
    lda rowHi,y
    sta scrPtrHi
    pla
    sta (scrPtrLo),x
    rts

WriteColorXY_A:
    pha
    lda crowLo,y
    sta colPtrLo
    lda crowHi,y
    sta colPtrHi
    pla
    sta (colPtrLo),x
    rts

// ------------------------------------------------------------
// Scratch
// ------------------------------------------------------------
newX:      .byte 0
newY:      .byte 0

// ------------------------------------------------------------
// Data
// ------------------------------------------------------------
HudStr:
    .text "SCORE: 0000   LIVES: "
HudLivesCol:
    .byte 21

GameOverStr:
    .text " GAME OVER  R=Restart "
    .byte 0

// 8x8 glyphs (low bit = leftmost pixel)
BrickGlyph:
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111

WallGlyph:
    .byte %00011000
    .byte %00011000
    .byte %00011000
    .byte %00011000
    .byte %00011000
    .byte %00011000
    .byte %00011000
    .byte %00011000

PaddleGlyph:
    .byte %00000000
    .byte %00000000
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %00000000
    .byte %00000000
    .byte %00000000

BallGlyph:
    .byte %00000000
    .byte %00011000
    .byte %00111100
    .byte %00111100
    .byte %00111100
    .byte %00011000
    .byte %00000000
    .byte %00000000

// ------------------------------------------------------------
// End
// ------------------------------------------------------------