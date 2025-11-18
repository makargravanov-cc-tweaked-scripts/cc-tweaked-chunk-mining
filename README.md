This script performs automatic extraction of resources in chunks, controlling multiple turtles from a central hub, with automatic unloading and refueling at the coordinates you specify during configuration. 
The script supports parallel operation of multiple turtles in a chunk. The script consists of two parts: one for the hub and one for the turtles. 
The installer automatically selects which files to install on the computer, depending on whether it is a turtle. 
The script ensures data consistency and synchronization, ensuring that all turtles unload their loot and refuel, if necessary, by joining a queue. 
Turtles do not collide with each other, as they are all at different heights, and the upper Y of mining must be specified lower than the base height. 
When moving (excluding mining), either vertical movement or horizontal movement is possible at the same time, and they never intersect.

Use with Create mod for the best experience. 
As fuel, we recommend using biomass pallets from Create, as one pallet gives 2880 fuel, and although they are somewhat harder to produce (need a large farm and factory) than lava buckets (which give 1000 fuel and only require a source, conveyor, and bucket-filling unit), they can be produced in large quantities and have very simple logistics for the huge amount of fuel they provide. 
It's better to use it with gold computers and gold turtles. 
Place the monitor next to the hub computer.
The optimal initial amount of fuel on the turtle is between 25K and 30K, to minimize delays during refueling. 
It's better to have a 4*4 monitor, and it should be a gold monitor, as we use colors in the output. 
The number of unloading/refueling points is generally higher, the better. However, for 44 turtles, for example, it should be at least 8 unloading points to avoid unnecessary delays.
There can be one filling point, if you like. We understand that it is quite difficult to maintain an even amount of fuel between them, so this can be done for stability. 

As we mentioned, we suggest using the Create mod for shipping/receiving items. 

The digging area is currently supported up to 25 chunks, but we usually leave a corridor to the edge of the area to accommodate the utilities. 
Additionally, excluding the central chunk where the hub and chunkloader are located, we have 22 chunks available for digging. Using 88 turtles (4 turtles per chunk), we dug this area in about 4-6 hours. 

IMPORTANT!
The turtles always drop deepslate and flint to avoid cluttering their inventory, as these materials are almost useless in Create, specifically for us! 
If you disagree with this, you can fork the repository and modify the list of dropped materials in `drone/services/inventory_service.lua` in the `itemsToDrop` variable. 
Just remember to change the base link in the installer, otherwise you will download our version!

The hub is controlled through the hub terminal commands. You can find a list of these commands in hub/console.lua

The command `chunks-show` displays the chunk grid on the monitor that you place next to the hub computer. Adjust the scale using the mouse wheel. 
The chunk grid is displayed with orientation, and you will see 4 letters (x z, X, Z) at the edges, where the capital letters represent the + coordinate and the lowercase letters represent the - coordinate. 
So it's better to immediately turn the monitor according to the directions, so as not to break your head.

Please note that we currently have logging enabled for what happens on the hub, which is written to a file on the hub's computer.
If you encounter any errors, please attach the log file and, if necessary, screenshots! If you have any questions, please create an Issue.

As a reminder, you can open the display of chunk boundaries, as shown in the last two screenshots, by pressing F3+G/

Install this from our latest version:

```
wget https://raw.githubusercontent.com/makargravanov-cc-tweaked-scripts/cc-tweaked-chunk-mining/refs/heads/master/startup.lua
```

<img width="1920" height="1080" alt="2025-11-13_20 56 08" src="https://github.com/user-attachments/assets/4545f3cc-7f5f-41bb-a4b6-75c5b2ee0298" />

<img width="1920" height="1080" alt="2025-11-16_18 43 03" src="https://github.com/user-attachments/assets/8065470c-acf9-41f8-9e4d-998e7dbc110c" />

<img width="1920" height="1080" alt="2025-11-16_18 44 02" src="https://github.com/user-attachments/assets/f1810d54-0f41-4127-90c8-0309f4e479ab" />

<img width="1920" height="1080" alt="2025-11-16_14 26 47" src="https://github.com/user-attachments/assets/3244f4e7-0036-4d33-b3ce-c48af2f3c15f" />

<img width="1280" height="720" alt="изображение" src="https://github.com/user-attachments/assets/992409ac-7853-48ed-be9e-1ea4dfe2d149" />

<img width="1280" height="720" alt="изображение" src="https://github.com/user-attachments/assets/5c940513-0007-46a3-ace0-566def5f1be4" />
