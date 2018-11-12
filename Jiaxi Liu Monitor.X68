*-----------------------------------------------------------
* Title      : Monitor Project
* Written by : Jiaxi Liu
* Date       : 10/8/2018
* Description: Build up a Monitor program with MC68000 assembly language.
*-----------------------------------------------------------
    ORG    $1000
    
                                            ;VARIABLES
                                    
STACK       EQU $3000                       ;1K STACK
INPUT       EQU $2C60                       ;INPUT FROM PROMPT
COMMAND     EQU $2C10                       ;COMMAND BUFFER
OUT         EQU $2BC0                       ;OUTPUT BUFFER
SSP         EQU $2AC0                       ;OUTPUT BUFFER

                                            ;LIST OF COMMANDS
COMMAND_LIST    DC.B 'HELP ',0
                DC.B 'MDSP ',0
                DC.B 'SORTW ',0
                DC.B 'MM ',0
                DC.B 'MS ',0
                DC.B 'BF ',0
;               DC.B 'BMOV ',0
;               DC.B 'BTST ',0
;               DC.B 'BSCH ',0
                DC.B 'GO ',0
                DC.B 'DF ',0
;               DC.B 'RCHG ',0
;               DC.B 'SWAP ',0
LAST_CMD        DC.B 'EXIT ',0

COMMAND_ADDRESSES   DC.L HELP               ;ADDRESS OF COMMANDS
                    DC.L MDSP
                    DC.L SORTW
                    DC.L MM
                    DC.L MS
                    DC.L BF
;                   DC.L BMOV
;                   DC.L BTST
;                   DC.L BSCH
                    DC.L GO
                    DC.L DF
;                   DC.L RCHG
;                   DC.L SWAP
LAST_ADD            DC.L EXIT
    
                                            ;MESSAGES

NOT_COMMAND     DC.B 'UNKNOWN COMMAND',0
INVALID_ARG     DC.B 'INVALID ARGUMENTS',0
NO_ERROR        DC.B 'NO ERRORS DETECTED',0
MEM_ERROR1      DC.B 'ERROR FOUND AT: ',0
MEM_ERROR2      DC.B 'DATA STORED: ',0
MEM_ERROR3      DC.B 'DATA READ: ',0
NOT_FOUND_MSG   DC.B 'DATA NOT FOUND',0
FOUND1          DC.B 'FOUND: ',0
FOUND2          DC.B 'AT MEMORY LOCATION: ',0
FOUND3          DC.B ' ',0
DF_MSG          DC.B 'D0=D1=D2=D3=D4=D5=D6=D7=A0=A1=A2=A3=A4=A5=A6=A7='
SR_MSG          DC.B	'SR=',0
PC_MSG          DC.B	'PC=',0
US_MSG          DC.B	'US=',0
SS_MSG          DC.B	'SS=',0
PROMPT          DC.B 'LIU_441>',0


    ORG $1200                               ;START UP AT $1200
    
START:
                                            ;MOVE EXCEPTIONS IN
    MOVE.L #STACK,$0
    MOVE.L #BUS_ERROR,$8
    MOVE.L #ADDR_ERROR,$C
    MOVE.L #ILLEGAL,$10
    MOVE.L #DIV_ZERO,$14
    MOVE.L #P_VIOLATION,$20
    MOVE.L #LINE_A,$24
    MOVE.L #LINE_F,$28
    
MAIN                                        ;START MAIN PROGRAM
    LEA PROMPT,A1
    MOVE.B #14,D0
    TRAP #15
    LEA INPUT,A1
    MOVE.B #2,D0
    TRAP #15
    
    
PARSE                                       ;PARSE TO GET COMMAND
    LEA INPUT,A1
    LEA COMMAND,A2    
SPACES                                      ;CLEAR STARTING SPACES
    CMP.B   #$20,(A1)+
    BEQ     SPACES
    SUB     #$01,A1    
SAVE_COMMAND                                ;GET THE COMMAND SAVED INTO LOCATION 'COMMAND'
    MOVE.B  (A1)+,(A2)+
    CMP.B   #$20,(A1)
    BEQ     LOADING
    CMP.B   #$00,(A1)
    BEQ     LOADING
    BRA SAVE_COMMAND
LOADING                                     ;LOAD COMMAND LIST AND ADDRESSES FOR MATCHING
    MOVE.B  #$20,(A2)
    LEA COMMAND,A1
    LEA COMMAND_LIST,A2
    LEA COMMAND_ADDRESSES, A3
