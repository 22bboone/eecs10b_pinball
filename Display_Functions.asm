;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                            Display_Functions.asm                           ;
;                            LED Display Functions                           ;
;                                 Homework #5                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the functions for turning an LED on the 8x8 grid of LEDs 
;   on or off, displaying hex digits on the Player 1 and Player 2 4-digit, 
;   7-segment displays, clearing the displays, and Muxing the LEDs.
;   The public functions included are:
;       InitDisplayPorts    -   Initializes ports A, C, D, used by the display
;       InitDisplay         -   Initializes the display, turning off all LEDs 
;                               and setting up variables for Muxing correctly.
;       MuxLEDs             -   multiplexes the LED display (both the Player 1 
;                               and 2 4-digit 7-segment displays, and the 8x8 
;                               grid of LEDs) under interrupt control.
;       ClearDisplay        -   Clears the display, turns off ALL LEDs.
;       DisplayHex          -   Outputs a 16-bit number in hexadecimal to a 
;                               a choice of one of the 7-segment LED displays.
;       DisplayLight        -   Sets a chosen LED on the 8x8 display to a 
;                               chosen state (on or off).
;       DisplayASCII        -   Outputs a single ASCII character to a chosen 
;                               digit in a chosen 7-segment LED Displays
;       DisplayHIGH     -   Writes the word "HIGH" to the player 1 display
;       DisplayPLAY     -   Writes the word "PLAY" to the player 1 display
;       DisplayBALL     -   Writes teh word "BALL" to the player 1 display
;       DisplayHighScore    -   Writes "HIGH" to p1 display, high score to P2
;       DisplayPlayGame     -   Writes "PLAY" to p1 display, games left to P2
;       BlinkDigits         -   Blinks the two 4-digit displays a number of 
;                               times at 1/4 second interval
;       FlashQuarterSecond  -   Turns on a passed light for 1/4 second. Then off
;       CheckFlashingLight  -   Checks how long a flashed light has been flashed
;                               via the EventHandler, turns off after duration.
;       CheckBlinkingDigits -   Checks how long and how many times the digits
;                               have been blinking via the Timer0 EventHandler.
;                               Controls continued blinking, or stops it.
;
; Revision History:
;   5/2/2025    Benjamin Boone  Initial revision
;   5/3/2025    Benjamin Boone  Updated procedure for setting the sensorCode, 
;                                   fixed bugs in debouncing
;   5/16/2025   Benjamin Boone  Added all functions (initial revisions) for HW3,
;                                   or Displaying the LEDs
;   5/17/2025   Benjamin Boone  Fixed bugs, updated comments.
;   6/12/2025   Benjamin Boone  Added the DisplayASCII function, fixed labels
;   6/14/2025   Benjamin Boone  Combined with other display functions, updated
;                               comments.



.cseg
; ------------------------------------------------------------------------------
; InitDisplayPorts
;
; Description:       This procedure initializes the I/O ports for the display. 
;                    Sets Ports A, C, and D to output ports and clears their 
;                    output.
;
; Operation:         The directions of each of Ports A, C, and D are set high 
;                    (outputs) and their initial values are set to low (board 
;                    will initialize with all LEDs off).
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
; Registers Changed: flags, R16
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025 (comments)

InitDisplayPorts:
                                        ; initialize I/O port directions
        ldi     r16, OUTDATA            ; initialize Ports A, C, and D to be 
        out     DDRA, r16               ; all outputs
        out     DDRC, r16
        out     DDRD, r16                              
        ldi     r16, INIT_PORTS_OFF     ; and set all outputs off (low)
        out     PORTA, r16              ; so all LEDs off when initialized
        out     PORTC, r16
        out     PORTD, r16  
        ;rjmp   EndInitPorts

EndInitDisplayPorts:                     ;done so return
        ret

; ==============================================================================
;
; InitDisplay
;
; Description:       This function initializes the shared variable buffer 
;                    (curDigCol) and the variables used in the MuxLEDs function. 
;                    This is the initialization routine for MuxLEDs and the 
;                    display. Also initializes all shared variables for blinking
;                    or flashing the display.
;
; Operation:         Clears the display by calling the clearDisplay function, 
;                    then initializes the first column to set in the mux, as  
;                    well as the first digit and column that Port A and D will 
;                    display when lit. Also Loops through the temporary digit 
;                    buffer and clears it (used for blinking).
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  Write only to the following:
;                    MuxIndex   - Initialized. Indicates column currently muxing.
;                    curDigCol  - Cleared. This is the display buffer.
;                    StorePortA - Initialized. Keeps track of muxing in 8x8 grid.
;                    StorePortD - Initialized. Keeps track of muxing in 4-digit
;                                 displays.
;                    blink_active       - write only. Flag for blinking digits
;                    blink_num_ctr      - write only. How many times to blink
;                    blink_counter_H    - write only. Counter for blinking
;                    blink_counter_L    - write only. Coutner for blinking
;                    flashed_active     - write only. Flag for flashing light
;                    flash_counter_H    - write only. Counter for flashing LED
;                    flash_counter_L    - write only. Counter for flashing LED
;                    flashed_light      - write only. Store which light flashing
;                    tempDigBuf         - write only. Buffer for blinking digits
;
; Global Variables:  None.
;
; Input:             None.
; Output:            None. Keeps all lights off.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R23, R16, R17
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025

InitDisplay:
	rcall   ClearDisplay            ; clear the buffer and all LEDs

    ldi     r23, FIRST_MUX_INDEX    ; set MuxIndex to it's starting value
    sts     MuxIndex, r23
    ldi     r23, INIT_PORT_DRIVE    ; set the Port drives to their starting vals
    sts     StorePortA, r23         ; Normally, these variables will hold one 
    sts     StorePortD, r23         ; active high value that is shifted once 
                                        ; in the MuxLEDs function

