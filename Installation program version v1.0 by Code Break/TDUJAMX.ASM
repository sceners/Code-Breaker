                smart
                locals
                dosseg

;---------------------------------------------------------------
; Equates.
;---------------------------------------------------------------
cr              equ        0dh                  ; line return (ENTER)
lf              equ        0ah                  ; line feed
paramarea       equ        80h                  ; parameter(s) area
instpml         equ        offset ds:setupfn - instparam - 2
setuppml        equ        offset ds:progfn - setupparam - 2
progpml         equ        offset ds:dummyparam - progparam - 2
lastdrive       equ        'Z' - 'A' + 1        ; last drive letter to check
firstdrive      equ        'A' - 'A' + 1        ; first drive letter to check
fbufsize        equ        100                  ; copy file buffer size
numdigit        equ         15                  ; number of digits in drive

;---------------------------------------------------------------
; Intro menu equates
;---------------------------------------------------------------
vgaseg          equ     0a000h                  ; VGA segment
numoptions      equ          3                  ; number of options
erasebarcolor   equ        245                  ; erase color of bar
barcolor        equ         16                  ; color of bar
barxc           equ        100                  ; x coord. of bar
baryc           equ        100                  ; y coord. of bar
barlength       equ        113                  ; length of bar
titlexc         equ          4                  ; title x coord.
titleyc         equ         50                  ; title y coord.
scrollx         equ          4                  ; credit x coord.
scrolly         equ        194                  ; credit y coord.
delay           equ        35h                  ; timer delay for credit msg
numlines        equ          7                  ; number of credit lines
strlen          equ         53                  ; length of string
optionx         equ        105                  ; x location of options
optiony         equ      baryc                  ; y     "    "   "
bkcolor         equ          0                  ; background color
down            equ      5000h                  ; down key
esckey          equ       11bh                  ; escape key
up              equ      4800h                  ; up key
offonx          equ        310                  ; +/- x coord.
offony          equ      baryc                  ; +/- y coord.

;---------------------------------------------------------------
; Stack segment
;---------------------------------------------------------------
sseg            segment para use16 stack 'stack'
                db      512 dup(?)
sseg            ends

                public  drivelet
;---------------------------------------------------------------
; Data segment
;---------------------------------------------------------------
dseg            segment para use16 'data'
presskey        db      cr,lf,lf,'Strike a key....$'
fail4a          db      cr,lf,'Error : Unable to modify allocated memory blocks.$'
fail4b          db      cr,lf,'Error : Unable to load program.$'
notenoughspace  db      ', not enough space!$'
checkingdisks   db      cr,lf,'Checking all drives for space...',cr,lf,'$'
drivesavail     db      cr,lf,lf,'Drive(s) available : $'
drivenotavail   db      cr,lf,'Drive selected doesn''t have enough space.$'
nodrives        db      'None$'
needthisspace   db      cr,lf,'Total space needed for installation : $'
errorstable     dw      offset error0,offset error1,offset error2
                dw      offset error3,offset error4,offset error5
                dw      offset error6,offset error7,offset error8
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
                dw      offset error0,offset error0,offset error0
error0          db      cr,lf,'Error : Unknown error code.$'
error1          db      cr,lf,'Error : Invalid function.$'
error2          db      cr,lf,'Error : File not found.$'
error3          db      cr,lf,'Error : Path not found.$'
error4          db      cr,lf,'Error : Too many files handles open.$'
error5          db      cr,lf,'Error : Access denied.$'
error6          db      cr,lf,'Error : Invalid handle.$'
error7          db      cr,lf,'Error : Memory control block destroyed.$'
error8          db      cr,lf,'Error : Insufficient memory.$'
totalspace      db      cr,lf,'Total free space for drive '
driveletter     db      0,' = $'
savesp          dw      0                       ; save SP, SS for EXEC function
savess          dw      0
drivelet        db      firstdrive
whatdrive       db      cr,lf,'Install to what drive : $'
needvga         db      cr,lf,'Installation program require VGA.$'
buffer          db      fbufsize dup(?)
dirname         db      '\                 ',0  ; directory to change to

;---------------------------------------------------------------
; Configuration program to be executed
;---------------------------------------------------------------
cnfname         db      ?                       ; configuration drive letter
                db      ':\     \'              ; configuration program path
cnfname2        db      ' .'                    ; configuration program name
cnfext          db      '   ',0                 ; configuration prog. extension

