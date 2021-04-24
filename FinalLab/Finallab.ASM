;--------------------------------------------------------------------------
;
;              Build this with the "Source" menu using
;                     "Build All" option
;
;--------------------------------------------------------------------------
;
;                           课程设计程序通用框架
;
;--------------------------------------------------------------------------
; 功能：通过8253定时，产生中断信号，在4位数码管上稳定显示0,1,2,3四个数字			                            				   |
; 编写：《计算机组成原理》课程组                  				   |
; 版本：
;--------------------------------------------------------------------------


		DOSSEG
		.MODEL	SMALL		; 设定8086汇编程序使用Small model
		.8086				; 设定采用8086汇编指令集

;-----------------------------------------------------------
;	定义堆栈段                                             |
;-----------------------------------------------------------
	.stack 100h				; 定义256字节容量的堆栈

;-------------------------------------------------------------------------
;	符号定义                                                              |
;-------------------------------------------------------------------------
;
;
; 8253芯片端口地址 （Port Address):
L8253T0			EQU		100h		; Even Timer0's address in I/O space, 108H as well.
									; 101H, 109H for high order byte access.
L8253T1			EQU 	102h		; Timer1's address in I/O space
									; 103H, 10BH for high order byte access.
L8253T2			EQU 	104h		; Timer2'saddress in I/O space
									; 105H, 10DH for high order byte access.
L8253CS			EQU 	106h		; 8253 Control Register's address in I/O space
									; 107H, 10FH for high order byte access.
;
; 8255芯片端口地址 （Port Address):
L8255PA			EQU		121h		; Odd Port A's address in I/O space, 129H as well.
									; 120H, 128H for low order byte access.
L8255PB			EQU 	123h		; Odd Port B's address in I/O space, 12BH as well.
									; 122H, 12AH for low order byte access.
L8255PC			EQU 	125h		; Odd Port C's address in I/O space, 13DH as well.
									; 124H, 12CH for low order byte access.
L8255CS			EQU 	127h		; 8255 Control Register's port number in I/O space, 12FH as well
									; 126H, 12EH for low order byte access.
;
;  中断矢量号定义
IRQNum			EQU		20h			; 中断矢量号,要根据学号计算得到后更新此定义。

Patch_Proteus	EQU		IN AL, 0	;	Simulation Patch for Proteus, please ignore this line

;=======================================================================
; 宏定义
;=======================================================================

; 修补Proteus仿真的BUG，参见程序段中的使用说明
    WaitForHWInt MACRO IRQNum		; IRQNum is the HW INT number
		MOV AL, IRQNum   			;
		OUT 0,AL					;
    ENDM

;-----------------------------------------------------------
;	定义数据段                                             |
;-----------------------------------------------------------
		.data					; 定义数据段;
;DisplayDigit函数的两个参数，DisplayDigit在DisplayIndex处的数码管显示DisplayVal数值
DisplayIndex 	db 	0			;DisplayIndex可取0,1,2,3 分别对应从左往右第1,2,3,4个数码管

;----------------------------------------------------------
;下面是我的定义data段                                         |
;----------------------------------------------------------
;以下部分用于计数，发生多少次中断，以便控制时间
LEDDisplayCount db 0 ;三项功能统一使用参数，主要用于四位数码管切换：1时切换，0时保持。
OneMinuteCount dw 0;字面意思，11999时切换。
OneSecondCount db 0;字面意思，199时切换。
ButtonTwoPushTimes db 0;记录BT2被按下的次数，0，1，2分别对应三种模式。
;以下部分是数码管显示的数据
ModeOneData dw 517h ;第一问，显示日期
ModeTwoData dw 1959h ;第二问，显示分钟时间
ModeThreeData dw 1000h ;第三问，显示倒计时

; SEGTAB示字符0-F
SEGTAB  DB 3FH	; 7-Segment Tube, 共阴极类型的7段数码管示意图
		DB 06H	;
		DB 5BH	;            a a a
		DB 4FH	;         f         b
		DB 66H	;         f         b
		DB 6DH	;         f         b
		DB 7DH	;            g g g 
		DB 07H	;         e         c
		DB 7FH	;         e         c
		DB 6FH	;         e         c
        DB 77H	;            d d d     h h h
		DB 7CH	; ----------------------------------
		DB 39H	;       b7 b6 b5 b4 b3 b2 b1 b0
		DB 5EH	;       DP  g  f  e  d  c  b  a
		DB 79H	;
		DB 71H	;

;-----------------------------------------------------------
;	定义代码段                                             |
;-----------------------------------------------------------
		.code						; Code segment definition
		.startup					; 定义汇编程序执行入口点
;------------------------------------------------------------------------
		Patch_Proteus				; Simulation Patch for Proteus,
									; Please ignore the above code line.
;------------------------------------------------------------------------
;=========================================================================
;               Main Function 主程序