InitBlinkAndFlash:
    clr     r16                     ; reset or clear all these variables, so 
    ldi     r17, FALSE                  ; nothing is blinking or flashing to 
    sts 	blink_active, r17           ; start.
	sts 	blink_num_ctr, r16
	sts 	blink_counter_H, r16
	sts 	blink_counter_L, r16
    sts     flash_active, r17     	; flags are false
    sts     flash_counter_H, r16
    sts     flash_counter_L, r16
    sts     flashed_light, r16

ClearTempDigBuf:
    ldi     YL, LOW(tempDigBuf)     ; set Y register to top of fake buffer to 
    ldi     YH, HIGH(tempDigBuf)    ;  increment through each byte in the buffer
    ldi     r19, 0                  ; start increment with no offset
    ldi     r20, LEDSOFF            ; used to clear each byte in buffer

ClearTempDigBufLoop:
    cpi     r19, NUM_DIGITS_TOTAL   ; make sure to clear each digit
    breq    EndClearDisplay         ; if cleared all NUM_DIGITS_TOTAL then we're 
    st      Y+, r20                     ; done
    inc     r19                     ; number of rows cleared
    rjmp    ClearTempDigBufLoop        

EndInitDisplay:
    ret 



; ==============================================================================
;
; MuxLEDs
;
; Description:       This procedure multiplexes the LED display under interrupt 
;                    control.  It is meant to be called at a regular interval of 
;                    about 1 ms. It multiplexes the display of both the Player 1 
;                    and 2 4-digit 7-segment displays, and the 8x8 grid of LEDs.
;
; Operation:         This procedure outputs the LEDs to turn on (from the 
;                    curDigCol buffer) for each row to the next column or digit 
;                    of the 8x8 and 4-digit displays each time each time it is 
;                    called.  To do this it outputs the digits that should have 
;                    the current segment on.  The column to output is determined 
;                    by MuxIndex and swapPortTime which are also updated by this 
;                    function.  One column is output each time the function is 
;                    called. To do this, the function first clears all columns, 
;                    then turns on the rows/segments to the appropriate index 
;                    that is currently turned on, then turns on the correct sink 
;                    port (A or D) based on MuxIndex, and finally increments 
;                    MuxIndex be used the next time called.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curDigCol  - read only. This is the display buffer.
;                    MuxIndex   - read and write. Indicates column currently 
;                                 muxing.
;                    StorePortA - read and write. Keeps track of muxing in 8x8 
;                                 grid.
;                    StorePortD - read and write. Keeps track of muxing in the 
;                                 4-digit, 7-segment displays.
;
; Input:             None.
; Output:            The next digit or column LEDs are lit using the parallel 
;                    I/O Ports D and A outputs, respectively. Port C is also 
;                    written to the rows (using the buffer variable).
;
; Error Handling:    None.
; Limitations:       None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, Z, R16, R17, R18, 
; Stack Depth:       0 bytes.
;
; Author:            Benjamin Boone
; Last Modified:     May 17, 2025
;

MuxLEDs:

TurnOffCurrentCols:
    ldi     r16, COLS_OFF           ; disables columns/digits so don't 
    out     PORTA, r16                  ; erroneously have the wrong lights on 
    out     PORTD, r16                  ; the digit or column while switching.

GetCurrentRows:
    ldi     ZL, LOW(curDigCol)      ; load Z with the buffer address and 
    ldi     ZH, HIGH(curDigCol)         ; offset by current column we're muxing.
    lds     r16, MuxIndex           
    ldi     r17, 0
    add     ZL, r16
    adc     ZH, r17

    ld      r18, Z                  ; load the current lights for the row and 
    out     PORTC, r18                  ; ouput to drive LEDs

ChooseWhichDisplay:                 ; determines whether we are currently muxing
                                        ; a column on the 8x8 display or a digit
                                        ; in the 4-digit 7-segment displays 
                                        ; based on value of MuxIndex.

   ;lds     r16, MuxIndex           ; if MuxIndex is greater than the length of 
    cpi     r16, SWAP_PORT_TIME         ; the grid of LEDs (8), then we're 
    brge    MuxDisplayDigits            ; currently muxing the digits, otherwise
   ;brlo    MuxDisplayGrid              ; we're currently muxing the LED grid.

MuxDisplayGrid:
    lds     r17, StorePortA         ; PORTA is the output to mux the LED grid. 
    bst     r17, 7                  ; ROL without Carry to change columns
    lsl     r17
    bld     r17, 0  
    out     PORTA, r17              ; output to LED grid via PortA
	sts 	StorePortA, r17			; save current column
    rjmp    IncrementMuxIndex

MuxDisplayDigits:
    lds     r17, StorePortD         ; PORTD is the output to mux the digits
    bst     r17, 7                  ; ROL without Carry to change columns
    lsl     r17
    bld     r17, 0  
    out     PORTD, r17              ; output to 4-digit Displays via PortD
	sts 	StorePortD, r17			; save current column
    ;rjmp   IncrementMuxIndex
 
IncrementMuxIndex:                  
   ;lds     r16, MuxIndex
    inc     r16                     ; increment MuxIndex to mux the next column
    cpi     r16, MAX_MUX_INDEX          ; on the next call
    brge    ResetMuxIndex           ; or reset if MuxIndex has reached it's max.
    rjmp    StoreMuxIndex

ResetMuxIndex:
    ldi     r16, FIRST_MUX_INDEX    ; reset MuxIndex if it's reached the final 
    ;rjmp   StoreMuxIndex               ; column.

StoreMuxIndex:
    sts     MuxIndex, r16           ; Save which column we will mux on next call
    ;rjmp   EndMuxLEDs          

EndMuxLEDs:                         ; done so return
    ret 
    
; ==============================================================================
; 
; ClearDisplay
;
; Description:       The function clears the display. After it is called all 
;                    LEDs will be off.
;
; Operation:         Resets outputs in ports A and D to zero. These correspond 
;                    to the sink lines for the 8x8 LED display and the two 
;                    4-digit 7-segment displays.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Input:             None.
; Output:            Turns off all LEDs, both the 8x8 display and the two 
;                    4-digit 7-segment displays.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, Y (YL | YH), R19, R20
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     May 17, 2025

