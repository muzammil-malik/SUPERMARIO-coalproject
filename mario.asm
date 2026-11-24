cpu 8086
bits 16
org 100h
jmp start

SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
TILE_SIZE equ 16
MAP_COLUMNS equ 60
MAP_ROWS equ 12
MAP_BYTES equ MAP_COLUMNS * MAP_ROWS
VISIBLE_COLUMNS equ SCREEN_WIDTH / TILE_SIZE
COLOR_TRANSPARENT equ 0
START_LIVES equ 3
START_TIME equ 300
START_HP equ 1

FRAME_BYTES equ SCREEN_WIDTH * SCREEN_HEIGHT
frame_segment dw 0
buffer_error_text db 'Unable to allocate the video frame buffer.', 13, 10, '$'

player_x dw 32
player_lives db START_LIVES
player_hp db START_HP
time_left dw START_TIME
score_low dw 0
score_high dw 0
coin_count db 0
active_enemy_count db 0
key_states times 128 db 0

; Tile colours indexed by the Appendix A.2 tile codes, 0 through 12.
tile_colors db 9,6,12,14,13,8,10,10,2,2,8,14,15

original_map:
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,11,11,11,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0
    db 0,0,0,0,0,4,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,4,0,0,0,11,11,11,0,0,0,0,3,0,0,0,0,0,0,0,10,0,0,12,0,0
    db 0,0,0,0,0,0,0,0,2,2,2,0,11,11,11,11,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,7,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,10,10,0,0,12,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,7,0,0,0,0,0,0,0,0,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10,10,10,0,0,12,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,9,0,0,0,0,0,0,0,0,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10,10,10,10,0,0,10,0,0
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
working_map times MAP_BYTES db 0
goomba_spawn_columns db 17,19,29,47
koopa_spawn_columns db 27,45

tile_test_points:
    dw 55,147,55,160,959,191,960,160,208,160,80,96,352,128,912,32
tile_test_results times 8 dw 0

palette db 9,6,12,2,4,13,15,0
border:
    dw 0,0,320,1, 0,199,320,1, 0,0,1,200, 319,0,1,200

SPRITE_MIRROR equ 1
KEY_SPRITES   equ 1Fh          ; S toggles the sprite preview.
KEY_NEXT_SPRITE equ 31h        ; N selects the next sprite.
KEY_BLINK     equ 30h          ; B advances one preview frame.

sprite_preview db 0
sprite_index   db 0
blink_phase    db 0

sprite_table:
    dw small_stand, 16
    dw small_run, 16
    dw small_jump, 16
    dw super_stand, 32
    dw super_run, 32
    dw super_jump, 32
    dw goomba_walk, 16
    dw goomba_flat, 16
    dw koopa_walk, 16
    dw koopa_shell, 16
    dw mushroom_sprite, 16
    dw coin_sprite, 16
SPRITE_COUNT equ ($ - sprite_table) / 4

; Each placement is screen x, screen y, and extra flags.
sprite_preview_positions:
    dw 64, 48, 0
    dw 96, 48, SPRITE_MIRROR
    dw -8, 80, 0
    dw SCREEN_WIDTH - 8, 80, SPRITE_MIRROR
    dw 144, -8, 0
    dw 176, SCREEN_HEIGHT - 12, 0
SPRITE_POSITION_COUNT equ ($ - sprite_preview_positions) / 6

; Practice artwork. Each line is one row of 16 palette indices.
small_stand:
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 0, 14, 14, 14, 14, 14, 8, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 14, 14, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 14, 14, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0

small_run:
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 0, 14, 14, 14, 14, 14, 8, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 14, 14, 14, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 14, 14, 14, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 8, 8, 8, 8, 8, 0
    db 0, 0, 8, 8, 8, 8, 8, 0, 0, 0, 8, 8, 8, 8, 8, 0
    db 0, 0, 8, 8, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

small_jump:
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 0, 14, 14, 14, 14, 14, 8, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 3, 3, 14, 14, 0
    db 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 8, 8, 8, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 8, 8, 8, 0, 0, 0, 0, 8, 8, 8, 8, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 8, 8, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

