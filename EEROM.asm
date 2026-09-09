;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  EEPROM.asm                                ;
;                                 Homework #4                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the functions for operating the SPI to read and write data
; to the 93C46 serial EEROM.
;   The public functions included are:
;       Init_SPI_EEROM      -   Initializes the Serial Periphial Interface used
;                               to access EEROM via PORTB.
;       ReadEEROM           -   Reads n bytes of data starting at a given 
;                               address in EEROM and stored at a given address
;                               in data memory.
;       WriteEEROM          -   Writes n bytes of data from data memory starting
;                               at a given address to a given address in EEROM.
;       ReadSPI             -   Helper function that reads in up to one word of 
;                               data from EEROM at a given address.
;       WriteSPI            -   Helper function which writes up to one word of 
;                               data given data to EEROM.
;       WaitForSPIF         -   Helper function to delay further operations  
;                               using the SPDR until the last SPDR values have 
;                               been sent (using the SPIF flag).
;                               
;
; Revision History:
;   5/30/2025    Benjamin Boone  Initial revision, implemented most functions
;   5/31/2025    Benjamin Boone  Added WriteSPI function, fixed bugs
;   6/3/2025     Benjamin Boone  Updated Comments
;   6/4/2025     Benjamin Boone  Actually fixed bugs (checked overflow, read and
;                                   write same order, addressing/shifting)



.cseg

; ==============================================================================
;
; Init_SPI_EEROM
;
; Description:       This function initializes the pins in Port B that are used 
;                    in the Serial EEROM interface. That is, it sets the !SS 
;                    (PB0), SCK (PB1), and MOSI (PB2) bits to outputs, and sets 
;                    the MISO (PB3) bit to an input. This function also sets the 
;                    appropriate bits in the SPI control register (SPCR) to set 
;                    the phase (0) and polarity (0) of the master SPI hardware.
;
; Operation:         Using defined constants, sets the SPI control register to 
;                    get desired polarity, phase, direction, and function in 
;                    general of the SPI. Then sets the first 3 bits of the DDRB 
;                    to high, and the fourth to low.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R20    -   Read and Write. Used for Temporary storage.
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
; Registers Changed: Flags, R20
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone                                                  
; Last Modified:     May 31, 2025

Init_SPI_EEROM:
	ldi     r20, (1<<SPE)|(1<<MSTR)|(0<<CPHA)|(1<<SPR1)|(1<<SPR0)
    out     SPCR, r20               ; set the control register for SPI

    sbi     DDRB, PB0               ; set !SS as an ouput (aka CS signal)
    sbi     DDRB, PB1               ; set SCK as an output
    sbi     DDRB, PB2               ; set MOSI as an output
    cbi     DDRB, PB3               ; set MISO as an input

EnableWritingEEROM:
    sbi     PORTB, PB0              ; set CS high
    ldi     r20, WRITE_ENABLE       ; code to eneable writing to EEROM
    out     SPDR, r20               ;   (includes start bit)
    rcall   WaitForSPIF             ; wait for it all to be sent
    ldi     r20, 0                  
    out     SPDR, r20               ; need more clocks for full instruction 
    rcall   WaitForSPIF             ; 
    cbi     PORTB, PB0              ; take CS down again
	nop
	nop
	nop

EndInit_SPI_EEROM:
    ret 



