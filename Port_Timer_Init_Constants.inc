;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                        Port_Timer_Init_Constants.inc                       ;
;            Constants for Timer and Port Initialization Functions           ;
;                               Homework #3                                  ;
;                                EE/CS 10b                                   ;
;                                                                            ;
;                              Benjamin Boone                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the assembly language definitions and constants used for
; the several initialization functions, and TimerInit functions for the pinball 
; machine project as a part of EE/CS 10b, Homework 5.
;
; Revision History:
;   5/2/2025    Benjamin Boone  Initialized needed constants
;   5/3/2025    Benjamin Boone  Added needed constants for new sensorCode 
;                                   generation
;   5/13/2025   Benjamin Boone  Repurposed old file for Homework 3
;   5/16/2025   Benjamin Boone  Updated constants for initialization file
;	6/14/2025	Benjamin Boone	Updated to work with HW5 Pinball Main


; Timer Tnitializaiton constants for Timer0
.equ    TIMERCLK     =      0b00000011  ; divides the clock by 64.
                           	; 0-------  not forcing output compare match
					       	; -0--0---  no waveform generation
					       	; --00----  normal operation of compare match
					       	; -----011  prescale timer by 32


.equ    TIMERCOMP       =   124         ; compare match register value to get to
                                        ; 1 ms interrupts after prescaling by 64

; I/O port definitions

.equ	OUTDATA         =   0b11111111	; data direction 1 is output
.equ    INDATA          =   0b00000000	; data direction 0 is input

; I/O port initial values
.equ    INIT_PORTS_OFF  =   $00         ; turn off LEDs (low is off)


; For the Status Register
.equ 	ZERO_FLAG 		=	1			; Zero Flag is Bit 1 in SREG
.equ 	CARRY_FLAG 		=	0			; Carry Flag is Bit 0 in SREG