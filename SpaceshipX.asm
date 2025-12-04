TITLE MASM Template                        (Project.asm)

INCLUDE Irvine32.inc

; ------------------------------------------------------------
; main entry point in Irvine32 uses decorated symbol start@0
; This EQU tells MASM that "main" refers to start@0, so that
; you can write "call main" if needed.
; ------------------------------------------------------------
main EQU start@0


; ------------------------------------------------------------
; External PROCEDURE DECLARATIONS
; These prototypes inform MASM about procedures implemented
; elsewhere in your project.
; ------------------------------------------------------------

; Determines whether the player has been hit by a meteor.
; temp_coord : coordinate of the meteor or collision object.
HitByMeteor proto, temp_coord:coord

; Copies one coord structure into another.
; temp1 : source coordinate
; temp2 : destination coordinate
CopyCoordFrom proto, temp1 : coord, temp2 : coord

; Prints a number on screen at a given coordinate.
; number : byte to print
; temp_coord : screen position
PrintNum proto, number : byte, temp_coord : coord


; ------------------------------------------------------------
; GAME BOUNDARIES (Screen Limits)
; These constants define the playable area.
; Modify these if window size changes.
; ------------------------------------------------------------
TopBorder    = 1
BottomBorder = 30
LeftBorder   = 1
RightBorder  = 63


; ============================================================
;                EARTH RANGER GAME – DATA STRUCTURES
; ============================================================
; This file defines all visual/gameplay structures:
;   - Player ship ("EarthRanger")
;   - Explosion animation frames
;   - Background elements (plane + border)
;   - Earth (large sprite with per-pixel color attributes)
;   - Number sprites (0–9)
;   - Player bullets
;   - Meteorites
;   - Game Over screen
;   - Life icon
;
; All structures use ASCII graphics stored as byte strings.
; Many include coordinate (coord) structures allowing them
; to be drawn anywhere on the console.
;
; ============================================================


; ============================================================
;                     EARTH RANGER SHIP
; ============================================================
; This structure contains:
;   - 13 ASCII-art lines forming the ship
;   - XY starting position (upper-left corner)
;   - 6 sets of color attributes (one per body line)
;     Each attribute line uses 69 WORDs = one color per char.
; ============================================================

EarthRanger struct

    ; Each body# is one line of the ASCII ship.
    ; All lines must be the same width (69 chars).
    body1  byte "  ______           _   _       _____                             "
    body2  byte " |  ____|         | | | |     |  __ \                            "
    body3  byte " | |__   __ _ _ __| |_| |__   | |__) |__ _ _ __   __ _  ___ _ __ "
    body4  byte " |  __| / _` | '__| __| '_ \  |  _  // _` | '_ \ / _` |/ _ \ '__|"
    body5  byte " | |___| (_| | |  | |_| | | | | | \ \ (_| | | | | (_| |  __/ |   "
    body6  byte " |_____|\__,_|_|   \__|_| |_| |_|  \_\__,_|_| |_|\__, |\___|_|   "
    body7  byte "                                                 |___/           "
    body8  byte "  _____                      ___    _              _             _   "
    body9  byte " |  __ \                    / _ \  | |            | |           | |  "
    body10 byte " | |__) | __ ___  ___ ___  | | | | | |_ ___    ___| |_ __ _ _ __| |_ "
    body11 byte " |  ___/ '__/ _ \/ __/ __| | | | | | __/ _ \  / __| __/ _` | '__| __|"
    body12 byte " | |   | | |  __/\__ \__ \ | |_| | | || (_) | \__ \ || (_| | |  | |_ "
    body13 byte " |_|   |_|  \___||___/___/  \___/   \__\___/  |___/\__\__,_|_|   \__|"

    ; Initial display position of ship.
    ; coord<X,Y>:
    ;     X = horizontal column
    ;     Y = vertical row
    XY coord<22,5>

    ; Per-character color attributes for each row of the ship.
    ; 69 values because each body line is 69 chars wide.
    ; Example color meanings (Windows ConsoleAttribute):
    ;   1 = Blue
    ;   2 = Dark Green
    ;   9 = Light Blue
    ;  10 = Light Green
    ;  14 = Yellow
    ;  15 = White
    attribute1 word 69 DUP(1)
    attribute2 word 69 DUP(9)
    attribute3 word 69 DUP(15)
    attribute4 word 69 DUP(10)
    attribute5 word 69 DUP(2)
    attribute6 word 69 DUP(14)

EarthRanger ends


; ============================================================
;                     EXPLOSION ANIMATION
; ============================================================
; Simple set of explosion patterns used when the ship or
; meteor explodes. “mode” selects which frame is displayed.
; ============================================================

ExplosionAnimation struct
    body1 byte "*"         ; Small spark (frame 0)
    body2 byte "***"       ; Wider burst (frame 1)
    body3 byte "* *"       ; Hollow center (frame 2)
    body4 byte "*   *"     ; Largest frame (frame 3)

    mode byte 0             ; Current animation frame index
    XY coord <0,0>          ; Explosion position
ExplosionAnimation ends


; ============================================================
;                     BACKGROUND PLANE
; ============================================================
; This ASCII plane is used to create a scrolling or stationary
; background behind the main gameplay.
; PlaneLength stores the length of body1.
; ============================================================

BackgroundPlane struct
    body0   byte    "                   _|_                   "
    body1   byte    "                  /   \                  "
    body2   byte    "               __/ (_) \__               "
    body3   byte    "          ____/_ ======= _\____          "
    body4   byte    " ________/ _/ (_)_______(_) \_ \________ "
    body5   byte    "<________     | /   _   \ |     ________>"
    body6   byte    "  O O O  \___  |   (_)   |  ___/  O O O  "
    body7   byte    "             \__\_______/__/             "

    ; CHARACTER WIDTH OF PLANE (used for drawing/scrolling)
    PlaneLength dword LENGTHOF BackgroundPlane.body1

BackgroundPlane ends


; ============================================================
;                     BACKGROUND BORDER
; ============================================================
; Visual border positioning the playfield area.
; XY determines upper-left placement.
; ============================================================

BackgroundBorder struct
    body1 byte "________________________________________________________"
    body2 byte "|                                                      |"
    body3 byte "|______________________________________________________|"
    XY coord<64,0>
BackgroundBorder ends


; ============================================================
;                             EARTH
; ============================================================
; Large ASCII art sphere with detailed color mapping.
; Each “attribute#” line contains per-character WORD colors.
; ============================================================

Earth struct

    body1  byte "           ******************************************           "
    body2  byte "       **************~~~~~~~~~~~****~~~~~~***************       "
    body3  byte "    ******************~~~~~~~~~~~***~~~~~~~~~***************    "
    body4  byte "  **************~~~****~~~~~~~~~~~~~~~~~~~~~~~~***************  "
    body5  byte "**~~~~******~~~~~~~~~***~~~~~~~~~~~~~~~~~~~~~~~~~***********~~**"

    ; Color map for each pixel of Earth (foreground colors)
    ; Numbers represent Windows console color attributes.
    attribute1 word 20 DUP(2), 12 DUP(1), 5 DUP(0Fh), 5 DUP(1), 22 DUP(2)
    attribute2 word 21 DUP(2), 11 DUP(1), 4 DUP(0Fh), 6 DUP(1), 22 DUP(2)
    attribute3 word 22 DUP(2), 11 DUP(1), 3 DUP(0Fh), 9 DUP(1), 19 DUP(2)
    attribute4 word 16 DUP(2), 3 DUP(1), 4 DUP(2), 24 DUP(1), 17 DUP(2)
    attribute5 word 2 DUP(2), 4 DUP(1), 6 DUP(2), 9 DUP(1), 3 DUP(2), \
                     25 DUP(1), 11 DUP(2), 2 DUP(1), 2 DUP(2)

Earth ends


; ============================================================
;                        NUMBER SPRITES
; ============================================================
; Each number is 5 rows tall and used for:
;   - Score display
;   - Countdown timers
;   - Level indicators
; ============================================================

One struct
    body1 byte "   _   "
    body2 byte "  / |  "
    body3 byte "  | |  "
    body4 byte "  | |  "
    body5 byte "  |_|  "
One ends

Two struct
    body1 byte " ____  "
    body2 byte "|___ \ "
    body3 byte " _ _) |"
    body4 byte " / __/ "
    body5 byte "|_____|"
Two ends

Three struct
    body1 byte " _____ "
    body2 byte "|___ / "
    body3 byte "  |_ \ "
    body4 byte "___ ) |"
    body5 byte "|____/ "
Three ends

Four struct
    body1 byte " _  _   "
    body2 byte "| || |  "
    body3 byte "| || |_ "
    body4 byte "|__   _|"
    body5 byte "   |_|  "
Four ends

Five struct
    body1 byte " ____  "
    body2 byte "| ___| "
    body3 byte "|___ \ "
    body4 byte " ___) |"
    body5 byte "|____/ "
Five ends

Six struct
    body1 byte "  __   "
    body2 byte " / /_  "
    body3 byte "| '_ \ "
    body4 byte "| (_) |"
    body5 byte " \___/ "
Six ends

Seven struct
    body1 byte " _____ "
    body2 byte "|___  |"
    body3 byte "   / / "
    body4 byte "  / /  "
    body5 byte " /_/   "
Seven ends

Eight struct
    body1 byte "  ___  "
    body2 byte " ( _ ) "
    body3 byte " / _ \ "
    body4 byte "| (_) |"
    body5 byte " \___/ "
Eight ends

Nine struct
    body1 byte "  ___  "
    body2 byte " / _ \ "
    body3 byte "| (_) |"
    body4 byte " \__, |"
    body5 byte "   /_/ "
Nine ends

Zero struct
    body1 byte "  ___  "
    body2 byte " / _ \ "
    body3 byte "| | | |"
    body4 byte "| |_| |"
    body5 byte " \___/ "
Zero ends


; ============================================================
;                         PLAYER PLANE
; ============================================================
; 3 plane types:
;   plane  = straight
;   lplane = tilted left
;   rplane = tilted right
;
; Used for player rotation animation or enemy sprites.
; ============================================================

PlaneWidth = 5   ; Width used for collision/draw logic

plane struct
    body1   byte    "^"
    body2   byte    "/_\"
    body3   byte    "/   \"
    body4   byte    "/     \"
    body5   byte    "/__[ ]__\"
    body6   byte    "//|||\\"
plane ends

lplane struct
    body1   byte    "/|"
    body2   byte    "(||"
    body3   byte    "/  \"
    body4   byte    "/    \"
    body5   byte    "/_|[___\"
    body6   byte    "\\\\\\\"
lplane ends

rplane struct
    body1   byte    "|\"
    body2   byte    "||)"
    body3   byte    "/  \"
    body4   byte    "/    \"
    body5   byte    "/___|]_\"
    body6   byte    "///////"
rplane ends


; ============================================================
;                           BULLET
; ============================================================
; body  = appearance of bullet
; bool  = active flag (1=bullet exists, 0=not in use)
; XY    = current position on screen
; ============================================================

bullet struct
    body byte "|"         ; Single vertical bullet
    bool byte 0           ; Active/not active
    XY coord <>           ; Position assigned when fired
bullet ends


; ============================================================
;                         METEORITE
; ============================================================
; 2x2 meteor sprite
; bool flag determines if meteor is active
; ============================================================

meteor struct
    body1 byte "##"
    body2 byte "##"
    bool byte 0
    XY coord<0,1>         ; Start slightly off-screen vertically
meteor ends


; ============================================================
;                        GAME OVER SCREEN
; ============================================================
; Large ASCII banner displayed when player loses.
; bool flag controls visibility.
; ============================================================

GameOver struct

    body1   byte    "   ____                         ___                   _ "
    body2   byte    "  / ___| __ _ _ __ ___   ___   / _ \__   _____ _ __  | |"
    body3   byte    " | |  _ / _` | '_ ` _ \ / _ \ | | | \ \ / / _ \ '__| | |"
    body4   byte    " | |_| | (_| | | | | | |  __/ | |_| |\ V /  __/ |    |_|"
    body5   byte    "  \____|\__,_|_| |_| |_|\___|  \___/  \_/ \___|_|    (_)"
    body6   byte    " __   __                 ____                         "
    body7   byte    " \ \ / /__  _   _ _ __  / ___|  ___ ___  _ __ ___   _ "
    body8   byte    "  \ V / _ \| | | | '__| \___ \ / __/ _ \| '__/ _ \ (_)"
    body9   byte    "   | | (_) | |_| | |     ___) | (_| (_) | | |  __/  _ "
    body10  byte    "   |_|\___/ \__,_|_|    |____/ \___\___/|_|  \___| (_)"
    body11  byte    "                                                      "

    bool byte 0           ; 0 = not shown, 1 = shown
    XY coord<31,5>        ; Center-ish placement

GameOver ends


; ============================================================
;                          LIFE ICON
; ============================================================
; ASCII heart-like graphic used to display player lives.
; XY controls where lives are drawn (typically upper-right).
; ============================================================

Lifes struct
    body1 byte " $$$$$$   $$$$$$ "
    body2 byte "$$$$$$$$ $$$$$$$$"
    body3 byte "$$$$$$$$$$$$$$$$$"
    body4 byte " $$$$$$$$$$$$$$$ "
    body5 byte "   $$$$$$$$$$$   "
    body6 byte "     $$$$$$$     "
    body7 byte "       $$$       "
    body8 byte "        $        "
    XY coord<65,18>
Lifes ends


.data
; ============================================================
; MOVEMENT STATE FLAGS
; ============================================================
; BoolMoveLeft   = 1 when plane moved left in the previous frame
; BoolMoveRight  = 1 when plane moved right in the previous frame
; These are used by ClearPlaneLastPosition to determine how the 
; aircraft tail and previous position should be erased.
; ============================================================

BoolMoveLeft   byte 0
BoolMoveRight  byte 0


; ============================================================
; ERASERS – BLANK ASCII STRINGS USED TO CLEAR PREVIOUS DRAW
; ============================================================
; Each eraser corresponds to the width of a plane body row.
; For smooth movement you must erase exact column widths.
; ============================================================

; Erasers for standing (straight plane)
eraser1  byte " "           ; Row 1 (1 char)
eraser2  byte "   "         ; Row 2 (3 chars)
eraser3  byte "     "       ; Row 3 (5 chars)
eraser4  byte "       "     ; Row 4 (7 chars)
eraser5  byte "         "   ; Row 5 (9 chars)

; Erasers for left/right movement (slanted plane)
eraser6  byte "  "          ; Row 1
eraser7  byte "   "         ; Row 2
eraser8  byte "    "        ; Row 3
eraser9  byte "      "      ; Row 4
eraser10 byte "        "    ; Row 5

; Erasers for tail / lowest row
eraser11 byte "       "     ; For last visual row of plane
eraser12 byte "                 " ; Wide area erase (unused here)


; ============================================================
; PLAYER PLANE INSTANCES
; ============================================================
; myplane  = plane facing forward (straight)
; mylplane = left-tilted plane
; myrplane = right-tilted plane
; mytest   = simple debug/test character
; pos      = current top-left coordinate of the plane
; ============================================================

myplane  plane <>      ; Neutral orientation sprite
mylplane lplane <>     ; Left-tilting sprite
myrplane rplane <>     ; Right-tilting sprite
mytest BYTE '1'        ; Possibly a debug or placeholder
pos coord <33,18>      ; Initial player position

; Temporary coordinate for drawing multi-row sprites
temp COORD <>


; ============================================================
; PLAYER BULLETS
; ============================================================
; Each bullet has:
;   - body (visual symbol)
;   - bool (active/inactive)
;   - XY (current position)
; Up to 5 bullets available (3 used by default)
; ============================================================

bullet1 bullet<>
bullet2 bullet<>
bullet3 bullet<>
bullet4 bullet<>
bullet5 bullet<>


; ============================================================
; METEOR INSTANCES
; ============================================================
; 4 meteor objects falling from top.
; BoolFlying determines if meteors currently spawn/accelerate.
; ============================================================

meteor1 meteor<>
meteor2 meteor<>
meteor3 meteor<>
meteor4 meteor<>
BoolFlying byte 0          ; meteor speed-up trigger


; ============================================================
; EXPLOSION ANIMATIONS
; ============================================================
; Each explosion instance contains:
;   - body1–body4 (frames)
;   - mode (current frame)
;   - XY (position)
; explosions1/2/3 are available for bullets & plane collisions
; ============================================================

explode1 ExplosionAnimation<>
explode2 ExplosionAnimation<>
explode3 ExplosionAnimation<>


; ============================================================
; HANDLE STORAGE FOR WINDOWS API OUTPUT
; ============================================================

outputHandle DWORD ?        ; Console output handle
check        DWORD ?        ; Stores returned characters count


; ============================================================
; SCORE SYSTEM
; ============================================================
; score  = numeric score
; myscore = prefix "Score: "
; score# = ASCII sprite digits for displaying score
; ============================================================

score  word 0
myscore byte "Score: ", 0

score1 One<>
score2 Two<>
score3 Three<>
score4 Four<>
score5 Five<>
score6 Six<>
score7 Seven<>
score8 Eight<>
score9 Nine<>
score0 Zero<>


; ============================================================
; EARTH SPRITE INSTANCE
; ============================================================

MyEarth Earth<>


; ============================================================
; BACKGROUND BORDER
; ============================================================

MyBackgroundBorder BackgroundBorder<>
Border byte "|"             ; Simple border symbol for collision check


; ============================================================
; SPEED-UP NOTIFICATION
; ============================================================
; Displays warning text when meteor speed increases.
; SpeedUpNotificationAttribute = color array for each letter.
; BoolSpeedUpNotification = 1 when message should be shown.
; ============================================================

SpeedUpNotification byte "!WARNING! THE METEORS ARE DROPPING FASTER THAN BEFORE!"
SpeedUpNotificationAttribute word 76 DUP (RED)
BoolSpeedUpNotification byte 0


; ============================================================
; BACKGROUND PLANE
; ============================================================

MyBackgroundPlane BackgroundPlane<>


; ============================================================
; "EARTH RANGER" TITLE SCREEN
; ============================================================

GameName EarthRanger<>


; ============================================================
; GAME OVER SCREEN
; ============================================================

Result GameOver<>


; ============================================================
; PLAYER LIFE ICON
; ============================================================

Heart Lifes<>


; ============================================================
; TIME MANAGEMENT / SPAWN TIMERS
; ============================================================
; spawning_time         = general meteor spawn cooldown
; NumberOfTwoSeconds    = counts 2-second intervals (speed-up)
; ============================================================

spawning_time       word 0
NumberOfTwoSeconds  word 0



; ============================================================
.code
; ============================================================
main PROC
    call clrscr

    ; Retrieve Windows console output handle
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax

    call Intro          ; Show title screen
    call StartKey       ; Wait for user to press key '0'
    call SetUp          ; Initialize game state

; ============================================================
;                     MAIN GAME LOOP
; ============================================================

Game:
    call Background
    call InputKey
    call BulletFly
    call SpawnMeteor
    call MeteorFly
    call BulletHit
    call MeteorHitPlane
    call Life

    ; If plane was hit 3 times → game over
    cmp Result.bool, 3
    je Game_over

    call Explosion
    jmp Game

Game_over:
    call Final
main ENDP



; ============================================================
; WAIT FOR START KEY
; ============================================================
; StartKey waits for the player to press '0'.
; Game begins only when '0' is detected.
; ============================================================

StartKey proc uses eax
L1:
    mov eax, 50     ; Delay ~1 second
    call Delay

    call ReadKey
    cmp al, '0'
    je Start

    jmp L1

Start:
    call clrscr
    ret
StartKey endp



; ============================================================
; INPUT KEY PROCESSING
; ============================================================
; Handles:
;   A  → Move left
;   D  → Move right
;   SPACE → Shoot
;   ESC → Quit game
;
; If no key pressed: draws the plane in neutral orientation.
; ============================================================

InputKey proc uses eax
    mov eax, 20     ; Delay ~0.02 sec (smooth control)
    call Delay

    call ReadKey
    jz NoKey        ; No key pressed?

    cmp al, 'a'
    je MoveLeft
    cmp al, 'd'
    je MoveRight
    cmp dx, VK_SPACE
    je Shoot
    cmp dx, VK_ESCAPE
    je quit

; ------------------------------------------------------------
; No input: draw straight plane
; ------------------------------------------------------------

NoKey:
    call ClearPlaneLastPosition

    ; Draw row 1
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body1, \
            lengthof myplane.body1, pos, addr check

    ; Build temp = pos + (x-1, y+1)
    call GetTempXY
    dec temp.X
    inc temp.Y

    ; Draw row 2
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body2, \
            lengthof myplane.body2, temp, addr check

    ; Row 3
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body3, \
            lengthof myplane.body3, temp, addr check

    ; Row 4
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body4, \
            lengthof myplane.body4, temp, addr check

    ; Row 5
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body5, \
            lengthof myplane.body5, temp, addr check

    ; Tail
    inc temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body6, \
            lengthof myplane.body6, temp, addr check

    mov BoolMoveLeft, 0
    mov BoolMoveRight, 0
    ret



; ============================================================
; MOVE LEFT
; ============================================================

MoveLeft:
    ; Check if moving left hits boundary
    mov ax, pos.X
    dec ax
    cmp ax, PlaneWidth
    jb HitBorder

    ; Clear previous graphics
    call ClearPlaneLastPosition

    ; Update X
    dec pos.X

    ; Draw left tilted plane
    call GetTempXY
    dec temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr mylplane.body1, \
            lengthof mylplane.body1, temp, addr check

    inc temp.Y
    dec temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr mylplane.body2, \
            lengthof mylplane.body2, temp, addr check

    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr mylplane.body3, \
            lengthof mylplane.body3, temp, addr check

    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr mylplane.body4, \
            lengthof mylplane.body4, temp, addr check

    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr mylplane.body5, \
            lengthof mylplane.body5, temp, addr check

    inc temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr mylplane.body6, \
            lengthof mylplane.body6, temp, addr check

    mov BoolMoveLeft, 1
    mov BoolMoveRight, 0
    ret



; ============================================================
; MOVE RIGHT
; ============================================================

MoveRight:
    mov ax, pos.X
    inc ax
    cmp ax, RightBorder - PlaneWidth + 1
    ja HitBorder

    call ClearPlaneLastPosition

    inc pos.X

    call GetTempXY
    invoke WriteConsoleOutputCharacter, outputHandle, addr myrplane.body1, \
            lengthof myrplane.body1, temp, addr check

    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myrplane.body2, \
            lengthof myrplane.body2, temp, addr check

    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myrplane.body3, \
            lengthof myrplane.body3, temp, addr check

    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myrplane.body4, \
            lengthof myrplane.body4, temp, addr check

    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myrplane.body5, \
            lengthof myrplane.body5, temp, addr check

    inc temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myrplane.body6, \
            lengthof myrplane.body6, temp, addr check

    mov BoolMoveLeft, 0
    mov BoolMoveRight,1

HitBorder:
    ret



; ============================================================
; SHOOTING SYSTEM
; ============================================================
; First available (inactive) bullet is activated.
; Bullet starting position = current plane position.
; ============================================================

Shoot:
    cmp bullet1.bool, 1
    jne Shoot_Bullet1
    cmp bullet2.bool, 1
    jne Shoot_Bullet2
    cmp bullet3.bool, 1
    jne Shoot_Bullet3
    ; bullet4/5 disabled optionally
    ret

Shoot_Bullet1:
    mov bullet1.bool, 1
    movzx eax, pos.X
    mov bullet1.XY.X, ax
    movzx eax, pos.Y
    mov bullet1.XY.Y, ax
    ret

Shoot_Bullet2:
    mov bullet2.bool, 1
    movzx eax, pos.X
    mov bullet2.XY.X, ax
    movzx eax, pos.Y
    mov bullet2.XY.Y, ax
    ret

Shoot_Bullet3:
    mov bullet3.bool, 1
    movzx eax, pos.X
    mov bullet3.XY.X, ax
    movzx eax, pos.Y
    mov bullet3.XY.Y, ax
    ret


; Exit program
quit:
    exit

InputKey endp



; ============================================================
; CLEAR PREVIOUS PLANE POSITION
; ============================================================
; Uses BoolMoveLeft / BoolMoveRight to determine which
; eraser widths to use. Prevents leftover ASCII.
; ============================================================

ClearPlaneLastPosition proc uses eax

    call GetTempXY

    ; Case 1: last move was LEFT
    cmp BoolMoveLeft, 1
    je LastMoveWasLeft

    ; Case 2: last move was RIGHT
    cmp BoolMoveRight, 1
    je LastMoveWasRight

    ; Case 3: plane did not move last frame
DidNotMoveLastSecond:
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser1, lengthof eraser1, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser2, lengthof eraser2, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser3, lengthof eraser3, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser4, lengthof eraser4, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser5, lengthof eraser5, temp, addr check
    inc temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser11, lengthof eraser11, temp, addr check
    jmp finish


; ------------------------------------------------------------
; Last frame was LEFT movement → erase slanted-left widths
; ------------------------------------------------------------

LastMoveWasLeft:
    dec temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check
    inc temp.Y
    dec temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser7, lengthof eraser7, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser8, lengthof eraser8, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser9, lengthof eraser9, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser10, lengthof eraser10, temp, addr check
    inc temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser11, lengthof eraser11, temp, addr check
    jmp finish


; ------------------------------------------------------------
; Last frame was RIGHT movement → erase slanted-right widths
; ------------------------------------------------------------

LastMoveWasRight:
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser7, lengthof eraser7, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser8, lengthof eraser8, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser9, lengthof eraser9, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser10, lengthof eraser10, temp, addr check
    inc temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser11, lengthof eraser11, temp, addr check

finish:
    ret
ClearPlaneLastPosition endp

; =====================================================================
;  BULLET FLYING ROUTINE
;  This procedure updates all bullets currently active on screen.
;  It moves each bullet upward, erases its previous position and
;  removes it once it reaches the top boundary.
; =====================================================================

BulletFly proc uses eax

; -------------------------------
; Check if bullet #1 is active
; -------------------------------
CheckBullet1:
    cmp bullet1.bool, 1       ; bullet1.bool = 1 → bullet is flying
    je Bullet1_Flying

; -------------------------------
; Check if bullet #2 is active
; -------------------------------
CheckBullet2:
    cmp bullet2.bool, 1
    je Bullet2_Flying

; -------------------------------
; Check if bullet #3 is active
; -------------------------------
CheckBullet3:
    cmp bullet3.bool, 1
    je Bullet3_Flying

; -------------------------------
; Check if bullet #4 is active
; -------------------------------
CheckBullet4:
    cmp bullet4.bool, 1
    je Bullet4_Flying

; -------------------------------
; Check if bullet #5 is active
; -------------------------------
CheckBullet5:
    cmp bullet5.bool, 1
    je Bullet5_Flying
    ret                         ; none are active → exit


; =====================================================================
;  BULLET #1 FLYING
; =====================================================================
Bullet1_Flying:
    ; erase old bullet position
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser1, lengthof eraser1, bullet1.XY, addr check

    mov ax, bullet1.XY.Y
    dec ax                      ; compute next Y (moving upward)
    cmp ax, 1                   ; reached top row?
    jae Bullet1_NotYetTop       ; still within screen

    ; bullet hit the top border → deactivate
    mov bullet1.bool, 0
    mov bullet1.XY.Y, 25        ; move it off-screen for safety
    jmp CheckBullet2            ; continue to next bullet

Bullet1_NotYetTop:
    dec bullet1.XY.Y            ; actually move it up
    invoke WriteConsoleOutputCharacter, outputHandle, addr bullet1.body, lengthof bullet1.body, bullet1.XY, addr check
    jmp CheckBullet2


; =====================================================================
;  BULLET #2 FLYING
; =====================================================================
Bullet2_Flying:
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser1, lengthof eraser1, bullet2.XY, addr check
    mov ax, bullet2.XY.Y
    dec ax
    cmp ax, 1
    jae Bullet2_NotYetTop

    mov bullet2.bool, 0
    mov bullet2.XY.Y, 25
    jmp CheckBullet3

Bullet2_NotYetTop:
    dec bullet2.XY.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr bullet2.body, lengthof bullet2.body, bullet2.XY, addr check
    jmp CheckBullet3


; =====================================================================
;  BULLET #3 FLYING
; =====================================================================
Bullet3_Flying:
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser1, lengthof eraser1, bullet3.XY, addr check
    mov ax, bullet3.XY.Y
    dec ax
    cmp ax, 1
    jae Bullet3_NotYetTop

    mov bullet3.bool, 0
    mov bullet3.XY.Y, 25
    jmp CheckBullet4

Bullet3_NotYetTop:
    dec bullet3.XY.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr bullet3.body, lengthof bullet3.body, bullet3.XY, addr check
    jmp CheckBullet4


; =====================================================================
;  BULLET #4 FLYING
; =====================================================================
Bullet4_Flying:
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser1, lengthof eraser1, bullet4.XY, addr check
    mov ax, bullet4.XY.Y
    dec ax
    cmp ax, 1
    jae Bullet4_NotYetTop

    mov bullet4.bool, 0
    mov bullet4.XY.Y, 25
    jmp CheckBullet5

Bullet4_NotYetTop:
    dec bullet4.XY.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr bullet4.body, lengthof bullet4.body, bullet4.XY, addr check
    jmp CheckBullet5


; =====================================================================
;  BULLET #5 FLYING
; =====================================================================
Bullet5_Flying:
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser1, lengthof eraser1, bullet5.XY, addr check
    mov ax, bullet5.XY.Y
    dec ax
    cmp ax , 1
    jae Bullet5_NotYetTop

    mov bullet5.bool, 0
    mov bullet5.XY.Y, 25
    ret

Bullet5_NotYetTop:
    dec bullet5.XY.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr bullet5.body, lengthof bullet5.body, bullet5.XY, addr check
    ret

BulletFly endp



; =====================================================================
;  SPAWN METEOR (ONLY IF NONE ACTIVE)
; =====================================================================

SpawnMeteor proc uses eax
    cmp meteor1.bool, 1         ; meteor already active?
    jne m1                     ; if not → spawn new
    ret

m1:
    mov eax, 53                ; choose random X within 53 columns
    call RandomRange
    add ax, 5                  ; shift right so meteor never spawns at border
    mov meteor1.XY.X, ax
    mov meteor1.XY.Y, -1       ; start above screen
    mov meteor1.bool, 1        ; mark meteor as flying
    ret
SpawnMeteor endp



; =====================================================================
;  METEOR FALLING MOTION
; =====================================================================

MeteorFly proc uses eax

CheckFlyingTime:
    call TimeToFly             ; spawn timing logic
    cmp BoolFlying, 1
    je Fly                     ; only move when timer fires
    ret


; -------------------------------
; meteor 1 flying logic
; -------------------------------
Fly:
CheckMeteor1:
    cmp meteor1.bool, 1
    je m1Flying
    ret

m1Flying:
    ; erase meteor previous location
    movzx eax, meteor1.XY.X
    mov temp.X, ax
    movzx eax, meteor1.XY.Y
    mov temp.Y, ax
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check

    mov ax, meteor1.XY.Y
    inc ax                      ; next Y coordinate (downward)
    cmp ax, 23                  ; bottom boundary?
    jbe NotYetBottom

    ; meteor reached bottom → remove it, count as plane hit
    mov meteor1.bool, 0
    inc result.bool

CheckExplosion1:
    cmp explode1.mode, 0
    je explosion11
    ret

explosion11:
    mov explode1.mode, 1
    movzx eax, meteor1.XY.X
    add eax, 2                  ; position explosion slightly centered
    mov explode1.XY.X, ax
    movzx eax, meteor1.XY.Y
    mov explode1.XY.Y, ax
    ret

NotYetBottom:
    inc meteor1.XY.Y            ; move meteor downward
    movzx eax, meteor1.XY.X
    mov temp.X, ax
    movzx eax, meteor1.XY.Y
    mov temp.Y, ax
    invoke WriteConsoleOutputCharacter, outputHandle, addr meteor1.body1, lengthof meteor1.body1, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr meteor1.body2, lengthof meteor1.body2, temp, addr check
    ret
MeteorFly endp



; =====================================================================
;   BULLET → METEOR COLLISION DETECTION
; =====================================================================

BulletHit proc uses eax ebx edx

CheckMeteor1Flying:
    cmp meteor1.bool, 1
    je Meteor1IsFlying
    ret

Meteor1IsFlying:

; --------------------------------------------------------
;  CHECK BULLET #1 COLLISION
; --------------------------------------------------------

check_bullet1:

    ; compare bullet Y with meteor Y (or meteor Y+1)
    mov ax, bullet1.XY.Y
    mov bx, meteor1.XY.Y
    mov dx, bx
    inc bx
    cmp ax, bx
    je SameAltitude1
    cmp ax, dx
    je SameAltitude1
    jmp check_bullet2

SameAltitude1:
    ; compare bullet X with meteor X (meteor is 2 chars wide)
    mov ax, bullet1.XY.X
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
    cmp ax, bx
    je SameXY1
    cmp ax, dx
    je SameXY1
    jmp check_bullet2

SameXY1:
    inc score
    mov bullet1.bool, 0
    mov meteor1.bool, 0

    ; erase meteor graphic
    movzx eax, meteor1.XY.X
    mov temp.X, ax
    movzx eax, meteor1.XY.Y
    mov temp.Y, ax
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check

CheckExplosion1:
    cmp explode1.mode, 0
    je explosion11
    ret

explosion11:
    mov explode1.mode, 1
    movzx eax, bullet1.XY.X
    mov explode1.XY.X, ax
    movzx eax, bullet1.XY.Y
    mov explode1.XY.Y, ax
    mov bullet1.XY.Y, 25     ; reset bullet offscreen
    ret



; --------------------------------------------------------
;  CHECK BULLET #2 COLLISION
; --------------------------------------------------------

check_bullet2:

    mov ax, bullet2.XY.Y
    mov bx, meteor1.XY.Y
    mov dx, bx
    inc bx
    cmp ax, bx
    je SameAltitude2
    cmp ax, dx
    je SameAltitude2
    jmp check_bullet3

SameAltitude2:
    mov ax, bullet2.XY.X
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
    cmp ax, bx
    je SameXY2
    cmp ax, dx
    je SameXY2
    jmp check_bullet3

SameXY2:
    inc score
    mov bullet2.bool, 0
    mov meteor1.bool, 0
    movzx eax, meteor1.XY.X
    mov temp.X, ax
    movzx eax, meteor1.XY.Y
    mov temp.Y, ax
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check

CheckExplosion2:
    cmp explode1.mode, 0
    je explosion12
    ret

explosion12:
    mov explode1.mode, 1
    movzx eax, bullet2.XY.X
    mov explode1.XY.X, ax
    movzx eax, bullet2.XY.Y
    mov explode1.XY.Y, ax
    mov bullet2.XY.Y, 25
    ret

; --------------------------------------------------------
;  CHECK BULLET #3 COLLISION
; --------------------------------------------------------

check_bullet3:

    mov ax, bullet3.XY.Y
    mov bx, meteor1.XY.Y
    mov dx, bx
    inc bx
    cmp ax, bx
    je SameAltitude3
    cmp ax, dx
    je SameAltitude3
    ret
SameAltitude3:
    mov ax, bullet3.XY.X
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
    cmp ax, bx
    je SameXY3
    cmp ax, dx
    je SameXY3
    ret
SameXY3:
    inc score
    mov bullet3.bool, 0
    mov meteor1.bool, 0
    movzx eax, meteor1.XY.X
    mov temp.X, ax
    movzx eax, meteor1.XY.Y
    mov temp.Y, ax
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp, addr check

CheckExplosion3:
    cmp explode1.mode, 0
    je explosion13
    ret
explosion13:
    mov explode1.mode, 1
    movzx eax, bullet3.XY.X
    mov explode1.XY.X, ax
    movzx eax, bullet3.XY.Y
    mov explode1.XY.Y, ax
    mov bullet3.XY.Y, 25
    ret

; --------------------------------------------------------
;  CHECK BULLET #4 COLLISION
; --------------------------------------------------------

; check bullet4
; TO-DO

; --------------------------------------------------------
;  CHECK BULLET #5 COLLISION
; --------------------------------------------------------
; check bullet5
; TO-DO

Finish:
    ret
BulletHit endp

MeteorHitPlane proc uses eax ebx edx

; copy plane XY into temp
    movzx eax, pos.X
    mov temp.X, ax
    movzx eax, pos.Y
    mov temp.Y, ax

; The plane move left
    cmp BoolMoveLeft, 1
    je MoveLeft


; The plane move right
    cmp BoolMoveRight, 1
    je MoveRight

; The plane stand still
StandStill:
    call CheckMeteorHitWhenStandStill
    ret

MoveRight:
    call CheckMeteorHitWhenMoveRight
    ret

MoveLeft:
    call CheckMeteorHitWhenMoveLeft

    ret
MeteorHitPlane endp

CheckMeteorHitWhenStandStill proc uses eax ebx edx
CheckMeteor1Flying:
    cmp meteor1.bool, 1
    je Meteor1IsFlying
    ret
Meteor1IsFlying:
;compare with tip of the plane
    mov bx, meteor1.XY.Y
    mov dx, bx
    inc bx
    cmp temp.Y, bx
    je SameAltitudeWithTip
    cmp temp.Y, dx
    je SameAltitudeWithTip
;compare with one block left/right of the plane
    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide1
    cmp temp.Y, dx
    je SameAltitudeWithSide1

; compare with two block left/right of the plane
    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide2
    cmp temp.Y, dx
    je SameAltitudeWithSide2

; compare with three block left/right of the plane
    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide3
    cmp temp.Y, dx
    je SameAltitudeWithSide3

    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide4
    cmp temp.Y, dx
    je SameAltitudeWithSide4

DidNotHitPlane:
    ret

;If the meteor is in the same altitude with the tip of the plane
SameAltitudeWithTip:
    mov ax, temp.X
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
    cmp ax, bx
    je GotHit
    cmp ax, dx
    je GotHit
    ret


;If the meteor is in the same altitude with one block left/right of the plane
SameAltitudeWithSide1:
; right 1
    inc temp.X
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; left 1
    sub temp.X, 2
; compare with left
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret

;If the meteor is in the same altitude with two block left/right of of the plane
SameAltitudeWithSide2:
; right 2
    add temp.X,2
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; left 2
    sub temp.X, 4
; compare with left
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret

;If the meteor is in the same altitude with three block left/right of the plane
SameAltitudeWithSide3:
    ; right 3
    add temp.X, 3
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; left 3
    sub temp.X, 6
; compare with left
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret

SameAltitudeWithSide4:
    ; right 4
    add temp.X, 4
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; left 4
    sub temp.X, 8
; compare with left
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit

    ret
GotHit:
    add Result.bool, 1
    invoke HitByMeteor, temp
    ret

CheckMeteorHitWhenStandStill endp

; The plane move left
CheckMeteorHitWhenMoveRight proc uses eax ebx edx

CheckMeteor1Flying:
    cmp meteor1.bool, 1
    je Meteor1IsFlying
    ret

Meteor1IsFlying:
;compare with tip of the plane
    mov bx, meteor1.XY.Y
    mov dx, bx
    inc bx
    cmp temp.Y, bx
    je SameAltitudeWithTip
    cmp temp.Y, dx
    je SameAltitudeWithTip
;compare with one block left/right of the plane
    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide1
    cmp temp.Y, dx
    je SameAltitudeWithSide1

; compare with two block left/right of the plane
    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide2
    cmp temp.Y, dx
    je SameAltitudeWithSide2

; compare with three block left/right of the plane
    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide3
    cmp temp.Y, dx
    je SameAltitudeWithSide3

    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide4
    cmp temp.Y, dx
    je SameAltitudeWithSide4

DidNotHitPlane:
    ret

;If the meteor is in the same altitude with the tip of the plane
SameAltitudeWithTip:
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with tip
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit

    inc temp.X
; compare with right1
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret

;If the meteor is in the same altitude with one block left/right of the plane
SameAltitudeWithSide1:
; right 1
    inc temp.X
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with right 1
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit

; right 2
    inc temp.X
; compare with right 2
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit

; body
    sub temp.X, 2
; compare with body
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret

;If the meteor is in the same altitude with two block left/right of of the plane
SameAltitudeWithSide2:
; right 3
    add temp.X, 3
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; body
    sub temp.X, 3
; compare with body
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret


;If the meteor is in the same altitude with three block left/right of the plane
SameAltitudeWithSide3:
    ; right 4
    add temp.X, 4
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; rleft 1
    sub temp.X, 5
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret

SameAltitudeWithSide4:
    ; left 2
    sub temp.X, 2
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with left
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; right 5
    add temp.X, 7
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit

    ret

GotHit:
    invoke HitByMeteor, temp
    add Result.bool, 1
    ret

CheckMeteorHitWhenMoveRight endp




CheckMeteorHitWhenMoveLeft proc uses eax ebx edx

CheckMeteor1Flying:
    cmp meteor1.bool, 1
    je Meteor1IsFlying
    ret

Meteor1IsFlying:
;compare with tip of the plane
    mov bx, meteor1.XY.Y
    mov dx, bx
    inc bx
    cmp temp.Y, bx
    je SameAltitudeWithTip
    cmp temp.Y, dx
    je SameAltitudeWithTip
;compare with one block left/right of the plane
    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide1
    cmp temp.Y, dx
    je SameAltitudeWithSide1

; compare with two block left/right of the plane
    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide2
    cmp temp.Y, dx
    je SameAltitudeWithSide2

; compare with three block left/right of the plane
    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide3
    cmp temp.Y, dx
    je SameAltitudeWithSide3

    inc temp.Y
    cmp temp.Y, bx
    je SameAltitudeWithSide4
    cmp temp.Y, dx
    je SameAltitudeWithSide4

DidNotHitPlane:
    ret

;If the meteor is in the same altitude with the tip of the plane
SameAltitudeWithTip:
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with tip
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit

    dec temp.X
; compare with left 1
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret

;If the meteor is in the same altitude with one block left/right of the plane
SameAltitudeWithSide1:
; left 1
    dec temp.X
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with left 1
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit

; left 2
    dec temp.X
; compare with left 2
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit

; body
    add temp.X, 2
; compare with body
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret

;If the meteor is in the same altitude with two block left/right of of the plane
SameAltitudeWithSide2:
; left 3
    sub temp.X, 3
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with left
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; body
    add temp.X, 3
; compare with body
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret


;If the meteor is in the same altitude with three block left/right of the plane
SameAltitudeWithSide3:
    ; left 4
    sub temp.X, 4
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with left
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; right 1
    add temp.X, 5
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
    ret

SameAltitudeWithSide4:
    ; right 2
    add temp.X, 2
    mov bx, meteor1.XY.X
    mov dx, bx
    inc dx
; compare with right
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit
; left 5
    sub temp.X, 7
; compare with left
    cmp temp.X, bx
    je GotHit
    cmp temp.X, dx
    je GotHit

    ret

GotHit:
    add Result.bool, 1
    invoke HitByMeteor, temp
    ret
CheckMeteorHitWhenMoveLeft endp


; explosion

Explosion proc

CheckExplosion1:
    cmp explode1.mode, 0
    jne Exploding
    ret
Exploding:
    movzx eax, explode1.XY.X
    mov temp.X, ax
    movzx eax, explode1.XY.Y
    mov temp.Y, ax
    cmp explode1.mode, 1
    je Ex1M1
    cmp explode1.mode, 2
    je Ex1M2
    cmp explode1.mode, 3
    je Ex1M3
    cmp explode1.mode, 4
    je Ex1M4
    ret
Ex1M1:
    invoke WriteConsoleOutputCharacter, outputHandle, addr explode1.body1, lengthof explode1.body1, temp, addr check
    inc explode1.mode
    ret
Ex1M2:
    ; clear last explosion
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser1, lengthof eraser1, temp, addr check

    dec temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr explode1.body1, lengthof explode1.body1, temp, addr check
    inc temp.Y
    dec temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr explode1.body2, lengthof explode1.body2, temp, addr check
    inc temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr explode1.body1, lengthof explode1.body1, temp, addr check
    inc explode1.mode
    ret
Ex1M3:
    ; clear last explosion
    dec temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser1, lengthof eraser1, temp, addr check
    inc temp.Y
    dec temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser7, lengthof eraser7, temp, addr check
    inc temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser1, lengthof eraser1, temp, addr check

    sub temp.Y, 2
    dec temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr explode1.body3, lengthof explode1.body3, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr explode1.body4, lengthof explode1.body4, temp, addr check
    inc temp.Y
    inc temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr explode1.body3, lengthof explode1.body3, temp, addr check
    inc explode1.mode
    ret
Ex1M4:
    ; clear last explosion
    dec temp.Y
    dec temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser7, lengthof eraser7, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser9, lengthof eraser9, temp, addr check
    inc temp.Y
    inc temp.X
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser7, lengthof eraser7, temp, addr check
    mov explode1.mode, 0
    ret

    ret
Explosion endp



SetUp proc uses eax

    ; print plane
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body1, lengthof myplane.body1, pos, addr check
    call GetTempXY
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body2, lengthof myplane.body2, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body3, lengthof myplane.body3, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body4, lengthof myplane.body4, temp, addr check
    dec temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body5, lengthof myplane.body5, temp, addr check
    inc temp.X
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr myplane.body6, lengthof myplane.body6, temp, addr check

    ret

SetUp endp

Background proc uses eax esi ecx
    local WarningXY : coord
    local BorderXY : coord
    local PlaneXY : coord
    local EarthXY : coord

    mov BorderXY.X, 64
    mov BorderXY.Y, 0
    ; Print Background Border
    invoke WriteConsoleOutputCharacter, outputHandle, addr MyBackgroundBorder.body1, lengthof MyBackgroundBorder.body1, BorderXY, addr check
    inc BorderXY.Y
    mov ecx, 13
PrintBorder:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, addr MyBackgroundBorder.body2, lengthof MyBackgroundBorder.body2, BorderXY, addr check
    inc BorderXY.Y
    pop ecx
    loop PrintBorder
    invoke WriteConsoleOutputCharacter, outputHandle, addr MyBackgroundBorder.body3, lengthof MyBackgroundBorder.body1, BorderXY, addr check

    mov ecx, 14
    mov BorderXY.X, 64
    mov BorderXY.Y, 15
PrintBottomBorder:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, addr Border, 1, BorderXY, addr check
    add BorderXY.X, 55
    invoke WriteConsoleOutputCharacter, outputHandle, addr Border, 1, BorderXY, addr check
    sub BorderXY.X, 55
    inc BorderXY.Y
    pop ecx
    loop PrintBottomBorder
    invoke WriteConsoleOutputCharacter, outputHandle, addr MyBackgroundBorder.body3, lengthof MyBackgroundBorder.body1, BorderXY, addr check


    ; Print Earth
    mov EarthXY.X, 0
    mov EarthXY.Y, 25
    mov ecx, 5
    mov esi, offset MyEarth.body1
    mov edi, offset MyEarth.attribute1
PrintEarth:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof Earth.body1, EarthXY, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, edi, lengthof Earth.body1, EarthXY, addr check
    inc EarthXY.Y
    add esi, SIZEOF Earth.body1
    add edi, SIZEOF Earth.attribute1
    pop ecx
    loop PrintEarth

    ; Print Background Plane
    mov PlaneXY.X, 72
    mov PlaneXY.Y, 3
    mov esi, OFFSET MyBackgroundPlane.body0
    mov ecx, 8
PrintPlane:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, MyBackgroundPlane.PlaneLength, PlaneXY, addr check
    inc PlaneXY.Y
    add esi, MyBackgroundPlane.PlaneLength
    pop ecx
    loop PrintPlane

; Print Score

    mov dh, 12
    mov dl, 108
    call GoToXY
    mov edx, offset myscore
    call WriteString
    movzx eax, score
    call WriteDec

; Print Speed Up Notification
    cmp BoolSpeedUpNotification, 1
    jne Finish
    cmp spawning_time, 30
    jb Finish
    mov WarningXY.X, 65
    mov WarningXY.Y, 13
    invoke WriteConsoleOutputCharacter, outputHandle, addr SpeedUpNotification, lengthof SpeedUpNotification, WarningXY, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr SpeedUpNotificationAttribute, lengthof SpeedUpNotification, WarningXY, addr check

Finish:
    ret

Background endp

Intro proc
    ; print earthranger
    movzx eax, GameName.XY.X
    mov temp.X, ax
    movzx eax, GameName.XY.Y
    mov temp.Y, ax
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body1, lengthof GameName.body1, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute1, lengthof GameName.body1, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body2, lengthof GameName.body2, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute1, lengthof GameName.body2, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body3, lengthof GameName.body3, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute2, lengthof GameName.body3, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body4, lengthof GameName.body4, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute3, lengthof GameName.body4, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body5, lengthof GameName.body5, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute4, lengthof GameName.body5, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body6, lengthof GameName.body6, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute5, lengthof GameName.body4, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body7, lengthof GameName.body7, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute5, lengthof GameName.body5, temp, addr check
    sub temp.X, 4
    add temp.Y, 5
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body8, lengthof GameName.body8, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute6, lengthof GameName.body8, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body9, lengthof GameName.body9, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute6, lengthof GameName.body9, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body10, lengthof GameName.body10, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute6, lengthof GameName.body10, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body11, lengthof GameName.body11, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute6, lengthof GameName.body11, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body12, lengthof GameName.body12, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute6, lengthof GameName.body12, temp, addr check
    inc temp.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr GameName.body13, lengthof GameName.body13, temp, addr check
    invoke WriteConsoleOutputAttribute, outputHandle, addr GameName.attribute6, lengthof GameName.body13, temp, addr check

    ret

Intro endp
; get x and y coordinate into temp

GetTempXY proc uses eax
    movzx eax, pos.X
    mov temp.X, ax
    movzx eax, pos.Y
    mov temp.Y, ax
    ret
GetTempXY endp



TimeToFly proc uses eax ebx

    inc spawning_time
    cmp NumberOfTwoSeconds, 15
    ja WarningNotification
    mov BoolSpeedUpNotification, 0
CheckSpeedUpTime :
    cmp NumberOfTwoSeconds, 20
    ja Fast

Slow:
    mov ax, spawning_time
    mov bl, 7
    div bl
    cmp ah, 0
    je DivideByFour
    mov BoolFlying, 0

CheckTwoSeconds:
    cmp spawning_time, 60
    je TwoSeconds
    ret

WarningNotification:
    mov BoolSpeedUpNotification, 1
    jmp CheckSpeedUpTime

Fast:
    mov ax, spawning_time
    mov bl, 5
    div bl
    cmp ah,0
    je DivideByThree
    mov BoolFlying, 0
    jmp CheckTwoSeconds

TwoSeconds:
    inc NumberOfTwoSeconds
    mov spawning_time, 0
    jmp CheckOneMinute

CheckOneMinute:
    cmp NumberOfTwoSeconds, 30
    jne Finish
    mov NumberOfTwoSeconds, 0
Finish:
    ret

DivideByFour:
    mov BoolFlying, 1
    jmp CheckTwoSeconds

DivideByThree:
    mov BoolFlying, 1
    jmp CheckTwoSeconds

TimeToFly endp

HitByMeteor proc uses eax, temp_coord:coord

    mov meteor1.bool, 0
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp_coord, addr check
    inc temp_coord.Y
    invoke WriteConsoleOutputCharacter, outputHandle, addr eraser6, lengthof eraser6, temp_coord, addr check
    dec temp_coord.Y
    jmp CheckExplosion
    ret

CheckExplosion:
    cmp explode1.mode, 0
    je explosion1
    ret
explosion1:
    mov explode1.mode, 1
    movzx eax, temp_coord.X
    mov explode1.XY.X, ax
    movzx eax, temp_coord.Y
    mov explode1.XY.Y, ax
    ret

HitByMeteor endp

CopyCoordFrom proc uses eax, temp1 : coord, temp2 : coord
    mov eax, 0
    mov ax, temp1.X
    mov temp2.X, ax
    mov ax, temp1.Y
    mov temp2.Y, ax
    ret
CopyCoordFrom endp

Final proc uses eax ebx ecx esi edi
    ; print Game Over
    call clrscr
    movzx eax, Result.XY.X
    mov temp.X, ax
    movzx eax, Result.XY.Y
    mov temp.Y, ax

    mov ecx, 5
    mov esi, offset Result.body1
PrintG:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof Result.body1, temp, addr check
    inc temp.Y
    add esi, sizeof result.body1
    pop ecx
    loop Printg

    sub temp.X, 13
    add temp.Y, 6
    mov ecx, 6
    mov esi, offset Result.body6
PrintS:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof Result.body6, temp, addr check
    inc temp.Y
    add esi, sizeof result.body6
    pop ecx
    loop PrintS

    mov temp.X, 74
    mov temp.Y, 16
    mov ax, score
    mov bl, 100
    div bl
    invoke PrintNum, al, temp
    add temp.X, 8
    movzx bx, ah
    mov ax, bx
    mov bl, 10
    div bl
    invoke PrintNum, al, temp
    add temp.X, 8
    invoke PrintNum, ah, temp

    ret
Final endp

Life proc uses eax
    movzx eax, Heart.XY.X
    mov temp.X, ax
    movzx eax, Heart.XY.Y
    mov temp.Y, ax
    cmp Result.bool, 1
    ja Life1
    je Life2
    jb Life3
;3 life remaining
Life3:
    mov ecx, 8
    mov esi, offset Heart.body1
print3l:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof Heart.body1, temp, addr check
    add temp.X, 18
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof Heart.body1, temp, addr check
    add temp.X, 18
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof Heart.body1, temp, addr check
    sub temp.X, 36
    inc temp.Y
    add esi, sizeof Heart.body1
    pop ecx
    loop print3l

    sub temp.Y, 8
    jmp EndofJudge
;2 life remaining
Life2:
    mov ecx, 8
    mov esi, offset Heart.body1
print2l:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof Heart.body1, temp, addr check
    add temp.X, 18
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof Heart.body1, temp, addr check
    sub temp.X, 18
    inc temp.Y
    add esi, sizeof Heart.body1
    pop ecx
    loop print2l

    sub temp.Y, 8
    add temp.X, 36
    mov ecx, 8
    mov esi, offset eraser12
erase1l:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof eraser12, temp, addr check
    inc temp.Y
    pop ecx
    loop erase1l
    jmp EndofJudge
;1 life remaining
Life1:
    mov ecx, 8
    mov esi, offset heart.body1
print1l:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof Heart.body1, temp, addr check
    inc temp.Y
    add esi, sizeof heart.body1
    pop ecx
    loop print1l
    sub temp.Y, 8
    add temp.X, 18
    mov ecx, 8
    mov esi, offset eraser12
erase2l:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, lengthof eraser12, temp, addr check
    inc temp.Y
    pop ecx
    loop erase2l
    jmp EndofJudge
EndOfJudge:
    ret
Life endp

PrintNum proc uses eax ecx, number : byte, temp_coord : coord

    mov ecx, 5
    mov esi, offset score0.body1
    cmp number, 0
    je pzero
    mov esi, offset score1.body1
    cmp number, 1
    je pone
    mov esi, offset score2.body1
    cmp number, 2
    je ptwo
    mov esi, offset score3.body1
    cmp number, 3
    je pthree
    mov esi, offset score4.body1
    cmp number, 4
    je pfour
    mov esi, offset score5.body1
    cmp number, 5
    je pfive
    mov esi, offset score6.body1
    cmp number, 6
    je psix
    mov esi, offset score7.body1
    cmp number, 7
    je pseven
    mov esi, offset score8.body1
    cmp number, 8
    je peight
    mov esi, offset score9.body1
pnine:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof nine.body1, temp_coord, addr check
    add esi, sizeof nine.body1
    inc temp_coord.Y
    pop ecx
    loop pnine
    ret

pzero:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof zero.body1, temp_coord, addr check
    inc temp_coord.Y
    add esi, sizeof zero.body1
    pop ecx
    loop pzero
    ret

pone:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof one.body1, temp_coord, addr check
    inc temp_coord.Y
    add esi, sizeof one.body1
    pop ecx
    loop pone
    ret
ptwo:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof two.body1, temp_coord, addr check
    inc temp_coord.Y
    add esi, sizeof two.body1
    pop ecx
    loop ptwo
    ret
pthree:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof three.body1, temp_coord, addr check
    inc temp_coord.Y
    add esi, sizeof three.body1
    pop ecx
    loop pthree
    ret
pfour:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof four.body1, temp_coord, addr check
    inc temp_coord.Y
    add esi, sizeof four.body1
    pop ecx
    loop pfour
    ret
pfive:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof five.body1, temp_coord, addr check
    inc temp_coord.Y
    add esi, sizeof five.body1
    pop ecx
    loop pfive
    ret
psix:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof six.body1, temp_coord, addr check
    inc temp_coord.Y
    add esi, sizeof six.body1
    pop ecx
    loop psix
    ret
pseven:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof seven.body1, temp_coord, addr check
    inc temp_coord.Y
    add esi, sizeof seven.body1
    pop ecx
    loop pseven
    ret
peight:
    push ecx
    invoke WriteConsoleOutputCharacter, outputHandle, esi, sizeof eight.body1, temp_coord, addr check
    inc temp_coord.Y
    add esi, sizeof eight.body1
    pop ecx
    loop peight
    ret
PrintNum endp

END main
