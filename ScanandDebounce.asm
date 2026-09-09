;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             ScanandDebounce.asm                            ;
;                                 Homework #5                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the functions for scanning the sensors, debouncing the 
;   sensors, and setting the appropriate flags and sesnorCode to notify other 
;   functions that a sensor is down, and which that is. 
;   The public functions included are:
;       InitButtonPorts     -   Initializes the I/O ports that are used in the 
;                               scan and debounce operation.
;       InitScanAndDebounceVars -   Initialize variables and values relevant to  
;                                   the Event Handler
;       ScanAndDebounce     -   Scans the rows of the sensor array, checking the
;                                   columns to see if a sensor is down. If a 
;                                   sensor is down, it will set the appropriate
;                                   flag, "sensorFlag", and save the row and
;                                   column values of the downed sensor in memory
;       HaveSensor          -   have debounced sensor
;       GetSensor           -   return the sensorCode corresponding to which 
;                               sensor is pressed.
;
; Revision History:
;   5/2/2025    Benjamin Boone  Initial revision
;   5/3/2025    Benjamin Boone  Updated procedure for setting the sensorCode, 
;                                   fixed bugs in debouncing
;   6/6/2025    Benjamin Boone  Rewrote SensorCode section to get val from 1-40
;   6/12/2025   Benjamin Boone  Updated Comments
;   6/13/2025   Benjamin Boone  Added Have and Get Sensor functions to this file
;   6/14/2025   Benjamin Boone  Updated comments and organized.


.cseg

; ------------------------------------------------------------------------------
; InitButtonPorts.
;
; Description:       This procedure initializes the I/O ports for the scan and 
;                    debounce system. Sets PORT G as an output with all values 
;                    off (high) and PORT E as inputs.
;
; Operation:         The direction bits are set appropriately for the ports
;                    and all outputs are turned off (high, as PORT G is active
;                    low).
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            The I/O ports are initialized, PORTE as an input and PORT G
;                    as an output.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     May 3, 2025

InitButtonPorts:
                                        ;initialize I/O port directions
        ldi     r16, OUTDATA            ;initialize Port G to all outputs
        sts     DDRG, r16
        sts     PORTG, r16              ; and all outputs are high (off)
                                        ; use STS because we can only do outs 
                                            ; for the first 31-63 I/O locations

        ldi     r16, INDATA             ;initialize Port E to all inputs
        out     DDRE, r16
        ;rjmp   EndInitPorts

EndInitButtonPorts:                     ;done so return
        ret

; ------------------------------------------------------------------------------
; InitScanAndDebounceVars
;
; Description:       This procedure initializes the variables and values for the
;                    ports that are used in the event handler for the 1 ms 
;                    interrupt, or, the ScanAndDebounce function.
;
; Operation:         The initial values for scanIndex (PORT G), debounceCtr, and
;                    pastColumnReg are set to their appropriate beginning values.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  debounceCtr        - write only. Tracks how long sensor dwn
;                    scanIndex (PORT G) - write only. Current Row being scanned.
;                    pastColumnReg      - write only. Most recent sensor down.
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
; Registers Changed: flags, r20
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025

InitScanAndDebounceVars:
	ldi		r20, ZERO					; use r20 as a temporary register for now
    out     sreg, r20                   ; clear status register to start, also 
                                        ; turns off interrupts for initializtion.
	ldi		r20, Row0
    sts     scanIndex, r20	            ; initially looking at Row0
	ldi 	r20, DEBOUNCE_TIME			; 
    sts     debounceCtr, r20		    ; start at 10 ms
	ldi		r20, ONES
    sts     pastColumnReg, r20          ; start with no buttons pressed

	ldi 	r20, ZERO	
    sts     colCode, r20           	    ; clear sensorFlag and sensorCode
	sts 	rowCode, r20
    sts     sensorFlag, r20				; Zero is the same as False, this faster.   

EndInitScanAndDebounceVars:
    ret

