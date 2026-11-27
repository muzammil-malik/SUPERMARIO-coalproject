bits 16
cpu 8086
org 100h

; Display and level dimensions (Appendix A.1).
SCREEN_WIDTH    equ 320
SCREEN_HEIGHT   equ 200
TILE_SIZE       equ 16
SUPER_HEIGHT    equ 32
LEVEL_COLUMNS   equ 60
LEVEL_ROWS      equ 12
WORLD_WIDTH     equ LEVEL_COLUMNS * TILE_SIZE
VGA_SEGMENT     equ 0A000h
TEXT_MODE       equ 0003h
GRAPHICS_MODE   equ 0013h

; Palette indices (0 is also the sprite transparency key).
COLOR_TRANSPARENT equ 0
COLOR_SKY         equ 9
COLOR_GROUND      equ 6
COLOR_BRICK       equ 12
COLOR_PIPE        equ 2
COLOR_HERO        equ 11
COLOR_ENEMY       equ 4
COLOR_TEXT        equ 15
COLOR_HUD         equ 1

; Keyboard make codes (Appendix A.3).
KEY_LEFT        equ 4Bh
KEY_RIGHT       equ 4Dh
KEY_UP          equ 48h
KEY_DOWN        equ 50h
KEY_SPACE       equ 39h
KEY_LEFT_SHIFT  equ 2Ah
KEY_P           equ 19h
KEY_ENTER       equ 1Ch
KEY_ESC         equ 01h
KEY_COUNT       equ 128
KEY_A           equ 1Eh
KEY_D           equ 20h
KEY_COMMA       equ 33h
KEY_PERIOD      equ 34h

; Game limits (Appendix A.4).
START_LIVES     equ 3
MAX_LIVES       equ 99
SMALL_HP        equ 1
SUPER_HP        equ 2
START_TIME      equ 300
MAX_SCORE       equ 999999
COINS_PER_LIFE  equ 100
MAX_ENEMIES     equ 8
CAMERA_FOLLOW_X equ 160
MAX_CAMERA_X    equ WORLD_WIDTH - SCREEN_WIDTH
INVULN_SECONDS  equ 2
FLAT_SECONDS    equ 1
KICK_GRACE      equ 8
DEATH_TIME_MS   equ 1500
LIFE_LOST_SECONDS equ 2

; DOS begins executing at offset 0100h. Jump over the data.
    jmp Start

; Hero.
hero_world_x   dw 32
hero_hp         db SMALL_HP

; Enemies.
active_enemies  db 0

; Score, coins and lives.
score_low       dw 0
score_high      dw 0
coin_count      db 0
lives           db START_LIVES

; Clock.
time_left       dw START_TIME

; Keyboard.
key_state       times KEY_COUNT db 0
key_pressed     times KEY_COUNT db 0
old_keyboard_offset dw 0
old_keyboard_segment dw 0

; Scan code, ASCII character for one-shot preview commands.
preview_commands:
    db KEY_P, 'p', 1Fh, 's', 26h, 'l', 2Fh, 'v'
    db 13h, 'r', 14h, 't', 31h, 'n', 32h, 'm', 30h, 'b'
    db KEY_ENTER, 13
PREVIEW_COMMAND_COUNT equ ($ - preview_commands) / 2

; Preview swatches, in display order from left to right.
preview_colors  db COLOR_SKY, COLOR_GROUND, COLOR_BRICK, COLOR_PIPE
                db COLOR_HERO, COLOR_ENEMY, COLOR_TEXT, COLOR_HUD
                db COLOR_TRANSPARENT
PREVIEW_COUNT   equ $ - preview_colors

; Appendix A.2 tile codes. Table order matches the codes.
TILE_SKY       equ 0
TILE_GROUND    equ 1
TILE_BRICK     equ 2
TILE_COIN_BOX  equ 3
TILE_POWER_BOX equ 4
TILE_EMPTY_BOX equ 5
TILE_PIPE_TL   equ 6
TILE_PIPE_TR   equ 7
TILE_PIPE_BL   equ 8
TILE_PIPE_BR   equ 9
TILE_STAIR     equ 10
TILE_COIN      equ 11
TILE_FLAG      equ 12
TILE_HUD       equ 13
MAP_BYTES      equ LEVEL_COLUMNS * LEVEL_ROWS
VISIBLE_COLS   equ SCREEN_WIDTH / TILE_SIZE
LAST_WINDOW    equ LEVEL_COLUMNS - VISIBLE_COLS
ENEMY_GOOMBA   equ 1
ENEMY_KOOPA    equ 2

tile_colors db COLOR_SKY, COLOR_GROUND, COLOR_BRICK
            db 14, 13, 8, COLOR_PIPE, COLOR_PIPE, COLOR_PIPE, COLOR_PIPE
            db 6, 14, 15, COLOR_HUD
preview_column dw 0

; Whole-pixel camera state. Module 9 can supply the integer part of x.
HERO_START_X    equ 32
HERO_MAX_X      equ WORLD_WIDTH - TILE_SIZE
camera_x        dw 0
hero_preview_dx dw 0
hero_preview_y  dw 24
hero_preview_flags dw 0
camera_paused   db 0
FRAME_WORDS    equ SCREEN_WIDTH * SCREEN_HEIGHT / 2
FRAME_PARAS    equ SCREEN_WIDTH * SCREEN_HEIGHT / 16
PAGE_MAP       equ 0
PAGE_SPRITES   equ 1
PAGE_PALETTE   equ 2
PAGE_BUFFER_DEMO equ 3
frame_segment  dw 0
last_tick      dw 0
preview_phase  dw 0
preview_page   db PAGE_MAP
demo_x         dw 0
allocation_error db 'Unable to reserve the 64000-byte frame buffer.',13,10,'$'

; Initial enemy placements: type, world x and top y (words).
enemy_starts:
    dw ENEMY_GOOMBA, 96, 144
    dw ENEMY_GOOMBA, 272, 144
    dw ENEMY_GOOMBA, 528, 144
    dw ENEMY_GOOMBA, 800, 144
    dw ENEMY_KOOPA, 400, 144
    dw ENEMY_KOOPA, 768, 144
ENEMY_START_COUNT equ ($ - enemy_starts) / 6

