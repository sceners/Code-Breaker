cr              equ     0dh
lf              equ     0ah
paramarea       equ     80h
skey1           equ       34h
skey2           equ       2eh
skey3           equ       5fh
skey4           equ       6ch
skey5           equ       91h
skey6           equ       7ah
skey7           equ       4bh
skey8           equ      0a8h
skey9           equ      0e9h
skey10          equ      0f8h
skey11          equ      0c5h
skey12          equ      0d4h
skey13          equ      0bfh
skey14          equ       2fh
skey15          equ       37h
skey16          equ       2ch
skeyint3        equ       1dh
startaddr       equ      100h
startkey        equ      03bh
memloc1         equ     94c6h
       
cseg            segment byte public
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
                org     0
firstbyte       equ     $
                org     100h

fix             proc    far

start:
                push    skey1
                push    offset cs:change2
                push    offset cs:change3 - cs:change2
                call    change
change2:
                push    skey2
                push    offset cs:change3
                push    offset cs:change4 - cs:change3
                call    change
change3:
                push    skey3
                push    offset cs:change4
                push    offset cs:change5 - cs:change4
                call    change
change4:
                push    skey4
                push    offset cs:change5
                push    offset cs:change6 - cs:change5
                call    change
change5:
                push    skey5
                push    offset cs:change6
                push    offset cs:change7 - cs:change6
                call    change
change6:
                push    skey6
                push    offset cs:change7
                push    offset cs:change8 - cs:change7
                call    change
change7:
                push    skey7
                push    offset cs:change8
                push    offset cs:change9 - cs:change8
                call    change
change8:
                push    skey8
                push    offset cs:change9
                push    offset cs:change10 - cs:change9
                call    change
change9:
                push    skey9
                push    offset cs:change10
                push    offset cs:change11 - cs:change10
                call    change
change10:
                push    skey10
                push    offset cs:change11
                push    offset cs:change12 - cs:change11
                call    change
change11:
                push    skey11
                push    offset cs:change12
                push    offset cs:change13 - cs:change12
                call    change
change12:
                push    skey12
                push    offset cs:change13
                push    offset cs:change14 - cs:change13
                call    change
change13:
                push    skey13
                push    offset cs:change14
                push    offset cs:change15 - cs:change14
                call    change
change14:
                push    skey14
                push    offset cs:change15
                push    offset cs:change16 - cs:change15
                call    change
change15:
                push    skey15
                push    offset cs:change16
                push    offset cs:nochange - cs:change16
                call    change
change16:
                push    skey16
                push    offset cs:nochange
                push    offset cs:lastbyte - cs:nochange
                call    change
nochange:
                push    cs
                pop     ds
                push    ds
                mov     bx,offset beginofs
                push    bx
                retf
beginofs:
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
                cmp     byte ptr cs:found,1
                je      exitnewint21
                push    bp
                mov     bp,sp
                push    ds
                push    di
                mov     ds,[bp+4]
                mov     di,memloc1
                cmp     word ptr ds:[di],0b851h
                jne     exitsearch
                cmp     word ptr ds:[di+2],0019h
                jne     exitsearch
                cmp     word ptr ds:[di+4],80e8h
                jne     exitsearch
                cmp     word ptr ds:[di+6],3285h
                jne     exitsearch
                mov     word ptr ds:[di],34ebh
                mov     byte ptr cs:found,1
exitsearch:
                pop     di
                pop     ds
                pop     bp
exitnewint21:
                jmp     dword ptr cs:oldint21
newint21        endp

;---------------------------------------------------------------
; Get a key from the keyboard.
;---------------------------------------------------------------
getkey          proc    near
                xor     ax,ax
                int     16h
                ret
getkey          endp

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
                call    unredirect1c
                call    unredirect3
                mov     savesp,sp
                mov     savess,ss
                mov     sp,offset userstackptr
                push    cs
                push    cs
                push    cs
                pop     ds
                pop     es
                pop     ss
                push    offset cs:credit
                call    writestr
                call    getkey
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

credit          db      '  ีอออออออออออออออออออออออออออออออต PENT/ดGRAM ฦอออออออออออออออออออออออออออออธ',cr,lf
                db      '  ณ PENT/ดGRAM PROUDLY PRESENTS - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   ณ',cr,lf
                db      '  ณ Memory patcher/loader v1.0 by Code Breaker                               ณ',cr,lf
                db      '  ณ                                                                          ณ',cr,lf
                db      '  ณ Greetings - The Rocketeer, Flip Boy, Fanfan, Dr. Insanity, Faceless      ณ',cr,lf
                db      '  ณ           - Viper, Silicon Soldier, all PTG members and everyone else... ณ',cr,lf
                db      '  ณ                                                                          ณ',cr,lf
                db      '  ณ Strike a key to start...                                                 ณ',cr,lf
                db      '  ิออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออพ',cr,lf,'$'
fail4a          db      cr,lf,'  Unable to modify allocated memory blocks.$'
fail4b          db      cr,lf,'  Unable to load program.$'
error0          db      cr,lf,'  Unknown error code.$'
error2          db      cr,lf,'  ''       '' - not found.$'
error4          db      cr,lf,'  Too many files handles open.$'
error8          db      cr,lf,'  Insufficient memory.$'
filename        db      '       ',0
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

;---------------------------------------------------------------
; Change program using xor.
;---------------------------------------------------------------
change          proc    near
                push    ax
                push    bx
                push    cx
                push    bp
                mov     bp,sp
changebytes:
                mov     cx,cs:[bp+10]
                mov     bx,cs:[bp+12]
                mov     al,cs:[bp+14]
xorbyte:
                xor     byte ptr cs:[bx],al
                inc     bx
                loop    xorbyte
                pop     bp
                pop     cx
                pop     bx
                pop     ax
                ret     6                               ; location 1
change          endp

;---------------------------------------------------------------
; Redirect interrupt 3h back to original.
;---------------------------------------------------------------
unredirect3     proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,0ch
                push    word ptr cs:oldint3
                pop     word ptr es:[bx]
                push    word ptr cs:oldint3+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect3     endp

;---------------------------------------------------------------
; New interrupt 3h.
;---------------------------------------------------------------
newint3         proc    near
                cmp     byte ptr cs:done,1
                jne     setdata
                pushf
                call    dword ptr cs:oldint3
                iret
setdata:
                mov     byte ptr cs:done,1
                pop     word ptr cs:tempseg
                pop     word ptr cs:tempofs
                push    cx
                push    si
                push    di
                push    ds
                push    es
                push    cs
                pop     ds
                push    cs
                pop     ds
                mov     cx,9
                mov     si,offset cs:begindata
                mov     di,offset cs:start
                rep     movsb
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     cx
                push    cs
                push    startaddr
                retf
newint3         endp

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
                cmp     byte ptr cs:done,1
                je      exitnewint1c
                pop     word ptr cs:tempseg
                pop     word ptr cs:tempofs
                int     3
                int     1
exitnewint1c:
                int     3
                int     1
                pushf
                call    dword ptr cs:oldint1c
                iret
newint1c        endp

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
; Calculate jump offset and encode interrupt 3h.
;---------------------------------------------------------------
caljmpencode3   proc    near
                push    ax                              ; location 2
                push    cx
                push    si
                push    di
                push    ds
                push    es
                push    cs
                pop     ds
                push    cs
                pop     ds
                mov     ax,offset cs:redirect3
                sub     ax,offset cs:start+3
                mov     word ptr cs:calint3ofs,ax
                mov     ax,offset cs:redirect1c
                sub     ax,offset cs:start+6
                mov     word ptr cs:calint1cofs,ax
                mov     cx,9
                mov     si,offset cs:jmpinst
                mov     di,offset cs:start
                rep     movsb
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     cx
                pop     ax
                call    scrnewint3
                call    scrunredirect3
                call    scrstart
                push    cs
                push    startaddr
                retf                                    ; location 3
caljmpencode3   endp

scrunredirect3  proc    near
                push    skeyint3
                push    offset cs:unredirect3
                push    offset cs:caljmpencode3 - cs:unredirect3
                call    change
                ret
scrunredirect3  endp

scrnewint3      proc    near
                push    skeyint3
                push    offset cs:newint3
                push    offset cs:caljmpencode3 - cs:newint3
                call    change
                ret
scrnewint3      endp

scrstart        proc    near
                push    startkey
                push    offset cs:start+3
                push    offset cs:change2 - cs:start+3
                call    change
                ret
scrstart        endp

;---------------------------------------------------------------
; Redirect interrupt 3h.
;---------------------------------------------------------------
redirect3       proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,0ch
                push    word ptr es:[bx]
                pop     word ptr cs:oldint3
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint3+2
                push    offset cs:newint3
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                call    scrunredirect3
                call    scrnewint3
                call    scrstart
                ret
redirect3       endp

done            db      0
oldint1c        dd      0
oldint3         dd      0
jmpinst         db      0e8h
calint3ofs      dw      0
                db      0e8h
calint1cofs     dw      0
                db      0cch
                dw      1ccdh
begindata       db      50h,55h,8bh,0ech,0c7h,46h,2,skey1,0
tempseg         dw      0
tempofs         dw      0
ofs1            dw      offset caljmpencode3
ofs2            dw      offset scrunredirect3-1

cseg            ends
                end     start


@echo off
goto start

rip
2ef
g 30d
t
g loc1
p

rip
2ce
g 2ec
t
g loc1
p

rip
2ad
g 2cb
t
g loc1
p

rip
28c
g 2aa
t
g loc1
p

rip
26b
g 289
t
g loc1
p

rip
24a
g 268
t
g loc1
p

rip
229
g 247
t
g loc1
p

rip
208
g 226
t
g loc1
p

rip
1e7
g 205
t
g loc1
p

rip
1c6
g 1e4
t
g loc1
p

rip
1a5
g 1c3
t
g loc1
p

rip
184
g 1a2
t
g loc1
p

rip
163
g 181
t
g loc1
p

rip
142
g 160
t
g loc1
p

rip
121
g 13f
t
g loc1
p

rip
100
g 11e
t
g loc1
p

rip
loc2
g loc3
p

rip
100

n temp.com
w
q

:start
if exist=%1 goto begin
echo %1 - not found.
goto exit
:begin
echo Encoding...Please wait...
debug %1 < %0.bat > nul
copy temp.com %1
del temp.com
:exit