ClearDisplay:
    ldi     YL, LOW(curDigCol)      ; set Y register to top of buffer to 
    ldi     YH, HIGH(curDigCol)     ;   increment through each byte in the buffer
    ldi     r19, 0                  ; start increment with no offset
    ldi     r20, LEDSOFF            ; used to clear each byte in buffer

ClearDisplayLoop:
    cpi     r19, NUM_COLS           ; make sure to clear each column
    breq    EndClearDisplay         ; if cleared all NUM_COLS then we're done
    st      Y+, r20                 ; clear this line / byte in the buffer
    inc     r19                     ; number of rows cleared
    rjmp    ClearDisplayLoop        

EndClearDisplay:            
    ret                             ; done so return


; ==============================================================================
;
; DisplayHex
;
; Description:       Outputs the number n to the 7-segment LED display for 
;                    player p in hexadecimal.
;
; Operation:         The function is passed a 16-bit unsigned value to output 
;                    (n) in hexadecimal (at most 4 digits) to the 7-segment LED 
;                    display for the passed player number (p). The number (n)
;                    is passed in R17|R16 by value. The player number (p) is 
;                    either 1 or 2 and is passed by value in R18. The function 
;                    gets each of the four nibbles in (n), and for each it gets 
;                    the appropriate segment display pattern from hexTable. Then 
;                    it sets the appropriate values in the curDigCol variable 
;                    (buffer) corresponding to which digit on the display should 
;                    be written for that nibble.
;
; Arguments:         n   -  a 16 bit (2 byte) hex value to output to the 
;                           7-segment LED display corresponding to the value 
;                           player. Passed in R17|R16.
;                    p   -  a boolean value corresponding to the top (Player 1, 
;                           p == 1) and bottom (Player 2, p == 2) 7-segment LED 
;                           displays. Passed in R18.
; Return Value:      None.
;
; Local Variables:   R19        -  read and write. Temporarily store the value 
;                                  of n.
;                    R20        -  read and write. Temporarily stores a segment 
;                                  pattern for the hex digit to display.
; Shared Variables:  curDigCol  -  write only. This is the display Buffer.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If the value passed in for p is not 1 or 2, this function              
;                    does nothing.
;
; Algorithms:        None.
; Data Structures:   Uses the hexTable lookup table.
;
; Registers Changed: flags, X (XH, XL), R16, R17, R19, R20, R21, R22, R23, R24
;                    Z (ZL | ZH), 
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

DisplayHex:
    cpi     r18, PLAYER_1       ; check which player display was passed in and
    breq    SetXRegPlayer1      ; go to set Z register appropriately
    cpi     r18, PLAYER_2
    breq    SetXRegPlayer2
    rjmp    EndDisplayHex       ; Error Handling: if invalid player number input
                                    ; do nothing.

SetXRegPlayer1:
    ldi     XL, LOW(curDigCol)      ; these next several lines is just getting 
    ldi     XH, HIGH(curDigCol)     ; the buffer address into X and then adding
    ldi     r22, 0                      ; the offset 
    ldi     r23, PLAYER_1_OFFSET    ; the offset of X to only write the bytes
    add     XL, r23                     ; corresponding to the Player 1 display.
    adc     XH, r22                     

    ldi     r24, 0                  ; initialize loop counter
    rjmp    DisplayHexLoop

SetXRegPlayer2:
    ldi     XL, LOW(curDigCol)      ; these next several lines is just getting 
    ldi     XH, HIGH(curDigCol)     ; the buffer address into X and then adding
    ldi     r22, 0                      ; the offset.
    ldi     r23, PLAYER_2_OFFSET    ; the offset of X to write only to the bytes
    add     XL, r23                     ; corresponding to the Player 2 display.
    adc     XH, r22

    ldi     r24, 0                  ; initialize loop counter    
    rjmp    DisplayHexLoop          


DisplayHexLoop:
    cpi     r24, NUM_LED_DIGITS     ; Check whether we've looped through each 
    breq    EndDisplayHex               ; digit in the display. If so, finish.

    mov     r19, r16                ; Get the next nibble to display as a digit
    andi    r19, LOW_MASK               ; (will shift so always in low 4)

    ldi     ZL, LOW(2*DigitSegTable)    ; Use a lookup table to get the segment       
    ldi     ZH, HIGH(2*DigitSegTable)   ; pattern corresponding to the value of
    add     ZL, r19                     ; this nibble/digit
   ;ldi     r22, 0                  ; already zero
    adc     ZH, r22                     
    lpm     r20, Z                  ; load the segment pattern into the Display
    st      X+, r20                     ; Buffer, and inc X (move to next digit)

    swap    r17                     ; shift R17|R16 right by four bits, such 
    swap    r16                         ; that the nibble for the next digit is
    ldi     r21, HIGH_MASK              ; in the low 4 bits of R16
    and     r21, r17            
    andi    r16, LOW_MASK      
    or      r16, r21            
                                    
    inc     r24                     ; count number of times we've completed the 
    rjmp    DisplayHexLoop              ; loop

EndDisplayHex:
    ret                             ; done so return