;---------------------------------------------------------------
; Installation program to be executed
;---------------------------------------------------------------
installfn       db      '         ',0           ; installation program name
instparam       db      instpml,' '             ; installation program parameter
instdrive       db      ?                       ; installation program drive
                db      ':\',cr                 ; extra inst. program parameter

;---------------------------------------------------------------
; Setup program to be executed
;---------------------------------------------------------------
setupfn         db      ' ',0                   ; setup program drive letter
setupparam      db      setuppml,'',cr          ; setup program name

;---------------------------------------------------------------
; Program to be executed
;---------------------------------------------------------------
progfn          db      ?                       ; program drive letter
                db      ':\          ',0        ; program name
progparam       db      progpml,'',cr           ; program parameters
dummyparam      db      1,' ',cr

;---------------------------------------------------------------
; Parameter block for child program
;---------------------------------------------------------------
paramblock      label   word                    ; child prog. parameters block
envstr          dw      ?                       ; environment string segment
cmdofs          dw      ?                       ; offset of default command
cmdseg          dw      ?                       ; segment of default command
fcb1ofs         dw      offset fcb_1            ; offset of default FCB 1
fcb1seg         dw      ?                       ; segment of default FCB 1
fcb2ofs         dw      offset fcb_2            ; offset of default FCB 2
fcb2seg         dw      ?                       ; segment of default FCB 2
fcb_1           db      45 dup(?)               ; FCB 1 buffer
fcb_2           db      45 dup(?)               ; FCB 2 buffer

dseg            ends

;---------------------------------------------------------------
; External procedures
;---------------------------------------------------------------

                extrn   playmode:far
                extrn   stopfmm:far
                extrn   drawpic:far
                extrn   setpalette:far
                extrn   checkdrive:far
                extrn   getfreespace:far

;---------------------------------------------------------------
; Code segment
;---------------------------------------------------------------
cseg            segment para use16 'code'
                assume  cs:cseg,ds:dseg,ss:sseg

trainer         proc    far
                mov     ax,dseg                 ; DS = data segment
                mov     ds,ax
                mov     bx,ss                   ; allocate memory
                mov     ax,es
                sub     bx,ax
                mov     ax,sp
                add     ax,15                   ; convert to # of paragraphs
                mov     cl,4
                shr     ax,cl
                add     bx,ax
                mov     ah,4ah                  ; change memory allocation
                int     21h
                jnc     executeprog
                push    offset fail4a           ; error in allocating memory
                call    writestr
                call    showerror
                jmp     terminate
executeprog:
                mov     ax,1a00h                ; check for VGA display
                int     10h
                cmp     al,1ah
                je      showintro
                push    offset needvga          ; need VGA display
                call    writestr
                call    getkey
                jmp     execprog
showintro:
                call    playmode
                call    dointro
                push    3
                call    setmode
                cmp     byte ptr cs:exitprogf,1
                je      exitprog
execprog:
                call    stopfmm
                call    instoption
                mov     byte ptr cs:loaderror,0
                cmp     byte ptr cs:currentopt,numoptions
                je      terminate
                push    word ptr es:[2ch]
                pop     envstr
                push    ds
                pop     fcb2seg
                push    ds
                pop     fcb1seg
                push    ds
                pop     cmdseg
                push    ds
                pop     es
                mov     bx,offset paramblock
                mov     savess,ss
                mov     savesp,sp
                mov     ax,4b00h
                int     21h
                mov     ss,savess
                mov     sp,savesp
                jnc     exitprog
                mov     byte ptr cs:loaderror,1
                push    offset fail4b
                call    writestr
error:
                call    showerror
                push    offset presskey
                call    writestr
                call    getkey
exitprog:
                cmp     byte ptr cs:currentopt,1
                je      cnfcreate
                cmp     byte ptr cs:currentopt,numoptions
                je      terminate
                jmp     showintro
cnfcreate:
                cmp     byte ptr cs:loaderror,1
                je      exitcnfcreate
                call    createconfig
exitcnfcreate:
                jmp     showintro
terminate:
                call    stopfmm
                mov     ax,4c00h
                int     21h
trainer         endp

;---------------------------------------------------------------
; Create installation program and copy this program.
;---------------------------------------------------------------
createconfig    proc
                push    ax bx cx dx ds
                clc
                mov     dx,offset ds:cnfname
                mov     byte ptr ds:cnfext,'c'
                mov     byte ptr ds:cnfext+1,'n'
                mov     byte ptr ds:cnfext+2,'f'
                call    createcnf
                jc      exitgetdrivex
                mov     cx,1
                mov     dx,offset ds:progfn
                call    writecnf
                jc      exitgetdrivex
                call    closecnf
