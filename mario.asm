cpu 8086
bits 16
org 100h

jmp start

; Display and level constants
SCREEN_WIDTH       equ 320
SCREEN_HEIGHT      equ 200
TILE_SIZE          equ 16
TILE_SHIFT         equ 4
MAP_COLUMNS        equ 60
MAP_ROWS           equ 12
MAP_BYTES          equ MAP_COLUMNS * MAP_ROWS
MAP_PIXEL_WIDTH    equ MAP_COLUMNS * TILE_SIZE
MAP_PIXEL_HEIGHT   equ MAP_ROWS * TILE_SIZE
VISIBLE_COLUMNS    equ SCREEN_WIDTH / TILE_SIZE
LAST_COLUMN        equ MAP_COLUMNS - VISIBLE_COLUMNS

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
COLOR_YELLOW       equ 14
COLOR_LIGHT_GREEN  equ 10

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

; Initial game data
player_x           dw 32
player_hp          db START_HP
player_lives       db START_LIVES
active_enemy_count db 0
score_low          dw 0
score_high         dw 0
coin_count         db 0
time_left          dw START_TIME
key_states         times KEY_COUNT db 0

; Tile codes from Appendix A.2
TILE_SKY           equ 0
TILE_GROUND        equ 1
TILE_BRICK         equ 2
TILE_QUESTION_COIN equ 3
TILE_QUESTION_MUSH equ 4
TILE_EMPTY_BLOCK   equ 5
TILE_PIPE_TOP_L    equ 6
TILE_PIPE_TOP_R    equ 7
TILE_PIPE_BODY_L   equ 8
TILE_PIPE_BODY_R   equ 9
TILE_STAIR         equ 10
TILE_COIN          equ 11
TILE_FLAG          equ 12
INVALID_TILE       equ 0FFFFh

tile_colors:
    db COLOR_SKY, COLOR_GROUND, COLOR_BRICK, COLOR_YELLOW
    db COLOR_ENEMY, COLOR_GRAY
    db COLOR_LIGHT_GREEN, COLOR_LIGHT_GREEN
    db COLOR_PIPE, COLOR_PIPE, COLOR_GRAY, COLOR_YELLOW, COLOR_WHITE
TILE_COLOR_COUNT equ $ - tile_colors

; Pad the row with sky up to the requested column.
%macro SKY_TO 2
    times (%2 - ($ - %1)) db TILE_SKY
%endmacro

original_map:
    ; Row 0 is reserved for the HUD. Row 1 is sky.
    times MAP_COLUMNS * 2 db TILE_SKY

row_2:
    SKY_TO row_2, 57
    db TILE_FLAG
    SKY_TO row_2, MAP_COLUMNS

row_3:
    SKY_TO row_3, 57
    db TILE_FLAG
    SKY_TO row_3, MAP_COLUMNS

row_4:
    SKY_TO row_4, 57
    db TILE_FLAG
    SKY_TO row_4, MAP_COLUMNS

row_5:
    SKY_TO row_5, 23
    times 3 db TILE_COIN
    SKY_TO row_5, 57
    db TILE_FLAG
    SKY_TO row_5, MAP_COLUMNS

row_6:
    SKY_TO row_6, 5
    db TILE_QUESTION_MUSH
    SKY_TO row_6, 11
    db TILE_QUESTION_COIN
    SKY_TO row_6, 26
    db TILE_QUESTION_COIN
    SKY_TO row_6, 35
    db TILE_QUESTION_MUSH
    SKY_TO row_6, 39
    times 3 db TILE_COIN
    SKY_TO row_6, 46
    db TILE_QUESTION_COIN
    SKY_TO row_6, 54
    db TILE_STAIR
    SKY_TO row_6, 57
    db TILE_FLAG
    SKY_TO row_6, MAP_COLUMNS

row_7:
    SKY_TO row_7, 8
    times 3 db TILE_BRICK
    SKY_TO row_7, 12
    times 4 db TILE_COIN
    SKY_TO row_7, 32
    db TILE_PIPE_TOP_L, TILE_PIPE_TOP_R
    SKY_TO row_7, 43
    times 3 db TILE_BRICK
    SKY_TO row_7, 53
    times 2 db TILE_STAIR
    SKY_TO row_7, 57
    db TILE_FLAG
    SKY_TO row_7, MAP_COLUMNS

