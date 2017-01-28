cr              equ     0dh                     ; Return
lf              equ     0ah                     ; Line feed
paramarea       equ     80h                     ; Parameter area
searchofs1      equ     620h                    ; Energy decrease
searchofs2      equ     80e2h                   ; Energy blocks
searchofs3      equ     80e4h                   ; Number of equipments

cseg            segment byte public
                assume  cs:cseg,ds:cseg
                org     0
firstbyte       equ     $                       ; First address of program
		org	100h

trainer         proc    far

start:
                jmp     begin

oldint8         dd      0                       ; Storage of old INT 8h
oldint9         dd      0                       ; Storage of old INT 9h
oldint92        dd      0                       ; Storage of old INT 9h
found           db      0                       ; Bytes found indicator
numeq           db      0                       ; Number of equipments
saveds          dw      0                       ; Segment where bytes found
savess          dw      0                       ; Save SS
savesp2         dw      0                       ; Save SP
counter         dw      200                     ; Counter
oddnums         db      1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35
                db      37,39,41,43,45,47,49,51,0
beginseg        dw      0

trainer         endp

;---------------------------------------------------------------
; Make a simple beep.
;---------------------------------------------------------------

beep            proc    near
                push    bx
                push    cx
                mov     bx,100h
                mov     cx,70
                call    maketone
                pop     cx
                pop     bx
                ret
beep            endp

;---------------------------------------------------------------
; Check if AX=odd.
;---------------------------------------------------------------

checkax         proc    near
                push    bx
                mov     bx,offset oddnums
compareodds:
                cmp     byte ptr cs:[bx],0
                je      exitcheckax
                cmp     al,cs:[bx]
                je      incax
                inc     bx
                jmp     short compareodds
incax:
                inc     ax
exitcheckax:
                pop     bx
                ret
checkax         endp

;---------------------------------------------------------------
; New interrupt 9h. Use to toggle cheat on/off.
;---------------------------------------------------------------

newint9         proc    near
                push    ax                          ; Save registers
                push    bx
                push    ds
                mov     ax,cs                       ; Set DS=CS
                mov     ds,ax
                in      al,60h                      ; Get a key
                mov     bx,offset key1              ; Key to compare
comparekeys:
                cmp     byte ptr cs:[bx],0          ; End of compare key
                je      exitnewint9
                cmp     al,cs:[bx]                  ; Compare keys
                je      execkey
                inc     bx                          ; Get next key
                inc     bx
                inc     bx
                jmp     short comparekeys
execkey:
                inc     bx                          ; Get address
                jmp     word ptr cs:[bx]            ; Execute key program
exitnewint9:
                pop     ds                          ; Restore registers
                pop     bx
                pop     ax
                jmp     dword ptr cs:oldint9        ; Execute old INT 9h

key1            db      2                           ; Predefine keys
                dw      offset key1ofs
key2            db      3
                dw      offset key2ofs
key3            db      4
                dw      offset key3ofs
key4            db      5
                dw      offset key4ofs
                db      0
key1ofs:
                push    es
                push    di
                mov     di,searchofs1
                push    saveds
                pop     es
                xor     word ptr es:[di],0a6b9h
                xor     word ptr es:[di+2],1072h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
key2ofs:
                push    es
                push    di
                mov     di,searchofs3
                add     saveds,622h
                push    saveds
                pop     es
                push    ax
                mov     al,byte ptr es:[di]
                call    checkax
                mov     numeq,al
                xor     ah,ah
                push    di
                add     di,ax
                mov     byte ptr es:[di],8
                pop     di
                mov     ax,2
                mul     numeq
                push    di
                add     di,ax
                mov     byte ptr es:[di],1
                pop     di
                pop     ax
                cmp     byte ptr es:[di],18h
                jge     exitkey2
                inc     byte ptr es:[di]
exitkey2:
                sub     saveds,622h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
key3ofs:
                push    es
                push    di
                mov     di,searchofs3
                add     saveds,622h
                push    saveds
                pop     es
                push    ax
                mov     al,byte ptr es:[di]
                call    checkax
                xor     ah,ah
                push    di
                add     di,ax
                mov     byte ptr es:[di],8
                pop     di
                pop     ax
                sub     saveds,622h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
key4ofs:
                push    es
                push    di
                mov     di,searchofs2
                add     saveds,622h
                push    saveds
                pop     es
                mov     byte ptr es:[di],6
                sub     saveds,622h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
newint9         endp

;---------------------------------------------------------------
; New interrupt 8h. Use to search memory
;---------------------------------------------------------------

newint8         proc    near
                cmp     byte ptr found,1
                jne     search
                pushf
                call    dword ptr oldint8
                iret
