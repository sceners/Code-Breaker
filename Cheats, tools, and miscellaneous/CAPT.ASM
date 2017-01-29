cr              equ     0dh                     ; Return
lf              equ     0ah                     ; Line feed
numtimes        equ     100
paramarea       equ     80h                     ; Parameter area

cseg            segment byte public
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
                org     0
firstbyte       equ     $                       ; First address of program
		org	100h

trainer         proc    far

start:
                jmp     begin

palname         db      'pic.pal',0
picname         db      'pic.dat',0
temppal         db      256*3 dup (?)
num8times       dw      0
palhandle       dw      0
pichandle       dw      0
savess          dw      0                       ; Save SS
savesp          dw      0                       ; Save SP
savetempsp      dw      0                       ; Save SP
oldint8         dd      0                       ; Storage of old INT 8h
oldint82        dd      0                       ; Storage of old INT 8h
oldint9         dd      0                       ; Storage of old INT 9h
oldint92        dd      0                       ; Storage of old INT 9h
oldint21        dd      0                       ; Storage of old INT 21h
oldint212       dd      0                       ; Storage of old INT 21h

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
; Get address of interrupt 8h by direct memory accessing.
;---------------------------------------------------------------

redirect8       proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,20h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint8
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint8+2
                push    word ptr es:[bx]
                pop     word ptr cs:oldint82
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint82+2
                push    offset newint8
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
redirect8       endp

;---------------------------------------------------------------
; Redirect interrupt 8h to original by direct memory accessing.
;---------------------------------------------------------------

unredirect8     proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,20h
                push    word ptr cs:oldint82
                pop     word ptr es:[bx]
                push    word ptr cs:oldint82+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect8     endp

;---------------------------------------------------------------
; New interrupt 1ch. Use to search memory.
;---------------------------------------------------------------

newint8         proc    near
                inc     word ptr cs:num8times
                cmp     word ptr cs:num8times,numtimes
                jl      exitnewint8
                mov     word ptr cs:num8times,0
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,24h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint9
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint9+2
                push    offset cs:newint9
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                call    beep
                call    setnewint
exitnewint8:
                jmp     dword ptr cs:oldint8
newint8routine:
                jmp     dword ptr cs:oldint8
num8bytes       equ     $-offset newint8routine
newint8         endp

;---------------------------------------------------------------
; Redirect interrupt 21h by direct memory accessing.
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
                cmp     ax,2508h
                je      intercept8
                cmp     ax,2509h
                je      intercept9
                cmp     ax,2521h
                je      intercept21
                jmp     exitnewint21
intercept8:
                push    ax
                mov     word ptr cs:oldint8,dx
                mov     ax,ds
                mov     word ptr cs:oldint8+2,ax
                push    cs
                pop     ds
                mov     dx,offset newint8
                pop     ax
                jmp     exitnewint21
intercept9:
                push    ax
                mov     word ptr cs:oldint9,dx
                mov     ax,ds
                mov     word ptr cs:oldint9+2,ax
                push    cs
                pop     ds
                mov     dx,offset newint9
                pop     ax
                jmp     exitnewint21
intercept21:
                push    ax
                mov     word ptr cs:oldint21,dx
                mov     ax,ds
                mov     word ptr cs:oldint21+2,ax
                push    cs
                pop     ds
                mov     dx,offset newint21
                pop     ax
exitnewint21:
                jmp     dword ptr cs:oldint21
newint21        endp

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
                push    ax                              ; pic registers
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
                call    getkey                       ; Wait until keypressed
                push    offset linefeed              ; New line
                call    writestr
                call    redirect8
                call    redirect9                    ; Redirect INT 9h
                call    redirect21
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
                call    unredirect21
                call    unredirect8
                call    unredirect9                 ; Redirect INT 9h
                mov     ss,savess
                mov     sp,savesp
                mov     ax,4c00h                    ; Exit program
		int	21h

