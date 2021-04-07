--[[

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

--]]

local STATE_IDLE = 0
local STATE_EDITING = 1
local STATE_JOINING = 2
local STATE_RACING = 3
local raceState = STATE_IDLE

local registerBlipColor =  2
local selectedBlipColor = 1
local blipColor = 38
local blipRouteColor = 18

local lastSelectedWaypoint = 0

local waypoints = {} -- blip - race waypoints
local raceLaps = -1 -- number of laps in current race
local currentLap = -1
local currentWaypoint = -1
local raceIndex = -1 -- index of race player has joined
local raceStart = -1 -- start time of race before delay
local raceDelay = -1  -- delay before official start of race

local position = -1 -- position in race out of numPlayers players
local numPlayers = -1 -- number of players in race - no DNF players included

local lapTimeStart = -1 -- start time of current lap
local bestLapTime = -1 -- best lap time

local numWaypoints = -1 -- number of waypoints player has passed
local playerFinishTime = -1 -- finish time of player or -1 for DNF

local raceCheckpoint
local checkpointDeleted = true

local DNFTimeout = -1 -- DNF timeout after first player finishes the race
local beginDNFTimeout = false
local timeoutStart = -1 -- start time of DNF timeout

local starts = {} -- blip, checkpoint - registration points

local results = {} -- player name, finish time

local frozen = true

--[[
edit start: STATE_IDLE
edit stop: STATE_EDITING
clear: STATE_IDLE, STATE_EDITING
load/loadPublic: STATE_IDLE, STATE_EDITING
save/savePublic: STATE_IDLE, STATE_EDITING, STATE_JOINING, STATE_RACING
overwrite/overwritePublic: STATE_IDLE, STATE_EDITING, STATE_JOINING, STATE_RACING
delete/deletePublic: STATE_IDLE, STATE_EDITING, STATE_JOINING, STATE_RACING
list/listPublic: STATE_IDLE, STATE_EDITING, STATE_JOINING, STATE_RACING
register: STATE_IDLE
unregister: STATE_IDLE, STATE_EDITING, STATE_JOINING, STATE_RACING
[race join]: STATE_IDLE
leave: STATE_JOINING, STATE_RACING
start: STATE_IDLE, STATE_EDITING, STATE_JOINING, STATE_RACING
results: STATE_IDLE, STATE_EDITING, STATE_JOINING, STATE_RACING
--]]

