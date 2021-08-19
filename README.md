INSTALLATION
------------
Setting up a server:  https://docs.fivem.net/docs/server-manual/setting-up-a-server/

Create a `races/` folder under your server `resources/` folder.  Place `fxmanifest.lua`, `races_client.lua`, `races_server.lua`, `port.lua` and `raceData.json` in the `resources/races/` folder.  Create an `html/` folder under your server `resources/races/` folder.  Place `index.css`, `index.html`, `index.js` and `reset.css` in the `resources/races/html/` folder.  Add `start races` to your `server.cfg` file.

CLIENT COMMANDS
---------------
`/races` - display list of available `/races` commands\
`/races edit` - toggle editing race waypoints\
`/races clear` - clear race waypoints\
`/races reverse` - reverse order of race waypoints\
`/races load [name]` - load race waypoints saved as [name]\
`/races save [name]` - save new race waypoints as [name]\
`/races overwrite [name]` - overwrite existing race waypoints saved as [name]\
`/races delete [name]` - delete race waypoints saved as [name]\
`/races blt [name]` - list 10 best lap times of race saved as [name]\
`/races list` - list saved races\
`/races loadPublic [name]` - load public race waypoints saved as [name]\
`/races savePublic [name]` - save new public race waypoints as [name]\
`/races overwritePublic [name]` - overwrite existing public race waypoints saved as [name]\
`/races deletePublic [name]` - delete public race waypoints saved as [name]\
`/races bltPublic [name]` - list 10 best lap times of public race saved as [name]\
`/races listPublic` - list public saved races\
`/races register (buy-in) (laps) (DNF timeout)` - register your race; (buy-in) defaults to 500; (laps) defaults to 1 lap; (DNF timeout) defaults to 120 seconds\
`/races unregister` - unregister your race\
`/races start (delay)` - start your registered race; (delay) defaults to 30 seconds\
`/races leave` - leave a race that you joined\
`/races rivals` - list competitors in a race that you joined\
`/races results` - view latest race results\
`/races car (name)` - spawn a car; (name) defaults to 'adder'\
`/races speedo` - toggle display of speedometer\
`/races funds` - view available funds\
`/races panel` - display command button panel

**IF YOU DO NOT WANT TO TYPE CHAT COMMANDS, YOU CAN BRING UP A CLICKABLE INTERFACE BY TYPING `/races panel`.**

SERVER COMMANDS
---------------
`races` - display list of available `races` commands\
`races export [name]` - export public race saved as [name] without best lap times to file named '[name].json'\
`races import [name]` - import race file named '[name].json' into public races without best lap times\
`races exportwblt [name]` - export public race saved as [name] with best lap times to file named '[name].json'\
`races importwblt [name]` - import race file named '[name].json' into public races with best lap times

**If you want to preserve races from a previous version of these scripts, you should update `raceData.json` and any exported races by executing the following commands before clients connect to the server to use the new new race data format which includes waypoint radius sizes.**

`races updateRaceData` - update 'raceData.json' to new format\
`races updateRace [name]` - update exported race '[name].json' to new format

SAMPLE RACES
------------
There are six sample races:  '00', '01', '02', '03', '04' and '05' saved in the public races list.  You can load sample race '00' by typing `/races loadPublic 00`.  To race in the loaded race, you need to register by typing `/races register`.  Go to the registration waypoint of the race indicated by a purple circled star blip on the waypoint map and a purple cylinder checkpoint in the world.  When prompted to join, type 'E' or press right DPAD to join.  Wait for other people to join if you want, then type `/races start`.

There are backups of the sample races in the `sampleraces/` folder with the extension '.json'.  Race '00' is backed up as `sampleraces/00.json`.  If any of the sample races were deleted from the public list of races, you can restore them.  Copy the deleted race from the `sampleraces/` folder to the `resources/races/` folder.  In the server console, type `races import 00` to import race '00' back into the public races list.
  
