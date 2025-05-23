;====================================================
; Project: Button-Hold Stopwatch + Timer0 Monitor
; Clock  : 11.0592 MHz
; Button : P3.2 (active-low)
;====================================================

ORG 0000H
LJMP MAIN

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

;=======================
; MAIN Program
MAIN:
    MOV TMOD, #21H       ; Timer1 Mode 2 for UART and Timer0 Mode 1
    ACALL UART_INIT

MAIN_LOOP:
    JB P3.2, MAIN_LOOP       ; Wait until button is pressed (P3.2 = 0)
    
    ; Init Timer0
    MOV TH0, #00H
    MOV TL0, #00H
    SETB TR0                 ; Start Timer0

    MOV R1, #0               ; Seconds held = 0

HOLD_LOOP:
    ; Check if still held
    JB P3.2, BUTTON_RELEASED ; If P3.2 = 1, button released

    ACALL DELAY_500US
    ACALL DELAY_500US        ; ~1 ms total delay
    INC R1

    ; --- Print seconds held
    MOV DPTR, #MSG_HELD
    ACALL SEND_STRING
    MOV A, R1
    ACALL SEND_DECIMAL
    MOV A, #13
    ACALL UART_SEND
    MOV A, #10
    ACALL UART_SEND

    ; --- Print Timer0 value
    MOV DPTR, #MSG_TIMER
    ACALL SEND_STRING
    ACALL SEND_TIMER0_HEX
    MOV A, #13
    ACALL UART_SEND
    MOV A, #10
    ACALL UART_SEND

    SJMP HOLD_LOOP

BUTTON_RELEASED:
    CLR TR0                 ; Stop Timer0

    ; Final message
    MOV DPTR, #MSG_DONE
    ACALL SEND_STRING
    SJMP MAIN_LOOP



;=======================
; ROM Data
MSG_HELD: DB "Held: ",0
MSG_TIMER: DB "Timer: ",0
MSG_DONE: DB "Button Released",13,10,0

END
