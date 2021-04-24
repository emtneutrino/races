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
local STATE_REGISTERING = 2
local STATE_RACING = 3
local raceState = STATE_IDLE -- race state

local registerBlipColor = 2 -- green
local selectedBlipColor = 1 -- red
local blipColor = 38 -- dark blue
local blipRouteColor = 18 -- light blue

local lastSelectedWaypoint = 0 -- index of last selected waypoint

local raceIndex = -1 -- index of race player has joined

local waypoints = {} -- blip - race waypoints

local numLaps = -1 -- number of laps in current race
local currentLap = -1 -- current lap

local numWaypointsPassed = -1 -- number of waypoints player has passed
local currentWaypoint = -1 -- current waypoint

local raceStart = -1 -- start time of race before delay
local raceDelay = -1 -- delay before official start of race

local position = -1 -- position in race out of numRacers players
local numRacers = -1 -- number of players in race - no DNF players included

local lapTimeStart = -1 -- start time of current lap
local bestLapTime = -1 -- best lap time

local raceCheckpoint = nil -- race checkpoint in world
local checkpointDeleted = true -- flag indicating if raceCheckpoint has been deleted

local DNFTimeout = -1 -- DNF timeout after first player finishes the race
local beginDNFTimeout = false -- flag indicating if DNF timeout should begin
local timeoutStart = -1 -- start time of DNF timeout

local results = {} -- playerName, finishTime, bestLapTime

local frozen = true -- flag indicating if vehicle is frozen

local starts = {} -- owner, blip, checkpoint - registration points

local speedo = false -- flag indicating if speedometer is displayed

local function notifyPlayer(msg)
    TriggerEvent("chat:addMessage", {
        color = {255, 0, 0},
        multiline = true,
        args = {"[races:client]", msg}
    })
end

local function loadRace(public, name)
    if name ~= nil then
        if STATE_IDLE == raceState or STATE_EDITING == raceState then
            TriggerServerEvent("races:load", public, name)
        else
            notifyPlayer("Cannot load '" .. name .. "'.  Leave race first.")
        end
    else
        notifyPlayer("Name required")
    end
end

local function convertWaypoints()
    local raceWaypoints = {}
    for i = 1, #waypoints do
        raceWaypoints[i] = GetBlipCoords(waypoints[i])
    end
    return raceWaypoints
end

local function saveRace(public, name)
    if name ~= nil then
        if #waypoints > 0 then
            TriggerServerEvent("races:save", public, name, convertWaypoints())
        else
            notifyPlayer("No waypoints created")
        end
    else
        notifyPlayer("Name required")
    end
end

local function overwriteRace(public, name)
    if name ~= nil then
        if #waypoints > 0 then
            TriggerServerEvent("races:overwrite", public, name, convertWaypoints())
        else
            notifyPlayer("No waypoints created")
        end
    else
        notifyPlayer("Name required")
    end
end

local function deleteRace(public, name)
    if name ~= nil then
        TriggerServerEvent("races:delete", public, name)
     else
         notifyPlayer("Name required")
     end
end

local function deleteWaypoints()
    for i = 1, #waypoints do
        RemoveBlip(waypoints[i])
    end
    waypoints = {}
end

local function loadWaypoints(raceWaypoints)
    deleteWaypoints()
    for index, coord in ipairs(raceWaypoints) do
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, blipColor)
        ShowNumberOnBlip(blip, index)
        waypoints[index] = blip
    end
    if #waypoints > 0 then
        SetBlipRoute(waypoints[1], true)
        SetBlipRouteColour(waypoints[1], blipRouteColor)
    end
end

local function removeRegistrationPoint(index)
    if starts[index] ~= nil then
        RemoveBlip(starts[index].blip) -- delete registration blip
        DeleteCheckpoint(starts[index].checkpoint) -- delete registration checkpoint
        starts[index] = nil
    end
end

local function minutesSeconds(milliseconds)
    local seconds = milliseconds / 1000.0
    local minutes = math.floor(seconds / 60.0)
    seconds = seconds - minutes * 60.0
    return minutes, seconds
