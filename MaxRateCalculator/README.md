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