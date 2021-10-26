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

local finishCheckpoint <const> = 9 -- cylinder checkered flag
local midCheckpoint <const> = 42 -- cylinder with number
local plainCheckpoint <const> = 45 -- cylinder
local arrow3Checkpoint <const> = 7 -- cylinder with 3 arrows

local defaultBuyin <const> = 500 -- default race buy-in
local defaultLaps <const> = 1 -- default number of laps in a race
local defaultTimeout <const> = 120 -- default DNF timeout
local defaultDelay <const> = 30 -- default race start delay
local defaultVehicle <const> = "adder" -- default spawned vehicle
local defaultFilename = nil -- default random vehicle filename - set by server
local defaultRadius = 0.0 -- default waypoint radius - set by server

local minRadius <const> = 0.5 -- minimum waypoint radius
local maxRadius <const> = 10.0 -- maximum waypoint radius

local topSide <const> = 0.45 -- top position of HUD
local leftSide <const> = 0.02 -- left position of HUD
local rightSide <const> = leftSide + 0.08 -- right position of HUD

local maxNumVisible <const> = 3 -- maximum number of waypoints visible during a race
local numVisible = maxNumVisible -- number of waypoints visible during a race - may be less than maxNumVisible

local highlightedCheckpoint = 0 -- index of highlighted checkpoint
local selectedWaypoint = 0 -- index of currently selected waypoint
local lastSelectedWaypoint = 0 -- index of last selected waypoint

local raceIndex = -1 -- index of race player has joined
local publicRace = false -- flag indicating if saved race is public or not
local savedRaceName = nil -- name of saved waypoints - nil if waypoints not saved

local waypoints = {} -- waypoints[] = {coord = {x, y, z, r}, checkpoint, blip, sprite, color, number, name}
local startIsFinish = false -- flag indicating if start and finish are same waypoint

local numLaps = -1 -- number of laps in current race
local currentLap = -1 -- current lap

local numWaypointsPassed = -1 -- number of waypoints player has passed
local currentWaypoint = -1 -- current waypoint - for multi-lap races, actual current waypoint is currentWaypoint % #waypoints + 1
local waypointCoord = nil -- coordinates of current waypoint

local raceStart = -1 -- start time of race before delay
local raceDelay = -1 -- delay before official start of race
local countdown = -1 -- countdown before start
local drawLights = false -- draw start lights

local position = -1 -- position in race out of numRacers players
local numRacers = -1 -- number of players in race - no DNF players included

local lapTimeStart = -1 -- start time of current lap
local bestLapTime = -1 -- best lap time

local raceCheckpoint = nil -- race checkpoint in world

local DNFTimeout = -1 -- DNF timeout after first player finishes the race
local beginDNFTimeout = false -- flag indicating if DNF timeout should begin
local timeoutStart = -1 -- start time of DNF timeout

local restrictedHash = nil -- vehicle hash of race with restricted vehicle
local restrictedClass = nil -- restricted vehicle class

local originalVehicleHash = nil -- vehicle hash of original vehicle before switching to other vehicles in random vehicle races
local colorPri = -1 -- primary color of original vehicle
local colorSec = -1 -- secondary color of original vehicle

local startVehicle = nil -- vehicle name hash of starting vehicle used in random races
local lastVehicleHash = nil -- hash of current vehicle being driven
local currentVehicle = nil -- name of current vehicle being driven
local bestLapVehicle = nil -- name of vehicle in which player recorded best lap time

local randVehicles = {} -- list of random vehicles used in random vehicle races

local respawnCtrlPressed = false -- flag indicating if respawn crontrol is pressed
local respawnTime = -1 -- time when respawn control pressed

local results = {} -- results[] = {source, playerName, finishTime, bestLapTime, vehicleName}

local started = false -- flag indicating if race started

local starts = {} -- starts[playerID] = {publicRace, savedRaceName, owner, buyin, laps, timeout, rtype, restrict, filename, vclass, svehicle, blip, checkpoint} - registration points

local speedo = false -- flag indicating if speedometer is displayed
local unitom = "imperial" -- current unit of measurement

local panelShown = false -- flag indicating if command button panel is shown

local permit = true -- flag indicating if player is permitted to create tracks and register races

math.randomseed(GetCloudTimeAsInt())

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
    local zCoord = coord.z
    if checkpointType ~= 42 and checkpointType ~= 45 then
        zCoord = zCoord + coord.r / 2.0
    else
        zCoord = zCoord - coord.r / 2.0
    end
    local checkpoint = CreateCheckpoint(checkpointType, coord.x, coord.y, zCoord, nextCoord.x, nextCoord.y, nextCoord.z, coord.r * 2.0, color.r, color.g, color.b, alpha, num)
    SetCheckpointCylinderHeight(checkpoint, 10.0, 10.0, coord.r * 2.0)
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

local function drawMsg(x, y, msg, scale, justify)
    SetTextFont(4)
    SetTextScale(0, scale)
    SetTextColour(255, 255, 0, 255)
    SetTextOutline()
    SetTextJustification(justify)
    SetTextWrap(0.0, 1.0)
    BeginTextCommandDisplayText ("STRING")
    AddTextComponentSubstringPlayerName (msg)
    EndTextCommandDisplayText (x, y)
end

local function drawRect(x, y, w, h, r, g, b, a)
    DrawRect(x + w / 2.0, y + h / 2.0, w, h, r, g, b, a)
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

local function putPlayerInVehicle(vehicleHash, coord)
    local player = PlayerPedId()
    local vehicle = CreateVehicle(vehicleHash, coord.x, coord.y, coord.z, GetEntityHeading(player), true, false)
    SetPedIntoVehicle(player, vehicle, -1)
    SetEntityAsNoLongerNeeded(vehicle)
    SetModelAsNoLongerNeeded(vehicleHash)
    SetVehRadioStation(vehicle, "OFF")
    return vehicle
end

local function switchVehicle(vehicleHash)
    local vehicle = nil
    if vehicleHash ~= nil then
        local player = PlayerPedId()
        local speed = GetEntitySpeed(player)
        RequestModel(vehicleHash)
        while HasModelLoaded(vehicleHash) == false do
            Citizen.Wait(0)
        end
        if IsPedInAnyVehicle(player, false) == 1 then
            vehicle = GetVehiclePedIsIn(player, false)
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteVehicle(vehicle)
        end
        vehicle = putPlayerInVehicle(vehicleHash, GetEntityCoords(player))
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleForwardSpeed(vehicle, speed)
        lastVehicleHash = vehicleHash
        currentVehicle = GetLabelText(GetDisplayNameFromVehicleModel(vehicleHash))
    end
    return vehicle
