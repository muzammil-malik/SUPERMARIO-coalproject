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

; Each entry contains x, y, width, and height.
border_rectangles:
    dw 0, 0, SCREEN_WIDTH, 1
    dw 0, SCREEN_HEIGHT - 1, SCREEN_WIDTH, 1
    dw 0, 0, 1, SCREEN_HEIGHT
    dw SCREEN_WIDTH - 1, 0, 1, SCREEN_HEIGHT
BORDER_COUNT       equ ($ - border_rectangles) / 8

; Module 3 tile codes
TILE_SKY           equ 0
TILE_GROUND        equ 1
INVALID_TILE       equ 0FFFFh

; Temporary map with ten sky rows and two ground rows.
original_map:
    times MAP_COLUMNS * (MAP_ROWS - 2) db TILE_SKY
    times MAP_COLUMNS * 2 db TILE_GROUND

; ResetMap will initialize this copy in the next step.
working_map:
    times MAP_BYTES db 0

; Each test contains world pixel x and y.
tile_test_points:
    dw 55, 147
    dw 55, 160
    dw 959, 191
    dw 960, 160
TILE_TEST_COUNT    equ ($ - tile_test_points) / 4

tile_test_results:
    times TILE_TEST_COUNT dw 0

start:
    ; Select graphics mode and set up the data and video segments.
    mov ax, GRAPHICS_MODE
    int 10h
    push cs
    pop ds
    mov ax, VIDEO_SEGMENT
    mov es, ax

    ; Run the lookup tests and save each result for AFD.
    mov si, tile_test_points
    mov di, tile_test_results
    mov cx, TILE_TEST_COUNT

run_tile_test:
    mov ax, original_map
    push ax
    push word [si+2]            ; World y
    push word [si]              ; World x
    call GetTile
    mov [di], ax

    add si, 4                   ; Next coordinate pair
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

    ; Draw one rectangle per palette entry.
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

    ; Draw the four edges of the white border.
    mov si, border_rectangles
    mov cx, BORDER_COUNT

draw_border:
    mov ax, COLOR_WHITE
    push ax
    push word [si+6]            ; Height
    push word [si+4]            ; Width
    push word [si+2]            ; Screen y
    push word [si]              ; Screen x
    call FillRect

    add si, 8
    loop draw_border

    ; PutPixel(10, 2, COLOR_WHITE)
    mov ax, COLOR_WHITE
    push ax
    mov ax, 2
    push ax
    mov ax, 10
    push ax
    call PutPixel

    ; Keep the test picture visible until a key is pressed.
    mov ah, 00h
    int 16h

exit_program:
    mov ax, TEXT_MODE
    int 10h
    mov ax, 4C00h
    int 21h

; GetTile
; Purpose: Read the tile at a world pixel coordinate.
; Inputs: Stack words x, y, and map address in DS.
; Outputs: AX = tile code or FFFFh for an invalid coordinate.
; Registers changed: AX and flags.
GetTile:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx

    mov bx, [bp+4]
    cmp bx, MAP_PIXEL_WIDTH
    jae .invalid

    mov ax, [bp+6]
    cmp ax, MAP_PIXEL_HEIGHT
    jae .invalid

    ; Divide both pixel coordinates by 16.
    mov cl, TILE_SHIFT
    shr bx, cl                  ; BX = tile column
    shr ax, cl                  ; AX = tile row

    ; Convert row and column to a byte address.
    mov cx, MAP_COLUMNS
    mul cx                      ; DX:AX = row * 60
    add bx, ax                  ; BX = row * 60 + column
    add bx, [bp+8]              ; BX = map address + index

    xor ax, ax
    mov al, [bx]
    jmp .done

.invalid:
    mov ax, INVALID_TILE

.done:
    pop dx
    pop cx
    pop bx
    pop bp
    ret 6

; PutPixel
; Purpose: Draw one pixel inside the screen.
; Inputs: Stack words x, y, and colour. ES is the drawing segment.
; Outputs: Writes one byte for a valid coordinate.
; Registers changed: Flags only on return.
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

    ; DI = y * 256 + y * 64 + x
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

; FillRect
; Purpose: Fill a rectangle that fits entirely inside the screen.
; Inputs: Stack words x, y, width, height, and colour.
;         ES is the drawing segment.
; Outputs: Draws valid rectangles. Skips empty or invalid rectangles.
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

    ; Check x and the number of pixels available to its right.
    mov bx, [bp+4]
    cmp bx, SCREEN_WIDTH
    jae .done
    mov ax, SCREEN_WIDTH
    sub ax, bx
    mov cx, [bp+8]
    jcxz .done
    cmp cx, ax
    ja .done

    ; Check y and the number of rows available below it.
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

    ; Calculate the offset of the first pixel.
    mov di, bx
    mov cl, 8
    shl di, cl
    mov cl, 6
    shl bx, cl
    add di, bx
    add di, [bp+4]

    ; After filling a row, skip to the same x on the next row.
    mov bx, SCREEN_WIDTH
    sub bx, [bp+8]
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