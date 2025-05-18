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
    ; Initialize timer
    MOV     TMOD, #01h    ; Timer0 in Mode 1 (16‑bit)
    CLR     TR0           ; Ensure Timer0 is OFF 
    CLR LED_FAR_1
    CLR LED_FAR_2
    CLR LED_MID_1
    CLR LED_MID_2
    CLR LED_CLOSE
    CLR US_TRIG_R
    CLR US_ECHO_R

    
MAIN_TOGGLE:
    ; Call Trigger
    SETB    US_TRIG_R    ; Drive P1.1 HIGH
    ACALL   DELAY_10US   ; Wait ≈10 µs
    CLR     US_TRIG_R    ; Drive P1.1 LOW
    ACALL   DELAY_10US   ; Wait ≈10 µs



WAIT_ECHO_LOW:
    JB   US_ECHO_R, WAIT_ECHO_LOW
    CLR  TF0
    CLR  TR0           ; ensure timer stopped

    ;----------------------------------------
    ; 2) Start Timer & await rising edge
    ;----------------------------------------
    SETB TR0

; Set up timeout = 11 600 µs / 3 µs ≈ 3867 loops
MOV   R1, 0Fh    ; high byte = 15
MOV   R0, 23h    ; low byte = 35 → 15×256 + 35 = 3860

WAIT_RISE:
    JB   US_ECHO_R, GOT_ECHO
    DJNZ  R0, WAIT_RISE   ; decrement low‑byte
    DJNZ  R1, WAIT_RISE   ; when low‑byte underflows, decrement high‑byte
    SJMP  NO_ECHO

SETB  LED_CLOSE

NO_ECHO:
    CLR  TR0                      ; ensure timer stopped
    CLR  LED_CLOSE                ; indicate “no reading” or far
    SJMP MAIN_TOGGLE              ; retrigger immediately

GOT_ECHO:
    CLR TR0
    ; Get result
    ;Distance (cm) = (Echo_High_Time (µs)) / 58
    ; example calculation: 10cm = 10 * 58 = 580us

    MOV     A, TH0
    CJNE    A, #2, IS_CLOSE   ; TH0<2 ⇒ count<512 ⇒ definitely <580
    JC      IS_CLOSE
    ; if TH0>2 ⇒ count>2×256=512 but might still be <580
    ; for TH0==2 check TL0
    MOV   A, TL0
    CLR   C            ; clear carry before subtraction
    SUBB  A, #044h     ; A ← TL0 − 68; C=0 if TL0≥68, C=1 if TL0<68
    JNC   NOT_CLOSE    ; if C=0 (TL0≥0x44) → not close
    ; else (C=1) → close
    SJMP  IS_CLOSE

NOT_CLOSE:
    CLR     LED_CLOSE
    SJMP    END_CHECK

IS_CLOSE:
    SETB    LED_CLOSE

END_CHECK:
    SJMP    MAIN_TOGGLE


END