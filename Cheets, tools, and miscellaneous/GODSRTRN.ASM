numparamptr     equ     0
paramarea       equ     80h

cseg            segment byte public
                assume  cs:cseg,ds:cseg
		org	100h

trainer         proc    far

start:
                jmp     begin

oldint9         dw      0,347dh
nummemtofree    dw      0
redirected      db      0
oldint21ofs     dw      0
oldint21seg     dw      347dh

trainer         endp

newint21        proc    far
		pushf
		sti
                cmp     byte ptr cs:redirected,1
                je      exitnewint21
		cmp	ax,2509h
                je      redirectint9
                jmp     short exitnewint21
redirectint9:
                cmp     dx,432h
                jne     exitnewint21
                mov     byte ptr cs:redirected,1
		push	bp
		mov	bp,sp
		push	ax
		push	bx
		push	ds
                mov     word ptr cs:oldint9,dx
                mov     word ptr cs:oldint9+2,ds
                mov     ax,[bp+0eh]
                mov     cs:savekbseg,ax
		pop	ds
		push	cs
                mov     dx,offset newint9
		pop	ds
		pop	bx
		pop	ax
		pop	bp
exitnewint21:
		popf
                jmp     dword ptr cs:oldint21ofs

newint9:
		push	ax
		push	di
		push	ds
                mov     ax,cs:savekbseg
		mov	ds,ax
                in      al,60h
                mov     di,offset searchkey
comparekeys:
		cmp	byte ptr cs:[di],0
                je      exitnewint9
		cmp	al,cs:[di]
                je      execkey
		inc	di
		inc	di
		inc	di
                jmp     short comparekeys
execkey:
		inc	di
                jmp     word ptr cs:[di]
exitnewint9:
		pop	ds
		pop	di
		pop	ax
                jmp     dword ptr cs:oldint9
exitnewint92:
		pop	ds
		pop	di
		pop	ax
                jmp     dword ptr cs:oldint9

searchkey       db      4eh
                dw      offset search
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
                db      0

search:
                cmp     word ptr cs:bytesfound,1
                je      exitnewint9
                push    bx
                push    ax
                mov     bx,0
incbx:
                inc     bx
                cmp     bx,0fffeh
                jne     searchfor
                jmp     exitsearch
searchfor:
                cmp     word ptr [bx],0effh
                jne     incbx
                cmp     word ptr [bx+2],224h
                jne     incbx
                mov     cs:saveax,ax
                mov     cs:savefoundofs,bx
                mov     cs:savecx,cx
                mov     cx,20bh
                mov     bx,233h
                call    maketone
                mov     ax,32h
                push    ax
                call    vrtretrace
                pop     ax
                mov     cx,20bh
                mov     bx,20fh
                call    maketone
                mov     cx,20bh
                mov     bx,223h
                call    maketone
                mov     ax,cs:saveax
                mov     bx,cs:savefoundofs
                mov     cx,cs:savecx
                mov     ax,bx
                add     ax,0a399h
                mov     cs:ofs1,ax
                mov     ax,bx
                add     ax,3c18h
                mov     cs:ofs2,ax
                mov     ax,bx
                add     ax,12a2h
                mov     cs:ofs3,ax
                mov     ax,bx
                add     ax,4310h
                mov     cs:ofs4,ax
                mov     ax,bx
                add     ax,0d26ah
                mov     cs:ofs5,ax
                mov     ax,bx
                add     ax,120bh
                mov     cs:ofs6,ax
                mov     ax,bx
                add     ax,0cd4eh
                mov     cs:ofs7,ax
                mov     ax,bx
                add     ax,4415h
                mov     cs:ofs8,ax
                mov     ax,bx
                add     ax,4387h
                mov     cs:ofs9,ax
                mov     ax,bx
                add     ax,0
                mov     cs:ofs10,ax
                mov     word ptr cs:bytesfound,1
exitsearch:
                pop     ax
                pop     bx
                sti
                jmp     exitnewint9
key1ofs:
                mov     di,cs:ofs1
                cmp     di,0
                jne     dokey1
                jmp     exitkey1
dokey1:
                mov     di,cs:ofs1
                xor     word ptr [di],86b9h
                xor     word ptr [di+2],9102h
                mov     di,cs:ofs2
                xor     word ptr [di],2
                mov     di,cs:ofs3
                xor     word ptr [di],2
                mov     di,cs:ofs4
                xor     word ptr [di],96b9h
                xor     word ptr [di+2],9102h
                mov     di,cs:ofs5
                xor     word ptr [di],2
                mov     di,cs:ofs6
                xor     word ptr [di],2
                mov     di,cs:ofs7
                xor     word ptr [di],2
                mov     di,cs:ofs8
                xor     word ptr [di],96b9h
                xor     word ptr [di+2],9102h
                mov     di,cs:ofs9
                xor     word ptr [di],96b9h
                xor     word ptr [di+2],9102h
                xor     cs:done1,1
                cmp     cs:done1,1
                jne     undokey1
                mov     cs:saveax,ax
                mov     cs:savefoundofs,bx
                mov     cs:savecx,cx
                mov     cx,20bh
                mov     bx,0fh
                call    maketone
                mov     cx,416h
                mov     bx,46h
                call    maketone
                mov     ax,cs:saveax
                mov     bx,cs:savefoundofs
                mov     cx,cs:savecx
                jmp     short exitkey1
undokey1:
                mov     cs:saveax,ax
                mov     cs:savefoundofs,bx
                mov     cs:savecx,cx
                mov     cx,416h
                mov     bx,0fh
                call    maketone
                mov     cx,20bh
                mov     bx,46h
                call    maketone
                mov     ax,cs:saveax
                mov     bx,cs:savefoundofs
                mov     cx,cs:savecx
exitkey1:
                jmp     exitnewint92

key2ofs:
                mov     di,cs:ofs10
                cmp     di,0
                jne     dokey2
                jmp     exitkey2
dokey2:
                mov     di,cs:ofs10
                xor     word ptr [di],9e6fh
                xor     word ptr [di+2],92b4h
                xor     word ptr [di+4],93e8h
                xor     cs:done2,1
                cmp     cs:done2,1
                jne     undokey2
                mov     cs:saveax,ax
                mov     cs:savefoundofs,bx
                mov     cs:savecx,cx
                mov     cx,24bh
                mov     bx,0fh
                call    maketone
                mov     cx,496h
                mov     bx,46h
                call    maketone
                mov     ax,cs:saveax
                mov     bx,cs:savefoundofs
                mov     cx,cs:savecx
                jmp     short exitkey2
undokey2:
                mov     cs:saveax,ax
                mov     cs:savefoundofs,bx
                mov     cs:savecx,cx
                mov     cx,496h
                mov     bx,0fh
                call    maketone
                mov     cx,24bh
                mov     bx,46h
                call    maketone
                mov     ax,cs:saveax
                mov     bx,cs:savefoundofs
                mov     cx,cs:savecx
exitkey2:
                jmp     exitnewint92

key3ofs:

exitkey3:
                jmp     exitnewint92

key4ofs:

exitkey4:
                jmp     exitnewint92

key5ofs:

exitkey5:
                jmp     exitnewint92

filename        db      'gods.com',0
trainerby       db      0dh,0ah,'Gods v1.0 Interactive Trainer by '
                db      'Rescue Raider.',0dh,0ah,0dh,0ah,'$'
done1           dw      0
done2           dw      0
bytesfound      dw      0
savekbseg       dw      0
saveax          dw      0
savefoundofs    dw      0
savecx          dw      0
savess          dw      0
savesp2         dw      0
ofs1            dw      0
ofs2            dw      0
ofs3            dw      0
ofs4            dw      0
ofs5            dw      0
ofs6            dw      0
ofs7            dw      0
ofs8            dw      0
ofs9            dw      0
ofs10           dw      0
stack2          db      32 dup('stack   ')
stack2ptr       dw      $-2

