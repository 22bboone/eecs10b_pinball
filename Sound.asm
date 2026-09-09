;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Sound.asm                                ;
;                                 Homework #5                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the functions for operating the Sound (speaker) in the 
;   pinball machine as a part of Homework 5. It also includes tables for playing
;   notes of different pitch and duration for Game Music
;   The public functions included are:
;       InitSound           -   Initializes the speaker, setting the correct 
;                               output port pins and turning the speaker off.
;       PlayNote            -   Plays a note through the speaker at a given
;                               frequency.
;       Div24by16           -   Helper function that will divide the prescaled
;                               CPU clock by 2 times the passed frequency to 
;                               get a value for the compare match register so
;                               PlayNote() operates correctly.
;       StartGameMusic      -   Initiates playing GameMusic from a given table
;       LoadNextNote        -   Function that will increment through the table
;                               of notes in a song and check if it's done or not
;       StopGameMusic       -   Will turn off any song being played.
;       CheckIfSongPlaying  -   Called from the EventHandler, will update the 
;                               speaker's output based on counters (time)
;       PlaySoundBurst      -   Plays a short burst of sound (1 note) for a 
;                               passed duration.
;       CheckSoundBurst     -   Called from the Event Handler, checks for a 
;                               sound burst playing and stops it after a given 
;                               amount of time.
;
;   Tables Included are:
;       CircusMusicTable    -   A table consisting of the note frequencies and
;                               durations to play circus music!
;
;
; Revision History:
;   5/30/2025    Benjamin Boone  Initial revision of all functions
;   6/3/2025     Benjamin Boone  Updated comments
;   6/14/2025    Benjamin Boone  Added SoundBurst and Music functions
;   6/16/2025    Benjamin Boone  Updated Comments, organized



.cseg

; ==============================================================================
;
; InitSound
;
; Description:       This procedure initializes the OC1A pin as an output as a 
;                    part of Port B, and initializes the settings for Timer1 
;                    (to not count).
;
; Operation:         Sets bit 5 in Port B, corresponding to OC1A as an output. 
;                    Calls the PlayNote() function with a frequency of zero to 
;                    initialize the Timer/Counter1 as off.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
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
; Registers Changed: Flags, R16, R17                    
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     May 17, 2025

InitSound:
    sbi     DDRB, SOUND_BIT         ; set this pin as an output (used as OC1A)
    ldi     r17, 0
    ldi     r16, 0
	rcall   PlayNote                ; call PlayNote with 0 turns off the speaker

EndInitSound:
    ret 




; ==============================================================================
;
; PlayNote
;
; Description:       The function plays the note with the passed frequency (freq,
;                    in Hz) on the speaker. This tone is output until a new tone 
;                    is output via this function. A frequency of 0 Hz (passed 
;                    value is 0) turns off the speaker output. The frequency 
;                    (freq) is a 16-bit value passed by value in R17 | R16 (R17 
;                    is the high byte).
;
; Operation:         First checks the value of freq passed in to see whether or 
;                    not it is zero. If it is zero, it turns the timer off in 
;                    order to stop the speaker from playing. If it is non-zero, 
;                    it turns the timer on, prescaled by 8, and sets the compare 
;                    match register to an appropriate value to output a signal 
;                    so the speaker plays a tone at the desired frequency.
;
; Arguments:         freq - a 16 bit value passed in R17 and R16 representing 
;                    the frequency to be played by the speaker (in Hz). See 
;                    Limitations for a note about range.                                     
; Return Value:      None.
;
; Local Variables:   R18    -   Read and Write for temporary variables
; Shared Variables:  None.
;
; Input:             None.
; Output:            The speaker will play a tone at the frequency given by freq. 
;                    This is done via toggling the OC1A output pin at twice the 
;                    frequency passed in (twice because each toggle only turns 
;                    it on or off).
;
; Error Handling:    If a frequency of zero is passed in, the function turns off 
;                    the speaker (no tone generated).
; Limitations:       If a frequency is passed in R17|R16 above the ability of 
;                    human hearing (between 20 Hz and 20 kHz) the function will 
;                    still work normally, but humans will not detect as sound. 
;                    Note also that output frequencies are approximations of the
;                    input value due to binary logic division (no decimal, will
;                    round).
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, Z, R16, R17, R18, 
; Stack Depth:       0 bytes.
;
; Author:            Benjamin Boone
; Last Modified:     May 30, 2025
;

