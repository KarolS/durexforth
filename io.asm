;{{{ The MIT License
;
;Copyright (c) 2008 Johan Kotlinski
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE. }}}

; TYPE EMIT PAGE KEY? KEY REFILL SOURCE SOURCE-ID >IN GETC CHAR

    +BACKLINK "emit", 4
EMIT
    lda	LSB, x
    inx
    jmp	PUTCHR

    +BACKLINK "page", 4
PAGE
    lda #K_CLRSCR
    jmp PUTCHR

    +BACKLINK "rvs", 3
RVS ; ( -- ) invert text output
    lda #$12
    jmp CHROUT

    +BACKLINK "cr", 2
CR ; ( -- )
    lda #$d
    jmp CHROUT

    +BACKLINK "type", 4
TYPE ; ( caddr u -- )
    lda #0 ; quote mode off
    sta $d4
-   lda LSB,x
    ora MSB,x
    bne +
    inx
    inx
    rts
+   jsr OVER
    jsr FETCHBYTE
    jsr EMIT
    jsr ONE
    jsr SLASH_STRING
    jmp -

    +BACKLINK "key?", 4
    lda $c6 ; Number of characters in keyboard buffer
    beq +
.pushtrue
    lda #$ff
+   tay
    jmp pushya

    +BACKLINK "key", 3
-   lda $c6
    beq -
    stx W
    jsr $e5b4 ; Get character from keyboard buffer
    ldx W
    ldy #0
    jmp pushya

    +BACKLINK "refill", 6
REFILL

READ_EOF = * + 1
    lda #0
    beq .not_eof
    stx W
    lda	SOURCE_ID_LSB
    jsr	CLOSE
    jsr RESTORE_INPUT
    ldx SOURCE_ID_LSB
    beq +
    jsr CHKIN
    jmp ++
+   jsr CLRCHN
++  ldx W
    rts
.not_eof
    lda SOURCE_ID_MSB
    beq +
    jsr evaluate_consume_tib
    jmp evaluate_get_new_line
+
    ldy #0
    sty TO_IN_W
    sty TO_IN_W + 1
    sty TIB_SIZE
    sty TIB_SIZE + 1

    lda SOURCE_ID_LSB
    beq .getLineFromConsole
    lda SOURCE_ID_MSB
    beq	.getLineFromDisk

.getLineFromConsole
    stx W
    ldx #0
-   jsr $e112 ; Input Character
    cmp #$d
    beq .gotReturn
    sta TIB,x
    cpx #$58 ; Default TIB area is $200-$258
    beq -
    inx
    jmp -
.gotReturn
    jsr PUTCHR
    ; Set TIB_SIZE to number of chars fetched.
    stx TIB_SIZE
    ldx W
    rts

.getLineFromDisk
    lda TIB_PTR
    sta W
    lda TIB_PTR + 1
    sta W+1
-   stx W2
    jsr	CHRIN
    ldx W2
    pha
    jsr	READST
    sta READ_EOF
    pla
    ora #0
    beq -
    cmp #K_RETURN
    beq +
    inc $d020
    ldy TIB_SIZE
    sta (W),y
    inc TIB_SIZE
    dec $d020
    jmp -
+   rts

GET_CHAR_FROM_TIB
    lda TO_IN_W
    cmp TIB_SIZE
    bne +
    lda TO_IN_W + 1
    cmp TIB_SIZE + 1
    bne +
    lda #0
    rts
+
    clc
    lda TIB_PTR
    adc TO_IN_W
    sta W
    lda TIB_PTR + 1
    adc TO_IN_W + 1
    sta W + 1
    ldy #0
    lda (W),y

    inc TO_IN_W
    bne +
    inc TO_IN_W + 1
+   rts

    +BACKLINK "source", 6
SOURCE
    dex
    dex
    lda TIB_PTR
    sta LSB+1, x
    lda TIB_PTR + 1
    sta MSB+1, x
    lda TIB_SIZE
    sta LSB, x
    lda TIB_SIZE + 1
    sta MSB, x
    rts

