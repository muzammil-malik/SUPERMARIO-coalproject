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
    ; Open graphics mode and set up the data and video segments.
    mov ax, GRAPHICS_MODE
    int 10h
    push cs
    pop ds
    mov ax, VIDEO_SEGMENT
    mov es, ax

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

    ; PutPixel(10, 2, COLOR_WHITE)
    mov ax, COLOR_WHITE
    push ax
    mov ax, 2
    push ax
    mov ax, 10
    push ax
    call PutPixel

    ; Keep the test screen visible until a key is pressed.
    mov ah, 00h
    int 16h

exit_program:
    ; Restore text mode and return to DOS.
    mov ax, TEXT_MODE
    int 10h
    mov ax, 4C00h
    int 21h

; GetPixelOffset
; Purpose: Convert a valid screen coordinate to a VGA byte offset.
; Inputs: Stack words x and y.
; Outputs: AX = y * 320 + x.
; Registers changed: AX. Flags may change.
GetPixelOffset:
    push bp
    mov bp, sp
    push cx
    push dx

    ; 320 = 256 + 64.
    mov ax, [bp+6]
    mov dx, ax
    mov cl, 8
    shl ax, cl
    mov cl, 6
    shl dx, cl
    add ax, dx
    add ax, [bp+4]

    pop dx
    pop cx
    pop bp
    ret 4

; PutPixel
; Purpose: Write one pixel if its coordinates are inside the screen.
; Inputs: Stack words x, y, colour. ES is the drawing segment.
; Outputs: Writes one byte for valid coordinates.
; Registers changed: None on return. Flags may change.
PutPixel:
    push bp
    mov bp, sp
    push ax
    push di

    ; Reject x >= 320 and y >= 200.
    cmp word [bp+4], SCREEN_WIDTH
    jae pixel_done
    cmp word [bp+6], SCREEN_HEIGHT
    jae pixel_done

    ; GetPixelOffset(x, y)
    push word [bp+6]
    push word [bp+4]
    call GetPixelOffset
    mov di, ax
    mov ax, [bp+8]
    mov [es:di], al

pixel_done:
    pop di
    pop ax
    pop bp
    ret 6

; FillRect
; Purpose: Fill a rectangle that fits entirely inside the screen.
; Inputs: Stack words x, y, width, height, colour.
;         ES is the drawing segment.
; Outputs: Draws valid rectangles. Skips empty or out-of-bounds ones.
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

    ; Check x and the available width.
    mov bx, [bp+4]
    cmp bx, SCREEN_WIDTH
    jae rectangle_done
    mov ax, SCREEN_WIDTH
    sub ax, bx
    mov cx, [bp+8]
    jcxz rectangle_done
    cmp cx, ax
    ja rectangle_done

    ; Check y and the available height.
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

    ; GetPixelOffset(x, y)
    push word [bp+6]
    push word [bp+4]
    call GetPixelOffset
    mov di, ax

    ; After each row, skip to the next row's starting x.
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