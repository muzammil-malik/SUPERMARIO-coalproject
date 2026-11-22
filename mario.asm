cpu 8086
bits 16
org 100h

jmp start

; Display and level
SCREEN_WIDTH       equ 320
SCREEN_HEIGHT      equ 200
TILE_SIZE          equ 16
TILE_SHIFT         equ 4
MAP_COLUMNS        equ 60
MAP_ROWS           equ 12
MAP_BYTES          equ MAP_COLUMNS * MAP_ROWS
MAP_PIXEL_WIDTH    equ MAP_COLUMNS * TILE_SIZE
MAP_PIXEL_HEIGHT   equ MAP_ROWS * TILE_SIZE

TEXT_MODE          equ 03h
GRAPHICS_MODE      equ 13h
VIDEO_SEGMENT      equ 0A000h

; Default VGA palette
COLOR_TRANSPARENT  equ 0
COLOR_BLACK        equ 0
COLOR_WHITE        equ 15
COLOR_SKY          equ 9
COLOR_GROUND       equ 6
COLOR_BRICK        equ 12
COLOR_PIPE         equ 2
COLOR_HERO         equ 4
COLOR_ENEMY        equ 13
COLOR_TEXT         equ COLOR_WHITE
COLOR_HUD          equ COLOR_BLACK
COLOR_GRAY         equ 8

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

; Clock and keyboard data
time_left          dw START_TIME
key_states         times KEY_COUNT db 0

; Module 2 palette test
SWATCH_WIDTH       equ 28
SWATCH_HEIGHT      equ 32
SWATCH_STEP        equ 36
SWATCH_X           equ 20
SWATCH_Y           equ 60

test_colors:
    db COLOR_SKY, COLOR_GROUND, COLOR_BRICK, COLOR_PIPE
    db COLOR_HERO, COLOR_ENEMY, COLOR_TEXT, COLOR_HUD
TEST_COLOR_COUNT   equ $ - test_colors

; Module 3 tile codes
TILE_SKY           equ 0
TILE_GROUND        equ 1
INVALID_TILE       equ 0FFFFh

; Temporary 60 by 12 map. Each tile is one byte.
original_map:
    times MAP_COLUMNS * 10 db TILE_SKY
    times MAP_COLUMNS * 2  db TILE_GROUND

; ResetMap will initialize this copy in the next step.
working_map:
    times MAP_BYTES db 0

; Each test contains two words: world pixel x and world pixel y.
tile_test_points:
    dw 55, 147
    dw 55, 160
    dw 959, 191
    dw 960, 160
TILE_TEST_COUNT    equ ($ - tile_test_points) / 4

tile_test_results:
    times TILE_TEST_COUNT dw 0

start:
    mov ax, GRAPHICS_MODE
    int 10h

    push cs
    pop ds
    mov ax, VIDEO_SEGMENT
    mov es, ax

    ; Run the tile lookups and save each AX result for AFD.
    mov si, tile_test_points
    mov di, tile_test_results
    mov cx, TILE_TEST_COUNT

run_tile_test:
    mov ax, original_map
    push ax                     ; Map address
    push word [si+2]            ; World y
    push word [si]              ; World x
    call GetTile
    mov [di], ax

    add si, 4                   ; Next pair of coordinates
    add di, 2                   ; Next result word
    loop run_tile_test

tile_tests_done:
    ; FillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, COLOR_GRAY)
    mov ax, COLOR_GRAY
    push ax
    mov ax, SCREEN_HEIGHT
    push ax
    mov ax, SCREEN_WIDTH
    push ax
    xor ax, ax
    push ax
    push ax
    call FillRect

    mov si, test_colors
    mov bx, SWATCH_X
    mov cx, TEST_COLOR_COUNT

draw_swatch:
    xor ax, ax
    mov al, [si]
    push ax
    mov ax, SWATCH_HEIGHT
    push ax
    mov ax, SWATCH_WIDTH
    push ax
    mov ax, SWATCH_Y
    push ax
    push bx
    call FillRect

    inc si
    add bx, SWATCH_STEP
    loop draw_swatch

    ; PutPixel(10, 2, COLOR_WHITE)
    mov ax, COLOR_WHITE
    push ax
    mov ax, 2
    push ax
    mov ax, 10
    push ax
    call PutPixel

    ; Wait for a key so the palette remains visible.
    mov ah, 00h
    int 16h