super_stand:
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 0, 14, 14, 14, 14, 14, 8, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 14, 14, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 14, 14, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0
    db 0, 0, 0, 0, 8, 8, 8, 0, 0, 8, 8, 8, 0, 0, 0, 0

super_run:
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 0, 14, 14, 14, 14, 14, 8, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 14, 14, 14, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 14, 14, 14, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 8, 8, 8, 8, 8, 0
    db 0, 0, 8, 8, 8, 8, 8, 0, 0, 0, 8, 8, 8, 8, 8, 0
    db 0, 0, 8, 8, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

super_jump:
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 0, 0, 0
    db 0, 0, 0, 0, 14, 14, 14, 14, 14, 8, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 0
    db 0, 0, 0, 6, 6, 14, 14, 14, 14, 14, 14, 3, 3, 14, 14, 0
    db 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 3, 15, 3, 3, 3, 3, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 8, 8, 8, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
    db 0, 0, 0, 8, 8, 8, 0, 0, 0, 0, 8, 8, 8, 8, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 8, 8, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

goomba_walk:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 6, 6, 6, 6, 6, 6, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 6, 6, 6, 6, 6, 6, 0, 0, 0, 0, 0
    db 0, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0
    db 0, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0
    db 0, 0, 0, 6, 6, 15, 15, 6, 6, 15, 15, 6, 6, 0, 0, 0
    db 0, 0, 6, 6, 6, 15, 8, 6, 6, 15, 8, 6, 6, 6, 0, 0
    db 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0
    db 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0
    db 0, 0, 0, 8, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 8, 8, 8, 8, 0, 0, 8, 8, 8, 8, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 8, 8, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

goomba_flat:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0
    db 0, 0, 0, 6, 6, 15, 15, 6, 6, 15, 15, 6, 6, 0, 0, 0
    db 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0
    db 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0
    db 0, 0, 0, 8, 8, 8, 8, 0, 0, 8, 8, 8, 8, 0, 0, 0

koopa_walk:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 14, 14, 14, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 14, 14, 8, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 14, 14, 14, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 14, 14, 14, 0, 0
    db 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 14, 14, 14, 0, 0, 0
    db 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 14, 14, 14, 0, 0, 0
    db 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 14, 14, 0, 0, 0
    db 0, 0, 2, 2, 2, 10, 10, 10, 2, 2, 2, 14, 14, 0, 0, 0
    db 0, 0, 2, 2, 2, 10, 10, 10, 2, 2, 2, 14, 14, 0, 0, 0
    db 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0
    db 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 14, 14, 14, 14, 0, 0, 14, 14, 14, 14, 0, 0
    db 0, 0, 0, 0, 14, 14, 14, 14, 0, 0, 14, 14, 14, 14, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

koopa_shell:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0
    db 0, 0, 0, 2, 2, 10, 10, 10, 2, 2, 2, 2, 2, 0, 0, 0
    db 0, 0, 0, 2, 2, 10, 10, 10, 2, 2, 2, 2, 2, 0, 0, 0
    db 0, 0, 0, 2, 2, 2, 2, 2, 2, 10, 10, 2, 2, 0, 0, 0
    db 0, 0, 0, 2, 2, 2, 2, 2, 2, 10, 10, 2, 2, 0, 0, 0
    db 0, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 0, 0
    db 0, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 0, 0
    db 0, 0, 0, 0, 0, 8, 8, 8, 8, 8, 8, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

mushroom_sprite:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 12, 12, 12, 12, 12, 12, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 12, 12, 12, 12, 12, 12, 0, 0, 0, 0, 0
    db 0, 0, 0, 12, 12, 12, 12, 12, 12, 12, 15, 15, 12, 0, 0, 0
    db 0, 0, 0, 12, 15, 15, 15, 12, 12, 12, 15, 15, 12, 0, 0, 0
    db 0, 0, 0, 12, 15, 15, 15, 12, 12, 12, 12, 12, 12, 0, 0, 0
    db 0, 0, 12, 12, 15, 15, 15, 12, 12, 12, 12, 12, 12, 12, 0, 0
    db 0, 0, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0, 0
    db 0, 0, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0, 0
    db 0, 0, 0, 0, 0, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 8, 14, 14, 8, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