end

local function printResults()
    if #results > 0 then
        local msg = "Race results:\n"
        for position, result in ipairs(results) do
            msg = msg .. position .. " - "
            if -1 == result.finishTime then
                msg = msg .. "DNF - " .. result.playerName
                if result.bestLapTime >= 0 then
                    local minutes, seconds = minutesSeconds(result.bestLapTime)
                    msg = msg .. (" - best lap %02d:%05.2f"):format(minutes, seconds)
                end
                msg = msg .. "\n"
            else
                local fMinutes, fSeconds = minutesSeconds(result.finishTime)
                local lMinutes, lSeconds = minutesSeconds(result.bestLapTime)
                msg = msg .. ("%02d:%05.2f - %s - best lap %02d:%05.2f\n"):format(fMinutes, fSeconds, result.playerName, lMinutes, lSeconds)
            end
        end
        notifyPlayer(msg)
    else
        notifyPlayer("No results")
    end
end

local function createRaceCheckpoint(checkpointType, coord)
    raceCheckpoint = CreateCheckpoint(checkpointType, coord.x, coord.y, coord.z, 0, 0, 0, 10.0, 255, 255, 0, 127, 0)
    SetCheckpointCylinderHeight(raceCheckpoint, 10.0, 10.0, 10.0)
    checkpointDeleted = false
end