exitgetdrivex:
                call    copyfile
                pop     ds dx cx bx ax
                ret
createconfig    endp

;---------------------------------------------------------------
; Do run or installation option from menu.
;---------------------------------------------------------------
instoption      proc
                push    ax bx cx dx
                cmp     byte ptr cs:currentopt,1
                je      dooption1
                cmp     byte ptr cs:currentopt,2
                je      dorunoption
                jmp     exitcheckdrive
dooption1:
                push    offset checkingdisks
                call    writestr
                mov     drivelet,firstdrive
checkdrives:
                call    checkdrive
                jc      checknext
                mov     bx,offset driveletter
                mov     al,drivelet
                mov     byte ptr ds:[bx],al
                add     byte ptr ds:[bx],'A' - 1
                call    getfreespace
                push    offset totalspace
                call    writestr
                call    showtotalspace
checknext:
                inc     drivelet
                cmp     drivelet,lastdrive
                jl      checkdrives
                call    showdrives
exitcheckdrive:
                pop     dx cx bx ax
                ret
dorunoption:
                push    ax bx cx dx
                mov     ah,0eh
                mov     dl,byte ptr ds:progfn
                sub     dl,'A'
                int     21h
                mov     ah,3bh
                mov     dx,offset ds:dirname
                int     21h
                mov     dx,offset ds:cnfname
                mov     byte ptr ds:cnfext,'c'
                mov     byte ptr ds:cnfext+1,'n'
                mov     byte ptr ds:cnfext+2,'f'
                call    opencnf
                jc      setdefcnf
                mov     cx,1
                mov     dx,offset ds:progfn
                call    readcnf
                jc      setdefcnf
                call    closecnf
                pop     dx cx bx ax
                jmp     exitcheckdrive
setdefcnf:
                mov     ah,19h
                int     21h
                add     al,'A'
                mov     ds:progfn,al
                mov     ds:cnfname,al
                pop     dx cx bx ax
                jmp     exitcheckdrive
instoption      endp

;---------------------------------------------------------------
; Open a file.
;---------------------------------------------------------------
opencnf         proc
                mov     ax,3d00h
                int     21h
                jc      exitopencnf
                mov     bx,ax
exitopencnf:
                ret
opencnf         endp

;---------------------------------------------------------------
; Read X bytes from a file.
;---------------------------------------------------------------
readcnf         proc
                mov     ah,3fh
                int     21h
                ret
readcnf         endp

;---------------------------------------------------------------
; Close a file.
;---------------------------------------------------------------
closecnf        proc
                mov     ah,3eh
                int     21h
                ret
closecnf        endp

;---------------------------------------------------------------
; Show all the available drives for installation.
;---------------------------------------------------------------
showdrives      proc
                push    ds si cx
                push    offset drivesavail
                call    writestr
                push    cs
                pop     ds
                mov     cx,26
                mov     si,offset cs:drivesok
                mov     byte ptr cs:drivef,0
checkdriveok:
                cmp     byte ptr cs:[si],1
                jne     shownextdrive
                mov     byte ptr cs:drivef,1
                push    ax dx
                mov     dx,si
                sub     dx,offset cs:drivesok
                add     dl,'A'
                call    writeach
                mov     dl,' '
                call    writeach
                pop     dx ax
shownextdrive:
                inc     si
                loop    checkdriveok
                cmp     byte ptr cs:drivef,0
                jne     exitshowdrives
nodriveerror:
                pop     cx si ds
                push    offset nodrives
                call    writestr
                push    offset needthisspace
                call    writestr
                call    writeneeded
                mov     byte ptr cs:currentopt,numoptions
                ret
exitshowdrives:
                pop     cx si ds
                push    offset whatdrive
                call    writestr
                call    getdrivelet
                cmp     byte ptr cs:getdrivef,1
                je      exitshowd
                jmp     showdrives
exitshowd:
                ret
drivef          db      ?
showdrives      endp

;---------------------------------------------------------------
; Ask user for installation drive letter.
;---------------------------------------------------------------
getdrivelet     proc
                push    ax bx
getach:
                mov     ah,8
                int     21h
                cmp     al,'A'
                jb      getach
                cmp     al,'Z'
                ja      checkiflower
                sub     al,'A'
                jmp     driveletok
checkiflower:
                cmp     al,'a'
                jb      getach
                cmp     al,'z'
                ja      getach
                sub     al,'a'
