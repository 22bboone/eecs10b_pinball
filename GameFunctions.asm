;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              GameFunctions.asm                             ;
;                                 Homework #5                                ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;                                Benjamin Boone                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the functions for running the main game loop and operating
;   the pinball machine. Also includes several tables.
;   The public functions included are:
;       PowerOnInit -   This will call all needed initialization functions for
;                       pinball machine operation, and initialize other game
;                       variables.
;       InitNewRound -  This function will reset any variables that change 
;                       round to round. Will reset lights as well.
;       GameLoop    -   This is the main game loop for the pinball machine and 
;                       will operate by continually checking whether a sensor is
;                       down, then use table driven code to operate on it.
;       AddGame     -   Function for a Add Game Button Press. Increments Games
;       StartButton -   Handles all cases for the start button bring pressed.
;                       Will start a new game and it's music.
;       SwiLeaf     -   Function for when the switch bonus leaf buttons are hit.
;       TopRoll     -   Function handling TopRollover Buttons being pressed.
;       DrainButton -   Handles all operations for when the ball goes down the
;                       drain in the pinball machine. Tracks rounds and games,
;                       and other game-play variables and sound.
;       CardButton  -   Function for whenever a card button is pressed. Handles
;                       Used with the Free Ball Function.
;       RotButton   -   Function for the rotating bumper being hit. Controls the 
;                       multiplier points for the Free Ball Buttons.
;       FreeBallHit -   Handles when the ball hits the free ball sensor, both
;                       points and receiving an extra ball, based on the 
;                       rotating bumper and card buttons, respectively.
;       GenLeaf     -   Function for hits to the general leaf bumpers.
;       PopBumper   -   Function for hits to the pop bumpers.
;       LowRoll     -   Function for hits to the Bottom Rollover Sensors.
;       TiltSensor  -   Function for when someone tries to tilt the machine.
;                       Turns of ability to score for the round.
;
;
;   Data Tables included are:
;       ResetLightsTable    -   Table of lights to reset when initiating a new 
;                               round. Only called by InitNewRound.
;       SensorTable         -   Table of all the functions to be called from 
;                               button presses, organized by index, also 
;                               includes arguments.
;       CW_Tb               -   Table containing lights to be turned on by any
;                               Clockwise Rotation of the Rotating Bumper.
;       CCWTb               -   Table containing lights to be turned on by any
;                               CounterClockwise rotation of the rotating bumper.
;
;   
; Revision History:
;   6/12/2025   Benjamin Boone  Initial revision
;   6/13/2025   Benjamin Boone  Added several functions for button presses
;   6/14/2025   Benjamin Boone  Updated functions and commentary.
;   6/16/2025   Benjamin Boone  Updated comments, made look nice(er).
;   5/11/2026   Benjamin Boone  Updated functions and tables to reflect actual 
;                                   board. Updated comments to reflect changes 
;                                   (mostly). Now just can't press the flippers
;                                   while ball is on the field since they are 
;                                   the start and add game buttons. 

.cseg

; ==============================================================================
;
; PowerOnInit
;
; Description:       After the stack is initialized and the interrupt vector set
;                    up, this function is the very first code in the program. It 
;                    makes use of other functions already defined to initialize
;                    all the game input and output (sensors, display, sound), 
;                    and then initializes game play variables, gets the high  
;                    score and games from EEROM, and then displays a wecome 
;                    message "PLAY" with the number of games left via the 
;                    DisplayPlayGame function.
;
; Operation:         Initializes all input and output by calling appropriate 
;                    functions as described above, initializes the timer for
;                    interrupts, intializes all game variables, reads in high 
;                    score and games left from EEROM, and calls the 
;                    DisplayPlayGame function.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  game_active  -  write only. Flag indicating whether there 
;                                    is a game currently in play.
;                    any_sensor_hit  -  write only. Flag indicating whether any 
;                                    sensor has been hit yet (used to determine 
;                                    whether we can toggle between 1 and 2 
;                                    players).
;
; Global Variables:  None.
;
; Input:             Power On.
; Output:            Displays "PLAY" on the Player 1 display and shows the 
;                    number of available games on the player 2 display.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 16, 2025

PowerOnInit:    
    rcall   Init_SPI_EEROM              ; init  EEROM

    rcall   InitButtonPorts             ; init Sensors
    rcall   InitScanAndDebounceVars

    rcall   InitDisplayPorts            ; init Display
    rcall   InitDisplay

    rcall   InitSound                   ; init Sound

    rcall   InitTimer0                  ; init the timer used for interrupts

	clr 	r16					        ; init game play variables
	sts 	numPlayers, r16

    ldi     r16, FALSE                  ; and flags
	sts 	game_active, r16
	sts 	any_sensor_hit, r16
    sts     song_playing, r16
    
    rcall   InitNewRound                ; reset lights and round variables
    
    rcall   GetHighScore                ; Read in high score and games left 
    rcall   GetGamesLeft                    ; vars from EEROM
    rcall 	DisplayPlayGame             ; And display welcome message!

EndPowerOnInit:     
    ret                                 ; done so return

; ==============================================================================
;
; InitNewRound
;
; Description:       This function is the very first code in the program. It 
;                    initializes the stack, initializes everything else by calling 
;                    their initialization functions, gets the high score, 
;                    initializes shared variables, and then calls the 
;                    WaitForGame() function when everything is ready.
;
; Operation:         Clears the display by calling the clearDisplay function, 
;                    then initializes the first column to set in the mux, as  
;                    well as the first digit and column that Port A and D will 
;                    display when lit.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  game_active  -  write only. Flag indicating whether there 
;                                    is a game currently in play.
;                    any_sensor_hit  -  write only. Flag indicating whether any 
;                                    sensor has been hit yet (used to determine 
;                                    whether we can toggle between 1 and 2 
;                                    players).
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
; Registers Changed: Flags, R23
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

InitNewRound:
    clr     r16                         ; Reset the variables which change
    ldi     r17, FALSE                      ; between rounds
    ldi     r18, 1
    sts     cardBuffer, r16             ; Blank the cardBuffer
    sts     TiltFlag, r17               ; Reset Flags
    sts     freeB_AcesL, r17
    sts     freeB_KingsR, r17
    sts     SamePlayerAgain, r17
    sts     KingPtIndex_CW_R, r18       ; And set point multiplier to 1
    sts     AcePtIndex_CCW_L, r18

ResetLightsNewRound:
    ldi	    ZL, low(2 * ResetLightsTable)	; get start of table (multiply by 2
	ldi     ZH, high(2 * ResetLightsTable)       ; for byte addressing)
    clr     r22

ResetLightsLoop:
    cpi     r22, RESET_TABLE_LENGTH     ; check to see when done with table
    breq    TurnOnTwoMultiplierLights       ; and do next thing when done
    lpm     r16, Z+                     ; get the light code to turn off
	push 	ZL							; save Z for next round
	push 	ZH
    rcall   DisplayLight                ; and turn it off (R17 FALSE)
	pop 	ZH							; get Z back
	pop 	ZL
	inc 	r22
    rjmp    ResetLightsLoop             ; and keep going

TurnOnTwoMultiplierLights:
    ldi     r16, CCW_LIGHT_0            ; these two lights will always start
    ldi     r17, TRUE                       ; on because multiplier is never
    rcall   DisplayLight                    ; less than 1
    ldi     r16, CW_LIGHT_0
    rcall   DisplayLight

EndInitNewRound:
    ret


; ==============================================================================
;
; ResetLightsTable
;
; Description:      This table holds the light codes for all the lights that 
;                   need to be turned off at the beginning of a new round. It 
;                   will be indexed through to turn off all the lights therein.
;
; Author:           Benjamin Boone
; Last Modified:    May 11, 2025		Removed unused lights for real machine.