; ==============================================================================
;
; DisplayLight
;
; Description:       Sets the light corresponding to l to the passed 
;                    state, s, with TRUE for on and FALSE for off. This is 
;                    assuming that the top left of the LED matrix is 1 and 
;                    bottom right is 64.                                        
;
; Operation:         The function is passed an 8-bit light or actuator number (l) 
;                    in R16 indicating the pinball machine light or actuator to 
;                    turn on or off. The new state of the light or actuator (s) 
;                    is passed in R17. The corresponding pinball machine light 
;                    or actuator is turned on if the passed state is TRUE 
;                    (non-zero) and turned off if the passed state is FALSE 
;                    (zero). To find the correct column for (l), we 
;                    subtract 8 from its value (but in a temporary register, R18) 
;                    until we get to less than zero, counting how long it takes. 
;                    To get which row it is in, we mod 8, and rotate a single 
;                    high bit to the right that number of times (then ANDed or
;                    ORed with current buffer to set or clear the bit).
;
; Arguments:         s       -  a boolean value used to indicate whether to turn 
;                               on (if state != FALSE) or turn off (if state == 
;                               FALSE) the LED corresponding to the LED number (l). 
;                               Passed in R17.
;                    l       -  a number between 1 and 64 indicating which LED 
;                               should be turned on, with 1 as the top left of 
;                               the 8x8 LED matrix and 64 as the bottom right.
;                               Passed in R16.
; Return Value:      None.
;
; Local Variables:   R19     - read and write. Get offset for Display Buffer 
;                              (column of the LED to turn on or off).
;                    R18     - read and write. Temporarily store LED number (l).
;                    R20     - read and write. Get specific bit to change in 
;                              the byte of Display Buffer based on LED number (l).
; Shared Variables:  curDigCol  -   write only. This is the Display Buffer.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If l is greater than 64 or less than 1, this function does 
;                    nothing.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R18, R19, R20, R21, Z (ZL | ZH)
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     May 17, 2025

DisplayLight:

CheckLEDRange:
	cpi 	r16, NUM_LEDS_IN_GRID + 1   ; Error Handling. If given a value more 
	brge	EndDisplayLight               ; than the number of LEDs, do nothing.
   ;rjmp    GetOffset

GetOffset:
    mov     r18, r16                    ; Use a helper register to get offset. 
    ldi     r19, START_COUNT_NEG1       ; Start the offset counter at negative 1
   ;rjmp    GetOffsetLoop                   ; to account for zero indexing.

GetOffsetLoop:
    ldi     r20, 0                  ; compare LED number in helper reg against 0
    cp      r20, r18                    ; to see if we have counted the offset
    brge    GetBitIndex 
    subi    r18, ROWLENGTH          ; decrement by 8 until helper is than 0 
    inc     r19                         ; to set the offset to the correct 
    rjmp    GetOffsetLoop               ; column for for this light

GetBitIndex:
    mov     r18, r16                ; Use helper register to find the exact bit
    andi    r18, MOD_8_MASK         ; Modulo 8 to get bit index number
    ldi     r20, 1                  ; Set a single bit to shift a number of 
   ;rjmp    GetBitIndexShiftLoop        ; times of bit index

GetBitIndexShiftLoop:
    cpi     r18, 0              ; We decrement every time we shift, so done
    breq    EditBitInBuffer         ; when at zero.
    dec     r18                 ; update conditional counter
    bst     r20, 0              ; rotate right (ROR) without carry a number of 
    lsr     r20                     ; based on the LED number mod 8
    bld     r20, 7                  ; will get the bitIndex (row)
    rjmp    GetBitIndexShiftLoop

EditBitInBuffer:
    ldi     ZL, LOW(curDigCol)      ; to edit bit in buffer, set Z to top of 
    ldi     ZH, HIGH(curDigCol)     ; buffer and offset by our offset value 
    ldi     r18, 0                      ; still held in helper register
    add     ZL, r19                 
    adc     ZH, r18
    ld      r21, Z                  ; get the byte to edit from the buffer

    tst     r17                 ; check argument (state)... (zero or non-zero)
    breq    ClearBitInBuffer    ; if FALSE, go to turn off the LED
   ;brnq    SetBitInBuffer      ; else, turn on the LED
    or      r21, r20            ; set the appropriate bit, keep everything else
    rjmp    StoreInBuffer

ClearBitInBuffer:
    com     r20                 ; flip all the bits and AND so everything else 
    and     r21, r20                ; stays the same and only turns off bit 
    ;rjmp   StoreInBuffer           ; according to the index

StoreInBuffer:
	st		Z, r21              ; actually save the editted byte in the buffer
   ;rjmp 	EndDisplayLight

EndDisplayLight:
    ret                         ; done so return



; ==============================================================================
;
; DisplayASCII
;
; Description:       Outputs a single ASCII Character to a chosen digit (passed 
;                    in R19) to the 7-segment LED display for the player p 
;                    (passed in R18).
;
; Operation:         The function is passed an 8-bit unsigned value which gives
;                    an offset to the ASCIISegTable to acquire the desired ASCII
;                    character to display. This character offset is passed in 
;                    R20. The digit to display this character to on the display
;                    is passed in R19. The player number (p) is either 1 or 2 
;                    and is passed by value in R18. The function indexes into 
;                    ASCIISegTable R20 times, aqcuires the segment display 
;                    pattern, and outputs it to the given digit in the given 
;                    display by loading the segment pattern into the LED buffer 
;                    (curDigCol) at the appropriate position.
;
; Arguments:         char - an 8-bit value that is the offset from the top of 
;                           ASCIISegTable to get a given ASCII character display
;                           pattern. Passed in R20.
;                    p   -  a boolean value corresponding to the top (Player 1, 
;                           p == 1) and bottom (Player 2, p == 2) 7-segment LED 
;                           displays. Passed in R18.
;                    dig -  a value (1-4) representing the digit to write 
;                           character to on the player (p) display. Passed in 
;                           R19. 
; Return Value:      None.
;
; Local Variables:   R19        -  read and write. Temporarily store the value 
;                                  of n.
;                    R20        -  read and write. Temporarily stores a segment 
;                                  pattern for the hex digit to display.
; Shared Variables:  curDigCol  -  write only. This is the display Buffer.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If the value passed in for p is not 1 or 2, this function              
;                    does nothing. If the digit (dig) passed is not from 1-4, 
;                    the function does nothing. Additionally, if the character
;                    table offset value is larger than the length of the table,
;                    nothing happens.
;
; Algorithms:        None.
; Data Structures:   Uses the ASCIISegTable lookup table.
;
; Registers Changed: flags, X (XH, XL), R19, R20, R22, R23
;                    Z (ZL | ZH), 
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

