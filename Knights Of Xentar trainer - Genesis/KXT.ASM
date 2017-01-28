                smart
                locals
                dosseg

;---------------------------------------------------------------
; Equates.
;---------------------------------------------------------------
cr              equ        0dh                  ; line return (ENTER)
lf              equ        0ah                  ; line feed
paramarea       equ        80h                  ; parameter(s) area
kbofs           equ      76b7h                  ; keyboard offset of child
memloc1         equ      1318h
memloc2         equ      16a4h
memloc3         equ      31c5h
lrmemloc        equ      144ch                  ; left & right location of child
udmemloc        equ      144eh                  ; up & down location of child

;---------------------------------------------------------------
; Pop-up menu equates.
;---------------------------------------------------------------
strlen          equ         53
savenumbytes    equ       4096
textscrsize     equ       2000
colorscr        equ     0b800h
tbc             equ        112          ; color of top & bottom row of menu
midcolor        equ        113          ; color of top & bottom row
fcc             equ        116          ; color of first character in string
numpopups       equ          4
wipescrsize     equ      23*80
exitkey         equ        44h
menusize        equ          3

;---------------------------------------------------------------
; Intro menu equates
;---------------------------------------------------------------
vgaseg          equ     0a000h                  ; VGA segment
introsize       equ       5840                  ; intro size
numoptions      equ          6                  ; number of options
erasebarcolor   equ        245                  ; erase color of bar
barcolor        equ         16                  ; color of bar
barxc           equ        176                  ; x coord. of bar
baryc           equ         56                  ; y coord. of bar
barlength       equ        142                  ; length of bar
scrollx         equ          4                  ; credit x coord.
scrolly         equ         42                  ; credit y coord.
delay           equ        35h                  ; timer delay for credit msg
numlines        equ          9                  ; number of credit lines
strlen          equ         53                  ; length of string
offonx          equ        310                  ; +/- x coord.
offony          equ         56                  ; +/- y coord.
optionx         equ        151                  ; x location of options
optiony         equ         56                  ; y     "    "   "
bkcolor         equ         19                  ; background color
extraopt        equ          5                  ; extra options
down            equ      5000h                  ; down key
esckey          equ       11bh                  ; escape key
space           equ      3920h                  ; space bar
up              equ      4800h                  ; up key

;---------------------------------------------------------------
; Stack segment
;---------------------------------------------------------------
sseg            segment para use16 stack 'stack'
                db      512 dup(?)
sseg            ends