ResetLightsTable:

    .DB     0,              CW_LIGHT_1     ; All the Multiplier lights but not
                                            ; first
    .equ    R_TBL_NTRY_SIZE   =   2 * (PC - ResetLightsTable)

    .DB     CW_LIGHT_2,     CW_LIGHT_3         ; (clockwise)
    .DB     CW_LIGHT_4,     CW_LIGHT_5
    .DB     CW_LIGHT_6,     CW_LIGHT_7
    .DB     CW_LIGHT_8,     CW_LIGHT_9

    .DB     0,              CCW_LIGHT_1        ; and counter clockwise too but
    .DB     CCW_LIGHT_2,    CCW_LIGHT_3         ; not first
    .DB     CCW_LIGHT_4,    CCW_LIGHT_5
    .DB     CCW_LIGHT_6,    CCW_LIGHT_7
    .DB     CCW_LIGHT_8,    CCW_LIGHT_9

    .DB     ACE1LIGHT,      ACE2LIGHT       ; All the Card Target Lights
    .DB     ACE3LIGHT,      ACE4LIGHT 
    .DB     KING1LIGHT,     KING2LIGHT
    .DB     KING3LIGHT,     KING4LIGHT

    .DB     KINGS_FREE_BALL_LIGHT,  ACES_FREE_BALL_LIGHT    ; Free Ball lights
    .DB     0,   0                           ; Same player light

    .equ    RESET_TABLE_LENGTH = 2 * (PC - ResetLightsTable) / (R_TBL_NTRY_SIZE / 2)

; ==============================================================================
;
; GameLoop
;
; Description:       This function is the main game loop. It continually checks 
;                    whether or not there is a sensor down. Once a sensor is 
;                    pressed, it uses the sensorCode table to call the necessary 
;                    functions for that sensor with the appropriate arguments. 
;                    Never returns.
;
; Operation:         Repeatedly calls HaveSensor and GetSensor if there is a 
;                    sensor active. It will then use the sensorCode given to 
;                    index into the sensorTable, calling the function at the 
;                    appropriate index with the corresponding argument. 
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
; Registers Changed: Flags, R0, R1, R16, R17, Z
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

GameLoop:
    rcall   HaveSensor                  ; continuously check for a sensor
    brne    DoButtonStuff               ; if there is one, go do stuff
    rjmp    GameLoop                    ; otherwise keep checking

DoButtonStuff:
    rcall   GetSensor                   ; will give sensorCode in r16
	lsl		r16							; multiply by 4 to account for
	lsl 	r16 							; 4 byte wide table and byte address
    clr     r0                          ; get zero for adding nothing to Z
    ldi	    ZL, LOW(2 * SensorTable)	; get start of table (multiply by 2
	ldi     ZH, HIGH(2 * SensorTable)       ; for byte addressing)
	add	    ZL, r16			            ; get current button in table
	adc     ZH, r0

    lpm     r0, Z+                      ; get low part of address of function
    lpm     r1, Z+                      ; and high
    lpm     r16, Z+                     ; get first argument
    lpm     r17, Z                      ; and second
    movw    Z, r0                       ; put address of function into Z 
    icall                               ; and call that function

ButtonStuffDone:
    rjmp    GameLoop                    ; done? go check for sensors 




; ==============================================================================
;
; SensorTable
;
; Description:      This is the sensor table which holds the operations for the
;                   machine based on sensor input. The table is organized by 
;                   index. The sensor code for each button is a value from
;                   0 to 39, corresponding to the 0th to 39th line in this table.
;                   Each entry consists of a 16-bit function address, and two 
;                   8-bit arguments for that function (sometimes one or both may
;                   be padding).
;
; Author:           Benjamin Boone
; Last Modified:    May 11, 2026        Updated table to reflect actual board
;
;



SensorTable:

    ; Row 0
            ; Function to Call                      Argument 1  Argument 2  Idx
    .DB     low(0),             high(0),            0,          0           ;00
    .DB     low(0),             high(0),            0,          0           ;01
    .DB     low(0),             high(0),            0,          0           ;02
    .DB     low(0),             high(0),            0,          0           ;03
    .DB     low(0),             high(0),            0,          0           ;04
    .DB     low(0),             high(0),            0,          0           ;05
    .DB     low(0),             high(0),            0,          0           ;06
    .DB     low(0),             high(0),            0,          0           ;07

    ; Row 1
            ; Function to Call                      Argument 1  Argument 2  Idx
    .DB     low(DrainButton),   high(DrainButton),  low(DNSND), high(DNSND) ;08
    .DB     low(AddGame),       high(AddGame),      0,          0           ;09     ; left flipper, will be game button
    .DB     low(PopBumper),     high(PopBumper),    0,          0           ;0A
    .DB     low(StartButton),   high(StartButton),  0,          0           ;0B     ; right flipper, will be start button
    .DB     low(PopBumper),     high(PopBumper),    0,          0           ;0C     ; don't control this light
    .DB     low(PopBumper),     high(PopBumper),    0,          0           ;0D     ; don't control this light
    .DB     low(FreeBallHit),   high(FreeBallHit),  RIGHT_FB,   0           ;0E
    .DB     low(FreeBallHit),   high(FreeBallHit),  LEFT_FB,    0           ;0F

    ; Row 2
            ; Function to Call                      Argument 1  Argument 2  Idx
    .DB     low(TopRoll),       high(TopRoll),      LEFT,       0           ;10
    .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;11
    .DB     low(CardButton),    high(CardButton),   ACE4LIGHT,  ACE1BIT3    ;12
    .DB     low(CardButton),    high(CardButton),   ACE3LIGHT,  ACE1BIT2    ;13
    .DB     low(CardButton),    high(CardButton),   ACE2LIGHT,  ACE1BIT1    ;14
    .DB     low(CardButton),    high(CardButton),   ACE1LIGHT,  ACE1BIT0    ;15
    .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;16
    .DB     low(GenLeaf),       high(GenLeaf),      0,          0           ;17     ; also don't control this light. Was G_LIGHT2

    ; Row 3
            ; Function to Call                      Argument 1  Argument 2  Idx
    .DB     low(0),             high(0),            0,          0           ;18
    .DB     low(0),             high(0),            0,          0           ;19
    .DB     low(0),             high(0),            0,          0           ;1A
    .DB     low(0),             high(0),            0,          0           ;1B
    .DB     low(RotButton),     high(RotButton),    0,          0           ;1C
    .DB     low(LowRoll),       high(LowRoll),      0,          0           ;1D
    .DB     low(LowRoll),       high(LowRoll),      0,          0           ;1E
    .DB     low(CardButton),    high(CardButton),   KING2LIGHT, KING2BIT5   ;1F     ; this switch not working (per Glen)

    ; Row 4
            ; Function to Call                      Argument 1  Argument 2  Idx
    .DB     low(CardButton),    high(CardButton),   KING3LIGHT, KING3BIT6   ;20
    .DB     low(CardButton),    high(CardButton),   KING4LIGHT, KING4BIT7   ;21
    .DB     low(TopRoll),       high(TopRoll),      RIGHT,      0           ;22
    .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;23
    .DB     low(GenLeaf),       high(GenLeaf),      0,          0           ;24     ; though apparently we don't get this light
    .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;25 
    .DB     low(CardButton),    high(CardButton),   KING1LIGHT, KING1BIT4   ;26
    .DB     low(0),             high(0),            0,          0           ;27


