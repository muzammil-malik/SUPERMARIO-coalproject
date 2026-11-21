org 100h

jmp start

; Display and level
SCREEN_WIDTH       equ 320
SCREEN_HEIGHT      equ 200
TILE_SIZE          equ 16
MAP_COLUMNS        equ 60
MAP_ROWS           equ 12
TEXT_MODE          equ 03h
GRAPHICS_MODE      equ 13h

; Colour indices
COLOR_TRANSPARENT  equ 0
COLOR_BLACK        equ 0
COLOR_WHITE        equ 15

; Keyboard scan codes
KEY_ESC            equ 01h
KEY_ENTER          equ 1Ch
KEY_PAUSE          equ 19h
KEY_SHIFT          equ 2Ah
KEY_SPACE          equ 39h
KEY_UP             equ 48h
KEY_LEFT           equ 4Bh
KEY_RIGHT          equ 4Dh
KEY_DOWN           equ 50h
KEY_COUNT          equ 128

; Game limits
START_LIVES        equ 3
MAX_LIVES          equ 99
START_TIME         equ 300
START_HP           equ 1
MAX_HP             equ 2
MAX_SCORE          equ 999999
MAX_ENEMIES        equ 8
COINS_FOR_LIFE     equ 100

; Hero data
player_x           dw 32
player_hp          db START_HP
player_lives       db START_LIVES

; Enemy data
active_enemy_count db 0

; Score and coins
score_low          dw 0
score_high         dw 0
coin_count         db 0

; Clock data
time_left          dw START_TIME

; Keyboard data
key_states         times KEY_COUNT db 0

; Program entry
; Purpose: Set up DS, select text mode, and return to DOS.
; Inputs: DOS .COM startup environment.
; Outputs: DOS exit code 0.
; Registers changed before termination: AX and DS, plus BIOS/DOS effects.
start:
    push cs
    pop ds

    mov ax, TEXT_MODE
    int 10h

    mov ax, 4C00h
    int 21h