;--------------------------------------------------
;               Initialization 初始化               |
;--------------------------------------------------
START:								
		CLI					 		; clear IF
		MOV AX, @DATA				
		MOV DS, AX					; 初始化DS段寄存器
		;需要先初始化好中断，再设置8253；否则定时中断产生后，执行的ISR未必是我们写的ISR
		MOV  BL, IRQNum				; 取得中断矢量号
		CALL INT_INIT				; 初始化中断向量表

		CALL INIT8255				; 初始化8255 
		CALL INIT8253				; 初始化8253  

		STI 						; set IF

;--------------------------------------------------
;               Endless Loop 主循环                 |
;--------------------------------------------------	
	
Display_Again:
		;1: Detect BT2 & Change ButtonTwoPushTimes
		MOV DX, L8255PC
		IN AL, DX
		AND AL, 1H
		CMP AL, 1H
		JNZ NChangeMode
		MOV AH, ButtonTwoPushTimes
		INC AH
		CMP AH, 3
		JNZ NZTimes
		MOV AH, 0
NZTimes:        MOV ButtonTwoPushTimes, AH
		MOV AL, 00000000B
		OUT DX, AL
		MOV AL, 00010000B
		OUT DX, AL
		
		;2: Change the display value of Mode2&3
NChangeMode: 		
		;MODE 3 CHANGE VALUE
		CMP OneSecondCount, 199
		JNZ NChangeSecond
		MOV OneSecondCount, 0
		CALL CountDown
NChangeSecond: 	
		;MODE 2 CHANGE VALUE 
		MOV AX, 11999
		CMP OneMinuteCount, AX
		JNZ NChangeMinute
		MOV OneMinuteCount, 0
		CALL ChangeMinute
NChangeMinute: 	
		
		;Update LED digit every 5ms
		CMP LEDDisplayCount,1
		JNZ NChangeDigit
		
		;3: Choose Mode According to ButtonTwoPushTimes
		MOV AL, ButtonTwoPushTimes
		CMP AL, 2
		JZ ModeThree
		CMP AL, 1
		JZ ModeTwo
		
		;ModeOne:
		MOV LEDDisplayCount,0
		CALL DisplayModeOne
		MOV AL, DisplayIndex
		INC AL
		AND AL, 3H
		MOV DisplayIndex, AL
		JMP Display_Again

		;ModeThree:
ModeThree: 
		MOV LEDDisplayCount,0
		CALL DisplayModeThree
		MOV AL, DisplayIndex
		INC AL
		AND AL, 3H
		MOV DisplayIndex, AL
		JMP Display_Again
		
		;ModeTwo:
ModeTwo:
		MOV LEDDisplayCount,0
		CALL DisplayModeTwo
		MOV AL, DisplayIndex
		INC AL
		AND AL, 3H
		MOV DisplayIndex, AL
		JMP Display_Again
		
NChangeDigit:		
		JMP Display_Again
		HLT							; 停止主程序运行
;=====================================================================================
;              Functions in Main Loop

;------------------------------------------------------------
; DisplayFunc0
; Display value in AX to LED digit BL
; Parameter: 
;    AX--Display Number, use 4-bits to store one digit value
;    BL--The Offset of LED digit, left->right 0->3
;------------------------------------------------------------

GetDigitNumber_Display PROC;use AX,BL to pass parameter
		MOV BH, 3
		SUB BH, BL
		MOV CL, 2
		SHL BH, CL
		MOV CL, BH
		SHR AX, CL
		AND AX, 0FH
GDN_Display:
		MOV AH, AL	
		;根据DisplayIndex，选中当前要刷新的数码管
		MOV AL, 01h     
		MOV CL, BL
		SHL AL, CL      
		NOT AL     
		MOV DX, L8255PA			
		OUT DX, AL
		;根据DisplayVal，确定当前选中的数码管要显示的数值
		MOV BL, AH
		MOV AX, OFFSET SEGTAB
		XOR BH, BH
		ADD BX, AX
		MOV AL, BYTE PTR [BX]  
		MOV DX, L8255PB		
		OUT DX, AL 
		
		RET
GetDigitNumber_Display ENDP

;------------------------------------------------------------
; DisplayFunc1-3
; Display in Mode 1,2,3
; No parameter
;------------------------------------------------------------
DisplayModeOne PROC
		MOV AX, ModeOneData
		MOV BL, DisplayIndex
		CALL GetDigitNumber_Display
		RET
DisplayModeOne ENDP

DisplayModeTwo PROC
		MOV AX, ModeTwoData
		MOV BL, DisplayIndex
		CALL GetDigitNumber_Display
		RET
DisplayModeTwo ENDP

DisplayModeThree PROC
		MOV AX, ModeThreeData
		MOV BL, DisplayIndex
		CALL GetDigitNumber_Display
		RET
