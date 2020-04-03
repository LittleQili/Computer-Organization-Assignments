DTSEG SEGMENT
INI_WORD DW  7FFH ;you can freely change from -7FFH to 7FFH
ABS_WORD DW  0  
DTSEG ENDS

CDSEG SEGMENT
MAIN    PROC FAR  
        ASSUME CS:CDSEG,DS:DTSEG
        MOV AX,DTSEG
        MOV DS,AX
        
        MOV AX,INI_WORD
        CMP AX,0
        JGE DST  
        MOV BX,AX
        MOV AX,0
        SUB AX,BX
DST:    MOV [ABS_WORD],AX  

;_DEBUG: MOV BX,ABS_WORD
;        MOV CX,INI_WORD
        
        MOV AH,4CH
        INT 21H
MAIN    ENDP   
CDSEG ENDS
        END MAIN       
