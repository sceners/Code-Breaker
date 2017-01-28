cr              equ     0dh
lf              equ     0ah
paramarea       equ     80h
memloc1         equ   65b7h
       
cseg            segment byte public
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
                org     0
firstbyte       equ     $
                org     100h

fix             proc    far

start:
                jmp     begin

found           db      0
savesp          dw      0
savess          dw      0
savetempsp      dw      0
oldint21        dd      0

fix             endp

;---------------------------------------------------------------
; Redirect interrupt 21h through absolute memory access.
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
; New interrupt 21h. Use to search for certain bytes in memory.
;---------------------------------------------------------------
newint21        proc    far
                cmp     byte ptr found,1
                je      exitnewint21
                push    bp
                mov     bp,sp
                push    ds
                push    di
                mov     ds,[bp+4]
                mov     di,memloc1
                cmp     word ptr ds:[di],468bh
                jne     exitsearch
                cmp     word ptr ds:[di+2],48feh
                jne     exitsearch
                cmp     word ptr ds:[di+4],9a50h
                jne     exitsearch
                cmp     word ptr ds:[di+6],90h
                jne     exitsearch
                mov     word ptr ds:[di],01beh
                mov     word ptr ds:[di+2],0e900h
                mov     word ptr ds:[di+4],00a3h
                mov     byte ptr found,1
exitsearch:
                pop     di
                pop     ds
                pop     bp
exitnewint21:
                jmp     dword ptr cs:oldint21
newint21        endp

;---------------------------------------------------------------
; Write a string.
;---------------------------------------------------------------
writestr        proc    near
                push    ax                              ; save registers
                push    dx
                push    bp
                mov     bp,sp
                push    [bp+8]                          ; set dx=[bp+8]
                pop     dx
                mov     ah,9                            ; write string
                int     21h
                pop     bp                              ; restore registers
                pop     dx
                pop     ax
                ret     2
writestr        endp

;---------------------------------------------------------------
; Show error(s) that occurred during execution of program.
;---------------------------------------------------------------
showerror       proc    near
                push    ax
                cmp     ax,2
                je      em2
                cmp     ax,4
                je      em4
                cmp     ax,8
                je      em8
                push    offset error0
                jmp     writeerror
em2:
                push    offset error2
                jmp     writeerror
em4:
                push    offset error4
                jmp     writeerror
em8:
                push    offset error8
writeerror:
                call    writestr
                pop     ax
                ret
showerror       endp

;---------------------------------------------------------------
; Get and store parameters.
;---------------------------------------------------------------
getparam        proc    near
                push    bx
                push    cx
                push    si
                push    di
                xor     bx,bx
                or      cx,bx
                mov     cl,ds:paramarea[bx]
                or      cl,cl
                jz      exitgetparam
                add     cx,2
                mov     si,offset paramarea
                mov     di,offset cmd_buf
                rep     movsb
exitgetparam:
                pop     di
                pop     si
                pop     cx
                pop     bx
                ret
getparam        endp

;---------------------------------------------------------------
; Main execution block.
;---------------------------------------------------------------
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
                push    offset credit
                call    writestr
                xor     ax,ax
                int     16h
                push    offset linefeed
                call    writestr
                call    redirect21
                call    getparam
                mov     bx,(offset lastbyte - firstbyte + 15) shr 4
                mov     ah,4ah
                int     21h
                jnc     executeprog
                push    offset fail4a
                call    writestr
                jmp     error
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
                push    offset fail4b
                call    writestr
error:
                call    showerror
exitprog:
                call    unredirect21
                mov     ss,savess
                mov     sp,savesp
                mov     ax,4c00h
                int     21h

credit          db      '''Prince of Persia 2'' unprotected by Code Breaker.',cr,lf
                db      'Greetings to all.',cr,lf,lf,'Strike a key....$'
linefeed        db      cr,lf,'$'
fail4a          db      cr,lf,'Unable to modify allocated memory blocks.$'
fail4b          db      cr,lf,'Unable to load program overlay.$'
error0          db      cr,lf,'Unknown error code.$'
error2          db      cr,lf,'''Prince.exe'' - not found.$'
error4          db      cr,lf,'Too many files handles open.$'
error8          db      cr,lf,'Insufficient memory.$'
filename        db      'Prince.exe',0
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
userstackptr    label   word
lastbyte        equ     $

cseg            ends
                end     start
