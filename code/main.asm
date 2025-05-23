;----------------------------------------------------------
; Project: Ultrasonic Echo Timer Measurement
; Clock  : 11.0592 MHz
; UART   : 9600 baud
; UART output = raw TH0/TL0 count of ECHO pulse width
;----------------------------------------------------------

MSG_PULSE: DB "Pulse: ", 0
MSG_START: DB "Program Starting",0


US_TRIG_R   EQU  P1.1    ; Right Trigger pin
US_ECHO_R   EQU  P1.0    ; Right Echo pin
LED_FAR_1   EQU  P2.0
LED_FAR_2   EQU  P2.4
LED_MID_1   EQU  P2.1
LED_MID_2   EQU  P2.3
LED_CLOSE   EQU  P2.2


$INCLUDE (delay.inc)
$INCLUDE (uart.inc)
$INCLUDE (ultrasonic_logic.inc)

ORG 0000h
LJMP START 

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

ACALL WAIT_ECHO_HIGH
ACALL WAIT_RISE

NO_ECHO:
    CLR TR0
    CLR LED_CLOSE
    SJMP MAIN_TOGGLE

GOT_ECHO:
    ACALL WAIT_ECHO_LOW
    ; Reset Timer0 for next round
    MOV TL0, #00h
    MOV TH0, #00h

    SJMP MAIN_TOGGLE

END