RegisterCommand("races", function(_, args)
---[[
    if "edit" == args[1] then
        if STATE_IDLE == raceState then
            raceState = STATE_EDITING
            lastSelectedWaypoint = 0
            SetWaypointOff()
            notifyPlayer("Editing started")
        elseif STATE_EDITING == raceState then
            raceState = STATE_IDLE
            if lastSelectedWaypoint > 0 then
                SetBlipColour(waypoints[lastSelectedWaypoint], blipColor)
                lastSelectedWaypoint = 0
            end
            notifyPlayer("Editing stopped")
        else
            notifyPlayer("Cannot edit waypoints.  Leave race first.")
        end
--]]
--[[
        if "start" == args[2] then
            if STATE_IDLE == raceState then
                raceState = STATE_EDITING
                lastSelectedWaypoint = 0
                SetWaypointOff()
                notifyPlayer("Editing started")
            elseif STATE_EDITING == raceState then
                notifyPlayer("Editing already started")
            else
                notifyPlayer("Cannot edit.  Leave race first.")
            end
        elseif "stop" == args[2] then
            if STATE_EDITING == raceState then
                raceState = STATE_IDLE
                if lastSelectedWaypoint > 0 then
                    SetBlipColour(waypoints[lastSelectedWaypoint], blipColor)
                    lastSelectedWaypoint = 0
                end
                notifyPlayer("Editing stopped")
            else
                notifyPlayer("Not editing")
            end
        elseif nil == args[2] then
            notifyPlayer("'start' or 'stop' command required")
        else
            notifyPlayer("Invalid edit command")
        end
--]]
    elseif "clear" == args[1] then
        if STATE_IDLE == raceState then
            deleteWaypoints()
        elseif STATE_EDITING == raceState then
            lastSelectedWaypoint = 0
            deleteWaypoints()
        else
            notifyPlayer("Cannot clear.  Leave race first.")
        end
    elseif "load" == args[1] then
        load(false, args[2])
    elseif "loadPublic" == args[1] then
        load(true, args[2])
    elseif "save" == args[1] then
        save(false, args[2])
    elseif "savePublic" == args[1] then
        save(true, args[2])
    elseif "overwrite" == args[1] then
        overwrite(false, args[2])
    elseif "overwritePublic" == args[1] then
        overwrite(true, args[2])
    elseif "delete" == args[1] then
        delete(false, args[2])
    elseif "deletePublic" == args[1] then
        delete(true, args[2])
    elseif "list" == args[1] then
        TriggerServerEvent("races:list", false)
    elseif "listPublic" == args[1] then
        TriggerServerEvent("races:list", true)
    elseif "register" == args[1] then
        local laps = tonumber(args[2]) or 1
        if laps > 0 then
            local timeout = tonumber(args[3]) or (2 * 60)
            if timeout >= 0 then
                if STATE_IDLE == raceState then
                    if #waypoints > 0 then
                        local race = convertWaypoints()
                        TriggerServerEvent("races:register", GetEntityCoords(GetPlayerPed(-1)), laps, timeout, race)
                    else
                        notifyPlayer("No waypoints loaded")
                    end
                elseif STATE_EDITING == raceState then
                    notifyPlayer("Cannot register. Stop editing first.")
                else
                    notifyPlayer("Cannot register. Leave race first.")
                end
            else
                notifyPlayer("Invalid DNF timeout")
            end
        else
            notifyPlayer("Invalid laps number")
        end
    elseif "unregister" == args[1] then
        TriggerServerEvent("races:unregister")
    elseif "leave" == args[1] then
        if STATE_JOINING == raceState or STATE_RACING == raceState then
            TriggerServerEvent("races:leave", raceIndex)
        else
            notifyPlayer("Not joined to any race")
        end
    elseif "start" == args[1] then
        local delay = tonumber(args[2]) or 30
        if delay < 0 then
            notifyPlayer("Invalid delay")
        else
            TriggerServerEvent("races:start", delay)
        end
    elseif "results" == args[1] then
        printResults()
--[[
    elseif "test0" == args[1] then
        local pedCoord = GetEntityCoords(GetPlayerPed(-1))
        local blipCoord = GetBlipCoords(waypoints[1])
        local dist0 = GetDistanceBetweenCoords(pedCoord.x, pedCoord.y, pedCoord.z, blipCoord.x, blipCoord.y, blipCoord.z, true)
        local dist1 = CalculateTravelDistanceBetweenPoints(pedCoord.x, pedCoord.y, pedCoord.z, blipCoord.x, blipCoord.y, blipCoord.z)
        print("dist0 = " .. dist0)
        print("dist1 = " .. dist1)
    elseif "test1" == args[1] then
        TriggerEvent("races:finish", raceIndex, "John Doe", (5 * 60 + 30) * 1000)
--]]
    elseif nil == args[1] then
        notifyPlayer("Command required")
    else
        notifyPlayer("Unknown command")
    end
end)

RegisterNetEvent("races:load")
AddEventHandler("races:load", function(name, race)
    if STATE_IDLE == raceState or STATE_EDITING == raceState then
        loadWaypoints(race)
        notifyPlayer("Loaded '" .. name .. "'")
    else
        notifyPlayer("Ignoring load event.  Currently joined to race.")
    end
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(index, owner, coord)
    local blip = AddBlipForCoord(coord.x, coord.y, coord.z) -- registration blip
    SetBlipColour(blip, registerBlipColor)
    SetBlipAsShortRange(blip, true)

    local checkpoint = CreateCheckpoint(45, coord.x,  coord.y, coord.z, 0, 0, 0, 10.0, 0, 255, 0, 127, 0) -- registration checkpoint
    SetCheckpointCylinderHeight(checkpoint, 10.0, 10.0, 10.0)

    starts[index] = {owner = owner, blip = blip, checkpoint = checkpoint}
end)

