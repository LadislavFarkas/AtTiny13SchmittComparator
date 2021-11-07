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
	out		DDRB, r16

MAIN:
	;r17	on/off state (bool)

	clr		r17
LOOP:
	;r16	temporary
	;r21	input voltage
	;r22	low ref. voltage
	;r23	high ref. volatage

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
    
	; r23 - ADC3
	ldi		r16, 1 << MUX1 | 1 << MUX0
	sts		SRC_PIN, r16
	rcall	GET_ADC_VAR
	lds		r23, VAR_ADC

	sbrc	r17, 0
	rjmp	IS_ON
IS_OFF:
	cp		r21, r23
	brsh	TURN_ON
	rjmp	TURN_OFF
IS_ON:
	cp		r21, r22
	brsh	TURN_ON
	rjmp	TURN_OFF

TURN_ON:
	ldi		r17, 1
	sbi		PORTB, OUTPUT_PIN
	cbi		PORTB, NEG_OUTPUT_PIN
	rjmp	LOOP
TURN_OFF:
	clr		r17
	sbi		PORTB, NEG_OUTPUT_PIN
	cbi		PORTB, OUTPUT_PIN
	rjmp	LOOP

GET_ADC_VAR:
	push	r16
	push	zl
	push	zh

	lds		r16, SRC_PIN
	out		ADMUX, r16
	nop
	
	; VCC used as analog reference
	; left adjusted result
	sbi		ADMUX, ADLAR
	nop

	; Prescaller division factor 2
	; Interupt disabled
	; Auto trigger disabled
	; Single converzion
	; ADC enable
	sbi		ADCSRA, ADEN
	nop
	sbi		ADCSRA, ADSC
	nop

	sbis	ADCSRA, ADSC
	rjmp	PC-1
	
	sbic	ADCSRA, ADSC
	rjmp	PC-1
	;in		r16, ADCL ; no need, because ADLAR is used
	in		r16, ADCH

	sbi		ADCSRA, ADIF
	nop

	ldi		zl, low(VAR_ADC)
	ldi		zh, high(VAR_ADC)
	st		Z, r16
	
	cbi		ADCSRA, ADEN
	nop

	pop		zh
	pop		zl
	pop		r16
	ret