coin_sprite:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 14, 14, 14, 14, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 14, 14, 14, 14, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 15, 14, 14, 6, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 15, 14, 14, 6, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 15, 14, 14, 6, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 15, 14, 14, 6, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 15, 14, 14, 6, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 15, 14, 14, 6, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 14, 14, 14, 14, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 14, 14, 14, 14, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

start:
    ; Move the stack into memory retained by DOS resize.
    mov ax, cs
    cli
    mov ss, ax
    mov sp, stack_top
    sti
    mov ds, ax
    mov es, ax
    mov bx, (stack_top - $$ + 100h + 15) / 16
    mov ah, 4Ah
    int 21h
    jnc .resized
    jmp buffer_error
.resized:

    mov bx, FRAME_BYTES / 16
    mov ah, 48h
    int 21h
    jnc .allocated
    jmp buffer_error
.allocated:
    mov [frame_segment], ax

    mov ax, 0013h
    int 10h
    mov ax, [frame_segment]
    mov es, ax
    mov ax, working_map
    push ax
    mov ax, original_map
    push ax
    call ResetMap
    mov si, tile_test_points
    mov di, tile_test_results
    mov cx, 8
run_tile_test:
    mov ax, working_map
    push ax
    push word [si+2]
    push word [si]
    call GetTile
    mov [di], ax
    add si, 4
    add di, 2
    loop run_tile_test
tile_tests_done:
    xor bx, bx
preview_map:
    mov ax, working_map
    push ax
    push bx
    call DrawMap
    call DrawSpritePreview
    call PresentFrame

read_preview_key:
    call ReadKey
    call HandleSpritePreviewKey
    jc redraw_map
    cmp ah, 01h
    je exit_program
    cmp ah, 19h
    je preview_palette
    cmp ah, 1Ch
    jne read_preview_key
    add bx, VISIBLE_COLUMNS
    cmp bx, MAP_COLUMNS - VISIBLE_COLUMNS
    jbe redraw_map
    xor bx, bx
redraw_map:
    jmp preview_map

preview_palette:
    call DrawPalette
    call PresentFrame
    call ReadKey
    cmp ah, 01h
    je exit_program
    jmp preview_map

exit_program:
    mov ax, [frame_segment]
    mov es, ax
    mov ah, 49h
    int 21h
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h

; PresentFrame()
; Copies the complete frame from RAM to VGA. Preserves registers and flags.
PresentFrame:
    pushf
    push ax
    push cx
    push si
    push di
    push ds
    push es

    mov ax, [frame_segment]
    mov ds, ax
    mov ax, 0A000h
    mov es, ax
    xor si, si
    xor di, di
    mov cx, FRAME_BYTES / 2
    cld
    rep movsw

    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    popf
    ret

buffer_error:
    mov dx, buffer_error_text
    mov ah, 09h
    int 21h
    mov ax, 4C01h
    int 21h



; BIOS preview input. AH returns the scan code.
ReadKey:
    push bx
    push ds
    push es
    mov ah, 00h
    int 16h
    pop es
    pop ds
    pop bx
    ret

; HandleSpritePreviewKey()
; Input: BIOS scan code in AH. Output: CF set if the key requests a redraw.
; Preserves all general-purpose registers.
HandleSpritePreviewKey:
    cmp ah, KEY_SPRITES
    jne .check_next
    xor byte [sprite_preview], 1
    mov byte [blink_phase], 0
    stc
    ret

.check_next:
    cmp byte [sprite_preview], 0
    je .ignore
    cmp ah, KEY_NEXT_SPRITE
    jne .check_blink
    inc byte [sprite_index]
    cmp byte [sprite_index], SPRITE_COUNT
    jb .show
    mov byte [sprite_index], 0