PlayNote:

CheckFreqValue:
    mov     r18, r16                    ; Copy low byte of freq to temp register
    or      r18, r17                    ; Combine with high byte
    breq    TurnOffSpeaker              ;   to check if they're both zero.
    ;brne   SetSpeakerTone

SetSpeakerTone:
	ldi 	r18, TIMER1A_ON
    out     TCCR1A, r18		            ; turn on toggle
	ldi 	r18, TIMER1B_ON
    out     TCCR1B, r18		            ; turn on prescaled clock
    ldi 	r20, PRESCALED_CLK_FREQ_HIGH    ; send the prescaled clk/8/2 as the  
	ldi 	r19, PRESCALED_CLK_FREQ_MID     ; dividend to divide function
	ldi 	r18, PRESCALED_CLK_FREQ_LOW
    rcall   Div24by16   
    out     OCR1AH, r19                 ; load the desired toggle frequency
    out     OCR1AL, r18                 
	rjmp    EndPlayNote

TurnOffSpeaker:
 	ldi 	r18, TIMER1A_OFF
    out     TCCR1A, r18		            ; turn off toggle
	ldi 	r18, TIMER1B_OFF
    out     TCCR1B, r18		            ; turn off clock
    cbi     PORTB, SOUND_BIT            ; turn "off" the speaker       
    ;rjmp   EndPlayNote                 ; Note for future: 
                                            ; need to reset the compare reg?

EndPlayNote:                            ; done so return
    ret 
    
; ==============================================================================
; Div24by16
;
;
; Description:       This function divides the 24-bit unsigned value passed in
;                    R18|R17|R16 by the 16-bit unsigned value passed in R21|R20.
;                    The quotient is returned in R18|R17|R16 and the remainder is
;                    returned in R3|R2.
;
; Operation:         The function divides R20|R19|R18 by R17|R16 using a restoring
;                    division algorithm with a 16-bit temporary register R3|R2
;                    and shifting the quotient into R20|R19|R18 as the dividend is
;                    shifted out.  Note that the carry flag is the inverted
;                    quotient bit (and this is what is shifted into the
;                    quotient) so at the end the entire quotient is inverted.
;
; Arguments:         R20|R19|R18 - 24-bit unsigned dividend.
;                    R17|R16     - 16-bit unsigned divisor.
; Return Values:     R20|R19|R18 - 24-bit quotient.
;                    R3|R2       - 16-bit remainder.
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
; Registers Changed: flags, R2, R3, R18, R19, R20, R22
; Stack Depth:       0 bytes
;
; Algorithms:        Restoring division.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
;
; Revision History:   
;   4/15/18     Glen George     initial revision
;   5/30/25     Benjamin Boone  modified from original Div16 for 24-bit dividend
;   6/3/2025    Benjamin Boone  updated comments

; Note for Homework submission: Used Claude (LLM) to assist in conversion from 
;                               16/16 divider to 24/16 divider. I made 
;                               appropriate modifications to Prof. George's code

Div24by16:
        ldi     r22, 24                 ; number of bits to divide into (24)
        clr     r3                      ; clear temporary register (remainder)
        clr     r2

