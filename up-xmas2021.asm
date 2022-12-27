    org #1200

SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25

hblnk = 0xe008
vblnk = 0xe002

include "monitor.asm"

include "decrunch/dzx0_fast.asm"

macro wait_vbl                                  ; wait for vblank
    ld hl, vblnk
    ld a, 0x7f
@wait0:
    cp (hl)
    jp nc, @wait0
@wait1:
    cp (hl)
    jp c, @wait1
mend

;----------------------------------------------------------------------------------------------------------------------
main:                                           ; main entry point
    di
    im 1

    call fill_screen

PRESS_SPACE_OFFSET = 12*SCREEN_WIDTH + SCREEN_WIDTH/2 - 12
    ld hl, press_space                          ; display "press space" message.
    ld de, 0xd000+PRESS_SPACE_OFFSET
    ld bc, 24
    ldir
    
    ld hl, 0xd800+PRESS_SPACE_OFFSET
    ld (hl), 0xF2
    ld de, 0xd801+PRESS_SPACE_OFFSET
    ld bc, 23
    ldir

wait_key:                                       ; wait for space to be pressed.
    ld hl, 0xe000
    ld (hl), 0xf6 
    inc hl
    bit 4,(hl)
    jp nz, wait_key


    out (0xe0), a                               ; allocates RAM to $0000-$0fff
                                                ; the monitor will be unavailable and all the IRQ jump addresses
                                                ; are right in the area where the frame are unpacked...

    ; the unpacked frame is stored from 0x0000 to 0x07d0
    ; the copy to vram routine is stored from 0x0800 to 0x0e12

                                                ; setup vram copy routine to RAM
    ld hl, copy_line                            ; d000
    ld de, 0x840
    ld bc, copy_line.end - copy_line
    ldir

    ld ix, 0xd000+10
    ld iy, 0xd800+10
    ld (copy_line.begin+2), iy
    ld hl, copy_line.begin                      ; d800
    ld bc, copy_line.end - copy_line.begin
    ldir

    ld a, 24
.l1:
        ld bc, 40
        add ix, bc
        add iy, bc

        ld (copy_line.begin+2), ix
        ld hl, copy_line.begin                  ; d000
        ld bc, copy_line.end - copy_line.begin
        ldir

        ld (copy_line.begin+2), iy
        ld hl, copy_line.begin                  ; d800
        ld bc, copy_line.end - copy_line.begin
        ldir

        dec a
        jp nz, .l1

    ld hl, copy_line.end                        ; copy stack pointer backup and return
    ld bc, 4
    ldir
    
    ld hl, song
    xor a
    call PLY_LW_Init

    ld hl, irq_call
    ld de, 0x0038
    ld bc, 3
    ldir

    ld hl, 0xe007                               ;Counter 2.
    ld (hl), 0xb0
    dec hl
    ld (hl),1
    ld (hl),0

    ld hl, 0xe007                               ; 100 Hz (plays the music at 50hz).
    ld (hl), 0x74
    ld hl, 0xe005
    ld (hl), 156
    ld (hl), 0

    ld hl, 0xe008                               ; Sound on
    ld (hl), 0x01

    ei

start:
    ld hl, scroller
    call load_frame

@scroll.0:
    call big_scroll_init

@scroll.1:
    call big_scroll_update
    ld a, (scroll_chr_index+1)
    cp 0xff
    jp nz, @scroll.1
    
    ; ball
    ld hl, ball.lo
    ld (frame_update.lo), hl

    ld hl, ball.hi
    ld (frame_update.hi), hl
    
    ld hl, ball_12
    ld (frame_src), hl

    ld a, l
    ld (frame_reset.lo), a

    ld a, h
    ld (frame_reset.hi), a

    ld a, 11
    ld (anim.frame_count), a

    ld c, 16
    call anim_play

    ; scroller 2
    ld hl, scroll_txt.1
    ld (big_scroll_txt), hl
    
    ld hl, scroller
    call load_frame

@scroll.2:
    call big_scroll_init