; ==============================================================================
;
; ScanAndDebounce
;
; Description:       This function lives within the Event Handler Timmer 0 
;                    interrupt. This function is called after interrupts have 
;                    been disabled, and at the end of the Event Handler 
;                    interrupts are re-enabled. It receives an input from the 
;                    Parallel I/O in the form of an 8-bit register named 
;                    columnReg. It checks for a new sensor being activated if 
;                    none is currently activated or debounces the currently 
;                    activated sensor. Once a sensor has been debounced it sets 
;                    a shared flag "sensorFlag" and stores the corresponding 
;                    code for the debounced sensor in the shared variable 
;                    "sensorCode".
;
; Operation:         Checks if the current columnReg is FF, indicating that no 
;                    sensors are pressed. If so, it resets the debounce counter, 
;                    increments scan, and resets pastColumnReg, all to scan the 
;                    next row of sensors on the next interrupt. If a sensor is 
;                    pressed, it then checks whether the current columnReg (PORT
;                    E) is the same as the pastColumnReg (the previously pressed
;                    button), and if so, it calls the debounce function 
;                    since debouncing is currently taking place. When debouncing
;                    reaches zero (lasted the full 10 ms), it will set the 
;                    sensorFlag and sensorCode in memory. 
;                    If there is a sensor pressed but it's not the same as the 
;                    past sensor (pastColumnReg), meaning a new button has been 
;                    pressed, it resets the debounce counter, sets the 
;                    pastColumnReg to the current columnReg and calls the 
;                    debounce function to start debouncing this sensor.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  scanIndex - write only.
;                    debounceCtr - read and write.
;                    pastColumnReg - read and write.
;
; Input:             Parallel I/O PORT E Input (8 bit register reflecting the 
;                    values of the columns of the sensor array) as "columnReg".
; Output:            Parallel I/O PORT G output (5 bits reflecting the values of
;                    the sensor array) as "scanIndex".
;
; Error Handling:    If the row being scanned (scanIndex) is not a valid row, 
;                    it is set to the first row. If the debounceCtr goes below
;                    zero, it is held at -1 (to stop any 'false' button presses).
; Limitations:       Is written under the assumption that only one button can be 
;                    pressed down at a time (reasonable for )
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, r0, r16, r17, r18, r19, r20, r21
; Stack Depth:       7 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 6, 2025
;
;


ScanAndDebounce:

SaveStuff:              ; push sreg and all register values that are changed
	in 		r0, sreg
	push	r0
	push	r16
	push	r17
	push	r18
	push	r19
	push	r20
	push 	r21

CheckAndScan:
    in      r17, columnReg          ; bring in current and past sensor columns
	lds		r20, pastColumnReg
	cpi     r17, ONES               ; check if any sensors are pressed
	breq	ScanNextRowAndReset		; No? Reset the debouncer and pastColumnReg 
                                    ;   and Check the next row...
                                    ; else:
    cp      r17, r20		        ; check whether same button is still pressed
    breq    Debounce                ; and go to keep debouncing that sensor
                                    ; else:
    rjmp    OtherSensorDn           ; ome other sensor is pressed, go start 
                                    ; debouncing it

ScanNextRowAndReset:

                ; after resetting:
			    ; the end goal of this part is to change the row we are 
                ; scanning. There are five possible rows to scan. If one of the 
                ; low 4 rows are currently being scanned, just invert, add to 
                ; itself, and invert again to "increment" the position of the 
                ; unset bit. If the the 5th row is being scanned, need to get 
                ; back to the first - just use a conditional

	ldi		r20, DEBOUNCE_TIME
    sts     debounceCtr, r20	    ; reset the debouncer counter
	ldi		r20, ONES
    sts     pastColumnReg, r20      ; reset the pastColumnReg

