INSTALLATION
------------
Setting up a server:  https://docs.fivem.net/docs/server-manual/setting-up-a-server/

Create a 'races' directory under your server 'resources' folder.  Place 'fxmanifest.lua', 'races_client.lua', 'races_server.lua' and 'raceData.txt' in the 'races' folder.  Add 'start races' to your 'server.cfg' file.

COMMANDS
--------
/races edit - toggle editing race waypoints
/races clear - clear race waypoints
/races load [name] - load race waypoints saved as [name]
/races save [name] - save new race waypoints as [name]
/races overwrite [name] - overwrite existing race waypoints saved as [name]
/races delete [name] - delete race waypoints saved as [name]
/races list - list saved races
/races loadPublic [name] - load public race waypoints saved as [name]
/races savePublic [name] - save new public race waypoints as [name]
/races overwritePublic [name] - overwrite existing public race waypoints saved as [name]
/races deletePublic [name] - delete public race waypoints saved as [name]
/races listPublic - list public saved races
/races register (laps) (DNF timeout) - register your race; If you do not indicate (laps) or (DNF timeout), the default is 1 lap and 120 secondS DNF timeout
/races unregister - unregister your race
/races leave - leave a race that you joined
/races start (delay) - start your registered race; If you do not indicate (delay), the default is 30 seconds delay
/races results - list latest race results

SAMPLE RACES
------------
There are two sample races:'00' and '01' saved in the public races list.  You can load one by typing '/races loadPublic 00' or '/races loadPubic 01'.  To race in one you need to register by typing '/races register', type 'E' or press right DPAD to join, wait for other people to join if you want, then type '/races start'.

QUICK GUIDE FOR RACE CREATORS
-----------------------------
Type '/races edit' until you see the message 'Editing started'.  Add waypoints in the order desired.  Type '/races edit' again to stop editing.  You should see the message 'Editing stopped'.  Save the race if you want by typing '/races save myrace'.  Register your race by typing '/races register'.  Your location will become the registration point.  A green registration point will appear in the map and a green checkpoint will appear in the world at your location.  All players will see this registration point.  Racers who want to join, maybe including yourself, need to go close to the registration point until prompted to join.  Once prompted to join, press 'E' or right DPAD to join.  Once people have joined, you can start the race by typing '/races start'.

QUICK GUIDE FOR RACING
----------------------
Look for green registration points on the map.  There will be a corresponding green checkpoint in the world.  Get close to the registration point until you are prompted to join.  Press 'E' or right DPAD to join.  The person who registered the race will be the one to start the race.  Once they start the race, your vehicle will be frozen until the start delay has expired and the race has officially begun.  Follow the checkpoints until the finish.  The results of the race will be broadcast to all racers who joined.  If you want to see the results again, type '/races results'.

COMMAND DETAILS
---------------
Type '/races edit' until you see the message 'Editing started' to start editing waypoints.  Once you are finished, type '/races edit' until you see the message 'Editing stopped' to stop editing.  You cannot edit waypoints if you are joined to a race.  Leave the race or finish it first.

Adding a waypoint will always be added as the last waypoint.  You cannot put a waypoint between two waypoints.  You also cannot put a waypoint before another waypoint.

Clicking an existing waypoint will select it and turn it red.  Clicking it again will unselect it and turn it blue.  If you have a previously selected waypoint, selecting a new waypoint will turn the new waypoint red and unselect your previous waypoint, turning it blue.

You can move an existing waypoint by selecting it, then click on where you want to move it.

You can delete a waypoint by selecting it, then press spacebar or the X button on an Xbox controller or the square button on a Dualshock controller.

After you've set your waypoints, you can save them as a race.  Type '/races save myrace' to save the waypoints as 'myrace'.  'myrace' must not exist.  If you want to overwrite an existing race, type '/races overwrite myrace'.

To list the races you have saved, type '/races list'.

If you want to delete a saved race, type '/races delete myrace' to delete 'myrace'.

You can load saved waypoints by typing '/races load myrace' to load a race named 'myrace'.  This will clear any current waypoints and load the saved ones.  You cannot load saved waypoints if you have joined a race.  Leave the race or finish it first.

You can clear all waypoints by typing '/races clear'.  You cannot clear waypoints if you have joined a race. Leave the race or finish it first.

After you've set your waypoints, you can register your race.  This will advertise your race to all players.  A green registration point will appear on the map and a green checkpoint will appear in the world where you registered your race.  These will be visible to all players.  Type '/races register 2 180' to register your race with 2 laps and a DNF timeout of 180 seconds.  If you do not indicate the number of laps, the default is 1 lap.  If you do not indicate the DNF timeout, the default is 120 seconds.  You may only register one race at a time.  If you want to register a new race, but already registered one, you must unregister your current race first. You cannot register a race if you are currently editing waypoints.  Stop editing first.

All players who want to join the race, including you, will need to be near the green register checkpoint.  To join the race, press 'E' or right DPAD.  This will clear any waypoints you previously set and load the race waypoints.  You cannot join a race if you are editing waypoints.  Stop editing first.  You can only join one race at a time.  If you want to join another race, leave your current one first.  If you do not join your own race, you will not see the race results.

Once everyone who wants to join your registered race have joined, you can start the race.  Type '/races start 10' to start the race with a delay of 10 seconds before the actual start.  If you do not indicate a delay, the default is 30 seconds.  Any vehicles the players are in will be frozen until after the delay expires.  After the race has started, your race advertisement will be removed from all players.

The current race waypoint will have a yellow checkpoint appear in the world.  A blue route will be shown in your map to the current race waypoint.

Your current position, lap, waypoint, lap time, best lap time, and total time will display.  If someone has already finished the race, a DNF timeout will also appear.

After the first racer finishes, there will be a DNF timeout for other racers.  They must finish within the timeout, otherwise they DNF.

As racers finish, their finishing time will be broadcast to players who joined the race.  If a racer DNF's, this will also be broadcast.

After all racers finish, the race results will be broadcast to players who joined the race.

If you want to look at the race results again, type '/races results'.

You can unregister your previously registered race by typing '/races unregister'.  This will remove your race advertisement from all players.  This can be done before or after you have started the race.  If you already started the race, it will be canceled.

If you want to leave a race you joined, type '/races leave'.  If you leave after the race has started you will DNF.

Leaving a race or finishing it does not clear its waypoints.  If you like the race, you can save it by typing '/races save nicerace'.

Multiple races can be registered and started simultaneously.

load, save, overwrite, delete and list operate on your private list of races.  No one else will be able to modify your private list.  loadPublic, savePublic, overwritePublic, deletePublic and listPublic work like the private versions but operate on the public list of races.  All players have access to the public list of races.

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