driveletok:
                xor     ah,ah
                mov     bx,offset cs:drivesok
                add     bx,ax
                cmp     byte ptr cs:[bx],1
                jne     getdriveerror
                add     al,'A'
                mov     ds:progfn,al
                mov     ds:cnfname,al
                mov     ds:instdrive,al
                mov     byte ptr cs:getdrivef,1
                jmp     exitgetdrive
getdriveerror:
                mov     byte ptr cs:getdrivef,0
                call    clrscr
                push    offset drivenotavail
                call    writestr
exitgetdrive:
                pop     bx ax
                ret
getdrivef       db      ?
getdrivelet     endp

;---------------------------------------------------------------
; Create file.
;---------------------------------------------------------------
createcnf       proc
                mov     ah,3ch
                mov     dx,offset ds:cnfname
                mov     cx,1
                int     21h
                jc      exitcreatecnf
                mov     bx,ax
exitcreatecnf:
                ret
createcnf       endp

;---------------------------------------------------------------
; Write X bytes to file.
;---------------------------------------------------------------
writecnf        proc
                mov     ah,40h
                int     21h
                jc      exitwritecnf
exitwritecnf:
                ret
writecnf        endp

;---------------------------------------------------------------
; Create configuration file and copy this program.
;---------------------------------------------------------------
copyfile        proc
                push    ax bx cx dx
                mov     dx,offset ds:cnfname
                mov     byte ptr ds:cnfext,'e'
                mov     byte ptr ds:cnfext+1,'x'
                mov     byte ptr ds:cnfext+2,'e'
                call    createcnf
                mov     cs:fh1,bx

                mov     dx,offset ds:cnfname2
                call    opencnf
                mov     cs:fh2,bx
                call    getfsize
readnwrite:
                mov     bx,cs:fh2
                mov     cx,fbufsize
                mov     dx,offset buffer
                call    readcnf

                mov     bx,cs:fh1
                mov     cx,fbufsize
                mov     dx,offset buffer
                call    writecnf
                sub     cs:numblock,1
                cmp     cs:numblock,0
                jne     readnwrite
                mov     bx,cs:fh2
                mov     cx,cs:rnumblock
                mov     dx,offset buffer
                call    readcnf

                mov     bx,cs:fh1
                mov     cx,cs:rnumblock
                mov     dx,offset buffer
                call    writecnf
                mov     bx,cs:fh1
                call    closecnf
                mov     bx,cs:fh2
                call    closecnf
exitcopyfile:
                pop     dx cx bx ax
                ret
fh1             dw      ?
fh2             dw      ?
numblock        dw      ?
rnumblock       dw      ?
copyfile        endp

;---------------------------------------------------------------
; Get file size.
;---------------------------------------------------------------
getfsize        proc
                push    ax cx dx
                mov     ax,4201h
                mov     cx,0
                mov     dx,0
                int     21h
                push    ax cx dx
                mov     ax,4202h
                mov     cx,0
                mov     dx,0
                int     21h
                xor     dx,dx
                mov     cx,fbufsize
                div     cx
                mov     cs:numblock,ax
                mov     cs:rnumblock,dx
                pop     dx cx ax
                mov     ax,4200h
                int     21h
                pop     dx cx ax
                ret
getfsize        endp

;---------------------------------------------------------------
; Clear screen and go to 0,0.
;---------------------------------------------------------------
clrscr          proc
                push    ax bx cx dx
                mov     ah,6
                mov     al,25
                mov     bh,7
                mov     cx,0
                mov     dh,24
                mov     dl,79
                int     10h
                mov     ah,2
                mov     dx,0
                mov     bh,0
                int     10h
                pop     dx cx bx ax
                ret
clrscr          endp

;---------------------------------------------------------------
; Write how much free space is needed to install.
;---------------------------------------------------------------
writeneeded     proc
                push    ax cx dx si ds
                push    cs
                pop     ds
                mov     cx,offset cs:drivesok - cs:spaceneed
                mov     si,offset cs:spaceneed
writeit:
                lodsb
                mov     dl,al
                add     dl,'0'
                call    writeach
                loop    writeit
                pop     ds si dx cx ax
                ret
writeneeded     endp

;---------------------------------------------------------------
; Print the number in AX to screen.
;---------------------------------------------------------------
printnum        proc
                push    ax bx cx dx                     ; save registers
                mov     cx,0                            ; count = 0
                mov     bx,10                           ; number to be divide by
loop2:
                xor     dx,dx
                div     bx                              ; DX:AX / BX
                push    dx                              ; save remainder
                inc     cx                              ; count += 1
                cmp     ax,0                            ; if AX > 0
                ja      loop2                           ;   then continue divide
loop3:
                pop     dx                              ; load remainder
                add     dx,'0'                          ; write the character
                call    writeach                        ;   to the screen
                loop    loop3                           ; do remaining
                pop     dx cx bx ax                     ; restore registers
                ret
printnum        endp

;---------------------------------------------------------------
; Print the number in AX to screen.
;---------------------------------------------------------------
showtotalspace  proc
                push    ax bx cx dx
                mov     cs:z0,cx                        ; Z0 = CX (bytes per clustor)
                mov     cs:z1,0                         ; Z1 = 0 (clustors per drive)
                mul     bx                              ; DX:AX = BX * AX
                mov     cs:y1,dx                        ; save multiplication
                mov     cs:y0,ax                        ;   result to Y1:Y0
                xor     ax,ax                           ; clear AX, BX, CX
                xor     bx,bx
                xor     cx,cx
                xor     dx,dx
                call    caltotalspace                   ; calculate free space
                mov     cs:numcounter,0                 ; counter = 0
                mov     si,offset cs:spacefree          ; save free space here
divnum:
                mov     cs:count,64                     ; # of times to shift left
                xor     ax,ax
                xor     dx,dx
                mov     cs:z1,0                         ; # to be divided by
                mov     cs:z0,10                        ;   Z1:Z0
                mov     bx,cs:z1
                mov     cx,cs:z0
shif:
                call    shla                            ; divide A:B:C:D by Z1:Z0
                cmp     dx,bx
                jb      notyet
                ja      hit
                cmp     ax,cx
                jb      notyet
hit:
                sub     ax,cx
                sbb     dx,bx
                add     cs:d,1
notyet:
                dec     cs:count
                cmp     cs:count,0
                jne     shif
                push    ax                              ; save digit
                inc     cs:numcounter                   ; number of digit += 1
                cmp     cs:a,0                          ; check if division
                jne     divnum                          ;   is done
                cmp     cs:b,0
                jne     divnum
                cmp     cs:c,0
                jne     divnum
                cmp     cs:d,0
                jne     divnum
                push    cs:numcounter                   ; save # of digits
                pop     word ptr cs:[si]                ;   in
                inc     si
                inc     si
showch:
                pop     ax                              ; get a digit
                mov     byte ptr cs:[si],al             ; save a digit and
                inc     si                              ;   move to next location
                call    printnum                        ; write digit to screen
                dec     cs:numcounter                   ; decrement # of digits
                cmp     cs:numcounter,0                 ; if #digits != 0
                jne     showch                          ;   then show next digit
                call    checkforspace                   ; check for free space
                pop     dx cx bx ax
                ret

count           dw      ?
numcounter      dw      ?
spacefree       dw      ?,numdigit dup(?)
spaceneed       db      6,0,0,0,0,0,0                   ; space requirement
drivesok        db      26 dup(?)                       ; drives free space flag
showtotalspace  endp

;---------------------------------------------------------------
; Shift A:B:C:D left by Z1:Z0 (BX:CX)
;---------------------------------------------------------------
checkforspace   proc
                push    ax bx
                mov     ax,offset cs:drivesok - cs:spaceneed
                cmp     word ptr cs:spacefree,ax
                jg      setdriveok
                je      checkifenough
nospace:
                push    offset notenoughspace
                call    writestr
                jmp     exitcheckspace
checkifenough:
                push    cx ds es si di                  ; check if space match
                push    cs                              ; set DS,ES = CS
                pop     ds
                push    ds
                pop     es
                mov     si,offset cs:spacefree
                mov     cx,word ptr cs:[si]
                add     si,2
                mov     di,offset cs:spaceneed
checknumbynum:
                repe    cmpsb
                jg      exitcheckenough
                pop     di si es ds cx
                jmp     nospace
exitcheckenough:
                pop     di si es ds cx
setdriveok:
                mov     ax,offset cs:drivesok
                xor     bh,bh
                mov     bl,drivelet
                add     ax,bx
                xchg    ax,bx
                mov     byte ptr cs:[bx-1],1
exitcheckspace:
                pop     bx ax
                ret
checkforspace   endp

;---------------------------------------------------------------
; Shift A:B:C:D left by Z1:Z0 (BX:CX)
;---------------------------------------------------------------
shla            proc
                push    bx cx
                xor     bx,bx
                xor     cx,cx
                shl     cs:d,1
                adc     bx,0
                shl     cs:c,1
                adc     cx,0
                add     cs:c,bx
                xor     bx,bx
                shl     cs:b,1
                adc     bx,0
                add     cs:b,cx
                xor     cx,cx
                shl     cs:a,1
                adc     cx,0
                add     cs:a,bx
                xor     bx,bx
                shl     ax,1
                adc     bx,0
                add     ax,cx
                shl     dx,1
                add     dx,bx
                pop     cx bx
                ret
