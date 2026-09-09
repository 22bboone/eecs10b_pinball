;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               Timer_Init.asm   	                         ;
;                              Timer Initialization                          ;
;                                 Homework #3                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the function for initializing the timer used for timed
; interrupts for the display and debounce functions in Homework 5.  The public 
; functions included are:
;    InitTimer0    - initialize timer 0 for 1 ms interrupts
;
; Revision History:
;   06/13/2025  Benjamin Boone  Initial Revision, copied functions from past HW
;

; device definitions
;.include  "m64def.inc" -   done in main file

; local include files
;.include  "Init_Constants.inc"  -   done in the main file
 

.cseg

; ------------------------------------------------------------------------------
; InitTimer0
;
; Description:       This function initializes Timer0 for exactly 1
;                    millisecond interrupts assuming an 8 MHz clock.
;
; Operation:         Initialization is done by prescaling Timer0 by 32, then 
;                    setting a compare match register value of 124 to generate 
;                    exactly 1 millisecond interrupts.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Timer 0 is initialized.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, r16
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025


InitTimer0:
                                    ;setup timer 0
	clr	r16			                ;clear the count register
	out	TCNT0, r16		            ;    (not really necessary)
	ldi	r16, TIMERCLK		        ; use CLK/PRESCALE as timer source, gives
	out	TCCR0, r16		            ; rate. See Constants for that rate

    ldi r16, TIMERCOMP              ; set the compare register to 124       
    out OCR0, r16                   ; to complete the conversion

	in	r16, TIMSK		            ;get current timer interrupt masks
	ori	r16, 1 << OCIE0		        ;turn on timer 0 interrupts                   
	out	TIMSK, r16
    ;rjmp   EndInitTimer0           ;done setting up the timer


EndInitTimer0:                      ;done initializing the timer - return
        ret