Div24Loop:                              ; loop doing the division
        rol     r18                     ; rotate bit into temp (and quotient
        rol     r19                     ;    into R20|R19|R18)
        rol     r20                     ; rotate the high byte as well
        rol     r2                      ; rotate into remainder register
        rol     r3
        cp      r2, R16                 ; check if can subtract divisor
        cpc     r3, R17
        brcs    Div24SkipSub            ; cannot subtract, don't do it
        sub     r2, R16                 ; otherwise subtract the divisor
        sbc     r3, R17
Div24SkipSub:                           ; C = 0 if subtracted, C = 1 if not
        dec     r22                     ; decrement loop counter
        brne    Div24Loop               ; if not done, keep looping
        rol     r18                     ; otherwise shift last quotient bit in
        rol     r19
        rol     r20                     ;    (all 3 bytes)
        com     r18                     ; and invert quotient (carry flag is
        com     r19                     ;    inverse of quotient bit)
        com     r20                     ; invert all three bytes of quotient
        ;rjmp   EndDiv24                ; and done (remainder is in R3|R2)

EndDiv24:                               ; all done, just return
        ret

; ==============================================================================
;
; StartGameMusic
;
; Description:       Will start playing a song, game music, from a song table,
;                    CircusMusicTable, by setting the appropriate flags and 
;                    variables to go through the table, and output notes to the 
;                    speaker.
;
; Operation:         Sets the song_playing flag, indicating that a song is now
;                    on. Then it will set the Z Register at the top of the table
;                    of the song to play, and save that position. Then it will
;                    call the next note to be played, starting the incrementation
;                    through the table.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  song_playing     - write only. Flag indicating a song is
;                                       now being played.
;                    song_base_l      - write only. The low half of the start of
;                                       the song table in program memory.
;                    song_base_l      - write only. The high half of the start 
;                                       of the song table in program memory.
;                    song_pointer_l   - write only. Points to where in the song
;                                       table we are. Low half.
;                    song_pointer_h   - write only. Points to where in the song
;                                       table we are. High half.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            Starts Playing Music out of the speaker.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, Z
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025
;
;       Special Notes: Used the LLM Claude by Anthropic in writing this function

StartGameMusic:
    ldi     r16, TRUE                       ; set the song playing flag
    sts     song_playing, r16   

    ldi     ZL, low(2*CircusMusicTable)     ; Get the bgeinning of song table
    ldi     ZH, high(2*CircusMusicTable)
    sts     song_base_l, ZL                 ; and save it
    sts     song_base_h, ZH

    sts     song_pointer_l, ZL              ; Initialize song pointer to the
    sts     song_pointer_h, ZH                  ; beginning

    rcall   LoadNextNote                    ; And start moving through table

EndStartGameMusic:
    ret                                     ; done so return

; ==============================================================================
;
; LoadNextNote
;
; Description:       This function is called while a song is playing, and only 
;                    intended to be called by the StartGameMusic function and 
;                    the CheckIfSongPlaying function. The function will index
;                    through the table of the current song being played, getting
;                    the next note and the next frequency, loading them in the 
;                    appropriate variables so that the speaker can play that 
;                    note next. Also checks to see if the song is over, and if 
;                    it is, it will start the song over again.
;
; Operation:         The function places the Z pointer at the saved last index
;                    of the most recent note played from the music table. Then
;                    it loads the next note frequency and duration from the 
;                    table into the appropriate variables (which will be used to
;                    with PlayNote and the CheckIfSongPlaying to play that note
;                    for the given duration). The function checks the loaded 
;                    values to see if we're at the end of the table (frequency
;                    is zero, and so is duration). If so, it will call the
;                    StartGameMusic function to loop the song again.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  current_freq_l/h - read and write. The current frequency to
;                                       play out of the speaker
;                    song_pointer_l/h - read and write. Points to where in the 
;                                       song table we are.
;                    note_duration_l/h - read and write. The duration in ms of 
;                                       the current note to play.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            Updates the frequency coming out of the speaker, indirect.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17, Z
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 16, 2025  -   comments
;
;       Special Notes: Used the LLM Claude by Anthropic in writing this function

