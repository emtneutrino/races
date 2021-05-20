INSTALLATION
------------
Setting up a server:  https://docs.fivem.net/docs/server-manual/setting-up-a-server/

Create a `races/` directory under your server `resources/` folder.  Place `fxmanifest.lua`, `races_client.lua`, `races_server.lua` and `raceData.json` in the `resources/races/` folder.  Create an `html/` directory under `resources/races/`.  Place `index.css`, `index.html`, `index.js` and `reset.css` in the `resources/races/html/` folder.  Add `start races` to your `server.cfg` file.

COMMANDS
--------
`/races` - display list of available `/races` commands\
`/races edit` - toggle editing race waypoints\
`/races clear` - clear race waypoints\
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
`/races register (laps) (DNF timeout)` - register your race; (laps) defaults to 1 lap; (DNF timeout) defaults to 120 seconds\
`/races unregister` - unregister your race\
`/races leave` - leave a race that you joined\
`/races rivals` - list competitors in a race that you joined\
`/races start (delay)` - start your registered race; (delay) defaults to 30 seconds\
`/races results` - list latest race results\
`/races speedo` - toggle display of speedometer\
`/races car (name)` - spawn a car; (name) defaults to 'adder'\
`/races panel` - display command button panel

**IF YOU DO NOT WANT TO TYPE CHAT COMMANDS, YOU CAN BRING UP A CLICKABLE INTERFACE BY TYPING `/races panel`.**

SAMPLE RACES
------------
There are six sample races:  '00', '01', '02', '03', '04' and '05' saved in the public races list.  You can load sample race '00' by typing `/races loadPublic 00`.  To race in the loaded race, you need to register by typing `/races register`.  Go to the registration waypoint of the race indicated by a purple circled star blip on the waypoint map and a purple cylinder checkpoint in the world.  When prompted to join, type 'E' or press right DPAD to join.  Wait for other people to join if you want, then type `/races start`.

QUICK GUIDE FOR RACE CREATORS
-----------------------------
Type `/races edit` until you see the message 'Editing started'.  Add at least 2 waypoints in the order desired.  Type `/races edit` again to stop editing.  You should see the message 'Editing stopped'.  Save the race if you want by typing `/races save myrace`.  Register your race by typing `/races register`.  At the starting waypoint of the race, a purple circled star blip will appear on the waypoint map and a purple cylinder checkpoint will appear in the world.  This is the registration waypoint.  All players will see the registration waypoint of the race.  Racers who want to join, maybe including yourself, need to get close to the registration waypoint until prompted to join.  Once prompted to join, type 'E' or press right DPAD to join.  Once people have joined, you can start the race by typing `/races start`.

QUICK GUIDE FOR RACING
----------------------
Look for purple circled star blips on the waypoint map.  There will be corresponding purple cylinder checkpoints in the world.  Get close to the registration waypoint until you are prompted to join.  Type 'E' or press right DPAD to join.  The person who registered the race will be the one to start the race.  Once they start the race, your vehicle will be frozen until the start delay has expired and the race has officially begun.  Follow the checkpoints until the finish.  The results of the race will be broadcast to all racers who joined.  If you want to see the results again, type `/races results`.

COMMAND DETAILS
---------------
Type `/races` to see the list of available `/races` commands.  If you cannot see all the commands, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

Type `/races edit` until you see the message 'Editing started' to start editing waypoints.  Once you are finished, type `/races edit` until you see the message 'Editing stopped' to stop editing.  You cannot edit waypoints if you are joined to a race.  Leave the race or finish it first.

There are five types of waypoints.  Each waypoint will have a blip on the map and, when editing, a corresponding checkpoint in the world.  When you stop editing, all the checkpoints will disappear, but all the blips on the map will remain.  A combined start/finish waypoint is a yellow checkered flag blip/checkpoint.  A start waypoint is a green checkered flag blip/checkpoint.  A finish waypoint is a white checkered flag blip/checkpoint.  A waypoint that is not a start and/or finish waypoint is a blue numbered blip/checkpoint.  A registration waypoint is a purple blip/checkpoint which will remain even when editing is stopped.

