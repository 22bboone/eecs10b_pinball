;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                     Timer0CompareMatch_EventHandler.asm                    ;
;                             Interrupt Handler			                     ;
;                   			  Homework #5					             ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the general interrupt handlers for the clock. The handlers 
; included are:
;    Timer0CompareMatch  - handler for timer 0 compare match interrupts
;
; Revision History:
;    5/17/2025	Benjamin Boone		Initial revision
;	 6/13/2025	Benjamin Boone		Updated to Display Functions and Scan And 
;										Debounce work together.
;	 6/14/2025	Benjamin Boone		Added calls to flash, blink, and sound play
;										updated functions. Updated Comments.


; device definitions
;.include  "m64def.inc"

; local include files
;    none

.cseg

; Timer0CompareMatch
;
; Description:       This is the event handler for compare match events on timer
;                    0.  It just calls the appropriate handlers. 
;
; Operation:         Calls the MuxLEDs function to Mux the display, calls the
;					 ScanAndDebounce Function to find sensors pressed. Calls the
;					 functions for Flashing a light, Blinking the Display, 
;					 playing a short burst of sound, and playing GameMusic. 
;					 These are operations that depend on time, and thus are 
;					 called by regular interrupts in this eventHandler.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Stack Depth:       7 bytes. Other Functions Pop and Push Individually as well.
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025

Timer0CompareMatch:             
    push    r0					; don't trash R0
	in 		r0, sreg            ; save the flags
	push	r0                  ; save the registers changed in MuxLEDs
	push	r16
	push	r17
	push	r18
    push    ZL
    push    ZH

DebounceFromEventHandler:		; previously written, ScanAndDebounce saves it's
    rcall   ScanAndDebounce			; registers already.

FlashingFromEventHandler:		; update any flashing lights, saves it's own
	rcall 	CheckFlashingLight		; registers. 

BlinkDigitsFromEventHandler:	; update the blinking display (if blinking)
	rcall	CheckBlinkingDigits		; saves it's own registers

DisplayLEDsFromEventHandler:	; Mux the LED display (both grid + digits)
    rcall   MuxLEDs             	

BurstFromEventHandler:			; update any timed sound bursts going on
	rcall	CheckSoundBurst			; saves own registers

GameMusicFromEventHandler:		; operate playing music during the game
	rcall 	CheckIfSongPlaying	

EndTimer0CompareMatch:                
    pop     ZH					; restore all pushed registers and sreg
    pop     ZL 
	pop		r18
	pop		r17
	pop		r16
	pop		r0	
	out		sreg, r0
    pop     r0
	reti                ; done with the eventhandler, return, set interrupts


; #############################################################################