shla            endp

;---------------------------------------------------------------
; Calculate total free space.
; Multiply Z1:Z0 by Y1:Y0 and store as A:B:C:D
;---------------------------------------------------------------
caltotalspace   proc
                mov     cs:b,0
                mov     cs:a,0
                mov     ax,cs:z0
                mul     cs:y0
                mov     cs:d,ax
                mov     cs:c,dx
                mov     ax,cs:z0
                mul     cs:y1
                add     cs:c,ax
                adc     cs:b,dx
                adc     cs:a,0
                mov     ax,cs:z1
                mul     cs:y0
                add     cs:c,ax
                adc     cs:b,dx
                adc     cs:a,0
                mov     ax,cs:z1
                mul     cs:y1
                add     cs:b,ax
                adc     cs:a,dx
                ret
y0              dw      0
y1              dw      0
z0              dw      0
z1              dw      0
a               dw      0
b               dw      0
c               dw      0
d               dw      0
caltotalspace   endp

;---------------------------------------------------------------
; Write a string.
;---------------------------------------------------------------
writestr        proc    near
                push    ax dx bp                        ; save registers
                mov     bp,sp
                push    [bp+8]                          ; set dx=[bp+8]
                pop     dx
                mov     ah,9                            ; write string
                int     21h
                pop     bp dx ax                        ; restore registers
                ret     2
writestr        endp

;---------------------------------------------------------------
; Write a character.
;---------------------------------------------------------------
writeach        proc    near
                push    ax                              ; save registers
                mov     ah,2                            ; write string
                int     21h
                pop     ax                              ; restore registers
                ret
writeach        endp

;---------------------------------------------------------------
; Show error(s) that occurred during execution of program.
;---------------------------------------------------------------
showerror       proc    near
                push    ax bx
                mov     bx,2
                mul     bl
                mov     bx,offset ds:errorstable
                add     bx,ax
                push    word ptr ds:[bx]
                call    writestr
                pop     bx ax
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
; Write a key to mode 13h.
;---------------------------------------------------------------
writechx8       proc    near
                push    bx cx si di ds es
                push    0a000h
                pop     es
                mov     si,offset cs:fontx
                mov     al,byte ptr cs:[bx]
                sub     al,' '
                or      al,al
                jnz     writechx8x
                jmp     exitwritechx
writechx8x:
                push    cs
                pop     ds
                xor     ch,ch
                mov     cl,al
setindexx:
                add     si,64
                loop    setindexx
                mov     cx,8
                mov     bx,7
setpixelx:
                push    di cx
                mov     cx,8
loadbytex:
                lodsb
                cmp     al,1
                jne     incdi2x
                push    si
                mov     si,offset cs:charcolorsx
                cmp     byte ptr cs:erase,1
                jne     normalx
                mov     si,offset cs:erasecolorsx
normalx:
                mov     al,byte ptr cs:[si+bx]
                pop     si
                mov     byte ptr es:[di],al
incdi2x:
                inc     di
setitx:
                loop    loadbytex
                pop     cx di
                add     di,320
                dec     bx
                loop    setpixelx
exitwritechx:
                pop     es ds di si cx bx
                ret
writechx8       endp

;---------------------------------------------------------------
; Write a key to mode 13h.
;---------------------------------------------------------------
writech         proc    near
                push    bx cx si di ds es
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
                push    di cx
                mov     cx,5
loadbyte:
                lodsb
                cmp     al,1
                jne     incdi2
                push    si
                mov     si,offset cs:charcolors
                cmp     byte ptr cs:xerase,1
                jne     normal
                mov     si,offset cs:erasecolors
normal:
                mov     al,byte ptr cs:[si+bx]
                pop     si
                mov     byte ptr es:[di],al
incdi2:
                inc     di
setit:
                loop    loadbyte
                pop     cx di
                add     di,320
                dec     bx
                loop    setpixel
exitwritech:
                pop     es ds di si cx bx
                ret
writech         endp

;---------------------------------------------------------------
; Write a key to mode 13h.
;---------------------------------------------------------------
writech2        proc    near
                push    bx cx si di ds es
                push    0a000h
                pop     es
                mov     si,offset cs:font
                mov     al,byte ptr cs:[bx]
                sub     al,' '
                or      al,al
                jnz     writechx2
                jmp     exitwritech2
