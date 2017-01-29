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

fix             proc    far

start:
                jmp     begin

found           db      0
beginseg        dw      0
counter         dw      repeatcounter
savesp          dw      0
savess          dw      0
savetempsp      dw      0
oldint1c        dd      0

fix             endp

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
                push    word ptr cs:oldint1c
                pop     word ptr es:[bx]
                push    word ptr cs:oldint1c+2
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
                mov     word ptr es:[di], 0h
                mov     word ptr es:[di+2], 0h
                mov     word ptr es:[di+4], 0h
                mov     word ptr es:[di+6], 0h
                mov     byte ptr found,1
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
                call    redirect1c
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
                call    unredirect1c
                mov     ss,savess
                mov     sp,savesp
                mov     ax,4c00h
                int     21h

credit          db      '''             '' fix by Code Breaker.',cr,lf
                db      'Greetings to all.',cr,lf,lf,'Strike a key....$'
linefeed        db      cr,lf,'$'
fail4a          db      cr,lf,'Unable to modify allocated memory blocks.$'
fail4b          db      cr,lf,'Unable to load program overlay.$'
error0          db      cr,lf,'Unknown error code.$'
error2          db      cr,lf,'''          '' - not found.$'
error4          db      cr,lf,'Too many files handles open.$'
error8          db      cr,lf,'Insufficient memory.$'
filename        db      '               ',0
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