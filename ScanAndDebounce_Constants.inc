;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                HW 2 Constants                              ;
;                                 Homework #2                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the assembly language definitions and constants used for
; the HaveSensor, GetSensor, and ScanAndDebounce function for the pinball 
; machine project as a part of EE/CS 10b, Homework 5.
;
; Revision History:
;   5/2/2025    Benjamin Boone  Initialized needed constants, in HW 2
;   5/3/2025    Benjamin Boone  Added needed constants for new sensorCode 
;                                   generation
;   6/14/2025   Benjamin Boone  Updated Comments, made so it'd work with other
;                               files in HW5
;
;
; ------------------------------------------------------------------------------

; general constants
.equ    TRUE     =   $FF     ; constant, indicates something is "set"
.equ    FALSE    =   $00     ; variable, indicates something is not set
.equ    ZERO     =   $00     ; don't want to use FALSE for everything
.equ    ONES     =   $FF     ; all ones
.equ    ONE		 =   $01     ; just one 1

; initialization constants
; Commented Out Because Defined in Another File (Port_Timer_Init_Constants.inc)
;.equ    INDATA   =   $00     ; would mean it's all inputs for a DDR
;.equ    OUTDATA  =   $FF     ; would mean it's all outputs for a DDR

.equ    CODEMASK =   0b11100000	    ;to be used when setting sensorCode
.equ	FIRSTFIVE =  0b11111000     ;also to be used when setting sensorCode

; constants for scan (column) and row index
; each is all ones but one zero, indicating the active low row or column 
    ; currently being scanned or read
.equ    Col0     =   $FE     
.equ    Col1     =   $FD
.equ    Col2     =   $FB
.equ    Col3     =   $F7
.equ    Col4     =   $EF
.equ    Col5     =   $DF 
.equ    Col6     =   $BF 
.equ    Col7     =   $7F

; constants for rows
.equ    Row0  =   $1E     
.equ    Row1  =   $1D
.equ    Row2  =   $1B
.equ    Row3  =   $17
.equ    Row4  =   $0F 

; constants representing physical quantities (timer)
.equ    DEBOUNCE_TIME  = 20             ; about 10 milliseconds for 


; timer initializaiton constants    - commented b/c defined elsewhere (as above)
;.equ    TIMERCLK64   =   0b00000100      ; divides the clock by 64.
;.equ    TIMERCOMP    =   124             ; will be used to set the compare reg 
                                          ; for the timer to get 1 millisecond

; Port definitions
.equ	scanIndex = PORTG		;scanning the rows of the sensor array
.equ	columnReg = PINE		;receiving inputs from the sensor array columns.
