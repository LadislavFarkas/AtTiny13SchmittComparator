;
; AssemblerApplication1.asm
;
; Created: 11/6/2021 15:41:19
; Author : Ladislav Farkas
;

;
;			RST	VCC
;	ADC3	PB4	PB2		ADC1
;	ADC2	PB3	PB1		-
;			GND	PB0		-
;

.equ	OUTPUT_PIN = PB0
.equ	NEG_OUTPUT_PIN = PB1

.dseg

.org	SRAM_START

SRC_PIN: .BYTE 1
VAR_ADC: .BYTE 1

.cseg

.org 0

rjmp	RESET

.org INT_VECTORS_SIZE

RESET:
	; SPL is already set

	cli
	
	; Output pins
	ldi		r16, 1 << NEG_OUTPUT_PIN | 1 << OUTPUT_PIN
	out		PORTB, r16

MAIN:
	; r21 - ADC1
	ldi		r16, 1 << MUX0
	sts		SRC_PIN, r16
	rcall	GET_ADC_VAR
	lds		r21, VAR_ADC

	; r22 - ADC2
	ldi		r16, 1 << MUX1
	sts		SRC_PIN, r16
	rcall	GET_ADC_VAR
	lds		r22, VAR_ADC
    rjmp	MAIN

	cp		r21, r22

	; r23 - ADC3
	ldi		r16, 1 << MUX1 | 1 << MUX0
	sts		SRC_PIN, r16
	rcall	GET_ADC_VAR
	lds		r23, VAR_ADC

	rjmp	MAIN

GET_ADC_VAR:
	push	r16
	push	zl
	push	zh

	lds		r16, SRC_PIN

	; VCC used as analog reference
	; left adjusted result
	ori		r16, 1 << ADLAR
	out		ADMUX, r16
	clr		r16

	; Prescaller division factor 2
	; Interupt disabled
	; Auto trigger disabled
	; Single converzion
	; ADC enable
	ori		r16, 1 << ADEN | 1 << ADSC
	out		ADCSRA, r16

	sbic	ADCSRA, ADSC
	rjmp	PC-1
	in		r16, ADCH

	ldi		zl, low(VAR_ADC)
	ldi		zh, high(VAR_ADC)
	st		Z, r16
	
	clr		r16
	out		ADCSRA, r16

	pop		zh
	pop		zl
	pop		r16
	ret
