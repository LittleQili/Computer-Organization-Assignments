;PAGE 245
STSEG SEGMENT  
      DB 128 DUP
STSEG ENDS

DTSEG SEGMENT
    A DW 0000,0000
    B DW 0000,0000
    C DW 0000,0000
    D DW 0000,0000
DTSEG ENDS

CDSEG SEGMENT  
;------------MAIN FUNC------------
MAIN    PROC FAR  
        ASSUME CS:CDSEG,DS:DTSEG
        MOV AX,DTSEG
        MOV DS,AX 
        ;A=-1
        MOV AX,-1
        MOV [A],AX
        SAR AX,15
        MOV [A]+2,AX
        ;B=1
        MOV AX,1
        MOV [B],AX
        SAR AX,15
        MOV [B]+2,AX
        ;ABS(A) 
        PUSH [A]
        PUSH [A]+2
        
        CALL ABS 
        ;C=ABS(A)
        MOV BP,SP
        MOV CX,[BP]
        MOV BX,[BP]+2
        ADD SP,4
        
        MOV [C],BX
        MOV [C]+2,CX
        ;ADD(A,B)
        PUSH [A]
        PUSH [A]+2
        PUSH [B]
        PUSH [B]+2 
        
        CALL _ADD
        ;D=ADD(A,B)
        MOV BP,SP
        MOV AX,[BP]+2
        MOV BX,[BP] 
        ADD SP,8
        
        MOV [D],AX
        MOV [D]+2,BX
        
        MOV AH,4CH
        INT 21H
MAIN    ENDP   
;-----------ABS FUNC---------
ABS     PROC
    
        MOV BP,SP
        MOV CX,[BP]+2
        MOV BX,[BP]+4
        
        CMP CX,0
        JGE DST  
        NOT BX
        NOT CX
        ADD BX,1
        JNC  DST
        ADD CX,1
DST:    MOV [BP]+2,CX
        MOV [BP]+4,BX
        RET
ABS     ENDP
;----------ADD FUNC----------
_ADD    PROC
        
        MOV BP,SP
        MOV DX,[BP]+2
        MOV CX,[BP]+4
        MOV BX,[BP]+6
        MOV AX,[BP]+8
        
        ADD AX,CX
        JNC DST_ADD
        ADD DX,1
DST_ADD:ADD BX,DX
        
        MOV [BP]+2,BX
        MOV [BP]+4,AX
            
        RET
_ADD    ENDP
        

CDSEG ENDS
        END MAIN