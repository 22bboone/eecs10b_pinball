;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   SEGTABLE                                 ;
;                           Tables of 7-Segment Codes                        ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains tables of 7-segment codes.  The segment ordering is
; given below.  The tables included are:
;    ASCIISegTable - table of codes for 7-bit ASCII characters
;    DigitSegTable - table of codes for hexadecimal digits
;
; Revision History:
;     5/18/24  auto-generated           initial revision
;     5/18/24  Glen George              added DigitSegTable
;     6/12/25  Benjamin Boone           Added Indexing Comments

; local include files
;    none

;table is in the code segment
.cseg


; ASCIISegTable
;
; Description:      This is the segment pattern table for ASCII characters.
;                   It contains the active-high segment patterns for all
;                   possible 7-bit ASCII codes.  Codes which do not have a
;                   "reasonable" way of being displayed on a 7-segment display
;                   are left blank.  None of the codes set the decimal point.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Author:           auto-generated
; Last Modified:    May 18, 2024

ASCIISegTable:


;        DB       gfeedcba    gfeedcba   ; ASCII character

        .DB     0b00000000, 0b00000000   ; NUL, SOH
        .DB     0b00000000, 0b00000000   ; STX, ETX
        .DB     0b00000000, 0b00000000   ; EOT, ENQ
        .DB     0b00000000, 0b00000000   ; ACK, BEL
        .DB     0b00000000, 0b00000000   ; backspace, TAB
        .DB     0b00000000, 0b00000000   ; new line, vertical tab
        .DB     0b00000000, 0b00000000   ; form feed, carriage return
        .DB     0b00000000, 0b00000000   ; SO, SI
        .DB     0b00000000, 0b00000000   ; DLE, DC1
        .DB     0b00000000, 0b00000000   ; DC2, DC3
        .DB     0b00000000, 0b00000000   ; DC4, NAK
        .DB     0b00000000, 0b00000000   ; SYN, ETB
        .DB     0b00000000, 0b00000000   ; CAN, EM
        .DB     0b00000000, 0b00000000   ; SUB, escape
        .DB     0b00000000, 0b00000000   ; FS, GS
        .DB     0b00000000, 0b00000000   ; AS, US

;        DB       gfeedcba    gfeedcba   ; ASCII character

        .DB     0b00000000, 0b00000000   ; space, !
        .DB     0b01000010, 0b00000000   ; ", #
        .DB     0b00000000, 0b00000000   ; $, %
        .DB     0b00000000, 0b00000010   ; &, '
        .DB     0b01111001, 0b00001111   ; (, )
        .DB     0b00000000, 0b00000000   ; *, +
        .DB     0b00000000, 0b10000000   ; ,, -
        .DB     0b00000000, 0b00000000   ; ., /
        .DB     0b01111111, 0b00000110   ; 0, 1
        .DB     0b10111011, 0b10001111   ; 2, 3
        .DB     0b11000110, 0b11001101   ; 4, 5
        .DB     0b11111101, 0b00000111   ; 6, 7
        .DB     0b11111111, 0b11000111   ; 8, 9
        .DB     0b00000000, 0b00000000   ; :, ;
        .DB     0b00000000, 0b10001000   ; <, =
        .DB     0b00000000, 0b00000000   ; >, ?

;        DB       gfeedcba    gfeedcba   ; ASCII character

        .DB     0b10111111, 0b11110111   ; @, A                 64
        .DB     0b11111111, 0b01111001   ; B, C                 66
        .DB     0b01111111, 0b11111001   ; D, E                 68
        .DB     0b11110001, 0b11111101   ; F, G                 70				
        .DB     0b11110110, 0b00000110   ; H, I                 72
        .DB     0b00111110, 0b00000000   ; J, K                 74
        .DB     0b01111000, 0b00000000   ; L, M                 76
        .DB     0b00000000, 0b01111111   ; N, O                 78
        .DB     0b11110011, 0b00000000   ; P, Q                 80
        .DB     0b00000000, 0b11001101   ; R, S                 82
        .DB     0b00000000, 0b01111110   ; T, U                 84
        .DB     0b00000000, 0b00000000   ; V, W                 86
        .DB     0b00000000, 0b11000110   ; X, Y                 88
        .DB     0b00000000, 0b01111001   ; Z, [
        .DB     0b00000000, 0b00001111   ; \, ]
        .DB     0b00000000, 0b00001000   ; ^, _

;        DB       gfeedcba    gfeedcba   ; ASCII character

        .DB     0b01000000, 0b00000000   ; `, a			
        .DB     0b11111100, 0b10111000   ; b, c
        .DB     0b10111110, 0b00000000   ; d, e
        .DB     0b00000000, 0b11001111   ; f, g			102
        .DB     0b11110100, 0b00000100   ; h, i
        .DB     0b00000000, 0b00000000   ; j, k
        .DB     0b01110000, 0b00000000   ; l, m
        .DB     0b10110100, 0b10111100   ; n, o
        .DB     0b00000000, 0b00000000   ; p, q
        .DB     0b10110000, 0b00000000   ; r, s
        .DB     0b11111000, 0b00111100   ; t, u
        .DB     0b00000000, 0b00000000   ; v, w
        .DB     0b00000000, 0b11001110   ; x, y
        .DB     0b00000000, 0b00000000   ; z, {
        .DB     0b00000110, 0b00000000   ; |, }
        .DB     0b00000001, 0b00000000   ; ~, rubout




; DigitSegTable
;
; Description:      This is the segment pattern table for hexadecimal digits.
;                   It contains the active-high segment patterns for all hex
;                   digits (0123456789AbCdEF).  None of the codes set the
;                   decimal point.  
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Author:           Glen George
; Last Modified:    May 18, 2024

DigitSegTable:


;        DB       gfeedcba    gfeedcba   ; Hex Digit

        .DB     0b01111111, 0b00000110   ; 0, 1
        .DB     0b10111011, 0b10001111   ; 2, 3
        .DB     0b11000110, 0b11001101   ; 4, 5
        .DB     0b11111101, 0b00000111   ; 6, 7
        .DB     0b11111111, 0b11000111   ; 8, 9
        .DB     0b11110111, 0b11111100   ; A, b
        .DB     0b01111001, 0b10111110   ; C, d
        .DB     0b11111001, 0b11110001   ; E, F