DisplayASCII:
    ldi     r22, NUM_LED_DIGITS
    cp	  	r22, r19                ; Error Handling, make sure that the digit 
	brlo    EndDisplayASCII				; is an acceptable digit (1-4)		

    cpi     r20, ASCII_TABLE_LENGTH ; Check that the offset is within range of 
    brsh    EndDisplayASCII             ; the ASCII Table
   
    cpi     r18, PLAYER_1           ; check which player display was passed in 
    breq    SetXRegPlayer1ASCII         ; and go to set Z register appropriately
    cpi     r18, PLAYER_2
    breq    SetXRegPlayer2ASCII
    rjmp    EndDisplayASCII         ; If invalid player number input: do nothing
                                  	
																

SetXRegPlayer1ASCII:
    ldi     XL, LOW(curDigCol)      ; these next several lines is just getting 
    ldi     XH, HIGH(curDigCol)     ; the buffer address into X and then adding
    ldi     r22, 0                      ; the offset 
    ldi     r23, PLAYER_1_OFFSET    ; the offset of X to only write the bytes
    add     XL, r23                     ; corresponding to the Player 1 display.
    adc     XH, r22                     
    rjmp    SetDigitPointerX

SetXRegPlayer2ASCII:
    ldi     XL, LOW(curDigCol)      ; these next several lines is just getting 
    ldi     XH, HIGH(curDigCol)     ; the buffer address into X and then adding
    ldi     r22, 0                      ; the offset.
    ldi     r23, PLAYER_2_OFFSET    ; the offset of X to write only to the bytes
    add     XL, r23                     ; corresponding to the Player 2 display.
    adc     XH, r22

SetDigitPointerX:
	;ldi 	r22, 0					; commented because r20 already 0
	subi 	r19, 1					; -1 to make r19 between 0-3 as an offset
	add 	XL, r19					; this will set the X pointer to the 
	adc 	XH, r22						; specific digit which we want to write
	;rjmp 	DisplayASCIIBody													

DisplayASCIIBody:					

    ldi     ZL, LOW(2*ASCIISegTable)    ; Use a lookup table to get the segment       
    ldi     ZH, HIGH(2*ASCIISegTable)       ; pattern corresponding to the value
    add     ZL, r20                         ; of the desired character (table 
   ;ldi     r22, 0                          ; offset in r20)
    adc     ZH, r22                     
    lpm     r20, Z                      ; load the segment pattern into the 
    st      X, r20                          ; Display Buffer

EndDisplayASCII:
    ret                             ; done so return

; ==============================================================================
;
; DisplayHIGH 
;
; Description:       This function will write the word "HIGH" to the player 1
;                    display.
;
; Operation:         Calls DisplayASCII function four times with the appropriate
;                    arguments to select the player 1 display, each of the 4 
;                    digits with the right offsets for the letters in "HIGH". 
;                    Starts on the low bit (goes backwards through the word).
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curDigCol  - write only via DisplayASCII function. This is 
;                                 the display buffer.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            The Player 1 Display will show the word "HIGH"
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R18, R19, R20
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

DisplayHIGH:
	ldi 	r18, 1			; on player 1 display
    ldi 	r20, H_OFFSET	; show the letter "H"
    ldi 	r19, 1 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

    ldi 	r20, G_OFFSET	; show the letter "G"
    ldi 	r19, 2 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

    ldi 	r20, I_OFFSET	; show the letter "I"
    ldi 	r19, 3 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

    ldi 	r20, H_OFFSET	; show the letter "H"
    ldi 	r19, 4 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

EndDisplayHIGH:
    ret 


; ==============================================================================
;
; DisplayPLAY
;
; Description:       This function will write the word "PLAY" to the player 1
;                    display.
;
; Operation:         Calls DisplayASCII function four times with the appropriate
;                    arguments to select the player 1 display, each of the 4 
;                    digits with the right offsets for the letters in "PLAY". 
;                    Starts on the low bit (goes backwards through the word).
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curDigCol  - write only via DisplayASCII function. This is 
;                                 the display buffer.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            The Player 1 Display will show the word "PLAY"
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R18, R19, R20
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

DisplayPLAY:
    ldi 	r18, PLAYER_1   ; on player 1 display
    ldi 	r20, Y_OFFSET	; show the letter "Y"
    ldi 	r19, 1 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

    ldi 	r20, A_OFFSET	; show the letter "A"
    ldi 	r19, 2 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

    ldi 	r20, L_OFFSET	; show the letter "L"
    ldi 	r19, 3 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

    ldi 	r20, P_OFFSET	; show the letter "P"
    ldi 	r19, 4 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

EndDisplayPLAY:
    ret 
    
; ==============================================================================
;
; DisplayBALL
;
; Description:       This function will write the word "BALL" to the player 1
;                    display.
;
; Operation:         Calls DisplayASCII function four times with the appropriate
;                    arguments to select the player 1 display, each of the 4 
;                    digits with the right offsets for the letters in "BALL". 
;                    Starts on the low bit (goes backwards through the word).
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curDigCol  - write only via DisplayASCII function. This is 
;                                 the display buffer.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            The Player 1 Display will show the word "BALL"
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R18, R19, R20
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

DisplayBALL:
; 	if I like the lowecase "b" better:
    ldi 	r17, 0b10110000
    ldi 	r18, PLAYER_1
    rcall 	DisplayHex

; player 2 say "BALL"
    ldi 	r18, PLAYER_1	; on player 1 display
    ldi 	r20, L_OFFSET	; show the letter "L"
    ldi 	r19, 1 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

    ldi 	r20, L_OFFSET  	; show the letter "L"
    ldi 	r19, 2 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

    ldi 	r20, A_OFFSET	; show the letter "A"
    ldi 	r19, 3 			; in the ones digit
    rcall 	DisplayASCII 	; see if it correctly displays

;	ldi 	r20, B_OFFSET	; show the letter "B"
;	ldi 	r19, 4 			; in the ones digit
;	rcall 	DisplayASCII 	; see if it correctly displays 

EndDisplayBALL:
    ret 

