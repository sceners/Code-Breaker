cr              equ     0dh
lf              equ     0ah
fileofs         equ        1h
fileseg         equ        0h
movecode        equ         0
opencode        equ         1
numbytes        equ         1
       
cseg            segment byte public
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
                org     100h

patch           proc    far
start:
                jmp     begin

patch           endp

;---------------------------------------------------------------
; Open file.
;---------------------------------------------------------------
openfile        proc    near
                mov     al,opencode
                mov     dx,offset cs:filename
                mov     ah,3dh
                int     21h
                ret
openfile        endp

;---------------------------------------------------------------
; Close file.
;---------------------------------------------------------------
closefile       proc    near
                mov     ah,3eh
                int     21h
                ret
closefile       endp

;---------------------------------------------------------------
; Write to file.
;---------------------------------------------------------------
writetofile     proc    near
                mov     cx,numbytes
                mov     dx,offset cs:patchbytes
                mov     ah,40h
                int     21h
                ret
writetofile     endp

;---------------------------------------------------------------
; Move to location in file.
;---------------------------------------------------------------
moveto          proc    near
                mov     bx,ax
                mov     al,movecode
                mov     cx,fileofs
                mov     dx,fileseg
                mov     ah,42h
                int     21h
                ret
moveto          endp

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
                cmp     ax,1
                je      em1
                cmp     ax,2
                je      em2
                cmp     ax,3
                je      em3
                cmp     ax,4
                je      em4
                cmp     ax,5
                je      em5
                push    offset error0
                jmp     writeerror
em1:
                push    offset error1
                jmp     writeerror
em2:
                push    offset error2
                jmp     writeerror
em3:
                push    offset error3
                jmp     writeerror
em4:
                push    offset error4
                jmp     writeerror
em5:
                push    offset error5
writeerror:
                call    writestr
                pop     ax
                ret
showerror       endp

;---------------------------------------------------------------
; Main execution block.
;---------------------------------------------------------------
begin:
                push    offset cs:credit
                call    writestr
                call    openfile
                jnc     openok
                jmp     error
openok:
                call    moveto
                jnc     moveok
                jmp     error
moveok:
                call    writetofile
                jnc     writeok
                jmp     error
writeok:
                call    closefile
                jnc     patchok
error:
                call    showerror
                jmp     exitprog
patchok:
                push    offset cs:patchokmsg
                call    writestr
exitprog:
                push    offset cs:endmsg
                call    writestr
                mov     ax,4c00h
                int     21h

credit          db      '  ีอออออออออออออออออออออออออออออออต PENT/ดGRAM ฦอออออออออออออออออออออออออออออธ',cr,lf
                db      '  ณ PENT/ดGRAM PROUDLY PRESENTS - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   ณ',cr,lf
                db      '  ณ                                                                          ณ',cr,lf
                db      '  ณ Greetings - The Rocketeer, Flip Boy, Fanfan, Dr. Insanity, Faceless      ณ',cr,lf
                db      '  ณ           - Viper, Silicon Soldier, all PTG members and everyone else... ณ',cr,lf
                db      '  ิออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออพ',cr,lf,'$'
patchokmsg      db      cr,lf,'  ีอออออออออออออออออออออออออออออออต PENT/ดGRAM ฦอออออออออออออออออออออออออออออธ',cr,lf
                db            '  ณ Patch was successfully. Type        to start game.                       ณ',cr,lf
                db            '  ิออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออพ',cr,lf,'$'
endmsg          db      cr,lf,'  ีอออออออออออออออออออออออออออออออต PENT/ดGRAM ฦอออออออออออออออออออออออออออออธ',cr,lf
                db            '  ณ Thank you for using PENT/ดGRAM generic patcher v1.0 by Code Breaker.     ณ',cr,lf
                db            '  ิออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออพ$'
error0          db      cr,lf,'  Unknown error code.',cr,lf,'$'
error1          db      cr,lf,'  Invalid function.',cr,lf,'$'
error2          db      cr,lf,'  ''ptg.com'' - not found.',cr,lf,'$'
error3          db      cr,lf,'  Path not found.',cr,lf,'$'
error4          db      cr,lf,'  Too many files handles open.',cr,lf,'$'
error5          db      cr,lf,'  Access denied.',cr,lf,'$'
filename        db      'ptg.com',0
patchbytes      db      0ebh
lastbyte        equ     $

cseg            ends
                end     start

