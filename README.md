# SpaceshipX

SpaceshipX is a small assembly-based game developed using MASM and WinDbg.  
In the game, the player controls a spaceship to shoot bullets and destroy incoming comets to protect Earth. Future updates will include new items, additional weapon types, and extra lives.

---

## Features

- Control the spaceship using the keyboard: arrow keys (W, S, A, D) to move, and Space to shoot.
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
- WinDbg (optional, only needed for debugging)

The Irvine32 library and WinDbg are provided in the windbg folder.

---

## Instructions

1. Clone the repository
2. Move the `SpaceshipX.asm` file into the `windbg` folder and navigate to it
3. Edit the default filepath (C:\WINdbgFolder\) in `make.bat` to point to your WinDbg installation directory
4. Run `make.bat` (it is normal if some files are not found)
5. Run the `SpaceshipX.exe` file

---

## Contributors

| Name            | GitHub Link                           |
|-----------------|---------------------------------------|
| Chao Chien Hung | https://github.com/ChaoChienHung      |
| Billy           | https://github.com/Billy152op         |
| Clark           | clarkwu0906@gmail.com                 |

## Acknowledgement

We would like to thank Microsoft WinDbg for providing a powerful debugging tool, and the Professor and TA of the National Central University Assembly Language and System Programming course for their excellent introduction and example files for running assembly programs.