end

local function getClass(vclass)
    if 0 == vclass then
        return "'Compacts'(0)"
    elseif 1 == vclass then
        return "'Sedans'(1)"
    elseif 2 == vclass then
        return "'SUVs'(2)"
    elseif 3 == vclass then
        return "'Coupes'(3)"
    elseif 4 == vclass then
        return "'Muscle'(4)"
    elseif 5 == vclass then
        return "'Sports Classics'(5)"
    elseif 6 == vclass then
        return "'Sports'(6)"
    elseif 7 == vclass then
        return "'Super'(7)"
    elseif 8 == vclass then
        return "'Motorcycles'(8)"
    elseif 9 == vclass then
        return "'Off-road'(9)"
    elseif 10 == vclass then
        return "'Industrial'(10)"
    elseif 11 == vclass then
        return "'Utility'(11)"
    elseif 12 == vclass then
        return "'Vans'(12)"
    elseif 13 == vclass then
        return "'Cycles'(13)"
    elseif 14 == vclass then
        return "'Boats'(14)"
    elseif 15 == vclass then
        return "'Helicopters'(15)"
    elseif 16 == vclass then
        return "'Planes'(16)"
    elseif 17 == vclass then
        return "'Service'(17)"
    elseif 18 == vclass then
        return "'Emergency'(18)"
    elseif 19 == vclass then
        return "'Military'(19)"
    elseif 20 == vclass then
        return "'Commercial'(20)"
    elseif 21 == vclass then
        return "'Trains'(21)"
    else
        return "'Unknown'(" .. vclass .. ")"
    end
end