.show:
    mov byte [blink_phase], 0
    stc
    ret

.check_blink:
    cmp ah, KEY_BLINK
    jne .ignore
    xor byte [blink_phase], 1
    stc
    ret

.ignore:
    clc
    ret

; DrawSpritePreview()
; Draws the selected bitmap normally, mirrored, and at the four screen edges.
; Skips the sprites on odd preview frames. Preserves registers and flags.
DrawSpritePreview:
    pushf
    cmp byte [sprite_preview], 0
    je .done
    cmp byte [blink_phase], 0
    jne .done

    push ax
    push bx
    push cx
    push si

    xor bx, bx
    mov bl, [sprite_index]
    shl bx, 1
    shl bx, 1
    mov si, sprite_preview_positions
    mov cx, SPRITE_POSITION_COUNT

.next_position:
    push word [si+4]
    push word [sprite_table+bx+2]
    push word [sprite_table+bx]
    push word [si+2]
    push word [si]
    call DrawSprite
    add si, 6
    loop .next_position

    pop si
    pop cx
    pop bx
    pop ax
.done:
    popf
    ret

; DrawSprite(x, y, bitmap, height, flags)
; DS holds the bitmap. ES is the destination. Colour zero is transparent.
; Flags bit 0 mirrors the image. PutPixel clips each visible pixel.
DrawSprite:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov si, [bp+8]
    mov dx, [bp+6]
    mov di, [bp+10]
    cmp di, 16
    je .row
    cmp di, 32
    jne .done
.row:
    mov bx, [bp+4]
    test word [bp+12], 1
    jz .row_start
    add bx, 15
.row_start:
    mov cx, 16
.pixel:
    xor ax, ax
    mov al, [si]
    cmp al, COLOR_TRANSPARENT
    je .advance
    push ax
    push dx
    push bx
    call PutPixel
.advance:
    inc si
    test word [bp+12], 1
    jnz .left
    inc bx
    jmp .count
.left:
    dec bx
.count:
    loop .pixel
    inc dx
    dec di
    jnz .row
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10

; Copy source to destination. Both offsets are in DS.
ResetMap:
    push bp
    mov bp, sp
    pushf
    push es
    push si
    push di
    push cx
    push ds
    pop es
    mov si, [bp+4]
    mov di, [bp+6]
    mov cx, MAP_BYTES
    cld
    rep movsb
    pop cx
    pop di
    pop si
    pop es
    popf
    pop bp
    ret 4

; GetTile(x, y, map): AX returns a tile code or FFFFh.
GetTile:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    mov bx, [bp+4]
    mov ax, [bp+6]
    cmp bx, MAP_COLUMNS * TILE_SIZE
    jae .invalid
    cmp ax, MAP_ROWS * TILE_SIZE
    jae .invalid
    mov cl, 4
    shr bx, cl
    shr ax, cl
    mov cx, MAP_COLUMNS
    mul cx
    add bx, ax
    add bx, [bp+8]
    xor ax, ax
    mov al, [bx]
    jmp .done
.invalid:
    mov ax, 0FFFFh
.done:
    pop dx
    pop cx
    pop bx
    pop bp
    ret 6

; DrawMap(first column, map). Draws a tile-aligned window into ES.
DrawMap:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    mov ax, [bp+4]
    cmp ax, MAP_COLUMNS - VISIBLE_COLUMNS
    ja .done
    mov si, [bp+6]
    add si, ax
    add si, MAP_COLUMNS
    mov ax, 0
    push ax
    mov ax, 200
    push ax
    mov ax, 320
    push ax
    mov ax, 0
    push ax
    mov ax, 0
    push ax
    call FillRect
    mov ax, 9
    push ax
    mov ax, 176
    push ax
    mov ax, 320
    push ax
    mov ax, 16
    push ax
    mov ax, 0
    push ax
    call FillRect
    mov dx, TILE_SIZE
.row:
    xor bx, bx
    mov cx, VISIBLE_COLUMNS
