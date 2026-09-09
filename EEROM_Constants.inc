;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               EEROM_Constants.inc                          ;
;                                 Homework #3                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the assembly language definitions and constants used for                
; the EEROM functions for the pinball machine project as a part of EE/CS 10b, 
; Homework 4.
;
; Revision History:
;   5/30/2025    Benjamin Boone  Initial Revision of Constants
;   5/31/2025    Benjamin Boone  Added correct write instruction



; SPI Control Register Constants
;.equ    SET_MASTER  =   0b00010000  ; set the master bit in Atmega SPI
;.equ    SPI_ENABLE  =   0b01000000  ; enable SPI
;.equ    MSB_FIRST   =   0b00000000  ; set DORD to 0, MSB will shift out first
;.equ    CPOL_LOW    =   0b00000000  ; Set clock poloarity low (idle low)
;.equ    CPHA_HIGH   =   0b00000100  ; Set clock phase high (sample on falling edge)
;.equ    SPEED_128   =   0b00000011  ; arbitrary clock speed (clk/128)
                                     ;  note: it's ok to use any  > clk/8
; SPI Control register is set via m64def.inc definitions.



; For EEROM 
.equ    LAST_6_MASK = 0b00111111    ; save 6 bits of word address to add op code
.equ    MAX_EEROM_INDEX = 127       ; total number of bytes - 1 in EEROM
.equ 	MOD_2_MASK 	=  0b00000001 	; keep just the last bit to check parity

; for ReadSPI
.equ    START = 0b00000001          ; sending a 1 bit is a start for EEROM
.equ    READ_INSTR = 0b10000000     ; 10 is op code for read instruction
.equ    WRITE_INSTR = 0b01000000    ; 01 is op code for write instruction

; for Init
.equ    WRITE_ENABLE    =   0b10011000  ; start bit, then WEN op code (0011XXXX)


