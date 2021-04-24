                                                             .MODEL SMALL
   .DATA
COUNT DW 200
BLINGK DW 50
_MULT DW 5
   .STACK 64
   .CODE
PortIn	EQU	90h	;定义输入端口号
PortOut	EQU	0A0H	;定义输出端口号
main proc far
	        ;State 0
		MOV DX,_MULT
	        MOV AL,36H
STATE0:    	MOV CX,COUNT
_STATE0:   	OUT PortOut,AL
	        DEC CX
	        JNZ _STATE0
	        DEC DX
	        JNZ STATE0
		
	        ;State 1
_LOOP:          MOV DX,_MULT    ;Endless loop begins here
		MOV AL,33H
STATE1:    	MOV CX,COUNT
_STATE1:        OUT PortOut,AL
	        DEC CX
	        JNZ _STATE1
	        DEC DX
	        JNZ STATE1
		
		;State 2
		;Green blinks
	        MOV DX,4
STATE2_1:       MOV CX,BLINGK
		MOV AL,33H
_STATE2_1_ON:   OUT PortOut,AL
		DEC CX
		JNZ _STATE2_1_ON
		MOV CX,BLINGK
		MOV AL,37H
_STATE2_1_OFF:  OUT PortOut,AL
		DEC CX
		JNZ _STATE2_1_OFF
		DEC DX
		JNZ STATE2_1
	        ;Yellow
		MOV DX,2
		  MOV AL,35H
STATE2_2:    	MOV CX,BLINGK
_STATE2_2:   	OUT PortOut,AL
		DEC CX
		JNZ _STATE2_2
		DEC DX
                JNZ STATE2_2
       
                ;State 3
                MOV DX,_MULT
                MOV AL,1EH
STATE3:         MOV CX,COUNT
_STATE3:        OUT PortOut,AL
                DEC CX
                JNZ _STATE3
                DEC DX
                JNZ STATE3
       
                ;State 4
		;Green blinks
		MOV DX,4
STATE4_1:       MOV CX,BLINGK
                MOV AL,1EH
_STATE4_1_ON:   OUT PortOut,AL
                DEC CX
	        JNZ _STATE4_1_ON
		MOV CX,BLINGK
	        MOV AL,3EH
_STATE4_1_OFF:  OUT PortOut,AL
	        DEC CX
	        JNZ _STATE4_1_OFF
	        DEC DX
	        JNZ STATE4_1
	        ;Yellow
	        MOV DX,2
	        MOV AL,2EH
STATE4_2:       MOV CX,BLINGK
_STATE4_2:      OUT PortOut,AL
	        DEC CX
	        JNZ _STATE4_2
                DEC DX
	        JNZ STATE4_2
       
	        JMP _LOOP
main endp
END	main				;指示汇编程序结束编译