LoadNextNote:
    lds     ZL, song_pointer_l      ; Load song pointer into Z
    lds     ZH, song_pointer_h
    
    lpm     r16, Z+                 ; Load frequency (first word in table)
    lpm     r17, Z+
    sts     current_freq_l, r16
    sts     current_freq_h, r17
    
    or      r16, r17                ; Check for end of song (freq & duration = 0)
    breq    CheckDuration           ; If frequency is 0, check duration
    rjmp    LoadDuration
    
CheckDuration:
    lpm     r16, Z+                 ; Frequency is 0, check if duration is also 
    lpm     r17, Z+                     ; zero (end of song)
    or      r16, r17
    breq    SongEnded               ; Both freq and duration are 0 - end of song
    
    sts     note_duration_l, r16    ; Otherwise, it's a rest note (freq = 0 but 
    sts     note_duration_h, r17        ; duration > 0), so do normal thing
    rjmp    UpdateSongPointer
    
LoadDuration:
    lpm     r16, Z+                 ; Load duration of the note (second word)
    lpm     r17, Z+
    sts     note_duration_l, r16
    sts     note_duration_h, r17
    
UpdateSongPointer:
    sts     song_pointer_l, ZL      ; Update song pointer for next note
    sts     song_pointer_h, ZH
    rjmp    EndLoadNextNote
    
SongEnded:
    rcall StartGameMusic            ; End of song reached - play again!!
    
EndLoadNextNote:
    ret


; ==============================================================================
;
; StopGameMusic
;
; Description:       Will turn off any song that is being played. It does this
;                    by resetting the song_playing flag, loading 0 into the 
;                    current frequency, and calls the PlayNote function with a
;                    argument of 0, which turns off the speaker.
;
; Operation:         Resets the song_playing flag, loads 0 into the 
;                    current frequency, and calls the PlayNote function with a
;                    argument of 0, which turns off the speaker.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  song_playing     - write only. Flag indicating a song is
;                                       now being played.
;                    current_freq_l/h - read and write. The current frequency to
;                                       play out of the speaker
;
; Global Variables:  None.
;
; Input:             None.
; Output:            Stops Playing Music out of the speaker.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, Z
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 16, 2025  -   comments
;
;       Special Notes: Used the LLM Claude by Anthropic in writing this function

StopGameMusic:
    ldi     r16, FALSE
    ldi     r17, 0                  ; to turn off the speaker (freq = 0)
    sts     song_playing, r16       ; Mark as not playing (reset flag)
    sts     current_freq_l, r16     ; Set frequency to 0 (silence)
    sts     current_freq_h, r16
    ldi     r17, 0                  ; just in case FALSE != 0
    rcall   PlayNote                ; call with R17|R16 = 0 to turn off speaker

EndStopGameMusic:
    ret

; ==============================================================================
;
; CircusMusicTable
;
; Description:      This table holds the notes to be played in a song, in order,
;                   to play circus music! It is two words wide, with the first
;                   word being the frequency of the next note to play and the 
;                   next word being the duration that that frequency should be
;                   played. The last entry in the table is a 0 for frequency and
;                   a zero for duration, indicating the end of the song.
;
; Author:           Benjamin Boone
; Last Modified:    6/16/2025   -   comments/org

