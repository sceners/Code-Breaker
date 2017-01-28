                extrn   drivelet:byte
                public  getfreespace
                public  checkdrive

;---------------------------------------------------------------
; Code segment
;---------------------------------------------------------------
cseg            segment para use16 'code'
                assume  cs:cseg,ds:nothing,ss:nothing

checkdrive      proc
                push    ax
                push    bx
                stc
                mov     ax,4408h
                mov     bl,drivelet
                int     21h
                jc      exitcheckdrive
                cmp     ax,1
                jne     exitcheckdrive
                clc
exitcheckdrive:
                pop     bx
                pop     ax
                retf
checkdrive      endp


getfreespace    proc
                push    dx
                mov     ah,36h
                mov     dl,drivelet
                int     21h
                pop     dx
                retf
getfreespace    endp

cseg            ends
                end

