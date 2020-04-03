;Question: why inverse?
.MODEL SMALL
.STACK 64
.DATA

COUNT DW 100
ARRAY DB  0

.CODE
MAIN    PROC FAR
        MOV AX,@DATA
        MOV DS,AX
        
        MOV CX,COUNT
        MOV BX,OFFSET ARRAY
        MOV AL,0  
        
_LOOP:  MOV [BX],AL
        INC BX
        INC AX
        DEC CX
        JNZ _LOOP
        
;_DEBUG: MOV BX,OFFSET ARRAY+20
        
        MOV AH,4CH
        INT 21H
MAIN    ENDP
        END MAIN