QUICK GUIDE FOR RACE CREATORS
-----------------------------
Type `/races edit` until you see the message 'Editing started'.  Add at least 2 waypoints in the order desired on the waypoint map or in the world by pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a DualShock controller.  Type `/races edit` again to stop editing.  You should see the message 'Editing stopped'.  Save the race if you want by typing `/races save myrace`.  Register your race by typing `/races register`.  At the starting waypoint of the race, a purple circled star blip will appear on the waypoint map and a purple cylinder checkpoint will appear in the world.  This is the registration waypoint.  All players will see the registration waypoint of the race.  Players who want to join, maybe including yourself, need to have enough funds to pay for the buy-in and move close to the registration waypoint until prompted to join.  Once prompted to join, type 'E' or press right DPAD to join.  Once people have joined, you can start the race by typing `/races start`.

QUICK GUIDE FOR RACING
----------------------
Look for purple circled star blips on the waypoint map.  There will be corresponding purple cylinder checkpoints in the world.  The label for the blip in the waypoint map will indicate the player who registered the race and the buy-in amount.  If you have enough funds to pay for the buy-in amount, you can join the race.  You can check how much funds you have by typing `/races funds`.  Get close to the registration waypoint until you are prompted to join.  Type 'E' or press right DPAD to join.  The person who registered the race will be the one to start the race.  Once they start the race, your vehicle will be frozen until the start delay has expired and the race has officially begun.  Follow the checkpoints until the finish.  The results of the race will be broadcast to all racers who joined.  Prize money will be distributed to all finishers.  If you want to see the results again, type `/races results`.

CLIENT COMMAND DETAILS
----------------------
Type `/races` to see the list of available `/races` commands.  If you cannot see all the commands, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

Type `/races edit` until you see the message 'Editing started' to start editing waypoints.  Once you are finished, type `/races edit` until you see the message 'Editing stopped' to stop editing.  You cannot edit waypoints if you are joined to a race.  Leave the race or finish it first.

There are four types of race waypoints and one type of registration waypoint.  Each race waypoint will have a corresponding blip on the waypoint map and, when editing, a corresponding checkpoint in the world.  When you stop editing, all the race waypoint checkpoints in the world will disappear, but all the race waypoint blips on the waypoint map will remain.  A combined start/finish waypoint is a yellow checkered flag blip/checkpoint.  A start waypoint is a green checkered flag blip/checkpoint.  A finish waypoint is a white checkered flag blip/checkpoint.  A waypoint that is not a start and/or finish waypoint is a blue numbered blip/checkpoint.  A registration waypoint is a purple blip/checkpoint.

Clicking a point on the waypoint map is done by moving the point you want to click on the map under the crosshairs and pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a DualShock controller.  'Clicking' a point in the world is done by moving to the point you want to 'click' and pressing 'Enter' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a DualShock controller.

Selecting a waypoint on the waypoint map is done by clicking on an existing blip.  This will turn the blip red.  The corresponding checkpoint in the world will also turn red.  Selecting a waypoint in the world is done by 'clicking' on an existing checkpoint.  This will turn the checkpoint red.  The corresponding blip on the waypoint map will also turn red.

Adding a waypoint is done by clicking on an empty spot on the waypoint map or by 'clicking' on an empty spot in the world.  Waypoints will always be added as the last waypoint.  You cannot make an added waypoint come before an existing waypoint.  The first added waypoint will be a yellow checkered flag blip/checkpoint.  Subsequent added waypoints will be a white checkered flag blip/checkpoint.  Adding a waypoint will add a blip on the map and a corresponding checkpoint in the world.  Placement of a waypoint in the world is unrestricted, while placement of a waypoint on the waypoint map is restricted to paths or roads.  You can place waypoints in the world where you can't in the waypoint map.

You can delete a waypoint by selecting it on the waypoint map or in the world, then pressing 'Spacebar' on a keyboard, 'X' button on an Xbox controller or 'Square' button on a DualShock controller.  Deleting a waypoint will delete the corresponding blip on the waypoint map and the corresponding checkpoint in the world.

