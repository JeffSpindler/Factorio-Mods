Max Rate Calculator mod for Factorio
==============================


Provides a selection tool (default hotkey is ctrl-n), which when used to select a set of machines, calculates the maximum
possible rate of items consumed and produced by those machines.   These rates are displayed in a GUI window on the left
side of the Factorio window, in items per second, and items per minute.

# Changelog
### 0.0.1
* Initial release - only handles assemblers, chemical plants, refineries, centrifuges.

### 0.0.2
* Fixed default hotkey (CONTROL-N not CTRL-N).  Fixed en locale strings

### 0.0.3
* Fixed calculation bug when mixed set of modules in an assembler

### 0.1.4
* Calculates production/consumption for furnaces (but not fuel)
* Beacon effectivity no longer hardcoded

### 1.0.5
* Dropdown list lets user select rate units
* Rate per machine and surplus/deficit number of machines calculated

### 1.0.6
* Fix red belt calculation
* Add warning if assemblers/furnaces have no recipe

### 1.1.7
* Adds calculations in terms of inserters
* Tooltip on item icons shows num of machines using/producing the item in the selection

### 1.2.8
* Vertical scroll bars if too many items
* Don't show rates of fluids on belts, in inserters
* Added rate calculations for train wagons per minute and per hour
* Items are sorted alphabetically

### 1.2.9
* Use LuaEntityPrototype::fluid_capacity for fluid-wagon (surfaced in 0.15.32) rather than hardcoded 75000
* Use beacon.prototype.distribution_effectivity rather than hardcoded 0.5 (also from 0.15.32)

### 1.2.10
* Fixed to work with modded versions of beacons, such as Creative Mode's Super Beacon.
* Speed cost won't go lower than 20%

### 1.2.11
* Fixed bug with new games getting fatal error when hotkey pressed for first time

### 2.0.12
* Added in-game four function calculator, accessed via hotkey or toggle button on Max Rate Calculator window
* Values in MRC window, when clicked on, appear in the calculator


### 2.0.13
* Added missing locale string for calc hotkey


### 2.0.14
* Fixed bug with text entry in other mods crashing

### 2.0.15
* Fixed bug recipes (like uranium processing) that have % chance causing crash
* Added fix for possible uninitalized variable (marc_selected_units) crash reported in mod portal.  Could not reproduce this, but added defensive code.

### 2.0.18
Fix for crash on player death when using selection tool
Calculates rates for mining drills and pumpjacks (however, not sulfuric acid consumption for uranium mining)

### 3.0.20 0.17 support.  Removed mining calculations.  Needs general rate re-testing

### 3.1.21 Max Rate Calculator selection tool and 4 function calculator available on the quickbar

### 3.1.22 Fix probablistic calculations (uranium processing)

### 3.1.23 Fix old-style probablistic calculations (Bob's Greenhouse)

### 3.1.24 Use only-in-cursor flag to keep selection tool out of inventory.  Attempt at thumbnail.

### 3.2.25 Window is moveable

### 3.2.27 Use most recent recipe if furnace has no current recipe

### 3.2.28 Fix no recipe crash

### 3.2.29 Save window location

### 3.2.31 Factorio 0.18 support

### 3.2.32 Use catalyst_amount for prod calcs.  Fixes issue with kovarex recipe

### 3.2.33 Fixed issue with small beacons not seen next to large assemblers (Krastorio 2)
           Honor allowed_effects consumption flag or not
           Don't allow productivity to drop below zero

### 3.2.34 Fixed issue with Factorio 0.18.22 and hotkeys prototypes

### 3.3.36 Belts and their speeds pulled from game tables rather than being hardcoded, now supports mods with faster belts

### 3.4.37 Mining and pumpjack calculations

### 3.4.38 Defensive coding against global debug not a lua table

### 3.4.39 Mining/pumpjack calculation improvements