INSTALLATION
------------
Setting up a server:  https://docs.fivem.net/docs/server-manual/setting-up-a-server/

Create a **`races/`** folder under your server **`resources/`** folder.  Place **`fxmanifest.lua`**, **`races_client.lua`**, **`races_server.lua`**, **`port.lua`**, **`raceData.json`**, **`vehicles.txt`** and **`random.txt`** in the **`resources/races/`** folder.  Create an **`html/`** folder under your server **`resources/races/`** folder.  Place **`index.css`**, **`index.html`**, **`index.js`** and **`reset.css`** in the **`resources/races/html/`** folder.  Add **`start races`** to your **`server.cfg`** file.

CLIENT COMMANDS
---------------
Required arguments are in square brackets.  Optional arguments are in parentheses.\
**`/races`** - display list of available **`/races`** commands\
**`/races request [role]`** - request permission to have [role] = {edit, register, spawn} role\
**`/races edit`** - toggle editing race waypoints\
**`/races clear`** - clear race waypoints\
**`/races reverse`** - reverse order of race waypoints\
**`/races load [name]`** - load race waypoints saved as [name]\
**`/races save [name]`** - save new race waypoints as [name]\
**`/races overwrite [name]`** - overwrite existing race waypoints saved as [name]\
**`/races delete [name]`** - delete race waypoints saved as [name]\
**`/races blt [name]`** - list 10 best lap times of race saved as [name]\
**`/races list`** - list saved races\
**`/races loadPublic [name]`** - load public race waypoints saved as [name]\
**`/races savePublic [name]`** - save new public race waypoints as [name]\
**`/races overwritePublic [name]`** - overwrite existing public race waypoints saved as [name]\
**`/races deletePublic [name]`** - delete public race waypoints saved as [name]\
**`/races bltPublic [name]`** - list 10 best lap times of public race saved as [name]\
**`/races listPublic`** - list public saved races

For the following **`/races register`** commands, (buy-in) defaults to 500, (laps) defaults to 1 lap and (DNF timeout) defaults to 120 seconds\
**`/races register (buy-in) (laps) (DNF timeout)`** - register your race with no vehicle restrictions\
**`/races register (buy-in) (laps) (DNF timeout) rest [vehicle]`** - register your race restricted to [vehicle]\
**`/races register (buy-in) (laps) (DNF timeout) class [class] (filename)`** - register your race restricted to vehicles of type [class] in (filename) file\
**`/races register (buy-in) (laps) (DNF timeout) rand (filename) (class) (vehicle)`** - register your race changing vehicles randomly every lap; (filename) defaults to **`random.txt`**; (class) defaults to any; (vehicle) defaults to any

**`/races unregister`** - unregister your race\
**`/races start (delay)`** - start your registered race; (delay) defaults to 30 seconds\
**`/races leave`** - leave a race that you joined\
**`/races rivals`** - list competitors in a race that you joined\
**`/races respawn`** - respawn at last waypoint\
**`/races results`** - view latest race results\
**`/races spawn (name)`** - spawn a vehicle; (name) defaults to 'adder'\
**`/races lvehicles (class)`** - list available vehicles of type (class); otherwise list all available vehicles if (class) is not specified\
**`/races speedo (unit)`** - change unit of speed measurement to (unit) = {imp, met}; otherwise toggle display of speedometer if (unit) is not specified\
**`/races funds`** - view available funds\
**`/races panel (panel)`** - display (panel) = {edit, register} panel; otherwise display main panel if (panel) is not specified

**IF YOU DO NOT WANT TO TYPE CHAT COMMANDS, YOU CAN BRING UP A CLICKABLE INTERFACE BY TYPING `/races panel`, `/races panel edit` or `/races panel register`.**

SERVER COMMANDS
---------------
**`races`** - display list of available **`races`** commands\
**`races export [name]`** - export public race saved as [name] without best lap times to file named **`[name].json`**\
**`races import [name]`** - import race file named **`[name].json`** into public races without best lap times\
**`races exportwblt [name]`** - export public race saved as [name] with best lap times to file named **`[name].json`**\
**`races importwblt [name]`** - import race file named **`[name].json`** into public races with best lap times\
**`races listReqs`** - list requests to edit tracks, register races and spawn vehicles\
**`races approve [playerID]`** - approve request of [playerID] to edit tracks, register races or spawn vehicles\
**`races deny [playerID]`** - deny request of [playerID] to edit tracks, register races or spawn vehicles\
**`races listRoles`** - list approved players' roles\
**`races removeRoles [name]`** - remove player [name]'s roles