; Original level. Rows and columns are numbered from zero.
original_map:
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  ; row 0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  ; row 1
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12  ; row 2
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12  ; row 3
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12  ; row 4
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12  ; row 5
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10,0,12  ; row 6
    db 0,0,0,0,0,4,0,2,2,2,0,3,11,11,11,11,0,0,0,0,0,0,0,4,0,3,0,0,2,2,2,0,0,0,11,11,11,11,11,0,0,0,0,3,0,0,6,7,0,0,0,0,0,0,0,0,10,10,0,12  ; row 7
    db 0,0,0,0,11,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,7,0,11,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,9,0,11,0,0,0,0,0,10,10,10,0,12  ; row 8
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,9,0,0,0,0,0,0,10,10,10,10,0,10  ; row 9
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1  ; row 10
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1  ; row 11
working_map times MAP_BYTES db 0

SPRITE_MIRROR equ 1
SPRITE_HIDE   equ 2
sprite_index  dw 0
sprite_x      dw 144
sprite_y      dw 132
sprite_flags  dw 0
sprite_blink  db 0

sprite_addresses:
    dw SpriteSmallStand
    dw SpriteSmallRun
    dw SpriteSmallJump
    dw SpriteSuperStand
    dw SpriteSuperRun
    dw SpriteSuperJump
    dw SpriteGoombaWalk
    dw SpriteGoombaFlat
    dw SpriteKoopa
    dw SpriteShell
    dw SpriteMushroom
    dw SpriteCoin
SPRITE_COUNT equ ($ - sprite_addresses) / 2

; Each sprite starts with its height, then 16 index bytes per row.
SpriteSmallStand:
    db 16
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,0,0,7,7,7,7,7,1,7,0,0,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,7,7,3,11,11,15,3,3,7,7,0,0,0
    db 0,0,0,7,7,3,11,11,15,3,3,7,7,0,0,0
    db 0,0,0,7,7,1,1,1,0,1,1,1,7,0,0,0
    db 0,0,0,0,0,1,1,1,0,1,1,1,0,0,0,0
    db 0,0,0,0,0,1,1,1,0,1,1,1,0,0,0,0
    db 0,0,0,0,0,8,8,8,8,8,8,8,8,8,0,0
    db 0,0,0,0,0,8,8,8,8,8,8,8,8,8,0,0
SpriteSmallRun:
    db 16
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,0,0,7,7,7,7,7,1,7,0,0,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,7,7,7,0
    db 0,0,0,0,0,3,11,11,15,3,3,3,7,7,7,0
    db 0,0,7,7,7,3,11,11,15,3,3,3,0,0,0,0
    db 0,0,7,1,1,1,1,0,0,0,1,1,1,0,0,0
    db 0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0
    db 0,8,8,8,8,8,1,0,0,0,1,1,1,0,0,0
    db 0,8,8,8,8,8,0,0,0,0,1,8,8,8,8,8
    db 0,0,0,0,0,0,0,0,0,0,0,8,8,8,8,8
SpriteSmallJump:
    db 16
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,0,0,7,7,7,7,7,1,7,7,7,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,0,7,7,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,0,7,7,3,11,11,3,3,3,3,7,7,0,0
    db 0,0,0,7,7,3,11,11,15,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,15,3,3,3,0,0,0,0
    db 0,0,0,1,1,1,1,0,0,1,1,8,8,8,8,0
    db 0,0,8,8,8,8,1,0,0,1,1,8,8,8,8,0
    db 0,0,8,8,8,8,1,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
SpriteSuperStand:
    db 32
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,0,0,7,7,7,7,7,1,7,0,0,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,7,7,3,11,11,15,3,3,7,7,0,0,0
    db 0,0,0,7,7,3,11,11,15,3,3,7,7,0,0,0
    db 0,0,0,7,7,3,11,11,3,3,3,7,7,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,1,1,1,0,1,1,1,0,0,0,0
    db 0,0,0,0,0,1,1,1,0,1,1,1,0,0,0,0
    db 0,0,0,0,0,1,1,1,0,1,1,1,0,0,0,0
    db 0,0,0,0,0,8,8,8,8,8,8,8,8,8,0,0
    db 0,0,0,0,0,8,8,8,8,8,8,8,8,8,0,0
SpriteSuperRun:
    db 32
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,0,0,7,7,7,7,7,1,7,0,0,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,7,7,7,0
    db 0,0,0,0,0,3,11,11,15,3,3,3,7,7,7,0
    db 0,0,7,7,7,3,11,11,15,3,3,3,0,0,0,0
    db 0,0,7,7,7,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0
    db 0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0
    db 0,8,8,8,8,8,1,0,0,0,1,1,1,0,0,0
    db 0,8,8,8,8,8,0,0,0,0,1,8,8,8,8,8
    db 0,0,0,0,0,0,0,0,0,0,0,8,8,8,8,8
SpriteSuperJump:
    db 32
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,0,11,11,11,11,11,11,11,11,0,0,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,11,11,11,11,11,11,11,11,11,11,11,0,0
    db 0,0,0,0,0,7,7,7,7,7,1,7,7,7,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,0,7,7,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,0,7,7,3,11,11,3,3,3,3,7,7,0,0
    db 0,0,0,7,7,3,11,11,15,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,15,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,0,0,3,11,11,3,3,3,3,0,0,0,0
    db 0,0,0,1,1,1,1,0,0,1,1,8,8,8,8,0
    db 0,0,8,8,8,8,1,0,0,1,1,8,8,8,8,0
    db 0,0,8,8,8,8,1,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
SpriteGoombaWalk:
    db 16
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,5,5,5,5,5,5,5,5,0,0,0,0
    db 0,0,0,0,5,5,5,5,5,5,5,5,0,0,0,0
    db 0,0,5,5,5,5,5,5,5,5,5,5,5,5,0,0
    db 0,0,5,5,5,15,15,5,5,5,15,15,5,5,0,0
    db 0,0,5,5,5,15,0,5,5,5,15,0,5,5,0,0
    db 0,0,5,5,5,5,5,5,5,5,5,5,5,5,0,0
    db 0,0,5,5,5,5,5,5,5,5,5,5,5,5,0,0
    db 0,0,0,13,13,13,13,13,13,13,13,13,13,0,0,0
    db 0,0,0,13,13,13,13,13,13,13,13,13,13,0,0,0
    db 0,0,8,8,8,8,8,0,0,8,8,8,8,8,0,0
    db 0,0,8,8,8,8,8,0,0,8,8,8,8,8,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