CircusMusicTable:
    ; Measure 1
    .dw     REST,   SHORT_ACCENT        ; short break 
    .dw     C5,     STACCATO_QUARTER    ; C5 staccato quarter
    .dw     REST,   SHORT_ACCENT        ; short accent
    ;.dw     REST,   SHORT_ACCENT        ; but not two rests in a row
    .dw     B4,     STACCATO_QUARTER    ; B4 staccato quarter
    .dw     REST,   SHORT_ACCENT        ; short accent

    .dw     AS4,    EIGHTH_NOTE         ; can just read note/duration from table
    .dw     REST,   VERY_SHORT          ; break it up (to account for tonguing)
    .dw     B4,     EIGHTH_NOTE
    .dw     REST,   VERY_SHORT          ; break it up
    .dw     AS4,    EIGHTH_NOTE
    .dw     REST,   VERY_SHORT          ; break it up
    .dw     A4,     EIGHTH_NOTE
    ;.dw     REST,   VERY_SHORT          ; not two rests in a row


    ; Measure 2
    .dw     REST,   SHORT_ACCENT        ; short accent
    .dw     GS4,    STACCATO_QUARTER    ; G#4 staccato quarter
    .dw     REST,   SHORT_ACCENT        ; short accent
    ;.dw     REST,   SHORT_ACCENT        ; but not two rests in a row
    .dw     G4,     STACCATO_QUARTER    ; G4 staccato quater
    .dw     REST,   SHORT_ACCENT        ; short accent

    .dw     FS4,    LEGATO_QUARTER      ; legatto quarter
    .dw     G4,     LEGATO_QUARTER          ; maybe change to quarter
    ;.dw     REST,   VERY_SHORT         ; no two rests in a row


    ;Measure 3
    .dw     REST,   SHORT_ACCENT        
    .dw     A4,     STACCATO_QUARTER
    .dw     REST,   SHORT_ACCENT          
    ;.dw     REST,   SHORT_ACCENT        ; not two rests in a row    
    .dw     GS4,    STACCATO_QUARTER
    .dw     REST,   SHORT_ACCENT          

    .dw     G4,     EIGHTH_NOTE
    .dw     REST,   VERY_SHORT       
    .dw     GS4,    EIGHTH_NOTE
    .dw     REST,   VERY_SHORT        
    .dw     G4,     EIGHTH_NOTE
    .dw     REST,   VERY_SHORT     
    .dw     FS4,    EIGHTH_NOTE
    ;.dw     REST,   VERY_SHORT          ; not two rests in a row


    ;Measure 4
    .dw     REST,   SHORT_ACCENT          
    .dw     F4,     STACCATO_QUARTER
    .dw     REST,   SHORT_ACCENT        ; not two rests in a row    
    .dw     E4,     STACCATO_QUARTER
    .dw     REST,   SHORT_ACCENT          

    .dw     DS4,    LEGATO_QUARTER
    .dw     E4,     LEGATO_QUARTER      ; maybe change to quarter
    ;.dw     REST,   VERY_SHORT          ; not two rests in a row


    ;Measure 5
    .dw     REST,   SHORT_ACCENT          
    .dw     G4,     STACCATO_QUARTER
    .dw     REST,   SHORT_ACCENT          

    .dw     D4,     EIGHTH_NOTE
    .dw     REST,   VERY_SHORT        
    .dw     D4,     EIGHTH_NOTE
    .dw     REST,   VERY_SHORT        

    .dw     CS4,    LEGATO_QUARTER
    .dw     D4,     LEGATO_QUARTER      ; maybe change to quarter
    ;.dw     REST,   VERY_SHORT          ; not two rests in a row


    ;Measure 6, same as measure 5
    .dw     REST,   SHORT_ACCENT          
    .dw     G4,     STACCATO_QUARTER
    .dw     REST,   SHORT_ACCENT          

    .dw     D4,     EIGHTH_NOTE
    .dw     REST,   VERY_SHORT        
    .dw     D4,     EIGHTH_NOTE
    .dw     REST,   VERY_SHORT        

    .dw     CS4,    LEGATO_QUARTER
    .dw     D4,     LEGATO_QUARTER      ; maybe change to quarter
    ;.dw     REST,   VERY_SHORT          ; not two rests in a row
    

    ;Measure 7
    .dw     B3,     EIGHTH_NOTE         ; no breaks - slurred
    .dw     C4,     EIGHTH_NOTE
    .dw     CS4,    EIGHTH_NOTE
    .dw     D4,     EIGHTH_NOTE
    .dw     DS4,    EIGHTH_NOTE
    .dw     E4,     EIGHTH_NOTE
    .dw     F4,     EIGHTH_NOTE
    .dw     FS4,    EIGHTH_NOTE


    ;Measure 8
    .dw     G4,     EIGHTH_NOTE
    .dw     GS4,    EIGHTH_NOTE
    .dw     A4,     EIGHTH_NOTE
    .dw     B4,     EIGHTH_NOTE         ; 
    .dw     REST,   VERY_SHORT          ; short break between slurred sections

    .dw     A4,     LEGATO_QUARTER
    .dw     G4,     LEGATO_QUARTER          ; maybe change to regular quarter
    ;.dw     REST,   VERY_SHORT          ; not two rests in a row
    

    ; End of song
    .dw REST, 0                 ; End marker (REST = 0, and duration = 0)

