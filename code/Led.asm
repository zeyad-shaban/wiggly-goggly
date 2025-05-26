;----------------------------------------------------------
;  LED Sequence – Light up and turn off in order (AT89C51)
;  XTAL  : 11.0592 MHz
;  LEDs  : anodes on P2.0–P2.3, cathodes to GND (active-HIGH)
;----------------------------------------------------------

LED0 EQU P2.0
LED1 EQU P2.1
LED2 EQU P2.2
LED3 EQU P2.3

LED4 EQU P2.4; 
LED5 EQU P2.5; 
LED6 EQU P2.6; 
LED7 EQU P2.7; 


ORG     0000h
SJMP START

;----------------------------------------------------------
; Delay subroutine (~500ms)
;----------------------------------------------------------
DELAY_500MS:
    MOV R7, #200
D1: MOV R6, #255
D2: DJNZ R6, D2
    DJNZ R7, D1
    RET

;----------------------------------------------------------
; Main program
;----------------------------------------------------------
START: 
    CLR LED0
    CLR LED1
    CLR LED2
    CLR LED3
    CLR LED4
    CLR LED5
    CLR LED6
    CLR LED7

MAIN_LOOP:
    ; --- Turn LEDs ON one by one ---
    SETB LED0
    ACALL DELAY_500MS

    SETB LED1
    ACALL DELAY_500MS

    SETB LED2
    ACALL DELAY_500MS

    SETB LED3
    ACALL DELAY_500MS

    ; --- Turn LEDs OFF one by one ---
    CLR LED0
    ACALL DELAY_500MS

    CLR LED1
    ACALL DELAY_500MS

    CLR LED2
    ACALL DELAY_500MS

    CLR LED3
    ACALL DELAY_500MS

    SJMP MAIN_LOOP

END