setnewint       proc    near
                push    cx
                push    si
                push    di
                push    ds
                push    es
                push    cs
                push    cs
                pop     ds
                pop     es
                mov     si,offset newint8routine
                mov     di,offset newint8
                mov     cx,num8bytes
                rep     movsb
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     cx
                push    cx
                push    si
                push    di
                push    ds
                push    es
                push    cs
                push    cs
                pop     ds
                pop     es
                mov     si,offset newint9routine
                mov     di,offset newint9
                mov     cx,num9bytes
                rep     movsb
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     cx
                ret
setnewint       endp

;---------------------------------------------------------------
; Dump picture & palettes to file.
;---------------------------------------------------------------

scrdump         proc    near
                push    ds
                push    cs
                pop     ds
                lea     dx,picname
                mov     cx,0
                mov     ah,3ch
                int     21h
                jc      dumperror
                mov     pichandle,ax
                mov     ax,0a000h
                mov     ds,ax
                xor     dx,dx
                mov     cx,64000
                mov     bx,cs:pichandle
                mov     ah,40h
                int     21h
                jc      dumperror
closedumpfile:
                mov     bx,cs:pichandle
                mov     ah,3eh
                int     21h
dumpdone:
                pop     ds
                jmp     paldump
dumperror:
                jmp     dumpdone
paldump:
                push    ds
                push    cs
                pop     ds
                lea     dx,palname
                mov     cx,0
                mov     ah,3ch
                int     21h
                jc      adumpdone
                mov     palhandle,ax
                push    cs
                pop     ds
                mov     dx,3c7h
                mov     al,0h
                out     dx,al
                mov     cx,256*3
                mov     dx,3c9h
                xor     bx,bx
                cld
dumppalloop:
                in      al,dx
                mov     temppal[bx],al
                inc     bx
                loop    dumppalloop
                mov     dx,offset temppal
                mov     cx,256*3
                mov     bx,cs:palhandle
                mov     ah,40h
                int     21h
                jc      adumpdone
aclosedumpfile:
                mov     bx,cs:palhandle
                mov     ah,3eh
                int     21h
adumpdone:
                pop     ds
                call    setnewint
                ret
scrdump         endp

;---------------------------------------------------------------
; Redirect interrupt 9h by direct memory accessing.
;---------------------------------------------------------------

redirect9       proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
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
; Redirect interrupt 9h to original by direct memory accessing.
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

newint9         proc    far
                cli
                pushf
                call    dword ptr cs:oldint9
                pushf
                call    dword ptr cs:oldint9
                mov     dx,3dah
wait2:
                in      al,dx
                test    al,08h
                jz      wait2
retr:
                in      al,dx
                test    al,08h
                jnz     retr
                push    ax
                push    di
                push    ds
                push    cs
                pop     ds
                in      al,60h
                push    offset newint9key1
                pop     di
compareint9keys:
                cmp     byte ptr cs:[di],0
                je      exitnewint9
                cmp     al,cs:[di]
                je      execint9key
                inc     di
                inc     di
                inc     di
                jmp     short compareint9keys
execint9key:
                inc     di
                jmp     word ptr cs:[di]
exitnewint9:
                pop     ds
                pop     di
                pop     ax
                iret

newint9key1     db      2
                dw      offset newint9key1ofs
                db      0

newint9key1ofs:
                call    scrdump
                jmp     exitnewint9
newint9routine:
                cli
                db      6 dup (90h)
num9bytes       equ     $-offset newint9routine
newint9         endp

credit          db      '''Capture V1.0'' by Code Breaker.',cr,lf,lf
                db      'Strike a key....$'
linefeed        db      cr,lf,'$'
fail4a          db      cr,lf,'Unable to modify allocated memory blocks.$'
fail4b          db      cr,lf,'Unable to load program overlay.$'
error0          db      cr,lf,'Unknown error code.$'
error2          db      cr,lf,'''          '' - not found.$'
error4          db      cr,lf,'Too many files handles open.$'
error8          db      cr,lf,'Insufficient memory.$'
filename        db      'cch.exe',0
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