SpriteGoombaFlat:
    db 16
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,5,5,5,15,15,5,5,5,15,15,5,5,0,0
    db 0,0,5,5,5,5,5,5,5,5,5,5,5,5,0,0
    db 0,13,13,13,13,13,13,13,13,13,13,13,13,13,13,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
SpriteKoopa:
    db 16
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,7,7,7,7,0,0
    db 0,0,0,0,0,0,0,0,0,0,7,7,1,7,0,0
    db 0,0,0,2,2,2,2,2,2,0,7,7,7,7,0,0
    db 0,0,10,2,2,2,2,2,2,10,7,7,7,7,0,0
    db 0,0,10,2,2,10,10,10,2,10,7,7,7,7,0,0
    db 0,0,10,2,2,10,10,10,2,10,7,7,7,7,0,0
    db 0,0,10,2,2,10,10,10,2,10,7,7,7,7,0,0
    db 0,0,10,2,2,2,2,2,2,7,7,7,7,0,0,0
    db 0,0,10,2,2,2,2,2,2,7,7,7,7,0,0,0
    db 0,0,0,2,2,2,2,2,2,7,7,7,7,0,0,0
    db 0,0,0,0,6,6,6,6,0,0,6,6,6,6,6,0
    db 0,0,0,0,6,6,6,6,0,0,6,6,6,6,6,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
SpriteShell:
    db 16
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,10,10,10,10,10,10,0,0,0,0,0
    db 0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0
    db 0,0,0,2,2,10,10,10,2,2,2,2,2,0,0,0
    db 0,0,0,2,2,10,10,10,2,2,2,2,2,0,0,0
    db 0,0,0,2,2,10,10,10,2,2,2,2,2,0,0,0
    db 0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0
    db 0,0,7,7,7,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,7,7,7,7,7,7,7,7,7,7,7,7,0,0
    db 0,0,0,0,8,8,8,8,8,8,8,8,8,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
SpriteMushroom:
    db 16
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,5,5,5,5,5,5,5,5,0,0,0,0
    db 0,0,0,0,5,5,5,5,5,11,11,11,0,0,0,0
    db 0,0,13,13,13,13,13,13,13,11,11,11,13,13,0,0
    db 0,0,13,11,11,11,13,13,13,13,13,13,13,13,0,0
    db 0,0,13,11,11,11,13,13,13,13,13,13,13,13,0,0
    db 0,0,13,13,13,13,13,13,13,13,13,13,13,13,0,0
    db 0,0,13,13,13,13,13,13,13,13,13,13,13,13,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,0,0,0,0,0
    db 0,0,0,0,0,7,1,7,7,1,7,0,0,0,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,0,0,0,0,0
    db 0,0,0,0,0,7,7,7,7,7,7,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
SpriteCoin:
    db 16
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,6,6,6,6,0,0,0,0,0,0
    db 0,0,0,0,0,14,14,14,14,14,14,0,0,0,0,0
    db 0,0,0,0,0,14,15,14,14,14,14,0,0,0,0,0
    db 0,0,0,0,0,14,15,14,14,14,14,0,0,0,0,0
    db 0,0,0,0,0,14,15,14,14,14,14,0,0,0,0,0
    db 0,0,0,0,0,14,15,14,14,14,14,0,0,0,0,0
    db 0,0,0,0,0,14,15,14,14,14,14,0,0,0,0,0
    db 0,0,0,0,0,14,15,14,14,14,14,0,0,0,0,0
    db 0,0,0,0,0,14,14,14,14,14,14,0,0,0,0,0
    db 0,0,0,0,0,0,6,6,6,6,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; Start
; Inputs: DOS .COM entry state (SS already equals the program segment).
; Outputs: buffered interactive preview. Changes: AX, BX, DS, ES, SP.
Start:
    ; Move the stack into our retained block before shrinking it.
    mov  sp, StackTop
    push cs
    pop  ds
    push cs
    pop  es
    mov  bx, (ProgramEnd - $$ + 100h + 15) / 16
    mov  ah, 4Ah
    int  21h
    jc   FrameAllocationFailed

    mov  bx, FRAME_PARAS
    mov  ah, 48h
    int  21h
    jc   FrameAllocationFailed
    mov  [frame_segment], ax

    mov  ax, GRAPHICS_MODE
    int  10h
    push cs
    pop  ds

    call ResetMap
    call ResetCamera
    call InstallKeyboard
    push word [frame_segment]
    call RunBufferedPreview
    jmp  ExitToDOS

; FrameAllocationFailed
; Inputs: DOS allocation failure. Outputs: error message and DOS status 1.
; Registers changed: AX, DX. Terminates the process.
FrameAllocationFailed:
    push cs
    pop  ds
    mov  dx, allocation_error
    mov  ah, 09h
    int  21h
    mov  ax, 4C01h
    int  21h

; ExitToDOS
; Purpose: restore 80x25 color text mode and terminate normally.
; Inputs: none. Output: DOS exit status 0.
; Registers changed: AX and any BIOS clobbers. This routine never returns.
ExitToDOS:
    call RestoreKeyboard
    mov  ax, TEXT_MODE
    int  10h

    mov  ax, 4C00h
    int  21h

; PixelOffset(x, y)
; Purpose: convert checked screen coordinates to a Mode 13h byte offset.
; Inputs: x at [bp+4], y at [bp+6]. Returns: AX. Changes: AX, flags.
PixelOffset:
    push bp
    mov  bp, sp
    push bx
    push cx

    mov  ax, [bp+6]
    mov  bx, ax
    mov  cl, 8
    shl  ax, cl           ; y * 256
    mov  cl, 6
    shl  bx, cl           ; y * 64
    add  ax, bx
    add  ax, [bp+4]       ; plus x

    pop  cx
    pop  bx
    pop  bp
    ret  4

