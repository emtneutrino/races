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

local STATE_IDLE <const> = 0
local STATE_EDITING <const> = 1
local STATE_REGISTERING <const> = 2
local STATE_RACING <const> = 3
local raceState = STATE_IDLE -- race state

local white <const> = {r = 255, g = 255, b = 255}
local red <const> = {r = 255, g = 0, b = 0}
local green <const> = {r = 0, g = 255, b = 0}
local blue <const> = {r = 0, g = 0, b = 255}
local yellow <const> = {r = 255, g = 255, b = 0}
local purple <const> = {r = 255, g = 0, b = 255}

local startFinishBlipColor <const> = 5 -- yellow
local startBlipColor <const> = 2 -- green
local finishBlipColor <const> = 0 -- white
local midBlipColor <const> = 38 -- dark blue
local registerBlipColor <const> = 83 -- purple

local selectedBlipColor <const> = 1 -- red

local blipRouteColor <const> = 18 -- light blue

local startFinishSprite <const> = 38 -- checkered flag
local startSprite <const> = 38 -- checkered flag
local finishSprite <const> = 38 -- checkered flag
local midSprite <const> = 1 -- numbered circle
local registerSprite <const> = 58 -- circled star

local finishCheckpoint <const> = 4 -- cylinder checkered flag
local midCheckpoint <const> = 42 -- cylinder with number
local plainCheckpoint <const> = 45 -- cylinder
local arrow3Checkpoint <const> = 2 -- cylinder with 3 arrows

local defaultBuyin <const> = 500 -- default race buy-in
local defaultLaps <const> = 1 -- default number of laps in a race
local defaultTimeout <const> = 120 -- default DNF timeout
local defaultDelay <const> = 30 -- default race start delay
local defaultVehicle <const> = "adder" -- default spawned vehicle

local leftSide <const> = 0.43 -- left position of HUD
local rightSide <const> = 0.51 -- right position of HUD

local maxNumVisible <const> = 3 -- maximum number of waypoints visible during a race
local numVisible = maxNumVisible -- number of waypoints visible during a race - may be less than maxNumVisible

local highlightedCheckpoint = 0 -- index of highlighted checkpoint
local selectedWaypoint = 0 -- index of currently selected waypoint
local lastSelectedWaypoint = 0 -- index of last selected waypoint

local raceIndex = -1 -- index of race player has joined
local publicRace = false -- flag indicating if saved race is public or not
local savedRaceName = nil -- name of saved waypoints - nil if waypoints not saved

local waypoints = {} -- waypoints[] = {coord, checkpoint, blip, sprite, color, number, name}
local startIsFinish = false -- flag indicating if start and finish are same waypoint

local numLaps = -1 -- number of laps in current race
local currentLap = -1 -- current lap

local numWaypointsPassed = -1 -- number of waypoints player has passed
local currentWaypoint = -1 -- current waypoint - for multi-lap races, actual current waypoint is currentWaypoint % #waypoints + 1
local waypointCoord = nil -- coordinates of current waypoint

local raceStart = -1 -- start time of race before delay
local raceDelay = -1 -- delay before official start of race

local position = -1 -- position in race out of numRacers players
local numRacers = -1 -- number of players in race - no DNF players included

local lapTimeStart = -1 -- start time of current lap
local bestLapTime = -1 -- best lap time

local raceCheckpoint = nil -- race checkpoint in world

local DNFTimeout = -1 -- DNF timeout after first player finishes the race
local beginDNFTimeout = false -- flag indicating if DNF timeout should begin
local timeoutStart = -1 -- start time of DNF timeout

local vehicleName = nil -- name of vehicle in which player started

local results = {} -- results[] = {playerName, finishTime, bestLapTime, vehicleName}

local frozen = false -- flag indicating if vehicle is frozen

local starts = {} -- starts[] = {owner, buyin, laps, publicRace, savedRaceName, blip, checkpoint} - registration points

local speedo = false -- flag indicating if speedometer is displayed

local panelShown = false -- flag indicating if command button panel is shown

TriggerServerEvent("races:init")

local function notifyPlayer(msg)
    TriggerEvent("chat:addMessage", {
        color = {255, 0, 0},
        multiline = true,
        args = {"[races:client]", msg}
    })
end

local function sendMessage(msg)
    if true == panelShown then
        local html = string.gsub(msg, "\n", "<br>")
        SendNUIMessage({
            panel = "reply",
            message = html
        })
    end
    notifyPlayer(msg)
end

local function deleteWaypointCheckpoints()
    for i = 1, #waypoints do
        DeleteCheckpoint(waypoints[i].checkpoint)
    end
end

local function getCheckpointColor(blipColor)
    if 0 == blipColor then
        return white
    elseif 1 == blipColor then
        return red
    elseif 2 == blipColor then
        return green
    elseif 38 == blipColor then
        return blue
    elseif 5 == blipColor then
        return yellow
    elseif 83 == blipColor then
        return purple
    else
        return yellow
    end
end

local function makeCheckpoint(checkpointType, coord, nextCoord, color, alpha, num)
    local checkpoint = CreateCheckpoint(checkpointType, coord.x, coord.y, coord.z, nextCoord.x, nextCoord.y, nextCoord.z, 10.0, color.r, color.g, color.b, alpha, num)
    SetCheckpointCylinderHeight(checkpoint, 10.0, 10.0, 10.0)
    return checkpoint
end

local function setStartToFinishCheckpoints()
    for i = 1, #waypoints do
        local color = getCheckpointColor(waypoints[i].color)
        local checkpointType = 38 == waypoints[i].sprite and finishCheckpoint or midCheckpoint
        waypoints[i].checkpoint = makeCheckpoint(checkpointType, waypoints[i].coord, waypoints[i].coord, color, 127, i - 1)
    end
end

local function deleteWaypointBlips()
    for i = 1, #waypoints do
        RemoveBlip(waypoints[i].blip)
    end
end

local function setBlipProperties(index)
    SetBlipSprite(waypoints[index].blip, waypoints[index].sprite)
    SetBlipColour(waypoints[index].blip, waypoints[index].color)
    ShowNumberOnBlip(waypoints[index].blip, waypoints[index].number)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(waypoints[index].name)
    EndTextCommandSetBlipName(waypoints[index].blip)
end

