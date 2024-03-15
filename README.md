## INSTALLATION

- Setting up a server:  https://docs.fivem.net/docs/server-manual/setting-up-a-server/

- Create a **`races/`** folder under your server **`resources/`** folder.  Place **`fxmanifest.lua`**, **`races_client.lua`**, **`races_server.lua`**, **`port.lua`**, **`trackData.json`** and **`vehicles.json`** in the **`resources/races/`** folder.  Create an **`html/`** folder under your server **`resources/races/`** folder.  Place **`index.css`**, **`index.html`**, **`index.js`** and **`reset.css`** in the **`resources/races/html/`** folder.  Add **`ensure races`** to your **`server.cfg`** file.

## CLIENT COMMANDS

Required arguments are in square brackets.  Optional arguments are in parentheses.  
>**`/races`** - display list of available **`/races`** commands  
>**`/races edit`** - toggle editing track waypoints  
>**`/races clear`** - clear track waypoints  
>**`/races reverse`** - reverse order of track waypoints

For the following **`/races`** commands, [access] = {pvt, pub} where 'pvt' operates on a private track and 'pub' operates on a public track  
>**`/races load [access] [name]`** - load private or public track saved as [name]  
>**`/races save [access] [name]`** - save new private or public track as [name]  
>**`/races overwrite [access] [name]`** - overwrite existing private or public track saved as [name]  
>**`/races delete [access] [name]`** - delete private or public track saved as [name]  
>**`/races list [access]`** - list saved private or public tracks  
>**`/races blt [access] [name]`** - list 10 best lap times of private or public track saved as [name]

>**`/races ai add [name]`** - add an AI driver named [name]  
>**`/races ai spawn [name] (vehicle)`** - spawn AI driver named [name] in (vehicle); (vehicle) defaults to 'adder'  
>**`/races ai delete [name]`** - delete an AI driver named [name]  
>**`/races ai deleteAll`** - delete all AI drivers  
>**`/races ai list`** - list AI driver names

For the following **`/races ai`** commands, [access] = {pvt, pub} where 'pvt' operates on a private AI group and 'pub' operates on a public AI group  
>**`/races ai loadGrp [access] [name]`** - load private or public AI group saved as [name]  
>**`/races ai saveGrp [access] [name]`** - save new private or public AI group as [name]  
>**`/races ai overwriteGrp [access] [name]`** - overwrite existing private or public AI group saved as [name]  
>**`/races ai deleteGrp [access] [name]`** - delete private or public AI group saved as [name]  
>**`/races ai listGrps [access]`** - list saved private or public AI groups

>**`/races vl add [vehicle]`** - add [vehicle] to vehicle list  
>**`/races vl delete [vehicle]`** - delete [vehicle] from vehicle list  
>**`/races vl addClass [class]`** - add all vehicles of type [class] to vehicle list  
>**`/races vl deleteClass [class]`** - delete all vehicles of type [class] from vehicle list  
>**`/races vl addAll`** - add all vehicles to vehicle list  
>**`/races vl deleteAll`** - delete all vehicles from vehicle list  
>**`/races vl list`** - list all vehicles in vehicle list

For the following **`/races vl`** commands, [access] = {pvt, pub} where 'pvt' operates on a private vehicle list and 'pub' operates on a public vehicle list  
>**`/races vl loadLst [access] [name]`** - load private or public vehicle list saved as [name]  
>**`/races vl saveLst [access] [name]`** - save new private or public vehicle list as [name]  
>**`/races vl overwriteLst [access] [name]`** - overwrite existing private or public vehicle list saved as [name]  
>**`/races vl deleteLst [access] [name]`** - delete private or public vehicle list saved as [name]  
>**`/races vl listLsts [access]`** - list saved private or public vehicle lists

For the following **`/races register`** commands, (buy-in) defaults to 500, (laps) defaults to 1 lap, (DNF timeout) defaults to 120 seconds and (allow AI) = {yes, no} defaults to 'no'  
>**`/races register (buy-in) (laps) (DNF timeout) (allow AI)`** - register your race with no vehicle restrictions  
>**`/races register (buy-in) (laps) (DNF timeout) (allow AI) rest [vehicle]`** - register your race restricted to [vehicle]  
>**`/races register (buy-in) (laps) (DNF timeout) (allow AI) class [class]`** - register your race restricted to vehicles of type [class]; if [class] is '-1' then use custom vehicle list  
>**`/races register (buy-in) (laps) (DNF timeout) (allow AI) rand (class) (start) (recur) (order)`** - register your race changing vehicles randomly every lap; (class) defaults to any; (start) defaults to any; (recur) = {yes, no} defaults to 'yes'; (order) = {yes, no} defaults to 'no'

>**`/races unregister`** - unregister your race  
>**`/races start (delay)`** - start your registered race; (delay) defaults to 30 seconds

>**`/races leave`** - leave a race that you joined  
>**`/races rivals`** - list players in a race that you joined  
>**`/races respawn`** - respawn at last waypoint  
>**`/races results`** - view latest race results  
>**`/races spawn (vehicle)`** - spawn a vehicle; (vehicle) defaults to 'adder'  
>**`/races lvehicles (class)`** - list available vehicles of type (class); otherwise list all available vehicles if (class) is not specified  
>**`/races speedo (unit)`** - change unit of speed measurement to (unit) = {imperial, metric}; otherwise toggle display of speedometer if (unit) is not specified  
>**`/races funds`** - view available funds  
>**`/races panel (panel)`** - display (panel) = {track, ai, list, register} panel; otherwise display main panel if (panel) is not specified

**IF YOU DO NOT WANT TO TYPE CHAT COMMANDS, YOU CAN BRING UP A PANEL THAT CAN DO THE SAME TASK BY TYPING `/races panel`, `/races panel track`, `/races panel ai`, `/races panel list` OR `/races panel register`.**

## SERVER COMMANDS

Required arguments are in square brackets.  
>**`races`** - display list of available **`races`** commands  
>**`races list`** - list public tracks  
>**`races export [name]`** - export public track saved as [name] without best lap times to file named **`[name].json`**  
>**`races import [name]`** - import track file named **`[name].json`** into public tracks without best lap times  
>**`races exportwblt [name]`** - export public track saved as [name] with best lap times to file named **`[name].json`**  
>**`races importwblt [name]`** - import track file named **`[name].json`** into public tracks with best lap times

## SAMPLE TRACKS

- There are six sample tracks:  '00', '01', '02', '03', '04' and '05' saved in the public tracks list.  You can load sample track '00' by typing **`/races load pub 00`**.  To use the loaded track in a race, you need to register the race by typing **`/races register`**.  Go to the registration waypoint of the race indicated by a purple circled star blip on the waypoint map and a purple cylinder checkpoint in the world.  When prompted to join, type 'E' or press DPAD right to join.  Wait for other people to join if you want, then type **`/races start`**.