; ==============================================================================
;
; CheckIfSongPlaying
;
; Description:       This function is meant to be called only during the Timer0
;					 compare match Event Handler. It is used to check the status
;					 of a song that is being played and update that songs state 
;                    after each note, updating the next note frequency and 
;                    duration to be played.
;
; Operation:         The function first checks the status of the song_playing 
;					 flag to see if a song is currently being played. If so,
;					 it will decrement the note duration counter, and if it
;					 reaches zero, will load the next note by calling the 
;                    LoadNextNote function. Then it will call the PlayNote 
;                    function with the new note to start outputting it.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  song_playing     - read only. Flag indicating a song is
;                                       now being played.
;                    current_freq_l/h - read only. The current frequency to
;                                       play out of the speaker
;                    note_duration_l/h - read and write. The duration in ms of 
;                                       the current note to play.
; Global Variables:  None.
;
; Input:             None.
; Output:            None directly, but may change the output of the speaker.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, Z
; Stack Depth:       5 bytes.
;
; Author:            Benjamin Boone
; Last Modified:     June 16, 2025  -   comments
;
;   Special Notes: Utilized the LLM Claude by Anthropic in writing this function


CheckIfSongPlaying:
    push 	r16                     ; save changed flags
    push 	r17
    push 	ZL
    push 	ZH
    in 		r16, SREG
    push 	r16                     ; Save status register
    
    ; Check if song is playing
    lds 	r16, song_playing       
    tst 	r16
    breq 	EndCheckIfSongPlaying   ; Exit if not playing
    
    ; Decrement note duration
    lds 	r16, note_duration_l    
    lds 	r17, note_duration_h
    subi 	r16, 1                  ; Subtract 1 from low byte
    sbci 	r17, 0                  ; Subtract with carry from high byte
    sts 	note_duration_l, r16
    sts 	note_duration_h, r17
    
    ; Check if duration reached zero
    or 		r16, r17
    brne 	EndCheckIfSongPlaying   ; Exit if duration not zero
    
    ; Duration reached zero - load next note
    rcall 	LoadNextNote
    
    ; Update the speaker with the new frequency
	lds 	r16, current_freq_l
	lds 	r17, current_freq_h
    rcall 	PlayNote
    
EndCheckIfSongPlaying:
    pop r16                         ; Restore status register and registers
    out SREG, r16               
    pop ZH
    pop ZL
    pop r17
    pop r16
    ret

; ==============================================================================
;
; PlaySoundBurst
;
; Description:       This function will play a note at a passed frequency (in 
;                    R17|R16) in Hz for a given duration passed in (R19|R18) (in 
;                    milliseconds).
;
; Operation:         First calls playNote with the given frequency. Then it 
;                    turns off interrupts for critical code, then sets the 
;                    sound burst counter to a time that will keep it on for 
;                    the given duration. It will set the burst_active flag.
;
; Arguments:         R17|R16    -   The frequency in Hz to play, with R17 as the
;                                   the high byte
;                    R19|R18    -   The duration in milliseconds to play for.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  burst_active     - write only. Indicates a sound is being 
;                                       played (briefly).
;                    burst_counter_L  - write only. The low half of the time 
;                                       tracker for a sound burst.
;                    burst_counter_H  - write only. The high half of the time
;                                       tracker for a sound burst.
; Global Variables:  None.
;
; Input:             None.
; Output:            Plays a tone for a period of time.
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