; ==============================================================================
;
; DisplayHighScore
;
; Description:       This function will display the word "HIGH" on the player 1
;                    display and then display the current high score, previously
;                    read from EEROM, on the player 2 display. 
;
; Operation:         Reads the 2 byte BCD high score stored at high_score and 
;                    displays it on the player 2 display by calling the 
;                    DisplayHex Function. Then calls the DisplayHIGH function to
;                    write "HIGH" to the player 1 display.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  high_score  -  read only. The highest score yet scored
;                                   on the pinball machine.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            Displays "HIGH" and high_score to the two 4-digit displays.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, R18
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

DisplayHighScore:
    lds     r17, high_score             ; get the high value at high_score
    lds     r16, high_score + 1         ; and then the low byte
    ldi     r18, 2                      ; show on the player 2 display
    rcall   DisplayHex      
    rcall   DisplayHIGH                 ; display "HIGH" to the player 1 display
 
EndDisplayHighScore:
    ret

; ==============================================================================
;
; DisplayPlayGame
;
; Description:       This function will display the word "PLAY" on the player 1
;                    display and then display the number of games left, 
;                    previously read from EEROM, on the player 2 display. 
;
; Operation:         Reads the 2 byte BCD high score stored at games_left and 
;                    displays it on the player 2 display by calling the 
;                    DisplayHex Function. Then calls the DisplayPLAY function to
;                    write "PLAY" to the player 1 display.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  games_left  -  write only. The number of games left on the 
;                                   machine to be played.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            Displays "PLAY" and games_left to the two 4-digit displays.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, R18
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

DisplayPlayGame:
    lds     r16, games_left             ; get the number of games left
    clr     r17                             ; and  0s
    rcall   Bin2BCD                     ; convert to BCD
    mov     r16, r18                    ; and put the BCD value in the right
    mov     r17, r19                        ; spot to display
    ldi     r18, 2                      ; show on the player 2 display
    rcall   DisplayHex      
    rcall   DisplayPLAY                 ; display "PLAY" to the player 1 display
 
EndDisplayPlayGame:
    ret


; ==============================================================================
;
; BlinkDigits
;
; Description:       Blinks both the 4-digit 7 segment displays a number of 
;                    times (passed in R18). Blinks at a rate of 1/4 second.
;
; Operation:         Sets the BlinkFlag, indicating that blinking is going
;                    on. Then it will store twice the number of blinks (from 
;                    R18) in the BlinkNumCtr variable. Twice because one blink
;                    is both on and off. This is all done so that these values 
;                    can be checked in the event handler to actually blink the 
;                    display.
;
; Arguments:         R18    -   The number of times to blink the display.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  BlinkActive     - write only. Indicates the digits are 
;                                      actively being blinked.
;                    blink_counter_L  - write only. The low half of the time 
;                                       tracker for the blinking digits.
;                    blink_counter_H  - write only. The high half of the time
;                                       tracker for the blinking digits.
;                    blink_num_ctr    - write only. Keeps track of how many 
;                                       times to blink the display.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            Blinks the digits on the display a number of times for a 
;                    quarter second.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025


BlinkDigits:       
    lsl     r18                     ; multiply by two (account for on/off) 
    sts     blink_num_ctr, r18      ; first save how many times to blink

SetBlinkDigitsVariables:
    ldi     r17, TRUE                   ; to turn the light on first turn on            
    in      r0, sreg                    ; save SREG (critical code, these vars
    cli                                     ; changed in Event Handler)
    sts     blink_active, r17           ; and set the flag to active (unchanged)
    ldi     r16, low(FLASH_QUARTER_SEC)     ; and set the duration to 1/4 sec
    ldi     r17, high(FLASH_QUARTER_SEC)
    sts     blink_counter_L, r16
    sts     blink_counter_H, r17
    out     sreg, r0                    ; end critical code protection

EndBlinkDigits:
    ret


; ==============================================================================
;
; FlashQuarterSecond
;
; Description:       This function will flash on a passed light (in R16) for 1/4 
;                    second, using the flash_counter in the Event Handler.
;
; Operation:         Turns off interrupts for critical code, then sets the 
;                    flashed light counter to a time that will keep it on for 
;                    only 1/4 second. It will set the flash_active flag, and 
;                    update the flashed_light variable to the passed light (R16)
;
; Arguments:         R16    -   The Light to flash.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  flash_active     - write only. Indicates a signal is being 
;                                       flashed.
;                    flash_counter_L  - write only. The low half of the time 
;                                       tracker for a light being flashed.
;                    flash_counter_H  - write only. The high half of the time
;                                       tracker for a light being flashed.
;                    flashed_light    - write only. The signal identifier that
;                                       is currently being flashed. 
; Global Variables:  None.
;
; Input:             None.
; Output:            Flashes a passed LED for 1/4 second.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 13, 2025

FlashQuarterSecond:
    ldi     r17, TRUE                   ; to turn the light on first turn on            
    rcall   DisplayLight                ; (flash) for a duration (R16 passed in)

    in      r0, sreg                    ; save SREG (critical code, these vars
    cli                                     ; changed in Event Handler)
    sts     flashed_light, r16          ; start flashing passed light (unchanged) 
    sts     flash_active, r17           ; and set the flag to active (unchanged)
    ldi     r16, low(FLASH_QUARTER_SEC)     ; and set the duration to 1/4 sec
    ldi     r17, high(FLASH_QUARTER_SEC)
    sts     flash_counter_L, r16
    sts     flash_counter_H, r17
    out     sreg, r0                    ; end critical code protection

EndFlashQuarterSecond:
    ret


; ==============================================================================
;
; CheckFlashingLight
;
; Description:       This function is meant to be called only during the Timer0
;					 compare match Event Handler. It is used to check the status
;					 of a light that is to be flashed and update that light's 
;					 state if it's flashed for the right amount of time.
;
; Operation:         The function first checks the status of the flash_active 
;					 flag to see if a light is currently being flashed. If so,
;					 it will decrement the flash counter, and if it reaches zero,
;					 will turn the light off by calling the DisplayLight 
;					 function.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  flash_active 	-	read and write. Indicates a light is 
;										being flashed.
;					 flash_counter_L/H 	-  read and write. Counter measuring how 
;										long a light has been flashing.
;					 flashed_light	-	read only. Tells what light is currently
;										being flashed.
; Global Variables:  None.
;
; Input:             None.
; Output:            None directly, but will turn off a light after a time.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17.
; Stack Depth:       3 bytes.
;
; Author:            Benjamin Boone
; Last Modified:     June 13, 2025

