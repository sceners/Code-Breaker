numparamptr     equ     0
paramarea       equ     80h
searchofs1      equ     24e3h
searchofs2      equ     24e6h

cseg            segment byte public
                assume  cs:cseg,ds:cseg
		org	100h

fix             proc    far

start:
                jmp     begin

oldint1cofs     dw      0
oldint1cseg     dw      0
oldint21ofs     dw      0
oldint21seg     dw      0
oldint1ofs      dw      0
oldint1seg      dw      0
oldint3ofs      dw      0
oldint3seg      dw      0
found           db      0
counter         db      20

fix             endp

newint1c        proc    far
                cmp     byte ptr cs:found,1
                je      exitint2
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    ds
                push    es
                push    bp
                mov     bp,sp
		sub	sp,2
                mov     ax,cs
		mov	ds,ax
		mov	ax,cs
		mov	[bp-2],ax
                dec     counter
                cmp     byte ptr counter,0
                je      checkiffound
                jmp     execint2
checkiffound:
                cmp     byte ptr found,0
                je      search1
                jmp     jmptoexit
exitint2:
                jmp     dword ptr cs:oldint1cofs
search1:
                mov     ax,[bp-2]
                push    ax
                mov     di,searchofs1
                pop     es
                cmp     word ptr es:[di],0c483h
                je      search2
                jmp     incbase
search2:
                cmp     byte ptr es:[di+2],0ah
                je      fixmem
                jmp     execint1
fixmem:
                mov     byte ptr found,1
                mov     ax,[bp-2]
                push    ax
                mov     di,searchofs2
                pop     es
                mov     word ptr es:[di],0b850h
                mov     word ptr es:[di+2],010h
                mov     word ptr es:[di+4],58a3h
                mov     word ptr es:[di+6],583dh
                mov     word ptr es:[di+8],9090h
                jmp     short incbase
execint1:
                pushf
                call    dword ptr cs:oldint1cofs
incbase:
		inc	word ptr [bp-2]
                jmp     checkiffound
jmptoexit:
                jmp     short exitnewint
execint2:
                pushf
                call    dword ptr cs:oldint1cofs
exitnewint:
                mov     sp,bp
                pop     bp
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                iret
newint1c        endp

newint1         proc    far
                jmp     beginprog
newint1         endp

newint3         proc    far
                int     1
newint3         endp

begin:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    ds
                push    es
                push    bp
                mov     bx,4
                push    0
                pop     es
                mov     ax,word ptr es:[bx]
                mov     oldint1ofs,ax
                mov     ax,word ptr es:[bx+2]
                mov     oldint1seg,ax
                mov     ax,offset newint1
                mov     word ptr es:[bx],ax
                mov     ax,cs
                mov     word ptr es:[bx+2],ax
                mov     bx,0ch
                mov     ax,word ptr es:[bx]
                mov     oldint3ofs,ax
                mov     ax,word ptr es:[bx+2]
                mov     oldint3seg,ax
                mov     ax,offset newint3
                mov     word ptr es:[bx],ax
                mov     ax,cs
                mov     word ptr es:[bx+2],ax
                pop     bp
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                int     3
terminate:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    ds
                push    es
                push    bp
                mov     bx,4
                push    0
                pop     es
                mov     ax,oldint1ofs
                mov     word ptr es:[bx],ax
                mov     ax,oldint1seg
                mov     word ptr es:[bx+2],ax
                mov     bx,4
                mov     ax,oldint3ofs
                mov     word ptr es:[bx],ax
                mov     ax,oldint3seg
                mov     word ptr es:[bx+2],ax
                pop     bp
                pop     es
                pop     ds
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                lea     dx,endmsg
                call    writestr
                mov     ax,4c00h
		int	21h

writestr        proc    near
                mov     ah,9
                int     21h
                ret
writestr        endp

beginprog:
                mov     sp,offset stack1ptr
                mov     ax,cs
                mov     ds,ax
                push    es
                mov     ax,351ch
                int     21h
                mov     word ptr cs:oldint1cofs,bx
                mov     word ptr cs:oldint1cseg,es
                mov     dx,offset newint1c
                mov     ax,251ch
                int     21h
                pop     es
                mov     bx,numparamptr
                mov     bl,ds:paramarea[bx]
                or      bl,bl
                jz      changemem
                add     bx,2
                mov     cx,bx
                mov     si,offset paramarea
                mov     di,offset paramstoredarea
                rep     movsb
changemem:
                mov     bx,0b3h
                mov     ah,4ah
                int     21h
                jnc     allocatemem
                lea     dx,allocateerror
                call    writestr
                jmp     exitprog
allocatemem:
                push    es
                mov     bx,280h
                mov     ah,48h
                int     21h
                mov     es,ax
                mov     ah,49h
                int     21h
                pop     es
                mov     ax,cs
                mov     fcb,ax
                mov     fcb2,ax
                mov     envstr,ax
                mov     dx,offset filename
                mov     bx,offset paramblock
                mov     savesp,sp
                mov     ax,4b00h
                int     21h
                mov     ax,cs
                mov     ss,ax
                mov     sp,cs:savesp
                mov     ds,ax
                mov     es,ax
                jnc     exitprog
                lea     dx,filenotfound
                call    writestr
exitprog:
                push    ds
                lds     dx,dword ptr cs:oldint1cofs
                mov     ax,251ch
                int     21h
                pop     ds
                jmp     terminate

msg             db      '''Prince Of Persia'' V1.1 unprotect by Code Breaker.$'
endmsg          db      0dh,0ah,'''Prince Of Persia'' unprotect by Code Breaker.'
                db      0dh,0ah,'Greetings : Flip Boy, The Rocketeer, and '
                db      'The Silicon Soldier.$'
savesp          dw      0
paramblock      dw      0
                dw      offset paramstoredarea
fcb             dw      0
                db      5ch,0
fcb2            dw      0
                db      6ch,0
envstr          dw      0
paramstoredarea dw      0,20h
                db      80 dup(0)
filename        db      'Prince.exe',0
allocateerror   db      'Error in allocating memory.',0dh,0ah,'$'
filenotfound    db      '''Prince.exe'' - not found.',0dh,0ah,'$'
stack1          db      'stack   stack   stack   stack   '
		db	'stack   stack   stack   stack   '
		db	'stack   stack   stack   stack   '
		db	'stack   stack   stack   stack   '
		db	'stack   stack   stack   stack   '
		db	'stack   stack   stack   stack   '
		db	'stack   stack   stack   stack   '
		db	'stack   stack   stack   stack   '
stack1ptr       dw      $-2

cseg            ends
		end	start