writechx2:
                push    cs
                pop     ds
                xor     ch,ch
                mov     cl,al
setindex2:
                add     si,25
                loop    setindex2
                mov     cx,5
                mov     bx,4
setpixel2:
                push    di cx
                mov     cx,5
loadbyte2:
                lodsb
                cmp     al,1
                jne     incdi3
                push    si
                mov     si,offset cs:charcolors
                mov     al,byte ptr cs:[si+bx]
                pop     si
                mov     byte ptr es:[di],al
incdi3:
                inc     di
                loop    loadbyte2
                pop     cx di
                add     di,320
                dec     bx
                loop    setpixel2
exitwritech2:
                pop     es ds di si cx bx
                ret
writech2        endp

;---------------------------------------------------------------
; Write a string to mode 13h.
;---------------------------------------------------------------
putstr2         proc    near
                push    di cx
                call    calculatedi
putch2:
                cmp     byte ptr cs:[bx],0
                je      exitputstr2
                call    writech2
                inc     bx
                add     di,6
                jmp     putch2
exitputstr2:
                pop     cx di
                ret
putstr2         endp

;---------------------------------------------------------------
; Write a string to mode 13h.
;---------------------------------------------------------------
putstr          proc    near
                push    di cx
                call    calculatedi
putch:
                cmp     byte ptr cs:[bx],0
                je      exitputstr
                call    writech
                inc     bx
                add     di,6
                jmp     putch
exitputstr:
                pop     cx di
                ret
putstr          endp

;---------------------------------------------------------------
; Write a string to mode 13h.
;---------------------------------------------------------------
putstrx         proc    near
                push    di cx
                call    calculatedi
putchx:
                cmp     byte ptr cs:[bx],0
                je      exitputstr
                call    writechx8
                inc     bx
                add     di,9
                jmp     putchx
exitputstrx:
                pop     cx di
                ret
putstrx         endp

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
                push    es di cx
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
                push    ax cx di
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
                pop     di cx ax
                add     di,320
                loop    drawhbar
                pop     word ptr cs:currenty
                pop     word ptr cs:currentx
                pop     cx di es
                ret
drawbar         endp

;---------------------------------------------------------------
; Redirect interrupt 1ch.
;---------------------------------------------------------------
redirect1c      proc    near
                push    ax dx ds es
                mov     ax,351ch
                int     21h
                mov     word ptr cs:oldint1c,bx
                mov     word ptr cs:oldint1c+2,es
                push    cs
                pop     ds
                mov     dx,offset cs:newint1c
                mov     ax,251ch
                int     21h
                pop     es ds dx ax
                ret
redirect1c      endp

;---------------------------------------------------------------
; Redirect interrupt 1ch back to original.
;---------------------------------------------------------------
unredirect1c    proc    near
                push    ax dx ds
                lds     dx,dword ptr cs:oldint1c
                mov     ax,251ch
                int     21h
                pop     ds dx ax
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
                mov     cs:currenty,titleyc
                mov     cs:currentx,titlexc
                mov     bx,offset cs:titlestr
                call    putstrx
                mov     cs:currenty,titleyc+10
                mov     cs:currentx,titlexc
                mov     bx,offset cs:titlestr2
                call    putstrx
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
                call    vrtretrace
                jmp     waitforkey
getcheckkey:
                call    getkey
                cmp     ax,up
                jne     checkifdown
                call    doupkey
checkifdown:
                cmp     ax,down
                jne     checkifexit
                call    dodownkey
checkifexit:
                cmp     ax,esckey
                jne     checkifenter
option4:
                mov     byte ptr cs:exitprogf,1
                mov     byte ptr cs:currentopt,numoptions
                jmp     exitdointro
checkifenter:
                cmp     al,cr
                jne     waitforkey
                cmp     byte ptr cs:currentopt,1
                je      option1
                cmp     byte ptr cs:currentopt,2
                je      option3
                cmp     byte ptr cs:currentopt,3
                je      option4
exitdointro:
                call    unredirect1c
                ret
option1:
                push    si
                mov     dx,offset installfn
                mov     si,offset instparam
                call    setparam
                pop     si
                jmp     exitdointro
option2:
                push    si
                mov     dx,offset setupfn
                mov     si,offset setupparam
                call    setparam
                pop     si
                jmp     exitdointro
option3:
                push    si
                mov     dx,offset progfn
                mov     si,offset progparam
                call    setparam
                pop     si
                jmp     exitdointro
dointro         endp

