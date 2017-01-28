cr              equ     0dh                     ; Return
lf              equ     0ah                     ; Line feed
paramarea       equ     80h                     ; Parameter area
counternum      equ     200
memloc1         equ        0h
memloc2         equ        0h
memloc3         equ        0h
memloc4         equ        0h
memloc5         equ        0h

cseg            segment byte public
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
                org     0
firstbyte       equ     $                       ; First address of program
		org	100h

trainer         proc    far

start:
                jmp     begin

found           db      0                       ; Bytes found indicator
beginseg        dw      0
counter         dw      counternum              ; Counter
saveseg         dw      0                       ; Segment where bytes found
savess          dw      0                       ; Save SS
savesp          dw      0                       ; Save SP
savetempsp      dw      0                       ; Save SP
oldint16        dd      0                       ; Storage of old INT 16h
oldint162       dd      0                       ; Storage of old INT 16h
oldint1c        dd      0                       ; Storage of old INT 1ch
oldint1c2       dd      0                       ; Storage of old INT 1ch

trainer         endp

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
; Redirect interrupt 16h by direct memory accessing.
;---------------------------------------------------------------

redirect16      proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,64h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint16
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint16+2
                push    word ptr es:[bx]
                pop     word ptr cs:oldint162
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint162+2
                push    offset cs:newint16
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
redirect16      endp

;---------------------------------------------------------------
; Redirect interrupt 16h to original by direct memory accessing.
;---------------------------------------------------------------

unredirect16    proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,64h
                push    word ptr cs:oldint162
                pop     word ptr es:[bx]
                push    word ptr cs:oldint162+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect16    endp

;---------------------------------------------------------------
; New interrupt 16h. Use to toggle cheat on/off.
;---------------------------------------------------------------

newint16        proc    near
                push    ax                          ; Save registers
                push    bx
                push    ds
                push    cs                          ; Set DS=CS
                pop     ds
                in      al,60h                      ; Get a key
                mov     bx,offset key1              ; Key to compare
comparekeys:
                cmp     byte ptr cs:[bx],0          ; End of compare key
                je      exitnewint16
                cmp     al,cs:[bx]                  ; Compare keys
                je      execkey
                inc     bx                          ; Get next key
                inc     bx
                inc     bx
                jmp     short comparekeys
execkey:
                inc     bx                          ; Get address
                jmp     word ptr cs:[bx]            ; Execute key program
exitnewint16:
                pop     ds                          ; Restore registers
                pop     bx
                pop     ax
                jmp     dword ptr cs:oldint16       ; Execute old INT 16h

key1            db      2                           ; Predefine keys
                dw      offset key1ofs
key2            db      3
                dw      offset key2ofs
key3            db      4
                dw      offset key3ofs
key4            db      5
                dw      offset key4ofs
key5            db      6
                dw      offset key5ofs
                db      0
key1ofs:
                push    es
                push    di
                mov     di,memloc1
                push    saveseg
                pop     es
                xor     word ptr es:[di],    0h
                xor     word ptr es:[di+2],   0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint16
key2ofs:
                push    es
                push    di
                mov     di,memloc2
                push    saveseg
                pop     es
                xor     word ptr es:[di],    0h
                xor     word ptr es:[di+2],   0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint16
key3ofs:
                push    es
                push    di
                mov     di,memloc3
                push    saveseg
                pop     es
                xor     word ptr es:[di],    0h
                xor     word ptr es:[di+2],   0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint16
key4ofs:
                push    es
                push    di
                mov     di,memloc4
                push    saveseg
                pop     es
                xor     word ptr es:[di],    0h
                xor     word ptr es:[di+2],   0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint16
key5ofs:
                push    es
                push    di
                mov     di,memloc5
                push    saveseg
                pop     es
                xor     word ptr es:[di],    0h
                xor     word ptr es:[di+2],   0h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint16
newint16        endp

;---------------------------------------------------------------
; Redirect interrupt 1ch by direct memory accessing.
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
; Redirect interrupt 1ch to original by direct memory accessing.
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
; New interrupt 1ch. Use to search memory.
;---------------------------------------------------------------

newint1c        proc    near
                push    ax
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
                push    counternum
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
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,24h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint16
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint16+2
                push    offset cs:newint16
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                call    beep
                jmp     short incbase
execint1:
                pushf
                call    dword ptr oldint1c
incbase:
		inc	word ptr [bp-2]
                jmp     checkiffound
jmptoexit:
                jmp     short exitnewint1c
execint2:
                pushf
                call    dword ptr oldint1c
exitnewint1c:
		mov	sp,bp
		pop	bp
		pop	es
                pop     ds
		pop	di
		pop	ax
		iret
newint1c        endp

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
; Get a key from keyboard.
;---------------------------------------------------------------

getkey          proc    near
                push    ax
                xor     ax,ax
                int     16h
                pop     ax
                ret
getkey          endp

;---------------------------------------------------------------
; Write a string ending with $.
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
; Main execution block.
;---------------------------------------------------------------

begin:
                mov     savesp,sp
                mov     savess,ss
                mov     sp,offset localstackptr      ; Set up stack
                push    cs
                push    cs
                push    cs
                pop     ds
                pop     es
                pop     ss
                push    offset credit                ; Show information
                call    writestr
                push    offset linefeed              ; New line
                call    writestr
                call    getkey                       ; Wait until keypressed
                call    redirect16                   ; Redirect INT 16h
                call    redirect1c                   ; Redirect INT 1ch
                xor     bx,bx                        ; Set BX and CX to 0
                or      cx,bx
                mov     cl,ds:paramarea[bx]          ; Move parameters to CX
                or      cl,cl                        ; No parameters?
                jz      changemem                    ; Yes, jump to CHANGEMEM
                add     cx,2                         ; Number parameters in CX
                mov     si,offset paramarea          ; Parameters source
                mov     di,offset cmd_buf            ; Parameters destination
                rep     movsb
changemem:
                mov     bx,(offset lastbyte - firstbyte + 15) shr 4
                mov     ah,4ah                       ; Change memory
                int     21h                          ; allocation
                jnc     executeprog                  ; No error, execute prog.
                push    offset fail4a                ; Write error message
                call    writestr
                jmp     error
executeprog:
                mov     ax,cs                        ; Set up parameters
                mov     fcb1,ax                      ; for EXEC function
                mov     fcb2,ax
                mov     envstr,ax
                mov     dx,offset filename
                mov     bx,offset paramblock
                mov     savetempsp,sp
                mov     ax,4b00h                     ; Execute program
                int     21h
                mov     bx,cs                        ; Set up DS,ES,SS to CS
                mov     ss,bx
                mov     sp,cs:savetempsp             ; Restore SP
                mov     ds,bx
                mov     es,bx
                jnc     exitprog                     ; No error, exit program
                push    offset fail4b                ; Show error message
                call    writestr
error:
                call    showerror
exitprog:
                call    unredirect16                ; Redirect INT 16h
                call    unredirect1c                ; Redirect INT 1ch
                mov     ss,savess
                mov     sp,savesp
                mov     ax,4c00h                    ; Exit program
		int	21h

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
localstack      db      32 dup ('stack   ')
localstackptr   label   word
lastbyte        equ     $

cseg            ends
                end     start

