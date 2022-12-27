anim_play           equ 0xc3fc
anim.frame_count    equ 0xc3fd
frame_src           equ 0xc400 
frame_delay         equ 0xc409 
frame_update.lo     equ 0xc421 
frame_update.hi     equ 0xc429 
frame_reset.lo      equ 0xc433 
frame_reset.hi      equ 0xc438 

    org #1200
main:
    di
    im 1

    ld hl, 0xe008                               ; Sound on
    ld (hl), 0x01

    out (0xe0), a                               ; allocates RAM to $0000-$0fff

    ei

    ; fishnet
    ld hl, uprough.lo
    ld (frame_update.lo), hl

    ld hl, uprough.hi
    ld (frame_update.hi), hl
    
    ld hl, uprough_24
    ld (frame_src), hl

    ld a, l
    ld (frame_reset.lo), a

    ld a, h
    ld (frame_reset.hi), a

    ld a, 23
    ld (anim.frame_count), a

    ld c, 8

    call anim_play

    ; ride
    ld hl, ride.lo
    ld (frame_update.lo), hl

    ld hl, ride.hi
    ld (frame_update.hi), hl
    
    ld hl, ride_24
    ld (frame_src), hl

    ld a, l
    ld (frame_reset.lo), a

    ld a, h
    ld (frame_reset.hi), a

    ld a, 23
    ld (anim.frame_count), a

    ld a, 4
    ld (frame_delay), a

    ld c, 8

    call anim_play

    ; end
    ld hl, end.lo
    ld (frame_update.lo), hl

    ld hl, end.hi
    ld (frame_update.hi), hl
    
    ld hl, end_12
    ld (frame_src), hl

    ld a, l
    ld (frame_reset.lo), a

    ld a, h
    ld (frame_reset.hi), a

    ld a, 11
    ld (anim.frame_count), a

    ld a, 5
    ld (frame_delay), a

loop:
    ld c, 20
    call anim_play
    jr loop


;----------------------------------------------------------------------------------------------------------------------
repeat 24,cnt
uprough_{cnt}:
    inczx0 "_data/anim/uprough/Frame_{cnt}.bin"
rend

uprough.lo:
repeat 24,cnt,24,-1
    defb lo(uprough_{cnt})
rend

uprough.hi:
repeat 24,cnt,24,-1
    defb hi(uprough_{cnt})
rend

;----------------------------------------------------------------------------------------------------------------------
repeat 24,cnt
ride_{cnt}:
    inczx0 "data/anim/ride/out_{cnt}.bin"
rend

ride.lo:
repeat 24,cnt,24,-1
    defb lo(ride_{cnt})
rend

ride.hi:
repeat 24,cnt,24,-1
    defb hi(ride_{cnt})
rend

;----------------------------------------------------------------------------------------------------------------------
repeat 12,cnt
end_{cnt}:
    inczx0 "_data/anim/end/Frame_{cnt}.bin"
rend

end.lo:
repeat 12,cnt,12,-1
    defb lo(end_{cnt})
rend

end.hi:
repeat 12,cnt,12,-1
    defb hi(end_{cnt})
rend