local function drawMsg(x, y, msg, scale)
    SetTextFont(4)
    SetTextScale(0, scale)
    SetTextColour(255, 255, 0, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(msg)
    DrawText(x, y)
end

RegisterCommand("races", function(_, args)
    if nil == args[1] then
        local msg = "\n"
        msg = msg .. "/races - display list of available races commands\n"
        msg = msg .. "/races edit - toggle editing race waypoints\n"
        msg = msg .. "/races clear - clear race waypoints\n"
        msg = msg .. "/races load [name] - load race waypoints saved as [name]\n"
        msg = msg .. "/races save [name] - save new race waypoints as [name]\n"
        msg = msg .. "/races overwrite [name] - overwrite existing race waypoints saved as [name]\n"
        msg = msg .. "/races delete [name] - delete race waypoints saved as [name]\n"
        msg = msg .. "/races list - list saved races\n"
        msg = msg .. "/races loadPublic [name] - load public race waypoints saved as [name]\n"
        msg = msg .. "/races savePublic [name] - save new public race waypoints as [name]\n"
        msg = msg .. "/races overwritePublic [name] - overwrite existing public race waypoints saved as [name]\n"
        msg = msg .. "/races deletePublic [name] - delete public race waypoints saved as [name]\n"
        msg = msg .. "/races listPublic - list public saved races\n"
        msg = msg .. "/races register (laps) (DNF timeout) - register your race; (laps) defaults to 1 lap; (DNF timeout) defaults to 120 seconds\n"
        msg = msg .. "/races unregister - unregister your race\n"
        msg = msg .. "/races leave - leave a race that you joined\n"
        msg = msg .. "/races start (delay) - start your registered race; (delay) defaults to 30 seconds\n"
        msg = msg .. "/races results - list latest race results\n"
        msg = msg .. "/races speedo - toggle display of speedometer\n"
        notifyPlayer(msg)
    elseif "edit" == args[1] then
        if STATE_IDLE == raceState then
            raceState = STATE_EDITING
            SetWaypointOff()
            notifyPlayer("Editing started")
        elseif STATE_EDITING == raceState then
            raceState = STATE_IDLE
            if false == checkpointDeleted then
                DeleteCheckpoint(raceCheckpoint)
                checkpointDeleted = true
            end
            if lastSelectedWaypoint > 0 then
                SetBlipColour(waypoints[lastSelectedWaypoint], blipColor)
                lastSelectedWaypoint = 0
            end
            notifyPlayer("Editing stopped")
        else
            notifyPlayer("Cannot edit waypoints.  Leave race first.")
        end
    elseif "clear" == args[1] then
        if STATE_IDLE == raceState then
            deleteWaypoints()
        elseif STATE_EDITING == raceState then
            if false == checkpointDeleted then
                DeleteCheckpoint(raceCheckpoint)
                checkpointDeleted = true
            end
            lastSelectedWaypoint = 0
            deleteWaypoints()
        else
            notifyPlayer("Cannot clear waypoints.  Leave race first.")
        end
    elseif "load" == args[1] then
        loadRace(false, args[2])
    elseif "loadPublic" == args[1] then
        loadRace(true, args[2])
    elseif "save" == args[1] then
        saveRace(false, args[2])
    elseif "savePublic" == args[1] then
        saveRace(true, args[2])
    elseif "overwrite" == args[1] then
        overwriteRace(false, args[2])
    elseif "overwritePublic" == args[1] then
        overwriteRace(true, args[2])
    elseif "delete" == args[1] then
        deleteRace(false, args[2])
    elseif "deletePublic" == args[1] then
        deleteRace(true, args[2])
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
                        TriggerServerEvent("races:register", GetEntityCoords(PlayerPedId()), laps, timeout, convertWaypoints())
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
        if STATE_REGISTERING == raceState then
            raceState = STATE_IDLE
            TriggerServerEvent("races:leave", raceIndex)
            notifyPlayer("Left race")
        elseif STATE_RACING == raceState then
            raceState = STATE_IDLE
            TriggerServerEvent("races:finish", raceIndex, numWaypointsPassed, -1, bestLapTime)
            DeleteCheckpoint(raceCheckpoint)
            checkpointDeleted = true
            SetBlipRoute(waypoints[1], true)
            SetBlipRouteColour(waypoints[1], blipRouteColor)
            speedo = false
            notifyPlayer("Left race")
        else
            notifyPlayer("Not joined to any race")
        end
    elseif "start" == args[1] then
        local delay = tonumber(args[2]) or 30
        if delay >= 0 then
            TriggerServerEvent("races:start", delay)
        else
            notifyPlayer("Invalid delay")
        end
    elseif "results" == args[1] then
        printResults()
    elseif "speedo" == args[1] then
        speedo = not speedo
    else
        notifyPlayer("Unknown command")
    end
end)

RegisterNetEvent("races:load")
AddEventHandler("races:load", function(name, raceWaypoints)
    if name ~= nil and raceWaypoints ~= nil then
        if STATE_IDLE == raceState then
            loadWaypoints(raceWaypoints)
            notifyPlayer("Loaded '" .. name .. "'")
        elseif STATE_EDITING == raceState then
            if false == checkpointDeleted then
                DeleteCheckpoint(raceCheckpoint)
                checkpointDeleted = true
            end
            lastSelectedWaypoint = 0
            loadWaypoints(raceWaypoints)
            notifyPlayer("Loaded '" .. name .. "'")
        else
            notifyPlayer("Ignoring load event.  Currently joined to race.")
        end
    end
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(index, owner, coord)
    if index ~= nil and owner ~= nil and coord ~= nil then
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z) -- registration blip
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, registerBlipColor)

        local checkpoint = CreateCheckpoint(45, coord.x, coord.y, coord.z, 0, 0, 0, 10.0, 0, 255, 0, 127, 0) -- registration checkpoint
        SetCheckpointCylinderHeight(checkpoint, 10.0, 10.0, 10.0)

        starts[index] = {owner = owner, blip = blip, checkpoint = checkpoint}
    end
end)

RegisterNetEvent("races:unregister")
AddEventHandler("races:unregister", function(index)
    if index ~= nil then
        removeRegistrationPoint(index)
        if raceIndex == index then
            if STATE_REGISTERING == raceState then
                raceState = STATE_IDLE
                notifyPlayer("Race canceled")
            elseif STATE_RACING == raceState then
                raceState = STATE_IDLE
                SetBlipRoute(waypoints[1], true)
                SetBlipRouteColour(waypoints[1], blipRouteColor)
                DeleteCheckpoint(raceCheckpoint)
                checkpointDeleted = true
                speedo = false
                notifyPlayer("Race canceled")
            end
        end
    end
end)

RegisterNetEvent("races:join")
AddEventHandler("races:join", function(index, laps, timeout, raceWaypoints)
    if index ~= nil and laps ~= nil and timeout ~= nil and raceWaypoints ~= nil then
        if STATE_IDLE == raceState then
            raceState = STATE_REGISTERING
            raceIndex = index
            numLaps = laps
            DNFTimeout = timeout * 1000
            loadWaypoints(raceWaypoints)
            notifyPlayer(("Joined race owned by %s : %d lap(s)"):format(starts[index].owner, laps))
        elseif STATE_EDITING == raceState then
            notifyPlayer("Ignoring race join event.  Currently editing.")
        else
            notifyPlayer("Ignoring race join event.  Already joined to a race.")
        end
    end
end)

RegisterNetEvent("races:start")
AddEventHandler("races:start", function(delay)
    if delay ~= nil then
        if delay >= 0 then
            if STATE_REGISTERING == raceState then
                raceState = STATE_RACING
                raceStart = GetGameTimer()
                raceDelay = delay
                lapTimeStart = raceStart + delay * 1000
                bestLapTime = -1
                currentLap = 1
                currentWaypoint = 1
                numWaypointsPassed = 0
                position = -1
                numRacers = -1
                beginDNFTimeout = false
                timeoutStart = -1
                results = {}
                checkpointDeleted = true
                frozen = true
                speedo = true
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
    end
end)

RegisterNetEvent("races:results")
AddEventHandler("races:results", function(raceResults)
    if raceResults ~= nil then
        results = raceResults -- results[] = {playerName, finishTime, bestLapTime}

        table.sort(results, function(p0, p1)
            return
                (p0.finishTime >= 0 and (-1 == p1.finishTime or p0.finishTime < p1.finishTime)) or
                (-1 == p0.finishTime and -1 == p1.finishTime and (p0.bestLapTime >= 0 and (-1 == p1.bestLapTime or p0.bestLapTime < p1.bestLapTime)))
        end)

        printResults()
    end
end)

RegisterNetEvent("races:hide")
AddEventHandler("races:hide", function(index)
    if index ~= nil then
        removeRegistrationPoint(index)
    end
end)

RegisterNetEvent("races:finish")
AddEventHandler("races:finish", function(playerName, raceFinishTime, raceBestLapTime)
    if playerName ~= nil and raceFinishTime ~= nil and raceBestLapTime ~= nil then
        if -1 == raceFinishTime then
            if -1 == raceBestLapTime then
                notifyPlayer(playerName .. " did not finish")
            else
                local minutes, seconds = minutesSeconds(raceBestLapTime)
                notifyPlayer(("%s did not finish and had a best lap time of %02d:%05.2f"):format(playerName, minutes, seconds))
            end
        else
            if false == beginDNFTimeout then
                beginDNFTimeout = true
                timeoutStart = GetGameTimer()
            end

            local fMinutes, fSeconds = minutesSeconds(raceFinishTime)
            local lMinutes, lSeconds = minutesSeconds(raceBestLapTime)
            notifyPlayer(("%s finished in %02d:%05.2f and had a best lap time of %02d:%05.2f"):format(playerName, fMinutes, fSeconds, lMinutes, lSeconds))
        end
    end
end)

RegisterNetEvent("races:position")
AddEventHandler("races:position", function(pos, numR)
    if pos ~= nil and numR ~= nil then
        position = pos
        numRacers = numR
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if STATE_RACING == raceState then
            local blipCoord = GetBlipCoords(waypoints[currentWaypoint])
            local pedCoord = GetEntityCoords(PlayerPedId())
            local dist = CalculateTravelDistanceBetweenPoints(pedCoord.x, pedCoord.y, pedCoord.z, blipCoord.x, blipCoord.y, blipCoord.z)
            TriggerServerEvent("races:report", raceIndex, numWaypointsPassed, dist)
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
                    if coord == GetBlipCoords(blip) then
                        selectedWaypoint = index
                        break
                    end
                end

                if 0 == selectedWaypoint then -- no existing waypoint selected
                    if 0 == lastSelectedWaypoint then -- no previous selected waypoint exists, add new waypoint
                        local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
                        SetBlipAsShortRange(blip, true)
                        SetBlipColour(blip, blipColor)
                        ShowNumberOnBlip(blip, #waypoints + 1)
                        waypoints[#waypoints + 1] = blip

                        if false == checkpointDeleted then -- new waypoint was added previously
                            DeleteCheckpoint(raceCheckpoint)
                        end
                    else -- previous selected waypoint exists, move previous selected waypoint to new location
                        SetBlipCoords(waypoints[lastSelectedWaypoint], coord.x, coord.y, coord.z)
                        DeleteCheckpoint(raceCheckpoint)
                    end

                    SetBlipRoute(waypoints[1], true)
                    SetBlipRouteColour(waypoints[1], blipRouteColor)

                    createRaceCheckpoint(45, coord)
                else -- existing waypoint selected
                    if 0 == lastSelectedWaypoint then -- no previous selected waypoint exists
                        SetBlipColour(waypoints[selectedWaypoint], selectedBlipColor)

                        lastSelectedWaypoint = selectedWaypoint

                        if false == checkpointDeleted then -- new waypoint was added previously
                            DeleteCheckpoint(raceCheckpoint)
                        end

                        createRaceCheckpoint(45, coord)
                    else -- previous selected waypoint exists
                        DeleteCheckpoint(raceCheckpoint)
                        if selectedWaypoint ~= lastSelectedWaypoint then -- selected waypoint and previous selected waypoint are different
                            SetBlipColour(waypoints[lastSelectedWaypoint], blipColor)
                            SetBlipColour(waypoints[selectedWaypoint], selectedBlipColor)

                            lastSelectedWaypoint = selectedWaypoint

                            createRaceCheckpoint(45, coord)
                        else -- selected waypoint and previous selected waypoint are the same
                            SetBlipColour(waypoints[selectedWaypoint], blipColor)
                            lastSelectedWaypoint = 0
                            checkpointDeleted = true
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

                    DeleteCheckpoint(raceCheckpoint)
                    checkpointDeleted = true

                    if #waypoints > 0 then
                        SetBlipRoute(waypoints[1], true)
                        SetBlipRouteColour(waypoints[1], blipRouteColor)
                    end
                end
            end
        elseif STATE_RACING == raceState then
            local player = PlayerPedId()
            local currentTime = GetGameTimer()
            local countDown = raceStart + raceDelay * 1000 - currentTime
            if countDown > 0 then
                drawMsg(0.41, 0.50, ("Race starting in %05.2f seconds"):format(countDown / 1000.0), 0.7)

                if IsPedInAnyVehicle(player, false) then
                    FreezeEntityPosition(GetVehiclePedIsIn(player, false), true)
                    frozen = true
                end
            else
                if true == frozen then
                    if IsPedInAnyVehicle(player, false) then
                        FreezeEntityPosition(GetVehiclePedIsIn(player, false), false)
                    end
                    frozen = false
                end

                local leftSide = 0.43
                local rightSide = 0.51

                drawMsg(leftSide, 0.03, "Position", 0.5)
                if -1 == position then
                    drawMsg(rightSide, 0.03, "-- of --", 0.5)
                else
                    drawMsg(rightSide, 0.03, ("%d of %d"):format(position, numRacers), 0.5)
                end

                drawMsg(leftSide, 0.06, "Lap", 0.5)
                drawMsg(rightSide, 0.06, ("%d of %d"):format(currentLap, numLaps), 0.5)

                drawMsg(leftSide, 0.09, "Waypoint", 0.5)
                drawMsg(rightSide, 0.09, ("%d of %d"):format(currentWaypoint, #waypoints), 0.5)

                local minutes, seconds = minutesSeconds(-countDown)
                drawMsg(leftSide, 0.12, "Total time", 0.5)
                drawMsg(rightSide, 0.12, ("%02d:%05.2f"):format(minutes, seconds), 0.5)

                local lapTime = currentTime - lapTimeStart
                minutes, seconds = minutesSeconds(lapTime)
                drawMsg(leftSide, 0.20, "Lap time", 0.7)
                drawMsg(rightSide, 0.20, ("%02d:%05.2f"):format(minutes, seconds), 0.7)

                drawMsg(leftSide, 0.24, "Best lap", 0.7)
                if -1 == bestLapTime then
                    drawMsg(rightSide, 0.24, "- - : - -", 0.7)
                else
                    minutes, seconds = minutesSeconds(bestLapTime)
                    drawMsg(rightSide, 0.24, ("%02d:%05.2f"):format(minutes, seconds), 0.7)
                end

                if true == beginDNFTimeout then
                    local milliseconds = timeoutStart + DNFTimeout - currentTime
                    if milliseconds >= 0 then
                        minutes, seconds = minutesSeconds(milliseconds)
                        drawMsg(leftSide, 0.28, "DNF time", 0.7)
                        drawMsg(rightSide, 0.28, ("%02d:%05.2f"):format(minutes, seconds), 0.7)
                    else -- DNF
                        raceState = STATE_IDLE
                        TriggerServerEvent("races:finish", raceIndex, numWaypointsPassed, -1, bestLapTime)
                        DeleteCheckpoint(raceCheckpoint)
                        checkpointDeleted = true

                        SetBlipRoute(waypoints[1], true)
                        SetBlipRouteColour(waypoints[1], blipRouteColor)
                        speedo = false
                    end
                end

                local blipCoord = GetBlipCoords(waypoints[currentWaypoint])
                if true == checkpointDeleted then
                    local checkpointType = (currentWaypoint == #waypoints and currentLap == numLaps) and 9 or 45
                    createRaceCheckpoint(checkpointType, blipCoord)
                end

                if STATE_RACING == raceState then
                    if #(GetEntityCoords(player) - blipCoord) < 10.0 then
                        DeleteCheckpoint(raceCheckpoint)
                        checkpointDeleted = true

                        numWaypointsPassed = numWaypointsPassed + 1

                        if currentWaypoint < #waypoints then
                            currentWaypoint = currentWaypoint + 1
                        else
                            currentWaypoint = 1
                            lapTimeStart = currentTime
                            if -1 == bestLapTime or lapTime < bestLapTime then
                                bestLapTime = lapTime
                            end
                            if currentLap < numLaps then
                                currentLap = currentLap + 1
                            else
                                raceState = STATE_IDLE
                                TriggerServerEvent("races:finish", raceIndex, numWaypointsPassed, -countDown, bestLapTime)
                                speedo = false
                            end
                        end

                        SetBlipRoute(waypoints[currentWaypoint], true)
                        SetBlipRouteColour(waypoints[currentWaypoint], blipRouteColor)
                    end
                end
            end
        elseif STATE_IDLE == raceState then
            local pedCoord = GetEntityCoords(PlayerPedId())
            for index, start in pairs(starts) do
                if #(pedCoord - GetBlipCoords(start.blip)) < 10.0 then
                    drawMsg(0.34, 0.50, "Press[E] or right DPAD to join race owned by " .. start.owner, 0.7)
                    if IsControlJustReleased(0, 51) then -- E or DPAD RIGHT
                        TriggerServerEvent('races:join', index)
                    end
                    break
                end
            end
        end

        if true == speedo then
            local speed = GetEntitySpeed(PlayerPedId())
            drawMsg(0.37, 0.91, ("%05.2f"):format(speed * 3.6), 0.7)
            drawMsg(0.41, 0.91, "kph", 0.7)
            drawMsg(0.57, 0.91, ("%05.2f"):format(speed * 2.2369363), 0.7)
            drawMsg(0.61, 0.91, "mph", 0.7)
        end
    end
end)