- There are backups of the sample tracks in the **`sampletracks/`** folder with the extension '.json'.  Track '00' is backed up as **`sampletracks/00.json`**.  If any of the sample tracks were deleted from the public list of tracks, you can restore them.  Copy the deleted track from the **`sampletracks/`** folder to the **`resources/races/`** folder.  In the server console, type **`races import 00`** to import track '00' back into the public tracks list.

## QUICK GUIDE FOR RACE CREATORS

- Type **`/races edit`** until you see the message **`'Editing started'`**.  Add at least 2 waypoints on the waypoint map or in the world by pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a PlayStation controller.  Type **`/races edit`** again until you see the message **`'Editing stopped'`**.  Save the track if you want by typing **`/races save pvt mytrack`**.  Register your race by typing **`/races register`**.  At the starting waypoint of the track, a purple circled star blip will appear on the waypoint map and a purple cylinder checkpoint will appear in the world.  This is the registration waypoint which all players will see.  Players need to have enough funds to pay for the buy-in.  Players should move towards the registration waypoint until prompted to join and type 'E' or press DPAD right to join.  After all the players who want to join the race have joined, you can start the race by typing **`/races start`**.

## QUICK GUIDE FOR RACING

- There are four possible types of race you can join:
1. Any vehicle can be used
2. Restricted to a specific vehicle
3. Restricted to a specific vehicle class
4. Vehicles change randomly every lap

- Look for registration waypoints which appear as purple circled star blips on the waypoint map.  The label for a blip in the waypoint map will indicate the player who registered the race, the buy-in amount, the number of laps, the DNF timeout, if AI drivers are allowed and other parameters of the race.  There will be corresponding purple cylinder checkpoints in the world.

- If the race allows AI drivers to be added, the label will include **'AI allowed'**.  The person who registered the race can add as many AI drivers as they like.  Buy-in amounts will be set to 0.

- If the race is restricted to a specific vehicle, the label will include **'using [vehicle]'** where [vehicle] is the name of the restricted vehicle.  You must be in that vehicle when you join the race.  You can spawn the restricted vehicle by typing **`/races spawn [vehicle]`** where [vehicle] is the restricted vehicle.  For example, if the label shows **'using zentorno'**, you can spawn the vehicle by typing **`/races spawn zentorno`**.

- If the race is restricted to a specific vehicle class, the label will include **'using [class] class vehicles'** where [class] is the vehicle class.  The class number will be in parentheses.  You must be in a vehicle of that class to join the race.  If the class is not **'Custom'(-1)**, you can list vehicles in the class by typing **`/races lvehicles [class]`** where [class] is the vehicle class number.  If the class is **'Custom'(-1)**, you can view which vehicles are allowed in the race by getting out of any vehicle you are in, walking into the registration waypoint on foot and trying to join the race as described later.  A message in the chat window will tell you that you cannot join the race and will list which vehicles are allowed.

- If the race changes vehicles randomly every lap, buy-in amounts will be set to 0 and the label will show one or more of the following.

   - If there are no restrictions on the vehicles used, the label will include **'using random vehicles'**.

   - If the race is restricted to a specific vehicle class, the label will include **'using random [class] class vehicles'** where [class] is the vehicle class.  The class number will be in parentheses.

   - If the label includes **'start [vehicle]'**, racers will start in the specified [vehicle].

   - If the label includes **'recurring'**, vehicles that appeared in previous laps may be used in later laps.

   - If the label includes **'nonrecurring'**, vehicles that appeared in previous laps will not be used in later laps.

   - If the label includes **'unordered'**, every racer may use a different random vehicle after the same lap number.

   - If the label includes **'ordered'**, every racer will use the same random vehicle after the same lap number.

- To join the race, you will need to move toward the registration waypoint until prompted to join.  The prompt will indicate who registered the race, if it uses an unsaved track or a publicly or privately saved track along with its saved name, the buy-in amount, the number of laps, the DNF timeout, if AI drivers are allowed and other parameters of the race.  If there is a restriction on the vehicle or the vehicle class that can be used, you will need to comply with the restriction to join the race.  You must have enough funds to pay for the buy-in amount.  You can check how much funds you have by typing **`/races funds`**.  Type 'E' or press DPAD right to join the race.  The player who registered the race will be the one who starts the race.  Once they start the race, all racer's vehicles will be frozen until the start delay has expired and the race has officially begun.  Follow the checkpoints until the finish.  The results of the race will be broadcast to all racers who joined.  Prize money will be distributed to all finishers.  If you want to see the results again, type **`/races results`**.

## CLIENT COMMAND DETAILS

- Type **`/races`** to see the list of available **`/races`** commands.  If you cannot see all the commands, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

