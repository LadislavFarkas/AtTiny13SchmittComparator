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
.equ	UART_TX = PB1

.dseg

.org	SRAM_START

BUFFER	: .BYTE 3   ; UPPER H | LOWER H | INPUT H

.cseg

.org	0
rjmp	RESET

.org	INT_VECTORS_SIZE

RESET:
    cli

    ldi	    r16,    1 << UART_TX | 1 << OUTPUT_PIN
    out	    DDRB,   r16
    nop

    ; uart init
    sbi	    PORTB, UART_TX
    nop
    rcall   UART_DELAY

    ldi	    r16, 1 << ADC1D | 1 << ADC2D | 1 << ADC3D
    out	    DIDR0, r16
    nop

    ldi	    r16, 1 << ADPS2 | 1 << ADPS1 | 1 << ADPS0
    out	    ADCSRA ,r16
    nop

    sbi	    ADMUX, ADLAR
    nop

    sbi	    ADCSRA, ADEN
    nop

; input registers: -
; output registers: Z, r16
LOOP:
    ldi	    zl,	    LOW(BUFFER)
    ldi	    zh,	    HIGH(BUFFER)

    ldi	    r16,    1 << MUX1 | 1 << MUX0 ; PB3 - ADC3 - upper
    rcall   READ_ADC

    ldi	    r16,    1 << MUX1 ; PB4 - ADC2 - lower
    rcall   READ_ADC

    ldi	    r16,    1 << MUX0 ; PB2 - ADC1 - input
    rcall   READ_ADC

    rcall   SEND2UART

    rcall   PROCESS

    rjmp    LOOP
    
SEND2UART:
    push    r16
    push    r17

    mov	    r16, zl
    mov	    r17, zh

    push    r16
    push    r17

    rcall   UART_RESET_DELAY

    ldi	    r16, 'B'
    rcall   SENDr16UART

    ldi	    r16, 'E'
    rcall   SENDr16UART

    ; UPPER H | LOWER H | INPUT H

    ; input value H
    ld	    r16,    -Z
    rcall   SENDr16UART

    ; input value L
    ;ld	    r16,    -Z
    ;rcall   SENDr16UART

    ; lower treshold H
    ld	    r16,    -Z
    rcall   SENDr16UART

    ; lower treshold L
    ;ld	    r16,    -Z
    ;rcall   SENDr16UART

    ; upper treshold H
    ld	    r16,    -Z
    rcall   SENDr16UART

    ; upper treshold L
    ;ld	    r16,    -Z
    ;rcall   SENDr16UART

    ldi	    r16, 'E'
    rcall   SENDr16UART
    ldi	    r16, 'D'
    rcall   SENDr16UART

    pop	    r17
    pop	    r16

    mov	    zl, r16
    mov	    zh, r17

    pop	    r17
    pop	    r16

    ret

; inpit registers: R16
; output registers:
SENDr16UART:
    push    r17
    push    r18

    ; start bit
    cbi	    PORTB, UART_TX
    rcall   UART_DELAY

    ldi	    r17, 8

SENDr16UART_nb:
    ror	    r16
    brcs    SENDr16UART_b1

SENDr16UART_b0:
    cbi	    PORTB, UART_TX
    rjmp    SENDr16UART_d

SENDr16UART_b1:
    sbi	    PORTB, UART_TX
    rjmp    SENDr16UART_d

SENDr16UART_d:
    rcall   UART_DELAY
    dec	    r17
    brne    SENDr16UART_nb

    ; stop bit
    sbi	    PORTB, UART_TX
    rcall   UART_DELAY
    
    pop	    r18
    pop	    r17

    ret

UART_DELAY: ; 9600 8n1 == 1042 us per frame == 104.2 us per bit
    push    r16
    ldi	    r16, 244
UART_DELAY0:
    nop
    dec	    r16
    brne    UART_DELAY0
    nop
    nop
    nop
    nop
    pop	    r16
    ret

UART_RESET_DELAY:
    push    r16
    ldi	    r16, 11
UART_RESET_DELAY0:
    rcall   UART_DELAY
    dec	    r16
    brne    UART_RESET_DELAY0
    pop	    r16
    ret

; input registers: Z
; output registers: Z
PROCESS:
    push    r16
    push    r17

    ; RAM ukazuje za INPUT_H a data su v poradi opbratene : UPPER H | LOWER H | INPUT H

    ; input value
    ld	    r16,    -Z

    ; lower treshold lower
    ld	    r17,    -Z

    cp	    r16,    r17
    brlo    PROCESS_TURN_OFF

    ; lower treshold upper
    ld	    r17,    -Z

    cp	    r17,    r16
    brlo    PROCESS_TURN_ON
    rjmp    PROCESS_RET

PROCESS_TURN_ON:
    sbi	    PORTB,  OUTPUT_PIN
    nop
    rjmp    PROCESS_RET

PROCESS_TURN_OFF:
    cbi	    PORTB,  OUTPUT_PIN
    nop
    
PROCESS_RET:
    pop	    r17
    pop	    r16
    ret

; input registers: Z, r16
; output registers: Z
READ_ADC:
    push    r17

    out	    ADMUX, r16
    nop
    nop

    sbi	    ADCSRA, ADSC
    nop
    nop
    nop

READ_ADC_W8:
    sbic    ADCSRA, ADSC
    rjmp    READ_ADC_W8

    in	    r17,    ADCH
    st	    Z+,	    r17

    pop	    r17

    ret