; PutPixel(x, y, color)
; Inputs: x, y, color at [bp+4], [bp+6], [bp+8]; ES is drawing segment.
; Outputs: one pixel if inside the screen. Changes: flags only.
PutPixel:
    push bp
    mov  bp, sp
    push ax
    push di

    cmp  word [bp+4], SCREEN_WIDTH
    jae  .done
    cmp  word [bp+6], SCREEN_HEIGHT
    jae  .done

    push word [bp+6]
    push word [bp+4]
    call PixelOffset
    mov  di, ax
    mov  al, [bp+8]
    mov  [es:di], al

.done:
    pop  di
    pop  ax
    pop  bp
    ret  6

; FillRect(x, y, width, height, color)
; Inputs: five words from [bp+4] to [bp+12]; ES is drawing segment.
; Outputs: rectangle drawn if it fits the screen. Changes: none.
FillRect:
    push bp
    mov  bp, sp
    pushf
    push ax
    push bx
    push cx
    push dx
    push di
    cld

    ; Unsigned checks also reject negative origins and dimensions.
    mov  bx, [bp+4]
    cmp  bx, SCREEN_WIDTH
    jae  .done
    mov  dx, [bp+6]
    cmp  dx, SCREEN_HEIGHT
    jae  .done

    mov  ax, SCREEN_WIDTH
    sub  ax, bx
    mov  cx, [bp+8]
    jcxz .done
    cmp  cx, ax
    ja   .done

    mov  ax, SCREEN_HEIGHT
    sub  ax, dx
    cmp  word [bp+10], 0
    je   .done
    cmp  [bp+10], ax
    ja   .done

    push dx
    push bx
    call PixelOffset
    mov  di, ax
    mov  al, [bp+12]
    mov  dx, [bp+10]
    mov  bx, SCREEN_WIDTH
    sub  bx, [bp+8]       ; advance from end of this row to next row

.row:
    mov  cx, [bp+8]
    rep  stosb
    add  di, bx
    dec  dx
    jnz  .row

.done:
    pop  di
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    popf
    pop  bp
    ret  10

; ShowColorTest
; Inputs: DS = project data, ES = VGA segment.
; Outputs: palette swatches and four corner pixels. Changes: flags only.
ShowColorTest:
    push ax
    push bx
    push cx
    push dx
    push si

    ; Gray board makes both the white and black swatches visible.
    mov  ax, 8
    push ax
    mov  ax, 56
    push ax
    mov  ax, 304
    push ax
    mov  ax, 72
    push ax
    mov  ax, 8
    push ax
    call FillRect

    mov  si, preview_colors
    mov  bx, 16
    mov  cx, PREVIEW_COUNT
.swatch:
    xor  ax, ax
    mov  al, [si]
    push ax
    mov  ax, 32
    push ax
    mov  ax, 24
    push ax
    mov  ax, 84
    push ax
    push bx
    call FillRect
    inc  si
    add  bx, 32
    loop .swatch

    ; Test both legal endpoint coordinates on each axis.
    mov  ax, COLOR_TEXT
    xor  bx, bx
    xor  dx, dx
    push ax
    push dx
    push bx
    call PutPixel

    mov  bx, SCREEN_WIDTH - 1
    push ax
    push dx
    push bx
    call PutPixel

    mov  dx, SCREEN_HEIGHT - 1
    push ax
    push dx
    push bx
    call PutPixel

    xor  bx, bx
    push ax
    push dx
    push bx
    call PutPixel

    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; ResetMap
; Inputs: DS = project segment. Copies original map into working map.
; Outputs: working map reset. Changes: none, including flags.
ResetMap:
    pushf
    push es
    push si
    push di
    push cx
    push ds
    pop  es
    mov  si, original_map
    mov  di, working_map
    mov  cx, MAP_BYTES
    cld
    rep  movsb
    pop  cx
    pop  di
    pop  si
    pop  es
    popf
    ret

; GetTile(px, py)
; Inputs: world x at [bp+4], world y at [bp+6].
; Outputs: AX = tile code, or sky outside the map. Changes: AX, flags.
GetTile:
    push bp
    mov  bp, sp
    push bx
    push cx
    push dx
    xor  ax, ax
    mov  bx, [bp+4]
    cmp  bx, WORLD_WIDTH
    jae  .done
    mov  dx, [bp+6]
    cmp  dx, LEVEL_ROWS * TILE_SIZE
    jae  .done
    mov  cl, 4
    shr  bx, cl
    shr  dx, cl
    mov  ax, LEVEL_COLUMNS
    mul  dx
    add  bx, ax
    xor  ax, ax
    mov  al, [working_map+bx]
.done:
    pop  dx
    pop  cx
    pop  bx
    pop  bp
    ret  4

; DrawTile(x, y, tile)
; Inputs: screen x, screen y, tile code at [bp+4..8]; ES = target.
; Outputs: one tile, with special details for boxes, coins and flag.
; Changes: flags only.
DrawTile:
    push bp
    mov  bp, sp
    push ax
    push bx
    push dx
    mov  bx, [bp+8]
    cmp  bx, TILE_HUD
    jbe  .valid_tile
    jmp  near .done
.valid_tile:
    mov  dx, TILE_SIZE
    xor  ax, ax
    mov  al, [tile_colors+bx]
    cmp  bx, TILE_COIN
    je   .sky
    cmp  bx, TILE_FLAG
    jne  .background
.sky:
    mov  ax, COLOR_SKY
.background:
    push ax
    push dx
    push dx
    push word [bp+6]
    push word [bp+4]
    call FillTileRect

    cmp  bx, TILE_COIN
    je   .detail
    cmp  bx, TILE_FLAG
    je   .pole
    cmp  bx, TILE_COIN_BOX
    je   .detail
    cmp  bx, TILE_POWER_BOX
    jne  .done
.detail:
    ; A small contrasting mark identifies an interactive tile.
    xor  ax, ax
    mov  al, [tile_colors+bx]
    cmp  bx, TILE_COIN_BOX
    jb   .draw_detail
    cmp  bx, TILE_POWER_BOX
    ja   .draw_detail
    mov  ax, COLOR_TEXT
.draw_detail:
    push ax
    mov  ax, 12
    push ax
    mov  ax, 4
    push ax
    mov  ax, [bp+6]
    add  ax, 2
    push ax
    mov  ax, [bp+4]
    add  ax, 6
    push ax
    call FillTileRect
    jmp  .done