newint21        endp

maketone        proc    near
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
                retn
maketone        endp

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
                jne     loc_30
                or      al,3
                out     61h,al
                mov     al,0b6h
                out     43h,al
loc_30:
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

turnoffspeaker  proc    near
                in      al,61h
                and     al,0fch
                out     61h,al
                mov     al,0b6h
                out     43h,al
                retn
turnoffspeaker  endp

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

begin:
                mov     sp,offset stack1ptr
		mov	bx,cs
		mov	ds,bx
		push	es
                mov     ax,3521h
		int	21h
                mov     word ptr oldint21ofs,bx
                mov     word ptr oldint21seg,es
                mov     dx,offset newint21
                mov     ax,2521h
		int	21h
		pop	es
                mov     bx,numparamptr
                mov     bl,ds:paramarea[bx]
                or      bl,bl
                jz      changemem
                add     bx,2
		mov	cx,bx
                mov     si,offset paramarea
                mov     di,offset paramstoredarea
		rep	movsb
changemem:
                mov     bx,0b3h
                mov     ah,4ah
		int	21h
                jnc     allocatemem
		push	ax
		mov	ah,9
                mov     dx,offset unabletofree
		int	21h
                jmp     short displayerrors
allocatemem:
		mov	ah,9
                mov     dx,offset programby
		int	21h
		push	es
                mov     bx,280h
                mov     ah,48h
		int	21h
                mov     nummemtofree,ax
                mov     es,ax
                mov     ah,49h
		int	21h
		pop	es
		mov	ax,cs
                mov     fcb,ax
                mov     fcb2,ax
                mov     envstr,ax
                mov     dx,offset filename
                mov     bx,offset paramblock
                mov     savesp,sp
                mov     ax,4b00h
		int	21h
		mov	cx,cs
		mov	ss,cx
                mov     sp,cs:savesp
		mov	ds,cx
		mov	es,cx
                jnc     exitprog
		push	ax
		mov	ah,9
                mov     dx,offset unabletoload
		int	21h
displayerrors:
		pop	ax
		cmp	ax,2
                je      filenotfoundmsg
		cmp	ax,4
                je      toomanyfilemsg
		cmp	ax,8
                je      notenoughmemmsg
                mov     dx,offset unknownerror
                jmp     short writestr
filenotfoundmsg:
                mov     dx,offset filenotfound
                jmp     short writestr
toomanyfilemsg:
                mov     dx,offset toomanyfile
                jmp     short writestr
notenoughmemmsg:
                mov     dx,offset notenoughmem
writestr:
		mov	ah,9
		int	21h
exitprog:
                push    ds
                lds     dx,dword ptr cs:oldint21ofs
                mov     al,21h
                mov     ah,25h
		int	21h
		pop	ds
                mov     ax,4c00h
		int	21h

programby       db      'Generic Interactive Trainer Program v2.1 by '
                db      'RBM & RR.',0dh,0ah,'$'
unabletofree    db      'Unable to free memory for the child '
                db      'program!',0dh,0ah,'$'
unabletoload    db      'Unable to load program!',0dh,0ah,'$'
unknownerror    db      '<<< UNKNOWN ERROR CODE >>>',0dh,0ah,'$'
filenotfound    db      '<<< File not found >>>',0dh,0ah,'$'
toomanyfile     db      '<<< Too many open files >>>',0dh,0ah,'$'
notenoughmem    db      '<<< Not enough memory >>>',0dh,0ah,'$'
savesp          dw      0
paramblock      dw      0
                dw      offset paramstoredarea
fcb             dw      347dh
                db      5ch,0
fcb2            dw      0
                db      6ch,0
envstr          dw      0
paramstoredarea db      0,' '
                db      80 dup(0)
stack1          db      32 dup ('stack   ')
stack1ptr       dw      $-2

cseg            ends
		end	start