;---------------------------------------------------------------
; Data segment
;---------------------------------------------------------------
dseg            segment para use16 'data'
fail4a          db      cr,lf,'Unable to modify allocated memory blocks.$'
fail4b          db      cr,lf,'Unable to load program.$'
error0          db      cr,lf,'Unknown error code.$'
error1          db      cr,lf,'Invalid function.$'
error2          db      cr,lf,'''Kx.exe'' - not found.$'
error3          db      cr,lf,'Path not found.$'
error4          db      cr,lf,'Too many files handles open.$'
error5          db      cr,lf,'Access denied.$'
error6          db      cr,lf,'Invalid handle.$'
error8          db      cr,lf,'Insufficient memory.$'
needvga         db      cr,lf,'Intro screen require VGA. See Genesis.key for '
                db      'information on trainer keys.$'
errors          dw      offset ds:error0        ; table of errors
                dw      offset ds:error1
                dw      offset ds:error2
                dw      offset ds:error3
                dw      offset ds:error4
                dw      offset ds:error5
                dw      offset ds:error6
                dw      offset ds:error8
filename        db      'Kx.exe',0
paramblock      label   word                    ; child prog. parameters block
envstr          dw      ?
                dw      80h
cmd             dw      ?
                dw      5ch
fcb1            dw      ?
                dw      6ch
fcb2            dw      ?
savesp          dw      0                       ; save SP, SS for EXEC function
savess          dw      0
module          label   byte
                include trnmusic
dseg            ends

;---------------------------------------------------------------
; Code segment
;---------------------------------------------------------------
cseg            segment para use16 'code'
                assume  cs:cseg,ds:dseg,ss:sseg

hscplayer       equ     $
                include hscobj

trainer         proc    far
                mov     bx,ss                   ; allocate memory
                mov     ax,es
                sub     bx,ax
                mov     ax,sp
                add     ax,15
                mov     cl,4
                shr     ax,cl
                add     bx,ax
                mov     ah,4ah
                int     21h
                jnc     executeprog
                push    offset fail4a           ; error in allocating memory
                call    writestr
                call    showerror
                jmp     terminate
executeprog:
                mov     ax,dseg
                mov     ds,ax
                call    getint10
                call    redirectbb
                call    redirectcc
                call    redirectdd
                call    redirect21
                mov     ax,1a00h
                int     10h
                cmp     al,1ah
                je      showintro
                push    offset needvga
                call    writestr
                call    getkey
                jmp     execprog
showintro:
                call    playmode
                call    dointro
                call    popupmenu
                call    stopfmm
                push    3
                call    setmode
                cmp     byte ptr cs:exitprogf,1
                je      exitprog
execprog:
                push    word ptr es:[2ch]
                pop     envstr
                push    es
                pop     cmd
                push    es
                pop     fcb1
                push    es
                pop     fcb2
                push    ds
                pop     es
                mov     dx,offset filename
                mov     bx,offset paramblock
                mov     savess,ss
                mov     savesp,sp
                mov     ax,4b00h
                int     21h
                mov     ss,savess
                mov     sp,savesp
                jnc     exitprog
                push    offset fail4b
                call    writestr
error:
                call    showerror
exitprog:
                call    unredirect21
                call    unredirectdd
                call    unredirectcc
                call    unredirectbb
terminate:
                mov     ax,4c00h
                int     21h
trainer         endp

;---------------------------------------------------------------
; Redirect interrupt 0bbh.
;---------------------------------------------------------------
redirectbb      proc    near
                push    ax
                push    dx
                push    ds
                push    es
                mov     ax,35bbh
                int     21h
                mov     word ptr cs:oldintbb,bx
                mov     word ptr cs:oldintbb+2,es
                push    cs
                pop     ds
                mov     dx,offset newintbb
                mov     ax,25bbh
                int     21h
                pop     es
                pop     ds
                pop     dx
                pop     ax
                ret
redirectbb      endp

;---------------------------------------------------------------
; Set address of interrupt 0bbh back to original.
;---------------------------------------------------------------
unredirectbb    proc    near
                push    ds
                lds     dx,dword ptr cs:oldintbb
                mov     ax,25bbh
                int     21h
                pop     ds
                ret
unredirectbb    endp

;---------------------------------------------------------------
; New interrupt 0bbh.
;---------------------------------------------------------------
newintbb        proc    near
                push    bx
                push    ds
                in      al,60h
                cmp     byte ptr cs:inplace,1
                jne     exitnewintbb
                cmp     al,41h                          ; toggle all key
                je      startcmpkeys
                cmp     al,40h                          ; pop-up key
                je      startcmpkeys
                cmp     al,3bh                          ; 1st key
                jb      exitnewintbb
                cmp     al,44h                          ; last key
                ja      checkmovement
                jmp     startcmpkeys
checkmovement:
                cmp     byte ptr cs:movementon,1
                je      startcmpkeys
                jmp     exitnewintbb
startcmpkeys:
                push    offset cs:key1
                pop     bx
comparekeys:
                cmp     byte ptr cs:[bx],0
                je      exitnewintbb
                cmp     al,cs:[bx]
                je      execkey
                inc     bx
                inc     bx
                inc     bx
                jmp     short comparekeys
execkey:
                inc     bx
                call    word ptr cs:[bx]
exitnewintbb:
                pop     ds
                pop     bx
                iret

key1            db      3bh
                dw      offset key1ofs
key2            db      3ch
                dw      offset key2ofs
key3            db      3dh
                dw      offset key3ofs
key4            db      3eh
                dw      offset key4ofs
key5            db      3fh
                dw      offset key5ofs
mrskey          db      42h                     ; Toggle movement rate on/off
                dw      offset mrateswitch
activateall     db      41h                     ; Toggle all
                dw      offset toggleall
menukey         db      40h                     ; Pop-up menu
                dw      offset menuroutine
imrkey          db      43h                     ; Increase movement rate
                dw      offset incmrate
dmrkey          db      44h                     ; Decrease movement rate
                dw      offset decmrate
keyhome         db      71                      ; Home
                dw      offset keyhomeofs
keyup           db      72                      ; Up
                dw      offset keyupofs
keypgup         db      73                      ; PgUp
                dw      offset keypgupofs
keyleft         db      75                      ; Left
                dw      offset keyleftofs
keyright        db      77                      ; Right
                dw      offset keyrightofs
keyend          db      79                      ; End
                dw      offset keyendofs
keydown         db      80                      ; Down
                dw      offset keydownofs
keypgdn         db      81                      ; PgDn
                dw      offset keypgdnofs
                db      0

key1ofs:
                xor     byte ptr cs:infeng,1
                call    beep
                cmp     byte ptr cs:infeng,1
                je      exitkey1ofs
                call    beep
exitkey1ofs:
                ret
key2ofs:
                xor     byte ptr cs:infmny,1
                call    beep
                cmp     byte ptr cs:infmny,1
                je      exitkey2ofs
                call    beep
exitkey2ofs:
                push    es
                push    di
                push    cs:savecseg
                pop     es
                mov     di,memloc3
                xor     word ptr es:[di],0b9f6h
                xor     word ptr es:[di+2],3496h
                xor     byte ptr es:[di+4],86h
                pop     di
                pop     es
                ret
key3ofs:
                push    es
                push    di
                mov     di,memloc1
                push    cs:savedseg
                pop     es
                mov     word ptr es:[di],03ffh
                mov     word ptr es:[di+2],03ffh
                mov     di,1350h
                mov     word ptr es:[di],03ffh
                mov     word ptr es:[di+2],03ffh
                mov     di,1388h
                mov     word ptr es:[di],03ffh
                mov     word ptr es:[di+2],03ffh
                call    beep
                pop     di
                pop     es
                ret
key4ofs:
                push    es
                push    di
                mov     di,memloc2
                push    cs:savedseg
                pop     es
                mov     word ptr es:[di],0e0ffh
                mov     word ptr es:[di+2],05f5h
                call    beep
                pop     di
                pop     es
                ret
key5ofs:
                push    bx
                push    cx
                push    es
                push    di
                push    cs:savedseg
                pop     es

                mov     di,142bh
                mov     cx,1438h-142bh
                call    moveit1

                mov     di,1329h
                mov     cx,132fh-1329h
                call    moveit1

                mov     di,1330h
                mov     cx,1332h-1330h
                call    moveit2

                mov     di,128bh
                mov     cx,12a4h-128bh
                call    moveit2

                mov     byte ptr es:[1314h],0ffh
                mov     byte ptr es:[1324h],0ffh
                mov     byte ptr es:[13beh],0ffh
                mov     byte ptr es:[13deh],0ffh
                mov     byte ptr es:[13dfh],0ffh
                mov     byte ptr es:[13fch],0ffh
                mov     byte ptr es:[140bh],0ffh
                mov     byte ptr es:[140ch],0ffh
                
                call    beep
                pop     di
                pop     es
                pop     cx
                pop     bx
                ret
                ret
moveit1:
                xor     bx,bx
moveit1x:
                mov     byte ptr es:[di+bx],0ffh
                inc     bx
                loop    moveit1x
                ret
moveit2:
                xor     bx,bx
moveit2x:
                mov     byte ptr es:[di+bx],64h
                inc     bx
                loop    moveit2x
                ret
mrateswitch:
                xor     byte ptr cs:movementon,1
                call    beep
                ret
incmrate:
                add     word ptr cs:x,1
                ret
decmrate:
                sub     word ptr cs:x,1
                ret
keyhomeofs:
                push    ax
                push    es
                push    di
                push    cs:savedseg
                pop     es
                mov     di,udmemloc
                mov     ax,word ptr cs:x
                sub     word ptr es:[di],ax
                mov     di,lrmemloc
                mov     ax,word ptr cs:x
                sub     word ptr es:[di],ax
                pop     di
                pop     es
                pop     ax
                ret
keyupofs:
                push    ax
                push    es
                push    di
                push    cs:savedseg
                pop     es
                mov     di,udmemloc
                mov     ax,word ptr cs:x
                sub     word ptr es:[di],ax
                pop     di
                pop     es
                pop     ax
                ret
keypgupofs:
                push    ax
                push    es
                push    di
                push    cs:savedseg
                pop     es
                mov     di,udmemloc
                mov     ax,word ptr cs:x
                sub     word ptr es:[di],ax
                mov     di,lrmemloc
                mov     ax,word ptr cs:x
                add     word ptr es:[di],ax
                pop     di
                pop     es
                pop     ax
                ret
keyleftofs:
                push    ax
                push    es
                push    di
                push    cs:savedseg
                pop     es
                mov     di,lrmemloc
                mov     ax,word ptr cs:x
                sub     word ptr es:[di],ax
                pop     di
                pop     es
                pop     ax
                ret
keyrightofs:
                push    ax
                push    es
                push    di
                push    cs:savedseg
                pop     es
                mov     di,lrmemloc
                mov     ax,word ptr cs:x
                add     word ptr es:[di],ax
                pop     di
                pop     es
                pop     ax
                ret
keyendofs:
                push    ax
                push    es
                push    di
                push    cs:savedseg
                pop     es
                mov     di,udmemloc
                mov     ax,word ptr cs:x
                add     word ptr es:[di],ax
                mov     di,lrmemloc
                mov     ax,word ptr cs:x
                sub     word ptr es:[di],ax
                pop     di
                pop     es
                pop     ax
                ret
keydownofs:
                push    ax
                push    es
                push    di
                push    cs:savedseg
                pop     es
                mov     di,udmemloc
                mov     ax,word ptr cs:x
                add     word ptr es:[di],ax
                pop     di
                pop     es
                pop     ax
                ret
keypgdnofs:
                push    ax
                push    es
                push    di
                push    cs:savedseg
                pop     es
                mov     di,udmemloc
                mov     ax,word ptr cs:x
                add     word ptr es:[di],ax
                mov     di,lrmemloc
                mov     ax,word ptr cs:x
                add     word ptr es:[di],ax
                pop     di
                pop     es
                pop     ax
                ret
menuroutine:
                call    popupmenu
                ret
toggleall:
                mov     byte ptr cs:nobeep,1
                push    bx
                push    cx
                push    si
                mov     bx,offset cs:key1
                mov     si,offset cs:optionson
                mov     cx,numoptions
cmpoption:
                cmp     byte ptr cs:[si],1
                jne     nextoption
                inc     bx
                call    word ptr cs:[bx]
                inc     si
                inc     bx
                inc     bx
                loop    cmpoption
                jmp     exittoggleall
nextoption:
                inc     bx
                inc     bx
                inc     bx
                inc     si
                loop    cmpoption
exittoggleall:
                pop     si
                pop     cx
                pop     bx
                mov     byte ptr cs:nobeep,0
                ret
newintbb        endp

;---------------------------------------------------------------
; Redirect interrupt 0cch.
;---------------------------------------------------------------
redirectcc      proc    near
                push    ax
                push    dx
                push    ds
                push    es
                mov     ax,35cch
                int     21h
                mov     word ptr cs:oldintcc,bx
                mov     word ptr cs:oldintcc+2,es
                push    cs
                pop     ds
                mov     dx,offset newintcc
                mov     ax,25cch
                int     21h
                pop     es
                pop     ds
                pop     dx
                pop     ax
                ret
redirectcc      endp

;---------------------------------------------------------------
; Set address of interrupt 0cch back to original.
;---------------------------------------------------------------
unredirectcc    proc    near
                push    ds
                lds     dx,dword ptr cs:oldintcc
                mov     ax,25cch
                int     21h
                pop     ds
                ret
unredirectcc    endp

;---------------------------------------------------------------
; New interrupt 0cch.
;---------------------------------------------------------------
newintcc        proc    near
                cmp     byte ptr cs:inplace,1
                jne     exitnewintcc
                cmp     byte ptr cs:infeng,1
                jne     exitnewintcc
                cmp     si,131ah-6
                je      doinfeng
                cmp     si,1352h-6
                je      doinfeng
                cmp     si,138ah-6
                jne     exitnewintcc
doinfeng:
                mov     byte ptr cs:nobeep,1
                call    key3ofs
                mov     byte ptr cs:nobeep,0
                iret
exitnewintcc:
                sub     [si+06h],ax
                iret
newintcc        endp

;---------------------------------------------------------------
; Redirect interrupt 0ddh.
;---------------------------------------------------------------
redirectdd      proc    near
                push    ax
                push    dx
                push    ds
                push    es
                mov     ax,35ddh
                int     21h
                mov     word ptr cs:oldintdd,bx
                mov     word ptr cs:oldintdd+2,es
                push    cs
                pop     ds
                mov     dx,offset newintdd
                mov     ax,25ddh
                int     21h
                pop     es
                pop     ds
                pop     dx
                pop     ax
                ret
redirectdd      endp

;---------------------------------------------------------------
; Set address of interrupt 0ddh back to original.
;---------------------------------------------------------------
unredirectdd    proc    near
                push    ds
                lds     dx,dword ptr cs:oldintdd
                mov     ax,25ddh
                int     21h
                pop     ds
                ret
unredirectdd    endp

;---------------------------------------------------------------
; New interrupt 0ddh.
;---------------------------------------------------------------
newintdd        proc    near
                cmp     byte ptr cs:inplace,1
                jne     exitnewintdd
                cmp     byte ptr cs:infmny,1
                jne     exitnewintdd
                cmp     di,16a4h
                jne     exitnewintdd
                iret
exitnewintdd:
                db      36h,0f3h,0a4h
                iret
newintdd        endp

;---------------------------------------------------------------
; Redirect interrupt 21h.
;---------------------------------------------------------------
redirect21      proc    near
                push    ax
                push    dx
                push    ds
                push    es
                mov     ax,3521h
                int     21h
                mov     word ptr cs:oldint21,bx
                mov     word ptr cs:oldint21+2,es
                push    cs
                pop     ds
                mov     dx,offset cs:newint21
                mov     ax,2521h
                int     21h
                pop     es
                pop     ds
                pop     dx
                pop     ax
                ret
redirect21      endp

;---------------------------------------------------------------
; Redirect interrupt 21h back to original.
;---------------------------------------------------------------
unredirect21    proc    near
                push    ds
                lds     dx,dword ptr cs:oldint21
                mov     ax,2521h
                int     21h
                pop     ds
                ret
unredirect21    endp

;---------------------------------------------------------------
; New interrupt 21h.
;---------------------------------------------------------------
newint21        proc    near
                push    bx
                push    di
                push    es
                cmp     byte ptr cs:inplace,1
                je      exitnewint21
                xor     di,di
                push    di
                pop     es
                or      di,24h
                cmp     word ptr es:[di],kbofs
                jne     exitnewint21
                push    word ptr es:[di+2]
                pop     es
                push    word ptr es:[76bdh]
                pop     cs:savedseg
                push    es
                pop     cs:savecseg
                mov     di,kbofs
searchkbcode:
                cmp     word ptr es:[di],60e4h
                jne     incdi
                jmp     changekbcode
incdi:
                inc     di
                jmp     searchkbcode
changekbcode:
                mov     word ptr es:[di],0bbcdh
                mov     word ptr es:[1db4h],0cccdh
                mov     byte ptr es:[1db6h],90h

                push    es
                push    di
                push    es
                pop     di
                add     di,0f3bh
                push    di
                pop     es
                mov     word ptr es:[1431h],0ddcdh
                mov     byte ptr es:[1433h],90h
                pop     di
                pop     es

                mov     byte ptr cs:inplace,1
                call    beep
exitnewint21:
                pop     es
                pop     di
                pop     bx
                jmp     dword ptr cs:oldint21
newint21        endp

;---------------------------------------------------------------
; Make a simple beep.
;---------------------------------------------------------------
beep            proc    near
                cmp     byte ptr cs:nobeep,1
                jne     yesbeep
                ret
yesbeep:
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
; Get a key from the keyboard.
;---------------------------------------------------------------
getkey          proc    near
                xor     ax,ax
                int     16h
                ret
getkey          endp

;---------------------------------------------------------------
; Turn on HSC player.
;---------------------------------------------------------------
playmode        proc    near
                push    ax
                push    bx
                push    es
                push    si
                mov     ah,0
                mov     bl,0
                mov     bh,0
                push    ds
                pop     es
                mov     si,offset ds:module
                push    cs
                call    hscplayer
                pop     si
                pop     es
                pop     bx
                pop     ax
                ret
playmode        endp

;---------------------------------------------------------------
; Turn off HSC player.
;---------------------------------------------------------------
stopfmm         proc    near
                push    ax
                mov     ah,2
                push    cs
                call    hscplayer
                pop     ax
                ret
stopfmm         endp

;---------------------------------------------------------------
; Pop-up menu
;---------------------------------------------------------------
popupmenu       proc    near
                push    ax
                push    ds
                push    es
                push    cs
                push    cs
                pop     es
                pop     ds
                in      al,21h
                mov     ah,al
                in      al,0a1h
                push    ax
                mov     al,0ffh
                out     21h,al
                out     0a1h,al
                cli
                call    showmenu
                call    writemenubar
                mov     byte ptr cs:menunum,0
                mov     byte ptr cs:exitpopup,0
getnextkey:
                in      al,60h
                cmp     byte ptr cs:exitpopup,1
                je      exitpopupmenu
                cmp     al,exitkey
                je      exitpopupmenu
                call    dopopupmenu
                jmp     getnextkey
exitpopupmenu:
                call    restorescr
                pop     ax
                out     0a1h,al
                mov     al,ah
                out     21h,al
                sti
                pop     es
                pop     ds
                pop     ax
                mov     al,0ffh
                sti
                ret
popupmenu       endp

;---------------------------------------------------------------
; Write available menu options
;---------------------------------------------------------------
writemenubar    proc    near
                push    ax
                push    es
                push    di
                push    si
                push    cx
                mov     cx,numpopups
                mov     di,0
                mov     si,offset cs:popupoptions
                mov     ax,colorscr
                mov     es,ax
writepopups:
                call    writespace
                call    writespace
                call    putxystr
                push    di
                call    writespace
                pop     di
                loop    writepopups
                call    wipemiddle
                pop     cx
                pop     si
                pop     di
                pop     es
                pop     ax
                ret
writemenubar    endp
                         
;---------------------------------------------------------------
; Wipe out middle of screen.
;---------------------------------------------------------------
wipemiddle      proc    near
                push    ax
                push    bx
                push    cx
                push    si
                push    di
                push    dx
                push    ds
                push    es
                mov     ax,colorscr
                mov     es,ax
                push    cs
                pop     ds
                mov     dh,2
                mov     dl,1
                call    calscraddr
                mov     cx,wipescrsize
                mov     al,'°'
                mov     bl,midcolor
wipescr:
                call    writechar
                loop    wipescr
                pop     es
                pop     ds
                pop     dx
                pop     di
                pop     si
                pop     cx
                pop     bx
                pop     ax
                ret
wipemiddle      endp

;---------------------------------------------------------------
; Write available menu options
;---------------------------------------------------------------
hilitemenubar   proc    near
                push    ax
                push    es
                push    di
                push    si
                push    cx
                mov     cx,numpopups
                mov     di,0
                mov     si,offset cs:popupoptions
                mov     ax,colorscr
                mov     es,ax
                mov     al,1
hilitepopups:
                add     di,2
                call    writespace
                cmp     al,byte ptr cs:menunum
                jne     regular
                mov     bh,80
                call    hilitestr
                sub     di,2
                jmp     exithilite
regular:
                call    putxystr
exithilite:
                inc     al
                loop    hilitepopups
                pop     cx
                pop     si
                pop     di
                pop     es
                pop     ax
                ret
hilitemenubar   endp

;---------------------------------------------------------------
; Do pop-up menu routines
;---------------------------------------------------------------
dopopupmenu     proc    near
                cli
                push    ax
                push    bx
                push    cx
                push    si
                push    es
                cmp     al,16
                jne     checkif18
                cmp     byte ptr cs:menunum,4
                je      jumptoexitpop
                mov     byte ptr cs:menunum,4
                jmp     domenurtx
checkif18:
                cmp     al,18
                jne     checkif31
                cmp     byte ptr cs:menunum,3
                je      jumptoexitpop
                mov     byte ptr cs:menunum,3
                jmp     domenurtx
checkif31:
                cmp     al,31
                jne     checkif35
                cmp     byte ptr cs:menunum,2
                je      jumptoexitpop
                mov     byte ptr cs:menunum,2
                jmp     domenurtx
checkif35:
                cmp     al,35
                jne     checkifleft
                cmp     byte ptr cs:menunum,1
                je      jumptoexitpop
                mov     byte ptr cs:menunum,1
domenurtx:
                call    getmenuaddr
                call    hilitemenubar
                call    domenurt
                call    nextkey
                jmp     exitdopopup
domenurt:
                mov     byte ptr cs:menuitem,1
                call    framemenu
                call    writeopts
                ret
jumptoexitpop:
                jmp     exitdopopup
checkifleft:
                cmp     al,75
                jne     checkifright
                dec     byte ptr cs:menunum
                cmp     byte ptr cs:menunum,0
                jg      doright
                mov     byte ptr cs:menunum,numpopups
                jmp     doright
checkifright:
                cmp     al,77
                jne     checkifdownx
                inc     byte ptr cs:menunum
                cmp     byte ptr cs:menunum,numpopups
                jle     doright
                mov     byte ptr cs:menunum,1
doright:
                call    writemenubar
                jmp     domenurtx
checkifdownx:
                cmp     byte ptr cs:menunum,0
                je      checkiff1
                cmp     al,80
                jne     checkifupx
                inc     byte ptr cs:menuitem
                call    getmenuaddr
                mov     ah,byte ptr cs:[si+2]
                cmp     byte ptr cs:menuitem,ah
                jle     doupdown
                mov     byte ptr cs:menuitem,1
                jmp     doupdown
checkifupx:
                cmp     al,72
                jne     checkifreturn
                dec     byte ptr cs:menuitem
                call    getmenuaddr
                mov     ah,byte ptr cs:[si+2]
                cmp     byte ptr cs:menuitem,0
                jg      doupdown
                mov     byte ptr cs:menuitem,ah
doupdown:
                call    writeopts
                call    nextkey
                jmp     exitdopopup
checkifreturn:
                cmp     al,28
                jne     checkiff1
                call    domenuitem
                call    nextkey
                jmp     exitdopopup
checkiff1:
                cmp     al,3bh
                jne     checkiff2
                push    word ptr cs:menunum
                mov     byte ptr cs:menunum,1
                mov     byte ptr cs:menuitem,1
                call    domenuitem
                pop     word ptr cs:menunum
                call    nextkey
                jmp     exitdopopup
checkiff2:
                cmp     al,3ch
                jne     checkiff3
                push    word ptr cs:menunum
                mov     byte ptr cs:menunum,1
                mov     byte ptr cs:menuitem,2
                call    domenuitem
                pop     word ptr cs:menunum
                call    nextkey
                jmp     exitdopopup
checkiff3:
                cmp     al,3dh
                jne     exitdopopup
                push    word ptr cs:menunum
                mov     byte ptr cs:menunum,2
                mov     byte ptr cs:menuitem,1
                call    domenuitem
                pop     word ptr cs:menunum
                call    nextkey
exitdopopup:
                pop     es
                pop     si
                pop     cx
                pop     bx
                pop     ax
                ret
dopopupmenu     endp

;---------------------------------------------------------------
; Do menu options
;---------------------------------------------------------------
domenuitem      proc    near
                push    ax
                push    bx
                push    si
                mov     si,offset cs:menuitems
                xor     ax,ax
                mov     al,byte ptr cs:menunum
                dec     al
                mov     cl,menusize
                shl     ax,cl
                mov     bl,byte ptr cs:menuitem
                dec     bl
                shl     bx,1
                add     ax,bx
                add     si,ax
                mov     bx,word ptr cs:[si]
                call    bx
                pop     si
                pop     bx
                pop     ax
                ret
domenuitem      endp

;---------------------------------------------------------------
; Do exit routine
;---------------------------------------------------------------
setexitkey      proc    near
                mov     byte ptr cs:exitpopup,1
                ret
setexitkey      endp

;---------------------------------------------------------------
; Do nothing routine
;---------------------------------------------------------------
dummyproc       proc    near
                ret
dummyproc       endp

;---------------------------------------------------------------
; Do nothing routine
;---------------------------------------------------------------
testproc        proc    near
                call    beep
                ret
testproc        endp

;---------------------------------------------------------------
; Get address of menu
;---------------------------------------------------------------
getmenuaddr     proc    near
                cmp     byte ptr cs:menunum,1
                jne     setmenu2
                mov     si,offset cs:menu1
                mov     byte ptr cs:menunum,1
                jmp     exitgetmenu
setmenu2:
                cmp     byte ptr cs:menunum,2
                jne     setmenu3
                mov     si,offset cs:menu2
                mov     byte ptr cs:menunum,2
                jmp     exitgetmenu
setmenu3:
                cmp     byte ptr cs:menunum,3
                jne     setmenu4
                mov     si,offset cs:menu3
                mov     byte ptr cs:menunum,3
                jmp     exitgetmenu
setmenu4:
                cmp     byte ptr cs:menunum,4
                jne     exitgetmenu
                mov     si,offset cs:menu4
                mov     byte ptr cs:menunum,4
exitgetmenu:
                ret
getmenuaddr     endp

;---------------------------------------------------------------
; Write pull-down menu options
;---------------------------------------------------------------
writeopts       proc    near
                cli
                push    ax
                push    dx
                push    cx
                push    si
                push    di
                mov     dh,byte ptr cs:[si+1]
                xor     cx,cx
                mov     cl,byte ptr cs:[si+2]
                mov     dl,byte ptr cs:[si]
                add     si,4
                inc     dh
                add     dl,3
                mov     al,1
                call    calscraddr
writeoptsloop:
                cmp     al,byte ptr cs:menuitem
                jne     writeit
                push    bx
                mov     bh,80
                call    hilitestr
                pop     bx
                jmp     donextstr
writeit:
                push    bx
                mov     bh,0
                call    hilitestr
                pop     bx
donextstr:
                inc     dh
                call    calscraddr
                inc     al
                loop    writeoptsloop
                pop     di
                pop     si
                pop     cx
                pop     dx
                pop     ax
                sti
                ret
writeopts       endp

;---------------------------------------------------------------
; Write a space
;---------------------------------------------------------------
writespace      proc    near
                push    ax
                push    bx
                mov     al,' '
                mov     bl,tbc
                call    writechar
                pop     bx
                pop     ax
                ret
writespace      endp

;---------------------------------------------------------------
; write a character at x,y
;---------------------------------------------------------------
writechar       proc    near
                push    ax
                push    bx
                stosb
                mov     al,bl
                stosb
                pop     bx
                pop     ax
                ret
writechar       endp

;---------------------------------------------------------------
; write aand highlight a string at x,y
;---------------------------------------------------------------
hilitestr       proc    near
                push    ax
                push    bx
                push    ds
                push    es
                push    cs
                pop     ds
                mov     ax,colorscr
                mov     es,ax
                sub     di,2
                mov     al,' '
                mov     bl,tbc
                sub     bl,bh
                call    writechar
                lodsb
                mov     bl,fcc
                sub     bl,bh
                call    writechar
hiliteanother:
                lodsb
                cmp     al,0
                je      exithilitex
                mov     bl,tbc
                sub     bl,bh
                call    writechar
                jmp     hiliteanother
exithilitex:
                mov     al,' '
                mov     bl,tbc
                sub     bl,bh
                call    writechar
                pop     es
                pop     ds
                pop     bx
                pop     ax
                ret
hilitestr       endp

;---------------------------------------------------------------
; write a string at x,y
;---------------------------------------------------------------
putxystr        proc    near
                push    ax
                push    bx
                push    ds
                push    es
                push    cs
                pop     ds
                mov     ax,colorscr
                mov     es,ax
                lodsb
                mov     bl,fcc
                call    writechar
loadanother:
                lodsb
                cmp     al,0
                je      exitshowkeys
                mov     bl,tbc
                call    writechar
                jmp     loadanother
exitshowkeys:
                pop     es
                pop     ds
                pop     bx
                pop     ax
                ret
putxystr        endp

;---------------------------------------------------------------
; Get next key
;---------------------------------------------------------------
nextkey         proc    near
                push    ax
                xchg    al,ah
getnkey:
                in      al,60h
                cmp     al,ah
                je      getnkey
                pop     ax
                ret
nextkey         endp

;---------------------------------------------------------------
;  Frame a pull down menu
;---------------------------------------------------------------
framemenu       proc    near
                call    wipemiddle
                call    drawframe
                ret
framemenu       endp

;---------------------------------------------------------------
; Take X,Y in DX and calculate & return absolute address in DI
;---------------------------------------------------------------
calscraddr      proc    near
                push    ax
                push    bx
                push    cx
                push    dx
                xor     ax,ax
                xor     cx,cx
                xor     bx,bx
                xor     di,di
                mov     al,dh
                dec     al
                mov     bl,dl
                mov     di,bx
                dec     di
                mov     bx,80
                mul     bx
                add     di,ax
                shl     di,1
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret
calscraddr      endp

;---------------------------------------------------------------
; Draw top section of pull down menu
;---------------------------------------------------------------
drawtopbar      proc    near
                call    writespace                      ; write a space
                mov     al,byte ptr cs:menuchars        ; write 'Ú'
                mov     bl,tbc
                call    writechar
                mov     al,byte ptr cs:menuchars+2      ; write XX of 'Ä'
                mov     byte ptr cs:item,al
                mov     byte ptr cs:itemcolor,tbc
                call    writemiddle
                mov     al,byte ptr cs:menuchars+1      ; write '¿'
                mov     bl,tbc
                call    writechar
                call    writespace                      ; write a space
                ret
drawtopbar      endp

;---------------------------------------------------------------
; Draw middle section of pull down menu
;---------------------------------------------------------------
drawmidbars     proc    near
                mov     dl,byte ptr cs:[si]
                mov     dh,byte ptr cs:[si+1]
writemidscr:
                inc     dh                              ; calc. next row addr.
                call    calscraddr
                call    writespace                      ; write a space
                mov     al,byte ptr cs:menuchars+3      ; write a '³'
                mov     bl,tbc
                call    writechar
                mov     byte ptr cs:item,' '            ; write XX of space
                mov     byte ptr cs:itemcolor,tbc
                call    writemiddle
                mov     al,byte ptr cs:menuchars+3      ; write '³'
                mov     bl,tbc
                call    writechar
                call    writespace                      ; write a space
                mov     al,' '                          ; do shadow
                mov     bl,6
                call    writechar
                mov     al,' '                          ; do shadow
                mov     bl,6
                call    writechar
                loop    writemidscr
                ret
drawmidbars     endp

;---------------------------------------------------------------
; Draw bottom section of pull down menu
;---------------------------------------------------------------
drawbottombar   proc    near
                mov     dl,byte ptr cs:[si]             ; calc. addr. of (1,y+1)
                call    calscraddr
                call    writespace                      ; write a space
                mov     al,byte ptr cs:menuchars+4      ; write a 'À'
                mov     bl,tbc
                call    writechar
                mov     al,byte ptr cs:menuchars+2      ; write XX of 'Ä'
                mov     byte ptr cs:item,al
                mov     byte ptr cs:itemcolor,tbc
                call    writemiddle
                mov     al,byte ptr cs:menuchars+5      ; write a 'Ù'
                mov     bl,tbc
                call    writechar
                call    writespace                      ; write a space
                mov     dl,byte ptr cs:[si]             ; calc. addr. of shadow
                add     dl,2
                inc     dh
                call    calscraddr
                mov     byte ptr cs:item,' '            ; do shadow
                mov     byte ptr cs:itemcolor,6
                call    writemiddle
                push    cx
                mov     cx,4
doshadow:
                mov     al,' '                          ; do shadow
                mov     bl,6
                call    writechar
                loop    doshadow
                pop     cx
                ret
drawbottombar   endp

;---------------------------------------------------------------
; Draw pull down menu frame
;---------------------------------------------------------------
drawframe       proc    near
                push    ax                              ; save registers
                push    bx
                push    cx
                push    dx
                push    di
                push    es
                mov     cx,colorscr
                mov     es,cx
                xor     cx,cx
                mov     dl,byte ptr cs:[si]             ; column, x
                mov     dh,byte ptr cs:[si+1]           ; row, y
                mov     cl,byte ptr cs:[si+2]           ; how many menu items
                add     cl,1
                call    calscraddr                      ; calculate abs. addr.
                call    drawtopbar                      ; draw top section
                call    drawmidbars
                call    drawbottombar
                pop     es
                pop     di                              ; restore registers
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret
drawframe       endp

;---------------------------------------------------------------
; Write XX characters
;---------------------------------------------------------------
writemiddle     proc    near
                push    ax
                push    bx
                push    cx
                mov     al,byte ptr cs:item
                mov     bl,byte ptr cs:itemcolor
                xor     cx,cx
                mov     cl,byte ptr cs:[si+3]
writetopbar:
                call    writechar
                loop    writetopbar
                pop     cx
                pop     bx
                pop     ax
                ret
writemiddle     endp

;---------------------------------------------------------------
; Get address of original interrupt 10h
;---------------------------------------------------------------
getint10        proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                mov     bx,es:[40h]
                mov     word ptr cs:oldint10,bx
                mov     bx,es:[42h]
                mov     word ptr cs:oldint10+2,bx
                pop     es
                pop     bx
                ret
getint10        endp

;---------------------------------------------------------------
; Show status menu inside game
;---------------------------------------------------------------
showmenu        proc    near
                cli
                call    scroff
                call    swapint10
                call    savevgastat
                call    stablescr
                call    savetextscr
                call    savecurrentmode
                call    setnewmode
                mov     byte ptr cs:cursoron,1
                call    cursoronoff
                call    swapscr
                call    scron
                sti
                ret
showmenu        endp

;---------------------------------------------------------------
; Get current mode
;---------------------------------------------------------------
savecurrentmode proc    near
                push    ax
                mov     ax,0f00h
                int     10h
                xor     ah,ah
                push    ax
                pop     cs:currentmode
                pop     ax
                ret
savecurrentmode endp

;---------------------------------------------------------------
; Set to new mode
;---------------------------------------------------------------
setnewmode      proc    near
                push    ax
                mov     ax,83h
                int     10h
                pop     ax
                ret
setnewmode      endp

;---------------------------------------------------------------
; Set mode back to original
;---------------------------------------------------------------
restoremode     proc    near
                push    ax
                push    cs:currentmode
                pop     ax
                or      al,80h
                int     10h
                pop     ax
                ret
restoremode     endp

;---------------------------------------------------------------
; Save VGA registers
;---------------------------------------------------------------
savevgastat     proc    near
                push    ax
                push    bx
                push    cx
                mov     ax,1c01h
                mov     cx,7
                mov     bx,offset cs:savestatarea
                int     10h
                pop     cx
                pop     bx
                pop     ax
                ret
savevgastat     endp

;---------------------------------------------------------------
; Save text screen
;---------------------------------------------------------------
savetextscr     proc    near
                push    ax
                push    cx
                push    si
                push    di
                push    ds
                push    es
                mov     ax,colorscr
                mov     ds,ax
                push    cs
                pop     es
                mov     cx,savenumbytes
                xor     si,si
                mov     di,offset cs:savescr
                rep     movsw
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     cx
                pop     ax
                ret
savetextscr     endp

;---------------------------------------------------------------
; Swap text screens
;---------------------------------------------------------------
swapscr         proc    near
                push    ax
                push    cx
                push    si
                push    di
                push    ds
                push    es
                push    cs
                pop     ds
                mov     ax,colorscr
                mov     es,ax
                mov     si,offset cs:trainerscr
                xor     di,di
                mov     cx,textscrsize
                cld
swapit:
                mov     ax,[si]
                xchg    ax,es:[di]
                mov     [si],ax
                add     si,2
                add     di,2
                loop    swapit
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     cx
                pop     ax
                ret
swapscr         endp

;---------------------------------------------------------------
; Restore original screen
;---------------------------------------------------------------
restorescr      proc    near
                cli
                call    scroff
                call    swapscr
                mov     byte ptr cs:cursoron,0
                call    cursoronoff
                call    restoremode
                call    stablescr
                call    restoretextscr
                call    restorevgastat
                call    swapint10
                call    scron
                sti
                ret
restorescr      endp

;---------------------------------------------------------------
; Turn off/on cursor
;---------------------------------------------------------------
cursoronoff     proc    near
                push    ax
                push    bx
                push    cx
                push    dx
                cmp     byte ptr cs:cursoron,1
                jne     cursoroff
                mov     ax,20h
                jmp     setcursor
cursoroff:
                xor     ax,ax
setcursor:
                push    ax
                mov     ah,3
                xor     bx,bx
                int     10h
                pop     ax
                and     ch,1fh
                or      ch,al
                mov     ah,1
                int     10h
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret
cursoronoff     endp

;---------------------------------------------------------------
; Restore VGA registers
;---------------------------------------------------------------
restorevgastat  proc    near
                push    ax
                push    bx
                push    cx
                mov     ax,1c02h
                mov     cx,7
                mov     bx,offset cs:savestatarea
                int     10h
                pop     cx
                pop     bx
                pop     ax
                ret
restorevgastat  endp

;---------------------------------------------------------------
; Restore text screen
;---------------------------------------------------------------
restoretextscr  proc    near
                push    cx
                push    si
                push    di
                push    es
                push    ds
                mov     cx,colorscr
                mov     es,cx
                push    cs
                pop     ds
                xor     di,di
                mov     cx,savenumbytes
                mov     si,offset cs:savescr
                rep     movsw
                pop     ds
                pop     es
                pop     di
                pop     si
                pop     cx
                ret
restoretextscr  endp

;---------------------------------------------------------------
; Swap current interrupt 10h with original
;---------------------------------------------------------------
swapint10       proc    near
                push    ax
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                mov     ax,word ptr cs:oldint10
                xchg    ax,es:[40h]
                mov     word ptr cs:oldint10,ax
                mov     ax,word ptr cs:oldint10+2
                xchg    ax,es:[42h]
                mov     word ptr cs:oldint10+2,ax
                pop     es
                pop     bx
                pop     ax
                ret
swapint10       endp

;---------------------------------------------------------------
; Blank screen
;---------------------------------------------------------------
scroff          proc    near
                push    ax
                push    dx
                mov     al,1
                mov     dx,3c4h
                out     dx,al
                inc     dx
                in      al,dx
                or      al,20h
                out     dx,al
                pop     dx
                pop     ax
                ret
scroff          endp

;---------------------------------------------------------------
; Turn screen on
;---------------------------------------------------------------
scron           proc    near
                push    ax
                push    dx
                mov     al,1
                mov     dx,3c4h
                out     dx,al
                inc     dx
                in      al,dx
                and     al,0dfh
                out     dx,al
                pop     dx
                pop     ax
                ret
scron           endp

;---------------------------------------------------------------
; Steady screen
;---------------------------------------------------------------
stablescr       proc    near
                push    ax
                push    dx
                mov     dx,3c4h
                mov     ax,402h
                out     dx,ax
                mov     dx,3ceh
                mov     ax,0ff08h
                out     dx,ax
                mov     dx,3c4h
                mov     ax,704h
                out     dx,ax
                mov     dx,3ceh
                mov     ax,0c06h
                out     dx,ax
                mov     ax,204h
                out     dx,ax
                mov     ax,5
                out     dx,ax
                pop     dx
                pop     ax
                ret
stablescr       endp

;---------------------------------------------------------------
; Write a key to mode 13h.
;---------------------------------------------------------------
writech         proc    near
                push    bx
                push    cx
                push    si
                push    di
                push    ds
                push    es
                push    0a000h
                pop     es
                mov     si,offset cs:font
                mov     al,byte ptr cs:[bx]
                sub     al,' '
                or      al,al
                jnz     writechx
                jmp     exitwritech
writechx:
                push    cs
                pop     ds
                xor     ch,ch
                mov     cl,al
setindex:
                add     si,25
                loop    setindex
                mov     cx,5
                mov     bx,4
setpixel:
                push    di
                push    cx
                mov     cx,5
loadbyte:
                lodsb
                cmp     al,1
                jne     incdi2
                push    si
                mov     si,offset cs:charcolors
                cmp     byte ptr cs:inkey,1
                je      checkerase
                cmp     byte ptr cs:xerase,1
                jne     normal
                jmp     erasec
checkerase:
                cmp     byte ptr cs:erase,1
                jne     normal
erasec:
                mov     si,offset cs:erasecolors
normal:
                mov     al,byte ptr cs:[si+bx]
                pop     si
                mov     byte ptr es:[di],al
incdi2:
                inc     di
setit:
                loop    loadbyte
                pop     cx
                pop     di
                add     di,320
                dec     bx
                loop    setpixel
exitwritech:
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     cx
                pop     bx
                ret
writech         endp

;---------------------------------------------------------------
; Write a string to mode 13h.
;---------------------------------------------------------------
putstr          proc    near
                push    di
                push    cx
                call    calculatedi
putch:
                cmp     byte ptr cs:[bx],0
                je      exitputstr
                call    writech
                inc     bx
                add     di,6
                jmp     putch
exitputstr:
                pop     cx
                pop     di
                ret
putstr          endp

;---------------------------------------------------------------
; Calculate ES:DI
;---------------------------------------------------------------
calculatedi     proc    near
                push    cx
                mov     cx,word ptr cs:currenty
                xor     di,di
calculatey:
                add     di,320
                loop    calculatey
                add     di,word ptr cs:currentx
                pop     cx
                ret
calculatedi     endp

;---------------------------------------------------------------
; Draw a highlight bar
;---------------------------------------------------------------
drawbar         proc    near
                push    es
                push    di
                push    cx
                mov     di,0a000h
                mov     es,di
                push    word ptr cs:currentx
                push    word ptr cs:currenty
                push    word ptr cs:barx
                push    word ptr cs:bary
                pop     word ptr cs:currenty
                pop     word ptr cs:currentx
                call    calculatedi
                sub     di,321
                mov     cx,7
drawhbar:
                push    ax
                push    cx
                push    di
                mov     cx,barlength
                cmp     byte ptr cs:barerase,1
                je      seterasebar
                mov     al,barcolor
                jmp     putbarpixel
seterasebar:
                mov     al,erasebarcolor
putbarpixel:
                cmp     byte ptr es:[di],22
                jae     checknpixel
                jmp     putpixel
checknpixel:
                cmp     byte ptr es:[di],26
                jbe     getnextpixel
putpixel:
                mov     byte ptr es:[di],al
getnextpixel:
                inc     di
                loop    putbarpixel
                pop     di
                pop     cx
                pop     ax
                add     di,320
                loop    drawhbar
                pop     word ptr cs:currenty
                pop     word ptr cs:currentx
                pop     cx
                pop     di
                pop     es
                ret
drawbar         endp

;---------------------------------------------------------------
; Redirect interrupt 1ch.
;---------------------------------------------------------------
redirect1c      proc    near
                push    ax
                push    dx
                push    ds
                push    es
                mov     ax,351ch
                int     21h
                mov     word ptr cs:oldint1c,bx
                mov     word ptr cs:oldint1c+2,es
                push    cs
                pop     ds
                mov     dx,offset cs:newint1c
                mov     ax,251ch
                int     21h
                pop     es
                pop     ds
                pop     dx
                pop     ax
                ret
redirect1c      endp

;---------------------------------------------------------------
; Redirect interrupt 1ch back to original.
;---------------------------------------------------------------
unredirect1c    proc    near
                push    ax
                push    dx
                push    ds
                lds     dx,dword ptr cs:oldint1c
                mov     ax,251ch
                int     21h
                pop     ds
                pop     dx
                pop     ax
                ret
unredirect1c    endp

;---------------------------------------------------------------
; New interrupt 1ch.
;---------------------------------------------------------------
newint1c        proc    near
                cli
                push    bx
                push    cs:currenty
                push    cs:currentx
                cmp     byte ptr cs:inkey,1
                je      exitnewint1c
                mov     cs:currentx,scrollx
                mov     cs:currenty,scrolly
                inc     word ptr cs:counter
                cmp     word ptr cs:counter,delay
                jl      exitnewint1c
                push    bx
                mov     bx,word ptr cs:currentstr
                call    putstr
                pop     bx
                mov     word ptr cs:counter,20h
                xor     byte ptr cs:xerase,1
                cmp     byte ptr cs:xerase,1
                jne     cont
                mov     word ptr cs:counter,0
cont:
                inc     byte ptr cs:xtimes
                cmp     byte ptr cs:xtimes,1
                jle     exitnewint1c
                mov     byte ptr cs:xtimes,0
                add     word ptr cs:currentstr,strlen
                mov     bx,offset cs:credit
                push    cx
                mov     cx,numlines-1
addlines:
                add     bx,strlen
                loop    addlines
                pop     cx
                cmp     word ptr cs:currentstr,bx
                jle     exitnewint1c
                push    offset cs:credit
                pop     word ptr cs:currentstr
exitnewint1c:
                pop     cs:currentx
                pop     cs:currenty
                pop     bx
                jmp     dword ptr cs:oldint1c
newint1c        endp

;---------------------------------------------------------------
; Do intro routine
;---------------------------------------------------------------
dointro         proc    near
                call    showpic
                push    offset cs:options
                pop     word ptr cs:coptions
                call    writeoptions
                push    bx
                mov     cs:currenty,scrolly
                mov     cs:currentx,scrollx
                mov     cs:counter,34h
                mov     bx,word ptr cs:currentstr
                call    putstr
                pop     bx
                mov     cs:currenty,offony
                mov     cs:currentx,offonx
                call    drawbar
                call    redirect1c
waitforkey:
                mov     ah,1
                int     16h
                jnz     getcheckkey
                mov     byte ptr cs:inkey,0
                call    vrtretrace
                jmp     waitforkey
getcheckkey:
                call    getkey
                cmp     ax,up
                jne     checkifdown
                call    doupkey
checkifdown:
                cmp     ax,down
                jne     checkifspace
                call    dodownkey
checkifspace:
                cmp     ax,space
                jne     checkifexit
                call    dospacekey
checkifexit:
                cmp     ax,esckey
                jne     checkifenter
                mov     byte ptr cs:exitprogf,1
                jmp     exitdointro
checkifenter:
                cmp     al,cr
                jne     waitforkey
exitdointro:
                call    unredirect1c
                ret
dointro         endp

;---------------------------------------------------------------
; Display the options.
;---------------------------------------------------------------
writeoptions    proc    near
                push    ax
                push    bx
                push    cx
                push    di
                mov     word ptr cs:currenty,optiony
                mov     word ptr cs:currentx,optionx
                mov     bx,cs:optionsptr
                mov     cx,cs:curnumopts
                add     cx,extraopt
writeoption:
                call    putstr
                push    word ptr cs:currentx
                add     word ptr cs:currentx,27
                inc     bx
                call    putstr
                pop     word ptr cs:currentx
                add     word ptr cs:currenty,11
                inc     bx
                loop    writeoption
                pop     di
                pop     cx
                pop     bx
                pop     ax
                ret
writeoptions    endp

;---------------------------------------------------------------
; Erase scroll bar
;---------------------------------------------------------------
erasebar        proc    near
                mov     byte ptr cs:barerase,1
                call    drawbar
                mov     byte ptr cs:barerase,0
                ret
erasebar        endp

;---------------------------------------------------------------
; Execute up key routine.
;---------------------------------------------------------------
doupkey         proc    near
                push    ax
                mov     byte ptr cs:inkey,1
                call    erasebar
                cmp     byte ptr cs:currentopt,1
                jg      deccolor
                mov     cs:curnumopts,numoptions
                mov     ax,cs:curnumopts
                mov     byte ptr cs:currentopt,al
                push    cx
                push    di
                mov     cx,ax
                dec     cx
                mov     di,offony
adddi11:
                add     di,11
                loop    adddi11
                mov     cs:currenty2,di
                mov     cs:bary,di
                pop     di
                pop     cx
                jmp     exitupkey
deccolor:
                dec     byte ptr cs:currentopt
                sub     cs:currenty2,11
                sub     cs:bary,11
exitupkey:
                call    drawbar
                pop     ax
                ret
doupkey         endp

;---------------------------------------------------------------
; Execute down key routine.
;---------------------------------------------------------------
dodownkey       proc    near
                push    ax
                mov     byte ptr cs:inkey,1
                call    erasebar
                mov     ax,cs:curnumopts
                cmp     byte ptr cs:currentopt,al
                jl      inccolor
                mov     cs:currenty2,offony
                mov     cs:bary,baryc
                mov     byte ptr cs:currentopt,1
                jmp     exitdownkey
inccolor:
                inc     byte ptr cs:currentopt
                add     cs:currenty2,11
                add     cs:bary,11
exitdownkey:
                call    drawbar
                pop     ax
                ret
dodownkey       endp

;---------------------------------------------------------------
; Execute space key routine.
;---------------------------------------------------------------
dospacekey      proc    near
                mov     byte ptr cs:inkey,1
                push    ax
                push    bx
                push    si
                push    ds
                push    cs
                pop     ds
                mov     al,byte ptr cs:erase
                push    cs:currentx
                push    cs:currenty
                mov     si,offset cs:optionson
                xor     bh,bh
                mov     bl,byte ptr cs:currentopt
                dec     bl
                mov     cs:currentx,offonx
                push    cs:currenty2
                pop     cs:currenty
                call    calculatedi
                xor     byte ptr cs:[si+bx],1
                cmp     byte ptr cs:[si+bx],1
                jne     minussign
                mov     byte ptr cs:erase,1
                mov     bx,offset cs:minus
                call    writech
                mov     byte ptr cs:erase,0
                mov     bx,offset cs:plus
                call    writech
                jmp     exitspacekey
minussign:
                mov     byte ptr cs:erase,1
                mov     bx,offset cs:plus
                call    writech
                mov     byte ptr cs:erase,0
                mov     bx,offset cs:minus
                call    writech
exitspacekey:
                mov     byte ptr cs:erase,al
                call    dodownkey
                pop     cs:currenty
                pop     cs:currentx
                pop     ds
                pop     si
                pop     bx
                pop     ax
                ret
dospacekey      endp

;---------------------------------------------------------------
; Check until vertical retrace is finished.
;---------------------------------------------------------------
vrtretrace      proc    near
                push    ax
                push    dx
                mov     dx,3dah
vrtwait:
                in      al,dx
                and     al,8
                jz      vrtwait
vrtwait2:
                in      al,dx
                and     al,8
                jnz     vrtwait2
                pop     dx
                pop     ax
                retn
vrtretrace      endp

;---------------------------------------------------------------
; Set mode to.
;---------------------------------------------------------------
setmode         proc    near
                push    ax
                push    dx
                push    bp
                mov     bp,sp
                xor     ah,ah
                mov     al,byte ptr [bp+8]
                int     10h
                pop     bp
                pop     dx
                pop     ax
                ret     2
setmode         endp

;---------------------------------------------------------------
; Show graphic menu interface.
;---------------------------------------------------------------
showpic         proc    near
                push    ax
                push    di
                push    si
                push    cx
                push    ds
                push    es
                push    13h
                call    setmode
                call    setpalette
                push    cs
                pop     ds
                mov     cx,cs:sizeofintro
                mov     ax,vgaseg
                mov     es,ax
                mov     si,offset introscr
                xor     di,di
writepixels:
                push    cx
                xor     ch,ch
                mov     cl,byte ptr ds:[si]
                xor     ah,ah
                mov     al,byte ptr ds:[si+1]
                rep     stosb
                add     si,2
                pop     cx
                loop    writepixels
                pop     es
                pop     ds
                pop     cx
                pop     si
                pop     di
                pop     ax
                ret
showpic         endp

;---------------------------------------------------------------
; Set palettes to.
;---------------------------------------------------------------
setpalette      proc    near
                push    ax
                push    cx
                push    dx
                push    si
                mov     cx,100h
                mov     si,offset cs:palette
changepal:
                mov     al,byte ptr cs:[si]
                mov     dx,3c8h
                out     dx,al
                inc     dx
                inc     si
                push    cx
                mov     cx,3
changec:
                mov     al,byte ptr cs:[si]
                out     dx,al
                inc     si
                loop    changec
                pop     cx
                loop    changepal
                pop     si
                pop     dx
                pop     cx
                pop     ax
                ret
setpalette      endp

;---------------------------------------------------------------
; Data - Variables
;---------------------------------------------------------------
barerase        db      0                       ; indicate if bar is to be erase
exitprogf       db      0                       ; indicate if exit program
minus           db      '-'                     ; '-'
plus            db      '+'                     ; '+'
currentx2       dw      offonx
currenty2       dw      optiony
barx            dw      barxc
bary            dw      baryc
coptions        dw      offset cs:options
xerase          db      0
erase           db      0
currentstr      dw      offset cs:credit
currentopt      db      1
counter         dw      delay-2
xtimes          db      0
inkey           db      0
currentx        dw      0
currenty        dw      0
currentoption   db      1
sizeofintro     dw      introsize
oldint1c        dd      0
options         db      '  F1',0,'Infinite energy       +',0
                db      '  F2',0,'Infinite money        +',0
                db      '  F3',0,'Maximize energy       +',0
                db      '  F4',0,'Maximize money        +',0
                db      '  F5',0,'Status, armor, etc.   +',0
                db      '  F8',0,'Rapid movement toggle +',0
                db      '    ',0,'                       ',0
                db      '  F6',0,'Pop-up help menu       ',0
                db      '  F7',0,'Activate all + selected',0
                db      '  F9',0,'Increase movement rate ',0
                db      ' F10',0,'Decrease movement rate ',0
optionsptr      dw      offset cs:options
curnumopts      dw      numoptions
credit          db      '   Genesis proudly presents an interactive trainer  ',0
                db      '        for Knights of Xentar by Code Breaker       ',0
                db      '   Genesis Genesis Genesis Genesis Genesis Genesis  ',0
                db      'Press F6 for interactive popup menu during game play',0
                db      '                -= Greetings to =-                  ',0
                db      '   The Rocketeer, Flip Boy, Dr. Insanity, Bandieto  ',0
                db      ' Skinnypuppy, Faceless, Maxan, Phil Douglas, Fanfan ',0
                db      ' Chicken, Zwerg Zwack, The Silicon Soldier, Everyone',0
                db      '                Use it, don''t abuse it!              ',0

;---------------------------------------------------------------
; Include files.
;---------------------------------------------------------------
charcolors      label   byte                    ; color of characters
                include chcolor.pal
erasecolors     label   byte                    ; erase colors
                include ercolor.pal
font            label   byte                    ; font of characters
                include letter.fnt
introscr        label   byte                    ; picture image
                include trainerx.pro
palette         label   byte                    ; picture palettes
                include trainer.pal

;---------------------------------------------------------------
; Pop-up menu variables
;---------------------------------------------------------------
exitpopup       db      0
inmenu1         db      0
inmenu2         db      0
inmenu3         db      0
inmenu4         db      0
kbstatus        db      0
menunum         db      0
menuitem        db      1
item            db      0
itemcolor       db      0
cursoron        db      0
currentmode     dw      0
oldint10        dd      0
savescr         dw      savenumbytes dup (0)
savestatarea    db      960 dup(?)
trainerscr      db      80 dup (' ',tbc)
                db      23 dup (80 dup ('°',midcolor))
                db      17 dup(' ',tbc)
                db      'I',fcc,'n',tbc,'t',tbc,'e',tbc,'r',tbc,'a',tbc,'t',tbc
                db      'i',tbc,'v',tbc,'e',tbc,' ',tbc,'T',fcc,'r',tbc,'a',tbc
                db      'i',tbc,'n',tbc,'e',tbc,'r',tbc,' ',tbc,'E',fcc,'n',tbc
                db      'g',tbc,'i',tbc,'n',tbc,'e',tbc,' ',tbc,'v',tbc,'3',tbc
                db      '.',tbc,'0',tbc,' ',tbc,'B',fcc,'y',tbc,' ',tbc,'C',fcc
                db      'o',tbc,'d',tbc,'e',tbc,' ',tbc,'B',fcc,'r',tbc,'e',tbc
                db      'a',tbc,'k',tbc,'e',tbc,'r',tbc
                db      17 dup (' ',tbc)
popupoptions    db      'Help',0,'Status',0,'Edit',0,'Quit',0
menus           dw      offset cs:menu1
                dw      offset cs:menu2
                dw      offset cs:menu3
                dw      offset cs:menu4
menu1           db      1,2,2,31                  ; format x,y,# of items
                db      'Show trainer keys          F1',0
                db      'Not available for now        ',0
menu2           db      7,2,1,28
                db      'Show trainer status     F3',0
menu3           db      15,2,4,25
                db      'Not available for now  ',0
                db      'Not available for now  ',0
                db      'Not available for now  ',0
                db      'Not available for now  ',0
menu4           db      21,2,1,23
                db      'Quit program      F10',0
menuchars       db      'Ú¿Ä³ÀÙ'
menuitems       dw      offset cs:showtrnkeys
                dw      offset cs:dummyproc
                dw      offset cs:dummyproc
                dw      offset cs:dummyproc

                dw      offset cs:showtrnkeys2
                dw      offset cs:dummyproc
                dw      offset cs:dummyproc
                dw      offset cs:dummyproc

                dw      offset cs:dummyproc
                dw      offset cs:dummyproc
                dw      offset cs:dummyproc
                dw      offset cs:dummyproc

                dw      offset cs:setexitkey
                dw      offset cs:dummyproc
                dw      offset cs:dummyproc
                dw      offset cs:dummyproc

showtrnkeys2    proc    near
                mov     byte ptr cs:showstatus,1
                call    showtrnkeys
                mov     byte ptr cs:showstatus,0
                ret
showtrnkeys2    endp

showtrnkeys     proc    near
                push    es
                push    si
                push    cx
                push    dx
                mov     dx,colorscr
                mov     es,dx
                mov     si,offset cs:trnkeys
                mov     dl,byte ptr cs:[si]
                mov     dh,byte ptr cs:[si+1]
                mov     cx,10
                inc     si
                inc     si
showtk:
                call    calscraddr
                call    putxystr
                cmp     byte ptr cs:showstatus,1
                jne     nexttrnkey
                cmp     cx,3
                je      writestatus
                cmp     cx,9
                je      writestatus
                cmp     cx,10
                je      writestatus
                jmp     nexttrnkey
writestatus:
                push    di
                mov     al,'°'
                mov     bl,midcolor
                call    writechar
                cmp     cx,10
                jne     checkifinfmny
                cmp     byte ptr cs:infeng,1
                je      writeon
writeoff:
                call    wordoff
                pop     di
                jmp     nexttrnkey
writeon:
                call    wordon
                pop     di
                jmp     nexttrnkey
checkifinfmny:
                cmp     cx,9
                jne     checkifmovement
                cmp     byte ptr cs:infmny,1
                je      writeon
                jmp     writeoff
checkifmovement:
                cmp     byte ptr cs:movementon,1
                je      writeon
                jmp     writeoff
nexttrnkey:
                inc     dh
                loop    showtk
                pop     dx
                pop     cx
                pop     si
                pop     es
                ret
trnkeys         db      3,11
                db      ' F1 - Infinite energy         ',0
                db      ' F2 - Infinite money          ',0
                db      ' F3 - Maximize energy         ',0
                db      ' F4 - Maximize money          ',0
                db      ' F5 - Status, armor, etc.     ',0
                db      ' F6 - Online menu help        ',0
                db      ' F7 - Activate all + selected ',0
                db      ' F8 - Rapid movement toggle   ',0
                db      ' F9 - Increase movement rate  ',0
                db      'F10 - Decrease movement rate  ',0
showtrnkeys     endp

wordoff         proc    near
                mov     al,'O'
                mov     bl,midcolor
                call    writechar
                mov     al,'f'
                mov     bl,midcolor
                call    writechar
                mov     al,'f'
                mov     bl,midcolor
                call    writechar
                ret
wordoff         endp

wordon          proc    near
                mov     al,'O'
                mov     bl,midcolor
                call    writechar
                mov     al,'n'
                mov     bl,midcolor
                call    writechar
                mov     al,'°'
                mov     bl,midcolor
                call    writechar
                ret
wordon          endp

;---------------------------------------------------------------
; Data - Variables
;---------------------------------------------------------------
optionson       db      numoptions dup(1)
movementon      db      0
nobeep          db      0
inplace         db      0
savecseg        dw      0
savedseg        dw      0
x               dw      5
oldint21        dd      0
oldintbb        dd      0
oldintcc        dd      0
oldintdd        dd      0
infeng          db      0
infmny          db      0
showstatus      db      0

cseg            ends
                end     trainer