RegisterNetEvent("races:unregister")
AddEventHandler("races:unregister", function(index)
    removeRegistrationPoint(index)
    if raceIndex == index then
        if STATE_JOINING == raceState then
            raceState = STATE_IDLE
            notifyPlayer("Race canceled")
        elseif STATE_RACING == raceState then
            raceState = STATE_IDLE
            SetBlipRoute(waypoints[1], true)
            SetBlipRouteColour(waypoints[1], blipRouteColor)
            DeleteCheckpoint(raceCheckpoint) -- delete last checkpoint
            notifyPlayer("Race canceled")
        end
    end
end)

RegisterNetEvent("races:join")
AddEventHandler("races:join", function(index, laps, timeout, race)
    if STATE_IDLE == raceState then
        raceState = STATE_JOINING
        raceIndex = index
        raceLaps = laps
        DNFTimeout = timeout * 1000
        loadWaypoints(race)
        notifyPlayer(("Joined race owned by %s : %d lap(s)"):format(starts[index].owner, laps))
    elseif STATE_EDITING == raceState then
        notifyPlayer("Ignoring race join event.  Currently editing.")
    else
        notifyPlayer("Ignoring race join event.  Already joined to a race.")
    end
end)

RegisterNetEvent("races:leave")
AddEventHandler("races:leave", function()
    if STATE_JOINING == raceState then
        raceState = STATE_IDLE
        notifyPlayer("Left race")
    elseif STATE_RACING == raceState then
        raceState = STATE_IDLE
        SetBlipRoute(waypoints[1], true)
        SetBlipRouteColour(waypoints[1], blipRouteColor)
        DeleteCheckpoint(raceCheckpoint) -- delete last checkpoint
        notifyPlayer("Left race")
    else
        notifyPlayer("Ignoring race leave event.  Not joined to a race.")
    end
end)

RegisterNetEvent("races:start")
AddEventHandler("races:start", function(delay)
    if delay >= 0 then
        if STATE_JOINING == raceState then
            raceState = STATE_RACING
            raceStart = GetGameTimer()
            raceDelay = delay
            lapTimeStart = raceStart + delay * 1000
            bestLapTime = -1
            currentLap = 1
            currentWaypoint = 1
            numWaypoints = #waypoints * (currentLap - 1) + currentWaypoint
            position = -1
            numPlayers = -1
            beginDNFTimeout = false
            results = {}
            checkpointDeleted = true
            notifyPlayer("Race started")
        elseif STATE_RACING == raceState then
            notifyPlayer("Ignoring race start event.  Already in a race.")
        elseif STATE_EDITING == raceState then
            notifyPlayer("Ignoring race start event.  Currently editing.")
        else
            notifyPlayer("Ignoring race start event.  Currently idle.")
        end
    else
        notifyPlayer("Ignoring race start event.  Invalid delay.")
    end
end)

RegisterNetEvent("races:results")
AddEventHandler("races:results", function(raceResults)
    results = raceResults
    printResults()
end)

RegisterNetEvent("races:hide")
AddEventHandler("races:hide", function(index)
    removeRegistrationPoint(index)
end)

RegisterNetEvent("races:finish")
AddEventHandler("races:finish", function(index, playerName, finishTime)
    if raceIndex == index then
        if finishTime < 0 then
            notifyPlayer(playerName .. " did not finish")
        else
            if not beginDNFTimeout then
                beginDNFTimeout = true
                timeoutStart = GetGameTimer()
            end

            local seconds = finishTime / 1000.0
            local minutes = math.floor(seconds / 60.0)
            seconds = seconds - minutes * 60.0
            notifyPlayer(("%s finished in %02d:%05.2f"):format(playerName, minutes, seconds))
        end
    end
end)

RegisterNetEvent("races:report")
AddEventHandler("races:report", function()
    if numWaypoints == #waypoints * (currentLap - 1) + currentWaypoint then -- player has not finished race
        local blipCoord = GetBlipCoords(waypoints[currentWaypoint])
        local pedCoord = GetEntityCoords(GetPlayerPed(-1))
        local dist = CalculateTravelDistanceBetweenPoints(pedCoord.x, pedCoord.y, pedCoord.z, blipCoord.x, blipCoord.y, blipCoord.z)
        TriggerServerEvent("races:report", raceIndex, numWaypoints, dist)
    else -- player has finished race - numWaypoints will be #waypoints * raceLaps + 1
        TriggerServerEvent("races:report", raceIndex, numWaypoints, playerFinishTime)
    end
end)

