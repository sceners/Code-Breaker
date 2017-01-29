cr              equ     0dh                     ; line return
lf              equ     0ah                     ; line feed
paramarea       equ     80h                     ; parameter(s) area
repeatcounter   equ     200
memloc1         equ       0h
memloc2         equ       0h
memloc3         equ       0h
memloc4         equ       0h
memloc5         equ       0h

cseg            segment
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
                org     0
firstbyte       equ     $
		org	100h

trainer         proc    far

start:
                jmp     begin

found           db      0
redirect9f      db      0
redirect1cf     db      0
redirect21f     db      0
beginseg        dw      0
counter         dw      repeatcounter
saveseg         dw      0
savesp          dw      0
savess          dw      0
savetempsp      dw      0
oldint9         dd      0
oldint92        dd      0
oldint1c        dd      0
oldint1c2       dd      0
oldint21        dd      0
oldint212       dd      0

trainer         endp

;---------------------------------------------------------------
; Intercept 9h.
;---------------------------------------------------------------

redirect9       proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                push    cs
                pop     ds
                or      bx,24h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint9
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint9+2
                push    word ptr es:[bx]
                pop     word ptr cs:oldint92
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint92+2
                push    offset cs:newint9
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
redirect9       endp

;---------------------------------------------------------------
; Set address of interrupt 9h back to original.
;---------------------------------------------------------------

unredirect9     proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,24h
                push    word ptr cs:oldint92
                pop     word ptr es:[bx]
                push    word ptr cs:oldint92+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect9     endp

;---------------------------------------------------------------
; New interrupt 9h.
;---------------------------------------------------------------

newint9         proc    near
                push    ax
                push    bx
                push    ds
                cmp     byte ptr cs:redirect9f,1
                jne     exitnewint9
                cmp     byte ptr cs:found,1
                jne     exitnewint9
                push    cs
                pop     ds
                in      al,60h
                push    offset key1
                pop     bx
comparekeys:
                cmp     byte ptr cs:[bx],0
                je      exitnewint9
                cmp     al,cs:[bx]
                je      execkey
                inc     bx
                inc     bx
                inc     bx
                jmp     short comparekeys
execkey:
                inc     bx
                jmp     word ptr cs:[bx]
exitnewint9:
                pop     ds
                pop     bx
                pop     ax
                jmp     dword ptr cs:oldint9

key1            db      0h
                dw      offset key1ofs
key2            db      0h
                dw      offset key2ofs
key3            db      0h
                dw      offset key3ofs
key4            db      0h
                dw      offset key4ofs
key5            db      0h
                dw      offset key5ofs
                db      0

key1ofs:
                push    es
                push    di
                mov     di,memloc1
                push    saveseg
                pop     es
                xor     word ptr es:[di],   0h
                xor     word ptr es:[di+2],  0h
                xor     word ptr es:[di+4],  0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
key2ofs:
                push    es
                push    di
                mov     di,memloc2
                push    saveseg
                pop     es
                xor     word ptr es:[di],   0h
                xor     word ptr es:[di+2],  0h
                xor     word ptr es:[di+4],  0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
key3ofs:
                push    es
                push    di
                mov     di,memloc3
                push    saveseg
                pop     es
                xor     word ptr es:[di],   0h
                xor     word ptr es:[di+2],  0h
                xor     word ptr es:[di+4],  0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
key4ofs:
                push    es
                push    di
                mov     di,memloc4
                push    saveseg
                pop     es
                xor     word ptr es:[di],   0h
                xor     word ptr es:[di+2],  0h
                xor     word ptr es:[di+4],  0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
key5ofs:
                push    es
                push    di
                mov     di,memloc5
                push    saveseg
                pop     es
                xor     word ptr es:[di],   0h
                xor     word ptr es:[di+2],  0h
                xor     word ptr es:[di+4],  0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
newint9         endp

;---------------------------------------------------------------
; Redirect interrupt 1ch.
;---------------------------------------------------------------

redirect1c      proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,70h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint1c
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint1c+2
                push    word ptr es:[bx]
                pop     word ptr cs:oldint1c2
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint1c2+2
                push    offset cs:newint1c
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
redirect1c      endp

;---------------------------------------------------------------
; Redirect interrupt 1ch back to original.
;---------------------------------------------------------------

unredirect1c    proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,70h
                push    word ptr cs:oldint1c2
                pop     word ptr es:[bx]
                push    word ptr cs:oldint1c2+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect1c    endp

;---------------------------------------------------------------
; New interrupt 1ch.
;---------------------------------------------------------------

newint1c        proc    near
		push	ax
		push	di
		push	ds
		push	es
		push	bp
		mov	bp,sp
                cmp     byte ptr found,1
                je      jmptoexit2
		sub	sp,2
                push    cs
                push    cs
                push    cs
                pop     ds
                pop     [bp-2]
                pop     beginseg
                dec     counter
                cmp     word ptr counter,0
                je      checkiffound
                jmp     execint2
