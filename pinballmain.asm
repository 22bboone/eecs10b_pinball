;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               PinballMain.asm                              ;
;                                 Homework #5                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program implements the entirety of the pinball machine
;                   as a part of Homework 5 of EE/CS 10b. It calls the 
;                   appropriate intialization functions, initializes the stack,
;                   calls the Main Game Loop, and connects other necessary files
;                   to this one.
;
; Input:            User presses sensors on the pinball machine with their hands
;                   or with the ball on the main playing field.
; Output:           Scores and other messages are displayed on 2 4-digit 7 
;                   segment LED displays, LED's are flashed, and sound is played
;                   through as speaker.
;
; User Interface:   The user presses/activates sensors which in turn play noises
;                   and display lights according to how they are doing in the 
;                   game.
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
; 
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    5/17/19  Glen George               initial revision
;    4/30/25  Glen George               changed function calls to match the
;                                          pinball machine controller board
;    4/30/25  Glen George               updated comments
;    5/02/25  Benjamin Boone            Acquired file from website for HW 2,
;                                          matched with my files (.includes and
;                                          vector table update)
;    6/12/25  Benjamin Boone            Initial Revision
;    6/13/25  Benjamin Boone            Connected files
;    6/14/25  Benjamin Boone            Updated comments




;set the device
;.device  ATMEGA64




;get the definitions for the device
.include  "m64def.inc"

;include all the .inc files since all .asm files are needed here (no linker)
.include  "Port_Timer_Init_Constants.inc"
.include  "ScanAndDebounce_Constants.inc"
.include  "Display_Constants.inc"
.include  "Sound_Constants.inc"
.include  "EEROM_Constants.inc"
.include  "GameConstants.inc"



.cseg




;setup the vector area

.org    $0000

        JMP     StartGame               ;reset vector
        JMP     PC                      ;external interrupt 0
        JMP     PC                      ;external interrupt 1
        JMP     PC                      ;external interrupt 2
        JMP     PC                      ;external interrupt 3
        JMP     PC                      ;external interrupt 4
        JMP     PC                      ;external interrupt 5
        JMP     PC                      ;external interrupt 6
        JMP     PC                      ;external interrupt 7
        JMP     PC                      ;timer 2 compare match
        JMP     PC                      ;timer 2 overflow
        JMP     PC                      ;timer 1 capture
        JMP     PC                      ;timer 1 compare match A
        JMP     PC                      ;timer 1 compare match B
        JMP     PC                      ;timer 1 overflow
        JMP     Timer0CompareMatch      ;timer 0 compare match
        JMP     PC                      ;timer 0 overflow               
        JMP     PC                      ;SPI transfer complete
        JMP     PC                      ;UART 0 Rx complete
        JMP     PC                      ;UART 0 Tx empty
        JMP     PC                      ;UART 0 Tx complete
        JMP     PC                      ;ADC conversion complete
        JMP     PC                      ;EEPROM ready
        JMP     PC                      ;analog comparator
        JMP     PC                      ;timer 1 compare match C
        JMP     PC                      ;timer 3 capture
        JMP     PC                      ;timer 3 compar e match A
        JMP     PC                      ;timer 3 compare match B
        JMP     PC                      ;timer 3 compare match C
        JMP     PC                      ;timer 3 overflow
        JMP     PC                      ;UART 1 Rx complete
        JMP     PC                      ;UART 1 Tx empty
        JMP     PC                      ;UART 1 Tx complete
        JMP     PC                      ;Two-wire serial interface
        JMP     PC                      ;store program memory ready




; start of the actual program



StartGame:                                  ;start the CPU after a reset
        LDI     R16, LOW(TopOfStack)        ;initialize the stack pointer
        OUT     SPL, R16
        LDI     R16, HIGH(TopOfStack)
        OUT     SPH, R16

        ;call any initialization functions
        RCALL	PowerOnInit          ; this init function calls all others

        SEI                          ; set interrupts

        RCALL   GameLoop             ; start the game
        RJMP    StartGame            ; shouldn't return, but if it does, restart


; ##############################################################################

.dseg


; the stack - 128 bytes
                .byte   127
TopOfStack:     .byte   1               ;top of the stack



; since don't have a linker, include all the .asm files 
.include "Timer_Init.asm"
.include "Timer0CompareMatch_EventHandler.asm"
.include "ScanandDebounce.asm"
.include "Display_Functions.asm"
.include "segtable.asm"
.include "Sound.asm"
.include "EEROM.asm"
.include "GameFunctions.asm"
.include "helperFunctions.asm"