- ### EDITING TRACKS
   - Type **`/races edit`** until you see the message **`'Editing started'`** to start editing waypoints.  Once you are finished, type **`/races edit`** until you see the message **`'Editing stopped'`** to stop editing.  You cannot edit waypoints if you have joined a race.  Leave the race or finish it first.

   - There are four types of track waypoints and one type of registration waypoint.  Each track waypoint will have a corresponding blip on the waypoint map and, when editing, a corresponding checkpoint in the world.  A combined start/finish waypoint is a yellow checkered flag blip/checkpoint.  A start waypoint is a green checkered flag blip/checkpoint.  A finish waypoint is a white checkered flag blip/checkpoint.  A waypoint that is not a start and/or finish waypoint is a blue numbered blip/checkpoint.  A registration waypoint is a purple blip/checkpoint.  When you stop editing, all the checkpoints in the world, except for registration checkpoints, will disappear, but all the blips on the waypoint map will remain.

   - Selecting a waypoint on the waypoint map is done by moving the waypoint you want to select under the crosshairs and pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a PlayStation controller.  Selecting a waypoint in the world is done by moving toward the waypoint until prompted to select the waypoint and pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a PlayStation controller.  The corresponding blip on the waypoint map and checkpoint in the world will turn red.  Unselecting a waypoint is done by selecting the waypoint again.  This will turn the waypoint color back to its original color.

   - To add a waypoint on the waypoint map, unselect any waypoints, move the point where you want to add the waypoint under the crosshairs and press 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a PlayStation controller.  A corresponding checkpoint in the world will be created.

   - To add a waypoint in the world, unselect any waypoints, move to the point where you want to add the waypoint and press 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a PlayStation controller.  A corresponding blip in the waypoint map will be created.

   - The first waypoint you add will be a start/finish waypoint (yellow checkered flag).  Adding a second waypoint will turn the start/finish waypoint into a start waypoint (green checkered flag) and the second waypoint will become a finish waypoint (white checkered flag).  Every waypoint added after the first two will become a finish waypoint (white checkered flag).  Waypoints between the start and finish waypoints will become blue numbered waypoints.

   - If you want to add a waypoint between two consecutive waypoints, select the two waypoints first and then add the new waypoint.  The two waypoints you select must be consecutive waypoints.  You will not be able to select two non-consecutive waypoints.  After adding the new waypoint, the two waypoints you selected will become unselected.  You will not be able to add a waypoint between the first and last waypoints this way.  To add a waypoint between the first and last waypoints, unselect any waypoints and add the new waypoint.

   - **NOTE: The position number of a racer while in a race will be the most accurate if waypoints are added at every bend or corner in the track.**

   - You can delete a waypoint by making it the only selected waypoint, then pressing 'Spacebar' on a keyboard, 'X' button on an Xbox controller or 'Square' button on a PlayStation controller.  Deleting a waypoint will delete the corresponding blip on the waypoint map and the corresponding checkpoint in the world.

   - You can move an existing waypoint on the waypoint map by making it the only selected waypoint, moving the point where you want to move the waypoint under the crosshairs and pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a PlayStation controller.

   - You can move an existing waypoint in the world by making it the only selected waypoint, moving to the point where you want the waypoint and pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a PlayStation controller.

   - You can increase or decrease the radius of an existing waypoint in the world, but not in the waypoint map.  There are minimum and maximum radius limits to waypoints.  To increase the radius of the waypoint, select the waypoint, then press 'Up Arrow' on a keyboard or DPAD up.  To decrease the radius of the waypoint, select the waypoint, then press 'Down Arrow' on a keyboard or DPAD down.  When in a race, a player has passed a waypoint if they pass within the radius of the waypoint.  The waypoint will disappear and the next waypoint will appear.

   - For multi-lap races, the start and finish must be the same waypoint.  Select the finish waypoint (white checkered flag) first, then select the start waypoint (green checkered flag).  The original start waypoint (green checkered flag) will become a start/finish waypoint (yellow checkered flag).  The original finish waypoint (white checkered flag) will become a blue numbered waypoint.

   - You can separate the start/finish waypoint (yellow checkered flag) in one of two ways.  The first way is by selecting the start/finish waypoint (yellow checkered flag) first, then selecting the highest numbered blue waypoint.  The start/finish waypoint will become the start waypoint (green checkered flag).  The highest numbered blue waypoint will become the finish waypoint (white checkered flag).  The second way is by unselecting any waypoints and adding a new waypoint.  The start/finish waypoint will become the start waypoint (green checkered flag).  The added waypoint will become the finish waypoint (white checkered flag).

   - Type **`/races clear`** to clear all waypoints, except registration waypoints.  You cannot clear waypoints if you have joined a race. Leave the race or finish it first.

   - Type **`/races reverse`** to reverse the order of waypoints.  You cannot reverse waypoints if you have joined a race. Leave the race or finish it first.

   - Best lap times will be recorded after a race only for saved tracks.  Best lap times will not be recorded if you are creating a track and have not saved it or if you have loaded a saved track and modified any of its waypoints.  A modification to a saved track means adding, deleting, moving, increasing/decreasing radii, combining start/finish, separating start/finish or reversing waypoints.  Changes can only be undone by reloading the saved track.

- ### MANAGING TRACKS
   - The commands **`/races load`**, **`/races save`**, **`/races overwrite`**, **`/races delete`**, **`/races list`** and **`/races blt`** operate on your private list if you specify **`pvt`** after the command or on the public list if you specify **`pub`** after the command.  Only you can manage your private list.  All players can manage the public list.

   - Type **`/races load pvt mytrack`** to load the waypoints of a track named **`mytrack`** in your private list.  This will clear any current waypoints and load the waypoints from the saved track.  You cannot load a saved track if you have joined a race.  Leave the race or finish it first.

   - Type **`/races save pvt mytrack`** to save the waypoints as **`mytrack`** in your private list.  The track must have at least two waypoints before you can save.  **`mytrack`** must not exist in your private list.  The best lap times for this track will be empty.

   - Type **`/races overwrite pvt mytrack`** to overwrite an existing track named **`mytrack`** in your private list.  **`mytrack`** must already exist in your private list.  **NOTE THAT OVERWRITING A TRACK WILL DELETE ANY EXISTING BEST LAP TIMES.**

   - Type **`/races delete pvt mytrack`** to delete a track named **`mytrack`** from your private list.

   - Type **`/races list pvt`** to list all the tracks in your private list.  If you cannot see all the track names, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

   - Type **`/races blt pvt mytrack`** to see the 10 best lap times recorded for **`mytrack`**.  If you cannot see all the best lap times, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

   - Track waypoints and best lap time data is saved in the file **`resources/races/trackData.json`**.

- ### EDITING AI GROUPS
   - An AI group is made of one or more AI drivers and the vehicles they drive.  Before you can add and spawn AI drivers, you will need to register a race allowing AI to join first.  You must join the race to see the gamer tags of any AI you add and spawn.

   - Type **`/races ai add alpha`** to add an AI driver named **`alpha`** at your current location and heading.  This only sets the location and heading of the driver.

   - Type **`/races ai spawn alpha elegy2`**, after moving away from the location where you added the driver, to spawn a driver in an **`elegy2`** vehicle at the location and heading you set.  If you do not specify a vehicle, an **`adder`** vehicle is spawned by default.  If you decide the driver should be in a different vehicle, type **`/races ai spawn alpha zentorno`** to change the vehicle to a **`zentrono`**.

   - Type **`/races ai delete alpha`** to delete an AI driver you added named **`alpha`**.  You can delete the driver before or after you spawn the driver.

   - Type **`/races ai deleteAll`** to delete all AI drivers.

   - Type **`/races ai list`** to list all the names of the AI drivers you added and the vehicles they are in.  If you cannot see all the AI drivers, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

   - If you want to ride as a passenger in the AI's vehicle, move close to the vehicle and press 'F' on a keyboard, 'Y' button on an Xbox controller or 'Triangle' button on a PlayStation controller.

