# MechaniMiner
https://www.roblox.com/games/119921565599201/MechaniMiner

A Roblox Game about building a mining vehicle, collecting resources, selling them, and buying more blocks to upgrade the vehicle.

<img width="1472" height="641" alt="Screenshot 2026-03-18 160207" src="https://github.com/user-attachments/assets/4514de5f-3a2b-4ef2-83b3-57cc098e6d18" />

## NOTE: 
The code files are just the ones I wrote or modified. They don't work outside of the game.
If you need to check the assets, import them into Roblox Studio by right-clicking workspace in explorer -> insert -> import Roblox model

## Newest Changes:
- Cleaned up a lot of code and fixed small bugs
- Fixed Block Rotation Saving: Previous method rounded Euler angles, resulting in wierd behavior. Changed to a system that calculated the facing axis and number of rotations around that axis.
- Saving Improvements: Added additional checks to prevent data loss and fast functions for incrementing money or block amounts
- Item Saving: Added functions for saving and loading and encoding item IDs, positional data, and extra values needing to be stored (like boxed blocks)
- New Creation Loading System: Remade the loading system to attach blocks more reliably and use the new saving data to prevent different vehicles from getting attached together
- Mine Generation: Remade mine generation to only load blocks around where they are mined while accounting for transparent blocks and changed ore rarity formulas
- Ore Refining: Added functionality to the furnace block to turn raw ores into ingots
- Money and Selling: Fixed the old money saving system and added a sell zone on the side of the shop building for selling sellable items
- Boxed Blocks and Buying: Added a box item that can be opened to add blocks to the inventory. Made the shop calculate total prices, deduct money, and set ownership of items that get bought.
- Conveyor Blocks: Implemented old conveyor models and made them work by applying forces to touching items and keeping track of them
- DRILL: Added a drill block that constantly does damage to stone and ores within a radius based on distance from center. (click the lever on top to turn on)
- New Wheels: Improved the model of the wooden wheel and put its wheel on a loose joint. Added a crude wheel (very rough surface and loose joint) and an iron wheel (rough surface, powered, not steerable)
- Steering Joint: Added a block that rotates the other end when steered

### Previous Changes: 
- Models for blocks: Furnace, Internal Combustion Engine, Steam Engine, Suspension, Shafts
- Terrain modeling: Mountains in back
- Creation Saving system: Compiles and stores blocks, block grids and positional data
- New Building System: Allows non-static blocks to be placed on different grids, handling block dimensions, rotations, bounds, and mechanical blocks containing multiple grids
- Internal Creation Tracking: Dynamically stores data about grids, connected blocks + positions/orientations relative to grids, and root parts as blocks are placed and deleted while handling grid creation and splitting. This information is used for determining how to attach blocks that get placed and when to split grids.

## Gameplay Instructions
- Press the build button (Q) or delete button (E) to enable build mode or delete mode
- In build mode, click a block from the menu to start building with. Click the tabs buttons at the top of the menu to switch between different types of blocks
- Build a mining truck with blocks, wheels, suspension, drills, and a seat. Also put a storage bin on the back
- Click the levers of the drills and drive to the mine
- Mine some metal ores with drills or a pickaxe
- Put the ores into the bin and drive back to your plot
- Place a furnace and drop the ores onto the input conveyor
- Take the ores into the sell zone next to the shop and click the sell button
- Items and blocks can be bought in the shop