exit_program:
    mov ax, TEXT_MODE
    int 10h
    mov ax, 4C00h
    int 21h

; GetTile
; Purpose: Read the tile at a world pixel position.
; Inputs: Stack words x, y, and map address in DS.
; Outputs: AX = tile code, or FFFFh for an invalid coordinate.
; Registers changed: AX and flags.
GetTile:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx

    ; Check world bounds before reading the map.
    mov bx, [bp+4]
    cmp bx, MAP_PIXEL_WIDTH
    jae .invalid

    mov ax, [bp+6]
    cmp ax, MAP_PIXEL_HEIGHT
    jae .invalid

    ; Divide by 16 to find the tile column and row.
    mov cl, TILE_SHIFT
    shr bx, cl                  ; BX = column
    shr ax, cl                  ; AX = row

    ; MUL CX calculates DX:AX = row * MAP_COLUMNS.
    mov cx, MAP_COLUMNS
    mul cx
    add bx, ax                  ; BX = row * 60 + column
    add bx, [bp+8]              ; BX = address of the tile

    xor ax, ax
    mov al, [bx]                ; Read one byte. AH stays zero.
    jmp .done

.invalid:
    mov ax, INVALID_TILE

.done:
    pop dx
    pop cx
    pop bx
    pop bp
    ret 6

; GetPixelOffset
; Purpose: Convert a valid screen coordinate to a VGA byte offset.
; Inputs: Stack words x and y.
; Outputs: AX = y * 320 + x.
; Registers changed: AX and flags.
GetPixelOffset:
    push bp
    mov bp, sp
    push cx
    push dx

    mov ax, [bp+6]
    mov dx, ax
    mov cl, 8
    shl ax, cl                  ; AX = y * 256
    mov cl, 6
    shl dx, cl                  ; DX = y * 64
    add ax, dx
    add ax, [bp+4]

    pop dx
    pop cx
    pop bp
    ret 4

; PutPixel
; Purpose: Draw one pixel if it is inside the screen.
; Inputs: Stack words x, y, colour. ES is the drawing segment.
; Outputs: Writes one byte for a valid coordinate.
; Registers changed: Flags only on return.
PutPixel:
    push bp
    mov bp, sp
    push ax
    push di

    cmp word [bp+4], SCREEN_WIDTH
    jae .done
    cmp word [bp+6], SCREEN_HEIGHT
    jae .done

    push word [bp+6]
    push word [bp+4]
    call GetPixelOffset
    mov di, ax
    mov ax, [bp+8]
    mov [es:di], al

.done:
    pop di
    pop ax
    pop bp
    ret 6

; FillRect
; Purpose: Fill a rectangle that fits entirely inside the screen.
; Inputs: Stack words x, y, width, height, colour.
;         ES is the drawing segment.
; Outputs: Draws a valid rectangle.
; Registers changed: None on return. Caller flags are restored.
FillRect:
    push bp
    mov bp, sp
    pushf
    push ax
    push bx
    push cx
    push dx
    push di

    ; Check x, then compare width with the space left on the row.
    mov bx, [bp+4]
    cmp bx, SCREEN_WIDTH
    jae .done
    mov ax, SCREEN_WIDTH
    sub ax, bx
    mov cx, [bp+8]
    jcxz .done
    cmp cx, ax
    ja .done

    ; Check y, then compare height with the rows left on screen.
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

    push word [bp+6]
    push word [bp+4]
    call GetPixelOffset
    mov di, ax

    mov bx, SCREEN_WIDTH
    sub bx, [bp+8]              ; Gap to the next row's starting x
    mov ax, [bp+12]
    cld

.fill_row:
    mov cx, [bp+8]
    rep stosb
    dec dx
    jz .done
    add di, bx
    jmp .fill_row

.done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    popf
    pop bp
    ret 10