- ### MANAGING AI GROUPS
   - The commands **`/races ai loadGrp`**, **`/races ai saveGrp`**, **`/races ai overwriteGrp`**, **`/races ai deleteGrp`** and **`/races ai listGrps`** operate on your private list if you specify **`pvt`** after the command or on the public list if you specify **`pub`** after the command.  Only you can manage your private list.  All players can manage the public list.

   - Type **`/races ai loadGrp pvt mygroup`** to load an AI group named **`mygroup`** from your private list.  This will clear any current AI drivers and load the AI drivers from **`mygroup`**`.  If the race is restricted to a specific vehicle or a vehicle class, loading the entire group will fail if any AI vehicle violates the restriction.  AI that have a vehicle violating the restriction will be added, but not spawned.

   - Type **`/races ai saveGrp pvt mygroup`** to save an AI group named **`mygroup`** to your private list.  **`mygroup`** must not exist in your private list.  You cannot save unless all AI drivers that were added are also spawned.

   - Type **`/races ai overwriteGrp pvt mygroup`** to overwrite an existing AI group named **`mygroup`** in your private list.  **`mygroup`** must already exist in your private list.  You cannot overwrite unless all AI drivers that were added are also spawned.

   - Type **`/races ai deleteGrp pvt mygroup`** to delete an AI group named **`mygroup`** from your private list.

   - Type **`/races ai listGrps pvt`** to list all the AI groups in your private list.  If you cannot see all the AI group names, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

   - AI group data is saved in the file **`resources/races/aiGroupData.json`**.

- ### EDITING VEHICLE LISTS
   - A vehicle list is a list of vehicles that will be used in custom class races or random vehicle races.  Vehicle lists must be created or loaded before registering these types of races.

   - Custom class races only allow vehicles that are in the vehicle list to be used for racing.

   - Random vehicle races change vehicles randomly every lap to one of the vehicles in the vehicle list.

   - Type **`/races vl add zentorno`** to add a **`zentorno`** to your vehicle list.  If you are creating a random race, you can add the same vehicle multiple times to your vehicle list to increase the chances that a racer will be put in this vehicle after they complete a lap.

   - Type **`/races vl delete zentorno`** to delete a **`zentorno`** from your vehicle list.  If you have multiple **`zentorno`** vehicles in your list, only one will be deleted at a time.

   - Type **`/races vl addClass 7`** to add all **'Super'(7)** class vehicles to your list.

   - Type **`/races vl deleteClass 7`** to delete all **'Super'(7)** class vehicles from your list.

   - Type **`/races vl addAll`** to add all vehicles from the **`vehicles.json`** file to your vehicle list.

   - Type **`/races vl deleteAll`** to delete all vehicles from your vehicle list.

   - Type **`/races vl list`** to list all the vehicles in your vehicle list.  If you cannot see all the vehicles in your vehicle list, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

- ### MANAGING VEHICLE LISTS
   - The commands **`/races vl loadLst`**, **`/races vl saveLst`**, **`/races vl overwriteLst`**, **`/races vl deleteLst`** and **`/races vl listLsts`** operate on your private list if you specify **`pvt`** after the command or on the public list if you specify **`pub`** after the command.  Only you can manage your private list.  All players can manage the public list.

   - Type **`/races vl loadLst pvt mylist`** to load the vehicle list named **`mylist`** from your private list.  This will clear your current vehicle list and load the vehicles from the saved list.

   - Type **`/races vl saveLst pvt mylist`** to save your vehicle list as **`mylist`** to your private list.  **`mylist`** must not exist in your private list.  You cannot save if there are no vehicles in the vehicle list.

   - Type **`/races vl overwriteLst pvt mylist`** to overwrite an existing vehicle list named **`mylist`** in your private list.  **`mylist`** must already exist in your private list.  You cannot overwrite if there are no vehicles in the vehicle list.

   - Type **`/races vl deleteLst pvt mylist`** to delete a vehicle list named **`mylist`** from your private list.

   - Type **`/races vl listLsts pvt`** to list all the vehicle lists in your private list.  If you cannot see all the vehicle lists, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

   - Vehicle list data is saved in the file **`resources/races/vehicleListData.json`**.

- ### REGISTERING A RACE
   - There are four possible types of race you can register:
   1. Any vehicle can be used
   2. Restricted to a specific vehicle
   3. Restricted to a specific vehicle class
   4. Vehicles change randomly every lap

   - You will need to create or load a track before you can register a race.  Registering your race will advertise the race to all players.  At the starting waypoint of the track, also known as the registration waypoint, a purple circled star blip will appear on the waypoint map and a purple cylinder checkpoint will appear in the world.  The registration waypoint will be visible to all players.

   - The registration waypoint on the waypoint map will be labeled with some information about the race.  The player who registered the race, the buy-in amount, the number of laps, the DNF timeout, if AI drivers are allowed and other parameters of the race will be shown.  If **'AI allowed'** is shown, AI drivers may be added by the person who registered the race.  If **'using [vehicle]'** is shown, [vehicle] is the name of the only vehicle that racers are allowed to use.  If **'using [class] class vehicles'** is shown, the race is restricted to vehicles of type [class].  Random vehicle races will show one or more of the following parameters.  If **'using random vehicles'** is shown, vehicles will change randomly every lap with no restrictions on the vehicles.  If **'start [vehicle]'** is shown, racers will start in the specified [vehicle].  If **'using random [class] class vehicles'** is shown, vehicles will change randomly every lap to one from that [class].  If **'recurring'** is shown, vehicles that appeared in previous laps may be used in later laps.  If **'nonrecurring'** is shown, vehicles that appeared in previous laps will not be used in later laps.  If **'unordered'** is shown, every racer may use a different random vehicle after the same lap number.  If **'ordered'** is shown, every racer will use the same random vehicle after the same lap number.

   - If you move close enough to the registration waypoint in the world, you will see a prompt to join the race.  The prompt will tell you who registered the race, if it is an unsaved track or if it is a publicly or privately saved track along with its saved name, the buy-in amount, the number of laps, the DNF timeout, if AI drivers are allowed and other parameters of the race.

   - You may only register one race at a time.  If you want to register a new race, but already registered one, you must unregister your current race first.  You cannot register a race if its starting point is too close to another registered race's registration waypoint.

   - Multiple races can be registered simultaneously by different players.

   - **IF YOU DO NOT JOIN THE RACE YOU REGISTERED, YOU WILL NOT SEE THE RESULTS OF THE RACE.**

   - Type **`/races unregister`** to unregister your race.  This will remove your race advertisement from all players.  This can be done before or after you have started the race.  **IF YOU ALREADY STARTED THE RACE AND THEN UNREGISTER IT, THE RACE WILL BE  CANCELED.**

   ---
   - #### RACE TYPE 1 - Any vehicle can be used

      - Type **`/races register`** to register a race using default values for '**buy-in**', '**laps**', '**DNF timeout**' and '**allow AI**' parameters.

         > The '**buy-in**' parameter is how much it costs to join the race.  The default value is 500.  This amount is added into the prize pool for the race and redistributed at the end of the race according to finishing order.

         > The '**laps**' parameter is how many laps of a circuit there are in the race.  The default value is 1 lap.  Multi-lap races can be 1 or more laps.  Point to point races can only be 1 lap.  If you set the number of laps to 2 or more, the start and finish must be the same waypoint.

         > The '**DNF timeout**' parameter is how many seconds racers have to finish the race after the first racer finishes.  The default value is 120 seconds.  If racers do not finish before time runs out, they will DNF.

         > The '**allow AI**' parameter indicates if AI drivers are allowed to enter the race.  The default value is 'no'.  If AI are allowed, the person who registered the race can add AI drivers and buy-in amounts will be set to 0 even if an amount was specified.

      - You can specify non-default values at the end of the **`/races register`** command.

         For example, type **`/races register 100 2 180 yes`** if you want '100' for '**buy-in**', '2' for '**laps**', '180' for '**DNF timeout**' and 'yes' for '**allow AI**'.  Note that since this race allows AI, the buy-in amount will be set to 0 even though 100 was specified.

      - Type a period ('.') to represent the default value for a parameter.

         For example, type **`/races register . 3 . yes`** if you want the default value for '**buy-in**', '3' for '**laps**', the default value for '**DNF timeout**' and 'yes' for '**allow AI**'.  Note that since this race allows AI, the buy-in amount will be set to 0 even though the default value for '**buy-in**' was specified.

   ---
   - #### RACE TYPE 2 - Restricted to a specific vehicle

      - Type **`/races register 100 2 180 no rest elegy2`** to restrict the race to **`elegy2`** vehicles.  Players must be in the restricted vehicle to join the race.  Players can spawn the restricted vehicle by typing **`/races spawn elegy2`**.

   ---
   - #### RACE TYPE 3 - Restricted to a specific vehicle class
      - Type **`/races register 100 2 180 no class 0`** to restrict the race to **'Compacts'(0)** class vehicles.  Players must be in a vehicle of the restricted class to join the race.

      - The class numbers you can specify and their names are listed below:

         -1: Custom  
         0: Compacts  
         1: Sedans  
         2: SUVs  
         3: Coupes  
         4: Muscle  
         5: Sports Classics  
         6: Sports  
         7: Super  
         8: Motorcycles  
         9: Off-road  
         10: Industrial  
         11: Utility  
         12: Vans  
         13: Cycles  
         14: Boats  
         15: Helicopters  
         16: Planes  
         17: Service  
         18: Emergency  
         19: Military  
         20: Commercial  
         21: Trains  
         22: Open Wheel

      - If the class is anything other than **'Custom'(-1)**, type **`/races lvehicles [class]`**, where [class] is the vehicle class number, to list all vehicles in the class.

      - Type **`/races register 100 2 180 no class -1`** to create a race where only vehicles in a custom list are allowed.  The allowed vehicles will come from a vehicle list that you created or loaded before registering the race.  **If you want to know which vehicles are allowed in a 'Custom'(-1) class race, get out of any vehicle you are in, walk into the registration waypoint on foot and try to join the race.  A message in the chat window will tell you that you cannot join the race and list which vehicles are allowed**.

   ---
   - #### RACE TYPE 4 - Vehicles change randomly every lap

      - You will need to create or load a vehicle list before registering the race.  After completing a lap of the race, the racer's vehicle will randomly change to one of the vehicles in the vehicle list.  Buy-in amounts will be set to 0 even if an amount was specified.

      - Type **`/races register 100 2 180 no rand`** to create a race where vehicles change randomly every lap to one selected from your vehicle list.  The number of laps must be two or more, otherwise you will not be able to register the race.  Note that since this is a random vehicle race, the buy-in amount will be set to 0 even though 100 was specified.

      - There are four parameters you can specify after **`rand`** in the command above.  They are '**class**', '**start**', '**recur**' and '**order**' in that order.  Each parameter has a default behavior.  Type a period ('.') for a parameter to specify the default behavior.  You do not have to specify any parameters after **`rand`** if you want the default behavior for all parameters, .

         > The '**class**' parameter specifies what class of vehicle will be chosen from the vehicle list.  The class is a number from 0 to 22.  If there are no vehicles of the specified class in the vehicle list, then you will not be able to register the race.  Vehicles that are not of the specifed class in the vehicle list will be ignored.  Racers who want to join the race must be in a vehicle of the specified class, otherwise they will not be able to join the race.  The default behavior is that any class may be used.

         > The '**start**' parameter specifies what vehicle every racer will use on the first lap.  For example the '**start**' parameter may be 'adder', or 'zentorno', or 'elegy2', etc.  If you specify a class in the '**class**' parameter, the start vehicle must be of that class, otherwise you will not be able to register the race.  The default behavior is that any start vehicle may be used.

         > The '**recur**' parameter value may be 'yes' or 'no'.  If it is 'yes', then vehicles that appeared in previous laps may be used in later laps.  If it is 'no', then vehicles that appeared in previous laps will not be used in later laps.  If you specify 'no', then the number of vehicles in the vehicle list must be at least one less than the number of laps in the race.  If there are multiple vehicles of the same model in the vehicle list, it may be used as many times as it appears in the vehicle list.  If you don't want the same model to appear multiple times, then make sure only one vehicle of that model is in the vehicle list.  The default behavior is that vehicles that appeared in previous laps may be used in later laps.

         > The '**order**' parameter value may be 'yes' or 'no'.  If it is 'yes' then every racer will use the same random vehicle after the same lap number.  For example, every racer's vehicle will change to an 'adder' after lap one, an 'elegy2' after lap two, a 'zentorno' after lap three, etc.  If it is 'no', then every racer may use a different random vehicle after the same lap number.  For example, after lap one, one racer's vehicle changes to an 'adder' and another racer's vehicle changes to an 'elegy2'.  The default behavior is that every racer may use a different random vehicle after the same lap number.

      - Below are examples of the four parameters:
         - Type **`/races register 100 2 180 no rand 0`** to create a race where vehicles change randomly every lap to one selected from your vehicle list that are of **'Compacts'(0)** class.

         - Type **`/races register 100 2 180 no rand . adder`** to create a race where vehicles change randomly every lap to one selected from your vehicle list and racers start in an **`adder`** vehicle.

         - Type **`/races register 100 2 180 no rand . . no`** to create a race where vehicles change randomly every lap to one selected from your vehicle list and vehicles that appeared in previous laps will not be used in later laps.

         - Type **`/races register 100 2 180 no rand . . . yes`** to create a race where vehicles change randomly every lap to one selected from your vehicle list and every racer uses the same random vehicle after the same lap number.

   ---

- To join a race, players will need to move toward the registration waypoint until prompted to join.  The prompt will tell the player who registered the race, if it is an unsaved track or if it is a publicly or privately saved track along with its saved name, the buy-in amount, the number of laps, the DNF timeout, if AI drivers are allowed and other parameters of the race.

- Players who want to join the race will need to have enough funds to pay for the buy-in amount.  All players begin with at least 5000 in their funds.  Type **`/races funds`** to view your funds.

- When prompted to join, type 'E' or press DPAD right to join the race.

- Joining the race will clear any previous waypoints and load the race's track waypoints.  You can only join one race at a time.  If you joined a race and want to join another race, leave your current one first.

- **NOTE THAT YOU WILL NOT SEE A PROMPT TO JOIN A RACE IF YOU ARE EDITING WAYPOINTS.  STOP EDITING FIRST.**

- A player can view the details of the race they joined if they move close enough to the race registration waypoint.

- Type **`/races rivals`** to list all players in the race that you joined.  You will not be able to see players if you have not joined a race.  If you cannot see all the players, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

- Type **`/races leave`** to leave a race you joined.  **IF YOU LEAVE AFTER THE RACE HAS STARTED, YOU WILL DNF.**

- Once everyone who wants to join your registered race have joined, you can start the race.  Multiple races can be started simultaneously by different players.  Type **`/races start 10`** to start the race with a delay of 10 seconds before the actual start.  If you do not specify a delay, the default is 30 seconds.  The minimum delay allowed is 5 seconds.  Any vehicles the players are in will be frozen until after the delay expires.  After the race has started, your race advertisement will be removed from all players.  The position of all human players and AI drivers will show up as green blips on the minimap and waypoint map.

- The current race waypoint will have a yellow cylinder checkpoint appear in the world.  It will have an arrow indicating the direction of the next waypoint.  If a restricted vehicle or vehicle class was specified at the race registration waypoint, you will need to be in the restricted vehicle or a vehicle of the specified class when passing the waypoint to make the next waypoint appear.  If a restricted vehicle or vehicle class was not specified, you can pass the waypoint in any vehicle or on foot to make the next waypoint appear.  Once you pass the waypoint, it will disappear, a sound will play and the next waypoint will appear in the world.  Only the next three waypoints will be shown on the minimap at a time.  A blue route will be shown in your minimap to the current race waypoint.  Once you pass the current waypoint, it will disappear on the minimap and the next third waypoint along the route will appear on the minimap.  Once you leave or finish the race, all the race waypoints will reappear on the minimap.

- Your current position, lap, waypoint, lap time, best lap time, total time, vehicle name and speed will display.  If someone has already finished the race, a DNF timeout will also appear.

- Type **`/races respawn`** to respawn at the last waypoint you passed in a race.  You can also press 'X' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a PlayStation controller for one second to respawn.  You can only respawn if you are currently in a race.

- After the first racer finishes, there will be a DNF timeout for other racers.  They must finish within the timeout, otherwise they DNF.

- As racers finish, their finishing time, best lap time and the vehicle name they used for their best lap time will be broadcast to players who joined the race.  If a racer DNF's, this will also be broadcast.

- After all racers finish or DNF, the race results will be broadcast to players who joined the race.  Their position, name, finishing time, best lap time and name of the vehicle used for their best lap time will be displayed.  Best lap times will be recorded if the track was a saved track and waypoints were not modified.  Race results are saved to **`resources/races/results_[owner].txt`** where [owner] is the name of the person who registered the race.

- Racers are given prize money after all racers finish or DNF.  At the start of every game session, players start with at least 5000 in their funds.  If you are using the existing **`port.lua`** file, race earnings are not saved between different game sessions.  If you win prize money in one game session, it will not carry over to the next game session.  **`port.lua`** may be ported to a framework that does save funds between different game sessions.  The ESX framework may save race earnings from one game session to the next game session.  A port of the **`port.lua`** file to ESX is in the **`esx/`** folder.  Total race prize money is the sum of all buy-in amounts that all racers paid.  The prize distribution is as follows: 1st - 60%, 2nd - 20%, 3rd - 10%, 4th - 5%, 5th - 3% and lastly, 2% is spread evenly among racers who finished 6th and later.  Racers who DNF will not receive a payout unless all racers DNF.  If all racers DNF, all racers are refunded their buy-in amounts.  If fewer racers finish the race than there are places in the prize distribution, all racers who finished will receive any left over place percentages split evenly among the finishers.  If you wish to distribute the prize money differently, you will need to modify the values of the table named **`dist`** in **`races_server.lua`**.  The declaration and initialization of **`dist`** is

  >**`local dist <const> = {60, 20, 10, 5, 3, 2}`**

   You can change the total number of values (places) in the table.  For the distribution to be valid, the following conditions must be met:  All values in the table **`dist`** must add up to 100.  All values in the table must be 1 or greater.  First place distribution must be greater than or equal to second place distribution.  Second place distribution must be greater than or equal to 3rd place distribution and so on.  If these conditions are not met, a message will be displayed in the server console in red saying that the distribution is invalid.  If the distribution is invalid, players can still race.  The buy-in amount of the race will be set to 0 even if an amount was specified.

- Type **`/races results`** to look at the race results again.  If you cannot see all the results, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

- Type **`/races spawn elegy2`** to spawn an **`elegy2`** vehicle.  If you are in a vehicle when you spawn the new one, it will be replaced by the new one.  If you do not specify a vehicle model, the default is **`adder`**.  You cannot spawn a vehicle if you are joining a race or in a race that has started.  You will need to respawn to get a new vehicle.  A list of vehicles you can spawn are listed in the **`vehicles.json`** file.  Some vehicles may not be spawnable and there may be some that are missing.

- Type **`/races lvehicles`** to list all vehicles that can be used for any race.  Type **`/races lvehicles 0`** to list all **'Compacts'(0)** class vehicles.  The vehicles displayed come from the **`vehicles.json`** file.

- Type **`/races speedo`** to toggle the display of the speedometer.  The speedometer automatically displays when you are in a race that has started and cannot be turned off during the race.  If the speedometer was visible before the race start, it will be visible after you finish or leave the race or if the race was unregistered, otherwise it will not be visible.  The default unit of measurement is 'Imperial'.  Type **`/races speedo (unit)`** where (unit) is either **`imperial`** or **`metric`** if you want to change the unit of measurement.

- Type **`/races funds`** to view your available funds.

- Type **`/races panel`** to show the 'Main' panel.  Type **`/races panel track`** to show the 'Track' panel.  Type **`/races panel ai`** to show the 'AI' panel.  Type **`/races panel list`** to show the 'Vehicle List' panel.  Type **`/races panel register`** to show the 'Register' panel.  All **`/races`** commands have a corresponding button and argument field(s) if needed in these panels.  Results of the commands will show up in another panel as well as in the chat window.  There are buttons near the bottom that will let you switch to another panel if you click them.  To close a panel, type 'Escape' or click the 'Close' button at the bottom.

## SERVER COMMAND DETAILS

- Server commands are typed into the server console.

- Type **`races`** to see the list of available **`races`** commands.

- Type **`races list`** to see the list of public tracks.

- Type **`races export publictrack`** to export the public track saved as **`publictrack`** without best lap times to the file **`resources/races/publictrack.json`**.  You cannot export the track if **`resources/races/publictrack.json`** already exists.  You will need to remove or rename the existing file and then export again.

- Type **`races import mytrack`** to import the track file named **`resources/races/mytrack.json`** into the public tracks list without best lap times.  You cannot import **`mytrack`** if it already exists in the public tracks list.  You will need to rename the file and then import with the new name.

- Type **`races exportwblt publictrack`** to export the public track saved as **`publictrack`** with best lap times to the file **`resources/races/publictrack.json`**.  You cannot export the track if **`resources/races/publictrack.json`** already exists.  You will need to remove or rename the existing file and then export again.

- Type **`races importwblt mytrack`** to import the track file named **`resources/races/mytrack.json`** into the public tracks list with best lap times.  You cannot import **`mytrack`** if it already exists in the public tracks list.  You will need to rename the file and then import with the new name.

## EVENT LOGGING

- If you want to save a log of certain events, change the following line in **`races_server.lua`** from

   >**`local saveLog <const> = false`**

   to

   >**`local saveLog <const> = true`**

- The following events will be logged to **`resources/races/log.txt`**:
   - Exporting a track
   - Importing a track
   - Saving a track
   - Overwriting a track
   - Deleting a track
   - Saving an AI group
   - Overwriting an AI group
   - Deleting an AI group
   - Saving a vehicle list
   - Overwriting a vehicle list
   - Deleting a vehicle list

## ADD-ON VEHICLES

- In the **`vehicles.meta`** file of the add-on vehicle, the model name is between the `<modelName>` and `</modelName>` tags.
- In the following example, the model name is `gemera`:  
   `<modelName>gemera</modelName>`
- If you try to spawn the vehicle using the model name by typing `/races spawn gemera`, the displayed name may show up as `NULL`.
- Do the following steps to fix this:
   - In the **`fxmanifest.lua`** or **`__resource.lua`** file of the add-on vehicle, add the following:
      ```
      client_script {
	      'vehicle_names.lua'
      }
      ```
   - In the same directory as the **`fxmanifest.lua`** or **`__resource.lua`** file of your add-on vehicle, create a file named **`vehicle_names.lua`**.
   - Add the following to the **`vehicle_names.lua`** file:
      ```
      Citizen.CreateThread(function()
	      AddTextEntry('gemera', 'Koenigsegg Gemera')
      end)
      ```
   - `gemera` is the model name and `Koenigsegg Gemera` is the name displayed when you spawn the vehicle.
   - You will need to do this for each add-on vehicle.
   - For a multi-vehicle add-on, you will need to add an `AddTextEntry` line for each vehicle to the `Citizen.CreateThread` function in the **`vehicle_names.lua`** file.
- You should now be able to spawn the vehicle and see its display name instead of `NULL`.
- Add the model name to the **`vehicles.json`** file in json format to make it available for use by the scripts.

## PORTING

- If you wish to port these scripts to a specific framework, such as ESX, you will need to modify the contents of the funds functions **`GetFunds`**, **`SetFunds`**, **`Withdraw`**, **`Deposit`** and **`Remove`** in **`port.lua`** to work for your framework.

- An attempt to port the funds functions to ESX is available in the **`esx/`** folder.  Copy **`esx/port.lua`** and **`esx/fxmanifest.lua`** to your server's **`resources/races/`** folder replacing the existing **`port.lua`** and **`fxmanifest.lua`** files.

## SCREENSHOTS

- Registration waypoint  
   <img src="screenshots/Screenshot%20(1).png" width="800">

- Before race start  
   <img src="screenshots/Screenshot%20(2).png" width="800">

- In race  
   <img src="screenshots/Screenshot%20(3).png" width="800">

- In race  
   <img src="screenshots/Screenshot%20(4).png" width="800">

- Near finish  
   <img src="screenshots/Screenshot%20(5).png" width="800">

- Race results  
   <img src="screenshots/Screenshot%20(6).png" width="800">

- Editing waypoints in waypoint map  
   <img src="screenshots/Screenshot%20(7).png" width="800">

- Editing waypoints in world  
   <img src="screenshots/Screenshot%20(8).png" width="800">

- Main panel  
   <img src="screenshots/Screenshot%20(9).png" width="800">

- Track panel  
   <img src="screenshots/Screenshot%20(10).png" width="800">

- AI panel  
   <img src="screenshots/Screenshot%20(11).png" width="800">

- Vehicle List panel  
   <img src="screenshots/Screenshot%20(12).png" width="800">

- Register panel  
   <img src="screenshots/Screenshot%20(13).png" width="800">

## VIDEOS

- [Point-to-point race](https://youtu.be/K8pEdsXJRtc)

- [Multi-lap race](https://youtu.be/TKibGh_11FA)

- [Multi-lap random vehicle race](https://youtu.be/Cwtz6t8Q82E)

- [Multi-lap race with AI drivers](https://youtu.be/ADkaNMvSFeM)

- [How to edit and manage tracks](https://youtu.be/FAwoplFK4GE)

- [How to edit and manage AI groups](https://youtu.be/m8FN5P5jXeI)

- [How to edit and manage vehicle lists](https://youtu.be/Lma8u3bxxuI)

- [How to register a race](https://youtu.be/ut6i73e9XWY)

- [How to register random vehicle races using the (recur) and (order) paramaters](https://youtu.be/MZUtaTSatuE)

## LICENSE

Copyright (c) 2024, Neil J. Tan  
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

## RECENT CHANGES AFFECTING PAST VERSIONS

- Removed player permissions code.  Code was way more complicated than what it was worth.  It is possible for the same player to join a server using different names.  It is also possible for different players to join a server using the same name.

- Removed **`updateRaceData`** and **`updateTrack`** server commands.

- **`raceData.json`** has been renamed to **`trackData.json`**.
   - Users who want to keep their older **`raceData.json`** data should rename the file to **`trackData.json`**.

- Modified **`aiGroupData.json`**: changed field name **`'vehicleHash'`** to **`'model'`** in saveGrp and overwriteGrp functions.
   - Uers who want to keep their older **`aiGroupData.json`** data should replace every instance of **`'vehicleHash'`** with **`'model'`** in **`aiGroupData.json`**.

- Converted **`vehicles.txt`** to json format and saved as **`vehicles.json`**.
   - Users who added vehicles to the **`vehicles.txt`** file and want to preserve that data should add the vehicles to the **`vehicles.json`** file in json format.

- Disabled spawn command when player is joining a race or player is in a race.
   - Players must respawn if they want a new vehicle.

- Added requirement that random vehicle races must be at least 2 laps.

## CHANGE NOTES
- 2024-03-14
   - races_client.lua and races_server.lua
      - flattened nested if statements for better readability
      - renamed 'races:allVehicles' trigger/event handler to 'races:initAllVehicles'
      - renamed 'races:trackNames' trigger/event handler to 'races:updateTrackNames'
      - renamed 'races:aiGrpNames' trigger/event handler to 'races:updateAiGrpNames'
      - renamed 'races:listNames' trigger/event handler to 'races:updateListNames'
      - replaced boolean arguments 'isPublic' with string arguments 'access' = {pub, pvt}
      - added random vehicle race option 'recur' = {yes, no}
         - if 'yes' (default) then a vehicle that appeared in a previous lap may be used in later laps
         - if 'no' then a vehicle that appeared in a previous lap is not used in later laps
      - added random vehicle race option 'order' = {yes, no}
         - if 'no' (default) then all racers may switch to a different random vehicle after the same lap number
         - if 'yes' then all racers switch to the same random vehicle after the same lap number
      - moved 'access', 'trackName', 'buyin', 'laps', 'timeout' and 'allowAI' into 'rdata' table when triggering/handline 'races:register' event
      - added 'owner' and 'className' to 'rdata' table when triggering/handling 'races:register' event
      - added initializer for all panel drop down lists
      - added requirement that random vehicle races must be at least 2 laps
      - vehicle list is copied for each AI driver instead of having one vehicle list for all AI because of new race options
      - when anyone saves or deletes a public track, AI group or vehicle list, everyone's corresponding dropdown lists are updated if they have a panel open

   - races_client.lua
      - renamed 'raceState' variable to 'state'
      - renamed 'starts' table to 'races'
      - renamed 'waypointCoord' to 'destCoord'
      - renamed 'finishCheckpoint' to 'checkeredFlagCheckpoint'
      - renamed 'midBlipColor' to 'numberedBlipColor'
      - renamed 'midSprite' to 'numberedSprite'
      - renamed 'midCheckpoint' to 'numberedCheckpoint'
      - renamed 'timeoutStart' to 'DNFTimeoutStart'
      - renamed 'aiState.rtype' to 'aiState.raceType'
      - renamed 'aiState.svehicle' to aiState.startVehicle'
      - renamed 'aiState.timeoutStart' to 'aiState.DNFTimeoutStart'
      - renamed 'aiState.drivers[name].vehicleList' to 'aiState.drivers[name].raceVehicleList'
      - renamed 'aiState.drivers[name].currentWP' to 'aiState.drivers[name].currentWaypoint'
      - renamed 'removeRacerBlipGT' function to 'removeAllRacerBlipGT'
      - removed 'allVehiclesHTML' variable
      - removed 'vehicleInList' function
      - removed 'currentColorPri', 'currentColorSec', 'currentColorPearl' and 'currentColorWheel' variables
      - removed 'deleteRegistrationPoint' function because it was too short
      - removed 'restoreBlips' function because it was too short
      - removed 'deleteWaypointBlips' function because it was too short
      - removed NUI callback 'show'
      - replaced boolean variable 'isPublicTrack' with string variable 'trackAccess' = {pub, pvt}
      - replaced 'customClassVehicleList' and 'randomVehicleList' with 'raceVehicleList'
      - replaced 'startFinishSprite', 'startSprite' and 'finishSprite' with 'checkeredFlagSprite'
      - added 'copyTable' function to copy vehicle lists for AI and for 'register' function
      - added 'loadModel' function for use by 'switchVehicle', 'respawnAI' and 'spawnAIDriver' functions
      - added 'races:deleteAllRacers' event handler for use when unregistering
      - use GetNetworkTimeAccurate instead of GetGameTimer so all player times are synchronized
      - set checkpoint types based on game build number
      - fixed bug in 'deleteDriver' function when AI was added, but not spawned
      - when in a race, heading of player or AI is recorded at last waypoint passed
         - if player or AI respawns, player or AI spawns at last waypoint passed and heading is set to last recorded heading
      - print long name of original vehicle in 'listAIDrivers' function instead of best lap vehicle name
      - show model and long names of vehicles in 'lvehicles' function
      - added vehicle long names to vehicle model lists used in panels
      - make sure numerical command arguments are integers and not floating point numbers
      - add all AI in 'races:loadGrp' event handler even if unable to spawn vehicle
      - in normal and random vehicle races, if player is in a vehicle, they must be driver of vehicle to make next checkpoint appear
      - in any class(-1 to 22) race, player must be in original model vehicle after joining race and be driver of vehicle to make next checkpoint appear
      - in restricted vehicle races, player must be in restricted model vehicle and be driver of vehicle to make next checkpoint appear
      - if speedometer is visible before race start, it is visible after race finish, otherwise it is not visible
         - player cannot turn off speedometer if in a race
      - vehicle class names are retrieved programatically instead of being hardcoded
         - 'getClassName' function uses GetLabelText("VEH_CLASS_" .. vclass) to retrieve class name
         - added class 'Open Wheel'(22)
      - reworked player respawn logic based on race type
      - reworked logic used to determine if player has passed waypoint in race based on race type
      - if player is joined to a race and moves inside the race registration waypoint, player will be shown race details
      - eliminated possible race condition with spawning start vehicle in random vehicle races
      - eliminated possible race condition with destCoord when calculating position in race
      - in register panel, if player selects random vehicle race and sets class, start vehicle list updates with vehicles in that class
      - decreased stop range in TaskVehicleDriveToCoord because AI does not get close enough to waypoint to make next waypoint appear if AI is in a bulldozer

   - races_server.lua
      - added command to list public tracks in server console
      - added function 'getTrackNames' for use in 'races:save', 'races:delete' and 'races:list' event handlers
      - added function 'getGrpNames' for use in 'races:saveGrp', 'races:deleteGrp' and 'races:listGrps' event handlers
      - added function 'getListNames' for use in 'races:saveLst', 'races:deleteLst' and 'races:listLsts' event handlers
      - removed most validity checks from 'races:register' event handler since validity checks are performed before event is triggered
      - removed 'defaultRadius' variable
      - removed 'races:trackNames', 'races:aiGrpNames' and 'races:listNames' event handlers
      - removed 'getClassName' function

   - index.html
      - added 'recur' and 'order' fields
      - added separate vehicle class field for random vehicle races
      - use original vehicle class field for vehicle class races
      - added confirm panel

   - index.css
      - added 'recur' and 'order' fields
      - added separate vehicle class field for random vehicle races
      - use original vehicle class field for vehicle class races
      - removed width paramaters for vehicle lists
      - added confirm panel fields

   - index.js
      - added 'recur' and 'order' fields
      - added separate vehicle class field for random vehicle races
      - use original vehicle class field for vehicle class races
      - added initializer for all panel drop down lists
      - all drop down list fields retain their last selected values unless they recently had items added to or removed from them
      - added confirmation dialog panel for overwriting or deleting tracks, AI groups and vehicle lists
      - guessing that window "message" event listener needs time to set up during client initialization before servicing events
         - if SendNUIMessage's are sent too early, they would often not be processed
         - e.g. tried SendNUIMessage with 'action' = 'init' at client startup and it would often not be processed
            - resulted in panel drop down lists not being populated
            - executing Citizen.Wait(2000) in 'races:init' event handler on server would 'fix' this issue
         - decided to initialize panel drop down lists when any panel is first shown

   - vehicles.json
      - added 52 vehicles'

   - updated ESX version of `port.lua` and added ESX version of `fxmanifest.lua` for latest ESX version
