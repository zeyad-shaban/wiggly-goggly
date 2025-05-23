;----------------------------------------------------------
; Project: Ultrasonic Echo Timer Measurement
; Clock  : 11.0592 MHz
; UART   : 9600 baud
; UART output = raw TH0/TL0 count of ECHO pulse width
;----------------------------------------------------------

US_TRIG_R   EQU  P1.1    ; Right Trigger pin
US_ECHO_R   EQU  P1.0    ; Right Echo pin
LED_FAR_1   EQU  P2.0
LED_FAR_2   EQU  P2.4
LED_MID_1   EQU  P2.1
LED_MID_2   EQU  P2.3
LED_CLOSE   EQU  P2.2

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
; Delay ≈ 500 µs
DELAY_500US:
    MOV R2, #5
L1: MOV R3, #40
L2: NOP
    DJNZ R3, L2
    DJNZ R2, L1
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
    CLR LED_FAR_1
    CLR LED_FAR_2
    CLR LED_MID_1
    CLR LED_MID_2
    CLR LED_CLOSE
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

WAIT_ECHO_HIGH:
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

SETB LED_CLOSE

NO_ECHO:
    CLR TR0
    CLR LED_CLOSE
    SJMP MAIN_TOGGLE

GOT_ECHO:
WAIT_ECHO_LOW:
    JB   US_ECHO_R, WAIT_ECHO_LOW
    CLR  TF0
    CLR  TR0

    ; -----------------------------
    ; Print "Pulse: " and Timer0
    ; -----------------------------
    MOV DPTR, #MSG_PULSE
    ACALL SEND_STRING
    ACALL SEND_TIMER0_HEX
    MOV A, #13
    ACALL UART_SEND
    MOV A, #10
    ACALL UART_SEND


    ; Reset Timer0 for next round
    MOV TL0, #00h
    MOV TH0, #00h


    SJMP MAIN_TOGGLE

;----------------------------------------------------------
; Message
MSG_PULSE: DB "Pulse: ", 0
MSG_START: DB "Program Starting",0

END