search:
		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		push	bp
		mov	bp,sp
                cmp     byte ptr found,1
                je      jmptoexit2
		sub	sp,2
                mov     ax,cs
		mov	ds,ax
		mov	ax,cs
		mov	[bp-2],ax
                mov     beginseg,ax
                dec     counter
                cmp     word ptr counter,0
                je      checkiffound
                jmp     execint2
checkiffound:
                cmp     byte ptr found,0
                je      search1
jmptoexit2:
                jmp     jmptoexit
search1:
                mov     ax,beginseg
                add     ax,0fffeh
                cmp     ax,[bp-2]
                jne     continues
                mov     ax,100h
                mov     counter,ax
                jmp     jmptoexit
continues:
                mov     ax,[bp-2]
		push	ax
                mov     di,searchofs1
		pop	es
                cmp     byte ptr es:[di],29h
                je      search2
                jmp     incbase
search2:
		mov	ax,[bp-2]
		push	ax
                mov     di,searchofs1
		pop	es
                cmp     byte ptr es:[di+1],36h
                je      search3
                jmp     incbase
search3:
		mov	ax,[bp-2]
		push	ax
                mov     di,searchofs1
		pop	es
                cmp     byte ptr es:[di+2],0e2h
                je      fixmem
                jmp     execint1
fixmem:
                mov     byte ptr found,1
		mov	ax,[bp-2]
		push	ax
                mov     di,searchofs1
		pop	es
                push    es
                pop     saveds
                mov     byte ptr es:[di],90h
                mov     byte ptr es:[di+1],90h
                mov     byte ptr es:[di+2],90h
                mov     byte ptr es:[di+3],90h
                mov     byte ptr es:[di+26h],6
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
                push    bx
                push    cx
                mov     bx,233h
                mov     cx,13h
                call    maketone
                pop     cx
                pop     bx
                jmp     short incbase
execint1:
                pushf
                call    dword ptr oldint8
incbase:
		inc	word ptr [bp-2]
                jmp     checkiffound
jmptoexit:
                jmp     short exitnewint
execint2:
                pushf
                call    dword ptr oldint8
exitnewint:
		mov	sp,bp
		pop	bp
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		iret
newint8         endp

;---------------------------------------------------------------
; Redirect interrupt 9h by direct memory accessing.
;---------------------------------------------------------------

redirect9       proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,64h
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
                or      bx,64h
                push    word ptr cs:oldint92
                pop     word ptr es:[bx]
                push    word ptr cs:oldint92+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect9     endp

;---------------------------------------------------------------
; Redirect interrupt 8h by direct memory accessing
;---------------------------------------------------------------

redirect8       proc    near
                push    ax
                push    bx
                push    es
                and     ax,0
                push    ax
                pop     es
                and     bx,0
                or      bx,70h
                mov     ax,word ptr es:[bx]
                mov     word ptr cs:oldint8,ax
                mov     ax,word ptr es:[bx+2]
                mov     word ptr cs:oldint8+2,ax
                mov     ax,offset cs:newint8
                mov     word ptr es:[bx],ax
                mov     ax,cs
                mov     word ptr es:[bx+2],ax
                pop     es
                pop     bx
                pop     ax
                ret
redirect8       endp

;---------------------------------------------------------------
; Redirect interrupt 8h to original by direct memory accessing
;---------------------------------------------------------------

unredirect8     proc    near
                push    ax
                push    bx
                push    es
                and     ax,0
                push    ax
                pop     es
                and     bx,0
                or      bx,70h
                mov     ax,word ptr cs:oldint8
                mov     word ptr es:[bx],ax
                mov     ax,word ptr cs:oldint8+2
                mov     word ptr es:[bx+2],ax
                pop     es
                pop     bx
                pop     ax
                ret
unredirect8     endp

;---------------------------------------------------------------
; Make a tone. CX - duration, BX - tone
;---------------------------------------------------------------

maketone        proc    near
                push    ax
                mov     word ptr cs:savess,ss
                mov     word ptr cs:savesp2,sp
                mov     ax,cs
                cli
                mov     ss,ax
                mov     sp,offset stack2ptr
                sti
                push    cx
                call    turnonspeaker
                pop     cx
                push    bx
                call    vrtretrace
                pop     bx
                call    turnoffspeaker
                cli
                mov     ss,word ptr cs:savess
                mov     sp,word ptr cs:savesp2
                sti
                pop     ax
                retn
maketone        endp

;---------------------------------------------------------------
; Turn on the speaker.
;---------------------------------------------------------------

turnonspeaker   proc    near
                push    bp
                mov     bp,sp
                push    ax
                push    bx
                push    dx
                mov     bx,[bp+4]
                mov     ax,34ddh
                mov     dx,12h
                cmp     dx,bx
                jge     exitturnonspeaker
                div     bx
                mov     bx,ax
                in      al,61h
                test    al,3
                jne     manual
                or      al,3
                out     61h,al
                mov     al,0b6h
                out     43h,al