PlaySoundBurst:
    rcall   PlayNote                    ; start playing the freq (passed in)

    in      r0, sreg                    ; save SREG (critical code, these vars
    cli                                     ; changed in Event Handler)
    sts     burst_counter_L, r18        ; set the low and high bytes of the 
    sts     burst_counter_H, r19            ; duration to play for
    ldi     r17, TRUE                   ; and set the flag to active
    sts     burst_active, r17           
    out     sreg, r0                    ; end critical code protection

EndPlaySoundBurst:
    ret


; ==============================================================================
;
; CheckSoundBurst
;
; Description:       This function is meant to be called only during the Timer0
;					 compare match Event Handler. It is used to check the status
;					 of a sound that is to be played briefly and update that 
;					 sound's state if it's played for the right amount of time.
;
; Operation:         The function first checks the status of the burst_active 
;					 flag to see if a sound is currently being played. If so,
;					 it will decrement the burst counter, and if it reaches zero,
;					 will turn the sound off by calling the PlayNote function.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  burst_active 	-	read and write. Indicates a sound is 
;										being played as a burst.
;					 burst_counter_L/H 	-  read and write. Counter measuring how 
;										long a sound burst has been playing.
; Global Variables:  None.
;
; Input:             None.
; Output:            None directly, but will turn off a sound burst.
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

CheckSoundBurst:
    push 	r16
    push 	r17
    in 		r16, SREG
    push 	r16                  		; Save status register
    
    lds 	r16, burst_active			; Check if sound burst is active
    tst 	r16							
    breq 	EndCheckSoundBurst      	; Exit if not playing

    lds 	r16, burst_counter_L		; Decrement 16-bit burst counter
    lds 	r17, burst_counter_H
    subi 	r16, 1                 		; Subtract 1 from low byte
    sbci 	r17, 0                 		; Subtract with carry from high byte
    sts 	burst_counter_L, r16		; and make sure to save
    sts 	burst_counter_H, r17
    
	; Check if counter reached zero (both bytes must be zero)
    or 		r16, r17                 	; OR low and high bytes
    brne 	EndCheckSoundBurst       	; Exit if result is not zero

    ldi 	r16, 0						; Counter reached zero - turn off sound 
	ldi 	r17, 0
	rcall	PlayNote
	clr 	r16							
    sts 	flash_active, r17			; and reset the burst_active flag
    
EndCheckSoundBurst:
    pop r16
    out SREG, r16               		; Restore status register and others
    pop r17
    pop r16
	ret

; ##############################################################################
.dseg

; For Playing a short burst
burst_active:       .byte   1   ; flag indicating a short burst of sound playing
burst_counter_H:    .byte   1   ; plays sound for this number of ms, 
burst_counter_L:    .byte   1       ; two registers to hold longer bursts

; For Playing Game Music
song_pointer_l:     .byte   1   ; Current position in song table (low byte)
song_pointer_h:     .byte   1   ; Current position in song table (high byte)
note_duration_l:    .byte   1   ; Current note duration counter (low byte)
note_duration_h:    .byte   1   ; Current note duration counter (high byte)
current_freq_l:     .byte   1   ; Current note frequency (low byte)
current_freq_h:     .byte   1   ; Current note frequency (high byte)
song_playing:       .byte   1   ; Flag: 0 = stopped, 1 = playing
song_base_l:        .byte   1   ; Base address of current song (low byte)
song_base_h:        .byte   1   ; Base address of current song (high byte)
