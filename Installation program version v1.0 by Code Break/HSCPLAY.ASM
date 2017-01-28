;---------------------------------------------------------------
; Data segment
;---------------------------------------------------------------
dseg            segment para use16 'data'
module          label   byte
                include tdujamm
dseg            ends

;---------------------------------------------------------------
; Code segment
;---------------------------------------------------------------
cseg            segment para use16 'code'
                assume  cs:cseg,ds:dseg,ss:nothing

                public  playmode
                public  stopfmm

hscplayer       equ     $
                include hscobj

;---------------------------------------------------------------
; Turn on HSC player.
;---------------------------------------------------------------
playmode        proc
                push    ax
                push    bx
                push    ds
                push    es
                push    si
                mov     ah,0
                mov     bl,0
                mov     bh,0
                push    dseg
                pop     ds
                push    ds
                pop     es
                mov     si,offset ds:module
                push    cs
                call    hscplayer
                pop     si
                pop     es
                pop     ds
                pop     bx
                pop     ax
                retf
playmode        endp

;---------------------------------------------------------------
; Turn off HSC player.
;---------------------------------------------------------------
stopfmm         proc
                push    ax
                mov     ah,2
                push    cs
                call    hscplayer
                pop     ax
                retf
stopfmm         endp

cseg            ends
                end
