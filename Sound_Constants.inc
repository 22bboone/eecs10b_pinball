;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               Sound_Constants.inc                          ;
;                                 Homework #4                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the assembly language definitions and constants used for    
; the sound functions for the pinball machine project as a part of EE/CS 10b, 
; Homework 5. Includes constants for the timer, musical notes and duration.
;
; Revision History:
;   5/30/2025    Benjamin Boone  Initial Revision of Constants
;	6/14/2025 	 Benjamin Boone	 Added Constants for Music


; General Hardware Definitions
.equ    SOUND_BIT   =   5           ; Bit 5 in the DDRB Register outputs sound.


; timer definitions
.equ	TIMER1A_ON  = 0b01000000	;setup timer 1 for tone output on OC1A
					 ;  01------  toggle OC1A output on compare match
					 ;  --00----  no output on OC1B
					 ;  ----00--  no output on OC1C
					 ;  ------00  no PWM output

.equ	TIMER1B_ON  = 0b00001010	;setup timer 1 for tone output on OC1A
					 ;  0-------  disable noise canceler
					 ;  -0------  capture on falling edge
					 ;  --0-----  reserved
					 ;  ---01---  clear on compare match
					 ;  -----010  run timer on clk/8

.EQU	TIMER1A_OFF = 0b00000000	;turn off timer 1
					 ;  00------  no output on OC1A
					 ;  --00----  no output on OC1B
					 ;  ----00--  no output on OC1C
					 ;  ------00  no PWM output

.equ    TIMER1B_OFF = 0b00001000  	;turn off timer 1
					 ;  0-------  disable noise canceler
					 ;  -0------  capture on falling edge
					 ;  --0-----  reserved
					 ;  ---01---  clear on compare match
					 ;  -----000  turn off the timer


; Prescaled CPU clock divided by 2 (8,000,000 / 8 / 2). 2 for toggle.
.equ    PRESCALED_CLK_FREQ_LOW    = 0b00100000  ; 500k in 3 different
.equ    PRESCALED_CLK_FREQ_MID    = 0b10100001  ;  registers.
.equ    PRESCALED_CLK_FREQ_HIGH   = 0b00000111


; Music Table Template for AVR Assembly
; Standard note frequencies and duration definitions
; Courtesy of Claude by Anthropic

; ============================================================================
; NOTE FREQUENCY DEFINITIONS (in Hz)
; ============================================================================

; Octave 3
.equ C3  = 131
.equ CS3 = 139      ; C#3/Db3
.equ D3  = 147
.equ DS3 = 156      ; D#3/Eb3
.equ E3  = 165
.equ F3  = 175
.equ FS3 = 185      ; F#3/Gb3
.equ G3  = 196
.equ GS3 = 208      ; G#3/Ab3
.equ A3  = 220
.equ AS3 = 233      ; A#3/Bb3
.equ B3  = 247

; Octave 4 (Middle C octave)
.equ C4  = 262      ; Middle C
.equ CS4 = 277      ; C#4/Db4
.equ D4  = 294
.equ DS4 = 311      ; D#4/Eb4
.equ E4  = 330
.equ F4  = 349
.equ FS4 = 370      ; F#4/Gb4
.equ G4  = 392
.equ GS4 = 415      ; G#4/Ab4
.equ A4  = 440      ; Concert A
.equ AS4 = 466      ; A#4/Bb4
.equ B4  = 494

; Octave 5
.equ C5  = 523
.equ CS5 = 554      ; C#5/Db5
.equ D5  = 587
.equ DS5 = 622      ; D#5/Eb5
.equ E5  = 659
.equ F5  = 698
.equ FS5 = 740      ; F#5/Gb5
.equ G5  = 784
.equ GS5 = 831      ; G#5/Ab5
.equ A5  = 880
.equ AS5 = 932      ; A#5/Bb5
.equ B5  = 988

; Octave 6
.equ C6  = 1047
.equ CS6 = 1109     ; C#6/Db6
.equ D6  = 1175
.equ DS6 = 1245     ; D#6/Eb6
.equ E6  = 1319
.equ F6  = 1397
.equ FS6 = 1480     ; F#6/Gb6
.equ G6  = 1568

; Special frequencies
.equ REST = 0       ; Silence/rest

; ============================================================================
; NOTE DURATION DEFINITIONS (in timer ticks)
; Assumes 240 BPM and timer running at 1000 Hz (1ms ticks)
; Adjust these values based on your timer frequency and desired tempo
; ============================================================================

; Basic note durations (240 BPM = 250ms per quarter note, plus short breaks)
.equ WHOLE_NOTE     = 2000   ; Whole note (4 beats)
.equ HALF_NOTE      = 1000   ; Half note (2 beats)
.equ QUARTER_NOTE   = 225    ; Quarter note (1 beat)
.equ EIGHTH_NOTE    = 100    ; Eighth note (1/2 beat)
.equ SIXTEENTH_NOTE = 125    ; Sixteenth note (1/4 beat)
.equ THIRTYSECOND   = 63     ; Thirty-second note (1/8 beat)

; Dotted notes 
.equ DOTTED_HALF    = 1500   ; Dotted half note (3 beats)
.equ DOTTED_QUARTER = 750    ; Dotted quarter note (1.5 beats)
.equ DOTTED_EIGHTH  = 375    ; Dotted eighth note (0.75 beats)

; Triplet notes 
.equ QUARTER_TRIPLET = 333   ; Quarter note triplet
.equ EIGHTH_TRIPLET  = 167   ; Eighth note triplet
.equ SIXTEENTH_TRIPLET = 83  ; Sixteenth note triplet

; Articulation styles
.equ STACCATO_QUARTER = 150  ; Quarter note played staccato (50% of normal)
.equ STACCATO_EIGHTH  = 125  ; Eighth note played staccato
.equ LEGATO_QUARTER   = 200  ; Quarter note played legato (98% of normal)
.equ LEGATO_EIGHTH    = 245  ; Eighth note played legato

; Special durations
.equ VERY_SHORT     = 15     ; Very short accent
.equ SHORT_ACCENT   = 50    ; Short accent
.equ LONG_HOLD      = 1500   ; Long sustained note
.equ BRIEF_REST     = 100    ; Brief pause
.equ SHORT_REST     = 250    ; Short rest
.equ LONG_REST      = 500    ; Long rest

