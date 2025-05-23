;----------------------------------------------------------
; Testing LCD and creating its functions
;----------------------------------------------------------

LCD_RS      EQU  P1.5
LCD_RW      EQU  P1.6
LCD_EN      EQU  P1.7
LCD_DATA    EQU  P3

ORG 0000h
LJMP START 

;=======================
; LCD SUB_ROUTINES
;=======================
LCD_DELAY:
    MOV R1, #255
DL1: MOV R2, #255
DL2: DJNZ R2, DL2
     DJNZ R1, DL1
     RET

LCD_CMD: ; to send LCD commands 
    CLR LCD_RS
    CLR LCD_RW
    SETB LCD_EN
    MOV LCD_DATA, A
    ACALL LCD_DELAY
    CLR LCD_EN
    RET

LCD_DATA_WRITE:
    SETB LCD_RS
    CLR LCD_RW
    SETB LCD_EN
    MOV LCD_DATA, A
    ACALL LCD_DELAY
    CLR LCD_EN
    RET

LCD_INIT:
    MOV A, #38H     ; 8-bit, 2-line
    ACALL LCD_CMD
    MOV A, #0EH     ; Display ON, Cursor ON
    ACALL LCD_CMD
    MOV A, #01H     ; Clear display
    ACALL LCD_CMD
    MOV A, #06H     ; Entry mode
    ACALL LCD_CMD
    RET

LCD_SEND_STRING:
    CLR A
    MOVC A, @A+DPTR
    JZ LCD_STRING_DONE
    ACALL LCD_DATA_WRITE
    INC DPTR
    SJMP LCD_SEND_STRING
LCD_STRING_DONE:
    RET

;----------------------------------------------------------
;  LCD_SEND_DECIMAL  – prints an 8-bit value in A (0-255)
;    • no leading zeros for <100 (prints “7”, “42”, “255”, …)
;----------------------------------------------------------
LCD_SEND_DECIMAL:
    MOV     B,#100          ; 1)  hundreds
    DIV     AB              ;    A = hundreds, B = 0-99 remainder
    MOV     R4,A            ;    save hundreds
    MOV     A,B             ; 2)  tens / ones
    MOV     B,#10
    DIV     AB              ;    A = tens, B = ones
    MOV     R5,A
    MOV     R6,B

    ; -------- print hundreds if non-zero ---------------
    MOV     A,R4
    JZ      SKIP_HUNDREDS
    ADD     A,#'0'
    ACALL   LCD_DATA_WRITE
SKIP_HUNDREDS:
    ; -------- print tens (always if hundreds shown) ----
    MOV     A,R5
    JZ      SKIP_TENS
    ADD     A,#'0'
    ACALL   LCD_DATA_WRITE
    SJMP    PRINT_ONES
SKIP_TENS:
    ; if both hundreds and tens were zero, we still need one ‘0’
    MOV     A,R4
    JNZ     PRINT_ONES      ; already printed a hundreds digit
    MOV     A,#'0'          ; value was 0-9, so show a single 0
    ACALL   LCD_DATA_WRITE
    SJMP    DONE_DEC
PRINT_ONES:
    MOV     A,R6
    ADD     A,#'0'
    ACALL   LCD_DATA_WRITE
DONE_DEC:
    RET

LCD_SEND_HEX:      ;send values to R6 first
    MOV B, A
    SWAP A
    ANL A, #0Fh
    ACALL HEX_TO_ASCII
    ACALL LCD_DATA_WRITE

    MOV A, B
    ANL A, #0Fh
    ACALL HEX_TO_ASCII
    ACALL LCD_DATA_WRITE
    RET

;----------------------------------------------------------
;  HEX_TO_ASCII  – expects 0-15 in A, returns ‘0’…‘F’ in A (uses a ROM look-up so it’s always right)
;----------------------------------------------------------
HEX_TO_ASCII:
    PUSH    DPL             ; keep caller’s DPTR safe
    PUSH    DPH
    MOV     DPTR,#HEX_TAB   ; point to table
    MOVC    A,@A+DPTR       ; fetch the correct character
    POP     DPH
    POP     DPL
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
    ACALL LCD_INIT

MAIN_LOOP:
    MOV R2, #86
    MOV R3, #86
    MOV A, R2
    ADD A, R3
    MOV R6, A

    ; Show Hex
    MOV DPTR, #MSG_HEX
    ACALL LCD_SEND_STRING
    MOV A,R6
    ACALL LCD_SEND_HEX

    ; ---- move cursor to start of line 2 ------------------
    MOV  A,#0C0h              ; DDRAM addr 40 → line 2, col 0
    ACALL LCD_CMD

    ; Line 2 or second part
    MOV DPTR, #MSG_DEC
    ACALL LCD_SEND_STRING
    MOV A,R6
    ACALL LCD_SEND_DECIMAL

    ; ---------- clear display & wait -------------------------
    MOV   A,#01h             ; Clear-Display command
    ACALL LCD_CMD            ; sends it
    ACALL LCD_DELAY          ; yields plenty of time (> 1.6 ms)

    ; ---------- start over -----------------------------------
    SJMP  MAIN_LOOP

;----------------------------------------------------------

MSG_HELLO: DB "HELLO_WORLD",0
MSG_HEX:   DB "HEX: ", 0
MSG_DEC:   DB "DEC: ", 0
HEX_TAB: DB  "0123456789ABCDEF" ; 16-byte table

END