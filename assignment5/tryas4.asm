CDSEG SEGMENT
MAIN    PROC FAR  
        ASSUME CS:CDSEG;,DS:DTSEG
        ;MOV AX,DTSEG
        ;MOV DS,AX
        
        SUB SP,4 ;int a
        
        CALL FOO
        
        MOV BP,SP
        ;MOV [BP],RETURN_VAL
        ADD SP,4
        
        MOV AH,4CH
        INT 21H
MAIN    ENDP 

FOO     PROC 
    
        SUB SP,12 ;int a,b,c
        ;...
        ADD SP,12 ;cleam
        
        RET 
FOO     ENDP 

CDSEG ENDS
        END MAIN       
