;----------------------------------------
; Variables / Ports
;----------------------------------------
US_TRIG_R   EQU  P1.1    ; Right Trigger pin
US_ECHO_R   EQU  P1.0    ; Right Echo pin
LED_FAR_1   EQU  P2.0    ; First Far LED
LED_FAR_2   EQU  P2.4    ; Second Far LED
LED_MID_1   EQU  P2.1    ; First Mid LED
LED_MID_2   EQU  P2.3    ; Second Mid LED
LED_CLOSE   EQU  P2.2    ; Close LED

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



START:
;----------------------------------------
; Main Toggle Loop
;----------------------------------------
MAIN_TOGGLE:
    SETB    US_TRIG_R    ; Drive P1.1 HIGH
    ACALL   DELAY_10US   ; Wait ≈10 µs
    CLR     US_TRIG_R    ; Drive P1.1 LOW
    ACALL   DELAY_10US   ; Wait ≈10 µs
    SJMP    MAIN_TOGGLE  ; Repeat forever
END