Clicking on the waypoint map is done by moving the crosshairs on the map and pressing 'Left Shift' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a DualShock controller.  'Clicking' in the world is done by moving to the spot you want to 'click' and pressing 'Left Shift' on a keyboard, 'A' button on an Xbox controller or 'Cross' button on a DualShock controller.

Selecting a waypoint on the map is done by clicking on an existing blip.  This will turn the blip red.  The corresponding checkpoint in the world will also turn red.  Selecting a waypoint in the world is done by 'clicking' on an existing checkpoint.  This will turn the checkpoint red.  The corresponding blip on the map will also turn red.

Adding a waypoint is done by clicking on an empty spot on the waypoint map or by 'clicking' on an empty spot in the world.  Waypoints will always be added as the last waypoint.  You cannot make an added waypoint come before an existing waypoint.  The first added waypoint will be a yellow checkered flag blip/checkpoint.  Subsequent added waypoints will be a white checkered flag blip/checkpoint.  Adding a waypoint will add a blip on the map and a corresponding checkpoint in the world.  Placement of a waypoint in the world is finer grained than adding a waypoint on the waypoint map.  You can place waypoints in the world where you can't in the waypoint map.

You can move an existing blip on the map by selecting it, then clicking an empty spot where you want to move it.  This will also move the corresponding checkpoint in the world.  You can move a checkpoint in the world by selecting it, then 'clicking' on an empty spot where you want to move it.  This will also move the corresponding blip on the map.

You can delete a waypoint by selecting it, then pressing 'Spacebar' on a keyboard, 'X' button on an Xbox controller or 'Square' button on a DualShock controller.

For multi-lap races, the start and finish waypoint must to be the same.  Select the finish waypoint first (white checkered flag), then select the start waypoint (green checkered flag).  The start/finish waypoint will become a yellow checkered flag.

You can separate the start/finish waypoint (yellow checkered flag) in one of two ways.  The first way is by adding a new waypoint.  The second way is by selecting the start/finish waypoint (yellow checkered flag) first, then selecting the highest numbered blue waypoint.

If you are editing waypoints from scratch or you have changed any waypoints of a saved race, then register and start a race, the best lap times will not be saved.  A change to a saved race means adding, deleting, moving, combining start/finish or separating start/finish waypoints.  Changes can only be undone by reloading the saved race.  If you are starting from scratch or made any changes, you must save or overwrite the race to allow best lap times to be saved.  **NOTE THAT OVERWRITING A RACE WILL DELETE ITS EXISTING BEST LAP TIMES.**

After you have set your waypoints, you can save them as a race.  Type `/races save myrace` to save the waypoints as 'myrace'.  'myrace' must not exist.  You cannot save unless there are two or more waypoints in the race.  The best lap times for this race will be empty.  If you want to overwrite an existing race, type `/races overwrite myrace`.  **OVERWRITING A RACE WILL DELETE THE BEST LAP TIMES OF THAT RACE.**

To list the races you have saved, type `/races list`.  If you cannot see all the race names, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

If you want to delete a saved race, type `/races delete myrace` to delete 'myrace'.

You can load saved waypoints by typing `/races load myrace` to load a race named 'myrace'.  This will clear any current waypoints and load the saved ones.  You cannot load saved waypoints if you have joined a race.  Leave the race or finish it first.

Type `/races blt myrace` to see the 10 best lap times recorded for 'myrace'.  Best lap times are recorded after a race has finished if it was loaded, saved or overwritten without changing any waypoints after loading, saving or overwriting.  If you cannot see all the best lap times, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

`save`, `overwrite`, `list`, `delete`, `load` and `blt` operate on your private list of races.  No one else will be able to view or modify your private list.  `savePublic`, `overwritePublic`, `listPublic`, `deletePublic`, `loadPublic` and `bltPublic` work like the private versions but operate on the public list of races.  All players have access to the public list of races.

