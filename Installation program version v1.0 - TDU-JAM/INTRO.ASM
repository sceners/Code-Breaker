;---------------------------------------------------------------
; Intro menu equates
;---------------------------------------------------------------
vgaseg          equ     0a000h                  ; VGA segment
introsize       equ        911                  ; intro size

;---------------------------------------------------------------
; Code segment
;---------------------------------------------------------------
                public  drawpic
                public  setpalette

cseg            segment para use16 'code'
                assume  cs:cseg,ds:nothing,ss:nothing

;---------------------------------------------------------------
; Draw picture on screen.
;---------------------------------------------------------------
drawpic         proc
                push    ax
                push    di
                push    si
                push    cx
                push    ds
                push    es
                push    cs
                pop     ds
                mov     cx,introsize
                mov     ax,vgaseg
                mov     es,ax
                mov     si,offset cs:introscr
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
                retf
drawpic         endp

;---------------------------------------------------------------
; Set palettes to.
;---------------------------------------------------------------
setpalette      proc
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
                retf
setpalette      endp

introscr        label   byte                    ; picture image
                include tdujam
palette         label   byte                    ; picture palettes
                include tdujam.pal

cseg            ends
                end
