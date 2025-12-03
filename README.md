# SpaceshipX

SpaceshipX is a small assembly-based game developed using MASM and WinDbg.  
In the game, the player controls a spaceship to shoot bullets and destroy incoming comets to protect Earth. Future updates will include new items, additional weapon types, and extra lives.

---

## Features

- Control the spaceship using the keyboard: arrow keys (Up, Down, Left, Right) to move, and Space to shoot.
- Shoot bullets to destroy incoming comets
- Protect the Earth from destruction
- Planned enhancements: multiple weapon types, collectibles, and advanced enemy patterns

---

## Project Structure

```bash
SpaceshipX/
├── windbg                  # Folder containing make.bat to compile and run the program
├── SpaceshipX.asm          # Main MASM assembly source file
└── README.md               # Project overview and usage instructions
```

---

## Requirements

- Windows OS
- MASM (ml.exe)
- Irvine32 library (Irvine32.inc, Irvine32.lib, Irvine32.dll)
- WinDbg (for debugging and running the game)

The Irvine32 library and WinDbg are provided in the windbg folder.

---

## Instructions

1. Clone the repository
2. Move the `SpaceshipX.asm` file into the `windbg` folder and navigate to it
3. Run `make.bat` (it is normal if some files are not found)
4. Run the `SpaceshipX.exe` file