local function setStartToFinishBlips()
    if true == startIsFinish then
        waypoints[1].sprite = startFinishSprite
        waypoints[1].color = startFinishBlipColor
        waypoints[1].number = -1
        waypoints[1].name = "Start/Finish"

        if #waypoints > 1 then
            waypoints[#waypoints].sprite = midSprite
            waypoints[#waypoints].color = midBlipColor
            waypoints[#waypoints].number = #waypoints - 1
            waypoints[#waypoints].name = "Waypoint"
        end
    else -- #waypoints should be > 1
        waypoints[1].sprite = startSprite
        waypoints[1].color = startBlipColor
        waypoints[1].number = -1
        waypoints[1].name = "Start"

        waypoints[#waypoints].sprite = finishSprite
        waypoints[#waypoints].color = finishBlipColor
        waypoints[#waypoints].number = -1
        waypoints[#waypoints].name = "Finish"
    end

    for i = 2, #waypoints - 1 do
        waypoints[i].sprite = midSprite
        waypoints[i].color = midBlipColor
        waypoints[i].number = i - 1
        waypoints[i].name = "Waypoint"
    end

    for i = 1, #waypoints do
        setBlipProperties(i)
    end
end

local function loadWaypointBlips(waypointCoords)
    deleteWaypointBlips()
    waypoints = {}

    for i = 1, #waypointCoords - 1 do
        local blip = AddBlipForCoord(waypointCoords[i].x, waypointCoords[i].y, waypointCoords[i].z)
        SetBlipAsShortRange(blip, true)
        waypoints[i] = {coord = waypointCoords[i], checkpoint = nil, blip = blip, sprite = -1, color = -1, number = -1, name = nil}
    end

    startIsFinish =
        waypointCoords[1].x == waypointCoords[#waypointCoords].x and
        waypointCoords[1].y == waypointCoords[#waypointCoords].y and
        waypointCoords[1].z == waypointCoords[#waypointCoords].z

    if false == startIsFinish then
        local blip = AddBlipForCoord(waypointCoords[#waypointCoords].x, waypointCoords[#waypointCoords].y, waypointCoords[#waypointCoords].z)
        SetBlipAsShortRange(blip, true)
        waypoints[#waypointCoords] = {coord = waypointCoords[#waypointCoords], checkpoint = nil, blip = blip, sprite = -1, color = -1, number = -1, name = nil}
    end

    setStartToFinishBlips()

    SetBlipRoute(waypoints[1].blip, true)
    SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
end

local function restoreBlips()
    for i = 1, #waypoints do
        SetBlipDisplay(waypoints[i].blip, 2)
    end
end

local function removeRegistrationPoint(index)
    RemoveBlip(starts[index].blip) -- delete registration blip
    DeleteCheckpoint(starts[index].checkpoint) -- delete registration checkpoint
    starts[index] = nil
end

local function drawMsg(x, y, msg, scale)
    SetTextFont(4)
    SetTextScale(0, scale)
    SetTextColour(255, 255, 0, 255)
    SetTextOutline()
    BeginTextCommandDisplayText ("STRING")
    AddTextComponentSubstringPlayerName (msg)
    EndTextCommandDisplayText (x, y)
end

local function waypointsToCoords()
    local waypointCoords = {}
    for i = 1, #waypoints do
        waypointCoords[i] = waypoints[i].coord
    end
    if true == startIsFinish then
        waypointCoords[#waypointCoords + 1] = waypointCoords[1]
    end
    return waypointCoords
end

local function waypointsToCoordsRev()
    local waypointCoords = {}
    if true == startIsFinish then
        waypointCoords[1] = waypoints[1].coord
    end
    for i = #waypoints, 1, -1 do
        waypointCoords[#waypointCoords + 1] = waypoints[i].coord
    end
    return waypointCoords
end

local function minutesSeconds(milliseconds)
    local seconds = milliseconds / 1000.0
    local minutes = math.floor(seconds / 60.0)
    seconds = seconds - minutes * 60.0
    return minutes, seconds
end

local function editWaypoints(coord, map)
    selectedWaypoint = 0
    local minDist = 10.0
    for index, waypoint in pairs(waypoints) do
        local dist = true == map and #(coord - vector3(waypoint.coord.x, waypoint.coord.y, coord.z)) or #(coord - vector3(waypoint.coord.x, waypoint.coord.y, waypoint.coord.z))
        if dist < minDist then
            minDist = dist
            selectedWaypoint = index
        end
    end

    if 0 == selectedWaypoint then -- no existing waypoint selected
        if true == map then
            _, coord = GetClosestVehicleNode(coord.x, coord.y, coord.z, 1)
        end

        if 0 == lastSelectedWaypoint then -- no previous selected waypoint exists, add new waypoint
            local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
            SetBlipAsShortRange(blip, true)

            waypoints[#waypoints + 1] = {coord = coord, checkpoint = nil, blip = blip, sprite = -1, color = -1, number = -1, name = nil}

            startIsFinish = 1 == #waypoints and true or false
            setStartToFinishBlips()
            deleteWaypointCheckpoints()
            setStartToFinishCheckpoints()

        else -- previous selected waypoint exists, move previous selected waypoint to new location
            waypoints[lastSelectedWaypoint].coord = coord

            SetBlipCoords(waypoints[lastSelectedWaypoint].blip, coord.x, coord.y, coord.z)

            DeleteCheckpoint(waypoints[lastSelectedWaypoint].checkpoint)
            local color = getCheckpointColor(selectedBlipColor)
            local checkpointType = 38 == waypoints[lastSelectedWaypoint].sprite and finishCheckpoint or midCheckpoint
            waypoints[lastSelectedWaypoint].checkpoint = makeCheckpoint(checkpointType, coord, coord, color, 127, lastSelectedWaypoint - 1)

            selectedWaypoint = lastSelectedWaypoint
        end

        savedRaceName = nil

        SetBlipRoute(waypoints[1].blip, true)
        SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
    else -- existing waypoint selected
        if 0 == lastSelectedWaypoint then -- no previous selected waypoint exists
            SetBlipColour(waypoints[selectedWaypoint].blip, selectedBlipColor)
            local color = getCheckpointColor(selectedBlipColor)
            SetCheckpointRgba(waypoints[selectedWaypoint].checkpoint, color.r, color.g, color.b, 127)
            SetCheckpointRgba2(waypoints[selectedWaypoint].checkpoint, color.r, color.g, color.b, 127)

            lastSelectedWaypoint = selectedWaypoint
        else -- previous selected waypoint exists
            if selectedWaypoint ~= lastSelectedWaypoint then -- selected waypoint and previous selected waypoint are different
                if true == startIsFinish then
                    if #waypoints == selectedWaypoint and 1 == lastSelectedWaypoint then -- split start/finish waypoint
                        startIsFinish = false

                        waypoints[1].sprite = startSprite
                        waypoints[1].color = startBlipColor
                        waypoints[1].number = -1
                        waypoints[1].name = "Start"
                        setBlipProperties(1)

                        local color = getCheckpointColor(waypoints[1].color)
                        SetCheckpointRgba(waypoints[1].checkpoint, color.r, color.g, color.b, 127)
                        SetCheckpointRgba2(waypoints[1].checkpoint, color.r, color.g, color.b, 127)

                        waypoints[#waypoints].sprite = finishSprite
                        waypoints[#waypoints].color = finishBlipColor
                        waypoints[#waypoints].number = -1
                        waypoints[#waypoints].name = "Finish"
                        setBlipProperties(#waypoints)

                        DeleteCheckpoint(waypoints[#waypoints].checkpoint)
                        color = getCheckpointColor(waypoints[#waypoints].color)
                        waypoints[#waypoints].checkpoint = makeCheckpoint(finishCheckpoint, waypoints[#waypoints].coord, waypoints[#waypoints].coord, color, 127, 0)

                        selectedWaypoint = 0
                        lastSelectedWaypoint = 0
                        savedRaceName = nil
                    else
                        SetBlipColour(waypoints[lastSelectedWaypoint].blip, waypoints[lastSelectedWaypoint].color)
                        local color = getCheckpointColor(waypoints[lastSelectedWaypoint].color)
                        SetCheckpointRgba(waypoints[lastSelectedWaypoint].checkpoint, color.r, color.g, color.b, 127)
                        SetCheckpointRgba2(waypoints[lastSelectedWaypoint].checkpoint, color.r, color.g, color.b, 127)

                        SetBlipColour(waypoints[selectedWaypoint].blip, selectedBlipColor)
                        color = getCheckpointColor(selectedBlipColor)
                        SetCheckpointRgba(waypoints[selectedWaypoint].checkpoint, color.r, color.g, color.b, 127)
                        SetCheckpointRgba2(waypoints[selectedWaypoint].checkpoint, color.r, color.g, color.b, 127)

                        lastSelectedWaypoint = selectedWaypoint
                    end
                else
                    if 1 == selectedWaypoint and #waypoints == lastSelectedWaypoint then -- combine start and finish waypoints
                        startIsFinish = true

                        waypoints[1].sprite = startFinishSprite
                        waypoints[1].color = startFinishBlipColor
                        waypoints[1].number = -1
                        waypoints[1].name = "Start/Finish"
                        setBlipProperties(1)

                        local color = getCheckpointColor(waypoints[1].color)
                        SetCheckpointRgba(waypoints[1].checkpoint, color.r, color.g, color.b, 127)
                        SetCheckpointRgba2(waypoints[1].checkpoint, color.r, color.g, color.b, 127)

                        waypoints[#waypoints].sprite = midSprite
                        waypoints[#waypoints].color = midBlipColor
                        waypoints[#waypoints].number = #waypoints - 1
                        waypoints[#waypoints].name = "Waypoint"
                        setBlipProperties(#waypoints)

                        DeleteCheckpoint(waypoints[#waypoints].checkpoint)
                        color = getCheckpointColor(waypoints[#waypoints].color)
                        waypoints[#waypoints].checkpoint = makeCheckpoint(midCheckpoint, waypoints[#waypoints].coord, waypoints[#waypoints].coord, color, 127, #waypoints - 1)

                        selectedWaypoint = 0
                        lastSelectedWaypoint = 0
                        savedRaceName = nil
                    else
                        SetBlipColour(waypoints[lastSelectedWaypoint].blip, waypoints[lastSelectedWaypoint].color)
                        local color = getCheckpointColor(waypoints[lastSelectedWaypoint].color)
                        SetCheckpointRgba(waypoints[lastSelectedWaypoint].checkpoint, color.r, color.g, color.b, 127)
                        SetCheckpointRgba2(waypoints[lastSelectedWaypoint].checkpoint, color.r, color.g, color.b, 127)

                        SetBlipColour(waypoints[selectedWaypoint].blip, selectedBlipColor)
                        color = getCheckpointColor(selectedBlipColor)
                        SetCheckpointRgba(waypoints[selectedWaypoint].checkpoint, color.r, color.g, color.b, 127)
                        SetCheckpointRgba2(waypoints[selectedWaypoint].checkpoint, color.r, color.g, color.b, 127)

                        lastSelectedWaypoint = selectedWaypoint
                    end
                end
            else -- selected waypoint and previous selected waypoint are the same
                SetBlipColour(waypoints[selectedWaypoint].blip, waypoints[selectedWaypoint].color)
                local color = getCheckpointColor(waypoints[selectedWaypoint].color)
                SetCheckpointRgba(waypoints[selectedWaypoint].checkpoint, color.r, color.g, color.b, 127)
                SetCheckpointRgba2(waypoints[selectedWaypoint].checkpoint, color.r, color.g, color.b, 127)

                selectedWaypoint = 0
                lastSelectedWaypoint = 0
            end
        end
    end
end

local function edit()
    if STATE_IDLE == raceState then
        raceState = STATE_EDITING
        SetWaypointOff()
        setStartToFinishCheckpoints()
        sendMessage("Editing started.\n")
    elseif STATE_EDITING == raceState then
        raceState = STATE_IDLE
        highlightedCheckpoint = 0
        if selectedWaypoint > 0 then
            SetBlipColour(waypoints[selectedWaypoint].blip, waypoints[selectedWaypoint].color)
            selectedWaypoint = 0
        end
        lastSelectedWaypoint = 0
        deleteWaypointCheckpoints()
        sendMessage("Editing stopped.\n")
    else
        sendMessage("Cannot edit waypoints.  Leave race first.\n")
    end
end

local function clear()
    if STATE_IDLE == raceState then
        deleteWaypointBlips()
        waypoints = {}
        startIsFinish = false
        savedRaceName = nil
        sendMessage("Waypoints cleared.\n")
    elseif STATE_EDITING == raceState then
        highlightedCheckpoint = 0
        selectedWaypoint = 0
        lastSelectedWaypoint = 0
        deleteWaypointCheckpoints()
        deleteWaypointBlips()
        waypoints = {}
        startIsFinish = false
        savedRaceName = nil
        sendMessage("Waypoints cleared.\n")
    else
        sendMessage("Cannot clear waypoints.  Leave race first.\n")
    end
end

local function reverse()
    if #waypoints > 1 then
        if STATE_IDLE == raceState then
            savedRaceName = nil
            loadWaypointBlips(waypointsToCoordsRev())
            sendMessage("Waypoints reversed.\n")
        elseif STATE_EDITING == raceState then
            savedRaceName = nil
            highlightedCheckpoint = 0
            selectedWaypoint = 0
            lastSelectedWaypoint = 0
            deleteWaypointCheckpoints()
            loadWaypointBlips(waypointsToCoordsRev())
            setStartToFinishCheckpoints()
            sendMessage("Waypoints reversed.\n")
        else
            sendMessage("Cannot reverse waypoints.  Leave race first.\n")
        end
    else
        sendMessage("Cannot reverse waypoints.  Race needs to have at least 2 waypoints.\n")
    end
end

local function loadRace(public, raceName)
    if raceName ~= nil then
        if STATE_IDLE == raceState or STATE_EDITING == raceState then
            TriggerServerEvent("races:load", public, raceName)
        else
            sendMessage("Cannot load.  Leave race first.\n")
        end
    else
        sendMessage("Cannot load.  Name required.\n")
    end
end

local function saveRace(public, raceName)
    if raceName ~= nil then
        if #waypoints > 1 then
            TriggerServerEvent("races:save", public, raceName, waypointsToCoords())
        else
            sendMessage("Cannot save.  Race needs to have at least 2 waypoints.\n")
        end
    else
        sendMessage("Cannot save.  Name required.\n")
    end
end

local function overwriteRace(public, raceName)
    if raceName ~= nil then
        if #waypoints > 1 then
            TriggerServerEvent("races:overwrite", public, raceName, waypointsToCoords())
        else
            sendMessage("Cannot overwrite.  Race needs to have at least 2 waypoints.\n")
        end
    else
        sendMessage("Cannot overwrite.  Name required.\n")
    end
end

local function deleteRace(public, raceName)
    if raceName ~= nil then
        TriggerServerEvent("races:delete", public, raceName)
     else
         sendMessage("Cannot delete.  Name required.\n")
     end
end

local function bestLapTimes(public, raceName)
    if raceName ~= nil then
        TriggerServerEvent("races:blt", public, raceName)
    else
        sendMessage("Cannot list best lap times.  Name required.\n")
    end
end

local function list(public)
    TriggerServerEvent("races:list", public)
end

local function register(buyin, laps, timeout)
    buyin = nil == buyin and defaultBuyin or tonumber(buyin)
    if buyin ~= nil and buyin >= 0 then
        laps = nil == laps and defaultLaps or tonumber(laps)
        if laps ~= nil and laps > 0 then
            timeout = nil == timeout and defaultTimeout or tonumber(timeout)
            if timeout ~= nil and timeout >= 0 then
                if STATE_IDLE == raceState then
                    if #waypoints > 1 then
                        if laps < 2 or (laps >= 2 and true == startIsFinish) then
                            TriggerServerEvent("races:register", buyin, laps, timeout, waypointsToCoords(), publicRace, savedRaceName)
                        else
                            sendMessage("For multi-lap races, start and finish waypoints need to be the same: While editing waypoints, select finish waypoint first, then select start waypoint.  To separate start/finish waypoint, add a new waypoint or select start/finish waypoint first, then select highest numbered waypoint.\n")
                        end
                    else
                        sendMessage("Cannot register.  Race needs to have at least 2 waypoints.\n")
                    end
                elseif STATE_EDITING == raceState then
                    sendMessage("Cannot register.  Stop editing first.\n")
                else
                    sendMessage("Cannot register.  Leave race first.\n")
                end
            else
                sendMessage("Invalid DNF timeout.\n")
            end
        else
            sendMessage("Invalid number of laps.\n")
        end
    else
        sendMessage("Invalid buy-in amount.\n")
    end
end

local function unregister()
    TriggerServerEvent("races:unregister")
end

local function startRace(delay)
    delay = nil == delay and defaultDelay or tonumber(delay)
    if delay ~= nil and delay >= 0 then
        TriggerServerEvent("races:start", delay)
    else
        sendMessage("Cannot start.  Invalid delay.\n")
    end
end

local function leave()
    if STATE_REGISTERING == raceState then
        raceState = STATE_IDLE
        TriggerServerEvent("races:leave", raceIndex)
        sendMessage("Left race.\n")
    elseif STATE_RACING == raceState then
        raceState = STATE_IDLE
        DeleteCheckpoint(raceCheckpoint)
        TriggerServerEvent("races:finish", raceIndex, numWaypointsPassed, -1, bestLapTime, vehicleName, nil)
        restoreBlips()
        SetBlipRoute(waypoints[1].blip, true)
        SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
        speedo = false
        sendMessage("Left race.\n")
    else
        sendMessage("Cannot leave.  Not joined to any race.\n")
    end
end

local function rivals()
    if STATE_REGISTERING == raceState or STATE_RACING == raceState then
        TriggerServerEvent("races:rivals", raceIndex)
    else
        sendMessage("Cannot list competitors.  Not joined to any race.\n")
    end
end

local function viewResults(chatOnly)
    local msg = nil
    if #results > 0 then
        -- results[] = {source, playerName, finishTime, bestLapTime, vehicleName}
        msg = "Race results:\n"
        for pos, result in ipairs(results) do
            if -1 == result.finishTime then
                msg = msg .. "DNF - " .. result.playerName
                if result.bestLapTime >= 0 then
                    local minutes, seconds = minutesSeconds(result.bestLapTime)
                    msg = msg .. (" - best lap %02d:%05.2f using %s"):format(minutes, seconds, result.vehicleName)
                end
                msg = msg .. "\n"
            else
                local fMinutes, fSeconds = minutesSeconds(result.finishTime)
                local lMinutes, lSeconds = minutesSeconds(result.bestLapTime)
                msg = msg .. ("%d - %02d:%05.2f - %s - best lap %02d:%05.2f using %s\n"):format(pos, fMinutes, fSeconds, result.playerName, lMinutes, lSeconds, result.vehicleName)
            end
        end
    else
        msg = "No results.\n"
    end
    if true == chatOnly then
        notifyPlayer(msg)
    else
        sendMessage(msg)
    end
end

local function car(vehicleHash)
    vehicleHash = vehicleHash or defaultVehicle
    if 1 == IsModelInCdimage(vehicleHash) and 1 == IsModelAVehicle(vehicleHash) then
        RequestModel(vehicleHash)
        while false == HasModelLoaded(vehicleHash) do
            Citizen.Wait(500)
        end

        local player = PlayerPedId()
        local pedCoord = GetEntityCoords(player)
        local vehicle = CreateVehicle(vehicleHash, pedCoord.x, pedCoord.y, pedCoord.z, GetEntityHeading(player), true, false)
        SetPedIntoVehicle(player, vehicle, -1)
        SetEntityAsNoLongerNeeded(vehicle)
        SetModelAsNoLongerNeeded(vehicleHash)
        sendMessage("'" .. GetLabelText(GetDisplayNameFromVehicleModel(vehicleHash)) .. "' spawned.\n")
    else
        sendMessage("Invalid vehicle '" .. vehicleHash .. "'.\n")
    end
end

local function setSpeedo()
    speedo = not speedo
    if true == speedo then
        sendMessage("Speedometer enabled.\n")
    else
        sendMessage("Speedometer disabled.\n")
    end
end

local function viewFunds()
    TriggerServerEvent("races:viewFunds")
end

local function showPanel()
    panelShown = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        panel = "main",
        defaultBuyin = defaultBuyin,
        defaultLaps = defaultLaps,
        defaultTimeout = defaultTimeout,
        defaultDelay = defaultDelay,
        defaultVehicle = defaultVehicle
    })
end

RegisterNUICallback("edit", function()
    edit()
end)

RegisterNUICallback("clear", function()
    clear()
end)

RegisterNUICallback("reverse", function()
    reverse()
end)

RegisterNUICallback("load", function(data)
    local raceName = data.raceName
    if "" == raceName then
        raceName = nil
    end
    loadRace(data.public, raceName)
end)

RegisterNUICallback("save", function(data)
    local raceName = data.raceName
    if "" == raceName then
        raceName = nil
    end
    saveRace(data.public, raceName)
end)

RegisterNUICallback("overwrite", function(data)
    local raceName = data.raceName
    if "" == raceName then
        raceName = nil
    end
    overwriteRace(data.public, raceName)
end)

RegisterNUICallback("delete", function(data)
    local raceName = data.raceName
    if "" == raceName then
        raceName = nil
    end
    deleteRace(data.public, raceName)
end)

RegisterNUICallback("blt", function(data)
    local raceName = data.raceName
    if "" == raceName then
        raceName = nil
    end
    bestLapTimes(data.public, raceName)
end)

RegisterNUICallback("list", function(data)
    list(data.public)
end)

RegisterNUICallback("register", function(data)
    local buyin = data.buyin
    if "" == buyin then
        buyin = nil
    end
    local laps = data.laps
    if "" == laps then
        laps = nil
    end
    local timeout = data.timeout
    if "" == timeout then
        timeout = nil
    end
    register(buyin, laps, timeout)
end)

RegisterNUICallback("unregister", function()
    unregister()
end)

RegisterNUICallback("start", function(data)
    local delay = data.delay
    if "" == delay then
        delay = nil
    end
    startRace(delay)
end)

RegisterNUICallback("leave", function()
    leave()
end)

RegisterNUICallback("rivals", function()
    rivals()
end)

RegisterNUICallback("results", function()
    viewResults(false)
end)

RegisterNUICallback("car", function(data)
    local carName = data.carName
    if "" == carName then
        carName = nil
    end
    car(carName)
end)

RegisterNUICallback("speedo", function()
    setSpeedo()
end)

RegisterNUICallback("funds", function()
    viewFunds()
end)

RegisterNUICallback("close", function()
    panelShown = false
    SetNuiFocus(false, false)
end)

RegisterCommand("races", function(_, args)
    if nil == args[1] then
        local msg = "Commands:\n"
        msg = msg .. "/races - display list of available /races commands\n"
        msg = msg .. "/races edit - toggle editing race waypoints\n"
        msg = msg .. "/races clear - clear race waypoints\n"
        msg = msg .. "/races reverse - reverse order of race waypoints\n"
        msg = msg .. "/races load [name] - load race waypoints saved as [name]\n"
        msg = msg .. "/races save [name] - save new race waypoints as [name]\n"
        msg = msg .. "/races overwrite [name] - overwrite existing race waypoints saved as [name]\n"
        msg = msg .. "/races delete [name] - delete race waypoints saved as [name]\n"
        msg = msg .. "/races blt [name] - list 10 best lap times of race saved as [name]\n"
        msg = msg .. "/races list - list saved races\n"
        msg = msg .. "/races loadPublic [name] - load public race waypoints saved as [name]\n"
        msg = msg .. "/races savePublic [name] - save new public race waypoints as [name]\n"
        msg = msg .. "/races overwritePublic [name] - overwrite existing public race waypoints saved as [name]\n"
        msg = msg .. "/races deletePublic [name] - delete public race waypoints saved as [name]\n"
        msg = msg .. "/races bltPublic [name] - list 10 best lap times of public race saved as [name]\n"
        msg = msg .. "/races listPublic - list public saved races\n"
        msg = msg .. "/races register (buy-in) (laps) (DNF timeout) - register your race; (buy-in) defaults to 500; (laps) defaults to 1 lap; (DNF timeout) defaults to 120 seconds\n"
        msg = msg .. "/races unregister - unregister your race\n"
        msg = msg .. "/races start (delay) - start your registered race; (delay) defaults to 30 seconds\n"
        msg = msg .. "/races leave - leave a race that you joined\n"
        msg = msg .. "/races rivals - list competitors in a race that you joined\n"
        msg = msg .. "/races results - view latest race results\n"
        msg = msg .. "/races car (name) - spawn a car; (name) defaults to 'adder'\n"
        msg = msg .. "/races speedo - toggle display of speedometer\n"
        msg = msg .. "/races funds - view available funds\n"
        msg = msg .. "/races panel - display command button panel\n"
        notifyPlayer(msg)
    elseif "edit" == args[1] then
        edit()
    elseif "clear" == args[1] then
        clear()
    elseif "reverse" == args[1] then
        reverse()
    elseif "load" == args[1] then
        loadRace(false, args[2])
    elseif "save" == args[1] then
        saveRace(false, args[2])
    elseif "overwrite" == args[1] then
        overwriteRace(false, args[2])
    elseif "delete" == args[1] then
        deleteRace(false, args[2])
    elseif "blt" == args[1] then
        bestLapTimes(false, args[2])
    elseif "list" == args[1] then
        list(false)
    elseif "loadPublic" == args[1] then
        loadRace(true, args[2])
    elseif "savePublic" == args[1] then
        saveRace(true, args[2])
    elseif "overwritePublic" == args[1] then
        overwriteRace(true, args[2])
    elseif "deletePublic" == args[1] then
        deleteRace(true, args[2])
    elseif "bltPublic" == args[1] then
        bestLapTimes(true, args[2])
    elseif "listPublic" == args[1] then
        list(true)
    elseif "register" == args[1] then
        register(args[2], args[3], args[4])
    elseif "unregister" == args[1] then
        unregister()
    elseif "start" == args[1] then
        startRace(args[2])
    elseif "leave" == args[1] then
        leave()
    elseif "rivals" == args[1] then
        rivals()
    elseif "results" == args[1] then
        viewResults(true)
    elseif "car" == args[1] then
        car(args[2])
    elseif "speedo" == args[1] then
        setSpeedo()
    elseif "funds" == args[1] then
        viewFunds(args[2])
    elseif "panel" == args[1] then
        showPanel(true)
--[[
    elseif "test" == args[1] then
        TriggerEvent("races:finish", "John Doe", (5 * 60 + 24) * 1000, (1 * 60 + 32) * 1000, "Duck")
--]]
    else
        notifyPlayer("Unknown command.\n")
    end
end)

RegisterNetEvent("races:message")
AddEventHandler("races:message", function(msg)
    sendMessage(msg)
end)

RegisterNetEvent("races:load")
AddEventHandler("races:load", function(public, raceName, waypointCoords)
    if public ~= nil and raceName ~= nil and waypointCoords ~= nil then
        if STATE_IDLE == raceState then
            publicRace = public
            savedRaceName = raceName
            loadWaypointBlips(waypointCoords)
            local msg = "Loaded "
            msg = msg .. (true == public and "public" or "private")
            msg = msg .. " race '" .. raceName .. "'.\n"
            sendMessage(msg)
        elseif STATE_EDITING == raceState then
            publicRace = public
            savedRaceName = raceName
            highlightedCheckpoint = 0
            selectedWaypoint = 0
            lastSelectedWaypoint = 0
            deleteWaypointCheckpoints()
            loadWaypointBlips(waypointCoords)
            setStartToFinishCheckpoints()
            local msg = "Loaded "
            msg = msg .. (true == public and "public" or "private")
            msg = msg .. " race '" .. raceName .. "'.\n"
            sendMessage(msg)
        else
            notifyPlayer("Ignoring load event.  Currently joined to race.\n")
        end
    else
        notifyPlayer("Ignoring load event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:save")
AddEventHandler("races:save", function(public, raceName)
    if public ~= nil and raceName ~= nil then
        publicRace = public
        savedRaceName = raceName
        local msg = "Saved "
        msg = msg .. (true == public and "public" or "private")
        msg = msg .. " race '" .. raceName .. "'.\n"
        sendMessage(msg)
    else
        notifyPlayer("Ignoring save event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:overwrite")
AddEventHandler("races:overwrite", function(public, raceName)
    if public ~= nil and raceName ~= nil then
        publicRace = public
        savedRaceName = raceName
        local msg = "Overwrote "
        msg = msg .. (true == public and "public" or "private")
        msg = msg .. " race '" .. raceName .. "'.\n"
        sendMessage(msg)
    else
        notifyPlayer("Ignoring overwrite event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:blt")
AddEventHandler("races:blt", function(public, raceName, bestLaps)
    if public ~= nil and raceName ~=nil and bestLaps ~= nil then
        local msg = true == public and "public" or "private"
        msg = msg .. " race '" .. raceName .. "'"
        if #bestLaps > 0 then
            msg = "Best lap times for " .. msg .. ":\n"
            for pos, bestLap in ipairs(bestLaps) do
                local minutes, seconds = minutesSeconds(bestLap.bestLapTime)
                msg = msg .. ("%d - %s - %02d:%05.2f using %s\n"):format(pos, bestLap.playerName, minutes, seconds, bestLap.vehicleName)
            end
            sendMessage(msg)
        else
            sendMessage("No best lap times for " .. msg .. ".\n")
        end
    else
        notifyPlayer("Ignoring best lap times event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(index, owner, buyin, laps, coord, public, raceName)
    if index ~= nil and owner ~= nil and buyin ~= nil and laps ~=nil and coord ~= nil and public ~= nil then
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z) -- registration blip
        SetBlipAsShortRange(blip, true)
        SetBlipSprite(blip, registerSprite)
        SetBlipColour(blip, registerBlipColor)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(owner .. " (" .. buyin .. " buy-in)")
        EndTextCommandSetBlipName(blip)

        local checkpoint = makeCheckpoint(plainCheckpoint, coord, coord, purple, 127, 0) -- registration checkpoint

        starts[index] = {owner = owner, buyin = buyin, laps = laps, publicRace = public, savedRaceName = raceName, blip = blip, checkpoint = checkpoint}
    else
        notifyPlayer("Ignoring register event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:unregister")
AddEventHandler("races:unregister", function(index)
    if index ~= nil then
        if starts[index] ~= nil then
            removeRegistrationPoint(index)
        end
        if STATE_REGISTERING == raceState and raceIndex == index then
            raceState = STATE_IDLE
            notifyPlayer("Race canceled.\n")
        elseif STATE_RACING == raceState and raceIndex == index then
            raceState = STATE_IDLE
            DeleteCheckpoint(raceCheckpoint)
            restoreBlips()
            SetBlipRoute(waypoints[1].blip, true)
            SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
            speedo = false
            notifyPlayer("Race canceled.\n")
        end
    else
        notifyPlayer("Ignoring unregister event.  Invalid parameters.\n")
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
                numWaypointsPassed = 0
                position = -1
                numRacers = -1
                beginDNFTimeout = false
                timeoutStart = -1
                vehicleName = "FEET"
                results = {}
                frozen = false
                speedo = true

                numVisible = maxNumVisible < #waypoints and maxNumVisible or (#waypoints - 1)
                for i = numVisible + 1, #waypoints do
                    SetBlipDisplay(waypoints[i].blip, 0)
                end

                currentWaypoint = true == startIsFinish and 0 or 1

                waypointCoord = waypoints[1].coord
                raceCheckpoint = makeCheckpoint(arrow3Checkpoint, waypointCoord, waypoints[2].coord, yellow, 127, 0)

                SetBlipRoute(waypointCoord, true)
                SetBlipRouteColour(waypointCoord, blipRouteColor)

                notifyPlayer("Race started.\n")
            elseif STATE_RACING == raceState then
                notifyPlayer("Ignoring start event.  Already in a race.\n")
            elseif STATE_EDITING == raceState then
                notifyPlayer("Ignoring start event.  Currently editing.\n")
            else
                notifyPlayer("Ignoring start event.  Currently idle.\n")
            end
        else
            notifyPlayer("Ignoring start event.  Invalid delay.\n")
        end
    else
        notifyPlayer("Ignoring start event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:hide")
AddEventHandler("races:hide", function(index)
    if index ~= nil then
        if starts[index] ~= nil then
            removeRegistrationPoint(index)
        else
            notifyPlayer("Ignoring hide event.  Race does not exist.\n")
        end
    else
        notifyPlayer("Ignoring hide event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:join")
AddEventHandler("races:join", function(index, timeout, waypointCoords)
    if index ~= nil and timeout ~= nil and waypointCoords ~= nil then
        if starts[index] ~= nil then
            if STATE_IDLE == raceState then
                raceState = STATE_REGISTERING
                raceIndex = index
                numLaps = starts[index].laps
                DNFTimeout = timeout * 1000
                loadWaypointBlips(waypointCoords)
                local msg = "Joined "
                if nil == starts[index].savedRaceName then
                    msg = msg .. "unsaved race "
                else
                    msg = msg .. (true == starts[index].publicRace and "publicly" or "privately")
                    msg = msg .. " saved race '" .. starts[index].savedRaceName .. "' "
                end
                msg = msg .. ("registered by %s : %d buy-in : %d lap(s).\n"):format(starts[index].owner, starts[index].buyin, numLaps)
                notifyPlayer(msg)
            elseif STATE_EDITING == raceState then
                notifyPlayer("Ignoring join event.  Currently editing.\n")
            else
                notifyPlayer("Ignoring join event.  Already joined to a race.\n")
            end
        else
            notifyPlayer("Ignoring join event.  Race does not exist.\n")
        end
    else
        notifyPlayer("Ignoring join event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:finish")
AddEventHandler("races:finish", function(playerName, raceFinishTime, raceBestLapTime, raceVehicleName)
    if playerName ~= nil and raceFinishTime ~= nil and raceBestLapTime ~= nil and raceVehicleName ~= nil then
        if -1 == raceFinishTime then
            if -1 == raceBestLapTime then
                notifyPlayer(playerName .. " did not finish.\n")
            else
                local minutes, seconds = minutesSeconds(raceBestLapTime)
                notifyPlayer(("%s did not finish and had a best lap time of %02d:%05.2f using %s\n"):format(playerName, minutes, seconds, raceVehicleName))
            end
        else
            if false == beginDNFTimeout then
                beginDNFTimeout = true
                timeoutStart = GetGameTimer()
            end

            local fMinutes, fSeconds = minutesSeconds(raceFinishTime)
            local lMinutes, lSeconds = minutesSeconds(raceBestLapTime)
            notifyPlayer(("%s finished in %02d:%05.2f and had a best lap time of %02d:%05.2f using %s\n"):format(playerName, fMinutes, fSeconds, lMinutes, lSeconds, raceVehicleName))
        end
    else
        notifyPlayer("Ignoring finish event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:results")
AddEventHandler("races:results", function(raceResults)
    if raceResults ~= nil then
        results = raceResults
        viewResults(true)
    else
        notifyPlayer("Ignoring results event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:position")
AddEventHandler("races:position", function(pos, numR)
    if pos ~= nil and numR ~= nil then
        if STATE_RACING == raceState then
            position = pos
            numRacers = numR
        else
            notifyPlayer("Ignoring position event.  Not racing.\n")
        end
    else
        notifyPlayer("Ignoring position event.  Invalid parameters.\n")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if  true == panelShown then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if STATE_RACING == raceState then
            local pedCoord = GetEntityCoords(PlayerPedId())
            local distance = CalculateTravelDistanceBetweenPoints(pedCoord.x, pedCoord.y, pedCoord.z, waypointCoord.x, waypointCoord.y, waypointCoord.z)
            TriggerServerEvent("races:report", raceIndex, numWaypointsPassed, distance)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if STATE_EDITING == raceState then
            local pedCoord = GetEntityCoords(PlayerPedId())
            local closestIndex = 0
            local minDist = 10.0
            for index, waypoint in pairs(waypoints) do
                local dist = #(pedCoord - vector3(waypoint.coord.x, waypoint.coord.y, waypoint.coord.z))
                if dist < minDist then
                    minDist = dist
                    closestIndex = index
                end
            end

            if closestIndex ~= 0 then
                local color = -1
                if highlightedCheckpoint ~= 0 then
                    color = highlightedCheckpoint == selectedWaypoint and getCheckpointColor(selectedBlipColor) or getCheckpointColor(waypoints[highlightedCheckpoint].color)
                    SetCheckpointRgba(waypoints[highlightedCheckpoint].checkpoint, color.r, color.g, color.b, 127)
                end
                color = closestIndex == selectedWaypoint and getCheckpointColor(selectedBlipColor) or getCheckpointColor(waypoints[closestIndex].color)
                SetCheckpointRgba(waypoints[closestIndex].checkpoint, color.r, color.g, color.b, 255)
                highlightedCheckpoint = closestIndex
                drawMsg(0.29, 0.50, "Press [ENTER] key, [A] button or [CROSS] button to select waypoint", 0.7)
            elseif highlightedCheckpoint ~= 0 then
                local color = highlightedCheckpoint == selectedWaypoint and getCheckpointColor(selectedBlipColor) or getCheckpointColor(waypoints[highlightedCheckpoint].color)
                SetCheckpointRgba(waypoints[highlightedCheckpoint].checkpoint, color.r, color.g, color.b, 127)
                highlightedCheckpoint = 0
            end

            if IsWaypointActive() then
                SetWaypointOff()
                editWaypoints(GetBlipCoords(GetFirstBlipInfoId(8)), true)
            elseif IsControlJustReleased(0, 215) then -- enter or A button or cross button
                editWaypoints(pedCoord, false)
            elseif selectedWaypoint > 0 and IsControlJustReleased(2, 216) then -- space or X button or square button
                DeleteCheckpoint(waypoints[selectedWaypoint].checkpoint)
                RemoveBlip(waypoints[selectedWaypoint].blip)
                table.remove(waypoints, selectedWaypoint)

                if highlightedCheckpoint == selectedWaypoint then
                    highlightedCheckpoint = 0
                end
                selectedWaypoint = 0
                lastSelectedWaypoint = 0

                savedRaceName = nil

                if #waypoints > 0 then
                    if 1 == #waypoints then
                        startIsFinish = true
                    end
                    setStartToFinishBlips()
                    deleteWaypointCheckpoints()
                    setStartToFinishCheckpoints()
                    SetBlipRoute(waypoints[1].blip, true)
                    SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
                end
            end
        elseif STATE_RACING == raceState then
            local player = PlayerPedId()
            local currentTime = GetGameTimer()
            local elapsedTime = currentTime - raceStart - raceDelay * 1000
            if elapsedTime < 0 then
                drawMsg(0.41, 0.50, ("Race starting in %05.2f seconds"):format(-elapsedTime / 1000.0), 0.7)

                if IsPedInAnyVehicle(player, false) then
                    FreezeEntityPosition(GetVehiclePedIsIn(player, false), true)
                    frozen = true
                end
            else
                if true == frozen then
                    if IsPedInAnyVehicle(player, false) then
                        local vehicle = GetVehiclePedIsIn(player, false)
                        FreezeEntityPosition(vehicle, false)
                        vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
                    end
                    frozen = false
                end

                drawMsg(leftSide, 0.03, "Position", 0.5)
                if -1 == position then
                    drawMsg(rightSide, 0.03, "-- of --", 0.5)
                else
                    drawMsg(rightSide, 0.03, ("%d of %d"):format(position, numRacers), 0.5)
                end

                drawMsg(leftSide, 0.06, "Lap", 0.5)
                drawMsg(rightSide, 0.06, ("%d of %d"):format(currentLap, numLaps), 0.5)

                drawMsg(leftSide, 0.09, "Waypoint", 0.5)
                if true == startIsFinish then
                    drawMsg(rightSide, 0.09, ("%d of %d"):format(currentWaypoint, #waypoints), 0.5)
                else
                    drawMsg(rightSide, 0.09, ("%d of %d"):format(currentWaypoint - 1, #waypoints - 1), 0.5)
                end

                local minutes, seconds = minutesSeconds(elapsedTime)
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
                    if milliseconds > 0 then
                        minutes, seconds = minutesSeconds(milliseconds)
                        drawMsg(leftSide, 0.28, "DNF time", 0.7)
                        drawMsg(rightSide, 0.28, ("%02d:%05.2f"):format(minutes, seconds), 0.7)
                    else -- DNF
                        raceState = STATE_IDLE
                        DeleteCheckpoint(raceCheckpoint)
                        TriggerServerEvent("races:finish", raceIndex, numWaypointsPassed, -1, bestLapTime, vehicleName, nil)
                        restoreBlips()
                        SetBlipRoute(waypoints[1].blip, true)
                        SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
                        speedo = false
                    end
                end

                if STATE_RACING == raceState then
                    if #(GetEntityCoords(player) - vector3(waypointCoord.x, waypointCoord.y, waypointCoord.z)) < 10.0 then
                        DeleteCheckpoint(raceCheckpoint)

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
                                TriggerServerEvent("races:finish", raceIndex, numWaypointsPassed, elapsedTime, bestLapTime, vehicleName, nil)
                                restoreBlips()
                                SetBlipRoute(waypoints[1].blip, true)
                                SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
                                speedo = false
                            end
                        end

                        if STATE_RACING == raceState then
                            local prev = currentWaypoint - 1

                            local last = currentWaypoint + numVisible - 1
                            local addLast = true

                            local curr = currentWaypoint
                            local checkpointType = -1

                            if true == startIsFinish then
                                prev = currentWaypoint
                                if currentLap ~= numLaps then
                                    last = last % #waypoints + 1
                                elseif last < #waypoints then
                                    last = last + 1
                                elseif #waypoints == last then
                                    last = 1
                                else
                                    addLast = false
                                end
                                curr = curr % #waypoints + 1
                                checkpointType = (1 == curr and numLaps == currentLap) and finishCheckpoint or arrow3Checkpoint
                            else
                                if last > #waypoints then
                                    addLast = false
                                end
                                checkpointType = #waypoints == curr and finishCheckpoint or arrow3Checkpoint
                            end

                            SetBlipDisplay(waypoints[prev].blip, 0)

                            if true == addLast then
                                SetBlipDisplay(waypoints[last].blip, 2)
                            end

                            SetBlipRoute(waypoints[curr].blip, true)
                            SetBlipRouteColour(waypoints[curr].blip, blipRouteColor)
                            waypointCoord = waypoints[curr].coord
                            local nextCoord = waypointCoord
                            if arrow3Checkpoint == checkpointType then
                                nextCoord = curr < #waypoints and waypoints[curr + 1].coord or waypoints[1].coord
                            end
                            raceCheckpoint = makeCheckpoint(checkpointType, waypointCoord, nextCoord, yellow, 127, 0)
                        end
                    end
                end
            end
        elseif STATE_IDLE == raceState then
            local pedCoord = GetEntityCoords(PlayerPedId())
            local closestIndex = -1
            local minDist = 10.0
            for index, start in pairs(starts) do
                local dist = #(pedCoord - GetBlipCoords(start.blip))
                if dist < minDist then
                    minDist = dist
                    closestIndex = index
                end
            end
            if closestIndex ~= -1 then
                local msg = "Join "
                if nil == starts[closestIndex].savedRaceName then
                    msg = msg .. "unsaved race "
                else
                    msg = msg .. (true == starts[closestIndex].publicRace and "publicly" or "privately")
                    msg = msg .. " saved race '" .. starts[closestIndex].savedRaceName .. "' "
                end
                msg = msg .. ("registered by %s : %d buy-in : %d lap(s).\n"):format(starts[closestIndex].owner, starts[closestIndex].buyin, starts[closestIndex].laps)
                drawMsg(0.24, 0.50, msg, 0.7)
                if IsControlJustReleased(0, 51) then -- E or DPAD RIGHT
                    TriggerServerEvent('races:join', closestIndex)
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
