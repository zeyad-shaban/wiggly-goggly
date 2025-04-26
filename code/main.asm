;----------------------------------------
; Variables / Ports
;----------------------------------------
US_TRIG_R   EQU  P1.1    ; Right Trigger pin

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