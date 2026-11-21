org 100h

jmp start

; Named value used by the video-mode service.
TEXT_MODE equ 0003h

; Program entry
; Purpose: initialise DS, select text mode, and exit to DOS.
; Inputs: DOS .COM startup environment.
; Outputs: returns control to DOS with exit code 0.
; Registers changed: AX, DS, and registers affected by BIOS/DOS.
start:
    ; Point DS at the segment containing this program.
    push cs
    pop ds

    ; Select the standard 80-column colour text mode.
    mov ax, TEXT_MODE
    int 10h

    ; Terminate the program successfully.
    mov ax, 4C00h
    int 21h