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

test_sprite:
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,15,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,15,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,15,0,0,0
    db 0,0,15,15,15,15,15,15,15,15,15,15,15,15,0,0
    db 0,0,15,15,15,15,15,15,15,15,15,15,15,15,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,15,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,15,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,15,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

start:
    mov ax, 0013h
    int 10h
    push cs
    pop ds
    mov ax, 0A000h
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
    mov ax, 0
    push ax
    mov ax, 16
    push ax
    mov ax, test_sprite
    push ax
    mov ax, 48
    push ax
    mov ax, 32
    push ax
    call DrawSprite
    mov ax, 1
    push ax
    mov ax, 16
    push ax
    mov ax, test_sprite
    push ax
    mov ax, 48
    push ax
    mov ax, 64
    push ax
    call DrawSprite
    mov ax, 0
    push ax
    mov ax, 16
    push ax
    mov ax, test_sprite
    push ax
    mov ax, 64
    push ax
    mov ax, -8
    push ax
    call DrawSprite
    mov ax, 0
    push ax
    mov ax, 16
    push ax
    mov ax, test_sprite
    push ax
    mov ax, 64
    push ax
    mov ax, 312
    push ax
    call DrawSprite
    mov ax, 0
    push ax
    mov ax, 16
    push ax
    mov ax, test_sprite
    push ax
    mov ax, -7
    push ax
    mov ax, 120
    push ax
    call DrawSprite
    mov ax, 0
    push ax
    mov ax, 16
    push ax
    mov ax, test_sprite
    push ax
    mov ax, 193
    push ax
    mov ax, 120
    push ax
    call DrawSprite

read_preview_key:
    call ReadKey
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
    call ReadKey
    cmp ah, 01h
    je exit_program
    jmp preview_map

exit_program:
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
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
    mov di, 16
    cmp word [bp+10], di
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
