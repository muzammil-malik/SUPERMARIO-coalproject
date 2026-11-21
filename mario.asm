cpu 8086
bits 16
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

; Module 2 test data
SWATCH_WIDTH       equ 28
SWATCH_HEIGHT      equ 32
SWATCH_STEP        equ 36
SWATCH_X           equ 20
SWATCH_Y           equ 60

test_colors:
    db COLOR_SKY, COLOR_GROUND, COLOR_BRICK, COLOR_PIPE
    db COLOR_HERO, COLOR_ENEMY, COLOR_TEXT, COLOR_HUD
TEST_COLOR_COUNT   equ $ - test_colors

start:
    ; Enter 320 by 200 graphics mode.
    mov ax, GRAPHICS_MODE
    int 10h

    ; Use DS for our data and ES for video memory.
    push cs
    pop ds
    mov ax, VIDEO_SEGMENT
    mov es, ax

    ; Fill the screen with dark gray so the black swatch is visible.
    ; FillRect(0, 0, 320, 200, 8)
    mov ax, 8
    push ax
    mov ax, SCREEN_HEIGHT
    push ax
    mov ax, SCREEN_WIDTH
    push ax
    xor ax, ax
    push ax
    push ax
    call FillRect

    ; Draw one rectangle for each game colour.
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

    ; Wait for a key so we can inspect the test picture.
    mov ah, 00h
    int 16h

exit_program:
    ; Restore text mode, then return to DOS.
    mov ax, TEXT_MODE
    int 10h
    mov ax, 4C00h
    int 21h

; PutPixel
; Purpose: Write one pixel if its coordinates are inside the screen.
; Inputs: Stack words x, y, colour. ES points to the drawing segment.
; Outputs: One byte written for valid coordinates.
; Registers changed: None on return. Flags may change.
PutPixel:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push di

    mov bx, [bp+4]
    cmp bx, SCREEN_WIDTH
    jae pixel_done

    mov ax, [bp+6]
    cmp ax, SCREEN_HEIGHT
    jae pixel_done

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

pixel_done:
    pop di
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

; FillRect
; Purpose: Fill a rectangle that fits entirely inside the screen.
; Inputs: Stack words x, y, width, height, colour.
;         ES points to the drawing segment.
; Outputs: Rectangle drawn. Empty or out-of-bounds rectangles are skipped.
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

    ; Check x and width. The right edge may reach column 319.
    mov bx, [bp+4]
    cmp bx, SCREEN_WIDTH
    jae rectangle_done
    mov ax, SCREEN_WIDTH
    sub ax, bx
    mov cx, [bp+8]
    jcxz rectangle_done
    cmp cx, ax
    ja rectangle_done

    ; Check y and height. The bottom edge may reach row 199.
    mov bx, [bp+6]
    cmp bx, SCREEN_HEIGHT
    jae rectangle_done
    mov ax, SCREEN_HEIGHT
    sub ax, bx
    mov dx, [bp+10]
    cmp dx, 0
    je rectangle_done
    cmp dx, ax
    ja rectangle_done

    ; Calculate the offset of the rectangle's first pixel.
    mov di, bx
    mov cl, 8
    shl di, cl
    mov cl, 6
    shl bx, cl
    add di, bx
    add di, [bp+4]

    ; After writing a row, skip to the same x on the next row.
    mov bx, SCREEN_WIDTH
    sub bx, [bp+8]
    mov ax, [bp+12]
    cld

fill_rectangle_row:
    mov cx, [bp+8]
    rep stosb
    dec dx
    jz rectangle_done
    add di, bx
    jmp fill_rectangle_row

rectangle_done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    popf
    pop bp
    ret 10