.pole:
    mov  ax, COLOR_TEXT
    push ax
    push dx
    mov  ax, 2
    push ax
    push word [bp+6]
    mov  ax, [bp+4]
    add  ax, 7
    push ax
    call FillTileRect
.done:
    pop  dx
    pop  bx
    pop  ax
    pop  bp
    ret  6

; FillTileRect(x, y, width, height, color)
; Inputs: five stack words and ES target. Clips horizontal tile edges.
; Outputs: visible part drawn via FillRect. Changes: flags only.
FillTileRect:
    push bp
    mov  bp, sp
    push ax
    push bx
    push cx
    mov  bx, [bp+4]
    mov  cx, [bp+8]
    or   bx, bx
    jns  .right
    add  cx, bx                 ; discard columns left of the viewport
    jle  .done
    xor  bx, bx
.right:
    cmp  bx, SCREEN_WIDTH
    jae  .done
    mov  ax, SCREEN_WIDTH
    sub  ax, bx
    cmp  cx, ax
    jbe  .draw
    mov  cx, ax
.draw:
    push word [bp+12]
    push word [bp+10]
    push cx
    push word [bp+6]
    push bx
    call FillRect
.done:
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret  10

; DrawMap(camera_pixels)
; Inputs: camera position in pixels at [bp+4], ES = target.
; Outputs: tile window, fixed HUD band and black bottom strip.
; Changes: flags only.
DrawMap:
    push bp
    mov  bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov  si, [bp+4]
    cmp  si, MAX_CAMERA_X
    jbe  .valid_view
    jmp  near .done
.valid_view:
    mov  di, si
    and  di, TILE_SIZE - 1
    neg  di                     ; screen x of first tile, possibly negative
    mov  cl, 4
    shr  si, cl                  ; world column of first tile

    xor  ax, ax
    mov  al, [tile_colors+TILE_HUD]
    push ax
    mov  ax, TILE_SIZE
    push ax
    mov  ax, SCREEN_WIDTH
    push ax
    xor  ax, ax
    push ax
    push ax
    call FillRect

    add  si, LEVEL_COLUMNS       ; row 0 is the fixed HUD
    mov  dx, TILE_SIZE
.row:
    push si                      ; remember the first tile of this row
    mov  bx, di
.column:
    xor  ax, ax
    mov  al, [working_map+si]
    push ax
    push dx
    push bx
    call DrawTile
    inc  si
    add  bx, TILE_SIZE
    cmp  bx, SCREEN_WIDTH
    jl   .column
    pop  si
    add  si, LEVEL_COLUMNS
    add  dx, TILE_SIZE
    cmp  dx, LEVEL_ROWS * TILE_SIZE
    jb   .row

    xor  ax, ax
    push ax
    mov  ax, SCREEN_HEIGHT - LEVEL_ROWS * TILE_SIZE
    push ax
    mov  ax, SCREEN_WIDTH
    push ax
    push dx
    xor  ax, ax
    push ax
    call FillRect
.done:
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret  2

; DrawSprite(x, y, address, flags)
; Inputs: four stack words. DS:address = height byte followed by pixels.
; ES = target. Flag 1 mirrors horizontally. Flag 2 hides this frame.
; Outputs: sprite drawn with transparent zero pixels and screen clipping.
; Changes: flags only.
DrawSprite:
    push bp
    mov  bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    test word [bp+10], SPRITE_HIDE
    jnz  .done
    mov  si, [bp+8]
    xor  ax, ax
    mov  al, [si]
    inc  si
    mov  cx, ax
    mov  dx, [bp+6]
.row:
    xor  di, di
.pixel:
    mov  bx, di
    test word [bp+10], SPRITE_MIRROR
    jz   .sample
    mov  bx, TILE_SIZE - 1
    sub  bx, di
.sample:
    xor  ax, ax
    mov  al, [bx+si]
    or   al, al
    jz   .next
    push ax
    push dx
    mov  ax, [bp+4]
    add  ax, di
    push ax
    call PutPixel
.next:
    inc  di
    cmp  di, TILE_SIZE
    jb   .pixel
    add  si, TILE_SIZE
    inc  dx
    loop .row
.done:
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret  8

; DrawPreviewEnemies(camera_pixels)
; Inputs: camera position in pixels at [bp+4], DS project data, ES target.
; Outputs: draws static enemy starts. Changes: flags only.
DrawPreviewEnemies:
    push bp
    mov  bp, sp
    push ax
    push bx
    push cx
    push dx
    push si

    mov  bx, [bp+4]
    mov  si, enemy_starts
    mov  cx, ENEMY_START_COUNT
.enemy:
    mov  dx, [si+2]
    sub  dx, bx
    cmp  dx, -TILE_SIZE
    jle  .next
    cmp  dx, SCREEN_WIDTH
    jge  .next
    xor  ax, ax
    push ax
    mov  ax, SpriteGoombaWalk
    cmp  word [si], ENEMY_GOOMBA
    je   .draw
    mov  ax, SpriteKoopa
.draw:
    push ax
    push word [si+4]
    push dx
    call DrawSprite
.next:
    add  si, 6
    loop .enemy

    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret  2

; DrawSpriteGallery(phase)
; Inputs: phase word at [bp+4], DS project segment, ES target.
; Outputs: all poses and selected sprite. Changes: flags only.
DrawSpriteGallery:
    push bp
    mov  bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    mov  ax, COLOR_SKY
    push ax
    mov  ax, SCREEN_HEIGHT
    push ax
    mov  ax, SCREEN_WIDTH
    push ax
    xor  ax, ax
    push ax
    push ax
    call FillRect

    mov  bx, 12
    mov  dx, 40
    mov  cx, SPRITE_COUNT
    mov  si, sprite_addresses
.pose:
    xor  ax, ax
    push ax
    push word [si]
    push dx
    push bx
    call DrawSprite
    add  si, 2
    add  bx, 25
    loop .pose

    mov  bx, [sprite_index]
    shl  bx, 1
    mov  ax, [sprite_flags]
    cmp  byte [sprite_blink], 0
    je   .selected
    test word [bp+4], 1
    jz   .selected
    or   ax, SPRITE_HIDE