; ==============================================================================
;
; ReadEEROM
;
; Description:       The function reads n bytes (0-128) of data from the 93C46                  
;                    serial EEROM at the passed byte address (addrEE (0-127)).                 
;                    The data is stored at the passed data address (d_addr). The 
;                    number of bytes (n) is passed in R16 by value, the 
;                    EEROM byte address (addrEE) is passed in R17 by value, and 
;                    the address at which to store the data (d_addr) is passed 
;                    in Y (R29|R28) by value (in other words the buffer is 
;                    passed by reference). It is assumed that there is enough 
;                    free memory at the passed address to store the bytes read 
;                    by the procedure.
;
; Operation:         The function first checks whether the requested address to 
;                    be read from, and the number of bytes, is consistent with 
;                    the amount of data that is available to be read in the 
;                    EEROM. If so, it continues (otherwise it does nothing). 
;                    Then the function gets the word- address (0-63) that the 
;                    byte address, addrEE (0-127), corresponds to in the EEROM. 
;                    The function reads the high and low bytes of the word at 
;                    address (by calling the Read_SPI() function, and stores the 
;                    needed bytes as specified by the arguments. This is done in 
;                    a while loop, which decrements the number of bytes left to 
;                    read, and increments address, until n bytes have been read, 
;                    in order, starting at the byte address addrEE in the EEROM. 
;                    For each iteration, the function checks which of the two 
;                    bytes read need to be stored (just the low, both, or just 
;                    the high). 
;
; Arguments:         addrEE - A number between 0 and 127 representing the byte 
;                             address in EEROM. Because EEROM uses word 
;                             addressing, (0 to 63), an even byte address 
;                             corresponds to the low byte of the word at EEROM 
;                             address addrEE / 2, and an odd byte address 
;                             corresponds to the high byte of the word at the 
;                             same address. Passed in R17. 
;                    n     -  A number of bytes between 0 and 128 to read into 
;                             memory from EEROM. Passed in R16.
;                    d_addr - A 16 bit address indicating where to start storing 
;                             the bytes read from the EEROM. Passed in the Y 
;                             register (R29|R28).
; Return Value:      Data is written to memory, but no values are returned in 
;                    registers.
;
; Local Variables:   None.
; Shared Variables:  address - write only (and send to another function to read). 
;                              Represents the EEROM word address (0-63) to read. 
;                              Stored in R19. Shared with the Read_SPI() function.
;                    Y (d_addr) - read and write the Y-register, used to hold 
;                              location to store next byte at in data memory.
;                    R22 -     read only. Holds the high byte of the word read 
;                              from EEROM. Shared with the Read_SPI() function.
;                    R21 -     read only. Holds the low byte of the word read  
;                              from EEROM. Shared with the Read_SPI() function.
;
; Input:             None.
; Output:            Outputs serial signals through Port B to the NM93C46 Serial 
;                    EEROM. 
;
; Error Handling:    If n_bytes + addrEE > 127, this function does nothing, as 
;                    it would require reading outside the number of bytes stored 
;                    in the EEROM. Overflow is also checked.
; Limitations:       It is assumed that there is enough free memory at the 
;                    passed address to store the bytes read by the procedure.
;
; Algorithms:        None.
; Data Structures:   Accesses EEROM.
;
; Registers Changed: flags, Y, R18, R19, R20, R21, R22
; Stack Depth:       5 bytes.
;
; Author:            Benjamin Boone
; Last Modified:     June 4, 2025
;

ReadEEROM:
	
	push 	r18                     ; push changed registers to stack just 
	push 	r19                         ; in case (actually not necessary).
	push 	r20
	push 	r21
	push 	r22

CheckReadEEROMConditions:           ; check all bytes to be read are in bounds
    mov     r20, r16                                                            
    add     r20, r17
    brcs    EndReadEEROM           ; check overflow
    cpi     r20, MAX_EEROM_INDEX + 2	; plus two so that reading 1 byte at 
    brsh    EndReadEEROM                ; address 127 is ok


ReadEEROMWhileLoop:   

;GetAddressReadEEROM:
    mov     r19, r17                ; should update word address in loop
    lsr     r19                     ; divide addrEE to get the word address
    
    tst     r16                     ; conditional (are we done reading?)
    breq    EndReadWhileLoop        ;   repeat while n_bytes (R16) > 0

    rcall   ReadSPI                 ; read word from EEROM to R22|R21

    ; if statement
    mov     r18, r17                ; find parity of address to check how many 
    andi    r18, MOD_2_MASK         ;   bytes to read from each word, based on 
    brne    ReadOddAddress          ;   current address we're reading
    cpi     r16, 1                  ; if we're at an even address, check the
    breq    ReadOneEvenAddress      ;   number of bytes to read (1 or >1)
   ;brne    ReadTwoBytes

ReadTwoBytes:
    st      Y+, r22                 ; save both bytes, high then low
    st      Y+, r21
    subi    r16, 2                  ; two less bytes to read
    subi    r17, -2                 ; move address up by two 
    rjmp    IncrementAddressReadLoop

ReadOddAddress:
    st      Y+, r21                 ; save the low byte
    dec     r16                     ; 1 less byte to read left
    inc     r17                     ; move one address up
    rjmp    IncrementAddressReadLoop

ReadOneEvenAddress:
    st      Y+, r22                 ;store just the high byte
    dec     r16
    inc     r17
    rjmp    IncrementAddressReadLoop

IncrementAddressReadLoop:
;	inc     r19                     ; increment the word address for next loop
	rjmp 	ReadEEROMWhileLoop

EndReadWhileLoop:                   ; done so finish. Keeping label in case
    ;rjmp   EndReadEEROM            ;   need to change functionality in future

EndReadEEROM:                       ; done, pop the stack.
	pop 	r22
	pop 	r21
	pop 	r20
	pop 	r19
	pop 	r18
    ret                             ; and return

    
; ==============================================================================
; 
; Read_SPI
;
; Description:       This helper function will read the 16-bit word in the EEROM 
;                    at the address passed in R19 and stores it in two registers 
;                    (R22|R21) with the high byte in R22. 
;
; Operation:         Sets the CS/!SS signal, combines the Read instruction with 
;                    address, sends a start signal and the byte with the read 
;                    signal and address to the EEROM. Sends 0s through the SPDR 
;                    to load the values to read into the SPDR and places those 
;                    read values into R22|R21 one after each other. Of course, 
;                    after each byte sent through the SPDR the function waits 
;                    for the full transmission to finish.
;
; Arguments:         address - an 8 bit value with the low 6 bits representing 
;                              an address in EEROM to be read. Passed in an 
;                              8-bit register, R19.
; Return Value:      Returns a 16 bit value that was stored in EEROM at address 
;                    in the registers R22|R21 with the high byte in R22.
;
; Local Variables:   R18    -   Read and Write. Stores temporary values             
; Shared Variables:  address -  read and write. Changed to include the read the
;                               op code for the EEROM before the address. 
;                               Represents the word address (0-63) to read. 
;                               Stored in R19. Shared with ReadEEROM().
;                    R22    -   write only. Holds the high byte of the word read  
;                               from EEROM. Shared with ReadEEROM().
;                    R21    -   write only. Holds the low byte of the word read  
;                               from EEROM. Shared with ReadEEROM().
;
; Input:             Receives serial information read from the EEROM through 
;                    Port B.
; Output:            Sends serial information out of Port B through the SPI 
;                    interface to the NM93C46 Serial EEROM. 
;
; Error Handling:    None. If upper level function operates correctly, don't
;                    need to worry about.
;
; Algorithms:        None.
; Data Structures:   Accesses EEROM.
;
; Registers Changed: flags, R22, R21, R20, R18
; Stack Depth:       2 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 3, 2025

ReadSPI:
	push 	r18                     ; save to stack just in case (unnessecary)
	push 	r20
    sbi     PORTB, PB0              ; start by sending CS/!SS signal high
	nop
	nop
	nop
	nop
	nop

MakeInstructionAddress:
    andi    r19, LAST_6_MASK        ; get only just the address
    ori     r19, READ_INSTR         ; put read instruction at front

    ldi     r18, START              ; tell eerom about to send an instruction

;Shift:          ; Note: No need to shift when CPHA High. Comment if High.
	lsl 	r19						; put top bit into carry
	rol 	r18 					; put that top bit now in bottom of r18

    out     SPDR, r18 
    rcall   WaitForSPIF             ; wait for instruction to send

    out     SPDR, r19               ; send actual instruction with address
    rcall   WaitForSPIF             ; wait

    ldi     r20, 0                  ; then get high byte of word in eerom
    out     SPDR, r20
    rcall   WaitForSPIF             ; wait
	mov 	r22, r18                

    out     SPDR, r20               ; and get low byte of word in eerom
    rcall   WaitForSPIF             ; wait
	mov 	r21, r18                
	
	lsr 	r19 					; revert to original (after shifting it)
	nop
	nop
	nop
	nop
	nop
    cbi     PORTB, PB0              ; reset CS (!SS) to low to finish reading

EndReadSPI:            
	pop		r20                     ; pop stack
	pop		r18
    ret                             ; done so return


; ==============================================================================
;
; WaitForSPIF
;
; Description:       This is a blocking function which waits for the SBIF flag 
;                    to be set, and then returns. No functional operation. 
;
; Operation:         The function continually checks the value of the SBIF flag 
;                    in the SPI Status Register until the SBIF flag is not zero 
;                    (set). Reads in the SPDR to R18 to reset the SPIF flag, 
;                    then returns.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  SPSR register - read only (SPIF Flag)
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, SPSR, r18
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 4, 2025

WaitForSPIF:
    sbis    SPSR, SPIF              ; keep checking until it's set
    rjmp    WaitForSPIF
	in 		r18, SPDR               ; read in from SPDR to clear SPIF flag

EndWaitForSPIF:
    ret         




; ==============================================================================
;
; WriteEEROM
;
; Description:       The function writes n bytes (0-128) of data to the 93C46 
;                    serial EEROM at the passed byte address (addrEE (0-127)). 
;                    The data to be written is located at the passed data 
;                    address (d_addr). The number of bytes (n_bytes) is passed 
;                    in R16 by value, the EEROM byte address (addrEE) is passed 
;                    in R17 by value, and the address where the data to be 
;                    written is stored (d_addr) is passed in Y (R29|R28) by 
;                    value (in other words the buffer is passed by reference).
;
; Operation:         The function first checks the Error Handling conditions 
;                    (see Error Handling). Next, the function enters a 
;                    while loop which gets the word at the word address
;                    corresponding to the byte given by addrEE via the 
;                    Read_SPI() function. Then, based on the values of n, 
;                    addrEE, and how many bytes we have left to write, the EEROM                
;                    is written, starting at the byte address addrEE with the 
;                    values stored in data memory starting at d_addr. After each 
;                    byte is stored, the Y register is incremented, and so is 
;                    the word address. This is done until the number of bytes 
;                    indicated by the argument have been stored. 
;
; Arguments:         addrEE - A number between 0 and 127 representing the byte 
;                             address in EEROM to write. Because EEROM uses word 
;                             addressing, (0 to 63), an even byte address 
;                             corresponds to the low byte of the word at EEROM 
;                             address addrEE / 2, and an odd byte address 
;                             corresponds to the high byte of the word at the 
;                             same address. Passed in R17. 
;                    n     -  A number of bytes between 0 and 128 to write to 
;                             memory in EEROM. Passed in R16.
;                    d_addr - A 16 bit address indicating where to start reading 
;                             the bytes to write to the EEROM. Passed in the Y 
;                             register (R29|R28).
; Return Value:      None.
;
; Local Variables:   R18    -   write only. Temporary holder.
; Shared Variables:  address -  write only. Represents the EEROM word address 
;                               (0-63) to write to. Stored in R19. Shared with 
;                               the Read_SPI() function.
;                    Y (d_addr) - read and write the Y-register, used to hold 
;                               location to store next byte at in data memory.
;                    R22 - read only. Holds the high byte of the word read from 
;                               EEROM. Shared with the Read_SPI() function.
;                    R21 - read only. Holds the low byte of the word read from 
;                               EEROM. Shared with the Read_SPI() function.
;
; Input:             Serial I/O data goes back and forth between the EEROM and 
;                    the micorcontroller via PORTB during reading and writing.
; Output:            Outputs serial signals through Port B to the NM93C46 Serial 
;                    EEROM. 
; 
; Error Handling:    If n_bytes + addrEE > 127, this function does nothing, as 
;                    it would require reading outside the number of bytes stored 
;                    in the EEROM. Checks for overflow as well.
; Limitations:       It is assumed that there is enough free memory at the 
;                    passed address to store the bytes read by the procedure.
;
; Algorithms:        None.
; Data Structures:   Accesses EEROM.
;
; Registers Changed: flags, Y, R18, R19, R20, R21, R22
; Stack Depth:       0 bytes.
;
; Author:            Benjamin Boone
; Last Modified:     June 4, 2025
;

WriteEEROM:
	push 	r18                     ; pop the stack (unnessecary)
	push 	r19
	push 	r20
	push 	r21
	push 	r22

CheckWriteEEROMConditions:          ; check all bytes to be read are in bounds              
    mov     r20, r16                                                              
    add     r20, r17
    brcs    EndWriteEEROM           ; check overflow
    cpi     r20, MAX_EEROM_INDEX + 2    ; plus two so that reading 1 byte at
    brsh    EndWriteEEROM               ;   address 127 is ok


WriteEEROMWhileLoop:     

;GetAddressWriteEEROM:              
    mov     r19, r17                ; should update word address in loop
    lsr     r19                     ; divide addrEE to get the word address

    tst     r16                     ; check if done writing 
    breq    EndWriteWhileLoop       ;   repeat while n_bytes (R16) > 0

    rcall   ReadSPI                 ; read word from EEROM to R22|R21

    ; if statement
    mov     r18, r17                ; find parity of byte address to check how 
    andi    r18, MOD_2_MASK         ;   many bytes to write to each word, based 
    brne    WriteOddAddress         ;   on current address (byte) we're reading
    cpi     r16, 1                  ; if we're at an even address, check the
    breq    WriteOneEvenAddress     ;   number of bytes to write (1 or >1)
   ;brne    WriteTwoBytes

WriteTwoBytes:
    ld      r22, Y+                 ; write both bytes
    ld      r21, Y+
    subi    r16, 2                  ; two less bytes to write
    subi    r17, -2                 ; move address up by two 
    rjmp    WriteBackToEEROM

WriteOddAddress:
    ld      r21, Y+                 ; write the low byte
    dec     r16                     ; 1 less byte to write left
    inc     r17                     ; move one address up
    rjmp    WriteBackToEEROM

WriteOneEvenAddress:
    ld      r22, Y+                 ; write just the high byte
    dec     r16
    inc     r17
    ;rjmp    WriteBackToEEROM

WriteBackToEEROM:                   ; write the new registers r21 and r22 to  
    rcall   WriteSPI                ;   eerom at word address (R19)
    ;inc     r19                     ; increment the word address for next loop
    rjmp    WriteEEROMWhileLoop

EndWriteWhileLoop:                  ; done so finish. Keeping label in case need 
    ;rjmp   EndReadEEROM            ;   to change functionality in future

EndWriteEEROM:
	pop 	r22                     ; pop the stack
	pop 	r21
	pop 	r20
	pop 	r19
	pop 	r18
    ret                             ; and return 

; ==============================================================================
; 
; WriteSPI
;
; Description:       This helper function will write a 16 bit value, wr_word, 
;                    passed in R22|R21 (high byte in R22), to the EEROM at the 
;                    address, passed in R19.
;
; Operation:         The function first turns on the CS/!SS signal, then sends a 
;                    start bit to the EEROM followed by a write code and the 
;                    address to write to. After each byte sent through the SPDR 
;                    the function waits for the full transmission to finish. 
;                    Then the values in R22|R21 are passed in, one at a time, 
;                    through the SPDR. Then the CS/!SS signal is brought low 
;                    before any more clocking. Then we clock several times, turn 
;                    the CS/!SS signal back high, and then send in 0s through 
;                    the SPDR to clock the EEROM until it has finished writing 
;                    (which is indicating by 1s being sent back to the SPDR. 
;
; Arguments:         address - an 8 bit value with the low 6 bits representing 
;                              an address in EEROM to be read. Passed in an 
;                              8-bit register, R19.
; Return Value:      None.
;
; Local Variables:   R18    -   read and write. Stores temporary values         
; Shared Variables:  address -  read and write. Changed to include the write 
;                               op code for the EEROM before the address. 
;                               Represents the EEROM word address to read. 
;                               Stored in R19. Shared with WriteEEROM().
;                    R22    -   write only. Holds the high byte of the word to  
;                               be written to EEROM. Shared with WriteEEROM().
;                    R21    -   write only. Holds the low byte of the word to 
;                               be written to EEROM. Shared with WriteEEROM().
;
; Input:             Receives serial information read from the EEROM through 
;                    Port B.
; Output:            Sends serial information out of Port B through the SPI 
;                    interface to the NM93C46 Serial EEROM. 
;
; Error Handling:    None. Assumes higher level function works as intended.   
;
; Algorithms:        None.
; Data Structures:   Accesses EEROM.
;
; Registers Changed: flags, R22, R21, R19, R18
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 3, 2025

WriteSPI:
	push 	r18                     ; save to stack just in case (unnessecary)
    sbi     PORTB, PB0              ; start by sending CS/!SS signal high

MakeWriteInstructionAddress:
    andi    r19, LAST_6_MASK        ; get just the address
    ori     r19, WRITE_INSTR        ; put write instruction at front

    ldi     r18, START              ; tell eerom about to send a instruction
    out     SPDR, r18 
    rcall   WaitForSPIF             ; wait for instruction to send

    out     SPDR, r19               ; send actual instruction with address
    rcall   WaitForSPIF             ; wait

    out     SPDR, r22               ; send the high byte to be written to EEROM
    rcall   WaitForSPIF             ; wait

    out     SPDR, r21               ; send low byte to be written to EEROM
    rcall   WaitForSPIF             ; wait

    cbi     PORTB, PB0              ; reset CS low to signal to EEROM to start 
    nop                             ;   the writing procedure
	nop                             ; Must be down for a few of CPU clocks to 
	nop                             ;   ensure that EEROM registers the change
	nop
	nop
	nop
	nop

	sbi     PORTB, PB0	            ; turn on CS signal again for EEROM to 
    nop                             ;   signal when writing is finished
	nop
	nop								; delay time so that it works
	nop
	nop
	nop
	nop

WriteSPILoop:
	sbis 	PINB, PB3               ; wait for EEROM to tell us that writing is 
    rjmp    WriteSPILoop            ;   finished
	;rjmp    EndWriteSPILoop	

EndWriteSPILoop:
    cbi     PORTB, PB0              ; CS signal low again to finish full write
    ;rjmp   EndWriteSPI             ;   instruction

EndWriteSPI:            
	pop		r18                     ; pop the stack
    ret                             ; done so return