MATCHING                                    ;MATCH UP THE COMMAND TO EXEC THE RIGHT SUBROUTINE
    CMPM.B  (A1)+,(A2)+
    BNE NEXT
    CMPI.B  #$20,(A1)
    BNE MATCHING
    CMPI.B  #$20,(A2)
    BNE ERROR
    
    MOVE.L  (A3),A4
    JMP (A4)
NEXT
    CMPI.B    #$00,(A2)+
    BNE NEXT
    CMPA    #LAST_ADD,A2
    BGT ERROR
    ADD #$04,A3
    LEA COMMAND,A1
    BRA MATCHING


;COMMANDS
HELP
    MOVEM.L D0-D7/A1-A6,-(A7)
    MOVE.L  #$FFF,D0
    LEA HELP1, A1
    MOVE.B #13, D0
    TRAP #15
    LEA HELP2, A1
    TRAP #15 

    MOVE.B  #$00, (A1)
    MOVE.B  #13, D0
    TRAP    #15
    MOVEM.L (A7)+,D0-D7/A0-A7
    JMP MAIN

;MEMORY DISPLAY
MDSP
    MOVEM.L D0-D7/A1-A6,-(A7)
    LEA OUT,A2
    LEA INPUT,A5
    ADD #$05,A5
    JSR NEXT_ARG
    MOVE.L  D2,A2
    ADD #$01,A5
    JSR NEXT_ARG
    MOVE.L  D2,A3
    MOVEQ   #$00,D1
    LEA INPUT,A1
NL  ;NEW LINE
    MOVE.B  #$00,(A1)
    MOVE.B  #13,D0
    TRAP    #15
    JSR DISP_ADDR   ;DISPLAY THE ADDRESS EVERY 8 BYTES
    MOVE.W  #8,D6
DISP_MEM    ;DISPLAY MEMORY
    MOVE.B  #16,D2
    CMPA    A2,A3
    BLT MDSP_EXIT
    MOVE.B  (A2)+,D1
    MOVE.B  #15,D0
    TRAP    #15
    MOVE.B  #$20,D1
    MOVE.B  #6,D0
    TRAP    #15
    SUBQ.W #1,D6
    BEQ NL
    BRA DISP_MEM
MDSP_EXIT
    MOVE.B  #$00,D1
    MOVE.B  #0,D0
    TRAP    #15
    MOVE.B  #$00, (A1)
    MOVE.B  #13, D0
    TRAP    #15
    MOVEM.L (A7)+,D0-D7/A0-A7
    JMP MAIN

;SORT WORD LENGTH VALUES IN MEMORY
SORTW
    MOVEM.L D0-D7/A1-A6,-(A7)
    LEA INPUT,A5
    ADD #$06,A5
    JSR NEXT_ARG
    MOVE.L  D2,A2
    ADD #$01,A5
    JSR NEXT_ARG
    MOVE.L D2,A3
    ADD #$01,A5
    CMPI.B  #$41,(A5)
    BEQ ASCEND
    CMPI.B  #$44,(A5)
    BEQ DESCEND
    BRA ARG_ERROR
    
ASCEND
    MOVE.L A2,A0                                ;SAVE STARTING POINT
ASCLOOP
    MOVE.L A0,A2 
ALOOP
    CMP.W (A2)+,(A2)+
    BLT SWITCHA
    SUBQ.L #2,A2 
    CMP.L A2,A3
    BGT ALOOP 
    BRA SORT_EXIT
SWITCHA
    MOVE.L -(A2),D0
    SWAP.W D0
    MOVE.L D0,(A2)
    BRA ASCLOOP

DESCEND
    MOVE.L A2,A0                                ;SAVE STARTING POINT
DESCLOOP
    MOVE.L A0,A2 
DLOOP
    CMP.W (A2)+,(A2)+
    BGT DSWITCH
    SUBQ.L #2,A2 
    CMP.L A2,A3
    BGT DLOOP 
    BRA SORT_EXIT
DSWITCH
    MOVE.L -(A2),D0
    SWAP.W D0
    MOVE.L D0,(A2)
    BRA DESCLOOP

SORT_EXIT
    MOVE.B  #$00, (A1)
    MOVE.B  #13, D0
    TRAP    #15
    MOVEM.L (A7)+,D0-D7/A0-A7
    JMP MAIN


