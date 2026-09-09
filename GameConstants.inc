;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               GameConstants.inc                            ;
;                                 Homework #5                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the assembly language definitions and constants used for
; the main game functions for the pinball machine. Most are constants used for 
; general logic, light or actuator activation, or playing sound.
;
; Revision History:
;   6/12/2025    Benjamin Boone  Initialized needed constants
;   5/11/2026    Benjamin Boone  Updated constants to reflect actual board.
;                                   Commented out lights not used
;

; general                       ; commented because defined elsewhere
;.equ    TRUE    =   $FF            ; but these are the same definitions
;.equ    FALSE   =   0  

.equ    LEFT =   FALSE          ; used for all directional conditions, to check
.equ    RIGHT  =   TRUE         ; toggled 'flags', Left is False and Right True

; for the Start Button
.equ    BALLS_TO_START  =   5       ; the num of balls each player starts with
.equ    FLASH_1_SEC     =   1000    ; the number of milliseconds want 
                                        ; to flash, assuming CLK/32 prescale.
.equ    FLASH_QUARTER_SEC   =   250 ; the num ms want to flash, as above

; for the Table
.equ    MAX_GAMES   =   $99     ; The max number of games (in BCD)
.equ    DNSND       =   440     ; The sound freq to be played when go in drain

; for the Card Buttons
.equ    ACE1LIGHT   =   24      ; The light for the 1st Ace Card Sensor
.equ    ACE2LIGHT   =   28      ; The light for the 2nd Ace Card Sensor 
.equ    ACE3LIGHT   =   27      ; The light for the 3rd Ace Card Sensor
.equ    ACE4LIGHT   =   30      ; The light for the 4th Ace Card Sensor

.equ    KING1LIGHT  =   37      ; The light for the 1st King Card Sensor
.equ    KING2LIGHT  =   36      ; The light for the 2nd King Card Sensor
.equ    KING3LIGHT  =   32      ; The light for the 3rd King Card Sensor
.equ    KING4LIGHT  =   33      ; The light for the 4th King Card Sensor

.equ    ACE1BIT0    =   0       ; The bit for the 1st Ace Card Sensor
.equ    ACE1BIT1    =   1       ; The bit for the 2nd Ace Card Sensor
.equ    ACE1BIT2    =   2       ; The bit for the 3rd Ace Card Sensor
.equ    ACE1BIT3    =   3       ; The bit for the 4th Ace Card Sensor
.equ    KING1BIT4   =   4       ; The bit for the 1st King Card Sensor
.equ    KING2BIT5   =   5       ; The bit for the 2nd King Card Sensor
.equ    KING3BIT6   =   6       ; The bit for the 3rd King Card Sensor
.equ    KING4BIT7   =   7       ; The bit for the 4th King Card Sensor

.equ    ACES_SIDE   =   $0F     ; Mask to keep only the Aces bits in cardBuffer
.equ    ALL_4_ACES  =   $0F     ; Constant to Compare against, if all Aces hit
.equ    KINGS_SIDE  =   $F0     ; Mask to keep only the kings bits in cardBuffer
.equ    ALL_4_KINGS =   $F0     ; Constant to Compare against, if all Kings hit

.equ    KINGS_FREE_BALL_LIGHT   =   38  ; light says free ball on kings side
.equ    ACES_FREE_BALL_LIGHT    =   25  ; light says free ball on aces side


; for the rotating bumper
.equ    CW_LIGHT_0  = 8         ; 1st Light in sequence for CW rotation bumper
.equ    CW_LIGHT_1  = 9         ; 2nd Light in sequence for CW rotation bumper
.equ    CW_LIGHT_2  = 10        ; 3rd Light in sequence for CW rotation bumper
.equ    CW_LIGHT_3  = 11        ; 4th Light in sequence for CW rotation bumper
.equ    CW_LIGHT_4  = 6         ; 5th Light in sequence for CW rotation bumper
.equ    CW_LIGHT_5  = 5         ; 6th Light in sequence for CW rotation bumper
.equ    CW_LIGHT_6  = 4         ; 7th Light in sequence for CW rotation bumper
.equ    CW_LIGHT_7  = 0         ; 8th Light in sequence for CW rotation bumper
.equ    CW_LIGHT_8  = 1         ; 9th Light in sequence for CW rotation bumper
.equ    CW_LIGHT_9  = 2         ; 10th Light in sequence for CW rotation bumper

.equ    CCW_LIGHT_0  = 12       ; 1st Light in sequence for CCW rotation bumper 
.equ    CCW_LIGHT_1  = 13       ; 2nd Light in sequence for CCW rotation bumper
.equ    CCW_LIGHT_2  = 14       ; 3rd Light in sequence for CCW rotation bumper 
.equ    CCW_LIGHT_3  = 19       ; 4th Light in sequence for CCW rotation bumper
.equ    CCW_LIGHT_4  = 18       ; 5th Light in sequence for CCW rotation bumper 
.equ    CCW_LIGHT_5  = 17       ; 6th Light in sequence for CCW rotation bumper
.equ    CCW_LIGHT_6  = 16       ; 7th Light in sequence for CCW rotation bumper 
.equ    CCW_LIGHT_7  = 20       ; 8th Light in sequence for CCW rotation bumper
.equ    CCW_LIGHT_8  = 21       ; 9th Light in sequence for CCW rotation bumper 
.equ    CCW_LIGHT_9  = 22       ; 10th Light in sequence for CCW rotation bumper

.equ    PT_INDEX_MAX = 10       ; Maximum value for the free ball multiplier

; for the Free Ball Targets
.equ    LEFT_FB     =   FALSE   ; 'flag' value meaning the left target was hit
.equ    RIGHT_FB    =   TRUE    ; 'flag' value meaning the right target was hit


; .equ    SAMEPLAYER_LIGHT = 39   ; Light telling user the same player go again (free ball)
    ; don't control this in real game

; for the General Leaf Bumpers
    ; Apparently we don't control these lights?
; .equ    G_LIGHT1   = 40         ; Light code for the 1st general leaf bumper  
; .equ    G_LIGHT2   = 41         ; Light code for the 2nd general leaf bumper  
; .equ    G_LIGHT3   = 42         ; Light code for the 3rd general leaf bumper  
; .equ    G_LIGHT4   = 43         ; Light code for the 4th general leaf bumper 

; for the Pop Bumpers
    ; Apparently we don't control these lights
; .equ    POPLIGHT1  = 6          ; light code for the 1st pop bumper
; .equ    POPLIGHT2  = 7          ; light code for the 1st pop bumper
; .equ    POPLIGHT3  = 8          ; light code for the 1st pop bumper

; others (load ball actuator and bonus lights)
; .equ    LOAD_BALL_ACTUATOR   =   1       ; the actuator number that will control 
                                            ; loading the ball into the launcher
                                            ; Apparently don't control
.equ    LEFT_ROLLOVER_LIGHT =   35       ; left rollover light index (bonus)
.equ    RIGHT_ROLLOVER_LIGHT =  34       ; right rollover light index (bonus)
.equ    LEFT_ROT_BONUS_LIGHT =  26       ; left rotating bumper light index
.equ    RIGHT_ROT_BONUS_LIGHT = 39       ; right rotating bumper light index


; for EEROM constants
.equ    HIGH_EEROM_ADDR     =   0   ; Address where High Score is kept in EEROM
.equ    GAMES_EEROM_ADDR    =   2   ; Address where Games Left is kept in EEROM
.equ    HSCORE_BYTE_LENGTH  =   2   ; Length of high Score in bytes
.equ    GAMES_BYTE_LENGTH   =   1   ; Length of the games_left in bytes