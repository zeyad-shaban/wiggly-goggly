; VARS
US_RIGHT EQU P2.6
US_LEFT EQU P2.7

LED_RED_L EQU P2.0
LED_YELLOW_L EQU P2.1
LED_GREEN EQU P2.2
LED_YELLOW_R EQU P2.3
LED_RED_R EQU P2.4


ORG 0000h
LJMP START    ; Jump to start of program


; ------DELAY SUBROUTINES-----
DELAY1US:
    MOV R2, #2       ; Outer count for roughly 2 µs
D1:
    NOP              ; 1 cycle
    NOP              ; 1 cycle
    DJNZ R2, D1      ; 2 cycles when decrement ≠ 0, 1 cycle when zero
    RET

DELAY10US:
    MOV R2, #10
D10:
    ACALL DELAY1US
    DJNZ R2, D10
    RET

;--- Main ---
START:      MOV TMOD, #00h   ; Clear timers
            CLR  TR0         ; ensure timer 0 stops
            CLR  TF0         ; clear overflow flag
            
            ; Initialize all LEDs to OFF
            MOV  P2, #000h   ; Initialize all pins high

MAIN_LOOP:
    ; 1. Trigger
        CLR  US_RIGHT
        ACALL DELAY1US
        SETB US_RIGHT
        ACALL DELAY10US
        CLR  US_RIGHT


    ; 2. Measure Echo
WAIT_HIGH:  JB   US_RIGHT, OK_HIGH
            SJMP WAIT_HIGH
OK_HIGH:    MOV  TMOD, #01h  ; Timer0 Mode1
            CLR  TR0
            CLR  TF0
            MOV  TH0, #0     ; Reset timer high byte
            MOV  TL0, #0     ; Reset timer low byte
            SETB TR0

WAIT_LOW:   JNB  US_RIGHT, OK_LOW
            SJMP WAIT_LOW
OK_LOW: CLR TR0

    ; 3. Compare Timer Value Against 1160 (20cm)
        MOV A, TH0
        CJNE A, #04h, CHECK_HIGH
        MOV A, TL0
        CJNE A, #88h, CHECK_LOW
        SJMP DIST_EQUAL

CHECK_HIGH: JC DIST_LESS
        JMP DIST_MORE

CHECK_LOW: JC DIST_LESS
        JMP DIST_MORE

DIST_LESS: SETB LED_RED_R
        SJMP NEXT

DIST_MORE: CLR LED_RED_R
DIST_EQUAL: CLR LED_RED_R

;========
; THIS NEXT IS JUST DUMMY FOR TESTING PURPOSE, IT SHOULD SET ALL PORT 2 TO ONES INFINITELY IF REACHED,
; THIS DUMMY TEST SHOWS THAT WITH THE CURRENT IMPLEMENTAITON NEXT IS NEVER ACTUALLY REAACHED!!
NEXT:   ; Test section - infinite loop setting P2 to all 1's
        MOV P2, #0FFh    ; Set all P2 bits to 1
TEST_LOOP:
        SJMP TEST_LOOP   ; Infinite loop
;========

;NEXT:   ; Add logic for other sensors/LEDs
;        ACALL DELAY10US
;        SJMP MAIN_LOOP
;
END