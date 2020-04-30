Cursor History mod for Factorio
==============================

Cursor History is a mod for Factorio which keeps a history of the last few items (currently 6) that the player has held in their hand, and makes it easy to retrieve those items via a keystroke (defaults to shift-Q) or clicking on an icon.

The mod keeps the items in a list, shown onscreen upper left.   Shift-Q moves through the list from most recent to least.   Ctl-Shift-Q moves in the opposite direction.  (These key setting may be changed by the user via the Factorio menu.)   The player can also click directly on the icons in the list to retrieve them.

When a player picks up an item, it is added to the list.  If the item was already in the list, it is moved to the most recent position.

The mod ignores certain items currently:   blueprint, blueprint-book, deconstruction-planner, and the max-rate-calculator selection tool (from another of my mods, Max Rate Calculator).

Future plans/possibilities
In future releases, I've been thinking about adding a mod settings capability to allow players to configure the number of items, manage the list of items to ignore (e.g. maybe you don't want it to keep track of raw-wood), to hide the gui part altogether, or to put the gui on the left, rather than the top.   I'd also like to properly handle blueprints, but I need to learn more to handle that properly!



# Changelog
### 0.0.1
* Initial release - basic version

### 0.0.2
* Update for corrupted icon

### 0.1.3
* Changes for 0.16

### 0.2.6
* Fix for 0.17.35 player_main -> character_main 

### 0.2.7
* Support 0.18

### 0.2.8  Fixed issue with Factorio 0.18.22 and hotkeys prototypes