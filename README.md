# CHIP-8 AR
An augmented reality CHIP-8 emulator for iOS written in Swift.

## Architecture
The core CHIP-8 emulator functionality is implemented in [this Swift package](https://github.com/ryanggrey/Chip8EmulatorPackage) which this project uses as a dependency. 

Core CHIP-8 emulator functionality is not handled by this project. This project concerns itself with:
- How to select and load ROMs into the Chip-8 engine
- When to start/stop the Chip-8 engine.
- How to render the resulting Chip-8 emulator `pixels`.
- How to collect and send user input to the Chip-8 engine.
- AR functionality