setparam        proc    near
                push    cx di es si
                push    ds
                pop     es
                mov     cmdofs,si
                inc     si
                mov     di,offset fcb_1
                mov     ax,2901h
                int     21h
                inc     si
                mov     si,offset dummyparam
                mov     di,offset fcb_2
                mov     ax,2901h
                int     21h
                pop     si es di cx
                ret
setparam        endp

;---------------------------------------------------------------
; Display the options.
;---------------------------------------------------------------
writeoptions    proc    near
                push    ax bx cx di
                mov     word ptr cs:currenty,optiony
                mov     word ptr cs:currentx,optionx
                mov     bx,cs:optionsptr
                mov     cx,cs:curnumopts
writeoption:
                push    word ptr cs:currentx
                call    putstr2
                pop     word ptr cs:currentx
                add     word ptr cs:currenty,11
                inc     bx
                loop    writeoption
                pop     di cx bx ax
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
                call    erasebar
                cmp     byte ptr cs:currentopt,1
                jg      deccolor
                mov     cs:curnumopts,numoptions
                mov     ax,cs:curnumopts
                mov     byte ptr cs:currentopt,al
                push    cx di
                mov     cx,ax
                dec     cx
                mov     di,offony
adddi11:
                add     di,11
                loop    adddi11
                mov     cs:currenty2,di
                mov     cs:bary,di
                pop     di cx
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
; Check until vertical retrace is finished.
;---------------------------------------------------------------
vrtretrace      proc    near
                push    ax dx
                mov     dx,3dah
vrtwait:
                in      al,dx
                and     al,8
                jz      vrtwait
vrtwait2:
                in      al,dx
                and     al,8
                jnz     vrtwait2
                pop     dx ax
                retn
vrtretrace      endp

;---------------------------------------------------------------
; Set mode to.
;---------------------------------------------------------------
setmode         proc    near
                push    ax dx bp
                mov     bp,sp
                xor     ah,ah
                mov     al,byte ptr [bp+8]
                int     10h
                pop     bp dx ax
                ret     2
setmode         endp

;---------------------------------------------------------------
; Show graphic menu interface.
;---------------------------------------------------------------
showpic         proc    near
                push    13h
                call    setmode
                call    setpalette
                mov     word ptr cs:optionsptr,offset cs:options
                mov     word ptr cs:curnumopts,numoptions
                call    writeoptions
                call    drawpic
                ret
showpic         endp

;---------------------------------------------------------------
; Data - Variables
;---------------------------------------------------------------
barerase        db      0                       ; indicate if bar is to be erase
exitprogf       db      0                       ; indicate if exit program
currentx2       dw      offonx
currenty2       dw      optiony
barx            dw      barxc
bary            dw      baryc
coptions        dw      offset cs:options
erase           db      0
xerase          db      0
leadingzero     db      0
currentstr      dw      offset cs:credit
currentopt      db      1
counter         dw      delay-2
xtimes          db      0
currentx        dw      0
currenty        dw      0
oldint1c        dd      0
loaderror       db      0
options         db      'Install game           ',0
;               db      'Configure game         ',0
                db      'Run game               ',0
                db      'Exit installation      ',0
optionsptr      dw      offset cs:options
curnumopts      dw      numoptions
                ;       '<-----TITLE MUST BE THIS LONG----->'
titlestr        db      '      TDU!JAM proudly presents     ',0
titlestr2       db      ' XXXXXXXXXXXXXXXXXXXXXXXXXX CD-RIP ',0
credit          db      ' Installation program version v1.0 by Code Breaker  ',0
                db      '                  Design by Fanfan                  ',0
                db      '                -= Greetings to =-                  ',0
                db      '   The Rocketeer, Flip Boy, Dr. Insanity, Bandieto  ',0
                db      ' Fanfan, Skinnypuppy, Faceless, Maxan, Phil Douglas ',0
                db      ' Chicken, Zwerg Zwack, The Silicon Soldier, Everyone',0
                db      '                Use it, don''t abuse it!              ',0

;---------------------------------------------------------------
; Include files.
;---------------------------------------------------------------
charcolors      label   byte                    ; color of characters
                include chcjam.pal
erasecolors     label   byte                    ; erase colors
                include ercjam.pal
charcolorsx     label   byte                    ; color of characters
                include chxcjam.pal
erasecolorsx    label   byte                    ; erase colors
                include erxcjam.pal
font            label   byte                    ; font of characters
                include letjam.fnt
fontx           label   byte                    ; font of characters
                include letjamx.fnt

cseg            ends
                end     trainer
