filesize        equ     24000
intnum          equ         h
startofs        equ     100h

cseg            segment
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
                org     0
firstbyte       equ     $
		org	100h

trainer         proc    far

start:
                jmp     begin

redirect1       db      0
oldint21        dd      0
savesp          dw      0
savess          dw      0
savetempsp      dw      0
code            db      filesize dup(90h)

trainer         endp

;---------------------------------------------------------------
; Redirect interrupt 21h.
;---------------------------------------------------------------

redirect21      proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,84h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint21
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint21+2
                push    offset cs:newint21
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
redirect21      endp

;---------------------------------------------------------------
; Redirect interrupt 21h back to original.
;---------------------------------------------------------------

unredirect21    proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,84h
                push    word ptr cs:oldint21
                pop     word ptr es:[bx]
                push    word ptr cs:oldint21+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect21    endp

;---------------------------------------------------------------
; New interrupt 21h. Use to intercept keyboard redirection.
;---------------------------------------------------------------

newint21        proc    near
                cmp     ax,intnum
                je      intercept1
                jmp     exitnewint21
intercept1:
                cmp     byte ptr cs:redirect1,1
                je      exitnewint21
                push    bp
                push    ds
                push    es
                push    si
                push    di
                push    cx
                mov     bp,sp
                mov     si,startofs
                mov     cx,[bp+8]
                mov     ds,cx
                push    cs
                pop     es
                mov     di,offset cs:code
                mov     cx,filesize
                rep     movsb
                pop     cx
                pop     di
                pop     si
                pop     es
                pop     ds
                pop     bp
                push    ax
                push    bx
                push    cx
                push    dx
                push    ds
                push    cs
                pop     ds
                mov     dx,offset datafile
                mov     cx,0
                mov     ah,3ch
                int     21h
                push    ax
                mov     bx,ax
                push    cs
                pop     ds
                mov     dx,offset code
                mov     cx,filesize
                push    cx
                mov     ah,40h
                int     21h
                pop     cx
                pop     ax
                mov     bx,ax
                mov     ah,3eh
                int     21h
                pop     ds
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                mov     byte ptr cs:redirect1,1
exitnewint21:
                jmp     dword ptr cs:oldint21
newint21        endp

begin:
                mov     savesp,sp
                mov     savess,ss
                mov     sp,offset userstackptr
                push    cs
                push    cs
                push    cs
                pop     ds
                pop     es
                pop     ss
                call    redirect21
                mov     bx,(offset lastbyte - firstbyte + 15) shr 4
                mov     ah,4ah
                int     21h
                jnc     executeprog
                jmp     exitprog
executeprog:
                push    cs
                pop     fcb1
                push    cs
                pop     fcb2
                push    cs
                pop     envstr
                mov     dx,offset filename
                mov     bx,offset paramblock
                mov     savetempsp,sp
                mov     ax,4b00h
                int     21h
                push    cs
                pop     ss
                mov     sp,savetempsp
                push    cs
                pop     ds
                push    cs
                pop     es
                jnc     exitprog
exitprog:
                call    unredirect21
                mov     ss,savess
                mov     sp,savesp
                mov     ax,4c00h
                int     21h

datafile        db      '      ',0
filename        db      '            ',0
paramblock      label   word
                dw      0
                dw      offset cmd_buf
fcb1            dw      ?
                dw      5ch
fcb2            dw      ?
                dw      6ch
envstr          dw      ?
cmd_buf         db      0
                db      ' '
cmd_txt         db      80h dup (?)
userstack       db      32 dup ('stack   ')
userstackptr    equ     $-2
lastbyte        equ     $

cseg            ends
                end     start



