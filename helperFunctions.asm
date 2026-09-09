;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             helperFunctions.asm                            ;
;                                 Homework #5                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the functions that are called by the main game loop and 
;   other functions to operate the pinball machine.
;   The public functions included are:
;       LoadTheBall -   Will 'flash' the actuator to load the ball into the 
;                       pinball machine launcher. Lasts 1 second.
;       Delay       -   Will delay an amount of time, 10 * passed number ms
;       Bin2BCD     -   Converts a 16-bit binary value into BCD
;       Div16       -   Divides two 16-bit binary values
;       IncrementPlayerScore1 - Increments the current player's score by 1, and
;                               displays the new score. 
;       IncrementPlayerScore10 - Increments the current player's score by 10, 
;                                and displays the new score.
;       IncrementPlayerScore100 - Increments the current players score by 100, 
;                                 and displays that new score.
;       GetHighScore    -   Reads the High Score from EEROM, saves in data mem.
;       GetGamesLeft    -   Reads the Games Left from EEROM, saves in data mem.
;
; Revision History:
;   6/12/2025    Benjamin Boone  Initial revision
;   6/14/2025    Benjamin Boone  Updated Comments, moved some functions


.cseg

; ==============================================================================
;
; LoadTheBall
;
; Description:       This function will load the ball from the drain into the 
;                    launcher, by activating the load ball actuator for 1 second
;
; Operation:         This function calls the DisplayLight Function on the 
;                    Load Ball Actuator, and then sets the flash_active flag and
;                    associated variables to 'flash' the actuator for one 
;                    second.
;
; Arguments:         None.
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
; Output:            Moves the ball (physically) from the drain to the launcher.
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
; Last Modified:     May 11, 2026		Removed actuator control since not doing on real machine.

LoadTheBall:
    ;ldi     r16, LOAD_BALL_ACTUATOR     ; get the load ball actuator
    ;ldi     r17, TRUE                   
    ;rcall   DisplayLight                ; first turn on (flash) for a duration

    in      r0, sreg                    ; save SREG (critical code, these vars
    cli                                     ; changed in Event Handler)
    sts     flashed_light, r16          ; start flashing THIS light (unchanged)
    sts     flash_active, r17           ; and set the flag to active (unchanged)
    ldi     r16, low(FLASH_1_SEC)       ; and set the duration
    ldi     r17, high(FLASH_1_SEC)
    sts     flash_counter_L, r16
    sts     flash_counter_H, r17
    out     sreg, r0                    ; end critical code protection

EndLoadTheBall:
    ret                                 ; and return


; ==============================================================================
;
; Delay
;
; Description:       Delays the number of clocks passed in R16 times 80000. Thus 
;                    with a 8 MHz clock the passed delay is in 10 millisecond 
;                    units (assuming no interrupt overhead).
;
; Operation:         The function just loops decrementing Y until it is 0.
;
; Arguments:         time   -   Pased in R16, the number of milliseconds to 
;                               delay divided by 10 (So if 50 is passed in, it 
;                               will delay for 500 ms).
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
; Registers Changed: flags, R16, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George, edited by Benjamin Boone
; Last Modified:     June 12, 2018

Delay:
    push    YL
    push    YH

DelayLoop:                      ; outer loop runs R16 times
    ldi     YL, low(20000)      ; inner loop is 4 clocks
    ldi     YH, high(20000)     ; so loop 20000 times to get 80000 clocks
DelayInnerLoop:                 ; do the delay
    sbiw    Y, 1
    brne    DelayInnerLoop

    dec     r16                 ; count outer loop iterations
    brne    DelayLoop


DoneDelay:                      ; done with the delay loop - pop and return
    pop     YH
    pop     YL
    ret