checkiffound:
                cmp     byte ptr found,0
                je      continues
jmptoexit2:
                jmp     jmptoexit
continues:
                mov     ax,beginseg
                add     ax,0fffeh
                cmp     ax,[bp-2]
                jne     search1
                push    repeatcounter
                pop     counter
                jmp     jmptoexit
search1:
                push    [bp-2]
                mov     di,memloc1
		pop	es
                cmp     word ptr es:[di], 0h
                je      search2
                jmp     incbase
search2:
                cmp     word ptr es:[di+2], 0h
                je      search3
                jmp     incbase
search3:
                cmp     word ptr es:[di+4], 0h
                je      fixmem
                jmp     execint1
fixmem:
                mov     byte ptr found,1
                push    [bp-2]
                pop     saveseg
                call    beep
                jmp     short incbase
execint1:
                pushf
                call    dword ptr oldint1c
incbase:
		inc	word ptr [bp-2]
                jmp     checkiffound
jmptoexit:
                jmp     short exitnewint
execint2:
                pushf
                call    dword ptr oldint1c
exitnewint:
		mov	sp,bp
		pop	bp
		pop	es
                pop     ds
		pop	di
		pop	ax
		iret
newint1c        endp

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
                push    word ptr es:[bx]
                pop     word ptr cs:oldint212
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint212+2
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
                push    word ptr cs:oldint212
                pop     word ptr es:[bx]
                push    word ptr cs:oldint212+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect21    endp

;---------------------------------------------------------------
; New interrupt 21h. Use to intercept keyboard redirection.
;---------------------------------------------------------------

newint21        proc    near
                cmp     ax,2509h
                je      intercept9
                cmp     ax,251ch
                je      intercept21
                cmp     ax,2521h
                je      intercept21
                jmp     exitnewint21
intercept9:
                cmp     byte ptr cs:redirect9f,1
                je      exitnewint21
                push    ax
                mov     word ptr cs:oldint9,dx
                mov     ax,ds
                mov     word ptr cs:oldint9+2,ax
                push    cs
                pop     ds
                mov     dx,offset newint9
                pop     ax
                mov     byte ptr cs:redirect9f,1
                jmp     exitnewint21
intercept1c:
                cmp     byte ptr cs:redirect1cf,1
                je      exitnewint21
                push    ax
                mov     word ptr cs:oldint1c,dx
                mov     ax,ds
                mov     word ptr cs:oldint1c+2,ax
                push    cs
                pop     ds
                mov     dx,offset newint1c
                pop     ax
                mov     byte ptr cs:redirect1cf,1
                jmp     exitnewint21
intercept21:
                cmp     byte ptr cs:redirect21f,1
                je      exitnewint21
                push    ax
                mov     word ptr cs:oldint21,dx
                mov     ax,ds
                mov     word ptr cs:oldint21+2,ax
                push    cs
                pop     ds
                mov     dx,offset newint21
                pop     ax
                mov     byte ptr cs:redirect21f,1
exitnewint21:
                jmp     dword ptr cs:oldint21
newint21        endp

;---------------------------------------------------------------
; Make a simple beep.
;---------------------------------------------------------------

beep            proc    near
                push    bx
                push    di
                mov     bx,100h
                mov     di,70
                call    sound
                pop     di
                pop     bx
                ret
beep            endp

;---------------------------------------------------------------
; Turn on speaker. BX - frequency, DI - duration
;---------------------------------------------------------------

sound           proc    near
                push    ax
                push    bx
                push    cx
                push    dx
                push    di
                mov     al,0b6h
                out     43h,al
                mov     dx,14h
                mov     ax,4f38h
                div     di
                out     42h,al
                mov     al,ah
                out     42h,al
                in      al,61h
                mov     ah,al
                or      al,3
                out     61h,al
pause:
                mov     cx,2801
spkron:
                loop    spkron
                dec     bx
                jnz     pause
                mov     al,ah
                out     61h,al
                pop     di
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret
sound           endp

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
                call    redirect9
                call    redirect1c
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
                call    unredirect9
                call    unredirect21
                call    unredirect1c
                mov     ss,savess
                mov     sp,savesp
                mov     ax,4c00h
                int     21h

credit          db      '''             '' cheat by Code Breaker.',cr,lf,lf
                db      'Keys are : ',cr,lf,lf
                db      '                     ',cr,lf
                db      '                     ',cr,lf
                db      '                     ',cr,lf
                db      '                     ',cr,lf
                db      '                     ',cr,lf,lf
                db      'Greetings to all.',cr,lf,lf,'Strike a key....$'
linefeed        db      cr,lf,'$'
fail4a          db      cr,lf,'Unable to modify allocated memory blocks.$'
fail4b          db      cr,lf,'Unable to load program overlay.$'
error0          db      cr,lf,'Unknown error code.$'
error2          db      cr,lf,'''          '' - not found.$'
error4          db      cr,lf,'Too many files handles open.$'
error8          db      cr,lf,'Insufficient memory.$'
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