CheckRow:
    lds     r18, scanIndex          ; bring the row to register space
    cpi     r18, Row4               ; if scanIndex <= the "final row"           
    brlo    SetToFirstRow           ; (meaning it's too far left or none)
	breq	SetToFirstRow			; branch to set the row to the first row.
    ;branch if higher    IncRow     ; else, increment the row being scanned.                          
                           
IncRow:                             
            ; overall: move the "0" among all the "1"s left one space.

    com     r18                     ; do a not of the scan index to increment.
    add     r18, r18                ; this will move the "set" bit one higher     
    com     r18                     ; then reset to active low
    sts     scanIndex, r18          ; save the new scanIndex
    rjmp    EndScanAndDebounce      ; 

SetToFirstRow:                      ; resets scanIndex to 0b11110
	ldi		r20, Row0	
    sts     scanIndex, r20	        ; reset to the first row
    rjmp    EndScanAndDebounce      ; then we're done.

OtherSensorDn:                      ; another sensor is down, update past
                                    ; column, start debouncing again.
	ldi		r20, DEBOUNCE_TIME
    sts     debounceCtr, r20		; reset the new debounce
    sts     pastColumnReg, r17      ; set the past Column to the currently
                                        ; pressed button index column
    ;rjmp   Debounce                ; start debouncing this sensor now.

Debounce:
    lds     r19, debounceCtr        ; bring debounceCtr into register space
    dec     r19                     ; decrement
	sts		debounceCtr, r19		; make sure to save it!
    cpi     r19, ONES               ; if debounce counter is:
    brlt    SetCtrNegOne            ; <0, then set debounce counter to -1
    breq    SetSensFlagAndCode      ; 0, then sensor is debounced 
    rjmp    EndScanAndDebounce      ; otherwise, we're done.

SetCtrNegOne:
	ldi		r20, ONES
    sts     debounceCtr, r20        ; set to negative one. This will ensure that 
    rjmp    EndScanAndDebounce      ; the same sensor is not debounced multiple 
                                    ; times for the same press.

SetSensFlagAndCode:                 ; set sensor Flag because timer is fully 
	ldi		r20, TRUE                   ; debounced.
    sts     sensorFlag, r20            
    ;rjmp    SetSensCode

SetSensCode:
                                ; send out the rows and col of the sensor
    ;in     r17, columnReg		; r17 already is columnReg
	sts     colCode, r17         ; store in memory
    lds     r18, scanIndex      ; and store the rows too 
    sts     rowCode, r18        ; and calculate the rest in GetSensor

EndScanAndDebounce:

Restore:                ; restore all pushed registers and sreg
	pop		r21
	pop		r20
	pop		r19
	pop		r18
	pop		r17
	pop		r16
	pop		r0	
	out		sreg, r0
	
	ret                ; done debouncing the sensors. return to event handler


; ==============================================================================
;
; HaveSensor
;
; Description:       Return whether or not have a debounced Sensor switch 
;                    available. This is later used to ensure that the code never 
;                    gets stuck on the blocking component of the GetSensor 
;                    function.
;
; Operation:         The flag indicating there is a debounced Sensor pressed 
;                    (sensorFlag) is checked. The zero flag is set (no debounced 
;                    sensor available) or reset (debounced sensor available) 
;                    based on the outcome of this check. 
;
; Arguments:         None.
; Return Value:      Zero Flag - set if have a sensor pressed, reset if not.
;
; Local Variables:   None.
; Shared Variables:  sensorFlag - read only.
;
; Input:             None.
; Output:            None.
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
; Last Modified:     May 2, 2025

HaveSensor:
    lds     r16, sensorFlag     ; Bring sensorFlag to a register to compare
    cpi     r16, FALSE          ; Set Zero Flag if sensorFlag is FALSE

EndHaveSensor:                  ; return
    ret     

; ==============================================================================
;
; GetSensor
;
; Description:       If the zero flag is set, indicating that there is an 
;                    available debounced sensor activation, this procedure 
;                    returns the sensor code corresponding to the debounced 
;                    sensor in R16. This is a blocking function which will not 
;                    return until HaveSensor resets the Zero flag. Resets the 
;                    flag "sensorFlag", which is critical code and done with 
;                    interrupts off.
;                                                                              
; Operation:         This procedure continuously calls HaveSensor until it 
;                    resets the Zero Flag. This indicates a sensor is available.
;                    After obtaining the Row and Column of the sensor that was 
;                    down (passed in shared variable), it will compute a 
;                    sensorCode for that sensor, and return it in R16. This code
;                    is computed to give each button a value from 0-39 based on 
;                    their position on the board, and a diagram shows that below.
;
; Arguments:         None.
; Return Value:      Returns the variable sensorCode, indicating which sensor is
;                    activated, to R16.
;
; Local Variables:   None.
; Shared Variables:  sensorFlag - write only (reset to FALSE).
;                    RowCode    - read only. The Row the depressed sensor is in.
;                    ColCode    - read only. The Column the hit sensor is in.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, r16, r0
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025
;
;
;               sensorCode is set according to the folowing table:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                       ;
;                                       ;
;              ;;;;;;;;;;               ;
;              JTAG CABLE               ;
;              ;;;;;;;;;;               ;
;                                       ;
;                                       ;
;           ;;;LED DISPLAY;;;           ;
;                                       ;
;                                       ;
;           ;;;LED DISPLAY;;;           ;
;                                       ;
;                                       ;
;   S   S   S                   S   S   ;   Column 0    -   PORT E = 0b11111110
;                                       ;   
;   S   S   S                   S   S   ;   Column 1    -   PORT E = 0b11111101
;                                       ;
;   S   S   S                   S   S   ;   Column 2    -   PORT E = 0b11111011
;                                       ;   
;   S   S   S                   S   S   ;   Column 3    -   PORT E = 0b11110111
;                -----------            ;
;   S   S   S   |           |   S   S   ;   Column 4    -   PORT E = 0b11101111
;               |    LED    |           ;   
;   S   S   S   |  DISPLAY  |   S   S   ;   Column 5    -   PORT E = 0b11011111
;               |           |           ;
;   S   S   S    ----------     S   S   ;   Column 6    -   PORT E = 0b10111111
;                                       ;   
;   S   S   S                   S   S   ;   Column 7    -   PORT E = 0b01111111
;   |   \    \                  |   |   ;
;;;;|;;;;\;;;;\;;;;;;;;;;;;;;;;;|;;;\;;;;
;   |     \    \                |    \   
;  Row   Row   Row            Row   Row 
;   0     1     2              3     4   
;
; Table of SensorCode to which sensor is pressed:
;   
;           |   Row 0   |   Row 1   |   Row 2   |   Row 3   |   Row 4
; -----------------------------------------------------------------------------    
; Column 0  |   $00     |   $08     |   $10     |   $18     |   $20
;           |           |           |           |           |           
; Column 1  |   $01     |   $09     |   $11     |   $19     |   $21
;           |           |           |           |           |
; Column 2  |   $02     |   $0A     |   $12     |   $1A     |   $22
;           |           |           |           |           |
; Column 3  |   $03     |   $0B     |   $13     |   $1B     |   $23
;           |           |           |           |           |
; Column 4  |   $04     |   $0C     |   $14     |   $1C     |   $24
;           |           |           |           |           |
; Column 5  |   $05     |   $0D     |   $15     |   $1D     |   $25
;           |           |           |           |           |
; Column 6  |   $06     |   $0E     |   $16     |   $1E     |   $26
;           |           |           |           |           |
; Column 7  |   $07     |   $0F     |   $17     |   $1F     |   $27
;           |           |           |           |           |
;

GetSensor:    

WhileLoopStart:
    rcall   HaveSensor          ; first call HaveSensor
    brne    SetSensorCode       ; then leave the while loop
    rjmp    WhileLoopStart      ; else keep checking

SetSensorCode:
                                ; will give a number from 0 to 39 according 
                                ;   to sensor row and column
    lds     r16, colCode        ; get col
    lds     r18, rowCode        ; get row
	ldi  	r20, 1              ; use as temp value to check value of scanIndex
	ldi  	r21, 0              ; this will be used to count - used to set code

ColCodeWhile:			    ; while r20 != 0:
	and 	r20, r16			; compute condition, will be zero if low bit in 
                                    ; columnReg is same as the "1" in r20
	breq	ColWhileEnd			; bit is in right location, compute code
	;brne	SCWhileBody			; go to move the "1" left and increment the index
	
ColWhileBody:
    add 	r20, r20            ; move the high bit one left  
    inc 	r21                 ; update index of which column the sensor is in
	rjmp	ColCodeWhile

ColWhileEnd:                    ; means r20 is not zero, so loop finishes, r21 
                                    ; holds numerical value of the column of the 
                                    ; pressed sensor (num from 0 to 7)
                                ; Need to multiply by scanIndex times
    ldi  	r20, 1              ; initiate conditional check / count
    ldi     r17, ROWLENGTH      ; add the row length each time to up it a set
	mov 	r16, r21	        ; copy over to use to add to itself

RowCodeWhile:       
    and     r20, r18            ; if  both have the same index then we are done
    breq    RowWhileEnd     
    
    add     r16, r17            ;else we will multiply (also just adding itself)
    add     r20, r20            ; and then we'll want to go do it again, but 
    rjmp    RowCodeWhile            ; after moving the 1 in r20

RowWhileEnd:
    ; code now already in r16, so just end

WhileLoopEnd:                   ; means sensorCode is not empty, so reset flag
    in      r0, sreg            ; critical code, save and clear interrupts
    cli
	ldi		r20, ZERO
	sts		sensorFlag, r20		; reset sensorFlag
    out     sreg, r0
    ret                         ; and return




; ##############################################################################
; data portion
.dseg

; shared variables in memory
sensorFlag:      .byte   1      ; flag indicating a sensor is available
colCode:         .byte   1      ; The column the depressed sensor is in
rowCode:         .byte   1      ; The row the depressed sensor is in

; event handler variables
debounceCtr:     .byte   1      ; Counts how long a sensor has been down
pastColumnReg:   .byte   1      ; Stores what sensor was down last 