You can clear all waypoints, except registration waypoints, by typing `/races clear`.  You cannot clear waypoints if you have joined a race. Leave the race or finish it first.

After you have set your waypoints, you can register your race.  You cannot register your race unless there are two or more waypoints in the race.  This will advertise your race to all players.  At the starting waypoint of the race, a purple circled star will appear on the map and a purple cylinder checkpoint will appear in the world.  This is the registration waypoint.  These will be visible to all players.  Type `/races register 2 180` to register your race with 2 laps and a DNF timeout of 180 seconds.  If you do not indicate the number of laps, the default is 1 lap.  If you do not indicate the DNF timeout, the default is 120 seconds.  If you set the number of laps to 2 or more, the start and finish waypoints must be the same.  You may only register one race at a time.  If you want to register a new race, but already registered one, you must unregister your current race first. You cannot register a race if you are currently editing waypoints.  Stop editing first.

All players who want to join the race, including you, will need to be near the purple registration waypoint.  To join the race, type 'E' or press right DPAD.  This will clear any waypoints you previously set and load the race waypoints.  **NOTE THAT YOU CANNOT JOIN A RACE IF YOU ARE EDITING WAYPOINTS.  STOP EDITING FIRST.**  You can only join one race at a time.  If you want to join another race, leave your current one first.  If you do not join your registered race, you will not see the race results.

To list all competitors in the race that you joined, type `/races rivals`.  You will not be able to see competitors if you have not joined a race.  If you cannot see all the competitors, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

Once everyone who wants to join your registered race have joined, you can start the race.  Type `/races start 10` to start the race with a delay of 10 seconds before the actual start.  If you do not indicate a delay, the default is 30 seconds.  Any vehicles the players are in will be frozen until after the delay expires.  After the race has started, your race advertisement will be removed from all players.

The current race waypoint will have a yellow cylinder checkpoint appear in the world.  Only the next three waypoints will be shown on the minimap at a time.  A blue route will be shown in your map to the current race waypoint.  Once you reach the current waypoint, it will disappear and the next third waypoint along the route will appear.  Once you leave or finish the race, all the race waypoints will reappear.

Your current position, lap, waypoint, lap time, best lap time, total time and speed will display.  If someone has already finished the race, a DNF timeout will also appear.

After the first racer finishes, there will be a DNF timeout for other racers.  They must finish within the timeout, otherwise they DNF.

As racers finish, their finishing time, best lap time and vehicle name will be broadcast to players who joined the race.  If a racer DNF's, this will also be broadcast.

After all racers finish, the race results will be broadcast to players who joined the race.  Their position, name, finishing time, best lap time and name of the vehicle they started in will be displayed.  Best lap times will be recorded if the race was a saved race and waypoints were not modified.

If you want to look at the race results again, type `/races results`.  If you cannot see all the results, type 'T' for chat and use the 'Page Up' and 'Page Down' keys to scroll.  Type 'Esc' when done.

You can unregister your previously registered race by typing `/races unregister`.  This will remove your race advertisement from all players.  This can be done before or after you have started the race.  **IF YOU ALREADY STARTED THE RACE AND THEN UNREGISTER IT, THE RACE WILL BE CANCELED.**

If you want to leave a race you joined, type `/races leave`.  **IF YOU LEAVE AFTER THE RACE HAS STARTED, YOU WILL DNF.**

To toggle the display of the speedometer, type `/races speedo`.  The speedometer automatically displays when you are in a race and disappears when you finish or leave the race.

To spawn a car, type `/races car elegy2` to spawn an 'elegy2' car.  If you do not indicate a car name, the default is 'adder'.

Type `/races panel` to show the command button panel.  All `/races` commands have a corresponding button and argument field(s) if needed.  Replies to the commands will show up in another window as well as in chat.  To close the panel, type 'Escape' or click the 'Close' button at the bottom.

Leaving a race or finishing it does not clear its waypoints.  If you like the race, you can save the waypoints to your private list by typing `/races save nicerace`.

Multiple races can be registered and started simultaneously by different players.

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
