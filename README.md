# Super Mario Engine

A 16-bit side-scrolling platformer in development for the Computer Organization and Assembly Language (COAL) course at FAST-NUCES, Chiniot–Faisalabad Campus. It is written in 8086 assembly and runs in DOSBox.

## Current progress

Module 1 sets up the program in `mario.asm`. It builds into `MARIO.COM`, sets text mode, and returns to the DOS prompt. Graphics, movement, and collisions are planned for later modules.

## Build and run

These DOSBox commands assume `NASM.EXE` is in `C:\nasm` and the repository is cloned to `C:\nasm\mariogit`. Adjust the paths if your setup is different.

```dos
mount x C:\nasm
x:
nasm.exe -f bin mariogit\mario.asm -o mariogit\MARIO.COM
cd mariogit
MARIO.COM
```
