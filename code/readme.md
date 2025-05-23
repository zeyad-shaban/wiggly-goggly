# MAZEN I SWEAR GIT EXISTS FOR A REASON
# WHY THE HELL DO YOU HAVE A FOLDER FOR PROJECT BACKUPS

## About
8051 Assembly project using [ASEM-51](https://plit.de/asem-51/) assembler running in DOSBox.

## Setup & Running
1. Open DOSBox and run the following commands:
```bash
# For Mazen
mount C E:\Mazen_Belal\projects\MicroProcessors\wiggly-goggly\code

# For Zeyad
mount C E:\workspace\wiggly_goggly\code

# Navigate and compile
C:
cd asem5113
asem.exe ..\main.asm ..\main.hex
```

## Project Documentation

### Distance Calculation
- Formula: Distance (cm) = echo (microSec) / 58
- Or: echo = distance * 58

### LED Indicators
| Color  | Distance Range |
|--------|---------------|
| Red    | < 10 cm      |
| Yellow | 10-20 cm     |
| Green  | > 20 cm      |

### Timing Details
Regarding WAIT_FALL_16 timing:
- Each loop takes 3 µs
- Target range: 200 cm
- Calculation: 3 * x / 58 = 200
- Result: x = 200 * 58 / 3 = 3866

## Development Notes

### File Imports
To make files importable:
1. Create a `.inc` file for the code you want to include
2. In the `.inc` files, expose functions using:
   ```assembly
   PUBLIC function_name
   ```
3. Import in main.asm using:
   ```assembly
   $INCLUDE (delay.inc)
   ```