@scroll.3:
    call big_scroll_update
    ld a, (scroll_chr_index+1)
    cp 0xff
    jp nz, @scroll.3

    ; santa
    ld hl, frame.lo
    ld (frame_update.lo), hl

    ld hl, frame.hi
    ld (frame_update.hi), hl
    
    ld hl, frame_6
    ld (frame_src), hl

    ld a, l
    ld (frame_reset.lo), a

    ld a, h
    ld (frame_reset.hi), a

    ld a, 5
    ld (anim.frame_count), a

    ld c, 24
    call anim_play

    ; tunnel
    ld hl, tunnel.lo
    ld (frame_update.lo), hl

    ld hl, tunnel.hi
    ld (frame_update.hi), hl
    
    ld hl, tunnel_12
    ld (frame_src), hl

    ld a, l
    ld (frame_reset.lo), a

    ld a, h
    ld (frame_reset.hi), a

    ld a, 11
    ld (anim.frame_count), a

    ld c, 20
    call anim_play

    call PLY_LW_Stop                            ; stop music

    ld hl, 0xe008                               ; Sound off
    ld (hl), 0x00

    di                                          ; deactivate interrupts
    call fill_screen

    ld hl, flip_tape
    ld de, 0xd000+(12*SCREEN_WIDTH + (SCREEN_WIDTH-36)/2)
    ld bc, 36
    ldir
    
    out (0xe2), a                               ; restore monitor
    ld sp, 0x10F0                               ; restore stack pointer

    ld de, 0x0e10
    ld (monitor_DSPXY), de

    jp monitor_LOAD

;----------------------------------------------------------------------------------------------------------------------
fill_screen:
    ld (@transition_sp_save), sp                ; save stack pointer (should be useless as we can deduce/hardcode it)
@fill_screen:                                   ; pull down a red curtain on screen
    ld iy, SCREEN_HEIGHT                        ; at each vbl will update the current line with a different character until the
    ld ix, 0xd000+SCREEN_WIDTH                  ; the line is "full". We'll then proceed to the next one until the screen is completly filled.

@fill_screen.loop
    ld bc, 0
    
@fill_line:
    wait_vbl

    ld sp, ix                                   ; we'll fill the line by pushing a char to the char vram.
    
    ld hl, histogram.attr                       ; A = histogram.attr[bc]
    add hl, bc
    ld a, (hl)
    ld h, a
    ld l, a

    repeat SCREEN_WIDTH/2                       ; we push 2 bytes each time
    push hl
    rend
        
    ld hl, 0x800+SCREEN_WIDTH                   ; do the same with color vram
    add hl, sp
    ld sp, hl
    
@fill_color equ $+1
    ld hl, histogram.color                      ; a = histogram.color[bc]
    add hl, bc
    ld a, (hl)
    ld h, a
    ld l, a

    repeat SCREEN_WIDTH/2
    push hl
    rend
   
    inc c                                       ; we'll repeat this until the char is full.
    ld a, 7
    cp c
    jp nz, @fill_line

    ld de,SCREEN_WIDTH                          ; jump to the next line
    add ix,de
    
    dec iyl
    jp nz, @fill_screen.loop                    ; we are done.
 
@transition_sp_save equ $+1                     ; restore stack pointer (may be useless and can be hardocded).
    ld sp, 0x0000
    ret

histogram.color:
    defb 0x21,0x21,0x21,0x12,0x12,0x12,0xf2
histogram.attr:
    defb 0x70,0x36,0x7a,0x7e,0x3e,0x3c,0x00

;----------------------------------------------------------------------------------------------------------------------
; copy a line from 0x0000-0xffff to VRAM (char or color)
copy_line:
    ld ix, 0x0040
copy_line.begin: 
    ld iy, 0xd000+10

    ld b, 4
l0:
    di
    ld sp, ix
    
    pop hl
    pop de
    exx
    pop hl
    pop bc
    pop de
    
    ld sp, iy
    push de
    push bc
    push hl
    exx
    push de
    push hl

    ld sp, 0x10ea
    ei

    ld de,  10
    add iy, de
    add ix, de
    
    djnz l0
copy_line.end:                                  ; we can hardcode stack return address
    ret

;----------------------------------------------------------------------------------------------------------------------
press_space:
    defb 0x82,0x83,0x84,0xb3,0xA0,0x00,0x10,0x12,0x05,0x13,0x13,0x00,0x00,0x13,0x10,0x01,0x03,0x05,0x00,0xA0,0xb3,0x84,0x83,0x82
