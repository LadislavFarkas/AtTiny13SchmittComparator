;
; AssemblerApplication1.asm
;
; Created: 11/6/2021 15:41:19
; Author : Ladislav Farkas
;

;				   AtTiny13A
;				    RST	VCC
;	(upper treshold)    ADC2    PB4	PB2	ADC1 (input signal)
;	(lower treshold)    ADC3    PB3	PB1	!OUTPUT
;				    GND	PB0	OUTPUT
;

.equ	OUTPUT_PIN = PB0
.equ	NEG_OUTPUT_PIN = PB1

.dseg

.org	SRAM_START

BUFFER	: .BYTE 6   ; UPPER L H | LOWER L H | INPUT L H

.cseg

.org	0
rjmp	RESET

.org	INT_VECTORS_SIZE

RESET:
    cli

    ldi	    r16,    1 << NEG_OUTPUT_PIN | 1 << OUTPUT_PIN
    out	    DDRB,   r16
    nop

; input registers: -
; output registers: Z, r17
LOOP:
    ldi	    zl,	    LOW(BUFFER)
    ldi	    zh,	    HIGH(BUFFER)

    ;cbi	    PORTB,  NEG_OUTPUT_PIN
    ldi	    r16,    1 << MUX1 | 1 << MUX0 ; PB3
    rcall   READ_ADC

    ;sbi	    PORTB,  NEG_OUTPUT_PIN
    ldi	    r16,    1 << MUX1 ; PB4
    rcall   READ_ADC

    ;cbi	    PORTB,  NEG_OUTPUT_PIN
    ldi	    r16,    1 << MUX0 ; PB2
    rcall   READ_ADC

    ;sbi	    PORTB,  NEG_OUTPUT_PIN
    rcall   PROCESS

    rjmp    LOOP
    
; input registers: Z
; output registers: Z
PROCESS:
    push    r16
    push    r17
    push    r18
    push    r19

    ; input value
    ld	    r16,    -Z ; H
    ld	    r17,    -Z ; L

    ; lower treshold H L
    ld	    r18,    -Z ; H
    ld	    r19,    -Z ; L

PROCESS_CHECK_LOWER_H:
    cp	    r16,    r18 ; H
    brlo    PROCESS_TURN_OFF
    breq    PROCESS_CHECK_LOWER_L
    rjmp    PROCESS_CHECK_UPPER_H

PROCESS_CHECK_LOWER_L:
    cp	    r17,    r19 ; L
    brlo    PROCESS_TURN_OFF	    ; input_h = low_h & input_l < low_l

PROCESS_CHECK_UPPER_H:
    ; upper treshold H L
    ld	    r18,    -Z ; H
    ld	    r19,    -Z ; L

    cp	    r18,    r16 ; H
    brlo    PROCESS_TURN_ON
    breq    PROCESS_CHECK_UPPER_L
    rjmp    PROCESS_RET

PROCESS_CHECK_UPPER_L:
    cp	    r19,    r17 ; L
    brlo    PROCESS_TURN_ON	    ; upper_l < input_l "zapinam"
    rjmp    PROCESS_RET

PROCESS_TURN_ON:
    sbi	    PORTB,  OUTPUT_PIN
    cbi	    PORTB,  NEG_OUTPUT_PIN
    rjmp    PROCESS_RET

PROCESS_TURN_OFF:
    sbi	    PORTB,  NEG_OUTPUT_PIN
    cbi	    PORTB,  OUTPUT_PIN
    
PROCESS_RET:
    pop	    r19
    pop	    r18
    pop	    r17
    pop	    r16
    ret

; input registers: Z, r16
; output registers: Z
READ_ADC:
    push    r17
    ldi	    r17, 1 << ADC1D | 1 << ADC2D | 1 << ADC3D

    out	    DIDR0, r17
    nop

    out	    ADMUX, r16
    nop
    nop

    sbi	    ADMUX, ADLAR
    nop
    sbi	    ADCSRA, ADEN
    nop
    sbi	    ADCSRA, ADSC
    nop
    nop
    nop

READ_ADC_W8:
    in	    r17,    ADCSRA
    andi    r17,    (1 << ADSC)
    brne    READ_ADC_W8

    in	    r17,    ADCL
    st	    Z+,	    r17
    in	    r17,    ADCH
    st	    Z+,	    r17

    cbi	    ADCSRA, ADEN
    nop

    pop	    r17

    ret
