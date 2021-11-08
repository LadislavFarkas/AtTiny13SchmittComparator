;
; AssemblerApplication1.asm
;
; Created: 11/6/2021 15:41:19
; Author : Ladislav Farkas
;

;				   AtTiny13A
;				    RST	VCC
;	(upper treshold)    ADC3    PB4	PB2	ADC1 (input signal)
;	(lower treshold)    ADC2    PB3	PB1	!OUTPUT
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

.org	ADCCaddr
rjmp	ADC_IRQ

.org	INT_VECTORS_SIZE

RESET:
    cli

    ldi	    r16,    1 << NEG_OUTPUT_PIN | 1 << OUTPUT_PIN
    out	    DDRB,   r16
    nop

    in	    r16,    MCUCR
    ori	    r16,    1 << SE
    out	    MCUCR,  r16
    nop

; input registers: -
; output registers: Z, r16, r17
LOOP:
    ldi	    zl,	    LOW(BUFFER)
    ldi	    zh,	    HIGH(BUFFER)

    ldi	    r16,    1 << ADC0D | 1 << ADC1D | 1 << ADC2D
    ldi	    r17,    1 << MUX1 | 1 << MUX0
    rcall   READ_ADC

    ldi	    r16,    1 << ADC0D | 1 << ADC1D | 1 << ADC3D
    ldi	    r17,    1 << MUX1
    rcall   READ_ADC

    ldi	    r16,    1 << ADC0D | 1 << ADC2D | 1 << ADC3D
    ldi	    r17,    1 << MUX0
    rcall   READ_ADC

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

    cp	    r16,    r18 ; H
    brlo    PROCESS_TURN_OFF
    breq    PROCESS_CHECK_LOWER_L
    rjmp    PROCES_CHECK_UPPER_H

PROCESS_CHECK_LOWER_L:
    cp	    r17,    r19 ; L
    brlo    PROCESS_TURN_OFF

PROCES_CHECK_UPPER_H:
    ; upper treshold H L
    ld	    r18,    -Z ; H
    ld	    r19,    -Z ; L

    cp	    r18,    r16 ; H
    brlo    PROCESS_TURN_ON
    breq    PROCESS_CHECK_UPPER_L
    rjmp    PROCESS_RET

PROCESS_CHECK_UPPER_L:
    cp	    r19,    r17 ; L
    brlo    PROCESS_TURN_ON
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

; input registers: r16, r17
; output registers: -
READ_ADC:
    out	    DIDR0,  r16
    nop

    out	    ADMUX,  r17
    nop
    nop

    sbi	    ADCSRA, ADLAR
    nop
    sbi	    ADCSRA, ADIE
    nop
    sbi	    ADCSRA, ADEN
    nop
    sbi	    ADCSRA, ADSC
    nop
    nop
    nop

    sei
    sleep
    cli

    cbi	    ADCSRA, ADEN
    nop

    ret

; input registers: Z
; output registers: Z
ADC_IRQ:
    push    r16

    in	    r16,    ADCL
    st	    Z+,	    r16
    in	    r16,    ADCH
    st	    Z+,	    r16

    pop	    r16

    reti