TIB_PTR
    !word 0
TIB_SIZE
    !word 0

    +BACKLINK "source-id", 9
SOURCE_ID_LSB = * + 1
SOURCE_ID_MSB = * + 3
    ; -1 : string (via evaluate)
    ; 0 : keyboard
    ; 1+ : file id
    +VALUE	0

    +BACKLINK ">in", 3
TO_IN
    +VALUE TO_IN_W
TO_IN_W
    !word 0

    +BACKLINK "getc", 4
    jsr GET_CHAR_FROM_TIB
    bne +
    jsr REFILL
    lda #K_RETURN
+   ldy #0
    jmp pushya

    +BACKLINK "char", 4
CHAR ; ( name -- char )
-   jsr PARSE_NAME
    lda LSB,x
    bne +
    inx
    inx
    jsr REFILL
    jmp -
+   inx
    jmp FETCHBYTE

SAVE_INPUT_STACK
    !fill 9*5
SAVE_INPUT_STACK_DEPTH
    !byte 0

push_input_stack
    ; ! there is no check for stack overflow!
    ; 5 is however enough for one EVALUATE and four DOS channels.
    ; opening more than four channels gives "no channel" error on C64.
    ldy SAVE_INPUT_STACK_DEPTH
    sta SAVE_INPUT_STACK, y
    inc SAVE_INPUT_STACK_DEPTH
    rts

pop_input_stack
    dec SAVE_INPUT_STACK_DEPTH
    ldy SAVE_INPUT_STACK_DEPTH
    lda SAVE_INPUT_STACK, y
    rts

SAVE_INPUT
    lda READ_EOF
    jsr push_input_stack
    lda #0
    sta READ_EOF
    lda TO_IN_W
    jsr push_input_stack
    lda TO_IN_W+1
    jsr push_input_stack
    lda SOURCE_ID_LSB
    jsr push_input_stack
    lda SOURCE_ID_MSB
    jsr push_input_stack
    lda TIB_PTR
    jsr push_input_stack
    lda TIB_PTR+1
    jsr push_input_stack
    lda TIB_SIZE
    jsr push_input_stack
    lda TIB_SIZE+1
    jmp push_input_stack

RESTORE_INPUT
    jsr pop_input_stack
    sta TIB_SIZE+1
    jsr pop_input_stack
    sta TIB_SIZE
    jsr pop_input_stack
    sta TIB_PTR+1
    jsr pop_input_stack
    sta TIB_PTR
    jsr pop_input_stack
    sta SOURCE_ID_MSB
    jsr pop_input_stack
    sta SOURCE_ID_LSB
    jsr pop_input_stack
    sta TO_IN_W+1
    jsr pop_input_stack
    sta TO_IN_W
    jsr pop_input_stack
    sta READ_EOF
    rts

; handle errors returned by open,
; close, and chkin. If ioresult is
; nonzero, print error message and
; abort.
    +BACKLINK "ioabort", 7
IOABORT ; ( ioresult -- )
    inx
    lda MSB-1,x
    bne .print_ioerr
    lda LSB-1,x
    bne +
    rts
+   cmp #10
    bcc .print_basic_error

.print_ioerr
    lda #<.ioerr
    sta W
    lda #>.ioerr
    sta W+1
    jmp .print_msb_terminated_string

.ioerr
    !text "ioer"
    !byte 'r'|$80

.print_basic_error
    lda #$37
    sta 1

    lda LSB-1,x
    asl
    tax
    lda $a326,x
    sta W
    lda $a327,x
    sta W+1

.print_msb_terminated_string
    jsr CLRCHN
    jsr RVS

    ldy #0
-   lda (W),y
    pha
    and #$7f
    jsr CHROUT
    iny
    pla
    bpl -

.cr_abort
    jsr CR
    jmp ABORT
