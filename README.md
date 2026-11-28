# Super Mario Engine

A 16-bit side-scrolling game written in 8086 assembly for the Computer Organization and Assembly Language (COAL) semester project at FAST-NUCES, Chiniot–Faisalabad Campus.

## Team — Group 17

| Name | Roll number | GitHub | Contributions |
|---|---|---|---|
| Malik Muhammad Muzammil | 25F-3081 | `muzammil-malik` | Camera and scrolling, keyboard fixes, enemies and shells, HUD, menus, and win/loss integration (Modules 6–7, 11, 13–15) |
| Zainab Naveed | 25F-3021 | `Zainab-Naveed` | Sprite drawing, frame buffering, timer, player physics, collisions, blocks, coins, and power-ups (Modules 4–5, 8–10, 12) |

## Build and run

Requires **NASM** and **DOSBox 0.74-3 or later**.

1. In Windows Command Prompt, open the repository folder and build:

   ```bat
   nasm -f bin mario.asm -o MARIO.COM
   ```

2. In DOSBox, mount the repository folder and run the game. Replace the example path with your local path.

   ```dos
   mount c "C:\path\to\repo"
   c:
   MARIO.COM
   ```

## Controls

| Key | Action |
|---|---|
| Up / Down | Move between Start and Exit on the title screen |
| Enter | Confirm the menu selection or return to the title from an end screen |
| Left / Right | Move Mario |
| Shift | Hold to run |
| Space | Jump. Hold for a higher jump. |
| P | Pause or resume |
| Esc | Return to the title from gameplay or pause. Press Esc on the title screen to exit. |

## How it works

- **Graphics and memory.** The game uses VGA Mode 13h at 320 × 200. It shrinks the DOS program memory block and allocates a separate 64,000-byte frame buffer with DOS interrupt `21h`. Each frame is drawn in that buffer and copied to video memory at segment `A000h` using `REP MOVSW`.
- **Input and timing.** A custom `INT 09h` keyboard handler tracks held keys. The `INT 1Ch` timer handler paces frames and supports the 300-second countdown. Both original handlers are restored before returning to DOS.
- **Level and gameplay.** The 60 × 12 tile map scrolls horizontally. Mario can collect coins and mushrooms, stomp enemies, kick shells, and reach the flagpole. The HUD displays score, coins, world, remaining time, lives, and health.
- **Game states.** The title opens gameplay or exits. Playing can switch to Paused, Dying, or the Win Sequence. After death, Life Lost restarts the level if any lives remain. Otherwise, Game Over displays the final score. The Win Sequence leads to Level Complete with a time bonus. Enter returns to the title from either end screen.

## Deviations and limitations

- Either Shift key works for running. The project manual lists Left Shift.
- The win sequence uses the manual's allowed option of hiding Mario briefly after the flag slide.
- The game contains one level. No debug keys are exposed during normal play.

## Development

The project was developed with AI assistance. The team is responsible for reviewing the code, testing the final build, documenting contributions, and explaining the implementation during the viva.
