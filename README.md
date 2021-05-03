INSTALLATION
------------
Setting up a server:  https://docs.fivem.net/docs/server-manual/setting-up-a-server/

Create a 'races' directory under your server 'resources' folder.  Place 'fxmanifest.lua', 'races_client.lua', 'races_server.lua' and 'raceData.json' in the 'races' folder.  Add 'start races' to your 'server.cfg' file.

COMMANDS
--------
`/races` - display list of available races commands\
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
`/races car (name)` - spawn a car; (name) defaults to 'adder'

SAMPLE RACES
------------
There are four sample races:'00', '01', '02' and '03' saved in the public races list.  You can load sample race '00' by typing `/races loadPublic 00`.  To race in the loaded race, you need to register by typing `/races register`.  Go to the starting waypoint of the race indicated by a green circled star on the waypoint map and a green cylinder checkpoint in the world.  When prompted to join, type 'E' or press right DPAD to join.  Wait for other people to join if you want, then type `/races start`.

QUICK GUIDE FOR RACE CREATORS
-----------------------------
Type `/races edit` until you see the message 'Editing started'.  Add waypoints in the order desired.  Type `/races edit` again to stop editing.  You should see the message 'Editing stopped'.  Save the race if you want by typing `/races save myrace`.  Register your race by typing `/races register`.  At the starting waypoint of the race, a green circled star will appear in the waypoint map and a green cylinder checkpoint will appear in the world.  All players will see the starting waypoint of the race.  Racers who want to join, maybe including yourself, need to get close to the starting waypoint until prompted to join.  Once prompted to join, type 'E' or press right DPAD to join.  Once people have joined, you can start the race by typing `/races start`.

QUICK GUIDE FOR RACING
----------------------
Look for green circled stars on the waypoint map.  There will be a corresponding green cylinder checkpoints in the world.  Get close to the starting waypoint until you are prompted to join.  Type 'E' or press right DPAD to join.  The person who registered the race will be the one to start the race.  Once they start the race, your vehicle will be frozen until the start delay has expired and the race has officially begun.  Follow the checkpoints until the finish.  The results of the race will be broadcast to all racers who joined.  If you want to see the results again, type `/races results`.

COMMAND DETAILS
---------------
Type `/races` to see the list of available races commands.  If you cannot see all the commands, type 'T' for chat and use the Page Up and Page Down keys to scroll.  Type Esc when done.

Type `/races edit` until you see the message 'Editing started' to start editing waypoints.  Once you are finished, type `/races edit` until you see the message 'Editing stopped' to stop editing.  You cannot edit waypoints if you are joined to a race.  Leave the race or finish it first.

There will be five types of waypoints on the map.  A yellow checkered flag is a combined start/finish waypoint.  A green checkered flag is the start waypoint.  A white checkered flag is the finish waypoint.  A blue numbered circle is a waypoint along the race route.  A green circled star is a registration point.

Adding a waypoint will always be added as the last waypoint.  You cannot put a waypoint between two waypoints.  You also cannot put a waypoint before another waypoint.  A yellow checkpoint will appear in the world where you added the waypoint.

Clicking an existing waypoint will select it and turn it red.  Clicking it again will unselect it and change it to its original color.  If you have a previously selected waypoint colored red, selecting a different waypoint will turn the different waypoint red and unselect your previous waypoint, changing it back to its original color.  A selected waypoint will have a yellow cylinder checkpoint appear in the world.  You can fine tune its placement by moving it to your desired location.

You can move an existing waypoint by selecting it, then click on where you want to move it.

You can delete a waypoint by selecting it, then press spacebar or the X button on an Xbox controller or the square button on a Dualshock controller.

For multi-lap races, the start and finish waypoint must to be the same.  Select the finish waypoint first(white checkered flag), then select the start waypoint(green checkered flag).  The start/finish waypoint will become a yellow checkered flag.

If you want to separate the start/finish waypoint, add a new waypoint or select the start/finish waypoint first, then select the highest numbered waypoint.

After you have set your waypoints, you can save them as a race.  Type `/races save myrace` to save the waypoints as 'myrace'.  'myrace' must not exist.  You cannot save unless there is more than one waypoint in the race.  If you want to overwrite an existing race, type `/races overwrite myrace`.

