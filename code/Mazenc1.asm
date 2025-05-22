;----------------------------------------
; Variables / Ports
;----------------------------------------
US_TRIG_R   EQU  P1.1    ; Right Trigger pin
US_ECHO_R   EQU  P1.0    ; Right Echo pin
LED1    EQU P2.0   ; 0–10 cm
LED2    EQU P2.1   ; 10–20 cm
LED3    EQU P2.2   ; 20–30 cm
LED4    EQU P2.3   ; 30–40 cm
LED5    EQU P2.4   ; 40–50 cm
LED6    EQU P2.5   ; 50–60 cm
LED7    EQU P2.6   ; 60–70 cm
LED8    EQU P2.7   ; >70 cm
LED_OUT EQU P1.7   ; Out of range indicator (e.g., no object detected)




ORG 0000h
LJMP START 

;----------------------------------------
; Subroutine: DELAY_10US
; Purpose:    ≈10 µs delay (at 11.0592 MHz)
;----------------------------------------
DELAY_10US:
    NOP       ; 1 µs
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP       ; ≈10 µs total
    RET
    

;=======================
; UART Initialization
UART_INIT:
    MOV TH1, #0FDh      ; Baud rate 9600 @ 11.0592 MHz
    MOV TL1, #0FDh
     MOV SCON, #50h      ; 8-bit UART mode, REN enabled
    SETB TR1            ; Start Timer1
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
SEND_STRING: ;move msg intp DPTR first
     CLR A
    MOVC A, @A+DPTR
    JZ DONE_STRING
    ACALL UART_SEND
    INC DPTR
    SJMP SEND_STRING
DONE_STRING:
    RET

; Convert RX to ASCII and send
SEND_DECIMAL: ; Move value into A first
    MOV B, #10
    DIV AB            ; A = tens, B = units
    ADD A, #'0'
    ACALL UART_SEND   ; send tens
    MOV A, B
    ADD A, #'0'
    ACALL UART_SEND   ; send units
    RET

START:
    ; Initialize timer
    MOV     TMOD, #21h    ; Timer0 in Mode 1 (16‑bit)
    CLR     TR0           ; Ensure Timer0 is OFF
    
    ACALL UART_INIT

    ;Clear all LEDS
    CLR LED1
    CLR LED2
    CLR LED3
    CLR LED4
    CLR LED5
    CLR LED6
    CLR LED7
    CLR LED8
    ;Clear Trigger/Echo
    CLR US_TRIG_R
    CLR US_ECHO_R

    
MAIN_TOGGLE:
    ; Call Trigger
    SETB    US_TRIG_R    ; Drive P1.1 HIGH
    ACALL   DELAY_10US   ; Wait ≈10 µs
    CLR     US_TRIG_R    ; Drive P1.1 LOW



WAIT_ECHO_HIGH:
    JB   US_ECHO_R, WAIT_ECHO_HIGH
    CLR  TF0
    CLR  TR0           ; ensure timer stopped
    ;----------------------------------------
    ; 2) Start Timer & await rising edge
    ;----------------------------------------
    SETB TR0

; Set up timeout = 11 600 µs / 3 µs ≈ 3867 loops
MOV   R1, 0Fh    ; high byte = 15
MOV   R0, 23h    ; low byte = 35 → 15×256 + 35 = 3860

WAIT_FALL:
    JB   US_ECHO_R, GOT_ECHO
    DJNZ  R0, WAIT_FALL   ; decrement low‑byte
    DJNZ  R1, WAIT_FALL   ; when low‑byte underflows, decrement high‑byte
    SJMP  NO_ECHO

CLR  LED_OUT

NO_ECHO:
    CLR  TR0                      ; ensure timer stopped
    SETB  LED_OUT               ; indicate “no reading” or far
    SJMP MAIN_TOGGLE              ; retrigger immediately

GOT_ECHO:
    ACALL DELAY_10US
    ACALL DELAY_10US
    CLR TR0
    ACALL SHOW_DISTANCE
    LJMP END_CHECK

;----------------------------------------
; Subroutine: SHOW_DISTANCE
; Purpose: Map timer value to 1 of 8 distance LEDs
;----------------------------------------
SHOW_DISTANCE:
    CLR LED_OUT
    

    ; Combine timer value → R1:R0
    MOV A, TL0
    MOV R0, A
    MOV A, TH0
    MOV R1, A
    MOV A,#00h

    

    ; Compute distance = (R1:R0) / 58 → store in R7
    MOV DPL, R0       ; Load low byte
    MOV DPH, R1       ; Load high byte
    MOV R7, #0        ; Result register = 0

