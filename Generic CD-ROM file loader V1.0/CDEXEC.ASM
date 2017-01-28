cr              equ     0dh
lf              equ     0ah
paramarea       equ     80h
cddrivelet1     equ     'A'
cddrivelet2     equ     'Z'
       
cseg            segment byte public
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
                org     0
firstbyte       equ     $
                org     100h

fix             proc    far

start:
                jmp     begin

cddrive         db      0
nocddrive       db      0
noparam         db      0
savesp          dw      0
savess          dw      0
savetempsp      dw      0
oldint21        dd      0
oldint2f        dd      0

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
; Shift name.
;---------------------------------------------------------------
shiftname       proc    near
                push    ds
                push    es
                push    di
                push    ds
                pop     es
                push    dx
                pop     di
                add     si,3
moveit:
                cmp     byte ptr [si],0
                je      exitmoveit
                movsb
                jmp     moveit
exitmoveit:
                mov     byte ptr [di],0
                pop     di
                pop     es
                pop     ds
                ret
shiftname       endp

;---------------------------------------------------------------
; New interrupt 21h. Use to search for certain bytes in memory.
;---------------------------------------------------------------
newint21        proc    far
                push    ax
                push    si
                cmp     ah,3ch
                jne     checkif3d
                push    dx
                pop     si
                mov     al,byte ptr cs:cddrive
                cmp     byte ptr [si],al
                je      int213c
                add     al,20h
                cmp     byte ptr [si],al
                jne     exitnewint21
int213c:
                cmp     byte ptr [si+1],':'
                jne     exitnewint21
                stc
                mov     ax,5
                iret
checkif3d:
                cmp     ah,3dh
                jne     checkif4e
                push    dx
                pop     si
                mov     al,byte ptr cs:cddrive
                cmp     byte ptr [si],al
                je      int213d
                add     al,20h
                cmp     byte ptr [si],al
                jne     exitnewint21
int213d:
                cmp     byte ptr [si+1],':'
                jne     exitnewint21
                call    shiftname
                jmp     exitnewint21
checkif4e:
                cmp     ah,4eh
                jne     checkif60
                push    dx
                pop     si
                mov     al,byte ptr cs:cddrive
                cmp     byte ptr [si],al
                je      int214e
                add     al,20h
                cmp     byte ptr [si],al
                jne     exitnewint21
int214e:
                cmp     byte ptr [si+1],':'
                jne     exitnewint21
                call    shiftname
                push    ax
                push    cx
                push    dx
                push    ds
                pushf
                call    dword ptr cs:oldint21
                pop     ds
                pop     dx
                pop     cx
                pop     ax
                jc      createfile
                pop     si
                pop     ax
                iret
checkif60:
                cmp     ah,60h
                jne     exitnewint21
                mov     al,byte ptr cs:cddrive
                cmp     byte ptr [si],al
                je      int2160
                add     al,20h
                cmp     byte ptr [si],al
                jne     exitnewint21
int2160:
                cmp     byte ptr [si+1],':'
                jne     exitnewint21
                mov     byte ptr ds:[si],0
exitnewint21:
                pop     si
                pop     ax
                jmp     dword ptr cs:oldint21
createfile:
                push    ax
                push    bx
                push    cx
                push    dx
                push    ds
                mov     ah,3ch
                mov     cx,0
                pushf
                call    dword ptr cs:oldint21
                mov     bx,ax
                mov     ah,40h
                push    cs
                pop     ds
                mov     cx,42
                mov     dx,offset cs:info
                pushf
                call    dword ptr cs:oldint21
                mov     ah,3eh
                pushf
                call    dword ptr cs:oldint21
                pop     ds
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                jmp     exitnewint21
newint21        endp

;---------------------------------------------------------------
; Redirect interrupt 2fh through absolute memory access.
;---------------------------------------------------------------
redirect2f      proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,2fh*4
                push    word ptr es:[bx]
                pop     word ptr cs:oldint2f
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint2f+2
                push    offset cs:newint2f
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
redirect2f      endp

;---------------------------------------------------------------
; Redirect interrupt 2fh back to original.
;---------------------------------------------------------------
unredirect2f    proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,2fh*4
                push    word ptr cs:oldint2f
                pop     word ptr es:[bx]
                push    word ptr cs:oldint2f+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect2f    endp

;---------------------------------------------------------------
; New interrupt 2fh. Use to search for certain bytes in memory.
;---------------------------------------------------------------
newint2f        proc    far
                cmp     ax,1500h
                je      int2f1500
                cmp     ax,1501h
                je      int2f1501
                cmp     ax,150bh
                je      int2f150b
                cmp     ax,150dh
                je      int2f150d
                cmp     ax,1510h
                je      int2f1510
                jmp     exitnewint2f
int2f1500:
                cmp     byte ptr cs:nocddrive,1
                jne     setcddrivelet
                mov     bx,1
                mov     cx,cddrivelet2 - cddrivelet1
                iret
int2f1501:
                cmp     byte ptr cs:nocddrive,1
                jne     getcddrivebuf
                mov     byte ptr es:[bx],19h
                mov     word ptr es:[bx+1],0
                mov     word ptr es:[bx+2],0
                iret
int2f150b:
                mov     byte ptr cs:cddrive,'A'
                add     byte ptr cs:cddrive,cl
                mov     bx,0adadh
                xor     ax,ax
                mov     al,cl
                iret
getcddrivebuf:
                pushf
                call    dword ptr cs:oldint2f
                mov     byte ptr cs:cddrive,'A'
                mov     cl,byte ptr es:[bx]
                add     byte ptr cs:cddrive,cl
                iret
int2f150d:
                cmp     byte ptr cs:nocddrive,1
                jne     setcddrivebuf
                mov     byte ptr es:[bx],19h
                iret
int2f1510:
                cmp     byte ptr cs:nocddrive,1
                jne     senddevdrvreq
                stc
                iret
senddevdrvreq:
                mov     ah,85h
                pushf
                call    dword ptr cs:oldint2f
                iret
setcddrivebuf:
                pushf
                call    dword ptr cs:oldint2f
                mov     byte ptr cs:cddrive,'A'
                mov     cl,byte ptr es:[bx]
                add     byte ptr cs:cddrive,cl
                iret
setcddrivelet:
                pushf
                call    dword ptr cs:oldint2f
                mov     byte ptr cs:cddrive,'A'
                add     byte ptr cs:cddrive,cl
                iret
exitnewint2f:
                jmp     dword ptr cs:oldint2f
newint2f        endp

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
; Get and store filename.
;---------------------------------------------------------------
getfilename     proc    near
                push    bx
                push    cx
                push    si
                push    di
                xor     bx,bx
                xor     cx,cx
                mov     cl,ds:paramarea[bx]
                or      cl,cl
                jz      noparameter
                mov     si,82h
                mov     di,offset cs:filename
movename:
                cmp     byte ptr [si],' '
                je      exitmovename
                cmp     byte ptr [si],cr
                je      exitgetparam
                dec     cl
                movsb
                jmp     movename
noparameter:
                mov     byte ptr cs:noparam,1
                jmp     exitgetparam
exitmovename:
                mov     byte ptr [di],0
                or      cl,cl
                jz      exitgetparam
                mov     di,offset cmd_buf
                dec     cl
                mov     byte ptr [di],cl
                inc     cl
                inc     di
                rep     movsb
exitgetparam:
                pop     di
                pop     si
                pop     cx
                pop     bx
                ret
getfilename     endp

;---------------------------------------------------------------
; Set CD-ROM drive.
;---------------------------------------------------------------
setcddrive      proc    near
                push    ax
                push    bx
                push    cx
                mov     ax,1500h
                int     2fh
                or      bx,bx
                jnz     setcddrive1
                xor     cx,cx
                add     cl,cddrivelet2
                jmp     setcddrive2
setcddrive1:
                add     cl,cddrivelet1
setcddrive2:
                mov     byte ptr cs:cddrive,cl
                pop     cx
                pop     bx
                pop     ax
                ret
setcddrive      endp

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
                push    offset cs:credit
                call    writestr
                call    setcddrive
                call    redirect2f
                call    redirect21
                call    getfilename
                cmp     byte ptr cs:noparam,1
                jne     allocmem
                push    offset cs:progusage
                call    writestr
                jmp     exitprog
allocmem:
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
error:
                call    showerror
exitprog:
                call    unredirect21
                call    unredirect2f
                mov     ss,savess
                mov     sp,savesp
                mov     ax,4c00h
                int     21h

credit          db      'Generic CD-ROM file loader V1.0 by Code Breaker.$'
progusage       db      cr,lf,lf,'Usage : CDExec <Program Name> '
                db      '<Parameters - Optional>$'
info            db      'Generic CD-ROM file loader by Code Breaker.'
fail4a          db      cr,lf,lf,'Unable to modify allocated memory blocks.$'
error0          db      cr,lf,lf,'Unknown error code.$'
error2          db      cr,lf,lf,'Unable to load child program.$'
error4          db      cr,lf,lf,'Too many files handles open.$'
error8          db      cr,lf,lf,'Insufficient memory.$'
filename        db      128 dup(0)
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
