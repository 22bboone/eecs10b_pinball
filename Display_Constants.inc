;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                            Display_Constants.inc                           ;
;                              Display Constants                             ;
;                                 Homework #3                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the assembly language definitions and constants used for
; the display functions for the pinball machine project as a part of EE/CS 10b, 
; Homework 5.
;
; Revision History:
;   5/2/2025    Benjamin Boone  Initialized needed constants
;   5/3/2025    Benjamin Boone  Added needed constants for new sensorCode 
;                                   generation
;   5/13/2025   Benjamin Boone  Repurposed old file for Homework 3
;   5/16/2025   Benjamin Boone  Updated constants for initialization file
;   5/17/2025   Benjamin Boone  Organized and updated comments
;   6/14/2025   Benjamin Boone  Added Constants for new Functions




; General Hardware Definitions
.equ    NUM_COLS            =   16      ; total number of columns of LEDs.
.equ    NUM_LED_DIGITS      =  4        ; number of digits per 7-segment display
.equ 	NUM_LEDS_IN_GRID	=  64       ; number of LEDs on grid display
.equ    ROWLENGTH           =  8        ; number of LEDs per row on grid display
.equ    NUM_DIGITS_TOTAL    =  8        ; the total number of digits


; init display function
.equ    INIT_PORT_DRIVE     =   $80		; starting value for StorePortA and 
                                            ; StorePortD

; Constants for Muxing the LEDs
.equ    COLS_OFF            =   0       ; columns off when switching columns
.equ    FIRST_MUX_INDEX     =   0       ; first column to start multiplexing.
.equ    MAX_MUX_INDEX       =   16      ; total number of columns of LEDs we 
                                            ; want to multiplex.
.equ    SWAP_PORT_TIME      =   8       ; divides number of columns of LEDs
                                            ; into those run by different ports 
                                            ; (8 each for now).

; for DisplayHex function
.equ    PLAYER_1            =   1   ; to write to Player 1 Display
.equ    PLAYER_2            =   2   ; to write to Player 2 Display
.equ    PLAYER_1_OFFSET     =   12  ; offset from top of the buffer table to get
                                        ; to the bytes that correspond to the 
                                        ; Player 1 display.
.equ    PLAYER_2_OFFSET     =   8   ; offset from top of the buffer table to get
                                        ; to the bytes that correspond to the 
                                        ; Player 2 display.

; for the DisplayASCII function
.equ    ASCII_TABLE_LENGTH  =   128  ; the length of the ASCIISegTable, used for
                                        ; error handling

; for BlinkDigits function
.equ    DIGITS_OFFSET       =   8   ; marks the start of where in curDigCol the 
                                        ; digits are stored

; for DisplayLight function
.equ    START_COUNT_NEG1    =  $FF  ; to start counting at negative 1

; for ClearDisplay function
.equ 	LEDSOFF				=  $00	; turn off the LEDs


; general masks
.equ    HIGH_MASK           =   $F0         ; keep high nibble of byte
.equ    LOW_MASK            =   $0F         ; keep low nibble of byte
.equ    MOD_8_MASK          =   0b00000111  ; Modulo 8 keeps last 3 bits. Used 
                                                ; to speed up calculations.

; The following are used in the DisplayWord Functions
; Letters used in "HIGH"
.equ    H_OFFSET    =   72      ; Offset to get the letter H in ASCIISegTable
.equ    I_OFFSET    =   73      ; Offset to get the letter I in ASCIISegTable
.equ    G_OFFSET    =   71      ; Offset to get the letter G in ASCIISegTable

; Additional Letters used in "PLAY"
.equ    P_OFFSET    =   80      ; Offset to get the letter P in ASCIISegTable
.equ    L_OFFSET    =   76      ; Offset to get the letter L in ASCIISegTable
.equ    A_OFFSET    =   65      ; Offset to get the letter A in ASCIISegTable
.equ    Y_OFFSET    =   89      ; Offset to get the letter Y in ASCIISegTable

; Additional Letters used in "BALL"
.equ    B_OFFSET    =   66      ; Offset to get the letter B in ASCIISegTable