**IF YOU WANT TO PRESERVE RACES FROM A PREVIOUS VERSION OF THESE SCRIPTS, YOU SHOULD UPDATE `raceData.json` AND ANY EXPORTED RACES BY EXECUTING THE FOLLOWING COMMANDS BEFORE CLIENTS CONNECT TO THE SERVER TO USE THE NEW RACE DATA FORMAT WHICH INCLUDES WAYPOINT RADIUS SIZES.**

**`races updateRaceData`** - update **`raceData.json`** to new format\
**`races updateRace [name]`** - update exported race **`[name].json`** to new format

**IF YOU WISH TO LIMIT WHO CAN EDIT TRACKS, REGISTER RACES AND SPAWN VEHICLES, YOU WILL NEED TO CHANGE THE LINE `requirePermission = false` IN `races_server.lua` TO `requirePermission = true`.**

SAMPLE RACES
------------
If permission to register races is not required, the sample races will be available to you.  There are six sample races:  '00', '01', '02', '03', '04' and '05' saved in the public races list.  You can load sample race '00' by typing **`/races loadPublic 00`**.  To race in the loaded race, you need to register by typing **`/races register`**.  Go to the registration waypoint of the race indicated by a purple circled star blip on the waypoint map and a purple cylinder checkpoint in the world.  When prompted to join, type 'E' or press right DPAD to join.  Wait for other people to join if you want, then type **`/races start`**.

There are backups of the sample races in the **`sampleraces/`** folder with the extension '.json'.  Race '00' is backed up as **`sampleraces/00.json`**.  If any of the sample races were deleted from the public list of races, you can restore them.  Copy the deleted race from the **`sampleraces/`** folder to the **`resources/races/`** folder.  In the server console, type **`races import 00`** to import race '00' back into the public races list.

QUICK GUIDE FOR RACE CREATORS
-----------------------------
If permission to edit tracks and register races is not required, all the following **`/races`** commands are permitted.  Type **`/races edit`** until you see the message 'Editing started'.  Add at least 2 waypoints on the waypoint map or in the world by pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a DualShock controller.  Type **`/races edit`** again until you see the message 'Editing stopped'.  Save the race if you want by typing **`/races save myrace`**.  Register your race by typing **`/races register`**.  At the starting waypoint of the race, a purple circled star blip will appear on the waypoint map and a purple cylinder checkpoint will appear in the world.  This is the registration waypoint which all players will see.  Players who want to join, maybe including yourself, need to have enough funds to pay for the buy-in and move towards the registration waypoint until prompted to join.  Once prompted to join, type 'E' or press right DPAD to join.  Once other people have joined, you can start the race by typing **`/races start`**.

QUICK GUIDE FOR RACING
----------------------
There are seven possible types of race you can join:  1. Any vehicle can be used, 2. Restricted to a specific vehicle, 3. Restricted to a specific vehicle class, 4. Vehicles change randomly every lap, 5. Vehicles change randomly every lap and racers start in a specified vehicle, 6. Vehicles change randomly every lap to one in a specific class, 7. Vehicles change randomly every lap to one in a specific class and racers start in a specified vehicle.

Look for purple circled star blips on the waypoint map.  There will be corresponding purple cylinder checkpoints in the world.  The label for the blip in the waypoint map will indicate the player who registered the race, the buy-in amount and the type of race.

If the race is restricted to a specific vehicle, the label will include **'using [vehicle]'** where [vehicle] is the name of the restricted vehicle.  You must be in that vehicle when prompted to join the race.  You can spawn the restricted vehicle by typing **`/races spawn [vehicle]`** where [vehicle] is the restricted vehicle.  For example, if the label shows **using 'adder'**, you can spawn the vehicle by typing **`/races spawn adder`**.

If the race is restricted to a specific vehicle class, the label will include **'using [class] vehicle class'** where [class] is the vehicle class.  The class number will be in parentheses.  You must be in a vehicle of that class when prompted to join the race.  If the class is 22 (Custom), you can view which vehicles are allowed in the race by getting out of any vehicle you are in, walking into the registration point on foot and trying to join the race.  The chat window will list which vehicles you can use in the class 22 (Custom) race.  If the class is not 22 (Custom), you can list vehicles of the class by typing **`/races lvehicles [class]`** where [class] is the vehicle class number.