You can move an existing waypoint by selecting it on the waypoint map or in the world, then clicking an empty spot on the waypoint map or in the world where you want to move it.  Moving a waypoint will move the corresponding blip on the waypoint map and the corresponding checkpoint in the world.

You can increase or decrease the radius of an existing waypoint only in the world and not in the waypoint map.  There is a minimum and maximum radius limit of a waypoint.  A racer has reached the waypoint if they are within the radius of the waypoint.  To increase the radius of the waypoint, select the waypoint in the world, then press 'Up Arrow' on a keyboard or up DPAD.  To decrease the radius of the waypoint, select the waypoint in the world, then press 'Down Arrow' on a keyboard or down DPAD.

For multi-lap races, the start and finish waypoint must be the same.  Select the finish waypoint first (white checkered flag), then select the start waypoint (green checkered flag).  The start/finish waypoint will become a yellow checkered flag.  The original finish waypoint will become a blue numbered waypoint.

You can separate the start/finish waypoint (yellow checkered flag) in one of two ways.  The first way is by adding a new waypoint.  The second way is by selecting the start/finish waypoint (yellow checkered flag) first, then selecting the highest numbered blue waypoint.

To reverse the order of waypoints, type `/races reverse`.  You cannot reverse waypoints if there are less than 2 waypoints.  You cannot reverse waypoints if you have joined a race. Leave the race or finish it first.

If you are editing waypoints from scratch or you have changed any waypoints of a saved race, then register and start the race, the best lap times will not be saved.  A change to a saved race means adding, deleting, moving, increasing/decreasing radii, combining start/finish, separating start/finish or reversing waypoints.  Changes can only be undone by reloading the saved race.  If you are starting from scratch or made any changes to waypoints, you must save or overwrite the race to allow best lap times to be saved.  **NOTE THAT OVERWRITING A RACE WILL DELETE ITS EXISTING BEST LAP TIMES.**

After you have set your waypoints, you can save them as a race.  Type `/races save myrace` to save the waypoints as 'myrace'.  'myrace' must not exist.  You cannot save unless there are two or more waypoints in the race.  The best lap times for this race will be empty.  If you want to overwrite an existing race named 'myrace', type `/races overwrite myrace`.  **OVERWRITING A RACE WILL DELETE THE BEST LAP TIMES OF THAT RACE.**

To list the races you have saved, type `/races list`.  If you cannot see all the race names, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

If you want to delete a saved race, type `/races delete myrace` to delete 'myrace'.

You can load saved waypoints by typing `/races load myrace` to load a race named 'myrace'.  This will clear any current waypoints and load the saved ones.  You cannot load saved waypoints if you have joined a race.  Leave the race or finish it first.

Type `/races blt myrace` to see the 10 best lap times recorded for 'myrace'.  Best lap times are recorded after a race has finished if it was loaded, saved or overwritten without changing any waypoints after loading, saving or overwriting.  If you cannot see all the best lap times, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

`save`, `overwrite`, `list`, `delete`, `load` and `blt` operate on your private list of races.  No one else will be able to view or modify your private list.  `savePublic`, `overwritePublic`, `listPublic`, `deletePublic`, `loadPublic` and `bltPublic` work like the private versions but operate on the public list of races.  All players have access to the public list of races.

You can clear all waypoints, except registration waypoints, by typing `/races clear`.  You cannot clear waypoints if you have joined a race. Leave the race or finish it first.