row_8:
    SKY_TO row_8, 22
    db TILE_PIPE_TOP_L, TILE_PIPE_TOP_R
    SKY_TO row_8, 32
    db TILE_PIPE_BODY_L, TILE_PIPE_BODY_R
    SKY_TO row_8, 52
    times 3 db TILE_STAIR
    SKY_TO row_8, 57
    db TILE_FLAG
    SKY_TO row_8, MAP_COLUMNS

row_9:
    SKY_TO row_9, 22
    db TILE_PIPE_BODY_L, TILE_PIPE_BODY_R
    SKY_TO row_9, 32
    db TILE_PIPE_BODY_L, TILE_PIPE_BODY_R
    SKY_TO row_9, 51
    times 4 db TILE_STAIR
    SKY_TO row_9, 57
    db TILE_STAIR
    SKY_TO row_9, MAP_COLUMNS

    ; Ground rows 10 and 11, with pits at 13–14 and 39–41.
    %rep 2
        times 13 db TILE_GROUND
        times 2  db TILE_SKY
        times 24 db TILE_GROUND
        times 3  db TILE_SKY
        times 18 db TILE_GROUND
    %endrep

working_map:
    times MAP_BYTES db TILE_SKY

; Spawn columns for the later enemy module.
goomba_spawn_columns db 17, 19, 29, 47
koopa_spawn_columns  db 27, 45

; Data for the optional Module 2 palette preview.
test_colors:
    db COLOR_SKY, COLOR_GROUND, COLOR_BRICK, COLOR_PIPE
    db COLOR_HERO, COLOR_ENEMY, COLOR_TEXT, COLOR_HUD
TEST_COLOR_COUNT equ $ - test_colors

border_rectangles:
    dw 0, 0, SCREEN_WIDTH, 1
    dw 0, SCREEN_HEIGHT - 1, SCREEN_WIDTH, 1
    dw 0, 0, 1, SCREEN_HEIGHT
    dw SCREEN_WIDTH - 1, 0, 1, SCREEN_HEIGHT
BORDER_COUNT equ ($ - border_rectangles) / 8

; World pixel coordinates for testing GetTile in AFD.
tile_test_points:
    dw 55, 147, 55, 160, 959, 191, 960, 160
    dw 208, 160, 80, 96, 352, 128, 912, 32
TILE_TEST_COUNT equ ($ - tile_test_points) / 4

tile_test_results:
    times TILE_TEST_COUNT dw 0

start:
    mov ax, GRAPHICS_MODE
    int 10h

    ; DS points to program data. ES points to VGA memory.
    push cs
    pop ds
    mov ax, VIDEO_SEGMENT
    mov es, ax

    ; ResetMap(original_map, working_map)
    mov ax, working_map
    push ax
    mov ax, original_map
    push ax
    call ResetMap

    ; Save the tile lookup results for inspection in AFD.
    mov si, tile_test_points
    mov di, tile_test_results
    mov cx, TILE_TEST_COUNT

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
    xor bx, bx                 ; First preview starts at column 0.

preview_map:
    mov ax, working_map
    push ax
    push bx
    call DrawMap

read_preview_key:
    call ReadKey
    cmp ah, KEY_ESC
    je exit_program
    cmp ah, KEY_PAUSE
    je preview_palette
    cmp ah, KEY_ENTER
    jne read_preview_key

    add bx, VISIBLE_COLUMNS
    cmp bx, LAST_COLUMN
    jbe preview_map
    xor bx, bx
    jmp preview_map

preview_palette:
    call DrawPalette
    call ReadKey
    cmp ah, KEY_ESC
    je exit_program
    jmp preview_map

exit_program:
    mov ax, TEXT_MODE
    int 10h
    mov ax, 4C00h
    int 21h