.tile:
    xor ax, ax
    mov al, [si]
    push ax
    push dx
    push bx
    call DrawTile
    inc si
    add bx, TILE_SIZE
    loop .tile
    add si, MAP_COLUMNS - VISIBLE_COLUMNS
    add dx, TILE_SIZE
    cmp dx, MAP_ROWS * TILE_SIZE
    jb .row
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 4

; DrawTile(x, y, tile). The blue background is drawn by DrawMap.
DrawTile:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    mov bx, [bp+8]
    cmp bx, 12
    ja .done
    cmp bx, 0
    je .done
    mov si, [bp+4]
    mov dx, [bp+6]
    mov cx, TILE_SIZE
    xor ax, ax
    mov al, [tile_colors+bx]
    push ax
    mov ax, TILE_SIZE
    cmp bx, 11
    je .coin
    cmp bx, 12
    jne .draw
    add si, 7
    mov cx, 2
    jmp .draw
.coin:
    add si, 5
    add dx, 4
    mov cx, 6
    mov ax, 8
.draw:
    push ax
    push cx
    push dx
    push si
    call FillRect
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

; Draw the Module 2 palette and border.
DrawPalette:
    push ax
    push bx
    push cx
    push si
    mov ax, 8
    push ax
    mov ax, 200
    push ax
    mov ax, 320
    push ax
    mov ax, 0
    push ax
    mov ax, 0
    push ax
    call FillRect
    mov si, palette
    mov bx, 20
    mov cx, 8
.swatch:
    xor ax, ax
    mov al, [si]
    push ax
    mov ax, 32
    push ax
    mov ax, 28
    push ax
    mov ax, 60
    push ax
    push bx
    call FillRect
    inc si
    add bx, 36
    loop .swatch
    mov si, border
    mov cx, 4
.edge:
    mov ax, 15
    push ax
    push word [si+6]
    push word [si+4]
    push word [si+2]
    push word [si]
    call FillRect
    add si, 8
    loop .edge
    mov ax, 15
    push ax
    mov ax, 2
    push ax
    mov ax, 10
    push ax
    call PutPixel
    pop si
    pop cx
    pop bx
    pop ax
    ret

; PutPixel(x, y, colour). Rejects coordinates outside the screen.
PutPixel:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push di
    mov bx, [bp+4]
    cmp bx, SCREEN_WIDTH
    jae .done
    mov ax, [bp+6]
    cmp ax, SCREEN_HEIGHT
    jae .done
    mov di, ax
    mov cl, 8
    shl di, cl
    mov cl, 6
    shl ax, cl
    add di, ax
    add di, bx
    mov ax, [bp+8]
    mov [es:di], al
.done:
    pop di
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

; FillRect(x, y, width, height, colour). Draws valid rectangles in ES.
FillRect:
    push bp
    mov bp, sp
    pushf
    push ax
    push bx
    push cx
    push dx
    push di
    mov bx, [bp+4]
    cmp bx, SCREEN_WIDTH
    jae .done
    mov ax, SCREEN_WIDTH
    sub ax, bx
    mov cx, [bp+8]
    jcxz .done
    cmp cx, ax
    ja .done
    mov bx, [bp+6]
    cmp bx, SCREEN_HEIGHT
    jae .done
    mov ax, SCREEN_HEIGHT
    sub ax, bx
    mov dx, [bp+10]
    cmp dx, 0
    je .done
    cmp dx, ax
    ja .done
    mov di, bx
    mov cl, 8
    shl di, cl
    mov cl, 6
    shl bx, cl
    add di, bx
    add di, [bp+4]
    mov bx, SCREEN_WIDTH
    sub bx, [bp+8]
    mov ax, [bp+12]
    cld
.row:
    mov cx, [bp+8]
    rep stosb
    dec dx
    jz .done
    add di, bx
    jmp .row
.done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    popf
    pop bp
    ret 10

; The stack must remain inside the resized DOS memory block.
align 2
times 1024 db 0
stack_top:
