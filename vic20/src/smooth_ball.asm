#import "basic_stub.asm"

// ---------------------------------------------------------
// Config (unexpanded defaults)
// ---------------------------------------------------------
.const SLOWDOWN   = 1
.const COLS       = 22          // 22-column default
.const BLANK_CHAR = 2           // our blank glyph

// Zero-page pointers (use built-in scratch)
.const ZP_SCR_LO  = $fb
.const ZP_SCR_HI  = $fc

// ---------------------------------------------------------
// State
// ---------------------------------------------------------
frameCounter: .byte SLOWDOWN
ballCol:      .byte 0
ballColPrev:  .byte 0
subpix:       .byte 0           // 0..7
rightCount:   .byte 0
tmp:          .byte 0

// ---------------------------------------------------------
// Program
// ---------------------------------------------------------
start:
    // clear screen
    lda #$93
    jsr $FFD2

    // charset -> RAM @ $1C00 (keep current screen base in high nibble)
    lda $9005
    and #$F0
    ora #$0F
    sta $9005

    // screen base pointer from OS ($0288), low byte = 0
    lda #$00
    sta ZP_SCR_LO
    lda $0288
    sta ZP_SCR_HI

    // make first row color BLACK (0) at $9600..$9615 (unexpanded)
    ldy #0
    lda #$00
!clrcol:
    sta $9600,y
    iny
    cpy #COLS
    bne !clrcol-

    // fill first row with our blank char
    ldy #0
    ldx #COLS
    lda #BLANK_CHAR
!clrrow:
    sta (ZP_SCR_LO),y
    iny
    dex
    bne !clrrow-

    // init ball
    lda #0
    sta ballCol
    sta ballColPrev
    sta subpix

    jsr RenderBallGlyphs

    // place initial two cells (col 0 / 1)
    ldy ballCol
    lda #0
    sta (ZP_SCR_LO),y
    iny
    lda #1
    sta (ZP_SCR_LO),y

// ---------------------------------------------------------
mainLoop:
    jsr WaitVBlank
    jsr BallFrame
    jsr BallFrame
    jsr BallFrame
    jsr BallFrame
    jmp mainLoop

// ---------------------------------------------------------
// Build two glyphs from base bitmap & current subpixel.
// left  = row >> subpix      -> char 0 ($1C00)
// right = row << (8-subpix)  -> char 1 ($1C08)
// ---------------------------------------------------------
RenderBallGlyphs: {
    lda #8
    sec
    sbc subpix
    sta rightCount

    ldx #7
!row:
    lda ballBase,x
    sta tmp

    // left part
    ldy subpix
    lda tmp
!sr:
    cpy #0
    beq !srDone+
    lsr
    dey
    bne !sr-
!srDone:
    sta glyphLeft,x

    // right part
    ldy rightCount
    lda tmp
!sl:
    cpy #0
    beq !slDone+
    asl
    dey
    bne !sl-
!slDone:
    sta glyphRight,x

    dex
    bpl !row-
    rts
}

// ---------------------------------------------------------
// Move 1 pixel each SLOWDOWN ticks.
// Shift glyphs every tick; when subpix wraps, shift cells.
// ---------------------------------------------------------
BallFrame: {
    // dec frameCounter
    // bne return

    // lda #SLOWDOWN
    // sta frameCounter

    // subpix = (subpix+1) & 7
    inc subpix
    lda subpix
    and #7
    sta subpix

    // always rebuild for smooth scroll
    jsr RenderBallGlyphs

    // if not wrapped, done
    lda subpix
    bne return

    // wrapped: advance column (0..COLS-1)
    lda ballCol
    sta ballColPrev
    clc
    adc #1
    cmp #COLS
    bcc !ok+
    lda #0
!ok:
    sta ballCol

    // clear previous two cells to blank
    ldy ballColPrev
    lda #BLANK_CHAR
    sta (ZP_SCR_LO),y
    cpy #(COLS-1)
    beq !skipPrevRight+
    iny
    sta (ZP_SCR_LO),y
!skipPrevRight:

    // draw new left/right halves
    ldy ballCol
    lda #0
    sta (ZP_SCR_LO),y
    cpy #(COLS-1)
    beq !skipNewRight+
    iny
    lda #1
    sta (ZP_SCR_LO),y
!skipNewRight:

return:
    rts
}

// ---------------------------------------------------------
// Wait for vertical blank
// ---------------------------------------------------------
WaitVBlank:{
vbBottom:
    lda $9004
    bpl vbBottom
vbTop:
    lda $9004
    bmi vbTop
    rts
}

// ---------------------------------------------------------
// Static data (outside char RAM)
// ---------------------------------------------------------
ballBase:
    .byte %00111100
    .byte %01111110
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %01111110
    .byte %00111100

// ---------------------------------------------------------
// Character RAM @ $1C00
// ---------------------------------------------------------
*= $1C00
glyphLeft:   .fill 8,0      // char 0
glyphRight:  .fill 8,0      // char 1
blankGlyph:  .fill 8,0      // char 2 (BLANK_CHAR)