After you have set your waypoints, you can register your race.  This will advertise your race to all players.  Your race must have two or more waypoints.  At the starting waypoint of the race, a purple circled star blip will appear on the waypoint map and a purple cylinder checkpoint will appear in the world.  These will be visible to all players.  This is the registration waypoint.  The registration waypoint on the waypoint map will be labeled with the player who registered the race and the buy-in amount.  This allows racers to determine whether or not they can join the race based on the amount of funds they have without having to drive all the way to the starting waypoint.  Type `/races register 100 2 180` to register your race with a buy-in amount of 100, 2 laps and a DNF timeout of 180 seconds.  If you do not indicate the buy-in amount, the default is 500.  If you do not indicate the number of laps, the default is 1 lap.  If you do not indicate the DNF timeout, the default is 120 seconds.  If you set the number of laps to 2 or more, the start and finish waypoints must be the same.  Instructions on how to do this are listed above.  You may only register one race at a time.  If you want to register a new race, but already registered one, you must unregister your current race first. You cannot register a race if you are currently editing waypoints.  Stop editing first.

You can unregister your race by typing `/races unregister`.  This will remove your race advertisement from all players.  This can be done before or after you have started the race.  **IF YOU ALREADY STARTED THE RACE AND THEN UNREGISTER IT, THE RACE WILL BE CANCELED.**

All players begin with 5000 in their funds.  Players who want to join the race, including you, will need to have enough funds to pay for the buy-in amount and be near the purple registration waypoint.  To join the race, type 'E' or press right DPAD.  Joining the race will clear any waypoints you previously set and load the race waypoints.  **NOTE THAT YOU CANNOT JOIN A RACE IF YOU ARE EDITING WAYPOINTS.  STOP EDITING FIRST.**  You can only join one race at a time.  If you want to join another race, leave your current one first.  If you do not join your registered race, you will not see the race results.

To list all competitors in the race that you joined, type `/races rivals`.  You will not be able to see competitors if you have not joined a race.  If you cannot see all the competitors, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

Once everyone who wants to join your registered race have joined, you can start the race.  Type `/races start 10` to start the race with a delay of 10 seconds before the actual start.  If you do not indicate a delay, the default is 30 seconds.  Any vehicles the players are in will be frozen until after the delay expires.  After the race has started, your race advertisement will be removed from all players.

The current race waypoint will have a yellow cylinder checkpoint appear in the world.  It will have an arrow indicating the direction of the next waypoint.  Once you reach the checkpoint, it will disappear, a sound will play and the next checkpoint will appear in the world.  Only the next three waypoints will be shown on the minimap at a time.  A blue route will be shown in your minimap to the current race waypoint.  Once you reach the current waypoint, it will disappear on the minimap and the next third waypoint along the route will appear on the minimap.  Once you leave or finish the race, all the race waypoints will reappear on the minimap.

Your current position, lap, waypoint, lap time, best lap time, total time and speed will display.  If someone has already finished the race, a DNF timeout will also appear.

If you want to leave a race you joined, type `/races leave`.  **IF YOU LEAVE AFTER THE RACE HAS STARTED, YOU WILL DNF.**

After the first racer finishes, there will be a DNF timeout for other racers.  They must finish within the timeout, otherwise they DNF.

As racers finish, their finishing time, best lap time and vehicle name will be broadcast to players who joined the race.  If a racer DNF's, this will also be broadcast.

After all racers finish or DNF, the race results will be broadcast to players who joined the race.  Their position, name, finishing time, best lap time and name of the vehicle they started in will be displayed.  Best lap times will be recorded if the race was a saved race and waypoints were not modified.

Racers are given prize money after all racers finish or DNF.  At the start of every game session, players start with 5000 in their funds.  Race earnings are not saved between different game sessions.  If you win prize money in one game session, it will not carry over to the next game session.  Total race prize money is the sum of all buy-in amounts that all racers paid.  The prize distribution is as follows: 1st 60%, 2nd 20%, 3rd 10%, 4th 5%, 5th 3% and lastly, 2% is spread evenly among racers who finished 6th and later.  Racers who DNF will not receive a payout unless all racers DNF.  If all racers DNF, all racers are refunded their buy-in amounts.  If fewer racers finish the race than there are places in the prize distribution, all racers who finished receive any left over placement percentages split evenly among the finishers.  If you wish to distribute the prize money differently, you will need to modify the values of the table named 'dist' in `races_server.lua`.  The declaration and initialization of 'dist' is `local dist <const> = {60, 20, 10, 5, 3, 2}`.  You can change the total number of values in the table.  For the distribution to be valid, the following conditions must be met:  All values in the table 'dist' must add up to 100.  All values in the table must be 1 or greater.  First place distribution must be greater than or equal to second place distribution.  Second place distribution must be greater than or equal to 3rd place distribution and so on.  If these conditions are not met, a message will be displayed in the server console in red saying that the distribution is invalid.  If the distribution is invalid, players can still race.  Their buy-in amounts will be refunded after all racers finish or DNF.