DisplayModeThree ENDP

;------------------------------------------------------------
; CalculateFunc0
; Change the Hour:Minute value in ModeTwoData
; No parameter
;------------------------------------------------------------

ChangeMinute PROC
		MOV AX, ModeTwoData
		INC AX
		MOV BL, AL
		AND BL, 0FH
		CMP BL, 0AH
		JB CM_END
		AND AX, 0FFF0H
		ADD AX, 10H
		CMP AL, 60H
		JB CM_END
		MOV AL, 0
		INC AH
		MOV BL, AH
		AND BL, 0FH
		CMP BL, 0AH
		JB CM_CMP24
		AND AH, 0F0H
		ADD AH, 10H
CM_CMP24: 	CMP AH, 24H
		JB CM_END
		MOV AH, 0
CM_END: 	MOV ModeTwoData, AX
		RET
ChangeMinute ENDP

;------------------------------------------------------------
; CalculateFunc1
; Change the Count Down value in ModeThreeData
; No parameter
;------------------------------------------------------------

CountDown PROC
		MOV AX, ModeThreeData
		DEC AX
		MOV BL, AL
		AND BL, 0FH
		CMP BL, 0FH
		JNZ CD_END
		AND AL, 0F9H
		CMP AL, 0F9H
		JNZ CD_END
		AND AL, 9FH
		MOV BL, AH
		AND BL, 0FH
		CMP BL, 0FH
		JNZ CD_END
		AND AH, 0F9H
		CMP AH, 0F9H
		JNZ CD_END
		MOV AX, 1000H
CD_END:
		MOV ModeThreeData, AX
		RET
CountDown ENDP
;=====================================================================================
;              Initialization Functions

;--------------------------------------------
; INIT 8255 (Changed)					            
; Add: Output Initial value of PC0 & PC4 to PortC
;--------------------------------------------
INIT8255 PROC

; Init 8255 in Mode 0,	L8255PA Output, L8255PB Output,	L8255PC LOW Input, L8255PC UP Output
		MOV DX, L8255CS
		MOV AL, 10000001B			; Control Word
; 发送控制字到8255
		OUT DX, AL
		;my code
		MOV DX, L8255PC
		MOV AL, 00010000B
		OUT DX, AL
		
		RET
INIT8255 ENDP

;--------------------------------------------
; INIT 8253 (Changed)
; Change: Time1's period = 5ms 
;--------------------------------------------
INIT8253 PROC

;	设定Timer0	
		MOV AL,00110110B			; 设定Timer0，2字节写入，方式3方波，二进制计数
		MOV DX,L8253CS				; 指向8253控制寄存器1 
		OUT DX,AL
		MOV AX, 1000				; 计数值=1000 每1ms产生一次中断
		MOV DX, L8253T0				; 指向Timer0
		OUT DX,AL					; 先送低位字节
		MOV AL,AH	
		OUT DX,AL					; 再送高位字节

;	设定Timer1
		MOV AL,01010110B			; 设定Timer1,只写低8位，方式3方波，二进制
		MOV DX,L8253CS				; 指向8253控制寄存器
		OUT DX,AL					; 
		MOV AX,5					; 计数值 = 5
		MOV DX, L8253T1				; 指向Timer1
		OUT DX,AL					; 送出8位计数值

;	设定Timer2

		RET
INIT8253 ENDP

;-------------------------------------------------------------
; Function：INTERRUPT Vector Table INIT	(Unchanged)					  
; Input: BL = Interrupt number								
; Output: None			                              
;-------------------------------------------------------------	
INT_INIT	PROC 			
		CLI						; Disable interrupt
		MOV AX, 0
		MOV ES, AX				; 准备操作中断向量表

		XOR BH, BH				;
		MOV BL, IRQNum				; 取得中断矢量号
		SHL BX, 1				; 
		SHL BX, 1				; 指向中断入口表地址
		MOV AX, OFFSET MYIRQ	; 中断服务程序的偏移地址送AX
		MOV ES:[BX], AX			; 中断服务程序的偏移地址写入向量表
		MOV AX, SEG MYIRQ		; 中断服务程序的段基址送AX
		MOV ES:[BX+2], AX		; 中断服务程序的段基址写入向量表
		RET
		
INT_INIT	ENDP
	
;--------------------------------------------------------------
; FUNCTION: INTERRUPT SERVICE  Routine （ISR）(Changed)			  
; Add Counter Number                                                   
;--------------------------------------------------------------	
		
MYIRQ 	PROC 
		CLI
		PUSH DX					; 保存DX
		PUSH AX					; 保存AX
		
		INC LEDDisplayCount
		INC OneMinuteCount
		INC OneSecondCount
		
		POP AX
		POP DX					; 取回DX	
		STI
		IRET					; 中断返回
MYIRQ 	ENDP

	END						; 指示汇编程序结束编译