; ReadKey
; Waits for a BIOS keystroke and returns ASCII in AL, scan code in AH.
; Preserves the other registers used by the preview.
ReadKey:
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es

    mov ah, 00h
    int 16h

    pop es
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; GetTile(x, y, map)
; Inputs: World pixel coordinates and map offset in DS.
; Output: AX = tile code, or FFFFh for an invalid coordinate.
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

    ; Convert pixels to tile column and row.
    mov cl, TILE_SHIFT
    shr bx, cl
    shr ax, cl

    ; Index = row * 60 + column.
    mov cx, MAP_COLUMNS
    mul cx
    add bx, ax
    add bx, [bp+8]
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

; ResetMap(source, destination)
; Copies 720 bytes between two maps in DS. Preserves ES and flags.
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

; DrawMap(first column, map)
; Draws a 20-column window from the map in DS to the screen in ES.
DrawMap:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, [bp+4]
    cmp ax, LAST_COLUMN
    ja .done

    ; Skip HUD row 0 and find the first tile in row 1.
    mov si, [bp+6]
    add si, ax
    add si, MAP_COLUMNS

    ; Clear the whole screen to black.
    mov ax, COLOR_BLACK
    push ax
    mov ax, SCREEN_HEIGHT
    push ax
    mov ax, SCREEN_WIDTH
    push ax
    xor ax, ax
    push ax
    push ax
    call FillRect

    ; Paint the blue play area from y = 16 through y = 191.
    mov ax, COLOR_SKY
    push ax
    mov ax, MAP_PIXEL_HEIGHT - TILE_SIZE
    push ax
    mov ax, SCREEN_WIDTH
    push ax
    mov ax, TILE_SIZE
    push ax
    xor ax, ax
    push ax
    call FillRect

    mov dx, TILE_SIZE

.next_row:
    xor bx, bx
    mov cx, VISIBLE_COLUMNS

.next_tile:
    xor ax, ax
    mov al, [si]
    push ax
    push dx
    push bx
    call DrawTile

    inc si
    add bx, TILE_SIZE
    loop .next_tile

    ; SI already advanced 20 bytes. Skip the other 40.
    add si, MAP_COLUMNS - VISIBLE_COLUMNS
    add dx, TILE_SIZE
    cmp dx, MAP_PIXEL_HEIGHT
    jb .next_row

.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 4

; DrawTile(screen x, screen y, tile code)
; Uses FillRect. Sky is already painted by DrawMap.
DrawTile:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, [bp+8]
    cmp bx, TILE_COLOR_COUNT
    jae .done
    cmp bx, TILE_SKY
    je .done

    mov si, [bp+4]
    mov dx, [bp+6]
    mov cx, TILE_SIZE

    xor ax, ax
    mov al, [tile_colors+bx]
    push ax                    ; Colour is pushed first.
    mov ax, TILE_SIZE          ; Default height.

    cmp bx, TILE_COIN
    je .coin
    cmp bx, TILE_FLAG
    jne .draw

    ; Draw a narrow pole in the middle of the tile.
    add si, 7
    mov cx, 2
    jmp .draw

.coin:
    add si, 5
    add dx, 4
    mov cx, 6
    mov ax, 8

.draw:
    push ax                    ; Height
    push cx                    ; Width
    push dx                    ; y
    push si                    ; x
    call FillRect

.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

; DrawPalette
; Displays the Module 2 palette, border, and white test pixel.
DrawPalette:
    push ax
    push bx
    push cx
    push si

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
    mov bx, 20
    mov cx, TEST_COLOR_COUNT

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

    mov si, border_rectangles
    mov cx, BORDER_COUNT

.border:
    mov ax, COLOR_WHITE
    push ax
    push word [si+6]
    push word [si+4]
    push word [si+2]
    push word [si]
    call FillRect

    add si, 8
    loop .border

    mov ax, COLOR_WHITE
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

; PutPixel(x, y, colour)
; Writes one pixel to ES if the coordinates fit on screen.
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

    ; Pixel offset = y * 256 + y * 64 + x.
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

; FillRect(x, y, width, height, colour)
; Fills a rectangle in ES. Skips empty and out-of-bounds rectangles.
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

    ; Calculate the offset of the first pixel.
    mov di, bx
    mov cl, 8
    shl di, cl
    mov cl, 6
    shl bx, cl
    add di, bx
    add di, [bp+4]

    ; Advance to the same x after each row is filled.
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