.selected:
    push ax
    push word [sprite_addresses+bx]
    push word [sprite_y]
    push word [sprite_x]
    call DrawSprite

    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret  2


; UpdateSpritePreview(key)
; Input: BIOS key word at [bp+4]. Output: updated gallery test controls.
; Changes: flags only.
UpdateSpritePreview:
    push bp
    mov  bp, sp
    push ax
    mov  ax, [bp+4]
    cmp  ah, KEY_LEFT
    je   .left
    cmp  ah, KEY_RIGHT
    je   .right
    cmp  ah, KEY_UP
    je   .up
    cmp  ah, KEY_DOWN
    jne  .letter
    jmp  near .down
.letter:
    or   al, 20h
    cmp  al, 'm'
    jne  .check_blink
    xor  word [sprite_flags], SPRITE_MIRROR
    jmp  near .done
.check_blink:
    cmp  al, 'b'
    jne  .check_next
    xor  byte [sprite_blink], 1
    jmp  near .done
.check_next:
    cmp  al, 'n'
    je   .next_sprite
    jmp  near .done
.next_sprite:
    inc  word [sprite_index]
    cmp  word [sprite_index], SPRITE_COUNT
    jb   .keep_index
    mov  word [sprite_index], 0
.keep_index:
    jmp  near .done
.left:
    sub  word [sprite_x], 4
    cmp  word [sprite_x], -16
    jge  .done
    mov  word [sprite_x], SCREEN_WIDTH
    jmp  .done
.right:
    add  word [sprite_x], 4
    cmp  word [sprite_x], SCREEN_WIDTH
    jle  .done
    mov  word [sprite_x], -16
    jmp  .done
.up:
    sub  word [sprite_y], 4
    cmp  word [sprite_y], -32
    jge  .done
    mov  word [sprite_y], SCREEN_HEIGHT
    jmp  .done
.down:
    add  word [sprite_y], 4
    cmp  word [sprite_y], SCREEN_HEIGHT
    jle  .done
    mov  word [sprite_y], -32
    jmp  .done
.done:
    pop  ax
    pop  bp
    ret  2

; ClearFrame(color)
; Inputs: word color at [bp+4], ES = frame buffer.
; Output: 64000 cleared bytes. Changes: none.
ClearFrame:
    push bp
    mov  bp, sp
    pushf
    push ax
    push cx
    push di
    mov  al, [bp+4]
    mov  ah, al
    xor  di, di
    mov  cx, FRAME_WORDS
    cld
    rep  stosw
    pop  di
    pop  cx
    pop  ax
    popf
    pop  bp
    ret  2

; PresentFrame(segment)
; Inputs: buffer segment at [bp+4]. Output: buffer copied to VGA.
; Changes: none. Preserves both segment registers and DF.
PresentFrame:
    push bp
    mov  bp, sp
    pushf
    push ax
    push cx
    push si
    push di
    push ds
    push es

    mov  ds, [bp+4]
    mov  ax, VGA_SEGMENT
    mov  es, ax
    xor  si, si
    xor  di, di
    mov  cx, FRAME_WORDS
    cld
    rep  movsw

    pop  es
    pop  ds
    pop  di
    pop  si
    pop  cx
    pop  ax
    popf
    pop  bp
    ret  2

; ReadBIOSClock
; Inputs: none. Returns: AX = low word of the BIOS tick count.
; Changes: AX. Reading the BIOS data area leaves the DOS clock alone.
ReadBIOSClock:
    push es
    mov  ax, 0040h
    mov  es, ax
    mov  ax, [es:006Ch]
    pop  es
    ret

; WaitForPreviewTick(previous_tick)
; Inputs: the last observed BIOS low tick word at [bp+4].
; Returns: AX = a new low tick word. Changes: AX and flags.
WaitForPreviewTick:
    push bp
    mov  bp, sp
.wait:
    call ReadBIOSClock
    cmp  ax, [bp+4]
    je   .wait
    pop  bp
    ret  2

; RunBufferedPreview(segment)
; Inputs: buffer segment at [bp+4]. Outputs: a preview frame on each
; observed BIOS tick. Esc returns so DOS can release the allocated block.
; Changes: flags only. Preview state persists in the project data.
RunBufferedPreview:
    push bp
    mov  bp, sp
    push ax
    push cx
    push es
    mov  es, [bp+4]
.frame:
    push word [last_tick]
    call WaitForPreviewTick
    mov  [last_tick], ax
    xor  word [preview_phase], 1
    mov  word [hero_preview_dx], 0

    xor  al, al
    xchg al, [key_pressed+KEY_ESC]
    or   al, al
    jz   .input
    jmp  near .done
.input:
    call PollPreviewKeys
    xor  ax, ax
    push ax
    call ClearFrame
    cmp  byte [preview_page], PAGE_PALETTE
    jne  .try_sprites
    call ShowColorTest
    jmp  .present
.try_sprites:
    cmp  byte [preview_page], PAGE_SPRITES
    jne  .choose_map
    push word [preview_phase]
    call DrawSpriteGallery
    jmp  .present
.choose_map:
    cmp  byte [preview_page], PAGE_BUFFER_DEMO
    je   .buffer_demo
    cmp  byte [camera_paused], 0
    jne  .draw_world
    mov  ax, [hero_world_x]
    add  ax, [hero_preview_dx]
    push ax
    call UpdateCamera
.draw_world:
    push word [camera_x]
    call DrawMap
    push word [camera_x]
    call DrawPreviewEnemies
    call DrawCameraHero
    call DrawKeyboardIndicators
    jmp  .present
.buffer_demo:
    mov  ax, [preview_column]
    mov  cl, 4
    shl  ax, cl
    push ax
    call DrawMap
    push ax
    call DrawPreviewEnemies

    ; Animate an original pose across the sky above the obstacles.
    xor  ax, ax
    push ax
    mov  ax, SpriteSmallRun
    push ax
    mov  ax, 24
    push ax
    push word [demo_x]
    call DrawSprite
    add  word [demo_x], 2
    cmp  word [demo_x], SCREEN_WIDTH
    jl   .present
    mov  word [demo_x], -TILE_SIZE
.present:
    push word [bp+4]
    call PresentFrame
    jmp  .frame
.done:
    pop  es
    pop  cx
    pop  ax
    pop  bp
    ret  2

; DrawCameraHero
; Inputs: ES target, current hero and camera state.
; Outputs: hero drawn at world x minus camera x. Changes: flags only.
DrawCameraHero:
    push ax
    push bx
    mov  ax, [hero_world_x]
    sub  ax, [camera_x]
    mov  bx, SpriteSmallStand
    cmp  word [hero_preview_dx], 0
    je   .draw
    mov  bx, SpriteSmallRun
.draw:
    push word [hero_preview_flags]
    push bx
    push word [hero_preview_y]
    push ax
    call DrawSprite
    pop  bx
    pop  ax
    ret

; HandlePreviewKey(key)
; Input: BIOS key word at [bp+4]. Outputs: selected preview and its state.
; Changes: flags only.
HandlePreviewKey:
    push bp
    mov  bp, sp
    push ax
    mov  ax, [bp+4]
    or   al, 20h
    cmp  al, 'p'
    jne  .check_sprites
    mov  byte [preview_page], PAGE_PALETTE
    jmp  near .done
.check_sprites:
    cmp  al, 's'
    jne  .check_world
    mov  byte [preview_page], PAGE_SPRITES
    jmp  .done
.check_world:
    cmp  al, 'l'
    jne  .check_demo
    mov  byte [preview_page], PAGE_MAP
    jmp  .done
.check_demo:
    cmp  al, 'v'
    jne  .dispatch
    mov  byte [preview_page], PAGE_BUFFER_DEMO
    jmp  .done
.dispatch:
    cmp  byte [preview_page], PAGE_PALETTE
    je   .done
    cmp  byte [preview_page], PAGE_SPRITES
    jne  .map_key
    push word [bp+4]
    call UpdateSpritePreview
    jmp  .done
.map_key:
    cmp  al, 'r'
    jne  .check_edit
    call ResetMap
    call ResetCamera
    mov  word [preview_column], 0
    jmp  .done
.check_edit:
    cmp  al, 't'
    jne  .movement
    call EmptyPreviewBox
    jmp  .done
.movement:
    cmp  byte [preview_page], PAGE_BUFFER_DEMO
    jne  .camera_keys
    cmp  ah, KEY_LEFT
    jne  .demo_right
    cmp  word [preview_column], 0
    je   .done
    dec  word [preview_column]
    jmp  .done
.demo_right:
    cmp  ah, KEY_RIGHT
    jne  .done
    cmp  word [preview_column], LAST_WINDOW
    je   .done
    inc  word [preview_column]
    jmp  .done
.camera_keys:
    push ax
    call UpdateCameraPreview
.done:
    pop  ax
    pop  bp
    ret  2

; Empty Preview Box
; Inputs: DS project segment. Outputs: preview mushroom box emptied.
; Changes: flags only.
EmptyPreviewBox:
    push ax
    mov  ax, 7 * TILE_SIZE
    push ax
    mov  ax, 5 * TILE_SIZE
    push ax
    call GetTile
    cmp  ax, TILE_POWER_BOX
    jne  .done
    mov  byte [working_map+7*LEVEL_COLUMNS+5], TILE_EMPTY_BOX
.done:
    pop  ax
    ret
; UpdateCameraPreview(key)
; Input: BIOS key word at [bp+4]. Outputs: preview movement or pause.
; Changes: flags only. Vertical preview movement leaves the camera alone.
UpdateCameraPreview:
    push bp
    mov  bp, sp
    push ax
    mov  ax, [bp+4]
    cmp  al, 13
    jne  .check_pause
    xor  byte [camera_paused], 1
    jmp  .done
.check_pause:
    cmp  byte [camera_paused], 0
    je   .active
    jmp  near .done
.active:
    cmp  al, 'a'
    je   .left
    cmp  al, 'd'
    je   .right
    cmp  al, ','
    je   .fine_left
    cmp  al, '.'
    je   .fine_right
    cmp  ah, KEY_LEFT
    je   .left
    cmp  ah, KEY_RIGHT
    je   .right
    cmp  ah, KEY_UP
    je   .up
    cmp  ah, KEY_DOWN
    jne  .done
    cmp  word [hero_preview_y], 128
    jae  .done
    add  word [hero_preview_y], 4
    jmp  .done
.up:
    cmp  word [hero_preview_y], 20
    jbe  .done
    sub  word [hero_preview_y], 4
    jmp  .done
.left:
    mov  ax, -4
    jmp  .set_left
.fine_left:
    mov  ax, -1
.set_left:
    mov  word [hero_preview_flags], SPRITE_MIRROR
    jmp  .set_step
.right:
    mov  ax, 4
    jmp  .set_right
.fine_right:
    mov  ax, 1
.set_right:
    mov  word [hero_preview_flags], 0
.set_step:
    mov  [hero_preview_dx], ax
.done:
    pop  ax
    pop  bp
    ret  2
; ResetCamera
; Restores the starting view and hero position for new lives and games.
; Inputs: none. Outputs: camera and hero preview state. Changes: none.
ResetCamera:
    mov  word [camera_x], 0
    mov  word [hero_world_x], HERO_START_X
    mov  word [hero_preview_dx], 0
    mov  word [hero_preview_y], 24
    mov  word [hero_preview_flags], 0
    mov  byte [camera_paused], 0
    ret

; UpdateCamera(proposed_x)
; Input: signed whole-pixel hero x at [bp+4], after horizontal movement.
; Outputs: clamped hero world x, forward-only camera, dx=0 at a wall.
; Changes: flags only. Call once per map frame after hero movement.
UpdateCamera:
    push bp
    mov  bp, sp
    push ax
    mov  ax, [bp+4]
    cmp  ax, [camera_x]
    jle  .left_wall
    cmp  ax, HERO_MAX_X
    jl   .store_hero
    mov  ax, HERO_MAX_X
    mov  word [hero_preview_dx], 0
    jmp  .store_hero
.left_wall:
    mov  ax, [camera_x]
    mov  word [hero_preview_dx], 0
.store_hero:
    mov  [hero_world_x], ax

    sub  ax, CAMERA_FOLLOW_X
    cmp  ax, [camera_x]
    jle  .done
    cmp  ax, MAX_CAMERA_X
    jle  .store_camera
    mov  ax, MAX_CAMERA_X
.store_camera:
    mov  [camera_x], ax
.done:
    pop  ax
    pop  bp
    ret  2

; InstallKeyboard / RestoreKeyboard
; Save the DOS IRQ1 vector and replace it for the duration of the preview.
; Inputs: DS = program segment. Preserve registers; flags may change.
InstallKeyboard:
    push ax
    push bx
    push dx
    push ds
    push es
    mov  ax, 3509h
    int  21h
    mov  [old_keyboard_offset], bx
    mov  [old_keyboard_segment], es
    mov  dx, KeyboardISR
    mov  ax, 2509h
    int  21h
    pop  es
    pop  ds
    pop  dx
    pop  bx
    pop  ax
    ret

RestoreKeyboard:
    push ax
    push dx
    push ds
    mov  dx, [old_keyboard_offset]
    mov  ds, [old_keyboard_segment]
    mov  ax, 2509h
    int  21h
    pop  ds
    pop  dx
    pop  ax
    ret

; KeyboardISR
; IRQ1 owns port 60h while installed. Complete the interrupt here.
; Use CS overrides because the interrupt may arrive while DS is the buffer.
KeyboardISR:
    push ax
    push bx
    in   al, 60h
    cmp  al, 0E0h
    je   .ack
    mov  ah, al
    and  al, 7Fh
    xor  bx, bx
    mov  bl, al
    test ah, 80h
    jnz  .release
    cmp  byte [cs:key_state+bx], 0
    jne  .ack                    ; typematic make, still the same press
    mov  byte [cs:key_state+bx], 1
    mov  byte [cs:key_pressed+bx], 1
    jmp  .ack
.release:
    mov  byte [cs:key_state+bx], 0
.ack:
    ; Pulse the keyboard acknowledge line while preserving the other bits.
    in   al, 61h
    mov  ah, al
    or   al, 80h
    out  61h, al
    mov  al, ah
    out  61h, al
    mov  al, 20h
    out  20h, al
    pop  bx
    pop  ax
    iret

; PollPreviewKeys
; Read press events for commands, then read the held keys for movement.
; XCHG takes and clears an event in one instruction. Preserves registers.
PollPreviewKeys:
    push ax
    push bx
    push cx
    push si

    mov  si, preview_commands
    mov  cx, PREVIEW_COMMAND_COUNT
.command:
    xor  bx, bx
    mov  bl, [si]
    xor  al, al
    xchg al, [key_pressed+bx]
    or   al, al
    jz   .next_command
    xor  ah, ah
    mov  al, [si+1]
    push ax
    call HandlePreviewKey
.next_command:
    add  si, 2
    loop .command

    cmp  byte [preview_page], PAGE_MAP
    jne  .vertical
    ; On the world page, A/D and the arrows are equivalent.
    mov  al, [key_state+KEY_LEFT]
    or   al, [key_state+KEY_A]
    mov  ah, [key_state+KEY_RIGHT]
    or   ah, [key_state+KEY_D]
    cmp  al, ah
    jne  .horizontal
    xor  al, al
    xchg al, [key_pressed+KEY_COMMA]
    or   al, al
    jz   .period
    mov  al, ','
    jmp  .fine
.period:
    xor  al, al
    xchg al, [key_pressed+KEY_PERIOD]
    or   al, al
    jz   .vertical
    mov  al, '.'
.fine:
    xor  ah, ah
    push ax
    call HandlePreviewKey
    jmp  .vertical
.horizontal:
    mov  ah, KEY_RIGHT
    or   al, al
    jz   .send_horizontal
    mov  ah, KEY_LEFT
    jmp  .send_horizontal
.vertical:
    mov  bl, KEY_UP
    cmp  byte [key_state+KEY_UP], 0
    jne  .send_vertical
    mov  bl, KEY_DOWN
    cmp  byte [key_state+KEY_DOWN], 0
    jne  .send_vertical
    cmp  byte [preview_page], PAGE_MAP
    je   .done
    mov  ah, KEY_LEFT
    cmp  byte [key_state+KEY_LEFT], 0
    jne  .send_horizontal
    mov  ah, KEY_RIGHT
    cmp  byte [key_state+KEY_RIGHT], 0
    je   .done
.send_horizontal:
    xor  al, al
    push ax
    call HandlePreviewKey
    cmp  byte [preview_page], PAGE_MAP
    jne  .done
    cmp  byte [key_state+KEY_LEFT_SHIFT], 0
    je   .check_vertical
    shl  word [hero_preview_dx], 1
.check_vertical:
    mov  bl, KEY_UP
    cmp  byte [key_state+KEY_UP], 0
    jne  .send_vertical
    mov  bl, KEY_DOWN
    cmp  byte [key_state+KEY_DOWN], 0
    je   .done
.send_vertical:
    xor  al, al
    mov  ah, bl
    push ax
    call HandlePreviewKey
.done:
    pop  si
    pop  cx
    pop  bx
    pop  ax
    ret

; DrawKeyboardIndicators
; Three boxes in the HUD: Right, Left Shift, Space (left to right).
; A bright green box means that key is held. Preserves registers.
DrawKeyboardIndicators:
    pushf
    cld
    push ax
    push bx
    push cx
    push si
    mov  bx, 8
    mov  si, .codes
    mov  cx, 3
.box:
    lodsb
    xor  ah, ah
    push bx
    mov  bx, ax
    mov  ax, 8
    cmp  byte [key_state+bx], 0
    je   .draw
    mov  ax, 10
.draw:
    pop  bx
    push ax
    mov  ax, 8
    push ax
    mov  ax, 12
    push ax
    mov  ax, 4
    push ax
    push bx
    call FillRect
    add  bx, 16
    loop .box
    pop  si
    pop  cx
    pop  bx
    pop  ax
    popf
    ret
.codes:
    db KEY_RIGHT, KEY_LEFT_SHIFT, KEY_SPACE

; This stack is inside the resized block; DOS frees both blocks on exit.
    align 2, db 0
    times 1024 db 0
StackTop:
ProgramEnd:
