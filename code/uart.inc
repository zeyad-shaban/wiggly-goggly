PUBLIC UART_INIT
PUBLIC UART_SEND
PUBLIC SEND_DECIMAL
PUBLIC SEND_HEX
PUBLIC NIBBLE_TO_ASCII
PUBLIC SEND_TIMER0_HEX
PUBLIC SEND_STRING
PUBLIC DONE_STRING


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
    RET

DONE_STRING:
    RET