MM
    MOVEM.L D0-D7/A1-A6,-(A7)
    LEA OUT,A1
    LEA INPUT,A5
    ADD #$03,A5
    JSR NEXT_ARG
    MOVE.L  D2,A2
    ADD #$01,A5
    MOVE.B  (A5),D6
CHANGE_LOOP
    JSR DISP_ADDR
    CMPI.B  #$42,D6
    BEQ MMBYTE
    CMPI.B  #$4C,D6
    BEQ MMLONG

    CMPI.B  #$57,D6
    BEQ MMWORD
    BRA ARG_ERROR
MMBYTE
    MOVE.B  #1,D5
    MOVE.B  #2,D4
    CLR D1
    MOVE.B  (A2),D1
    MOVE.B  #16,D2
    MOVE.L  #15,D0
    TRAP    #15
    MOVE.B  #$20,D1
    MOVE.B  #6,D0
    TRAP    #15
    JMP CHANGE
MMWORD
    MOVE.B  #2,D5
    MOVE.B  #4,D4
    CLR D1
    MOVE.W  (A2),D1
    MOVE.B  #16,D2
    MOVE.L  #15,D0
    TRAP    #15
    MOVE.B  #$20,D1
    MOVE.B  #6,D0
    TRAP    #15
    JMP CHANGE
MMLONG
    MOVE.B  #4,D5
    MOVE.B  #8,D4
    CLR D1
    MOVE.L  (A2),D1
    MOVE.B  #16,D2
    MOVE.L  #15,D0
    TRAP    #15
    MOVE.B  #$20,D1
    MOVE.B  #6,D0
    TRAP    #15
CHANGE    
    MOVE.B  #2,D0
    TRAP    #15
    LEA OUT,A1
    CMPI.B  #$2E,(A1)
    BEQ MM_EXIT
    CMPI.B  #$00,(A1)
    BEQ NOTHING
    CMPI.B  #2,D1
    BEQ MMB
    CMPI.B  #4,D1
    BEQ MMW
    CMPI.B  #8,D1
    BEQ MML
    BRA ARG_ERROR
    
MMB
    CMP.B   #2,D4
    BNE ARG_ERROR
    LEA OUT,A5
    JSR GET_VALUE
    MOVE.B  D3,(A2)+
    BRA CHANGE_LOOP
MMW
    CMP.B   #4,D4
    BNE ARG_ERROR
    LEA OUT,A5
    JSR GET_VALUE
    MOVE.W  D3,(A2)+
    BRA CHANGE_LOOP
MML
    CMP.B   #8,D4
    BNE ARG_ERROR
    LEA OUT,A5
    JSR GET_VALUE
    MOVE.L  D3,(A2)+
    BRA CHANGE_LOOP
NOTHING
    ADDA.L D5,A2
    BRA CHANGE_LOOP

MM_EXIT
    MOVE.B  #$00,(A1)
    MOVE.B  #13,D0
    TRAP    #15
    MOVEM.L (A7)+,D0-D7/A0-A7
    JMP MAIN


MS
    MOVEM.L D0-D7/A1-A6,-(A7)
    MOVE.L  #1,D1
    CLR D5
    LEA INPUT,A5
    ADD #$03,A5
    JSR NEXT_ARG
    MOVE.L  D2,A2
    ADD #1,A5
    CMPI.B  #$24,(A5)
    BEQ HEX_LOOP
MS_LOOP
    CMPI.B  #$00,(A5)
    BEQ MS_EXIT
    MOVE.B  (A5)+,(A2)+
    BRA MS_LOOP
HEX_LOOP
    MOVE.L  A5,A3
    ADDA.L  #1,A3
    CLR D4
COUNT
    ADD #1,D4
    CMPI.B  #$00,(A3)+
    BNE COUNT
    CMPI.L  #9,D4
    BGT ARG_ERROR
    ADDA.L  #1,A5
H_LOOP    
    ;FIRST 4 BITS
    CMPI.B  #$00,(A5)
    BEQ MS_EXIT
    JSR GET_VALUE
    CMPI.B  #$0,D3
    BLT ARG_ERROR
    CMPI.B  #$F,D3
    BGT ARG_ERROR
    ROL.L   #4,D5
    ADD.L   D3,D5

    ;SECOND 4 BTIS
    CMPI.B  #$00,(A5)
    BEQ MS_EXIT
    JSR GET_VALUE
    CMPI.B  #$0,D3
    BLT ARG_ERROR
    CMPI.B  #$F,D3
    BGT ARG_ERROR
    ROL.L   #4,D5
    ADD.L   D3,D5
    
    MOVE.B  D5,(A2)+
    BRA H_LOOP
    