local function editWaypoints(coord)
    selectedWaypoint = 0
    local minDist = maxRadius
    for index, waypoint in ipairs(waypoints) do
        local dist = #(coord - vector3(waypoint.coord.x, waypoint.coord.y, waypoint.coord.z))
        if dist < waypoint.coord.r and dist < minDist then
            minDist = dist
            selectedWaypoint = index
        end
    end

    if 0 == selectedWaypoint then -- no existing waypoint selected
        if 0 == lastSelectedWaypoint then -- no previous selected waypoint exists, add new waypoint
            local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
            SetBlipAsShortRange(blip, true)

            local coordRad = {x = coord.x, y = coord.y, z = coord.z, r = defaultRadius}
            waypoints[#waypoints + 1] = {coord = coordRad, checkpoint = nil, blip = blip, sprite = -1, color = -1, number = -1, name = nil}

            startIsFinish = 1 == #waypoints and true or false
            setStartToFinishBlips()
            deleteWaypointCheckpoints()
            setStartToFinishCheckpoints()

        else -- previous selected waypoint exists, move previous selected waypoint to new location
            waypoints[lastSelectedWaypoint].coord = {x = coord.x, y = coord.y, z = coord.z, r = waypoints[lastSelectedWaypoint].coord.r}

            SetBlipCoords(waypoints[lastSelectedWaypoint].blip, coord.x, coord.y, coord.z)

            DeleteCheckpoint(waypoints[lastSelectedWaypoint].checkpoint)
            local color = getCheckpointColor(selectedBlipColor)
            local checkpointType = 38 == waypoints[lastSelectedWaypoint].sprite and finishCheckpoint or midCheckpoint
            waypoints[lastSelectedWaypoint].checkpoint = makeCheckpoint(checkpointType, waypoints[lastSelectedWaypoint].coord, coord, color, 127, lastSelectedWaypoint - 1)

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
                local splitCombine = false
                local checkpointType = finishCheckpoint
                local waypointNum = 0
                if true == startIsFinish then
                    if #waypoints == selectedWaypoint and 1 == lastSelectedWaypoint then -- split start/finish waypoint
                        splitCombine = true

                        startIsFinish = false

                        waypoints[1].sprite = startSprite
                        waypoints[1].color = startBlipColor
                        waypoints[1].number = -1
                        waypoints[1].name = "Start"

                        waypoints[#waypoints].sprite = finishSprite
                        waypoints[#waypoints].color = finishBlipColor
                        waypoints[#waypoints].number = -1
                        waypoints[#waypoints].name = "Finish"
                    end
                else
                    if 1 == selectedWaypoint and #waypoints == lastSelectedWaypoint then -- combine start and finish waypoints
                        splitCombine = true

                        startIsFinish = true

                        waypoints[1].sprite = startFinishSprite
                        waypoints[1].color = startFinishBlipColor
                        waypoints[1].number = -1
                        waypoints[1].name = "Start/Finish"

                        waypoints[#waypoints].sprite = midSprite
                        waypoints[#waypoints].color = midBlipColor
                        waypoints[#waypoints].number = #waypoints - 1
                        waypoints[#waypoints].name = "Waypoint"

                        checkpointType = midCheckpoint
                        waypointNum = #waypoints - 1
                    end
                end
                if true == splitCombine then
                    setBlipProperties(1)
                    setBlipProperties(#waypoints)

                    local color = getCheckpointColor(waypoints[1].color)
                    SetCheckpointRgba(waypoints[1].checkpoint, color.r, color.g, color.b, 127)
                    SetCheckpointRgba2(waypoints[1].checkpoint, color.r, color.g, color.b, 127)

                    DeleteCheckpoint(waypoints[#waypoints].checkpoint)
                    color = getCheckpointColor(waypoints[#waypoints].color)
                    waypoints[#waypoints].checkpoint = makeCheckpoint(checkpointType, waypoints[#waypoints].coord, waypoints[#waypoints].coord, color, 127, waypointNum)

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

local function request()
    TriggerServerEvent("races:request")
end

local function edit()
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
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
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
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
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
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
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
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
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
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
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
    if raceName ~= nil then
        TriggerServerEvent("races:delete", public, raceName)
    else
        sendMessage("Cannot delete.  Name required.\n")
    end
end

local function bestLapTimes(public, raceName)
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
    if raceName ~= nil then
        TriggerServerEvent("races:blt", public, raceName)
    else
        sendMessage("Cannot list best lap times.  Name required.\n")
    end
end

local function list(public)
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
    TriggerServerEvent("races:list", public)
end

local function register(buyin, laps, timeout, rtype, arg6, arg7, arg8)
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
    buyin = (nil == buyin or "." == buyin) and defaultBuyin or tonumber(buyin)
    if buyin ~= nil and buyin >= 0 then
        laps = (nil == laps or "." == laps) and defaultLaps or tonumber(laps)
        if laps ~= nil and laps > 0 then
            timeout = (nil == timeout or "." == timeout) and defaultTimeout or tonumber(timeout)
            if timeout ~= nil and timeout >= 0 then
                local registerRace = true
                local restrict = nil
                local filename = nil
                local vclass = nil
                local svehicle = nil
                if "rest" == rtype then
                    restrict = arg6
                    if nil == restrict or IsModelInCdimage(restrict) ~= 1 or IsModelAVehicle(restrict) ~= 1 then
                        registerRace = false
                        sendMessage("Cannot register.  Invalid restricted vehicle.\n")
                    end
                elseif "class" == rtype then
                    vclass = tonumber(arg6)
                    if nil == vclass or vclass < 0 or vclass > 21 then
                        registerRace = false
                        sendMessage("Cannot register.  Invalid vehicle class.\n")
                    end
                elseif "rand" == rtype then
                    buyin = 0
                    if "." == arg6 then
                        arg6 = nil
                    end
                    if "." == arg7 then
                        arg7 = nil
                    end
                    if "." == arg8 then
                        arg8 = nil
                    end
                    filename = arg6
                    vclass = tonumber(arg7)
                    if vclass ~= nil and (vclass < 0 or vclass > 21) then
                        registerRace = false
                        sendMessage("Cannot register.  Invalid vehicle class.\n")
                    else
                        svehicle = arg8
                        if svehicle ~= nil then
                            if IsModelInCdimage(svehicle) ~= 1 or IsModelAVehicle(svehicle) ~= 1 then
                                registerRace = false
                                sendMessage("Cannot register.  Invalid start vehicle.\n")
                            elseif vclass ~= nil and GetVehicleClassFromName(svehicle) ~= vclass then
                                registerRace = false
                                sendMessage("Cannot register.  Start vehicle not of indicated vehicle class.\n")
                            end
                        end
                    end
                elseif rtype ~= nil then
                    registerRace = false
                    sendMessage("Cannot register.  Unknown race type.\n")
                end
                if true == registerRace then
                    if STATE_IDLE == raceState then
                        if #waypoints > 1 then
                            if laps < 2 or (laps >= 2 and true == startIsFinish) then
                                TriggerServerEvent("races:register", waypointsToCoords(), publicRace, savedRaceName, buyin, laps, timeout, rtype, restrict, filename, vclass, svehicle)
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
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
    TriggerServerEvent("races:unregister")
end

local function startRace(delay)
    if false == permit then
        sendMessage("Permission required.\n")
        return
    end
    delay = nil == delay and defaultDelay or tonumber(delay)
    if delay ~= nil and delay >= 5 then
        TriggerServerEvent("races:start", delay)
    else
        sendMessage("Cannot start.  Invalid delay.\n")
    end
end

local function leave()
    if STATE_REGISTERING == raceState then
        TriggerServerEvent("races:leave", raceIndex)
        sendMessage("Left race.\n")
        raceState = STATE_IDLE
    elseif STATE_RACING == raceState then
        local player = PlayerPedId()
        if IsPedInAnyVehicle(player, false) == 1 then
            FreezeEntityPosition(GetVehiclePedIsIn(player, false), false)
        end
        DeleteCheckpoint(raceCheckpoint)
        TriggerServerEvent("races:finish", raceIndex, numWaypointsPassed, -1, bestLapTime, bestLapVehicle, nil)
        restoreBlips()
        SetBlipRoute(waypoints[1].blip, true)
        SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
        speedo = false
        if #randVehicles > 0 then
            local vehicle = switchVehicle(originalVehicleHash)
            if vehicle ~= nil then
                SetVehicleColours(vehicle, colorPri, colorSec)
            end
        end
        sendMessage("Left race.\n")
        raceState = STATE_IDLE
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

local function respawn()
    if STATE_RACING == raceState then
        local prev = currentWaypoint - 1
        if true == startIsFinish then
            if currentWaypoint > 0 then
                prev = currentWaypoint
            else
                return
            end
        else
            if 1 == currentWaypoint then
                return
            end
        end
        local vehicle = GetPlayersLastVehicle()
        if vehicle ~= 0 then
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteVehicle(vehicle)
        end
        local coord =  waypoints[prev].coord
        if lastVehicleHash ~= nil then
            RequestModel(lastVehicleHash)
            while HasModelLoaded(lastVehicleHash) == false do
                Citizen.Wait(0)
            end
            putPlayerInVehicle(lastVehicleHash, coord)
        else
            SetEntityCoords(PlayerPedId(), coord.x, coord.y, coord.z, false, false, false, true)
        end
    else
        sendMessage("Cannot respawn.  Not in a race.\n")
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

local function spawn(vehicleHash)
    vehicleHash = vehicleHash or defaultVehicle
    if IsModelInCdimage(vehicleHash) == 1 and IsModelAVehicle(vehicleHash) == 1 then
        RequestModel(vehicleHash)
        while HasModelLoaded(vehicleHash) == false do
            Citizen.Wait(0)
        end
        putPlayerInVehicle(vehicleHash, GetEntityCoords(PlayerPedId()))
        sendMessage("'" .. GetLabelText(GetDisplayNameFromVehicleModel(vehicleHash)) .. "' spawned.\n")
    else
        sendMessage("Cannot spawn vehicle.  Invalid vehicle.\n")
    end
end

local function lvehicles(vclass)
    vclass = tonumber(vclass)
    if nil == vclass or (vclass >= 0 and vclass <= 21) then
        TriggerServerEvent("races:lvehicles", vclass)
    else
        sendMessage("Cannot list vehicles.  Invalid vehicle class.\n")
    end
end

local function setSpeedo(unit)
    if unit ~= nil then
        if "imp" == unit then
            unitom = "imperial"
            sendMessage("Unit of measurement changed to Imperial.\n")     
        elseif "met" == unit then
            unitom = "metric"
            sendMessage("Unit of measurement changed to Metric.\n")     
        else
            sendMessage("Invalid unit of measurement.\n")     
        end
    else
        speedo = not speedo
        if true == speedo then
            sendMessage("Speedometer enabled.\n")
        else
            sendMessage("Speedometer disabled.\n")
        end
    end
end

local function viewFunds()
    TriggerServerEvent("races:funds")
end

local function showPanel()
    panelShown = true
    SetNuiFocus(true, true)
    if true == permit then
        SendNUIMessage({
            panel = "main",
            defaultBuyin = defaultBuyin,
            defaultLaps = defaultLaps,
            defaultTimeout = defaultTimeout,
            defaultDelay = defaultDelay,
            defaultVehicle = defaultVehicle,
            defaultFilename = defaultFilename
        })
    else
        SendNUIMessage({
            panel = "restricted",
            defaultVehicle = defaultVehicle,
        })
    end
end

RegisterNUICallback("request", function()
    request()
end)

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
    local rtype = data.rtype
    if "norm" == rtype then
        rtype = nil
    end
    local restrict = data.restrict
    if "" == restrict then
        restrict = nil
    end
    local filename = data.filename
    if "" == filename then
        filename = nil
    end
    local svehicle = data.svehicle
    if "" == svehicle then
        svehicle = nil
    end
    local vclass = data.vclass
    if "-1" == vclass then
        vclass = nil
    end
    if nil == rtype then
        register(buyin, laps, timeout, rtype, nil, nil)
    elseif "rest" == rtype then
        register(buyin, laps, timeout, rtype, restrict, nil)
    elseif "class" == rtype then
        register(buyin, laps, timeout, rtype, vclass, nil)
    elseif "rand" == rtype then
        register(buyin, laps, timeout, rtype, filename, vclass, svehicle)
    end
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

RegisterNUICallback("respawn", function()
    respawn()
end)

RegisterNUICallback("results", function()
    viewResults(false)
end)

RegisterNUICallback("spawn", function(data)
    local vehicle = data.vehicle
    if "" == vehicle then
        vehicle = nil
    end
    spawn(vehicle)
end)

RegisterNUICallback("lvehicles", function(data)
    local vclass = data.vclass
    if "-1" == vclass then
        vclass = nil
    end
    lvehicles(vclass)
end)

RegisterNUICallback("speedo", function(data)
    local unit = data.unit
    if "" == unit then
        unit = nil
    end
    setSpeedo(unit)
end)

RegisterNUICallback("funds", function()
    viewFunds()
end)

RegisterNUICallback("close", function()
    panelShown = false
    SetNuiFocus(false, false)
end)

--[[
local function testSound(audioRef, audioName)
    PlaySoundFrontend(-1, audioName, audioRef, true)
end

local function testCheckpoint(cptype)
    local pedCoord = GetEntityCoords(PlayerPedId())
    local coord = {x = pedCoord.x, y = pedCoord.y, z = pedCoord.z, r = 5.0}
    local checkpoint = makeCheckpoint(tonumber(cptype), coord, coord, yellow, 127, 5)
end

local function setEngineHealth(num)
    local player = PlayerPedId()
    if IsPedInAnyVehicle(player, false) == 1 then
        SetVehicleEngineHealth(GetVehiclePedIsIn(player, false), tonumber(num))
    end
end

local function getEngineHealth()
    local player = PlayerPedId()
    if IsPedInAnyVehicle(player, false) == 1 then
        print(GetVehicleEngineHealth(GetVehiclePedIsIn(player, false)))
    end
end

RegisterNetEvent("sounds")
AddEventHandler("sounds", function(sounds)
    print("start")
    for _, sound in pairs(sounds) do
        print(sound.ref .. ":" .. sound.name)
        if
            fail == string.find(sound.name, "Loop") and
            fail == string.find(sound.name, "Background") and
            sound.name ~= "Pin_Movement" and
            sound.name ~= "WIND" and
            sound.name ~= "Trail_Custom" and
            sound.name ~= "Altitude_Warning" and
            sound.name ~= "OPENING" and
            sound.name ~= "CONTINUOUS_SLIDER" and
            sound.name ~= "SwitchWhiteWarning" and
            sound.name ~= "SwitchRedWarning" and
            sound.name ~= "ZOOM" and sound.name ~= "Microphone" and
            sound.ref ~= "MP_CCTV_SOUNDSET" and
            sound.ref ~= "SHORT_PLAYER_SWITCH_SOUND_SET"
        then
            testSound(sound.ref, sound.name)
        else
            print("------------" .. sound.name)
        end
        Citizen.Wait(1000)
    end
    print("done")
end)

RegisterNetEvent("vehicles")
AddEventHandler("vehicles", function(vehicleList)
    local unknown = {}
    local maxName = nil
    local maxLen = 0
    local minName = nil
    local minLen = 0
    for _, vehicle in ipairs(vehicleList) do
        if IsModelInCdimage(vehicle) ~= 1 or IsModelAVehicle(vehicle) ~= 1 then
            unknown[#unknown + 1] = vehicle
        else
            local name = GetLabelText(GetDisplayNameFromVehicleModel(vehicle))
            local len = string.len(name)
            if len > maxLen then
                maxName = vehicle .. ":" .. name
                maxLen = len
            elseif 0 == minLen or len < minLen then
                minName = vehicle .. ":" .. name
                minLen = len
            end
        end
    end
    TriggerServerEvent("unk", unknown)
    print(maxLen .. ":" .. maxName)
    print(minLen .. ":" .. minName)

    for vclass = 0, 21 do
        local vehicles = {}
        for _, vehicle in ipairs(vehicleList) do
            if IsModelInCdimage(vehicle) == 1 and IsModelAVehicle(vehicle) == 1 then
                if GetVehicleClassFromName(vehicle) == vclass then
                    vehicles[#vehicles + 1] = vehicle
                end
            end
        end
        TriggerServerEvent("veh", vclass, vehicles)
    end
end)
--]]

RegisterCommand("races", function(_, args)
    if nil == args[1] then
        local msg = "Commands:\n"
        msg = msg .. "Required arguments are in square brackets.  Optional arguments are in parentheses.\n"
        msg = msg .. "/races - display list of available /races commands\n"
        msg = msg .. "/races request - request permission to create tracks and register races\n"
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
        msg = msg .. "\n"
        msg = msg .. "For the following '/races register' commands, (buy-in) defaults to 500, (laps) defaults to 1 lap and (DNF timeout) defaults to 120 seconds\n"
        msg = msg .. "/races register (buy-in) (laps) (DNF timeout) - register your race with no vehicle restrictions\n"
        msg = msg .. "/races register (buy-in) (laps) (DNF timeout) rest [vehicle] - register your race restricted to [vehicle]\n"
        msg = msg .. "/races register (buy-in) (laps) (DNF timeout) class [class] - register your race restricted to vehicles of type [class]\n"
        msg = msg .. "/races register (buy-in) (laps) (DNF timeout) rand (filename) (class) (vehicle) - register your race changing vehicles randomly every lap; (filename) defaults to 'random.txt'; (class) defaults to any; (vehicle) defaults to any\n"
        msg = msg .. "\n"
        msg = msg .. "/races unregister - unregister your race\n"
        msg = msg .. "/races start (delay) - start your registered race; (delay) defaults to 30 seconds\n"
        msg = msg .. "/races leave - leave a race that you joined\n"
        msg = msg .. "/races rivals - list competitors in a race that you joined\n"
        msg = msg .. "/races respawn - respawn at last waypoint\n"
        msg = msg .. "/races results - view latest race results\n"
        msg = msg .. "/races spawn (name) - spawn a vehicle; (name) defaults to 'adder'\n"
        msg = msg .. "/races lvehicles (class) - list available vehicles of type (class); otherwise list all available vehicles if (class) is not specified\n"
        msg = msg .. "/races speedo (unit) - change unit of speed measurement to (unit); otherwise toggle display of speedometer if (unit) is not specified\n"
        msg = msg .. "/races funds - view available funds\n"
        msg = msg .. "/races panel - display command button panel\n"
        notifyPlayer(msg)
    elseif "request" == args[1] then
        request()
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
        register(args[2], args[3], args[4], args[5], args[6], args[7], args[8])
    elseif "unregister" == args[1] then
        unregister()
    elseif "start" == args[1] then
        startRace(args[2])
    elseif "leave" == args[1] then
        leave()
    elseif "rivals" == args[1] then
        rivals()
    elseif "respawn" == args[1] then
        respawn()
    elseif "results" == args[1] then
        viewResults(true)
    elseif "spawn" == args[1] then
        spawn(args[2])
    elseif "lvehicles" == args[1] then
        lvehicles(args[2])
    elseif "speedo" == args[1] then
        setSpeedo(args[2])
    elseif "funds" == args[1] then
        viewFunds()
    elseif "panel" == args[1] then
        showPanel()
--[[
    elseif "test" == args[1] then
        if "0" == args[2] then
            TriggerEvent("races:finish", "John Doe", (5 * 60 + 24) * 1000, (1 * 60 + 32) * 1000, "Duck")
        elseif "1" == args[2] then
            testCheckpoint(args[3])
        elseif "2" == args[2] then
            testSound(args[3], args[4])
        elseif "3" == args[2] then
            TriggerServerEvent("sounds0")
        elseif "4" == args[2] then
            TriggerServerEvent("sounds1")
        elseif "5" == args[2] then
            TriggerServerEvent("vehicles")
        elseif "6" == args[2] then
            setEngineHealth(args[3])
        elseif "7" == args[2] then
            getEngineHealth()
        end
--]]
    else
        notifyPlayer("Unknown command.\n")
    end
end)

RegisterNetEvent("races:init")
AddEventHandler("races:init", function(filename, radius)
    defaultFilename = filename
    defaultRadius = radius
end)

RegisterNetEvent("races:permission")
AddEventHandler("races:permission", function(permission)
    permit = permission
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
AddEventHandler("races:register", function(index, coord, public, raceName, owner, buyin, laps, timeout, rdata)
    if index ~= nil and coord ~= nil and public ~= nil and owner ~= nil and buyin ~= nil and laps ~=nil and timeout ~= nil then
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z) -- registration blip
        SetBlipAsShortRange(blip, true)
        SetBlipSprite(blip, registerSprite)
        SetBlipColour(blip, registerBlipColor)
        BeginTextCommandSetBlipName("STRING")
        local msg = owner .. " (" .. buyin .. " buy-in"
        if "rest" == rdata.rtype then
            msg = msg .. " : using '" .. rdata.restrict .. "' vehicle"
        elseif "class" == rdata.rtype then
            msg = msg .. " : using " .. getClass(rdata.vclass) .. " vehicle class"
        elseif "rand" == rdata.rtype then
            msg = msg .. " : using random "
            if rdata.vclass ~= nil then
                msg = msg .. getClass(rdata.vclass) .. " vehicle class"
            else
                msg = msg .. "vehicles"
            end
            if rdata.svehicle ~= nil then
                msg = msg .. " : '" .. rdata.svehicle .. "'"
            end
        end
        msg = msg .. ")"
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandSetBlipName(blip)

        coord.r = defaultRadius
        local checkpoint = makeCheckpoint(plainCheckpoint, coord, coord, purple, 127, 0) -- registration checkpoint

        starts[index] = {
            publicRace = public,
            savedRaceName = raceName,
            owner = owner,
            buyin = buyin,
            laps = laps,
            timeout = timeout,
            rtype = rdata.rtype,
            restrict = rdata.restrict,
            filename = rdata.filename,
            vclass = rdata.vclass,
            svehicle = rdata.svehicle,
            blip = blip,
            checkpoint = checkpoint
        }
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

RegisterNetEvent("races:lvehicles")
AddEventHandler("races:lvehicles", function(vehicleList, vclass)
    if vehicleList ~= nil then
        local msg = "Available vehicles"
        if nil == vclass then
            msg = msg .. ": "
        else
            msg = msg .. " of class " .. getClass(vclass) .. ": "
        end
        local vehicleFound = false
        for _, vehicle in pairs(vehicleList) do
            if IsModelInCdimage(vehicle) == 1 and IsModelAVehicle(vehicle) == 1 then
                if nil == vclass or GetVehicleClassFromName(vehicle) == vclass then
                    msg = msg .. vehicle .. ", "
                    vehicleFound = true
                end
            end
        end
        if false == vehicleFound then
            msg = "No vehicles in list."
        else
            msg = string.sub(msg, 1, -3)
        end
        sendMessage(msg)
    else
        notifyPlayer("Ignoring list vehicles event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:start")
AddEventHandler("races:start", function(delay)
    if delay ~= nil then
        if delay >= 5 then
            if STATE_REGISTERING == raceState then
                raceStart = GetGameTimer()
                raceDelay = delay
                countdown = 5
                drawLights = false
                lapTimeStart = raceStart + delay * 1000
                bestLapTime = -1
                currentLap = 1
                numWaypointsPassed = 0
                position = -1
                numRacers = -1
                beginDNFTimeout = false
                timeoutStart = -1
                lastVehicleHash = nil
                currentVehicle = "FEET"
                bestLapVehicle = currentVehicle
                originalVehicleHash = nil
                results = {}
                started = false
                speedo = true

                local player = PlayerPedId()
                if IsPedInAnyVehicle(player, false) == 1 then
                    local vehicle = GetVehiclePedIsIn(player, false)
                    if vehicle ~= nil then
                        originalVehicleHash = GetEntityModel(vehicle)
                        colorPri, colorSec = GetVehicleColours(vehicle)
                    end
                end

                if startVehicle ~= nil then
                    switchVehicle(startVehicle)
                end

                numVisible = maxNumVisible < #waypoints and maxNumVisible or (#waypoints - 1)
                for i = numVisible + 1, #waypoints do
                    SetBlipDisplay(waypoints[i].blip, 0)
                end

                currentWaypoint = true == startIsFinish and 0 or 1

                waypointCoord = waypoints[1].coord
                raceCheckpoint = makeCheckpoint(arrow3Checkpoint, waypointCoord, waypoints[2].coord, yellow, 127, 0)

                SetBlipRoute(waypointCoord, true)
                SetBlipRouteColour(waypointCoord, blipRouteColor)

                raceState = STATE_RACING

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
AddEventHandler("races:join", function(index, waypointCoords, vehicleList)
    if index ~= nil and waypointCoords ~= nil then
        if starts[index] ~= nil then
            if STATE_IDLE == raceState then
                raceState = STATE_REGISTERING
                raceIndex = index
                numLaps = starts[index].laps
                DNFTimeout = starts[index].timeout * 1000
                loadWaypointBlips(waypointCoords)
                restrictedHash = nil
                restrictedClass = nil
                startVehicle = starts[index].svehicle
                randVehicles = {}
                local msg = "Joined "
                if nil == starts[index].savedRaceName then
                    msg = msg .. "unsaved race "
                else
                    msg = msg .. (true == starts[index].publicRace and "publicly" or "privately")
                    msg = msg .. " saved race '" .. starts[index].savedRaceName .. "' "
                end
                msg = msg .. ("registered by %s : %d buy-in : %d lap(s)"):format(starts[index].owner, starts[index].buyin, starts[index].laps)
                if "rest" == starts[index].rtype then
                    msg = msg .. " : using '" .. starts[index].restrict .. "' vehicle"
                    restrictedHash = GetHashKey(starts[index].restrict)
                elseif "class" == starts[index].rtype then
                    msg = msg .. " : using " .. getClass(starts[index].vclass) .. " vehicle class"
                    restrictedClass = starts[index].vclass
                elseif "rand" == starts[index].rtype then
                    msg = msg .. " : using random "
                    restrictedClass = starts[index].vclass
                    if starts[index].vclass ~= nil then
                        msg = msg .. getClass(starts[index].vclass) .. " vehicle class"
                    else
                        msg = msg .. "vehicles"
                    end
                    if startVehicle ~= nil then
                        msg = msg .. " : '" .. startVehicle .. "'"
                    end
                    if vehicleList ~= nil then
                        for _, vehicle in pairs(vehicleList) do
                            if IsModelInCdimage(vehicle) == 1 and IsModelAVehicle(vehicle) == 1 then
                                if nil == starts[index].vclass or GetVehicleClassFromName(vehicle) == starts[index].vclass then
                                    randVehicles[#randVehicles + 1] = vehicle
                                end
                            end
                        end
                        if 0 == #randVehicles then
                            msg = msg .. " : No random vehicles loaded"
                        end
                    else
                        msg = msg .. " : No random vehicles loaded"
                    end
                end
                msg = msg .. ".\n"
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
        Citizen.Wait(0)
        local player = PlayerPedId()
        local pedCoord = GetEntityCoords(player)
        if STATE_EDITING == raceState then
            local closestIndex = 0
            local minDist = maxRadius
            for index, waypoint in ipairs(waypoints) do
                local dist = #(pedCoord - vector3(waypoint.coord.x, waypoint.coord.y, waypoint.coord.z))
                if dist < waypoint.coord.r and dist < minDist then
                    minDist = dist
                    closestIndex = index
                end
            end

            if closestIndex ~= 0 then
                if highlightedCheckpoint ~= 0 and closestIndex ~= highlightedCheckpoint then
                    local color = highlightedCheckpoint == selectedWaypoint and getCheckpointColor(selectedBlipColor) or getCheckpointColor(waypoints[highlightedCheckpoint].color)
                    SetCheckpointRgba(waypoints[highlightedCheckpoint].checkpoint, color.r, color.g, color.b, 127)
                end
                local color = closestIndex == selectedWaypoint and getCheckpointColor(selectedBlipColor) or getCheckpointColor(waypoints[closestIndex].color)
                SetCheckpointRgba(waypoints[closestIndex].checkpoint, color.r, color.g, color.b, 255)
                highlightedCheckpoint = closestIndex
                drawMsg(0.50, 0.50, "Press [ENTER] key, [A] button or [CROSS] button to select waypoint", 0.7, 0)
            elseif highlightedCheckpoint ~= 0 then
                local color = highlightedCheckpoint == selectedWaypoint and getCheckpointColor(selectedBlipColor) or getCheckpointColor(waypoints[highlightedCheckpoint].color)
                SetCheckpointRgba(waypoints[highlightedCheckpoint].checkpoint, color.r, color.g, color.b, 127)
                highlightedCheckpoint = 0
            end

            if IsWaypointActive() == 1 then
                SetWaypointOff()
                local coord = GetBlipCoords(GetFirstBlipInfoId(8))
                _, coord = GetClosestVehicleNode(coord.x, coord.y, coord.z, 1)
                editWaypoints(coord)
            elseif IsControlJustReleased(0, 215) == 1 then -- enter key or A button or cross button
                editWaypoints(pedCoord)
            elseif selectedWaypoint > 0 then
                if IsControlJustReleased(2, 216) == 1 then -- space key or X button or square button
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
                elseif IsControlJustReleased(0, 187) == 1 and waypoints[selectedWaypoint].coord.r > minRadius then -- arrow down or DPAD DOWN
                    waypoints[selectedWaypoint].coord.r = waypoints[selectedWaypoint].coord.r - 0.5
                    DeleteCheckpoint(waypoints[selectedWaypoint].checkpoint)
                    local color = getCheckpointColor(selectedBlipColor)
                    local checkpointType = 38 == waypoints[selectedWaypoint].sprite and finishCheckpoint or midCheckpoint
                    waypoints[selectedWaypoint].checkpoint = makeCheckpoint(checkpointType, waypoints[selectedWaypoint].coord, waypoints[selectedWaypoint].coord, color, 127, selectedWaypoint - 1)
                    savedRaceName = nil
                elseif IsControlJustReleased(0, 188) == 1 and waypoints[selectedWaypoint].coord.r < maxRadius then -- arrow up or DPAD UP
                    waypoints[selectedWaypoint].coord.r = waypoints[selectedWaypoint].coord.r + 0.5
                    DeleteCheckpoint(waypoints[selectedWaypoint].checkpoint)
                    local color = getCheckpointColor(selectedBlipColor)
                    local checkpointType = 38 == waypoints[selectedWaypoint].sprite and finishCheckpoint or midCheckpoint
                    waypoints[selectedWaypoint].checkpoint = makeCheckpoint(checkpointType, waypoints[selectedWaypoint].coord, waypoints[selectedWaypoint].coord, color, 127, selectedWaypoint - 1)
                    savedRaceName = nil
                end
            end
        elseif STATE_RACING == raceState then
            local currentTime = GetGameTimer()
            local elapsedTime = currentTime - raceStart - raceDelay * 1000
            if elapsedTime < 0 then
                drawMsg(0.50, 0.46, ("Race starting in "), 0.7, 0)
                drawMsg(0.50, 0.50, ("%05.2f"):format(-elapsedTime / 1000.0), 0.7, 0)
                drawMsg(0.50, 0.54, "seconds", 0.7, 0)

                if elapsedTime > -countdown * 1000 then
                    drawLights = true
                    countdown = countdown - 1
                    PlaySoundFrontend(-1, "MP_5_SECOND_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                end

                if true == drawLights then
                    for i = 0, 4 - countdown do
                        drawRect(i * 0.2 + 0.05, 0.15, 0.1, 0.1, 255, 0, 0, 255)
                    end
                end
                
                if IsPedInAnyVehicle(player, false) == 1 then
                    FreezeEntityPosition(GetVehiclePedIsIn(player, false), true)
                end
            else
                local vehicle = nil
                if IsPedInAnyVehicle(player, false) == 1 then
                    vehicle = GetVehiclePedIsIn(player, false)
                    FreezeEntityPosition(vehicle, false)
                    lastVehicleHash = GetEntityModel(vehicle)
                    currentVehicle = GetLabelText(GetDisplayNameFromVehicleModel(lastVehicleHash))
                else
                    currentVehicle = "FEET"
                end
                if false == started then
                    started = true
                    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
                    bestLapVehicle = currentVehicle
                end

                if IsControlPressed(0, 73) == 1 then -- X key or A button or cross button
                    if true == respawnCtrlPressed then
                        if currentTime - respawnTime > 1000 then
                            respawnCtrlPressed = false
                            respawn()
                        end
                    else
                        respawnCtrlPressed = true
                        respawnTime = currentTime
                    end
                else
                    respawnCtrlPressed = false
                end

                drawRect(leftSide - 0.01, topSide - 0.01, 0.21, 0.35, 0, 0, 0, 127)

                drawMsg(leftSide, topSide, "Position", 0.5, 1)
                if -1 == position then
                    drawMsg(rightSide, topSide, "-- of --", 0.5, 1)
                else
                    drawMsg(rightSide, topSide, ("%d of %d"):format(position, numRacers), 0.5, 1)
                end

                drawMsg(leftSide, topSide + 0.03, "Lap", 0.5, 1)
                drawMsg(rightSide, topSide + 0.03, ("%d of %d"):format(currentLap, numLaps), 0.5, 1)

                drawMsg(leftSide, topSide + 0.06, "Waypoint", 0.5, 1)
                if true == startIsFinish then
                    drawMsg(rightSide, topSide + 0.06, ("%d of %d"):format(currentWaypoint, #waypoints), 0.5, 1)
                else
                    drawMsg(rightSide, topSide + 0.06, ("%d of %d"):format(currentWaypoint - 1, #waypoints - 1), 0.5, 1)
                end

                local minutes, seconds = minutesSeconds(elapsedTime)
                drawMsg(leftSide, topSide + 0.09, "Total time", 0.5, 1)
                drawMsg(rightSide, topSide + 0.09, ("%02d:%05.2f"):format(minutes, seconds), 0.5, 1)

                drawMsg(leftSide, topSide + 0.12, "Vehicle", 0.5, 1)
                drawMsg(rightSide, topSide + 0.12, currentVehicle, 0.5, 1)

                local lapTime = currentTime - lapTimeStart
                minutes, seconds = minutesSeconds(lapTime)
                drawMsg(leftSide, topSide + 0.17, "Lap time", 0.7, 1)
                drawMsg(rightSide, topSide + 0.17, ("%02d:%05.2f"):format(minutes, seconds), 0.7, 1)

                drawMsg(leftSide, topSide + 0.21, "Best lap", 0.7, 1)
                if -1 == bestLapTime then
                    drawMsg(rightSide, topSide + 0.21, "- - : - -", 0.7, 1)
                else
                    minutes, seconds = minutesSeconds(bestLapTime)
                    drawMsg(rightSide, topSide + 0.21, ("%02d:%05.2f"):format(minutes, seconds), 0.7, 1)
                end

                if true == beginDNFTimeout then
                    local milliseconds = timeoutStart + DNFTimeout - currentTime
                    if milliseconds > 0 then
                        minutes, seconds = minutesSeconds(milliseconds)
                        drawMsg(leftSide, topSide + 0.29, "DNF time", 0.7, 1)
                        drawMsg(rightSide, topSide + 0.29, ("%02d:%05.2f"):format(minutes, seconds), 0.7, 1)
                    else -- DNF
                        DeleteCheckpoint(raceCheckpoint)
                        TriggerServerEvent("races:finish", raceIndex, numWaypointsPassed, -1, bestLapTime, bestLapVehicle, nil)
                        restoreBlips()
                        SetBlipRoute(waypoints[1].blip, true)
                        SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
                        speedo = false
                        if #randVehicles > 0 then
                            local veh = switchVehicle(originalVehicleHash)
                            if veh ~= nil then
                                SetVehicleColours(veh, colorPri, colorSec)
                            end
                        end
                        raceState = STATE_IDLE
                    end
                end

                if STATE_RACING == raceState then
                    if #(pedCoord - vector3(waypointCoord.x, waypointCoord.y, waypointCoord.z)) < waypointCoord.r then
                        local waypointPassed = true
                        if restrictedHash ~= nil then
                            if vehicle ~= nil then
                                if GetEntityModel(vehicle) ~= restrictedHash then
                                    waypointPassed = false
                                end
                            else
                                waypointPassed = false
                            end
                        elseif restrictedClass ~= nil then
                            if vehicle ~= nil then
                                if GetVehicleClass(vehicle) ~= restrictedClass then
                                    waypointPassed = false
                                end
                            else
                                waypointPassed = false
                            end
                        end

                        if true == waypointPassed then
                            DeleteCheckpoint(raceCheckpoint)
                            PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)

                            numWaypointsPassed = numWaypointsPassed + 1

                            if currentWaypoint < #waypoints then
                                currentWaypoint = currentWaypoint + 1
                            else
                                currentWaypoint = 1
                                lapTimeStart = currentTime
                                if -1 == bestLapTime or lapTime < bestLapTime then
                                    bestLapTime = lapTime
                                    bestLapVehicle = currentVehicle
                                end
                                if currentLap < numLaps then
                                    currentLap = currentLap + 1
                                    if #randVehicles > 0 then
                                        switchVehicle(randVehicles[math.random(#randVehicles)])
                                        PlaySoundFrontend(-1, "CHARACTER_SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                    end
                                else
                                    TriggerServerEvent("races:finish", raceIndex, numWaypointsPassed, elapsedTime, bestLapTime, bestLapVehicle, nil)
                                    restoreBlips()
                                    SetBlipRoute(waypoints[1].blip, true)
                                    SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
                                    speedo = false
                                    if #randVehicles > 0 then
                                        local veh = switchVehicle(originalVehicleHash)
                                        if veh ~= nil then
                                            SetVehicleColours(veh, colorPri, colorSec)
                                        end
                                    end
                                    raceState = STATE_IDLE
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
            end
        elseif STATE_IDLE == raceState then
            local closestIndex = -1
            local minDist = defaultRadius
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
                msg = msg .. ("registered by %s :"):format(starts[closestIndex].owner)
                drawMsg(0.50, 0.50, msg, 0.7, 0)
                msg = ("%d buy-in : %d lap(s)"):format(starts[closestIndex].buyin, starts[closestIndex].laps)
                if "rest" == starts[closestIndex].rtype then
                    msg = msg .. " : using '" .. starts[closestIndex].restrict .. "' vehicle"
                elseif "class" == starts[closestIndex].rtype then
                    msg = msg .. " : using " .. getClass(starts[closestIndex].vclass) .. " vehicle class"
                elseif "rand" == starts[closestIndex].rtype then
                    msg = msg .. " : using random "
                    if starts[closestIndex].vclass ~= nil then
                        msg = msg .. getClass(starts[closestIndex].vclass) .. " vehicle class"
                    else
                        msg = msg .. "vehicles"
                    end
                    if starts[closestIndex].svehicle ~= nil then
                        msg = msg .. " : '" .. starts[closestIndex].svehicle .. "'"
                    end
                end
                drawMsg(0.50, 0.54, msg, 0.7, 0)
                if IsControlJustReleased(0, 51) == 1 then -- E key or DPAD RIGHT
                    local joinRace = true
                    if "rest" == starts[closestIndex].rtype then
                        if IsPedInAnyVehicle(player, false) == 1 then
                            if GetEntityModel(GetVehiclePedIsIn(player, false)) ~= GetHashKey(starts[closestIndex].restrict) then
                                joinRace = false
                                notifyPlayer("Cannot join race.  Player needs to be in restricted vehicle.")
                            end
                        else
                            joinRace = false
                            notifyPlayer("Cannot join race.  Player needs to be in restricted vehicle.")
                        end
                    elseif "class" == starts[closestIndex].rtype then
                        if IsPedInAnyVehicle(player, false) == 1 then
                            if GetVehicleClass(GetVehiclePedIsIn(player, false)) ~= starts[closestIndex].vclass then
                                joinRace = false
                                notifyPlayer("Cannot join race.  Player needs to be in vehicle of " .. getClass(starts[closestIndex].vclass) .. " class.")
                            end
                        else
                            joinRace = false
                            notifyPlayer("Cannot join race.  Player needs to be in vehicle of " .. getClass(starts[closestIndex].vclass) .. " class.")
                        end
                    elseif "rand" == starts[closestIndex].rtype then
                        if starts[closestIndex].vclass ~= nil then
                            if nil == starts[closestIndex].svehicle then
                                if IsPedInAnyVehicle(player, false) == 1 then
                                    if GetVehicleClass(GetVehiclePedIsIn(player, false)) ~= starts[closestIndex].vclass then
                                        joinRace = false
                                        notifyPlayer("Cannot join race.  Player needs to be in vehicle of " .. getClass(starts[closestIndex].vclass) .. " class.")
                                    end
                                else
                                    joinRace = false
                                    notifyPlayer("Cannot join race.  Player needs to be in vehicle of " .. getClass(starts[closestIndex].vclass) .. " class.")
                                end
                            end
                        end
                    end
                    if true == joinRace then
                        TriggerServerEvent('races:join', closestIndex)
                    end
                end
            end
        end

        if true == speedo then
            local speed = GetEntitySpeed(player)
            if "metric" == unitom then
                drawMsg(leftSide, topSide + 0.25, "Speed(kph)", 0.7, 1)
                drawMsg(rightSide, topSide + 0.25, ("%05.2f"):format(speed * 3.6), 0.7, 1)
            else
                drawMsg(leftSide, topSide + 0.25, "Speed(mph)", 0.7, 1)
                drawMsg(rightSide, topSide + 0.25, ("%05.2f"):format(speed * 2.2369363), 0.7, 1)
            end
        end
    end
end)