RegisterNetEvent("races:position")
AddEventHandler("races:position", function(pos, numP)
    position = pos
    numPlayers = numP
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if STATE_RACING == raceState then
            TriggerServerEvent("races:position", raceIndex)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if STATE_EDITING == raceState then
            if IsWaypointActive() then
                local waypoint = GetBlipCoords(GetFirstBlipInfoId(8))
                local _, coord = GetClosestVehicleNode(waypoint.x, waypoint.y, waypoint.z, 1)
                SetWaypointOff()

                local selectedWaypoint = 0
                for index, blip in pairs(waypoints) do
                    local blipCoord = GetBlipCoords(blip)
                    if coord.x == blipCoord.x and coord.y == blipCoord.y and coord.z == blipCoord.z then
                        selectedWaypoint = index
                        break
                    end
                end

                if selectedWaypoint < 1 then -- no existing waypoint selected
                    local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
                    SetBlipAsShortRange(blip, true)

                    if lastSelectedWaypoint < 1 then -- no previous selected waypoint exists, add new waypoint
                        SetBlipColour(blip, blipColor)
                        ShowNumberOnBlip(blip, #waypoints + 1)
                        table.insert(waypoints, blip)
                    else -- previous selected waypoint exists, move previous selected waypoint to new location
                        RemoveBlip(waypoints[lastSelectedWaypoint])
                        table.remove(waypoints, lastSelectedWaypoint)

                        SetBlipColour(blip, selectedBlipColor)
                        ShowNumberOnBlip(blip, lastSelectedWaypoint)
                        table.insert(waypoints, lastSelectedWaypoint, blip)
                    end

                    SetBlipRoute(waypoints[1], true)
                    SetBlipRouteColour(waypoints[1], blipRouteColor)
                else -- existing waypoint selected
                    if lastSelectedWaypoint < 1 then -- no previous selected waypoint exists
                        SetBlipColour(waypoints[selectedWaypoint], selectedBlipColor)
                        lastSelectedWaypoint = selectedWaypoint
                    else -- previous selected waypoint exists
                        if selectedWaypoint ~= lastSelectedWaypoint then -- selected waypoint and previous selected waypoint are different
                            SetBlipColour(waypoints[lastSelectedWaypoint], blipColor)
                            SetBlipColour(waypoints[selectedWaypoint], selectedBlipColor)
                            lastSelectedWaypoint = selectedWaypoint
                        else -- selected waypoint and previous selected waypoint are the same
                            SetBlipColour(waypoints[selectedWaypoint], blipColor)
                            lastSelectedWaypoint = 0
                        end
                    end
                end
            else
                if lastSelectedWaypoint > 0 and IsControlJustReleased(2, 193) then -- space or X button or square button
                    RemoveBlip(waypoints[lastSelectedWaypoint])
                    table.remove(waypoints, lastSelectedWaypoint)
                    for i = lastSelectedWaypoint, #waypoints do
                        ShowNumberOnBlip(waypoints[i], i)
                    end

                    lastSelectedWaypoint = 0

                    if #waypoints > 0 then
                        SetBlipRoute(waypoints[1], true)
                        SetBlipRouteColour(waypoints[1], blipRouteColor)
                    end
                end
            end
        elseif STATE_RACING == raceState then
            local player = GetPlayerPed(-1)
            local currentTime = GetGameTimer()
            local countDown = raceStart + raceDelay * 1000 - currentTime
            if countDown > 0 then
                DrawMsg(0.45, 0.5, ("Race starting in %05.2f seconds"):format(countDown / 1000.0), 0.5)

                if IsPedInAnyVehicle(player, false) then
                    local vehicle = GetVehiclePedIsIn(player, false)
                    FreezeEntityPosition(vehicle, true)
                    frozen = true
                end
            else
                if frozen then
                    if IsPedInAnyVehicle(player, false) then
                        local vehicle = GetVehiclePedIsIn(player, false)
                        FreezeEntityPosition(vehicle, false)
                    end
                    frozen = false
                end

                local blipCoord = GetBlipCoords(waypoints[currentWaypoint])
                if checkpointDeleted then
                    local checkpointType = (currentWaypoint == #waypoints and currentLap == raceLaps) and 9 or 45
                    raceCheckpoint = CreateCheckpoint(checkpointType, blipCoord.x,  blipCoord.y, blipCoord.z, 0, 0, 0, 10.0, 255, 255, 0, 127, 0)
                    SetCheckpointCylinderHeight(raceCheckpoint, 10.0, 10.0, 10.0)
                    checkpointDeleted = false
                end

                if -1 == position then
                    DrawMsg(0.015, 0.575, "Position -- of --", 0.5)
                else
                    DrawMsg(0.015, 0.575, ("Position %d of %d"):format(position, numPlayers), 0.5)
                end

                DrawMsg(0.015, 0.605, ("Lap %d of %d"):format(currentLap, raceLaps), 0.5)

                DrawMsg(0.015, 0.635, ("Waypoint %d of %d"):format(currentWaypoint, #waypoints), 0.5)

                local lapTime = currentTime - lapTimeStart
                local seconds = lapTime / 1000.0
                local minutes = math.floor(seconds / 60.0)
                seconds = seconds - minutes * 60.0
                DrawMsg(0.015, 0.665, ("Lap time %02d:%05.2f"):format(minutes, seconds), 0.5)

                if bestLapTime < 0 then
                    DrawMsg(0.015, 0.695, "Best lap time --:--", 0.5)
                else
                    seconds = bestLapTime / 1000.0
                    minutes = math.floor(seconds / 60.0)
                    seconds = seconds - minutes * 60.0
                    DrawMsg(0.015, 0.695, ("Best lap time %02d:%05.2f"):format(minutes, seconds), 0.5)
                end

                seconds = -countDown / 1000.0
                minutes = math.floor(seconds / 60.0)
                seconds = seconds - minutes * 60.0
                DrawMsg(0.015, 0.725, ("Total time %02d:%05.2f"):format(minutes, seconds), 0.5)

                numWaypoints = #waypoints * (currentLap - 1) + currentWaypoint

                if true == beginDNFTimeout then
                    seconds = (timeoutStart + DNFTimeout - currentTime) / 1000.0
                    if seconds > 0 then
                        minutes = math.floor(seconds / 60.0)
                        seconds = seconds - minutes * 60.0
                        DrawMsg(0.015, 0.755, ("DNF in %02d:%05.2f"):format(minutes, seconds), 0.5)
                    else -- DNF
                        numWaypoints = numWaypoints + 1 -- indicates this player has finished the race
                        playerFinishTime = -1
                        TriggerServerEvent("races:finish", raceIndex, true, -1, playerFinishTime)
                        raceState = STATE_IDLE
                        DeleteCheckpoint(raceCheckpoint)
                        SetBlipRoute(waypoints[1], true)
                        SetBlipRouteColour(waypoints[1], blipRouteColor)
                    end
                end

                if STATE_RACING == raceState then
                    local pedCoord = GetEntityCoords(player)
                    if GetDistanceBetweenCoords(pedCoord.x, pedCoord.y, pedCoord.z, blipCoord.x, blipCoord.y, blipCoord.z, true) < 10.0 then

                        DeleteCheckpoint(raceCheckpoint)
                        checkpointDeleted = true

                        if currentWaypoint < #waypoints then
                            currentWaypoint = currentWaypoint + 1
                        else
                            currentWaypoint = 1
                            if currentLap < raceLaps then
                                currentLap = currentLap + 1
                                lapTimeStart = currentTime
                                if bestLapTime < 0 or lapTime < bestLapTime then
                                    bestLapTime = lapTime
                                end
                            else
                                numWaypoints = numWaypoints + 1 -- indicates this player has finished the race
                                playerFinishTime = -countDown
                                TriggerServerEvent("races:finish", raceIndex, true, -1, playerFinishTime)
                                raceState = STATE_IDLE
                            end
                        end

                        SetBlipRoute(waypoints[currentWaypoint], true)
                        SetBlipRouteColour(waypoints[currentWaypoint], blipRouteColor)
                    end
                end
            end
        elseif STATE_IDLE == raceState then
            local pedCoord = GetEntityCoords(GetPlayerPed(-1))
            for index, start in pairs(starts) do
                local blipCoord = GetBlipCoords(start.blip)
                if GetDistanceBetweenCoords(pedCoord.x, pedCoord.y, pedCoord.z, blipCoord.x, blipCoord.y, blipCoord.z, true) < 10.0 then
                    DrawMsg(0.45, 0.5, "Press[E] or right DPAD to join race owned by " .. start.owner, 0.5)
                    if IsControlJustReleased(0, 51) then -- E or DPAD RIGHT
                        TriggerServerEvent('races:join', index)
                    end
                    break
                end
            end
        end
    end
end)

function load(public, name)
    if name ~= nil then
        if STATE_IDLE == raceState or STATE_EDITING == raceState then
            lastSelectedWaypoint = 0
            TriggerServerEvent("races:load", public, name)
        else
            notifyPlayer("Cannot load '" .. name .. "'.  Leave race first.")
        end
    else
        notifyPlayer("Name required")
    end
end

function save(public, name)
    if name ~= nil then
        if #waypoints > 0 then
            local race = convertWaypoints()
            TriggerServerEvent("races:save", public, name, race)
        else
            notifyPlayer("No waypoints created")
        end
    else
        notifyPlayer("Name required")
    end
end

function overwrite(public, name)
    if name ~= nil then
        if #waypoints > 0 then
            local race = convertWaypoints()
            TriggerServerEvent("races:overwrite", public, name, race)
        else
            notifyPlayer("No waypoints created")
        end
    else
        notifyPlayer("Name required")
    end
end

function delete(public, name)
    if name ~= nil then
        TriggerServerEvent("races:delete", public, name)
     else
         notifyPlayer("Name required")
     end
end

function loadWaypoints(race)
    deleteWaypoints()
    for index, coord in pairs(race) do
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
        SetBlipColour(blip, blipColor)
        SetBlipAsShortRange(blip, true)
        ShowNumberOnBlip(blip, index)
        waypoints[index] = blip
    end
    if #waypoints > 0 then
        SetBlipRoute(waypoints[1], true)
        SetBlipRouteColour(waypoints[1], blipRouteColor)
    end
end

function deleteWaypoints()
    for _, blip in pairs(waypoints) do
        RemoveBlip(blip)
    end
    waypoints = {}
end

function convertWaypoints()
    local race = {}
    for i = 1, #waypoints do
        local blipCoords = GetBlipCoords(waypoints[i])
        race[i] = {x = blipCoords.x, y = blipCoords.y, z = blipCoords.z}
    end
    return race
end

function removeRegistrationPoint(index)
    if starts[index] ~= nil then
        RemoveBlip(starts[index].blip) -- delete registration blip
        DeleteCheckpoint(starts[index].checkpoint) -- delete registration checkpoint
        starts[index] = nil
    end
end

function printResults()
    if #results > 0 then
        local msg = "Race results:\n"
        for _, result in pairs(results) do
            if result.finishTime < 0 then
                msg = msg .. ("DNF - %s\n"):format(result.playerName)
            else
                local seconds = result.finishTime / 1000.0
                local minutes = math.floor(seconds / 60.0)
                seconds = seconds - minutes * 60.0
                msg = msg .. ("%02d:%05.2f - %s\n"):format(minutes, seconds, result.playerName)
            end
        end
        notifyPlayer(msg)
    else
        notifyPlayer("No results")
    end
end

function notifyPlayer(msg)
    TriggerEvent("chat:addMessage", {
        color = {255, 0, 0},
        multiline = true,
        args = {"[races:client]",  msg}
    })
end

function DrawMsg(x, y, msg, scale)
    SetTextFont(4)
    SetTextScale(0, scale)
    SetTextColour(255, 255, 0, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(msg)
    DrawText(x, y)
end
