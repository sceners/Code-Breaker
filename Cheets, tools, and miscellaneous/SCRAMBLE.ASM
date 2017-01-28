cr              equ     0dh
lf              equ     0ah
xorkey          equ     1
filesize        equ     2153h

cseg            segment
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
		org	100h

scrambler       proc    far

start:
                jmp     begin

inbuffer        db      filesize dup(?)
outbuffer       db      filesize dup(?)
infilehandle    dw      0
outfilehandle   dw      0
savesp          dw      0
savess          dw      0

scrambler       endp

scramblefile    proc    near
                push    ax
                push    bx
                push    cx
                push    dx
                mov     bx,offset inbuffer
                mov     dx,offset outbuffer
                mov     cx,ax
movebyte:
                mov     al,byte ptr cs:[bx]
                add     al,xorkey
                push    bx
                mov     bx,dx
                mov     byte ptr cs:[bx],al
                pop     bx
                inc     bx
                inc     dx
                loop    movebyte
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret
scramblefile    endp

closefile       proc    near
                mov     ah,3eh
                int     21h
                ret
closefile       endp

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
                mov     dx,offset outfile
                mov     cx,0
                mov     ah,3ch
                int     21h
                mov     outfilehandle,ax
                mov     dx,offset infile
                mov     ah,3dh
                mov     al,0
                int     21h
                mov     infilehandle,ax
                mov     bx,ax
                mov     dx,offset inbuffer
                mov     cx,filesize
                mov     ah,3fh
                int     21h
                call    scramblefile
                push    ax
                mov     bx,outfilehandle
                mov     dx,offset headerbuffer
                mov     cx,numbytes
                push    cx
                mov     ah,40h
                int     21h
                pop     cx
                pop     ax
                mov     bx,outfilehandle
                mov     dx,offset outbuffer
                mov     cx,ax
                push    cx
                mov     ah,40h
                int     21h
                pop     cx
exitprog:
                mov     bx,infilehandle
                call    closefile
                mov     bx,outfilehandle
                call    closefile
                mov     ss,savess
                mov     sp,savesp
                mov     ax,4c00h
                int     21h

headerbuffer:
                db      718 dup (0cdh,1,0cch)
                push    cs
                pop     ds
                mov     bx,offset infile-headerbuffer
                add     bx,100h
                mov     dx,100h
                mov     cx,filesize
xorbyte:
                mov     al,byte ptr cs:[bx]
                sub     al,xorkey
                push    bx
                mov     bx,dx
                mov     byte ptr cs:[bx],al
                pop     bx
                inc     bx
                inc     dx
                loop    xorbyte
                jmp     headerbuffer

numbytes        equ     $-offset headerbuffer
infile          db      'mpcht.com',0
outfile         db      'mpcht2.com',0
userstack       db      32 dup ('STACK   ')
userstackptr    equ     $-2

cseg            ends
                end     start