To list the races you have saved, type `/races list`.  If you cannot see all the race names, type 'T' for chat and use the Page Up and Page Down keys to scroll.  Type Esc when done.

If you want to delete a saved race, type `/races delete myrace` to delete 'myrace'.

You can load saved waypoints by typing `/races load myrace` to load a race named 'myrace'.  This will clear any current waypoints and load the saved ones.  You cannot load saved waypoints if you have joined a race.  Leave the race or finish it first.

Type `/races blt myrace` to see the 10 best lap times recorded for 'myrace'.  If you cannot see all the best lap times, type 'T' for chat and use the Page Up and Page Down keys to scroll.  Type Esc when done.

`save`, `overwrite`, `list`, `delete`, `load` and `blt` operate on your private list of races.  No one else will be able to modify your private list.  `savePublic`, `overwritePublic`, `listPublic`, `deletePublic`, `loadPublic` and `bltPublic` work like the private versions but operate on the public list of races.  All players have access to the public list of races.

You can clear all waypoints by typing `/races clear`.  You cannot clear waypoints if you have joined a race. Leave the race or finish it first.

After you have set your waypoints, you can register your race.  You cannot register unless there is more than one waypoint in the race.  This will advertise your race to all players.  At the starting waypoint of the race, a green circled star will appear on the map and a green cylinder checkpoint will appear in the world.  These will be visible to all players.  Type `/races register 2 180` to register your race with 2 laps and a DNF timeout of 180 seconds.  If you do not indicate the number of laps, the default is 1 lap.  If you do not indicate the DNF timeout, the default is 120 seconds.  If you set the number of laps to 2 or more, the start and finish waypoints must be the same.  You may only register one race at a time.  If you want to register a new race, but already registered one, you must unregister your current race first. You cannot register a race if you are currently editing waypoints.  Stop editing first.

All players who want to join the race, including you, will need to be near the green starting waypoint.  To join the race, type 'E' or press right DPAD.  This will clear any waypoints you previously set and load the race waypoints.  You cannot join a race if you are editing waypoints.  Stop editing first.  You can only join one race at a time.  If you want to join another race, leave your current one first.  If you do not join your own race, you will not see the race results.

To list all competitors in the race that you joined, type `/races rivals`.  You will not be able to see competitors if you have not joined a race.  If you cannot see all the competitors, type 'T' for chat and use the Page Up and Page Down keys to scroll.  Type Esc when done.

Once everyone who wants to join your registered race have joined, you can start the race.  Type `/races start 10` to start the race with a delay of 10 seconds before the actual start.  If you do not indicate a delay, the default is 30 seconds.  Any vehicles the players are in will be frozen until after the delay expires.  After the race has started, your race advertisement will be removed from all players.

The current race waypoint will have a yellow cylinder checkpoint appear in the world.  A blue route will be shown in your map to the current race waypoint.

Your current position, lap, waypoint, lap time, best lap time, total time and speed will display.  If someone has already finished the race, a DNF timeout will also appear.

After the first racer finishes, there will be a DNF timeout for other racers.  They must finish within the timeout, otherwise they DNF.

As racers finish, their finishing time, best lap time and vehicle name will be broadcast to players who joined the race.  If a racer DNF's, this will also be broadcast.

After all racers finish, the race results will be broadcast to players who joined the race.

If you want to look at the race results again, type `/races results`.  If you cannot see all the results, type 'T' for chat and use the Page Up and Page Down keys to scroll.  Type Esc when done.

You can unregister your previously registered race by typing `/races unregister`.  This will remove your race advertisement from all players.  This can be done before or after you have started the race.  If you already started the race, it will be canceled.

If you want to leave a race you joined, type `/races leave`.  If you leave after the race has started you will DNF.

To toggle the display of the speedometer, type `/races speedo`.

To spawn a car, type `/races car elegy2` to spawn an 'elegy2' car.  If you do not indicate a car name, the default is 'adder'.

Leaving a race or finishing it does not clear its waypoints.  If you like the race, you can save it by typing `/races save nicerace`.

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

Editing waypoints\
<img src="screenshots/Screenshot%20(7).png" width="800">

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