CheckFlashingLight:
    push 	r16
    push 	r17
    in 		r16, SREG
    push 	r16                  		; Save status register
    
    lds 	r16, flash_active			; Check if flashing is active
    tst 	r16							
    breq 	EndCheckFlashingLight      	; Exit if not flashing

    lds 	r16, flash_counter_L		; Decrement 16-bit flash counter
    lds 	r17, flash_counter_H
    subi 	r16, 1                 		; Subtract 1 from low byte
    sbci 	r17, 0                 		; Subtract with carry from high byte
    sts 	flash_counter_L, r16
    sts 	flash_counter_H, r17
    
	; Check if counter reached zero (both bytes must be zero)
    or 		r16, r17                 	; OR low and high bytes
    brne 	EndCheckFlashingLight       ; Exit if result is not zero

    lds 	r16, flashed_light			; Counter reached zero - turn off LED 
	ldi 	r17, FALSE
	rcall	DisplayLight
	clr 	r16							; and reset the flashed light variable
    sts 	flashed_light, r16
    sts 	flash_active, r17			; and reset the flash_active flag
    
EndCheckFlashingLight:
    pop r16
    out SREG, r16               		; Restore status register
    pop r17
    pop r16
	ret

; ==============================================================================
;
; CheckBlinkingDigits                                                          
;
; Description:       This function is meant to be called only during the Timer0
;					 compare match Event Handler. It is used to check the status
;					 of the blinking digits on the display (if they are 
;                    blinking). It will update that status (on/off) based on how
;                    long they've been blinking and how many times they've blunk.
;                    Ends with all digits off.
;
; Operation:         The function first checks the status of the blink_active 
;					 flag to see if the digits are currently being flashed. If 
;					 so, it will decrement the blink counter, which monitors how
;                    long the digits have been on/off most recently. If the 
;					 counter reachers zero, then the blink_num_ctr will be 
;                    decremented (which controls how many times to blink the 
;                    digits). Once this reaches zero, the digits will be turned
;                    off. To actually accomplish blinking the digits, it will 
;                    save the display buffer (digit portion) to a temporary 
;                    buffer, and then alternate between setting the actual 
;                    buffer to zero (blink off) or the digit values (blink on).
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   Various registers.
; Shared Variables:  blink_active 	-	read and write. Indicates the digits are
;                                       being blinked.
;					 blink_counter_L/H 	-  read and write. Counter measuring how 
;										long the digits have been on/off in most
;                                       recent blink.
;					 blink_num_ctr	-	read and write. Tracks number of times
;                                       to turn the digits on/off.
;                    tempDigBuf     -   read and write. Temporary buffer to 
;                                       store digit segment patterns for blinks.
;                    curDigCol      -   read and write. Display Buffer.
; Global Variables:  None.
;
; Input:             None.
; Output:            Will, indirectly, turn the digits display on and off.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, R18, R22, R23, R24, X, Y
; Stack Depth:       3 bytes.
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025

