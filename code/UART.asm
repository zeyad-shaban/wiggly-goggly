ORG 0000h
LJMP START

;=======================
; UART Initialization
UART_INIT:
    MOV TMOD, #20h       ; Timer1 in Mode 2
    MOV TH1, #0FDh       ; 9600 baud @ 11.0592 MHz
    MOV TL1, #0FDh
    MOV SCON, #50h       ; 8-bit UART, REN enabled
    SETB TR1             ; Start Timer1
    RET

;=======================
; UART Send Single Byte
UART_SEND:
    MOV SBUF, A
WAIT_SEND:
    JNB TI, WAIT_SEND
    CLR TI
    RET

;=======================
; UART Send String
SEND_STRING:
    MOV DPTR, #MSG         ; R0 points to message
NEXT_CHAR:
     CLR A
    MOVC A, @A+DPTR
    JZ DONE_STRING
    ACALL UART_SEND
    INC DPTR
    SJMP NEXT_CHAR
DONE_STRING:
    RET

;=======================
; Main Program
START:
    ACALL UART_INIT
    ACALL SEND_STRING
HERE: SJMP HERE          ; Infinite loop

;=======================
; Data Section
MSG: DB 'Hello, world', 13, 10, 0  ; \r\n + null terminator

END
