# MechaniMiner
https://www.roblox.com/games/119921565599201/MechaniMiner

A Roblox Game about building a mining vehicle, collecting resources, selling them, and obtaining more blocks to upgrade the vehicle through buying or crafting.

<img width="569" height="352" alt="Screenshot 2026-02-19 203418" src="https://github.com/user-attachments/assets/c3ad3d05-78da-4433-98aa-43af42be15c2" />

## NOTE: 
For these hours, I only added some features and remade some outdated parts of the game. The rest of the game doesn't really work yet.
### The things I added are: 
- Models for blocks: Furnace, Internal Combustion Engine, Steam Engine, Suspension, Shafts
- Terrain modeling: Mountains in back
- Creation Saving system: Compiles and stores blocks, block grids and positional data
- New Building System: Allows non-static blocks to be placed on different grids, handling block dimensions, rotations, bounds, and mechanical blocks containing multiple grids
- Internal Creation Tracking: Dynamically stores data about grids, connected blocks + positions/orientations relative to grids, and root parts as blocks are placed and deleted while handling grid creation and splitting. This information is used for determining how to attach blocks that get placed and when to split grids.
## Instructions
- Press the build button or delete button to enable build mode or delete mode
- In build mode, click a block from the menu to start building with. Click different tabs at the top of the menu to switch between different types of blocks
- You can build a car with blocks, wheels, suspension, and a seat. Note that there is no vehicle controller, so the car cannot be driven.
- Your creation will save when you leave and load in when you join the game. The creation loading system is accurate. However, the function that initially welds all the blocks together when you join is outdated and may mess things up.