If you want to look at the race results again, type `/races results`.  If you cannot see all the results, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

To spawn a car, type `/races car elegy2` to spawn an 'elegy2' car.  If you do not indicate a car name, the default is 'adder'.

To toggle the display of the speedometer at any time, type `/races speedo`.  The speedometer automatically displays when you are in a race and disappears when you finish or leave the race.

To view your available funds for race buy-ins, type `/races funds`.

Type `/races panel` to show the command button panel.  All `/races` commands have a corresponding button and argument field(s) if needed.  Replies to the commands will show up in another window as well as in chat.  To close the panel, type 'Escape' or click the 'Close' button at the bottom.

Leaving a race or finishing it does not clear its waypoints.  If you like the race, you can save the waypoints to your private list by typing `/races save nicerace`.

Multiple races can be registered and started simultaneously by different players.

SERVER COMMAND DETAILS
----------------------
Server commands are typed into the server console.  These commands allow server owners to backup individual public races as well as trade races with other server owners.

Type `races` to see the list of available `races` commands.

Type `races export publicrace` to export the public race saved as 'publicrace' without best lap times to the file `resources/races/publicrace.json`.  You cannot export the race if `resources/races/publicrace.json` already exists.  You will need to remove or rename the existing file and then export again.

Type `races import myrace` to import the race file named `resources/races/myrace.json` into the public races list without best lap times.  You cannot import 'myrace' if it already exists in the public races list.  You will need to rename the file and then import with the new name.

Type `races exportwblt publicrace` to export the public race saved as 'publicrace' with best lap times to the file `resources/races/publicrace.json`.  You cannot export the race if `resources/races/publicrace.json` already exists.  You will need to remove or rename the existing file and then export again.

Type `races importwblt myrace` to import the race file named `resources/races/myrace.json` into the public races list with best lap times.  You cannot import 'myrace' if it already exists in the public races list.  You will need to rename the file and then import with the new name.

**If you want to preserve races from a previous version of these scripts, you should update `raceData.json` and any exported races by executing the following commands before clients connect to the server to use the new new race data format which includes waypoint radius sizes.**

Type `races updateRaceData` to update `resources/races/raceData.json` to the new file `resources/races/raceData_updated.json`.  You will need to remove the old `raceData.json` file and then rename `raceData_updated.json` to `raceData.json` to use the new race data format.

Type `races updateRace myrace` to update the exported race `resources/races/myrace.json` to the new file `resources/races/myrace_updated.json`.  You will need to remove the old `myrace.json` file and then rename `myrace_updated.json` to `myrace.json` to use the new race data format.  You will then be able to import the race using the new race data format.

PORTING
-------
If you wish to port these scripts to a specific framework, such as ESX, you will need to modify the contents of the funds functions `GetFunds`, `SetFunds`, `Withdraw` and `Deposit` in `port.lua` to work for your framework.

An attempt to port the funds functions to ESX is available in the `esx/` folder.  Copy `esx/port.lua` to your server's `resources/races/` folder replacing the existing `port.lua` file.  **IF YOU DO NOT WANT TO INITIALIZE YOUR FUNDS TO 5000, COMMENT OUT LINE 499 OF `races_server.lua` BY ADDING `--` TO THE LEFT OF `SetFunds(source, 5000)`.**

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

Command button panel\
<img src="screenshots/Screenshot%20(9).png" width="800">

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