flip_tape:
    defb 0x82,0x83,0x84,0xb3,0xA0,0x00,0x06,0x0c,0x09,0x10,0x00,0x14,0x01,0x10,0x05,0x00,0x01,0x0e,0x04,0x00,0x10,0x12,0x05,0x13,0x13,0x00,0x10,0x0c,0x01,0x19,0x00,0xA0,0xb3,0x84,0x83,0x82

;----------------------------------------------------------------------------------------------------------------------
repeat 12,cnt
ball_{cnt}:
    inczx0 "_data/anim/ball/Frame_{cnt}.bin"
rend

ball.lo:
repeat 12,cnt,12,-1
    defb lo(ball_{cnt})
rend

ball.hi:
repeat 12,cnt,12,-1
    defb hi(ball_{cnt})
rend

;----------------------------------------------------------------------------------------------------------------------
repeat 12,cnt
tunnel_{cnt}:
    inczx0 "_data/anim/tunnel/Frame_{cnt}.bin"
rend

tunnel.lo:
repeat 12,cnt,12,-1
    defb lo(tunnel_{cnt})
rend

tunnel.hi:
repeat 12,cnt,12,-1
    defb hi(tunnel_{cnt})
rend

;----------------------------------------------------------------------------------------------------------------------
repeat 6,cnt
frame_{cnt}:
    inczx0 "_data/anim/santa/Frame_{cnt}.bin"
rend

frame.lo:
repeat 6,cnt,6,-1
    defb lo(frame_{cnt})
rend

frame.hi:
repeat 6,cnt,6,-1
    defb hi(frame_{cnt})
rend

;----------------------------------------------------------------------------------------------------------------------
scroller:
    inczx0 "_data/anim/scroller/Frame_7.bin"


;----------------------------------------------------------------------------------------------------------------------
include "big_scroll.asm"

;----------------------------------------------------------------------------------------------------------------------
    org #c340

;----------------------------------------------------------------------------------------------------------------------
; ZX0 depacking
decrunch:
    DecompressZX0 (void)
    ret

;----------------------------------------------------------------------------------------------------------------------
anim_play:
anim.frame_count equ $+1
    ld b, 5
play.1:

    push bc

frame_src equ $+1
    ld hl, frame_6
    ld de, 0x0040

    call decrunch

frame_delay: equ $+1
    ld b, 3
@wait:
    wait_vbl
    djnz @wait

    call 0x840                                  ; copy frame to VRAM

    pop bc

    xor   a                                     ; fetch next compressed frame
    ld    d,a
    ld    e,b

frame_update.lo equ $+1
    ld    hl, frame.lo
    add   hl, de
    ld    a, (hl)
    ld    (frame_src), a

frame_update.hi equ $+1
    ld    hl, frame.hi
    add   hl, de
    ld    a, (hl)
    ld    (frame_src+1), a                      ; frame_src += frame[b]

    djnz  play.1

frame_reset.lo equ $+1                          ; reset source pointer
    ld    a, lo(frame_6)
    ld    (frame_src), a
frame_reset.hi equ $+1
    ld    a, hi(frame_6)
    ld    (frame_src+1), a

    dec   c
    jp    nz, anim_play

    ret

;----------------------------------------------------------------------------------------------------------------------
load_frame:                                     ; load a single frame
    push bc
    ld de, 0x0040
    call decrunch                               ; unpack frame
    wait_vbl                                    ; wait for vblnk
    call 0x840                                  ; copy frame to VRAM
    pop bc
    ret

;----------------------------------------------------------------------------------------------------------------------
irq_call:
    jp _irq_vector
_irq_vector:                                    ; timer irq vector.
    di

    push af                                     ; ... this makes santa sad...
    push hl
    push bc
    push de
    push ix
    push iy
    exx
    push af
    push hl
    push bc
    push de
    push ix
    push iy
    
    ld hl, 0xe006
    ld a,1
    ld (hl), a
    xor a
    ld (hl), a
    
    call PLY_LW_Play        
    
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af
    exx
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af

    ei

    reti

player: include "PlayerLightweight_SHARPMZ700.asm"

include "data/music_playerconfig.asm"
song: include "data/music.asm"