CheckBlinkingDigits:
    push    r16                         ; Save all registers used (called in 
    push    r17                             ; event handler, but saves it's own)
    push    r18
    push    r22
    push    r23
    push    r24
    push    YL
    push    YH
    push    XL
    push    XH
    in      r16, SREG
    push    r16                         ; Save status register


CheckConditionalsBlinkDigits:
    lds     r16, blink_active           ; Check if blinking is active
    tst     r16                        
    breq    EndCheckBlinkingDigits      ; Exit if not blinking

    lds     r16, blink_counter_L        ; Decrement 16-bit blink counter
    lds     r17, blink_counter_H
    subi    r16, 1                      ; Subtract 1 from low byte
    sbci    r17, 0                      ; Subtract with carry from high byte
    sts     blink_counter_L, r16        ; and make sure to save
    sts     blink_counter_H, r17
   
    ; Check if counter reached zero (both bytes must be zero)
    or      r16, r17                    ; OR low and high bytes
    brne    EndCheckBlinkingDigits      ; Exit if result is not zero

    lds     r16, blink_num_ctr          ; Counter reached zero - decrement the
    dec     r16                             ; BlinkNumCounter
    sts     blink_num_ctr, r16          ; save
    tst     r16                         ; and check if at zero. If so, exit
    breq    DoneBlinking                    ; (done blinking)

    ldi     r16, low(FLASH_QUARTER_SEC)     ; if not, reset the duration for
    ldi     r17, high(FLASH_QUARTER_SEC)        ; the next blink
    sts     blink_counter_L, r16
    sts     blink_counter_H, r17


SetUpPointersSaveBlinkDigits:       ; To save the digits being blunk,
    ldi     XL, LOW(curDigCol)      ; Set X register to the start of the digits
    ldi     XH, HIGH(curDigCol)         ; in the display buffer
    ldi     r22, 0                    
    ldi     r23, DIGITS_OFFSET      
    add     XL, r23                  
    adc     XH, r22                    

    ldi     YL, LOW(tempDigBuf)     ; set Y to the top of the temporary buffer
    ldi     YH, HIGH(tempDigBuf)  
   
    ldi     r22, NUM_DIGITS_TOTAL   ; set up loop to save each digit


BlinkDigitsOnOrOff:                 ; prepare to loop through buffers
    lds     r16, blink_num_ctr      ; get num_ctr again
    andi    r16, MOD_2_MASK         ; get parity of the counter to determine if
    brne    BlinkDigitsOff              ; turn lights on or off
    ;breq   BlinkDigitsOn


BlinkDigitsOn:                      ; copy digits from tempDigBuf to curDigCol
    cpi     r22, 0                      ; and write curDigCol digits to 0
    breq    EndCheckBlinkingDigits  ; when done, jump to end

    ld      r18, Y+                 ; copy out of tempDigBuf
    st      X+, r18                 ; and put them in curDigCol (buffer)

    dec     r22                    
    rjmp    BlinkDigitsOn           ; loop until all done


BlinkDigitsOff:                 ; copy the digits from curDigCol to tempDigBuf
    cpi     r22, 0                      ; and write curDigCol digits to 0
    breq    EndCheckBlinkingDigits  ; When done, jump to end

    ld      r18, X
    ldi     r24, 0                  
    st      X+, r24                 ; clear the digit displays in the buffer
    st      Y+, r18                 ; but save them in tempDigBuf

    dec     r22                    
    rjmp    BlinkDigitsOff          ; loop until all digits done

DoneBlinking:
    ldi     r17, FALSE                  ; turn off the blinking flag if blinked
    sts     blink_active, r17               ; for the full duration
   
EndCheckBlinkingDigits:
    pop     r16
    out     SREG, r16                       ; Restore status register
    pop     XH
    pop     XL
    pop     YH
    pop     YL
    pop     r24
    pop     r23
    pop     r22
    pop     r18
    pop     r17
    pop     r16
    ret


; ##############################################################################
; data portion
.dseg

; shared variables in memory for multiplexing. See outline below.
MuxIndex:       .byte   1               ; Indicates column currently multiplexing.
StorePortA:		.byte	1               ; Keeps track of muxing in 8x8 grid.
StorePortD:		.byte 	1               ; Keeps track of muxing in 4-digit displays.
curDigCol:      .byte   NUM_COLS        ; this is the Display Buffer.

; for blinking display function
tempDigBuf:         .byte   NUM_DIGITS_TOTAL  ; stores the digits while blinking
blink_active:       .byte   1   ; flag indicating the digits are blinking
blink_counter_H:    .byte   1   ; blinks/is on/off for this many of seconds 
blink_counter_L:    .byte   1       ; two registers to hold longer delays
blink_num_ctr:      .byte   1   ; holds the number of times to blink the digits

; For Flashing LEDs
flash_active:       .byte   1   ; flag indicating that a light is flashing now
flash_counter_H:    .byte   1   ; flashes light for this number of ms, 
flash_counter_L:    .byte   1       ; two registers to hold longer flashes
flashed_light:      .byte   1   ; stores which light is currently being flashed


; Format of Display Buffer, or curDigCol, in memory.
;       and what each bit/byte means:

;   Byte/ |   Port/    | Bit7 | Bit6 | Bit5 | Bit4 | Bit3 | Bit2 | Bit1 | Bit0
;  Offset |  Display   |      |      |      |      |      |      |      | 
; ==============================================================================
;    0	  |  8x8 Grid  | LED  | LED  | LED  | LED  | LED  | LED  | LED  | LED  
;    	  |  Port  A0  |   1  |   2  |   3  |   4  |   5  |   6  |   7  |   8
; --------| - - - - - -|--------------------------------------------------------
;    1	  |        A1  | LED  | LED  | LED  | LED  | LED  | LED  | LED  | LED  
;    	  |            |   9  |   10 |   11 |   12 |   13 |   14 |   15 |   16
; --------| - - - - - -|--------------------------------------------------------
;    2	  |        A2  | LED  | LED  | LED  | LED  | LED  | LED  | LED  | LED  
;    	  |            |   17 |   18 |   19 |   20 |   21 |   22 |   23 |   24
; --------| - - - - - -|--------------------------------------------------------
;    3	  |        A3  | LED  | LED  | LED  | LED  | LED  | LED  | LED  | LED  
;    	  |            |   25 |   26 |   27 |   28 |   29 |   30 |   31 |   32
; --------| - - - - - -|--------------------------------------------------------
;    4	  |        A4  | LED  | LED  | LED  | LED  | LED  | LED  | LED  | LED  
;    	  |            |   33 |   34 |   35 |   36 |   37 |   38 |   39 |   40
; --------| - - - - - -|--------------------------------------------------------
;    5	  |        A5  | LED  | LED  | LED  | LED  | LED  | LED  | LED  | LED  
;    	  |            |   41 |   42 |   43 |   44 |   45 |   46 |   47 |   48
; --------| - - - - - -|--------------------------------------------------------
;    6	  |        A6  | LED  | LED  | LED  | LED  | LED  | LED  | LED  | LED  
;    	  |            |   49 |   50 |   51 |   52 |   53 |   54 |   55 |   56
; --------| - - - - - -|--------------------------------------------------------
;    7	  |        A7  | LED  | LED  | LED  | LED  | LED  | LED  | LED  | LED  
;    	  |            |   57 |   58 |   59 |   60 |   61 |   62 |   63 |   64
; ==============================================================================
;    8	  |  Player 2  |      
;    	  |  Port  D0  |     - - - - - - - - Digit 0 Pattern - - - - - -
; ---------            ---------------------------------------------------------
;    9	  |        D1  |     - - - - - - - - Digit 1 Pattern - - - - - - 
; --------- 	       ---------------------------------------------------------
;    10	  |        D2  |     - - - - - - - - Digit 2 Pattern - - - - - - 
; ---------	           ---------------------------------------------------------
;    11	  |        D3  |     - - - - - - - - Digit 3 Pattern - - - - - - 
; ------------------------------------------------------------------------------
;    12	  |  Player 1  |      
;    	  |  Port  D4  |     - - - - - - - - Digit 0 Pattern - - - - - -
; ---------	           ---------------------------------------------------------
;    13	  |        D5  |     - - - - - - - - Digit 1 Pattern - - - - - - 
; ---------	           ---------------------------------------------------------
;    14	  |        D6  |     - - - - - - - - Digit 2 Pattern - - - - - - 
; ---------	           ---------------------------------------------------------
;    15	  |        D7  |     - - - - - - - - Digit 3 Pattern - - - - - - 
; ------------------------------------------------------------------------------
