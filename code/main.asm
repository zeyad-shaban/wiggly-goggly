;----------------------------------------------------------
; Project: Ultrasonic Echo Timer Measurement
; Clock  : 11.0592 MHz
; Output : LCD Screen and Led Display
;----------------------------------------------------------

US_TRIG_R   EQU  P1.1    ; Right Trigger pin
US_ECHO_R   EQU  P1.0    ; Right Echo pin

LED0 EQU P2.0; 10cm ; LEDS Output Display
LED1 EQU P2.1; 20cm
LED2 EQU P2.2; 30cm
LED3 EQU P2.3; 40cm
LED4 EQU P2.4; 50cm
LED5 EQU P2.5; 60cm
LED6 EQU P2.6; 70cm
LED7 EQU P2.7; >70cm

LED_OUT EQU P1.3 ;Out of Range LED

;LCD Control Pins and Data Port
LCD_RS      EQU  P1.5
LCD_RW      EQU  P1.6
LCD_EN      EQU  P1.7
LCD_DATA    EQU  P3

$INCLUDE (delay.inc);include the SUB_ROUTINES
$INCLUDE (ultrasonic_logic.inc)
$INCLUDE (LCD.inc)

ORG 0000h
LJMP START 

START:
    MOV TMOD, #01H      ;Timer0 Mode 1(16 bit) TL & TH
    CLR TR0             ; Ensure Timer0 OFF
    
    MOV TL0, #00h 		; Reset Timer0 for next round
    MOV TH0, #00h

    CLR LED0 			; make sure all pins are ready
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
    MOV LCD_DATA,#00h
    
     ACALL LCD_INIT     ; Initialize LCD

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

ACALL WAIT_ECHO_HIGH
ACALL WAIT_RISE

CLR LED_OUT

NO_ECHO:
    CLR TR0
    SETB LED_OUT
    SJMP MAIN_TOGGLE

GOT_ECHO:
    ACALL WAIT_ECHO_LOW
    ; Reset Timer0 for next round
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