DIV_LOOP:
    CLR C 
    MOV A, DPL
    SUBB A, #3Ah
    MOV DPL, A
    MOV A, DPH
    SUBB A, #00h
    MOV DPH, A
    JC DIV_DONE
    INC R7
    SJMP DIV_LOOP

DIV_DONE:
    ; Send "Distance: "
    MOV DPTR, #MSG1
    ACALL SEND_STRING

    ; Send decimal digits from R7
    MOV A,R7
    ACALL SEND_DECIMAL

    ; Send " cm\r\n"
    MOV DPTR, #MSG2
    ACALL SEND_STRING

    ; Send "Timer: "
    MOV DPTR, #MSG3
    ACALL SEND_STRING

    MOV A, TH0
    ACALL SEND_DECIMAL
    MOV A, TL0
    ACALL SEND_DECIMAL
    MOV A,#00h

    MOV DPTR, #SPACE
    ACALL SEND_STRING

    ; Clear all LEDs
    CLR LED1
    CLR LED2
    CLR LED3
    CLR LED4
    CLR LED5
    CLR LED6
    CLR LED7
    CLR LED8

    ; ----- Check: R1:R0 < 580 -----
    MOV DPH, #02h
    MOV DPL, #044h
    ACALL CMP16_LT
    JC SET_LED1

    ; ----- Check: R1:R0 < 1160 -----
    MOV DPH, #04h
    MOV DPL, #088h
    ACALL CMP16_LT
    JC SET_LED2

    ; ----- Check: R1:R0 < 1740 -----
    MOV DPH, #06h
    MOV DPL, #0CCh
    ACALL CMP16_LT
    JC SET_LED3

    ; ----- Check: R1:R0 < 2320 -----
    MOV DPH, #09h
    MOV DPL, #010h
    ACALL CMP16_LT
    JC SET_LED4

    ; ----- Check: R1:R0 < 2900 -----
    MOV DPH, #0Bh
    MOV DPL, #054h
    ACALL CMP16_LT
    JC SET_LED5

    ; ----- Check: R1:R0 < 3480 -----
    MOV DPH, #0Dh
    MOV DPL, #098h
    ACALL CMP16_LT
    JC SET_LED6

    ; ----- Check: R1:R0 < 4060 -----
    MOV DPH, #0Fh
    MOV DPL, #0DCh
    ACALL CMP16_LT
    JC SET_LED7

    ; Else → LED8
    SJMP SET_LED8

SET_LED1: 
    SETB LED1  ; 0–10cm
    RET
SET_LED2: 
    SETB LED2  ; 10–20cm
    RET
SET_LED3: 
    SETB LED3  ; 20–30cm
    RET
SET_LED4: 
    SETB LED4  ; 30–40cm
    RET
SET_LED5: 
    SETB LED5  ; 40–50cm
    RET
SET_LED6: 
    SETB LED6  ; 50–60cm
    RET
SET_LED7: 
    SETB LED7  ; 60–70cm
    RET
SET_LED8: 
    SETB LED8  ; >70cm
    RET


;----------------------------------------
; Subroutine: CMP16_LT
; Purpose: Compare R1:R0 with DPH:DPL
; Returns: CY = 1 if R1:R0 < DPH:DPL
;----------------------------------------
CMP16_LT:
    MOV A, R1
    CLR C
    SUBB A, DPH
    JZ CHECK_LOW
    JC DONE_LT     ; R1 < DPH
    SJMP DONE_GE   ; R1 > DPH

CHECK_LOW:
    MOV A, R0
    CLR C
    SUBB A, DPL
    JC DONE_LT     ; R0 < DPL

DONE_GE:
    CLR C          ; Greater or equal
    RET

DONE_LT:
    SETB C         ; Less than
    RET



END_CHECK:
    MOV TL0, #00h   ; Clear Timer0 low byte
    MOV TH0, #00h   ; Clear Timer0 high byte
    LJMP    MAIN_TOGGLE

MSG1: DB 'Distance: ', 0
MSG2: DB ' cm', 13, 10, 0
MSG3: DB 'timer: ', 0
SPACE: DB ' ', 0

END