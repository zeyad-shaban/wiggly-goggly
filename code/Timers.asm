;----------------------------------------------------------
; Project: Ultrasonic Echo Timer Measurement
; Clock  : 11.0592 MHz
; UART   : 9600 baud
; UART output = raw TH0/TL0 count of ECHO pulse width
;----------------------------------------------------------

US_TRIG_R   EQU  P1.1    ; Right Trigger pin
US_ECHO_R   EQU  P1.0    ; Right Echo pin
LED0 EQU P2.0; 10cm
LED1 EQU P2.1; 20cm
LED2 EQU P2.2; 30cm
LED3 EQU P2.3; 40cm
LED4 EQU P2.4; 50cm
LED5 EQU P2.5; 60cm
LED6 EQU P2.6; 70cm
LED7 EQU P2.7; >70cm
LED_OUT EQU P1.3;out of range


ORG 0000h
LJMP START 

;=======================
; UART Initialization
UART_INIT:
    MOV TH1, #0FDH       ; Baud = 9600
    MOV TL1, #0FDH
    MOV SCON, #50H       ; 8-bit UART, REN enabled
    SETB TR1
    RET

;=======================
; UART Send Byte (in A)
UART_SEND:
    MOV SBUF, A
WAIT_SEND:
    JNB TI, WAIT_SEND
    CLR TI
    RET

;=======================
; SEND_DECIMAL: Converts A to 2-digit ASCII
SEND_DECIMAL:
    MOV B, #10
    DIV AB
    ADD A, #'0'
    ACALL UART_SEND
    MOV A, B
    ADD A, #'0'
    ACALL UART_SEND
    RET

;=======================
; SEND_HEX: Send A as 2-digit HEX
SEND_HEX:
    SWAP A                ; High nibble first
    ANL A, #0Fh
    ACALL NIBBLE_TO_ASCII
    ACALL UART_SEND

    MOV A, R5             ; Restore original
    ANL A, #0Fh
    ACALL NIBBLE_TO_ASCII
    ACALL UART_SEND
    RET

; Convert nibble in A to ASCII
NIBBLE_TO_ASCII:
    ADD A, #'0'
    CJNE A, #'9'+1, OK_ASCII
    ADD A, #7            ; for A-F
OK_ASCII:
    RET

;=======================
; Send 16-bit Timer0 value in HEX
SEND_TIMER0_HEX:
    MOV A, TH0
    MOV R5, A
    ACALL SEND_HEX
    MOV A, TL0
    MOV R5, A
    ACALL SEND_HEX
    RET

;=======================
; UART Send String in DPTR
SEND_STRING:
    CLR A
    MOVC A, @A+DPTR
    JZ DONE_STRING
    ACALL UART_SEND
    INC DPTR
    SJMP SEND_STRING
DONE_STRING:
    RET

;----------------------------------------------------------
; Delay ≈10 µs
DELAY_10US:
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    RET

;----------------------------------------------------------
; START
START:
    MOV TMOD, #21H       ; Timer1 Mode 2 (for UART), Timer0 Mode 1
    CLR TR0               ; Ensure Timer0 OFF
    ; Reset Timer0 for next round
    MOV TL0, #00h
    MOV TH0, #00h

    ACALL UART_INIT       ; Initialize UART
    CLR LED0
    CLR LED1
    CLR LED2
    CLR LED3
    CLR LED4
    CLR LED5
    CLR LED6
    CLR LED7
    CLR US_TRIG_R
    CLR US_ECHO_R
    
    ;send start string
    MOV DPTR,#MSG_START
    ACALL SEND_STRING

MAIN_TOGGLE:
    ; Send TRIG pulse
    SETB US_TRIG_R
    ACALL DELAY_10US
    CLR  US_TRIG_R

WAIT_ECHO_HIGH: ; also this was JB and that was waiting for echo low which doesnt make any sense
    JNB   US_ECHO_R, WAIT_ECHO_HIGH
    CLR  TF0
    CLR  TR0

    ; Start Timer0
    SETB TR0


WAIT_RISE:
    JB   US_ECHO_R, GOT_ECHO
    DJNZ  R0, WAIT_RISE
    DJNZ  R1, WAIT_RISE
    SJMP  NO_ECHO

CLR LED_OUT

NO_ECHO:
    CLR TR0
    SETB LED_OUT
    SJMP MAIN_TOGGLE

GOT_ECHO:
;i can belive this fixed everything 
WAIT_ECHO_LOW:
    JB   US_ECHO_R, WAIT_ECHO_LOW
    CLR  TF0
    CLR  TR0

    ; -----------------------------
    ; Print "Pulse: " and Timer0
    ; -----------------------------
    MOV DPTR, #MSG_PULSE
    ACALL SEND_STRING
    MOV A,TH0
    ACALL SEND_DECIMAL
    MOV A,TL0
    ACALL SEND_DECIMAL
    MOV A, #13
    ACALL UART_SEND
    MOV A, #10
    ACALL UART_SEND

        ; Calculate pulse duration
    MOV A, TL0       ; Store TL0 in R0
    MOV R0, A
    MOV A, TH0       ; Store TH0 in R1
    MOV R1, A

    ; Use DPH:DPL = R1:R0 to load 16-bit value
    MOV DPL, R0
    MOV DPH, R1

    ; Approximate Distance = timer / 53
    ; Result will be in R2
    MOV R2, #0        ; Distance result = 0

DIV_LOOP:
    CLR C
    MOV A, DPL
    SUBB A, #53
    MOV DPL, A
    MOV A, DPH
    SUBB A, #00
    MOV DPH, A
    JC DIV_DONE       ; Stop if DPH:DPL < 53
    INC R2
    SJMP DIV_LOOP

DIV_DONE:
    ; Display Distance (in cm)
    MOV DPTR, #MSG_DISTANCE
    ACALL SEND_STRING
    MOV A, R2
    ACALL SEND_DECIMAL
    MOV A, #13
    ACALL UART_SEND
    MOV A, #10
    ACALL UART_SEND

        ; ----- Clear all LEDs (P2.0 to P2.7) -----
    CLR LED0
    CLR LED1
    CLR LED2
    CLR LED3
    CLR LED4
    CLR LED5
    CLR LED6
    CLR LED7

    ; ----- Light LEDs based on distance in R2 -----
    MOV A, R2

    CJNE A, #10, CHECK_20
    SETB LED0

CHECK_20:
    JC DONE_LEDS       ; A < 10
    SETB LED0
    CJNE A, #20, CHECK_30
    SETB LED1

CHECK_30:
    JC DONE_LEDS
    SETB LED1
    CJNE A, #30, CHECK_40
    SETB LED2

CHECK_40:
    JC DONE_LEDS
    SETB LED2
    CJNE A, #40, CHECK_50
    SETB LED3

CHECK_50:
    JC DONE_LEDS
    SETB LED3
    CJNE A, #50, CHECK_60
    SETB LED4

CHECK_60:
    JC DONE_LEDS
    SETB LED4
    CJNE A, #60, CHECK_70
    SETB LED5

CHECK_70:
    JC DONE_LEDS
    SETB LED5
    SETB LED6
    SETB LED7           ; Everything beyond 70 cm → all LEDs ON

DONE_LEDS:

    ; Reset Timer0 for next round
    MOV TL0, #00h
    MOV TH0, #00h


    LJMP MAIN_TOGGLE

;---------------------Rom Message------------------------------------
MSG_PULSE: DB "Pulse: ", 0
MSG_START: DB "Program Starting",0
MSG_DISTANCE: DB "Distance: ", 0


END
