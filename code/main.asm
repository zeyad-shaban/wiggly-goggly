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

LCD_RS      EQU  P1.2
LCD_RW      EQU  P1.3
LCD_EN      EQU  P1.4
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

; )NOTE: must move value you wish to print into register DPTR)
LCD_SEND_STRING:
    CLR A
    MOVC A, @A+DPTR
    JZ LCD_STRING_DONE
    ACALL LCD_DATA_WRITE
    INC DPTR
    SJMP LCD_SEND_STRING
LCD_STRING_DONE:
    RET

LCD_CLEAR:
    MOV   A,#01h             ; Clear-Display command
    ACALL LCD_CMD            ; sends it
    ACALL LCD_DELAY          ; yields plenty of time (> 1.6 ms)
    RET

;----------------------------------------------------------
;  LCD_SEND_DECIMAL  – prints an 8-bit value in A (0-255)
; )NOTE: must move value you wish to print into register A)
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

;----------------------------------------------------------
; Delay ≈ 500 µs
DELAY_500US:
    MOV R2, #5
L1: MOV R3, #40
L2: NOP
    DJNZ R3, L2
    DJNZ R2, L1
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
    MOV TMOD, #01H       ; Timer1 Mode 2 (for UART), Timer0 Mode 1
    CLR TR0               ; Ensure Timer0 OFF
   
    MOV TL0, #00h  ; Reset Timer0 for next round
    MOV TH0, #00h

    CLR LED0 ; make sure all pins are ready
    CLR LED1
    CLR LED2
    CLR LED3
    CLR LED4
    CLR LED5
    CLR LED6
    CLR LED7
    CLR US_TRIG_R
    CLR US_ECHO_R
    CLR LCD_RS      
    CLR LCD_RW      
    CLR LCD_EN      
    CLR LCD_DATA   

    ACALL LCD_INIT       ; Initialize LCD
    
    ;send start string
    MOV DPTR,#MSG_START
    ACALL LCD_SEND_STRING
    ACALL DELAY_500US
    ACALL LCD_CLEAR

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
    ACALL LCD_SEND_STRING
    MOV A,TH0
    ACALL LCD_SEND_HEX
    MOV A,TL0
    ACALL LCD_SEND_HEX

        ; Calculate pulse duration
    MOV A, TL0       ; Store TL0 in R0
    MOV R0, A
    MOV A, TH0       ; Store TH0 in R1
    MOV R1, A

    ; Use DPH:DPL = R1:R0 to load 16-bit value
    MOV DPL, R0
    MOV DPH, R1

    ; Approximate Distance = timer / 53
    ; Result will be in R7
    MOV R7, #0        ; Distance result = 0

DIV_LOOP:
    CLR C
    MOV A, DPL
    SUBB A, #53
    MOV DPL, A
    MOV A, DPH
    SUBB A, #00
    MOV DPH, A
    JC DIV_DONE       ; Stop if DPH:DPL < 53
    INC R7
    SJMP DIV_LOOP

DIV_DONE:
    ; ---- move cursor to start of line 2 ------------------
    MOV  A,#0C0h              ; DDRAM addr 40 → line 2, col 0
    ACALL LCD_CMD

    ; Display Distance (in cm)
    MOV DPTR, #MSG_DISTANCE
    ACALL LCD_SEND_STRING
    MOV A, R7
    ACALL LCD_SEND_DECIMAL

        ; ----- Clear all LEDs (P2.0 to P2.7) -----
    MOV P2,#0h

    ; ----- Light LEDs based on distance in R2 -----
    MOV A, R7

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
    
    ACALL LCD_CLEAR
    LJMP MAIN_TOGGLE

;---------------------Rom Message------------------------------------
MSG_PULSE: DB "Pulse: ", 0
MSG_START: DB "Program Starting",0
MSG_DISTANCE: DB "Distance: ", 0
HEX_TAB: DB  "0123456789ABCDEF" ; 16-byte table


END