MS_EXIT
    MOVE.B  #$00,(A1)
    MOVE.B  #13,D0
    TRAP    #15
    MOVEM.L (A7)+,D0-D7/A0-A7
    JMP MAIN


BF
    MOVEM.L D0-D7/A1-A6,-(A7)
    CLR D1
    CLR D3
    LEA INPUT,A5
    ADD #$03,A5
    JSR NEXT_ARG
    MOVE.L  D2,A2
    ADD #$01,A5
    JSR NEXT_ARG
    MOVE.L  D2,A3
    MOVE.L  A5,A6
    ADD #2,A6
    ADD #1,A5
    CMPI.B  #$24,(A5)
    BNE ARG_ERROR
    ADD #1,A5
LENGTH
    ADD #1,D1
    CMPI.B  #$00,(A6)+
    BNE LENGTH
    CMPI.B  #$5,D1
    BGT ARG_ERROR
    SUBI    #1,D1
    JSR GET_VALUE
FILL
    CMPA    A2,A3
    BLT BF_EXIT
    MOVE.W  D3,(A2)+
    BRA FILL
    
BF_EXIT
    MOVE.B  #$00, D1
    MOVE.B  #0, D0
    TRAP    #15
    MOVEM.L (A7)+,D0-D7/A0-A7
    JMP MAIN

GO
    LEA INPUT,A5
    LEA OUT,A2
    ADD #$03,A5
    JSR NEXT_ARG
    MOVE.L  D2,(A2)
    JMP (A2)


DF
    ;D AND A REGISTERS
    MOVE.L  A7,SSP
    
    LEA     STACK, A7
    MOVEM.L D0-D7/A0-A7,-(A7)
    MOVEQ   #00, D5
NXT_REG
    LEA     DF_MSG, A1
    ADD     D5, A1
    ADD     #$03, D5
    MOVE.W  #03, D1
    MOVE.B  #01, D0
    TRAP    #15
    LEA     OUT, A1
    MOVE.W  #8, D2
    MOVE.L  (A7)+, D0
NXT_DIG
    ROL.L   #4, D0
    MOVE.L  D0, D3
    AND.L   #$0F, D3
    CMPI.B  #$09, D3
    BLE     LESS
    ADD     #$07, D3
LESS
    ADD     #$30, D3
    MOVE.B  D3, (A1)+
    SUBQ.W  #1, D2
    BNE     NXT_DIG
    
    MOVE.B  #$00, (A1)+
    LEA     OUT, A1
    MOVE.B  #13, D0
    TRAP #15
    
    CMPA    #STACK, A7
    BLT     NXT_REG
    
;OTHER REGISTERS
SR
	LEA		STACK, A7
	MOVE	SR, -(A7)
	LEA		SR_MSG, A1
	MOVE.B	#14, D0
	TRAP	#15
	LEA		OUT, A1
	MOVE.W	#4, D2
	MOVE.L	(A7)+, D0
NXT_SR
    ROL.L   #4, D0
    MOVE.L  D0, D3
    AND.L   #$0F, D3
    CMPI.B  #$09, D3
    BLE     LESS_SR
    ADD     #$07, D3
LESS_SR
    ADD     #$30, D3
    MOVE.B  D3, (A1)+
    SUBQ.W  #1, D2
    BNE     NXT_SR
    
    MOVE.B  #$00, (A1)+
    LEA     OUT, A1
    MOVE.B  #13, D0
    TRAP #15
SS
	LEA		STACK, A7
	MOVE	SSP, -(A7)
	LEA		SS_MSG, A1
	MOVE.B	#14, D0
	TRAP	#15
	LEA		OUT, A1
	MOVE.W	#8, D2
	MOVE.L	(A7)+, D0
NXT_SS
    ROL.L   #4, D0
    MOVE.L  D0, D3
    AND.L   #$0F, D3
    CMPI.B  #$09, D3
    BLE     LESS_SS
    ADD     #$07, D3
LESS_SS
    ADD     #$30, D3
    MOVE.B  D3, (A1)+
    SUBQ.W  #1, D2
    BNE     NXT_SS
    
    MOVE.B  #$00, (A1)+
    LEA     OUT, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     MAIN

EXIT
    MOVEM.L (A7)+,D0-D7/A0-A7
    MOVE.B #9,D0
    TRAP #15

