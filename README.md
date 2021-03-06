# mcp9808-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Microchip MCP9808 Temperature sensors

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz
* Read temperature in hundredths of a degree
* Set temperature scale to Celsius or Fahrenheit
* Power sensor on/off
* Interrupts: set low, high, critical thresholds, enable low, high, critical, or _only_ critical interrupts, set interrupts active low or active high, set comparator or interrupt output mode
* Supports alternate slave addresses

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81), FlexSpin (tested with 5.3.3-beta)
* P2/SPIN2: FlexSpin (tested with 5.3.3-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build

## TODO
- [x] Port to P2/SPIN2
- [x] Add support for changing sensor resolution
- [x] Add support for power on/off
- [x] Add support for interrupts
- [x] Add support for alternate slave addresses