; old table before I fixed my versus Glen's documentation differences:

    ; ; Row 0
    ;         ; Function to Call                      Argument 1  Argument 2  Idx
    ; .DB     low(0),             high(0),            0,          0           ;00
    ; .DB     low(0),             high(0),            0,          0           ;01
    ; .DB     low(0),             high(0),            0,          0           ;01
    ; .DB     low(CardButton),    high(CardButton),   KING1LIGHT, KING1BIT4   ;03
    ; .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;04
    ; .DB     low(GenLeaf),       high(GenLeaf),      0,          0           ;05     ; though apparently we don't get this light
    ; .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;06
    ; .DB     low(TopRoll),       high(TopRoll),      RIGHT,      0           ;07

    ; ; Row 1
    ;         ; Function to Call                      Argument 1  Argument 2  Idx
    ; .DB     low(CardButton),    high(CardButton),   KING4LIGHT, KING4BIT7   ;08
    ; .DB     low(CardButton),    high(CardButton),   KING3LIGHT, KING3BIT6   ;09
    ; .DB     low(CardButton),    high(CardButton),   KING2LIGHT, KING2BIT5   ;0A     ; this switch not working (per Glen)
    ; .DB     low(LowRoll),       high(LowRoll),      0,          0           ;0B
    ; .DB     low(LowRoll),       high(LowRoll),      0,          0           ;0C
    ; .DB     low(RotButton),     high(RotButton),    0,          0           ;0D
    ; .DB     low(0),             high(0),            0,          0           ;0E
    ; .DB     low(0),             high(0),            0,          0           ;0F

    ; ; Row 2
    ;         ; Function to Call                      Argument 1  Argument 2  Idx
    ; .DB     low(0),             high(0),            0,          0           ;10
    ; .DB     low(0),             high(0),            0,          0           ;11
    ; .DB     low(GenLeaf),       high(GenLeaf),      0,          0           ;12     ; also don't control this light. Was G_LIGHT2
    ; .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;13
    ; .DB     low(CardButton),    high(CardButton),   ACE1LIGHT,  ACE1BIT0    ;14
    ; .DB     low(CardButton),    high(CardButton),   ACE2LIGHT,  ACE1BIT1    ;15
    ; .DB     low(CardButton),    high(CardButton),   ACE3LIGHT,  ACE1BIT2    ;16
    ; .DB     low(CardButton),    high(CardButton),   ACE4LIGHT,  ACE1BIT3    ;17

    ; ; Row 3
    ;         ; Function to Call                      Argument 1  Argument 2  Idx
    ; .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;18
    ; .DB     low(TopRoll),       high(TopRoll),      LEFT,       0           ;19
    ; .DB     low(FreeBallHit),   high(FreeBallHit),  LEFT_FB,    0           ;1A
    ; .DB     low(FreeBallHit),   high(FreeBallHit),  RIGHT_FB,   0           ;1B
    ; .DB     low(PopBumper),     high(PopBumper),    0,          0           ;1C     ; don't control this light
    ; .DB     low(PopBumper),     high(PopBumper),    0,          0           ;1D     ; don't control this light
    ; .DB     low(StartButton),   high(StartButton),  0,          0           ;1E     ; right flipper, will be start button
    ; .DB     low(PopBumper),     high(PopBumper),    0,          0           ;1F

    ; ; Row 4
    ;         ; Function to Call                      Argument 1  Argument 2  Idx
    ; .DB     low(AddGame),       high(AddGame),      0,          0           ;20     ; left flipper, will be game button
    ; .DB     low(DrainButton),   high(DrainButton),  low(DNSND), high(DNSND) ;21
    ; .DB     low(0),             high(0),            0,          0           ;22
    ; .DB     low(0),             high(0),            0,          0           ;23
    ; .DB     low(0),             high(0),            0,          0           ;24
    ; .DB     low(0),             high(0),            0,          0           ;25
    ; .DB     low(0),             high(0),            0,          0           ;26
    ; .DB     low(0),             high(0),            0,          0           ;27


;
;               sensorCode is set according to the folowing table:
; These codes DO NOT correspond to the actual number of the button, because 
; I flipped them both horizontally and vertically during ScanandDebounce.

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
; Table of Button Number : SensorCode to which sensor is pressed:
;   
;           |     Row 0   |     Row 1   |     Row 2   |     Row 3   |     Row 4
; -----------------------------------------------------------------------------    
; Column 0  |  41: $00    |  33: $08    |  25: $10    |   17: $18   |   9: $20
;           |             |             |             |             |              
; Column 1  |  40: $01    |  32: $09    |  24: $11    |   16: $19   |   8: $21
;           |             |             |             |             |       
; Column 2  |  39: $02    |  31: $0A    |  23: $12    |   15: $1A   |   7: $22
;           |             |             |             |             |       
; Column 3  |  38: $03    |  30: $0B    |  22: $13    |   14: $1B   |   6: $23
;           |             |             |             |             |         
; Column 4  |  37: $04    |  29: $0C    |  21: $14    |   13: $1C   |   5: $24
;           |             |             |             |             |        
; Column 5  |  36: $05    |  28: $0D    |  20: $15    |   12: $1D   |   4: $25
;           |             |             |             |             |        
; Column 6  |  35: $06    |  27: $0E    |  19: $16    |   11: $1E   |   3: $26
;           |             |             |             |             |        
; Column 7  |  34: $07    |  26: $0F    |  18: $17    |   10: $1F   |   2: $27
;           |             |             |             |             |       
;
;   The Button number is what they are labeled as on the board and in Glen's 
;   documentation. The SensorCode is the button number I give it and will be
;   used in my diagram of which button is which!

; Old table from original submission, before updating for the real machine:

; SensorTable:

;     ; Row 0
;             ; Function to Call                      Argument 1  Argument 2  Idx
;     .DB     low(0),             high(0),            0,          0           ;00
;     .DB     low(0),             high(0),            0,          0           ;01
;     .DB     low(PopBumper),     high(PopBumper),    POPLIGHT1,  0           ;02
;     .DB     low(PopBumper),     high(PopBumper),    POPLIGHT2,  0           ;03
;     .DB     low(PopBumper),     high(PopBumper),    POPLIGHT3,  0           ;04
    ; .DB     low(FreeBallHit),   high(FreeBallHit),  LEFT_FB,    0           ;05
    ; .DB     low(FreeBallHit),   high(FreeBallHit),  RIGHT_FB,   0           ;06
;     .DB     low(StartButton),   high(StartButton),  0,          0           ;07

;     ; Row 1
;             ; Function to Call                      Argument 1  Argument 2  Idx
;     .DB     low(LowRoll),       high(LowRoll),      0,          0           ;08
;     .DB     low(LowRoll),       high(LowRoll),      0,          0           ;09
;     .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;0A
;     .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;0B
;     .DB     low(TopRoll),       high(TopRoll),      LEFT,       0           ;0C
;     .DB     low(TopRoll),       high(TopRoll),      RIGHT,      0           ;0D
;     .DB     low(RotButton),     high(RotButton),    0,          0           ;0E
;     .DB     low(RotButton),     high(RotButton),    0,          0           ;0F

;     ; Row 2
;             ; Function to Call                      Argument 1  Argument 2  Idx
    ; .DB     low(CardButton),    high(CardButton),   ACE1LIGHT,  ACE1BIT0    ;10
    ; .DB     low(CardButton),    high(CardButton),   ACE2LIGHT,  ACE1BIT1    ;11
    ; .DB     low(CardButton),    high(CardButton),   ACE3LIGHT,  ACE1BIT2    ;12
    ; .DB     low(CardButton),    high(CardButton),   ACE4LIGHT,  ACE1BIT3    ;13
;     .DB     low(CardButton),    high(CardButton),   KING1LIGHT, KING1BIT4   ;14
;     .DB     low(CardButton),    high(CardButton),   KING2LIGHT, KING2BIT5   ;15
;     .DB     low(CardButton),    high(CardButton),   KING3LIGHT, KING3BIT6   ;16
;     .DB     low(CardButton),    high(CardButton),   KING4LIGHT, KING4BIT7   ;17

;     ; Row 3
;             ; Function to Call                      Argument 1  Argument 2  Idx
;     .DB     low(AddGame),       high(AddGame),      0,          0           ;18
;     .DB     low(0),             high(0),            0,          0           ;19
;     .DB     low(0),             high(0),            0,          0           ;1A
;     .DB     low(0),             high(0),            0,          0           ;1B
;     .DB     low(0),             high(0),            0,          0           ;1C
;     .DB     low(0),             high(0),            0,          0           ;1D
;     .DB     low(0),             high(0),            0,          0           ;1E
;     .DB     low(0),             high(0),            0,          0           ;1F

;     ; Row 4
;             ; Function to Call                      Argument 1  Argument 2  Idx
;     .DB     low(GenLeaf),       high(GenLeaf),      G_LIGHT1,   0           ;20
;     .DB     low(GenLeaf),       high(GenLeaf),      G_LIGHT2,   0           ;21
;     .DB     low(GenLeaf),       high(GenLeaf),      G_LIGHT3,   0           ;22
;     .DB     low(GenLeaf),       high(GenLeaf),      G_LIGHT4,   0           ;23
;     .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;24
;     .DB     low(SwiLeaf),       high(SwiLeaf),      0,          0           ;25
;     .DB     low(TiltSensor),    high(TiltSensor),   0,          0           ;26
;     .DB     low(DrainButton),   high(DrainButton),  low(DNSND), high(DNSND) ;27


; ==============================================================================
;
; AddGame
;
; Description:       This function is called when the Add Game Button is 
;                    pressed. It will increment the number of games the user has
;                    left to play, saturating at the max number of games. If a
;					 game is not currently in play (start button not yet pressed)
;					 then the function will also update the display showing 
;					 "PLAY" with the number of games left.
;
; Operation:         Increments games_left. If it were to go past the  
;                    maximum value of games that can be stored, it saturates.
;					 Then, checks the game_active flag and calls DisplayPlayGame
;					 if it is not true.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  games_left -   read and write. The number of games left 
;                                   available to be played.
;					 game_active - 	read only. Flag indicating a game is active
;
; Global Variables:  None.
;
; Input:             Add Game Button Pressed.
; Output:            None.
;
; Error Handling:    If games_left is at it's max value, it will saturate there.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, 
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 12, 2025

AddGame:
    lds     r16, games_left         ; increment games_left
    inc     r16

    cpi     r16, MAX_GAMES          ; check the number against the max
    brsh    SaturateGamesLeft
    rjmp    SaveGames

SaturateGamesLeft:
    ldi     r16, MAX_GAMES          ; if >= max, set at the max

SaveGames:
    sts     games_left, r16         ; and make sure to save (and to EEROM)
    ldi     r16, GAMES_BYTE_LENGTH  ; write (1) byte
    ldi     r17, GAMES_EEROM_ADDR   ; at it's address
    ldi     YL, low(games_left)
    ldi     YH, high(games_left)
    rcall   WriteEEROM              ; save in EEROM

MaybeDisplayPlayGame:
	lds 	r16, game_active		; check if a game is active, if not, display
	cpi 	r16, TRUE				; the number of games left! (update)
	breq 	EndAddGame		
	rcall 	DisplayPlayGame

EndAddGame:		
    ret								; done so return


; ==============================================================================
;
; StartButton
;
; Description:       This function handles the cases for a user pressing the 
;                    start button. When the start button is pressed, it will 
;                    start a game (if there are games left to play), 
;                    decrementing the number of games left. If a game is not 
;                    currently in play, then it will start a game with 1 player. 
;                    If pressed again (before any other sensor has been hit) 
;                    then the game will be two players. If pressed again (also 
;                    before any other sensor has been hit) then it will toggle 
;                    between 1 and 2 players. If a game is currently in play 
;                    (meaning a sensor has been hit by the ball -  not user) the 
;                    start button will do nothing. 
;                    While switching between players it will clear the display 
;                    and then show $0000 on each active player's display (i.e. 
;                    will show only on player 1 display for 1 player, or both 
;                    for two).
;                    Additionally, this function will load the ball into the 
;                    launcher. 
;                    Initial Score (0) and Ball Count (5) are set for the game.
;                    Starts playing game music from the speaker.
;
; Operation:         Checks the game_active and any_sensor_hit flags to find out
;                    if this button has been hit before, and if the ball has 
;                    been launched. Based on those, will toggle the number of 
;                    players, set the displays, and change the flags, and init
;                    a new game. Also calls functions to initiate the next round
;                    and play music.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  games_left -   read and write. The number of available 
;                                   games the user can play
;                    game_active -  read and write. Flag indicating the start 
;                                   button was pressed (and thus a game started)
;                    any_sensor_hit - read and write. Flag indicating the ball 
;                                     has been launched and hit a sensor
;                    numPlayers -   read and write. Number of players in current
;                                   game.
;                    currentPlayer - write only. The player of the current round
;                    p1Score    -   write only. Player 1's score.
;                    p2Score    -   write only. Player 2's score.
;                    p1Balls    -   write only. Player 1's balls left in game.
;                    p2Balls    -   write only. Player 2's balls left in game.
;                    top_bonus  -   write only. Which rollover gets 300 pt bonus
;
; Global Variables:  None.
;
; Input:             Start Button Pressed.
; Output:            Either or both the Player Displays are set to 0000 based on
;                    how many times the Start Button has been hit. Starts 
;                    game music from the speaker.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, R18, R19, Y
; Stack Depth:       1 byte (in another function)
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025

StartButton:
    lds     r16, game_active            ; check whether there is a game active
    cpi     r16, TRUE           
    breq    StartButGameActive          ; if there is, check if it's 'started'   

    lds     r16, games_left             ; if game not active, check if games
    cpi     r16, 0                          ; available to play
	in 		r19, sreg					; if not, do nothing. Otherwise...
    sbrc    r19, ZERO_FLAG                  ; My pseudo "BREQ" but because the  
    rjmp    EndStartButton                  ; next label is out of range

    rcall   StartGameMusic              ; Play Music but only start it once
    ldi     r16, TRUE                   ; set game_active to true so we can know
    sts     game_active, r16                ; whether start has been pressed yet

DecrementGamesLeft:
	lds 	r16, games_left
    dec     r16                         ; one less game left to play
    sts     games_left, r16
    ldi     r17, GAMES_EEROM_ADDR       ; and make sure to save in EEROM too
    ldi     r16, GAMES_BYTE_LENGTH
    ldi     YL, low(games_left)
    ldi     YH, high(games_left)
    rcall   WriteEEROM

TogglePlayerStart:
    rcall   clearDisplay                ; clear the display
    lds     r16, numPlayers             ; check how many players the are (if 1)
    cpi     r16, 1                          ; so we can toggle
    breq    SetNumPlayers2              ; if numPlayers == 1, set to 2
    ;brne   continue                    ; if not 1, then numPlayers = 2 or 0
    ldi     r16, 1                          ; so set numPlayers to 1
    sts     numPlayers, r16             

DisplayOnePlayer:
    clr     r16                         ; prepare to and then display $0000 on 
    clr     r17                             ; the player 1 display to show the 
    ldi     r18, PLAYER_1                   ; user how many players there are
    rcall   DisplayHex
    rjmp    InitNewGame                 ; then finish

SetNumPlayers2:
    ldi     r16, 2                      ; if numPlayers == 1 when start button
    sts     numPlayers, r16                 ; hit, set to 2.

DisplayTwoPlayers:
    clr     r16                         ; and prepare to and display $0000 on 
    clr     r17                             ; both the player 1 and 2 displays 
    ldi     r18, PLAYER_1                   ; to show the user how many players 
    rcall   DisplayHex                      ; there are
    ldi     r18, PLAYER_2
    rcall   DisplayHex                  ; setting second display to $0000
    rjmp    InitNewGame                 ; and finish

StartButGameActive:                     ; called when not first time hitting
    lds     r16, any_sensor_hit             ; the start button, so just toggle
    cpi     r16, TRUE                       ; but only if haven't launched ball
    breq    EndStartButton              ; if a sensor has been hit, do nothing
    rjmp    TogglePlayerStart

InitNewGame:                            
    ldi     r16, 0                      ; initialize all scores to zero
    sts     p1Score, r16				; make sure to get both bytes of each
	sts 	p1Score + 1, r16
    sts     p2Score, r16 
	sts 	p2Score + 1, r16
    ldi     r16, BALLS_TO_START         ; give 'both' players 5 balls
    sts     p1Balls, r16
    sts     p2Balls, r16                
    ldi     r16, PLAYER_1               ; Player 1 always starts
    sts     currentPlayer, r16

    ldi     r17, FALSE                  ; top bonus initializes on the left
    sts     top_bonus, r17
    ldi     r16, LEFT_ROLLOVER_LIGHT    ; so turn ON the left rollover light
    ldi     r17, TRUE               
    rcall   DisplayLight

    rcall   InitNewRound                ; And reset all the lights and vars
	rcall	LoadTheBall	           		; Load the Ball

EndStartButton:
    ret

; ==============================================================================
;
; SwiLeaf
;
; Description:       This function is called when one of the four switch bonus   
;                    bumpers are pressed. When one is hit, the current player 
;                    will earn 1 point. Additionally, the top_bonus flag will be 
;                    toggled and so will the two bonus lights. Also sets the  
;                    any_sensor_hit flag.
;
; Operation:         Adds 1 to the current player's score. Set the state of 
;                    the left rollover bonus light (and left rotating bumper 
;                    light) to what top_bonus is, then flips top_bonus, and then 
;                    sets the state of the right rollover bonus light (and 
;                    right) to the new state of top_bonus. This will effectively
;                    toggle the lights in accordance to what the top_bonus flag
;                    indicates (FALSE for left, TRUE for right). Ex: if 
;                    top_bonus is currently FALSE, then we want to switch it, so 
;                    we turn OFF the left light (what top_bonus currently is), 
;                    then switch it (TRUE) and set the right light to that value.
;                    This also works in reverse. Also sets the any_sensor_hit,
;                    as these may be the first sensors to be hit.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  p1/2Score  -   Write only. Indirectly updates the current
;                                   player's score.
;                    top_bonus  -   Read and Write. Flag indicating which side
;                                   of the top rollover buttons gets a 200 pt 
;                                   bonus.
;                    any_sensor_hit    -   write only. Indicates if there any
;                                          game sensor has been hit.
;
; Global Variables:  None.
;
; Input:             One of the top leaf buttons hit by ball.
; Output:            Will toggle the Top Bonus Lights. Changes score display too.
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
; Last Modified:     June 16, 2025

SwiLeaf:
    rcall   IncrementPlayerScore1   ; Give them 1 point
    ldi     r16, TRUE               ; and set the any_sensor_hit flag
    sts     any_sensor_hit, r16

ToggleTopBonus:
    ldi     r16, LEFT_ROLLOVER_LIGHT    ; left rollover light is initially on
    lds     r17, top_bonus          ; top_bonus will be false, and we're gonna
    rcall   DisplayLight                ; toggle it, so turn off that light. 
    ldi     r16, LEFT_ROT_BONUS_LIGHT   ; Likewise toggle the rotating bumper
    rcall   DisplayLight                    ; lights. R17 unchanged.
    com     r17                     ; toggle top bonus
    sts     top_bonus, r17          ; and save
    ldi     r16, RIGHT_ROLLOVER_LIGHT   ; and turn on/off the right light
    rcall   DisplayLight            ; This sequence will work in reverse.
    ldi     r16, RIGHT_ROT_BONUS_LIGHT   ; Likewise toggle the rotating bumper
    rcall   DisplayLight                    ; lights. R17 unchanged.

EndSwiLeaf:
    ret                             ; done so return


; ==============================================================================
;
; TopRoll
;
; Description:       This function is called when one of the top rollover 
;                    buttons is hit. It adds 100 points to the current player’s 
;                    score and sets the any_sensor_hit flag (as these would be 
;                    the first sensors to be hit, none others can until after 
;                    these are). Additionally, if the top_bonus flag matches the 
;                    index of the button (TRUE or FALSE) that was pressed, 
;                    an additional 200 points are awarded (for a total of 300).
;
; Operation:         Sets the any_sensor_hit flag and then gives the current 
;                    player 100 points. Checks the value of the top_bonus flag 
;                    and if it matches the button pressed (the argument passed 
;                    in from the table, index), then will give the current 200 
;                    more points.
;
; Arguments:         index  -   Passed in R16 from the table, will hold the 
;                               index of the Top Rollover Button that has been 
;                               hit. FALSE for left, TRUE for right.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  p1/2Score  -   Write only. Indirectly updates the current
;                                   player's score.
;                    any_sensor_hit  -   Write only. Flag indicating which side
;                                   of the top rollover buttons gets a 200 pt 
;                                   bonus.
;                    top_bonus  -   Read only. Flag indicating which side
;                                   of the top rollover buttons gets a 200 point 
;                                   bonus.
;
; Global Variables:  None.
;
; Input:             One of top rollover buttons hit by ball.
; Output:            Changes the display when updating player score.
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
; Last Modified:     June 13, 2025

TopRoll:
    lds     r17, top_bonus          ; check whether top_bonus matches button
    cp      r16, r17                    ; index for extra points
    brne    NoBonusPoints           ; if not, no extra points

    rcall   IncrementPlayerScore100 ; give the extra 200 points
    rcall   IncrementPlayerScore100

NoBonusPoints:
    ldi     r16, TRUE               ; and set the any_sensor_hit flag
    sts     any_sensor_hit, r16
    rcall   IncrementPlayerScore100     ; give the current player 100 points

EndTopRoll:
    ret


; ==============================================================================
;
; DrainButton
;
; Description:       The function will decrease the number of balls of whoever’s 
;                    turn it is by 1. It will also check to see whether the 
;                    player has any balls left, and if there are no more rounds 
;                    to play it will end the game (checking and setting the high
;                    score, resetting game play variables, stopping game play
;                    music, plays a short tone and displays the high score, 
;                    blinking). Otherwise it will blink the display with how 
;                    balls left the player who just ended their turn has, and 
;                    then switch whose turn it is, and  load the ball into the 
;                    launcher. The function also handles the case of a free ball
;                    (just loads the ball and turns off Same Player light).
;
; Operation:         First initializes a new round (to reset lights and vars, 
;                    then checks for the free ball case (SamePlayerAgain flag),
;                    which if it is set, will just load the ball and reset the 
;                    flag. Otherwise, it checks who the current player is and  
;                    decrements the number of balls they have by 1, then blinks 
;                    the display with how many balls they have left. If they, or 
;                    everyone, is out of balls it will end the game by resetting
;                    game play variables, comparing the high score with those of
;                    the current game, and not reloading the ball. Otherwise, it 
;                    switch whose turn it is, change the display to show the 
;                    number of balls left for whose turn just finished, and load
;                    the next ball. If it is the end of the whole game, it will
;                    check for a new high score (and if there is one save it in
;                    EEROM) and then blink the display with the high score and 
;                    play a short note.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  numPlayers     -   read only. Num of players in the game.
;                    currentPlayer  -   read only. Code of the current player.
;                    p1/2balls      -   read and write. The number of balls that
;                                       player 1 and/or 2 have left.
;                    any_sensor_hit -   write only. Flag if any sensor been hit
;                    game_active    -   write only. Flag for a game in play
;                    high_score     -   read and write. High Score yet gotten
;                    SamePlayerAgain -  read and write. Indicates a free ball
;                    p1/2Score      -   read only. Player 1/2's scores
;
; Global Variables:  None.
;
; Input:             Drain Button hit by the ball.
; Output:            A brief tone will play.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, R18, R19, Y
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     May 11, 2026		Removed SamePlayerLight and call since not on real board

DrainButton:
    rcall   InitNewRound        ; Always reset lights and vars

CheckSamePlayerFreeBall:
    lds     r18, SamePlayerAgain    ; check whether someone has a free
    cpi     r18, FALSE                  ; ball
    breq    CheckBalls              ; if they don't, continue as normal
    rcall   LoadTheBall             ; otherwise, load the ball,
    ldi     r17, FALSE              ; reset the flag,
    sts     SamePlayerAgain, r17
;    ldi     r16, SAMEPLAYER_LIGHT   ; turn off the light,
;    rcall   DisplayLight
    rjmp    EndDrainButton          ; and skip everything

CheckBalls:
    lds     r16, currentPlayer     ; to check balls, need to know who's turn 
    cpi     r16, PLAYER_1               ; it is
    breq    DecP1Balls
    ;brne   DecP2Balls

DecP2Balls:
    lds     r17, p2Balls        ; decrement the number of balls player 2 has
    dec     r17
    sts     p2Balls, r17
    cpi     r17, 0              ; check if they've reached zero. If so, 
    breq    EndGame                 ; it is the end of the game
    rjmp    NotEndofGame

DecP1Balls:
    lds     r17, p1Balls        ; decrement the number of balls player 1 has
    dec     r17
    sts     p1Balls, r17
    cpi     r17, 0              ; check if reached zero. If not, skip ahead 
    brne    NotEndofGame        
    lds     r18, numPlayers     ; BUT if they do have no balls left, check how
    cpi     r18, 1           	; many players there are. If only one, then
    brne    NotEndofGame            ; it is the end of the game
    rjmp    EndGame

NotEndofGame:
    ;rcall   SwitchTurns        ; Note: R16 still holds currentPlayer 
    ldi     r18, PLAYER_2       ; Here, will show on P2 display number of balls
    cpi     r16, PLAYER_1       ; of who is currently playing. So need to check
    breq    ShowP1Balls         
    ;brne   ShowP2Balls

ShowP2Balls:
    lds     r16, p2Balls        ; Get player 2's balls
    clr     r17                 ; clear reg 17 so not to display random num
    rcall   DisplayHex          ; and display
    ldi     r18, PLAYER_1       ; and toggle the player
    sts     currentPlayer, r18
    rjmp    ContinueDrainButton

ShowP1Balls:
    lds     r16, p1Balls        ; Get player 1's balls
    clr     r17                 ; clear reg 17 so not to display random num
    rcall   DisplayHex          ; and display
    lds     r18, numPlayers     ; if player 1, need to check how many players 
    cpi     r18, 2                  ; there are before we toggle
    brne    ContinueDrainButton ; if only 1, then don't toggle
    ldi     r18, PLAYER_2           ; else, do!
    sts     currentPlayer, r18
    ;rjmp   ContinueDrainButton

ContinueDrainButton:
    rcall   DisplayBALL         ; Will write "BALL" on P1 Display
    ldi     r18, 5              ; test to see if will blink
    rcall   BlinkDigits  
    rcall   LoadTheBall         ; and load the ball
    rjmp    EndDrainButton

EndGame:                        ; No balls left, game is over.

CheckHighestPlayerScore:        ; Check for a high score
    lds     r24, p1Score        ; Load Player 1's score (low and high bytes)
    lds     r25, P1Score+1          
    
    lds     r22, p2Score        ; load Player 2's score to compare
    lds     r23, p2Score+1     
    
    cp      r24, r22            ; Compare low bytes
    cpc     r25, r23            ; Compare high bytes with carry
    brcc    CheckAgainstHigh    ; Branch if p1score >= p2score (unsigned)
    
    mov     r24, r22            ; if p2 > p1, store p2 in registers used to hold
    mov     r25, r23                ; the max of the two

CheckAgainstHigh:
    lds     r22, high_score     ; Load the high score for comparison
    lds     r23, high_score+1      
    
    cp      r24, r22            ; Compare next 16-bit value
    cpc     r25, r23               
    brcc    StoreHighestScore   ; Branch if max(p1, p2) >= high_score
    
    mov     r24, r22            ; put max of all three in R25|R24
    mov     r25, r23            

StoreHighestScore:
    sts     high_score, r24     ; Store max(p1, p2, high_score) in the high
    sts     high_score+1, r25       ; score variable
    ldi     YL, low(high_score)     ; and in EEROM
    ldi     YH, high(high_score)    
    ldi     r16, HSCORE_BYTE_LENGTH ; write two bytes to the high score address  
    ldi     r17, HIGH_EEROM_ADDR    ; in EEROM.
    rcall   WriteEEROM

ResetGameVariables:                                                             
    ldi     r16, FALSE          ; here, reset all the game variables
    ldi     r17, 0              ; 0, in case different from false
    sts     game_active, r16    ; set flags to false
    sts     any_sensor_hit, r16
    sts     numPlayers, r17     ; and numPlayers to 0    
    rcall   StopGameMusic       ; Stop the Game Music (resets variables)         

    ldi     r16, low(C3)                    ; play a tone to indicate done
    ldi     r17, high(C3)
    ldi     r18, low(FLASH_QUARTER_SEC)     ; play a short tone for a quarter
    ldi     r19, high(FLASH_QUARTER_SEC)        ; second   
    rcall   PlaySoundBurst      

EndDisplaySequence:
    rcall   DisplayHighScore    ; Display the High Score and Blink Digits !!
    ldi     r18, 9
    rcall   BlinkDigits
    ldi     r16, TRUE               ; delay 3 seconds
    rcall   Delay               ; yes it blocks but ok because game done
    ldi     r16, TRUE               ; and next ball won't load
    rcall   Delay               
    rcall   DisplayPlayGame

    rjmp    EndDrainButton   

EndDrainButton:
    ret                         ; then return 

; ==============================================================================
;
; cardButton
;
; Description:       Turns on a corresponding LED and increases the current  
;                    player's score, by 10. Once an LED is lit in this function 
;                    it will remain on in a game until it is reset by a 
;                    matching Free Ball Target, or when the ball goes down the 
;                    drain. Will also update the cardBuffer to indicate which
;                    card has been hit to potentially give a free ball. This 
;                    function will also then check whether all the Aces or Kings
;                    have been hit, and set the appropriate flag and light
;                    indicating a free ball available.
;
; Operation:         The light passed in R16 via the SensorTable will be turned
;                    on with DisplayLight(). Then the bit index passed in R17 
;                    via the SensorTable will be used to set the corresponding
;                    bit index in the cardBuffer. This is done by looping while
;                    decrementing this index, rotating a single set bit, and 
;                    ORing it with the cardBuffer once rotated the correct 
;                    amount. After cardBuffer is updated, the function will, one
;                    after the other, mask the bits corresponding to the Aces 
;                    and Kings and see if all 4 of either are down. If so, it 
;                    will turn on the Free Ball Light for that card type and 
;                    set a flag. The current player's score aldo will be  
;                    incremented by 10.
;
; Arguments:         index  -   Passed in R17 from the table, will hold the 
;                               bit index for the current card (value from 0 to
;                               7) based on it's position. This'll be used to 
;                               set that bit in the cardBuffer.
;                    light  -   Passed in R16 from the table. This is the LED to
;                               turn on.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  cardBuffer -   write only. Keeps track of which cards have
;                                   been hit, so that a free ball can be given
;                                   accurately.
;                    freeB_KingsR/AcesL -   Write only. Flags indicating that a
;                                           a free ball is available on the aces
;                                           or kings free ball target.
;
; Global Variables:  None.
;
; Input:             One of the 8 Card Sensors Hit.
; Output:            Changes the display when updating player score. Turns on an
;                    LED. May turn on other LEDs.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, R23
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025

CardButton:
    mov     r23, r17                    ; save the bit for later
    ldi     r17, TRUE                   ; first turn on the light (R16 loaded by
    rcall   DisplayLight                    ; sensorTable)
    lds     r17, cardBuffer             ; set up loop by reading in cardBuffer
    ldi     r16, 1                          ; and setting a bit to rotate

CardBufferLoop:
    cpi     r23, 0                      ; find index in the cardBuffer to set
    breq    SetCardBufferBit            ; when at zero, have rotated enough
    lsl     r16                         ; move the bit left each time
    dec     r23                         ; and update count
    rjmp    CardBufferLoop

SetCardBufferBit:
    or      r17, r16                    ; set the bit in cardBuffer and save
    sts     cardBuffer, r17

CheckAces:                              ; Want to check if all Kings/Aces down
    mov     r23, r17                    ; save cardBuffer for kings later
    andi    r17, ACES_SIDE              ; Mask to keep only the Aces
    cpi     r17, ALL_4_ACES             ; check to see if all Aces are down
    brne    CheckKings                  ; if not, go check Kings

SetAcesFreeBall:
    ldi     r16, ACES_FREE_BALL_LIGHT   ; turn on the Aces Free Ball Light
    ldi     r17, TRUE
    rcall   DisplayLight    
    sts     FreeB_AcesL, r17            ; and set the free ball flag (r17 same)

CheckKings:
    andi    r23, KINGS_SIDE             ; Mask to keep only the Kings
    cpi     r23, ALL_4_KINGS            ; check to see if all Kings are down
    brne    EndCardButton

SetKingsFreeBall:
    ldi     r16, KINGS_FREE_BALL_LIGHT  ; turn on the Kings Free Ball light
    ldi     r17, TRUE
    rcall   DisplayLight
    sts     FreeB_KingsR, r17           ; and set the free ball flag (r17 same)

EndCardButton:
    rcall   IncrementPlayerScore10      ; give the player 10 points
    ret                                 ; and return 

; ==============================================================================
;
; RotButton
;
; Description:       This function is called when the rotating bumper is rotated
;                    in either direction. Based on the direction of points to be
;                    awarded, set by the top_bonus flag it will then index into 
;                    a table of lights displaying how many points a free ball
;                    target is worth. It will turn on that corresponding light, 
;                    and also increment point multiplier by 1 (each increment 
;                    worth 10 points when the free ball target is hit).
;
; Operation:         First checks what direction gets points via the top_bonus
;                    flag, (left or right). Based on that it will load the
;                    table address (of a table of light codes) into the Z reg,
;                    and turn on the next light in the sequence. This is done by
;                    offsetting Z with one of two point multipliers (CW or CCW), 
;                    which is also incremented in this function (but not past
;                    the max multiplier/index value).
;
; Arguments:         None. 
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  AcePtIndex_CCW_L - read and write. The multiplier/index 
;                                     variable for the left free ball target 
;                                     point value. 
;                    KingPtIndex_CW_R - read and write. The multiplier/index 
;                                     variable for the right free ball target 
;                                     point value.  
;                    top_bonus  -   read only. Flag stores which side gets a 
;                                   bonus, and thus which rotation direction 
;                                   gets more points.
; Global Variables:  None.
;
; Input:             The Rotating Bumper rotated sufficiently far.
; Output:            Turns on LEDs according to point value of Free Ball Target.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R0, R16, R17, R18, Z
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     May 11, 2026       Removed arguments (didn't use)

RotButton:
    clr     r0                          ; clear for adding with carry soon
    lds     r17, top_bonus              ; "direction" of points awarded based on
    cpi     r17, RIGHT                      ; the same as top bonus flag. Check.
    breq    ClockwiseRotation           ; And go to appropriate portion

CounterClockwiseRotation:
    lds     r18, AcePtIndex_CCW_L       ; get the point index for ccw rotation
    inc     r18                             ; and increment.
    ldi     r19, PT_INDEX_MAX           ; need to make sure didn't increment
    cp      r19, r18                        ; past the max amount
	in 		r19, sreg
    sbrc    r19, CARRY_FLAG             ; if carry is set, then variable is too 
    ldi     r18, PT_INDEX_MAX               ; big, so saturate at max
    sts     AcePtIndex_CCW_L, r18        ; and make sure to save
	dec 	r18 						; go down one for table access

    ldi		ZL, low(2 * CCWTb)	        ; low bit of table already in r16
	ldi     ZH, high(2 * CCWTb)         ; (*2 for byte addressing)
	add	    ZL, r18			            ; get current index in table
	adc     ZH, r0
    rjmp    SetRotLights

ClockwiseRotation:
    lds     r18, KingPtIndex_CW_R       ; get the point index for cw rotation
    inc     r18                             ; and increment. 
    ldi     r19, PT_INDEX_MAX           ; need to make sure didn't increment
    cp      r19, r18                        ; past the max amount
	in	 	r19, sreg
    sbrc    r19, CARRY_FLAG             ; if carry is set, then variable is too 
    ldi     r18, PT_INDEX_MAX               ; big, so saturate at max
    sts     KingPtIndex_CW_R, r18        ; and save
	dec 	r18						    ; go down one for table access

    ldi		ZL, low(2 * CW_Tb)	        ; low bit of table
	ldi     ZH, high(2 * CW_Tb)         ; (*2 for byte addressing)
	add	    ZL, r18			            ; get current index in table
	adc     ZH, r0
    ;rjmp   SetRotLights

SetRotLights:
    lpm     r16, Z                      ; load this light value into r16
    ldi     r17, TRUE                   ; and prepare to, and then turn on that
    rcall   DisplayLight                    ; light.

EndRotButton:
    ret                                 ; Then done, so return


; ==============================================================================
;
; CW_Tb (RotCWLightTable)
;
; Description:      This table holds the sequence of lights to turn on for when 
;                   the rotating bumper is hit in a clockwise direction. In the
;                   table are constants set based on which light will correspond
;                   to them on the pinball machine. Each time the rotating 
;                   bumper is hit clockwise, it will increment a point value, 
;                   then index into this table based on that, and set that light
;                   on.
;
; Author:           Benjamin Boone
; Last Modified:    June 14, 2025

CW_Tb:

    .DB     0,  		 CW_LIGHT_1				; 0th light never goes off

    .equ    CW_TABLE_SIZE = 2 * (PC - CW_Tb)    ; get length and width of table

    .DB     CW_LIGHT_2,  CW_LIGHT_3
    .DB     CW_LIGHT_4,  CW_LIGHT_5
    .DB     CW_LIGHT_6,  CW_LIGHT_7
    .DB     CW_LIGHT_8,  CW_LIGHT_9

    .equ    NUM_MULT_LIGHTS_R = 2 * (PC - CW_Tb) / (CW_TABLE_SIZE / 2)


; ==============================================================================
;
; CCWTb (RotCCWLightTable)
;
; Description:      This table holds the sequence of lights to turn on for when 
;                   the rotating bumper is hit in a counterclockwise direction. 
;                   In the table are constants set based on which light will 
;                   correspond to them on the pinball machine. Each time the  
;                   rotating bumper is hit clockwise, it will increment a point 
;                   value, then index into this table based on that, and set 
;                   that light on.
;
; Author:           Benjamin Boone
; Last Modified:    June 14, 2025

CCWTb:

    .DB     0,  		  CCW_LIGHT_1			; 0th light never goes off

    .equ    CCWTABLE_SIZE = 2 * (PC - CCWTb)    ; get length and width of table

    .DB     CCW_LIGHT_2,  CCW_LIGHT_3
    .DB     CCW_LIGHT_4,  CCW_LIGHT_5
    .DB     CCW_LIGHT_6,  CCW_LIGHT_7
    .DB     CCW_LIGHT_8,  CCW_LIGHT_9

    .equ    NUM_MULT_LIGHTS_L = 2 * (PC - CCWTb) / (CCWTABLE_SIZE / 2)



; ==============================================================================
;
; FreeBallHit
;
; Description:       This function is called when the ball lands in a free ball 
;                    spot (doesn’t necessarily mean they get a free ball though). 
;                    Depending on the cardBuffer, the player will get an extra 
;                    free ball/round. If all the card buttons that correspond to
;                    the hit free ball are down (all Kings or all Aces, read via
;                    the cardBuffer) the player gets a free ball (flag set). The
;                    player will also get points, 10 times the number of lights
;                    that are lit in the multiplier row (from the rotating 
;                    bumper. It will also reset the multiplier lights and the 
;                    multiplier variable (of the respective target, left or 
;                    right)
;
; Operation:         First checks which target was hit, then checks if that 
;                    target gives a free ball, based on a flag. If it does it'll
;                    set the SamePlayerAgain flag and turn on the Same Player 
;                    light, and resets the other flags and lights that were on.
;                    Regardless, the function will give the player 10x the 
;                    corresponding multiplier in points by looping and 
;                    decrementing the multiplier/index. 
;
; Arguments:         R16    -   The position of the hit free ball target.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  KingPtIndex_CW_R   - read and write. Point Multiplier for 
;                                         right free ball target.
;                    freeB_KingsR       - read and write. Flag indicating there
;                                         is a free ball for the right target.
;                    AcePtIndex_CCW_L   - read and write. Point Multiplier for 
;                                         left free ball target.
;                    freeB_AcesL        - read and write. Flag indicating there
;                                         is a free ball for the left target.
;                    SamePlayerAgain    - write only. Flag indicating that there
;                                         will be free ball round (same player)
;
; Global Variables:  None.
;
; Input:             One of the Free Ball Targets Hit.
; Output:            Changes the display when updating player score. Possibly 
;                    turns on or off an LED or two.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16, R17, R18, R22, R23, Z
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     May 11, 2026		Removed SAMEPLAYERLIGHT thing since not controlled on real machine

FreeBallHit:
    cpi     r16, LEFT_FB                ; find out which target was hit (L/R)
    breq    LeftFreeTarget              ; and go to appropriate part
    ;brne   RightFreeTarget

RightFreeTarget:
    lds     r23, KingPtIndex_CW_R       ; load in the point multiplier (later)
    lds     r17, freeB_KingsR           ; check if there is a free ball 
    cpi     r17, FALSE                      ; reward
    breq    ResetRightMultiplierLights

    ;ldi     r17, TRUE                  ; commented b/c if here, must be true
    sts     SamePlayerAgain, r17        ; set the same player again flag        
    ;ldi     r16, SAMEPLAYER_LIGHT       ; and turn on the corresponding light
    ;rcall   DisplayLight                ; Note, again, r17 already TRUE
    ldi     r17, FALSE                  ; and then reset other free ball flag   
    sts     freeB_KingsR, r17           
    ldi     r16, KINGS_FREE_BALL_LIGHT  ; and turn off that free ball light
    rcall   DisplayLight

ResetRightMultiplierLights:
    ldi	    ZL, low(2 * CW_Tb)	; get start of table (multiply by 2
	ldi     ZH, high(2 * CW_Tb)       ; for byte addressing)
    clr     r22

ResetRightLoop:
    cpi     r22, NUM_MULT_LIGHTS_R      ; check to see when done with table
    breq    RightPointMultiplyingLoop        ; and be done when done
    lpm     r16, Z+                     ; get the light code to turn off
	push 	ZL							; save Z for next round
	push 	ZH
    rcall   DisplayLight                ; and turn it off (R17 FALSE)
	pop 	ZH							; get Z back
	pop 	ZL
	inc 	r22
    rjmp    ResetRightLoop			    ; and keep going

RightPointMultiplyingLoop:
    cpi     r23, 0                      ; r23 holds our multiplier, check if 0
    breq    ResetRightMultiplier              
	push 	r23							; save so it doesn't get changed
    rcall   IncrementPlayerScore10      ; give the player 10x multiplier points
	pop 	r23
	dec 	r23
    rjmp    RightPointMultiplyingLoop 

ResetRightMultiplier:
	ldi 	r18, 1						; reset the multiplier to one
	sts 	KingPtIndex_CW_R, r18
	rjmp 	EndFreeBallHit

LeftFreeTarget:
    lds     r23, AcePtIndex_CCW_L       ; load in the point multiplier (later)
    lds     r17, freeB_AcesL            ; check if there is a free ball 
    cpi     r17, FALSE                      ; reward
    breq    ResetLeftMultiplierLights    
    ;ldi     r17, TRUE                  ; commented b/c if here, must be true
    sts     SamePlayerAgain, r17        ; set the same player again flag
    ;ldi     r16, SAMEPLAYER_LIGHT       ; and turn on the corresponding light
    ;rcall   DisplayLight                ; Note, again, r17 already TRUE
    ldi     r17, FALSE                  ; and then reset other free ball flag
    sts     freeB_AcesL, r17           
    ldi     r16, ACES_FREE_BALL_LIGHT   ; and turn off that free ball light
    rcall   DisplayLight

ResetLeftMultiplierLights:
    ldi	    ZL, low(2 * CCWTb)	; get start of table (multiply by 2
	ldi     ZH, high(2 * CCWTb)       ; for byte addressing)
    clr     r22

ResetLeftLoop:
    cpi     r22, NUM_MULT_LIGHTS_L      ; check to see when done with table
    breq    LeftPointMultiplyingLoop          ; and be done when done
    lpm     r16, Z+                     ; get the light code to turn off
	push 	ZL							; save Z for next round
	push 	ZH
    rcall   DisplayLight                ; and turn it off (R17 FALSE)
	pop 	ZH							; get Z back
	pop 	ZL
	inc 	r22
    rjmp    ResetLeftLoop		  		; and keep going

LeftPointMultiplyingLoop:
    cpi     r23, 0                      ; r23 holds our multiplier, check if 0
    breq    ResetLeftMultiplier              
	push 	r23							; save so it doesn't get changed
    rcall   IncrementPlayerScore10      ; give the player 10x multiplier points
	pop 	r23
	dec 	r23
    rjmp    LeftPointMultiplyingLoop   
	
ResetLeftMultiplier:
	ldi 	r18, 1						; reset the multiplier to one
	sts 	AcePtIndex_CCW_L, r18
	rjmp 	EndFreeBallHit     

EndFreeBallHit:
    ret                                 ; done so return

; ==============================================================================
;
; GenLeaf
;
; Description:       This function is called when the ball hits one of the 4 
;                    general leaf bumpers in the main playing field of the
;                    pinball machine. Each will flash a light and increment the
;                    current player's score by 1 point.
;
; Operation:         First calls the FlashQuarterSecond function with the light
;                    passed in from the SensorTable. Then it will call the 
;                    IncrementPlayerScore1 function to give that player 1 point.
;
; Arguments:         light  -   Passed in R16 from the table. This is the LED to
;                               turn on for a quarter second.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  Indirectly changes p1/2Score and the LED Buffer (curDigCol).
;
; Global Variables:  None.
;
; Input:             One of the 6 General Leaf Bumpers Hit.
; Output:            Changes the display when updating player score. Flashes an
;                    LED.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Some Indirectly.
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025

GenLeaf:
    rcall   FlashQuarterSecond          ; Flash the passed in light for 1/4 sec
    rcall   IncrementPlayerScore1       ; Give the player 1 point

EndGenLeaf:
    ret                                 ; done so return

; ==============================================================================
;
; PopBumper
;
; Description:       This function is called when the ball hits one of the 3 
;                    mushroom shaped pop bumpers in the main playing field of 
;                    the pinball machine. Each will flash a light and increment 
;                    the current player's score by 10 points.
;
; Operation:         First calls the FlashQuarterSecond function with the light
;                    passed in from the SensorTable. Then it will call the 
;                    IncrementPlayerScore10 function to give that player 10 pts.
;
; Arguments:         light  -   Passed in R16 from the table. This is the LED to
;                               turn on for a quarter second.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  Indirectly changes p1/2Score and the LED Buffer (curDigCol).
;
; Global Variables:  None.
;
; Input:             One of the 3 Pop Bumpers Hit.
; Output:            Changes the display when updating player score. Flashes an
;                    LED.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Some Indirectly.
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025

PopBumper:
    rcall   FlashQuarterSecond          ; Flash the passed in light for 1/4 sec
    rcall   IncrementPlayerScore10      ; Give the player 10 points

EndPopBumper:
    ret   

; ==============================================================================
;
; LowRoll
;
; Description:       This function is called when the ball hits one of the 2 
;                    rollover sensors at the bottom of the pinball machine
;                    Each will give the current player 100 points.
;
; Operation:         Will call the IncrementPlayerScore100 function to give that 
;                    player 100 pts.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  Indirectly changes p1/2Score.
;
; Global Variables:  None.
;
; Input:             Bottom Rollover Bumper hit.
; Output:            Changes the display when updating player score. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Some Indirectly.
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025
;
;                    Note: Keeping as a separate function for table cleanliness.

LowRoll:
    rcall   IncrementPlayerScore100      ; Give the player 100 points

EndLowRoll:
    ret    

; ==============================================================================
;
; TiltSensor
;
; Description:       When the tilt sensor is hit, no more points can be scored 
;                    in the current round. ONLY if a current game is active. 
;                    Thus, if there is a game_active, it will set a flag that 
;                    is checked in the increment score functions, keeping the 
;                    player from scoring.
;
; Operation:         First checks the game_active flag, and if it is set, it'll
;                    set the TiltFlag too.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  game_active    -   read only. Flag indicating active game.
;                    TiltFlag       -   write only. Flag for a tilt violation.
;
; Global Variables:  None.
;
; Input:             A cheater tried to tilt the game!
; Output:            None. Hah! Take that.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R16
; Stack Depth:       0 bytes
;
; Author:            Benjamin Boone
; Last Modified:     June 14, 2025

TiltSensor:
    lds     r16, game_active        ; check whether there is a game active now
    cpi     r16, FALSE
    breq    EndTiltSensor           ; if not do nothing
    ldi     r16, TRUE               ; if so, stop the player from getting points
    sts     TiltFlag, r16           	; until the ball goes in

EndTiltSensor:
    ret


; ##############################################################################
.dseg
; overall machine variables
game_active:        .byte   1   ; flag indicating if there's a game active now   
any_sensor_hit:     .byte   1   ; flag indicating if a sensor has been hit yet
high_score:         .byte   2   ; the most recent high score of the game in BCD
games_left:         .byte   1   ; the number of games left on the machine in hex

; game specific variables
numPlayers:         .byte   1   ; the number of players in the current game
currentPlayer:      .byte   1   ; holds the code of the current player
p1Score:            .byte   2   ; score of Player 1, in BCD, low byte first
p2Score:            .byte   2   ; score of Player 2, in BCD, low byte first
p1Balls:            .byte   1   ; num balls left for Player 1
p2Balls:            .byte   1   ; num balls left for Player 2

; bonus flag for the toprollover buttons
top_bonus:          .byte   1   ; flag telling which top rollover gets +200 pts
                                    ; FALSE = left, TRUE = right

; for the cardButton function
cardBuffer:         .byte   1   ; holds 8 flags, keeps track of hit card sensors
freeB_KingsR:       .byte   1   ; flag = a free ball available on Kings (R) side
freeB_AcesL:        .byte   1   ; flag = a free ball available on Aces (L) side

; for the rotating bumper, RotButton function
KingPtIndex_CW_R:   .byte   1   ; how many points (/10) for a Kings Free Ball
AcePtIndex_CCW_L:   .byte   1   ; how many points (/10) for an Aces Free Ball

; from the free ball targets
SamePlayerAgain:    .byte   1   ; flag to not switch players at end (free ball)

; for the TiltSensor function
TiltFlag:           .byte   1   ; flag for a tilt violation. Stops scoring.