manual:
                mov     al,bl
                out     42h,al
                mov     al,bh
                out     42h,al
exitturnonspeaker:
                pop     dx
                pop     bx
                pop     ax
                pop     bp
                retn
turnonspeaker   endp

;---------------------------------------------------------------
; Turn off the speaker.
;---------------------------------------------------------------

turnoffspeaker  proc    near
                in      al,61h
                and     al,0fch
                out     61h,al
                mov     al,0b6h
                out     43h,al
                retn
turnoffspeaker  endp

;---------------------------------------------------------------
; Wait until vertical retrace.
;---------------------------------------------------------------

vrtretrace      proc    near
                push    bp
                mov     bp,sp
                push    bx
                push    ax
                push    dx
                mov     bx,[bp+4]
                mov     dx,3dah
vrtwait:
                in      al,dx
                and     al,8
                jz      vrtwait
                dec     bx
                jnz     vrtwait
                pop     dx
                pop     ax
                pop     bx
                pop     bp
                retn
vrtretrace      endp

;---------------------------------------------------------------
; Execute program.
;---------------------------------------------------------------

execprog        proc    near
                mov     ax,cs                        ; Set up parameters
                mov     fcb1,ax                      ; for EXEC function
                mov     fcb2,ax
                mov     envstr,ax
                mov     dx,offset filename
                mov     bx,offset paramblock
                mov     savesp,sp
                mov     ax,4b00h                     ; Execute program
                int     21h
                ret
execprog        endp

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
; Show error message occurred during execution of program.
;---------------------------------------------------------------

showerror       proc    near
                push    ax
                cmp     ax,2
                je      em2
                cmp     ax,8
                je      em8
                push    offset error0
                jmp     writeerror
em2:
                push    offset error2
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
                push    offset credit                ; Show information
                call    writestr
                call    getkey                       ; Wait until keypressed
                mov     sp,offset stack1ptr          ; Set up stack
                push    cs                           ; Set DS=CS
                pop     ds
                call    redirect8                    ; Redirect INT 8h
                call    redirect9                   ; Redirect INT 9h
                push    word ptr cs:oldint9          ; Save INT 9h to
                pop     word ptr cs:oldint92         ; be use later
                push    word ptr cs:oldint9+2
                pop     word ptr cs:oldint92+2
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
                call    execprog                     ; Execute program
                mov     bx,cs                        ; Set up DS,ES,SS to CS
                mov     ss,bx
                mov     sp,cs:savesp                 ; Restore SP
                mov     ds,bx
                mov     es,bx
                jnc     exitprog                     ; No error, exit program
                push    offset fail4b                ; Show error message
                call    writestr
error:
                call    showerror
exitprog:
                call    unredirect8                 ; Redirect INT 8h
                call    unredirect9                 ; Redirect INT 9h
                mov     ax,4c00h                    ; Exit program
		int	21h

credit          db      '''Jill of the Jungle'' cheat by Code Breaker.',cr,lf,lf
                db      'Keys are : ',cr,lf,lf
                db      '1  -  Infinite energy',cr,lf
                db      '2  -  Get a door key',cr,lf
                db      '3  -  Increase power',cr,lf
                db      '4  -  Get full energy',cr,lf,lf
                db      'Greetings to all.',cr,lf,lf,'Strike a key....$'
fail4a          db      cr,lf,'Unable to modify allocated memory blocks.$'
fail4b          db      cr,lf,'Unable to load program overlay.$'
error0          db      cr,lf,'Unknown error code.$'
error2          db      cr,lf,'''Jill2.exe'' - not found.$'
error8          db      cr,lf,'Not enough memory.$'
filename        db      'jill2.exe',0
savesp          dw      ?
paramblock      label   word                        ; Parameter block
                dw      0
                dw      offset cmd_buf
fcb1            dw      ?                           ; File control block #1
                dw      5ch
fcb2            dw      ?                           ; File control block #2
                dw      6ch
envstr          dw      ?
cmd_buf         db      ?                           ; Parameters are stored
                db      ' '                         ; here
cmd_txt         db      80h dup (?)                   
stack1          db      32 dup ('stack   ')
stack1ptr       equ     $-2
stack2          db      32 dup ('stack   ')
stack2ptr       equ     $-2
lastbyte        equ     $                           ; last address of program

cseg            ends
		end	start


                push    es
                push    di
                mov     di,searchofs3
                add     saveds,622h
                push    saveds
                pop     es
                push    ax
                mov     al,byte ptr es:[di]
                mov     numeq,al
                mov     ax,2
                mul     numeq
                push    di
                add     di,ax
                mov     byte ptr es:[di],1
                pop     di
                pop     ax
                inc     byte ptr es:[di]
                sub     saveds,622h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
