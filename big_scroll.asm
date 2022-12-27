big_scroll_init:
    ld hl, scroll_buffer
    ld (hl), 0x00
    ld de, scroll_buffer+1
    ld bc, (SCREEN_WIDTH+1)*8-1
    ldir

    ld a, 0x43
    ld (scroll_char), a

    ld a, 0x3d
    ld (scroll_char+0x01), a 
    ld (scroll_char+0xfe), a

    ld a, 0x3f
    ld (scroll_char+0x03), a
    ld (scroll_char+0xfc), a

    ld a, 0x7f
    ld (scroll_char+0x07), a
    ld (scroll_char+0xf8), a
    
    ld a, 0x3b
    ld (scroll_char+0x0f), a
    ld (scroll_char+0xf0), a
    
    ld a, 0x7b
    ld (scroll_char+0x1f), a                ; :/
    ld (scroll_char+0xe0), a                ; :/

    ld a, 0x37
    ld (scroll_char+0x3f), a
    ld (scroll_char+0xc0), a

    ld a, 0x71
    ld (scroll_char+0x7f), a
    ld (scroll_char+0x80), a

    ld a, 0x43
    ld (scroll_char+0xff), a

    ld a, 0x70
    ld (scroll_attr+0x03), a
    ld (scroll_attr+0x07), a
    ld (scroll_attr+0x0f), a
    ld (scroll_attr+0x80), a
    ld (scroll_attr+0xc0), a
    ld (scroll_attr+0xe0), a
    ld (scroll_attr+0xff), a

    ld a, 0x07
    ld (scroll_attr+0x01), a
    ld (scroll_attr+0x1f), a
    ld (scroll_attr+0x3f), a
    ld (scroll_attr+0x7f), a
    ld (scroll_attr+0xf0), a
    ld (scroll_attr+0xf8), a
    ld (scroll_attr+0xfc), a
    ld (scroll_attr+0xfe), a

big_scroll_reset:
    ld a, 3
    ld (scroll_x), a

    ld a, 0xff
    ld (scroll_chr_index  ), a
    ld (scroll_chr_index+1), a

    ld a, 7
    ld (scroll_chr_px), a

    ret

big_scroll_update:
    ld hl, scroll_x
    inc (hl)
    ld a, (hl)
    cp 4
    jp nz, .l0
        xor a
        ld (hl), a

        ld hl, scroll_chr_px
        inc (hl)
        ld a, (hl)
        cp 8
        jp nz, .l1
            xor a
            ld (hl), a

            ld bc, (scroll_chr_index)
            inc bc
big_scroll_txt equ $+1
            ld hl, scroll_txt.0
            add hl, bc
            ld a, (hl)
            or a
            jp nz, .l2
                ld bc, 0xffff
                ld a, 0x20
.l2:
            ld (scroll_chr_index), bc

            ld b, 0x00
            add a,a
            rl b
            add a,a
            rl b
            add a,a
            rl b
            ld c, a
            ld hl, font_8x8
            add hl, bc

            ld de, scroll_bitmap
repeat 8, j
            ldi
rend
.l1:

        ld hl, scroll_bitmap
repeat 8, j
        xor a
        sla (hl)
        sbc a, a
        ld (scroll_buffer + (j-1)*(SCREEN_WIDTH+1) + SCREEN_WIDTH), a
        inc hl
rend
.l0:

    ld b, hi(scroll_char)
    ld d, hi(scroll_attr)


repeat 8, j
       ld hl, scroll_buffer + (j-1)*(SCREEN_WIDTH+1) + SCREEN_WIDTH                     ;  repeat 2 ?
       sla (hl)
       dec l
repeat SCREEN_WIDTH, i
            rl (hl)
if ( (j-1)*(SCREEN_WIDTH+1) + SCREEN_WIDTH - i ) == 256
            dec h
endif
            dec l
rend

        ld hl, scroll_buffer + (j-1)*(SCREEN_WIDTH+1) + SCREEN_WIDTH                    ; this will move the line 2 px :<
        sla (hl)
        dec l
repeat SCREEN_WIDTH, i
            rl (hl)
if ( (j-1)*(SCREEN_WIDTH+1) + SCREEN_WIDTH - i ) == 256
            dec h
endif
            dec l
rend
rend

    wait_vbl

repeat 8, j
        ld hl, scroll_buffer+(j-1)*(SCREEN_WIDTH+1) + SCREEN_WIDTH
repeat SCREEN_WIDTH, i
        dec hl
        ld c, (hl)
        ld e, c
        ld a,(bc)
        ld (0xd000+(SCREEN_WIDTH-i)+(17+j-1)*SCREEN_WIDTH), a
        ld a,(de)
        ld (0xd800+(SCREEN_WIDTH-i)+(17+j-1)*SCREEN_WIDTH), a
rend

rend
    
    ret

font_8x8:
    incbin "data/font.bin"

;align 256

scroll_char equ 0x0100;: defs 256                       ; move it 0x0000
scroll_attr equ 0x0200;: defs 256

scroll_buffer equ: 0x300; : defs (SCREEN_WIDTH+1)*8

scroll_bitmap: defs 8

scroll_x: defb 0
scroll_chr_index: defw 0
scroll_chr_px: defb 0

scroll_txt.0: 
    defb "Ho!Ho!Ho! MERRY CHRISTMAS to you all! Special greetings to the MZ Scene and all our friends! ", 0x00
scroll_txt.1: 
    defb "Check out who we have with us here - who has found the Xmas trips a bit early this year ?.The Man, The Myth, The Legend    ", 0x00