;SUBROUTINES
NEXT_ARG                                        ;GETS THE NEXT ARGUMENT INTO D2
    CMPI.B  #$24,(A5)
    BNE ARG_ERROR
    CLR.L D0
    CLR.L D2
ADD_ARG
    ADD     #$01, A5
    ROL.L   #4,D2
    ADD.L   D0,D2
    MOVE.B  (A5)+,D0
    CMPI.B  #$39,D0                             ;IF IT IS A NUMBER
    BLE     NUMBER
    SUBQ.B  #$07,D0                             ;IF A LETTER
NUMBER
    SUB.B   #$30, D0
    CMPI.B  #$00,-(A5)                          ;IF IT WAS NULL
    BEQ     GOT_ARG
    CMPI.B  #$20,(A5)                           ;IF ITS A SPACE
    BEQ     GOT_ARG
    CMPI.B  #$3B,(A5)                           ; ITS A SEMICOLON
    BEQ     GOT_ARG
    BRA     ADD_ARG
GOT_ARG
    RTS
    
;PRINT OUT THE VALUE OF A2, INCREMEMNTS BY 8 BYTES
DISP_ADDR   
    MOVE.B  #$24,D1                             ;PRINT $ FIRST
    MOVE.B  #6,D0
    TRAP    #15
    MOVE.L  A2,D0
    LEA     OUT,A1                              ;POINT A1 TO OUTPUT BUFFER
    MOVE.W #8,D2
DSP_ADR_LP                                      ;CONVERT THE HEX NUMBER TO ASCII
    ROL.L   #4,D0
    MOVE.L  D0,D3
    AND.L   #$0F,D3
    CMPI.B  #$09,D3
    BLE     LESS_ADDR
    ADD     #$07,D3
LESS_ADDR
    ADD     #$30,D3
    MOVE.B  D3,(A1)+
    SUBQ.W  #1,D2
    BNE     DSP_ADR_LP
    MOVE.B  #$00,(A1)+
    LEA     OUT,A1                              ;PRINT OUT FULL ADDRESS LOCATION
    MOVE.B  #14,D0
    TRAP #15
    MOVE.B	#$3A,D1
    MOVE.B	#6,D0
    TRAP	#15
    RTS

;GET THE VALUE THAT A5 IS POINTING TO AND PUT IT IN D3. D1 STORES THE LENGTH OF THE VALUE.
GET_VALUE
    CLR D4
    CLR D3
ADD
    MOVE.B  (A5)+,D4
    CMPI.B  #$39,D4
    BLE     NUMBER_VALUE
    SUBQ.B  #$07, D4
NUMBER_VALUE
    SUB.B   #$30,D4
    ROL.L   #4,D3
    ADD.B   D4,D3
    SUB.B   #$01,D1
    CMPI.B  #$00,D1
    BLE     GET_VALUE_EXIT
    BRA     ADD
GET_VALUE_EXIT
    RTS
    
;CONVERT (A1) TO ASCII
TO_ASCII
    CLR D4
    CLR D3
ASCII_ADD
    MOVE.B  (A1)+,D4
    CMPI.B  #$39,D4
    BLE     A_NUM
    ADD     #$07,D4
A_NUM
    ADD     #$30,D4
    ROL.L   #4,D3
    ADD.L   D4,D3
    SUB.B   #$01,D1
    CMPI.B  #$00,D1
    BLE     TO_ASCII_EXIT
    BRA     ASCII_ADD
TO_ASCII_EXIT
    MOVE.L  D3,(A1)
    RTS
    


;EXCEPTIONS/ERRORS
;EXCEPTIONS JUMP TO DF AFTERWARDS TO DISPLAY THE REGISTERS
BUS_ERROR
    LEA     BUS_ERROR_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     DF

ADDR_ERROR
    LEA     ADDR_ERROR_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     DF

ILLEGAL
    LEA     ILL_INST_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     DF

DIV_ZERO
    LEA     DIV_ZERO_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     DF

P_VIOLATION
    LEA     PRIV_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     DF

LINE_A
    LEA     LINE_A_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     DF

LINE_F
    LEA     LINE_F_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     DF


ARG_ERROR
    LEA INVALID_ARG,A1
    MOVE.B  #13,D0
    TRAP #15
    JMP MAIN
    
    
MEM_ERROR
    LEA MEM_ERROR1,A1
    MOVE.B  #14,D0
    TRAP    #15
    CLR D1
    MOVE.L  A2,D1
    MOVE.B  #16,D2
    MOVE.L  #15,D0
    TRAP    #15
    MOVE.B  #$00,(A1)
    MOVE.B  #$00,D1
    MOVE.B  #0,D0
    TRAP    #15
    
    CLR D1
    LEA MEM_ERROR2,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.L  D3,D1
    MOVE.B  #16,D2
    MOVE.L  #15,D0
    TRAP    #15
    MOVE.B  #$00,D1
    MOVE.B  #0,D0
    TRAP    #15
    
    LEA MEM_ERROR3,A1
    MOVE.B  #14,D0
    TRAP    #15
    CLR D1
    MOVE.B  (A2),D1
    MOVE.B  #16,D2
    MOVE.L  #15,D0
    TRAP    #15
    MOVE.B  #$00,D1
    MOVE.B  #0,D0
    TRAP    #15
    MOVE.B  #$00,D1
    MOVE.B  #0,D0
    TRAP    #15
    
    JMP MAIN


ERROR
    LEA NOT_COMMAND,A1
    MOVE.B #13,D0
    TRAP #15
    JMP MAIN


BUS_ERROR_MSG
    DC.B    'A BUS ERROR HAS OCCURRED',$0A,$0D,0
ADDR_ERROR_MSG
    DC.B    'AN ADDRESS ERROR HAS OCCURRED',$0A,$0D,0    
ILL_INST_MSG
    DC.B    'THAT IS NOT A VALID INSTRUCTION',$0A,$0D,0
DIV_ZERO_MSG
    DC.B    'YOU CANNOT DIVIDE BY ZERO',$0A,$0D,0
PRIV_MSG
    DC.B    'PRIVILEGE VIOLATION',0
LINE_A_MSG
    DC.B    'LINE A EXCEPTION',0
LINE_F_MSG
    DC.B    'LINE F EXCEPTION',0
    
HELP1    
    DC.B    'HELP: DISPLAYS THIS HELP MESSAGE.',$0A,$0D

    DC.B    'MDSP: OUTPUTS ADDRESS AND MEMORY CONTENTS.',$0A,$0D

    DC.B    'MDSP $900 $910.',$0A,$0D

    DC.B    'SORTW: SORTS A BLOCK OF MEMORY',$0A,$0D

    DC.B    'SORTW $900 $910;A/D',$0A,$0D

    DC.B    'MM: MODIFIES DATA IN MEMORY.',$0A,$0D

    DC.B    'MM $900;B/W/L',$0A,$0D

    DC.B	'MS: SETS THE CONTENTS OF THE ALL ADDRESSES SPECIFED. NO LARGER THAN LONG FOR HEX VALUES',$0A,$0D

    DC.B	'MS $900 ABCD/$1234',$0A,$0D

    DC.B    'BSCH: SEARCHES A BLOCK OF MEMORY FOR DATA.',$0A,$0D

    DC.B    'BSCH $900 $950 ABCD',$0A,$0D

    DC.B    'BTST: TESTS A BLOCK OF MEMORY FOR ERROR.',$0A,$0D
    
    DC.B    'BTST $900 $910',$0A,$0D

    DC.B    'BF: FILLS A BLOCK OF MEMORY WITH THE GIVEN WORD.',0
HELP2   
    DC.B    'BF $900 $910 $AAAA',$0A,$0D

    DC.B    'DF: DISPLAY REGISTER VALUES.',$0A,$0D

    DC.B    'DF',$0A,$0D

    DC.B    'BMOV: MOVES A BLOCK OF MEMORY.',$0A,$0D

    DC.B    'BMOV $900 $910 $920',$0A,$0D

    DC.B    'RCHG: MODIFY A REGISTER.',$0A,$0D

    DC.B    'RCHG D1 $FFFF',$0A,$0D

    DC.B    'SWAP: SWAP DATA FROM MEMORY LOCATIONS.',$0A,$0D

    DC.B    'SWAP $900 $920;B/W/L',$0A,$0D
    
    DC.B    'GO: BEGINS PROGRAM EXECUTION AT THE SPECIFIED ADDRESS.',$0A,$0D

    DC.B    'GO $1000',$0A,$0D

    DC.B    'EXIT: EXITS THE MONITOR PROGRAM.',$0A,$0D,0
    
    
    ORG $8000
    ANDI.W  #$0700,SR
    BRA $8000
    
    END    START        



























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