If the race changes vehicles randomly every lap, the label will include **'using random vehicles'**.  If a vehicle is specified after the **'using random vehicles'** message, racers will be placed in the specified vehicle when the race starts.

If the race changes vehicles randomly every lap to one of a specific class, the label will include **'using random [class] vehicle class'** where [class] is the vehicle class.  The class number will be in parentheses.  If a vehicle is specified after the **'using random [class] vehicle class'** message, racers will be placed in the specified vehicle when the race starts.

To join a race, you must have enough funds to pay for the buy-in amount.  You can check how much funds you have by typing **`/races funds`**.

Move towards the registration waypoint until you are prompted to join.  Type 'E' or press right DPAD to join.  The player who registered the race will be the one who starts the race.  Once they start the race, your vehicle will be frozen until the start delay has expired and the race has officially begun.  Follow the checkpoints until the finish.  The results of the race will be broadcast to all racers who joined.  Prize money will be distributed to all finishers.  If you want to see the results again, type **`/races results`**.

CLIENT COMMAND DETAILS
----------------------
Type **`/races`** to see the list of available **`/races`** commands.  If you cannot see all the commands, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

By default, permission is not required to use any of the commands.  If permission is required, there are 3 types of permissions that can be given: edit tracks, register races and spawn vehicles.

If permission is required to edit tracks, the following commands will be restricted to players who have permission:

**`/races edit`**\
**`/races reverse`**\
**`/races load [name]`**\
**`/races save [name]`**\
**`/races overwrite [name]`**\
**`/races delete [name]`**\
**`/races loadPublic [name]`**\
**`/races savePublic [name]`**\
**`/races overwritePublic [name]`**\
**`/races deletePublic [name]`**

If permission is required to register races, the following commands will be restricted to players who have permission:

**`/races register (buy-in) (laps) (DNF timeout)`**\
**`/races register (buy-in) (laps) (DNF timeout) rest [vehicle]`**\
**`/races register (buy-in) (laps) (DNF timeout) class [class] (filename)`**\
**`/races register (buy-in) (laps) (DNF timeout) rand (filename) (class) (vehicle)`**\
**`/races unregister`**\
**`/races start (delay)`**

If permission is required to spawn vehicles, the following command will be restricted to players who have permission:

**`/races spawn (name)`**

If permission is required to edit tracks, register races and spawn vehicles, players who wish to do these tasks will need to request permission.  Type **`/races request edit`** to request permission to edit tracks.  Type **`/races request register`** to request permission to register races.  Type **`/races request spawn`** to request permission to spawn vehicles.  The server administrator will then approve or deny the request and the player will be notified.

Type **`/races edit`** until you see the message 'Editing started' to start editing waypoints.  Once you are finished, type **`/races edit`** until you see the message 'Editing stopped' to stop editing.  You cannot edit waypoints if you are joined to a race.  Leave the race or finish it first.

There are four types of race waypoints and one type of registration waypoint.  Each race waypoint will have a corresponding blip on the waypoint map and, when editing, a corresponding checkpoint in the world.  A combined start/finish waypoint is a yellow checkered flag blip/checkpoint.  A start waypoint is a green checkered flag blip/checkpoint.  A finish waypoint is a white checkered flag blip/checkpoint.  A waypoint that is not a start and/or finish waypoint is a blue numbered blip/checkpoint.  A registration waypoint is a purple blip/checkpoint.  When you stop editing, all the checkpoints in the world, except for registration checkpoints, will disappear, but all the blips on the waypoint map will remain.

Clicking a point on the waypoint map is done by moving the point you want to click on the map under the crosshairs and pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a DualShock controller.  'Clicking' a point in the world is done by moving to the point you want to 'click' and pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a DualShock controller.

Selecting a waypoint on the waypoint map is done by clicking on an existing blip.  This will turn the blip red.  The corresponding checkpoint in the world will also turn red.  Selecting a waypoint in the world is done by 'clicking' on an existing checkpoint.  You will be prompted to select the checkpoint once you are close enough.  This will turn the checkpoint red.  The corresponding blip on the waypoint map will also turn red.

Adding a waypoint is done by clicking on an empty spot on the waypoint map or by 'clicking' on an empty spot in the world.  Waypoints will always be added as the last waypoint.  You cannot make an added waypoint come before an existing waypoint.  The first waypoint you add will be a yellow checkered flag blip/checkpoint.  Subsequent added waypoints will be a white checkered flag blip/checkpoint.  Adding a waypoint will add a blip on the map and a corresponding checkpoint in the world.  Placement of a waypoint in the world is unrestricted, while placement of a waypoint on the waypoint map is restricted to paths or roads.