; ==============================================================================
;
; Bin2BCD
;
;
; Description:       This function converts the 16-bit binary value passed to
;                    it to BCD (4-digits) and returns that result.  If there
;                    is an overflow (the number is bigger than 9999), the
;                    carry flag is set.  The number is assumed to be positive.
;
; Operation:         The function starts with the largest power of 10 possible
;                    (1000) and loops dividing the number by the power of 10,
;                    the quotient is a digit and the remainder is used in the
;                    next iteration of the loop.  Each loop iteration divides
;                    the power of 10 by 10 until it is 0.  At that point the
;                    number has been converted to BCD.
;
; Arguments:         R17|R16 - binary value to convert to BCD.
; Return Values:     R19|R18 - BCD of binary value passed in R17|R16.
;                    CF      - set to 1 if passed value > 9999 (decimal), 0
;                              otherwise.
;
; Local Variables:   digit (R3|R2)    - computed BCD digit (R3 always 0).
;                    error (CF)       - error flag.
;                    pwr10 (R21|R20)  - current power of 10 being computed.
;                    result (R19|R18) - BCD result from conversion.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If the number to be converted is greater than 9999 the
;                    carry flag is set and a meaningless value is returned.
;
; Registers Changed: flags, R2, R3, R4, R5, R16, R17, R18, R19, R20, R21, R22
; Stack Depth:       0 words
;
; Algorithms:        Repeatedly divide by powers of 10 and get the remainders
;                    (which are the BCD digits).
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       Can only handle positive numbers which are less than
;                    9999.
;
; Revision History:   4/16/18   Glen George      initial revision
;                     4/22/22   Glen George      use a loop for rotation
;                     6/12/25   Glen George      fixed bug - mixed up return
;                                                   values for Div16
;
;
; Pseudo Code
;
;   result = 0
;   pwr10 = 1000
;   error = FALSE
;   WHILE ((error = FALSE) AND (pwr10 != 0))
;       digit = arg/pwr10
;       IF (digit < 10) THEN
;           result = result shifted left 4 bits OR digit
;           arg = arg MODULO pwr10
;           pwr10 = pwr10/10
;           error = FALSE
;       ELSE
;           error = TRUE
;       ENDIF
;   ENDWHILE
;   RETURN  error, result


Bin2BCD:

Bin2BCDInit:                            ;initialization
        LDI     R20, LOW(1000)          ;start with 10^3 (1000's digit)
        LDI     R21, HIGH(1000)
        CLC                             ;no error yet
        ;RJMP   Bin2BCDLoop             ;now start looping to get digits


Bin2BCDLoop:                            ;loop getting the digits in arg
        BRCS    EndBin2BCDLoop          ;if there is an error - we're done
        MOV     R22, R21                ;check if pwr10 != 0
        OR      R22, R20
        BREQ    EndBin2BCDLoop          ;if not, have done all digits, done
        ;RJMP   Bin2BCDLoopBody         ;else get the next digit

Bin2BCDLoopBody:                        ;get a digit
        RCALL   Div16                   ;digit = arg/pwr10, arg = arg % pwr10
        CPI     R16, 10                 ;check if digit < 10 (upper 8 bits always 0)
        BRSH    TooBigError             ;if not, it's an error
        ;BRLO   HaveDigit               ;otherwise process the digit

HaveDigit:                              ;put the digit into the result
        LDI     R22, 4                  ;shift result to make room for new
ShiftLoop:                              ;   digit (need to shift 16-bit value
        CPI     R22, 1                  ;   left by 4)
        BRLO    DoneShift
        ;BRSH   DoShift
DoShift:                                ;shift 16-bit value left one bit
        LSL     R18
        ROL     R19
        DEC     R22                     ;update loop counter
        RJMP    ShiftLoop               ;and loop

DoneShift:
        OR      R18, R16                ;and actually or in the digit

        MOVW    R4, R2                  ;temporarily save remaining value to convert
        MOVW    R16, R20                ;setup to update pwr10
        LDI     R20, LOW(10)            ;will divide by 10
        LDI     R21, HIGH(10)
        RCALL   Div16                   ;divide pwr10 by 10
        MOVW    R20, R16                ;pwr10 = pwr10/10
        MOVW    R16, R4                 ;restore value to convert too
        CLC                             ;no error
        RJMP    EndBin2BCDLoopBody      ;done getting this digit

TooBigError:                            ;the value was too big
        SEC                             ;set the error flag
        ;RJMP   EndBin2BCDLoopBody      ;and done with this loop iteration

EndBin2BCDLoopBody:
        RJMP    Bin2BCDLoop             ;keep looping (end check is at top)


EndBin2BCDLoop:                         ;done converting, just return
        RET

; ==============================================================================
;
; Div16
;
; Description:       This function divides the 16-bit unsigned value passed in
;                    R17|R16 by the 16-bit unsigned value passed in R21|R20.
;                    The quotient is returned in R17|R16 and the remainder is
;                    returned in R3|R2.
;
; Operation:         The function divides R17|R16 by R21|R20 using a restoring
;                    division algorithm with a 16-bit temporary register R3|R2
;                    and shifting the quotient into R17|R16 as the dividend is
;                    shifted out.  Note that the carry flag is the inverted
;                    quotient bit (and this is what is shifted into the
;                    quotient) so at the end the entire quotient is inverted.
;
; Arguments:         R17|R16 - 16-bit unsigned dividend.
;                    R21|R20 - 16-bit unsigned divisor.
; Return Values:     R17|R16 - 16-bit quotient.
;                    R3|R2   - 16-bit remainder.
;
; Local Variables:   bitcnt (R22) - number of bits left in division.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Registers Changed: flags, R2, R3, R16, R17, R22
; Stack Depth:       0 bytes
;
; Algorithms:        Restoring division.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
;
; Revision History:   4/15/18   Glen George      initial revision

Div16:
        LDI     R22, 16                 ;number of bits to divide into
        CLR     R3                      ;clear temporary register (remainder)
        CLR     R2

Div16Loop:                              ;loop doing the division
        ROL     R16                     ;rotate bit into temp (and quotient
        ROL     R17                     ;   into R17|R16)
        ROL     R2
        ROL     R3
        CP      R2, R20                 ;check if can subtract divisor
        CPC     R3, R21
        BRCS    Div16SkipSub            ;cannot subtract, don't do it
        SUB     R2, R20                 ;otherwise subtract the divisor
        SBC     R3, R21
Div16SkipSub:                           ;C = 0 if subtracted, C = 1 if not
        DEC     R22                     ;decrement loop counter
        BRNE    Div16Loop               ;if not done, keep looping
        ROL     R16                     ;otherwise shift last quotient bit in
        ROL     R17
        COM     R16                     ;and invert quotient (carry flag is
        COM     R17                     ;   inverse of quotient bit)
        ;RJMP   EndDiv16                ;and done (remainder is in R3|R2)

EndDiv16:                               ;all done, just return
        RET


; ==============================================================================
;
; IncrementPlayerScore1
;
; Description:       This function will add 1 to the current player's score, 
;                    unless there is a tilt violation. It will also update the 
;                    digits display with both player's scores.
;
; Operation:         First checks if there was a tilt violation. If so, skips to
;                    the end. The checks who current player is, and loads their 
;                    score into registers, then offsets the BCD value by 6 in 
;                    each digit so carry's will work normally, then adds one and  
;                    sets back to BCD, accounting for carried values between 
;                    digits. Then checks again who's playing and stores the 
;                    updated value appropriately.
;
; Arguments:         None. 
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentPlayer  -   read only. Who the current player is
;                    p1/2score      -   read and write. The current (p1 or p2) 
;                                       player's score.
;                    TiltFlag       -   read only. Flag for a tilt violation
;                   
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
; Registers Changed: flags, R16, R17, R18
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 13, 2025

IncrementPlayerScore1:
    lds     r18, TiltFlag           ; first check the tilt flag, if set, don't
    cpi     r18, FALSE                  ; give any points.
    brne    EndIncrementPlayerScore1
    lds     r18, currentPlayer      ; get the current player
    cpi     r18, PLAYER_1           ; check if it's player 1
    breq    IncrementP1Score1           ; if so, go get his score
    ;brne   IncrementP2Score1

IncrementP2Score1:
    lds     r16, p2Score            ; get the low byte of player 2's score
    lds     r17, p2Score + 1        ; and the high byte (compiler does +1) 
    rjmp    BCDIncrement1  

IncrementP1Score1:
    lds     r16, p1Score            ; get the low byte of player 1's score
    lds     r17, p1Score + 1        ; and the high byte (compiler does +1)   
    ;rjmp   BCDIncrement1

BCDIncrement1:
    subi    r16, -0x66              ; offset so carry's will work
    subi    r17, -0x66

    subi    r16, -1                 ; add one
    brhs    SkipDigit0Adj1          ; if half carry, then we don't do anything
    ori     r16, 0x06                   ; to first digit (already "0")
SkipDigit0Adj1:
    brcs    SkipDigit1Adj1          ; if whole carry, then don't update 2nd 
    ori     r16, 0x60                   ; digit (already "0")
SkipDigit1Adj1:

    sbci    r17, -1                 ; bring the carry over to the next reg
    brhs    SkipDigit2Adj1          ; and check if need to update this digit
    ori     r17, 0x06                   ; based on half carry
SkipDigit2Adj1:
    brcs    SkipDigit3Adj1          ; if whole carry, don't update last digit
    ori     r17, 0x60                   ; (already "0")
SkipDigit3Adj1:
    subi    r16, 0x66               ; undo offset, back to normal BCD
    subi    r17, 0x66

StoreUpdatedScore1:
    cpi     r18, PLAYER_1           ; check again whose playing right now
    breq    StoreP1Score1               ; r18 is unchanged
    ;brne   StoreP2Score1

StoreP2Score1:
    sts     p2Score, r16            ; store the low byte of player 2's score
    sts     p2Score + 1, r17        ; and the high byte (compiler does +1) 
    rjmp    EndIncrementPlayerScore1  

StoreP1Score1:
    sts     p1Score, r16            ; store the low byte of player 1's score
    sts     p1Score + 1, r17        ; and the high byte (compiler does +1)   
    ;rjmp   EndIncrementPlayerScore1

EndIncrementPlayerScore1:
    ldi     r18, PLAYER_1           ; Display both player's scores
    lds     r16, p1Score            ; get the low byte of player 1's score
    lds     r17, p1Score + 1        ; and the high byte (compiler does +1)     
    rcall   DisplayHex              ; and display. 
    ldi     r18, PLAYER_2           ; Same for player 2
    lds     r16, p2Score
    lds     r17, P2Score + 1
    rcall   DisplayHex
    ret                             ; done, so return.

; ==============================================================================
;
; IncrementPlayerScore10
;
; Description:       This function will add 10 to the current player's score, 
;                    unless there is a tilt violation. It will also update the 
;                    digits display with both player's scores.
;
; Operation:         First checks if there was a tilt violation. If so, skips to
;                    the end. The checks who current player is, and loads their 
;                    score into registers, then offsets the BCD value by 6 in 
;                    each digit so carry's will work normally, then adds ten and  
;                    sets back to BCD, accounting for carried values between 
;                    digits. Then checks again who's playing and stores the 
;                    updated value appropriately.
;
; Arguments:         None. 
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentPlayer  -   read only. Who the current player is
;                    p1/2score      -   read and write. The current (p1 or p2) 
;                                       player's score.
;                    TiltFlag       -   read only. Flag for a tilt violation
;                   
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
; Registers Changed: flags, R16, R17, R18
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 13, 2025

IncrementPlayerScore10:
    lds     r18, TiltFlag           ; first check the tilt flag, if set, don't
    cpi     r18, FALSE                  ; give any points.
    brne    EndIncrementPlayerScore10
    lds     r18, currentPlayer      ; get the current player
    cpi     r18, PLAYER_1           ; check if it's player 1
    breq    IncrementP1Score10          ; if so, go get his score
    ;brne   IncrementP2Score10

IncrementP2Score10:
    lds     r16, p2Score            ; get the low byte of player 2's score
    lds     r17, p2Score + 1        ; and the high byte (compiler does +1) 
    rjmp    BCDIncrement10  

IncrementP1Score10:
    lds     r16, p1Score            ; get the low byte of player 1's score
    lds     r17, p1Score + 1        ; and the high byte (compiler does +1)   
    ;rjmp   BCDIncrement10

BCDIncrement10:
    subi    r16, -0x66              ; offset so carry's will work
    subi    r17, -0x66

    subi    r16, -0x10				; add ten (and don't worry about first dig)
    brcs    SkipDigit1Adj10			; if whole carry, then don't update 2nd 
    ori     r16, 0x60                   ; digit (already "0")
SkipDigit1Adj10:

    sbci    r17, -1                 ; bring the carry over to the next reg
    brhs    SkipDigit2Adj10         ; and check if need to update this digit
    ori     r17, 0x06                   ; based on half carry
SkipDigit2Adj10:
    brcs    SkipDigit3Adj10         ; if whole carry, don't update last digit
    ori     r17, 0x60                   ; (already "0")
SkipDigit3Adj10:
    subi    r16, 0x66               ; undo offset, back to normal BCD
    subi    r17, 0x66

StoreUpdatedScore10:
    cpi     r18, PLAYER_1           ; check again whose playing right now
    breq    StoreP1Score1               ; r18 is unchanged
    ;brne   StoreP2Score1

StoreP2Score10:
    sts     p2Score, r16            ; store the low byte of player 2's score
    sts     p2Score + 1, r17        ; and the high byte (compiler does +1) 
    rjmp    EndIncrementPlayerScore10  

StoreP1Score10:
    sts     p1Score, r16            ; store the low byte of player 1's score
    sts     p1Score + 1, r17        ; and the high byte (compiler does +1)   
    ;rjmp   EndIncrementPlayerScore10

EndIncrementPlayerScore10:
    ldi     r18, PLAYER_1           ; Display both player's scores
    lds     r16, p1Score            ; get the low byte of player 1's score
    lds     r17, p1Score + 1        ; and the high byte (compiler does +1)     
    rcall   DisplayHex              ; and display. 
    ldi     r18, PLAYER_2           ; Same for player 2
    lds     r16, p2Score
    lds     r17, P2Score + 1
    rcall   DisplayHex
    ret                             ; done, so return.

; ==============================================================================
;
; IncrementPlayerScore100
;
; Description:       This function will add 100 to the current player's score, 
;                    unless there is a tilt violation. It will also update the 
;                    digits display with both player's scores.
;
; Operation:         First checks if there was a tilt violation. If so, skips to
;                    the end. The checks who current player is, and loads their 
;                    score into registers, then offsets the BCD value by 6 in 
;                    each digit so carry's will work normally, then adds 100 and  
;                    sets back to BCD, accounting for carried values between 
;                    digits. Then checks again who's playing and stores the 
;                    updated value appropriately.
;
; Arguments:         None. 
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentPlayer  -   read only. Who the current player is
;                    p1/2score      -   read and write. The current (p1 or p2) 
;                                       player's score.
;                    TiltFlag       -   read only. Flag for a tilt violation
;                   
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
; Registers Changed: flags, R16, R17, R18
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 13, 2025


IncrementPlayerScore100:
    lds     r18, TiltFlag           ; first check the tilt flag, if set, don't
    cpi     r18, FALSE                  ; give any points.
    brne    EndIncrementPlayerScore100
    lds     r18, currentPlayer      ; get the current player
    cpi     r18, PLAYER_1           ; check if it's player 1
    breq    IncrementP1Score100         ; if so, go get his score
    ;brne   IncrementP2Score100

IncrementP2Score100:
    lds     r16, p2Score            ; get the low byte of player 2's score
    lds     r17, p2Score + 1        ; and the high byte (compiler does +1) 
    rjmp    BCDIncrement100  

IncrementP1Score100:
    lds     r16, p1Score            ; get the low byte of player 1's score
    lds     r17, p1Score + 1        ; and the high byte (compiler does +1)   
    ;rjmp   BCDIncrement100

BCDIncrement100:
    ;subi    r16, -0x66             ; offset so carry's will work
    subi    r17, -0x66                  ; not changing r16, so commented out

    subi    r17, -1                 ; add 1 to r17 (digit 3) = adding 100 
    brhs    SkipDigit2Adj100        ; check if need to edit dig 3 or not
    ori     r17, 0x06
SkipDigit2Adj100:
    brcs    SkipDigit3Adj100        ; check if need to edit last digit
    ori     r17, 0x60
SkipDigit3Adj100:               
    ;subi    r16, 0x66              ; and undo the offset (only edited r17)
    subi    r17, 0x66

StoreUpdatedScore100:
    cpi     r18, PLAYER_1           ; check again whose playing right now
    breq    StoreP1Score100             ; r18 is unchanged
    ;brne   StoreP2Score1

StoreP2Score100:
    sts     p2Score, r16            ; store the low byte of player 2's score
    sts     p2Score + 1, r17        ; and the high byte (compiler does +1) 
    rjmp    EndIncrementPlayerScore100  

StoreP1Score100:
    sts     p1Score, r16            ; store the low byte of player 1's score
    sts     p1Score + 1, r17        ; and the high byte (compiler does +1)   
    ;rjmp   EndIncrementPlayerScore100

EndIncrementPlayerScore100:
    ldi     r18, PLAYER_1           ; Display both player's scores
    lds     r16, p1Score            ; get the low byte of player 1's score
    lds     r17, p1Score + 1        ; and the high byte (compiler does +1)     
    rcall   DisplayHex              ; and display. 
    ldi     r18, PLAYER_2           ; Same for player 2
    lds     r16, p2Score
    lds     r17, P2Score + 1
    rcall   DisplayHex
    ret                             ; done, so return.


; ==============================================================================
;
; GetHighScore
;
; Description:       This function will read the current high score from
;                    EEROM. It will also set a variable in memory, high_score, 
;                    to the value read from EEROM.
;
; Operation:         Reads the 2 byte value in EEROM stored at address 0, this 
;                    is where the high score will be kept. Stores that in 
;                    memory at high_score.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  high_score  -  write only. The highest score yet scored
;                                   on the pinball machine.
;
; Global Variables:  None.
;
; Input:             Receives data from EEROM.
; Output:            Sends signals to read from EEROM.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, Y
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

GetHighScore:
    ldi     r16, HSCORE_BYTE_LENGTH     ; read 2 bytes from EEROM
    ldi     r17, HIGH_EEROM_ADDR        ; from address (0) in EEROM
    ldi     YL, LOW(high_score)         ; and store in the high_score variable
    ldi     YH, HIGH(high_score) 
    rcall   ReadEEROM

EndGetHighScore:
    ret

; ==============================================================================
;
; GetGamesLeft
;
; Description:       This function will read the current number of games left 
;                    from EEROM. It will also set a variable in memory, 
;                    games_left, to the value read from EEROM.
;
; Operation:         Reads the 2 byte value in EEROM stored at address 2, this 
;                    is where the games left will be kept. Stores that in 
;                    memory at games_left.
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
; Input:             Receives data from EEROM.
; Output:            Sends signals to read from EEROM.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, Y
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

GetGamesLeft:
    ldi     r16, GAMES_BYTE_LENGTH      ; read 1 byte from EEROM
    ldi     r17, GAMES_EEROM_ADDR       ; from address (2) in EEROM
    ldi     YL, LOW(games_left)         ; and store in the high_score variable
    ldi     YH, HIGH(games_left) 
    rcall   ReadEEROM

EndGetGamesLeft:
    ret