**NOTE: The position number of a racer while in a race will be the most accurate if waypoints are added at every bend or corner in the track.**

You can delete a waypoint by selecting it on the waypoint map or in the world, then pressing 'Spacebar' on a keyboard, 'X' button on an Xbox controller or 'Square' button on a DualShock controller.  Deleting a waypoint will delete the corresponding blip on the waypoint map and the corresponding checkpoint in the world.

You can move an existing waypoint by selecting it on the waypoint map or in the world, then clicking an empty spot on the waypoint map or in the world where you want to move it.  Moving a waypoint will move the corresponding blip on the waypoint map and the corresponding checkpoint in the world.

You can increase or decrease the radius of an existing waypoint in the world, but not in the waypoint map.  There are minimum and maximum radius limits to waypoints.  To increase the radius of the waypoint, select the waypoint in the world, then press 'Up Arrow' on a keyboard or up DPAD.  To decrease the radius of the waypoint, select the waypoint in the world, then press 'Down Arrow' on a keyboard or down DPAD.  When in a race, a player has passed a waypoint if they pass within the radius of the waypoint.  The waypoint will disappear and the next waypoint will appear.

For multi-lap races, the start and finish waypoint must be the same.  Select the finish waypoint first (white checkered flag), then select the start waypoint (green checkered flag).  The start/finish waypoint will become a yellow checkered flag.  The original finish waypoint will become a blue numbered waypoint.

You can separate the start/finish waypoint (yellow checkered flag) in one of two ways.  The first way is by adding a new waypoint.  The second way is by selecting the start/finish waypoint (yellow checkered flag) first, then selecting the highest numbered blue waypoint.

To reverse the order of waypoints, type **`/races reverse`**.  You can reverse waypoints if there are two or more waypoints.  You cannot reverse waypoints if you have joined a race. Leave the race or finish it first.

If you are editing waypoints from scratch or you have changed any waypoints of a saved race, the best lap times will not be saved if you register and start the race.  A change to a saved race means adding, deleting, moving, increasing/decreasing radii, combining start/finish, separating start/finish or reversing waypoints.  Changes can only be undone by reloading the saved race.  If you are starting from scratch or made any changes to the waypoints of a saved race, you must save or overwrite the race to allow best lap times to be saved.  **NOTE THAT OVERWRITING A RACE WILL DELETE ITS EXISTING BEST LAP TIMES.**

After you have set your waypoints, you can save them as a race.  Type **`/races save myrace`** to save the waypoints as 'myrace'.  'myrace' must not exist.  You cannot save unless there are two or more waypoints in the race.  The best lap times for this race will be empty.  If you want to overwrite an existing race named 'myrace', type **`/races overwrite myrace`**.  **OVERWRITING A RACE WILL DELETE THE BEST LAP TIMES OF THAT RACE.**

To list the races you have saved, type **`/races list`**.  If you cannot see all the race names, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

If you want to delete a saved race, type **`/races delete myrace`** to delete 'myrace'.

You can load saved waypoints by typing **`/races load myrace`** to load a race named 'myrace'.  This will clear any current waypoints and load the saved ones.  You cannot load saved waypoints if you have joined a race.  Leave the race or finish it first.

Type **`/races blt myrace`** to see the 10 best lap times recorded for 'myrace'.  Best lap times are recorded after a race has finished if it was loaded, saved or overwritten without changing any waypoints.  If you cannot see all the best lap times, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

**`save`**, **`overwrite`**, **`list`**, **`delete`**, **`load`** and **`blt`** operate on your private list of races.  No one else will be able to view or modify your private list.  **`savePublic`**, **`overwritePublic`**, **`listPublic`**, **`deletePublic`**, **`loadPublic`** and **`bltPublic`** work like the private versions but operate on the public list of races.  All players have access to the public list of races.

You can clear all waypoints, except registration waypoints, by typing **`/races clear`**.  You cannot clear waypoints if you have joined a race. Leave the race or finish it first.

After you have set your waypoints, you can register your race.  This will advertise your race to all players.  Your race must have two or more waypoints.  At the starting waypoint of the race, a purple circled star blip will appear on the waypoint map and a purple cylinder checkpoint will appear in the world.  These will be visible to all players.  This will be the registration waypoint.

The registration waypoint on the waypoint map will be labeled with some information about the race.  The player who registered the race and the buy-in amount will be shown.  If **'using [vehicle]'** is shown, the race is restricted to that vehicle.  If **'using [class] vehicle class'** is shown, the race is restricted to vehicles of type [class].  If **'using random vehicles'** is shown, the race will change vehicles randomly every lap.  If **'using random vehicles : [vehicle]'** is shown, the race will change vehicles randomly every lap and racers will start in the specified [vehicle].  If **'using random [class] vehicle class'** is shown, the race will change vehicles randomly every lap to one from that [class].  If **'using random [class] vehicle class : [vehicle]'** is shown, the race will change vehicles randomly every lap to one from that [class] and start in the specified [vehicle].  This allows racers to determine whether or not they can join the race without having to drive all the way to the starting waypoint.

Type **`/races register 100 2 180`** to register your race with a buy-in amount of 100, 2 laps, a DNF timeout of 180 seconds and no restrictions on the vehicle used.  If you do not indicate the buy-in amount, the default is 500.  If you do not indicate the number of laps, the default is 1 lap.  If you do not indicate the DNF timeout, the default is 120 seconds.

If you want to restrict the vehicle used in a race, type **`/races register 100 2 180 rest elegy2`** to restrict vehicles to **`elegy2`**.

If you want to restrict the vehicle class used in a race, type **`/races register 100 2 180 class 0`** to restrict vehicles to class 0 (Compacts).

If you want to restrict vehicles to a custom list used in a race, type **`/races register 100 2 180 class 22 tier.txt`** to restrict vehicles to class 22 (Custom) which are specified in a file named **`resources/races/tier.txt`**.  If you specify class 22 (Custom), you must provide a file containing the vehicles you want in the race.

If you want a race where vehicles change randomly every lap, type **`/races register 100 2 180 rand`**.  Buy-in amounts will be set to 0 and there will be no payouts.  The randomly selected vehicles will come from the file **`resources/races/random.txt`**.  You can add vehicles from **`resources/races/vehicles.txt`** to **`resources/races/random.txt`** or remove vehicles from **`resources/races/random.txt`**.

If you want a race where vehicles change randomly every lap to one selected from vehicles in **`resources/races/myvehicles.txt`** that you created, type **`/races register 100 2 180 rand myvehicles.txt`**.  You can add vehicles from **`resources/races/vehicles.txt`** to **`resources/races/myvehicles.txt`**.

If you want to increase the chances of a specific vehicle appearing, you can enter multiple entries of that vehicle in **`resources/races/random.txt`** or the file that you specified.  Blank lines in the file are ignored.  If there are invalid vehicles in the file, they will be ignored.

If you want a race where vehicles change randomly every lap to one selected from vehicles of class 0 (Compacts) in **`resources/races/myvehicles.txt`**, type **`/races register 100 2 180 rand myvehicles.txt 0`**.

If you want a race where vehicles change randomly every lap to one selected from vehicles in **`resources/races/myvehicles.txt`** and racers start in an **`adder`** vehicle, type **`/races register 100 2 180 rand myvehicles.txt . adder`**.  The period between **`myvehicles.txt`** and **`adder`** indicates that vehicles can come from any class in **`resources/races/myvehicles.txt`**.

If you want a race where vehicles change randomly every lap to one selected from vehicles of class 0 (Compacts) in **`resources/races/myvehicles.txt`** and racers start in a **`blista`** vehicle, type **`/races register 100 2 180 rand myvehicles.txt 0 blista`**.  When you specify a class like 0 (Compacts), the start vehicle must be of class 0 (Compacts).

The different classes of vehicle you can specify are listed here:

0: Compacts\
1: Sedans\
2: SUVs\
3: Coupes\
4: Muscle\
5: Sports Classics\
6: Sports\
7: Super\
8: Motorcycles\
9: Off-road\
10: Industrial\
11: Utility\
12: Vans\
13: Cycles\
14: Boats\
15: Helicopters\
16: Planes\
17: Service\
18: Emergency\
19: Military\
20: Commercial\
21: Trains\
22: Custom

As a convenience, each class of vehicle has been separated into different files in the **`vehicles/`** folder.  Vehicles of class 0 have been placed in **`00.txt`**.  Vehicles of class 1 have been placed in **`01.txt`**.  Vehicles of other classes have been placed in similarly named files except for class 22 (Custom).  Each of these files contain vehicles taken from **`vehicles.txt`**.  Vehicles that don't seem to be in my version of GTA 5 are in the **`uknown.txt`** file.

If you want to use the default value for some arguments of the **`/races register`** command, you can type '.' to use the default value for that argument.  For example, if you type **`/races register . 4 . rand . 9`** the race will be a random race using the default buy-in amount (500), 4 laps, the default DNF timeout (120 seconds), the default file of vehicles to randomly select from (**`resources/races/random.txt`**) and vehicles of class 9 (Off-road).  This is the equivalent of **`/races register 500 4 120 rand random.txt 9`**.

If you set the number of laps to 2 or more, the start and finish waypoints must be the same.  Instructions on how to do this are listed above.  You may only register one race at a time.  If you want to register a new race, but already registered one, you must unregister your current race first. You cannot register a race if you are currently editing waypoints.  Stop editing first.

You can unregister your race by typing **`/races unregister`**.  This will remove your race advertisement from all players.  This can be done before or after you have started the race.  **IF YOU ALREADY STARTED THE RACE AND THEN UNREGISTER IT, THE RACE WILL BE CANCELED.**

To join a race, players will need to be close enough to a registration point to be prompted to join.  The registration point will tell the player if it is an unsaved race or if it is a publicly or privately saved race along with its saved name, who registered the race, how much the buy-in amount is, how many laps there are and the type of race.

There are seven possible types of race you can join:  1. Any vehicle can be used, 2. Restricted to a specific vehicle, 3. Restricted to a specific vehicle class, 4. Vehicles change randomly every lap, 5. Vehicles change randomly every lap and racers start in a specified vehicle, 6. Vehicles change randomly every lap to one in a specific class, 7. Vehicles change randomly every lap to one in a specific class and racers start in a specified vehicle.  For race types 4, 5, 6 and 7, buy-in amounts will be set to 0 and there will be no payouts.

Players who want to join the race will need to have enough funds to pay for the buy-in amount.  All players begin with at least 5000 in their funds.

If the race is restricted to specific vehicle, its name is shown at the registration point.  Players will need to be in the restricted vehicle at the registration point in order to join the race.  Players can spawn the restricted vehicle by typing **`/races spawn [vehicle]`** where [vehicle] is the restricted vehicle name.

If the race is restricted to a specific vehicle class, the class name and number is shown at the registration point.  You must be in a vehicle of the restricted class to join the race.  If the class is 22 (Custom), you can view which vehicles are allowed in the race by getting out of any vehicle you are in, walking into the registration point on foot and trying to join the race.  The chat window will list which vehicles you can use in the class 22 (Custom) race.  If the class is not 22 (Custom), you can list vehicles of the class by typing **`/races lvehicles [class]`** where [class] is the vehicle class number.

To join the race, type 'E' or press right DPAD.  Joining the race will clear any waypoints you previously set and load the race waypoints.  **NOTE THAT YOU CANNOT JOIN A RACE IF YOU ARE EDITING WAYPOINTS.  STOP EDITING FIRST.**  You can only join one race at a time.  If you want to join another race, leave your current one first.  If you do not join the race you registered, you will not see the results of that race.

To list all competitors in the race that you joined, type **`/races rivals`**.  You will not be able to see competitors if you have not joined a race.  If you cannot see all the competitors, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

To respawn at the last waypoint the player has passed in a race type **`/races respawn`**.  You can also press 'X' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a DualShock controller for one second to respawn.  You can only respawn if you are currently in a race.

Once everyone who wants to join your registered race have joined, you can start the race.  Type **`/races start 10`** to start the race with a delay of 10 seconds before the actual start.  If you do not indicate a delay, the default is 30 seconds.  The minimum delay allowed is 5 seconds.  Any vehicles the players are in will be frozen until after the delay expires.  After the race has started, your race advertisement will be removed from all players.

The current race waypoint will have a yellow cylinder checkpoint appear in the world.  It will have an arrow indicating the direction of the next checkpoint.  If a restricted vehicle was specified at the race registration point, you will need to be in the restricted vehicle when passing the checkpoint to make the next checkpoint appear.  If a restricted vehicle was not specified, you can pass the checkpoint in any vehicle or on foot to make the next checkpoint appear.  Once you pass the checkpoint, it will disappear, a sound will play and the next checkpoint will appear in the world.  Only the next three waypoints will be shown on the minimap at a time.  A blue route will be shown in your minimap to the current race waypoint.  Once you pass the current waypoint, it will disappear on the minimap and the next third waypoint along the route will appear on the minimap.  Once you leave or finish the race, all the race waypoints will reappear on the minimap.

Your current position, lap, waypoint, lap time, best lap time, total time, vehicle name and speed will display.  If someone has already finished the race, a DNF timeout will also appear.

If you want to leave a race you joined, type **`/races leave`**.  **IF YOU LEAVE AFTER THE RACE HAS STARTED, YOU WILL DNF.**

After the first racer finishes, there will be a DNF timeout for other racers.  They must finish within the timeout, otherwise they DNF.

As racers finish, their finishing time, best lap time and the vehicle name they used for their best lap time will be broadcast to players who joined the race.  If a racer DNF's, this will also be broadcast.

After all racers finish or DNF, the race results will be broadcast to players who joined the race.  Their position, name, finishing time, best lap time and name of the vehicle used for their best lap time will be displayed.  Best lap times will be recorded if the race was a saved race and waypoints were not modified.  Race results are saved to **`resources/races/[owner]_results.txt`** where [owner] is the owner of the race.

Racers are given prize money after all racers finish or DNF.  At the start of every game session, players start with at least 5000 in their funds.  If you are using the existing **`port.lua`** file, race earnings are not saved between different game sessions.  If you win prize money in one game session, it will not carry over to the next game session.  **`port.lua`** may be ported to a framework that does save funds between different game sessions.  The ESX framework may save race earnings from one game session to the next game session.  A port of the **`port.lua`** file to ESX is in the **`esx/`** folder.  Total race prize money is the sum of all buy-in amounts that all racers paid.  The prize distribution is as follows: 1st 60%, 2nd 20%, 3rd 10%, 4th 5%, 5th 3% and lastly, 2% is spread evenly among racers who finished 6th and later.  Racers who DNF will not receive a payout unless all racers DNF.  If all racers DNF, all racers are refunded their buy-in amounts.  If fewer racers finish the race than there are places in the prize distribution, all racers who finished will receive any left over percentages split evenly among the finishers.  If you wish to distribute the prize money differently, you will need to modify the values of the table named **`dist`** in **`races_server.lua`**.  The declaration and initialization of **`dist`** is **`local dist <const> = {60, 20, 10, 5, 3, 2}`**.  You can change the total number of values in the table.  For the distribution to be valid, the following conditions must be met:  All values in the table **`dist`** must add up to 100.  All values in the table must be 1 or greater.  First place distribution must be greater than or equal to second place distribution.  Second place distribution must be greater than or equal to 3rd place distribution and so on.  If these conditions are not met, a message will be displayed in the server console in red saying that the distribution is invalid.  If the distribution is invalid, players can still race.  Their buy-in amounts will be refunded after all racers finish or DNF.

If you want to look at the race results again, type **`/races results`**.  If you cannot see all the results, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

To spawn a vehicle, type **`/races spawn elegy2`** to spawn an **`elegy2`** vehicle.  If you do not indicate a vehicle name, the default is **`adder`**.  A list of vehicles you can spawn are listed in **`vehicles.txt`**.  This list has not been verified to work for all vehicles listed and there may be some missing.

To list vehicles that can be used for any race, type **`/races lvehicles`**.  To list vehicles of a specific class, type **`/races lvehicles 0`** to list class 0 (Compacts) vehicles.  The vehicles displayed come from the **`vehicles.txt`** file which should contain every vehicle.

To toggle the display of the speedometer at any time, type **`/races speedo`**.  The speedometer automatically displays when you are in a race and disappears when you finish or leave the race.  The default unit of measurement is imperial.  If you wish to change the unit of measurement type **`/races speedo (unit)`** where (unit) is either **`imp`** for imperial or **`met`** for metric.

To view your available funds for race buy-ins, type **`/races funds`**.

Type **`/races panel`** to show the main panel.  Type **`/races panel edit`** to show the edit tracks panel.  Type **`/races panel register`** to show the register races panel.  All **`/races`** commands have a corresponding button and argument field(s) if needed.  Replies to the commands will show up in another panel as well as in chat.  To close the panel, type 'Escape' or click the 'Close' button at the bottom.

Leaving a race or finishing it does not clear its waypoints.  If you like the race, you can save the waypoints to your private list by typing **`/races save nicerace`**.

Multiple races can be registered and started simultaneously by different players.

SERVER COMMAND DETAILS
----------------------
Server commands are typed into the server console.

Type **`races`** to see the list of available **`races`** commands.

Type **`races export publicrace`** to export the public race saved as 'publicrace' without best lap times to the file **`resources/races/publicrace.json`**.  You cannot export the race if **`resources/races/publicrace.json`** already exists.  You will need to remove or rename the existing file and then export again.

Type **`races import myrace`** to import the race file named **`resources/races/myrace.json`** into the public races list without best lap times.  You cannot import 'myrace' if it already exists in the public races list.  You will need to rename the file and then import with the new name.

Type **`races exportwblt publicrace`** to export the public race saved as 'publicrace' with best lap times to the file **`resources/races/publicrace.json`**.  You cannot export the race if **`resources/races/publicrace.json`** already exists.  You will need to remove or rename the existing file and then export again.

Type **`races importwblt myrace`** to import the race file named **`resources/races/myrace.json`** into the public races list with best lap times.  You cannot import 'myrace' if it already exists in the public races list.  You will need to rename the file and then import with the new name.

**If permission is required to edit tracks, register races and spawn vehicles, the following commands administer these permissions:**

Type **`races listReqs`** to list requests by players to edit tracks, register races and spawn vehicles.  The format of each element of the list is **`[playerID]:[name]:[role]`** where [playerID] is the player ID who requested permission, [name] is the player's name and [role] is either "EDIT", "REGISTER" or "SPAWN".

Type **`races approve [playerID]`** to approve the request of the player with [playerID].

Type **`races deny [playerID]`** to deny the request of the player with [playerID].

Type **`races listRoles`** to list the players who have had their roles approved.  The format of each element of the list is **`[name]:[roles]`** where [name] is the name of the player and [roles] is a list of roles the player has which can be any combination of "EDIT", "REGISTER" and "SPAWN".

Type **`races removeRoles [name]`** to remove all the roles of the player with [name].

Roles are saved in the file **`resources/races/roles.json`**.

**IF YOU WANT TO PRESERVE RACES FROM A PREVIOUS VERSION OF THESE SCRIPTS, YOU SHOULD UPDATE `raceData.json` AND ANY EXPORTED RACES BY EXECUTING THE FOLLOWING COMMANDS BEFORE CLIENTS CONNECT TO THE SERVER TO USE THE NEW RACE DATA FORMAT WHICH INCLUDES WAYPOINT RADIUS SIZES.**

Type **`races updateRaceData`** to update **`resources/races/raceData.json`** to the new file **`resources/races/raceData_updated.json`**.  You will need to remove the old **`raceData.json`** file and then rename **`raceData_updated.json`** to **`raceData.json`** to use the new race data format.

Type **`races updateRace myrace`** to update the exported race **`resources/races/myrace.json`** to the new file **`resources/races/myrace_updated.json`**.  You will need to remove the old **`myrace.json`** file and then rename **`myrace_updated.json`** to **`myrace.json`** to use the new race data format.  You will then be able to import the race using the new race data format.

PORTING
-------
If you wish to port these scripts to a specific framework, such as ESX, you will need to modify the contents of the funds functions **`GetFunds`**, **`SetFunds`**, **`Withdraw`**, **`Deposit`** and **`Remove`** in **`port.lua`** to work for your framework.

An attempt to port the funds functions to ESX is available in the **`esx/`** folder.  Copy **`esx/port.lua`** to your server's **`resources/races/`** folder replacing the existing **`port.lua`** file.

SCREENSHOTS
-----------
Registration point\
<img src="screenshots/Screenshot%20(1).png" width="800">

Before race start\
<img src="screenshots/Screenshot%20(2).png" width="800">

In race\
<img src="screenshots/Screenshot%20(3).png" width="800">

In race\
<img src="screenshots/Screenshot%20(4).png" width="800">

Near finish\
<img src="screenshots/Screenshot%20(5).png" width="800">

Race results\
<img src="screenshots/Screenshot%20(6).png" width="800">

Editing waypoints in waypoint map\
<img src="screenshots/Screenshot%20(7).png" width="800">

Editing waypoints in world\
<img src="screenshots/Screenshot%20(8).png" width="800">

Main command button panel\
<img src="screenshots/Screenshot%20(9).png" width="800">

Edit tracks command button panel\
<img src="screenshots/Screenshot%20(10).png" width="800">

Register races command button panel\
<img src="screenshots/Screenshot%20(11).png" width="800">

LICENSE
-------
Copyright (c) 2021, Neil J. Tan
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
