--[[

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

--]]

local STATE_IDLE <const> = 0 -- idle state
local STATE_EDITING <const> = 1 -- editing track state
local STATE_JOINING <const> = 2 -- joining race state
local STATE_RACING <const> = 3 -- racing state
local state = STATE_IDLE -- player state

local white <const> = {r = 255, g = 255, b = 255}
local red <const> = {r = 255, g = 0, b = 0}
local green <const> = {r = 0, g = 255, b = 0}
local blue <const> = {r = 0, g = 0, b = 255}
local yellow <const> = {r = 255, g = 255, b = 0}
local orange <const> = {r = 255, g = 127, b = 0}
local purple <const> = {r = 255, g = 0, b = 255}

local startFinishBlipColor <const> = 17 -- orange
local startBlipColor <const> = 2 -- green
local finishBlipColor <const> = 0 -- white
local numberedBlipColor <const> = 38 -- dark blue
local registerBlipColor <const> = 83 -- purple
local racerBlipColor <const> = 2 -- green
local currentWPBlipColor <const> = 5 -- yellow
local selectedBlipColor <const> = 1 -- red
local blipRouteColor <const> = 18 -- light blue

local checkeredFlagSprite <const> = 38 -- checkered flag
local numberedSprite <const> = 1 -- numbered circle
local registerSprite <const> = 58 -- circled star
local racerSprite <const> = 1 -- circle

local checkeredFlagCheckpoint <const> = GetGameBuildNumber() < 2189 and 9 or 10 -- cylinder checkered flag
local numberedCheckpoint <const> = GetGameBuildNumber() < 2189 and 42 or 45 -- cylinder with number
local plainCheckpoint <const> = GetGameBuildNumber() < 2189 and 45 or 48 -- cylinder
local arrow3Checkpoint <const> = GetGameBuildNumber() < 2189 and 7 or 8 -- cylinder with 3 arrows

local defaultBuyin <const> = 500 -- default race buy-in
local defaultLaps <const> = 1 -- default number of laps in a race
local defaultTimeout <const> = 120 -- default DNF timeout
local defaultAllowAI <const> = "no" -- default allow AI value
local defaultRecur <const> = "yes" -- default random vehicle race recur value
local defaultOrder <const> = "no" -- default random vehicle race order value
local defaultDelay <const> = 30 -- default race start delay
local defaultModel <const> = "adder" -- default spawned vehicle model
local defaultRadius <const> = 5.0 -- default waypoint radius

local minDelay <const> = 5 -- minimum race start delay

local minRadius <const> = 0.5 -- minimum waypoint radius
local maxRadius <const> = 10.0 -- maximum waypoint radius

local topSide <const> = 0.45 -- top position of HUD
local leftSide <const> = 0.02 -- left position of HUD
local rightSide <const> = leftSide + 0.09 -- right position of HUD

local maxNumVisible <const> = 3 -- maximum number of waypoints visible during a race
local numVisible = maxNumVisible -- number of waypoints visible during a race - may be less than maxNumVisible

local races = {} -- races[playerID] = {owner, access, trackName, buyin, laps, timeout, allowAI, rtype, restrict, vclass, className, svehicle, recur, order, vehicleList, blip, checkpoint} - race information

local raceIndex = -1 -- index of race player has joined

local waypoints = {} -- waypoints[] = {coord = {x, y, z, r}, checkpoint, blip, sprite, color, number, name} - race waypoints
local startIsFinish = false -- flag indicating if start and finish are same waypoint

local numLaps = -1 -- number of laps in current race

local DNFTimeout = -1 -- DNF timeout after first player finishes the race
local beginDNFTimeout = false -- flag indicating if DNF timeout should begin
local DNFTimeoutStart = -1 -- start time of DNF timeout

local raceType = nil -- type of race that player has joined

local startVehicle = nil -- vehicle model of starting vehicle used in random vehicle races
local startVehicleSpawned = false -- flag indicating if start vehicle has spawned

local recurring = true -- flag indicating if vehicles recur in random vehicle races
local ordered = false -- flag indicating if all racers switch to the same random vehicle after the same lap number in random vehicle races

local raceStart = -1 -- start time of race before delay
local raceDelay = -1 -- delay before official start of race

local started = false -- flag indicating if race started

local startCoord = nil -- coordinates of vehicle once race has started

local heading = nil -- heading of player at last waypoint

local destCoord = nil -- coordinates of destination waypoint

local numWaypointsPassed = -1 -- number of waypoints player has passed
local currentWaypoint = -1 -- current waypoint index - for multi-lap races, actual current waypoint index is currentWaypoint % #waypoints + 1

local currentLap = -1 -- current lap
local lapTimeStart = -1 -- start time of current lap
local bestLapTime = -1 -- best lap time
local bestLapVehicleName = nil -- name of vehicle in which player recorded best lap time

local originalVehicleHash = nil -- vehicle hash of original vehicle before switching to other vehicles in random vehicle races
local originalColorPri = -1 -- primary color of original vehicle
local originalColorSec = -1 -- secondary color of original vehicle
local originalColorPearl = -1 -- pearlescent color of original vehicle
local originalColorWheel = -1 -- wheel color of original vehicle

local respawnVehicleHash = nil -- hash of respawn vehicle being driven
local respawnColorPri = -1 -- primary color of respawn vehicle
local respawnColorSec = -1 -- secondary color of respawn vehicle
local respawnColorPearl = -1 -- pearlescent color of respawn vehicle
local respawnColorWheel = -1 -- wheel color of respawn vehicle
local respawnCtrlPressed = false -- flag indicating if respawn crontrol is pressed
local respawnStart = -1 -- start time when respawn control pressed

local currentVehicleName = nil -- name of current vehicle being driven

local raceVehicleList = {} -- list of vehicles used in random vehicle race

local highlightedIndex = 0 -- index of highlighted checkpoint
local selectedIndex0 = 0 -- index of first selected waypoint
local selectedIndex1 = 0 -- index of second selected waypoint

local trackAccess = nil -- indicaties if saved track is public("pub") or private("pvt")
local savedTrackName = nil -- name of saved track - nil if track not saved

local vehicleList = {} -- vehicle list used for custom class races and random vehicle races

local camTransStarted = false -- flag indicating if camera transition at start of race has started

local vehicleFrozen = false -- flag indicating if vehicle player is in is frozen before start of race

local countdown = -1 -- countdown before start

local position = -1 -- position in race out of numRacers players
local numRacers = -1 -- number of players in race - no DNF players included

local raceCheckpoint = nil -- race checkpoint of current waypoint in world

local racerBlipGT = {} -- racerBlipGT[netID] = {blip, gamerTag, name} - blips, gamer tags and names for all racers participating in race

local results = {} -- results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName} - race results

local speedo = false -- flag indicating if speedometer is displayed
local preRaceSpeedo = speedo -- speedo value before race start
local unitom = "imperial" -- current unit of measurement

local panelsInitialized = false -- flag indicating if selectable fields of all panels have been populated
local panelShown = false -- flag indicating if main, track, ai, list or register panel is shown

local allVehiclesList = {} -- list of all vehicles from vehicles.json

local aiState = nil -- table containing race and AI driver info

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
        SendNUIMessage({
            action = "reply",
            message = string.gsub(msg, "\n", "<br>")
        })
    end
    notifyPlayer(msg)
end

local function copyTable(tbl)
    if nil == tbl then
        return nil
    end
    local t = {}
    for key, value in pairs(tbl) do
        t[key] = value
    end
    return t
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
    elseif 17 == blipColor then
        return orange
    elseif 83 == blipColor then
        return purple
    else
        return yellow
    end
end

local function makeCheckpoint(checkpointType, coord, nextCoord, color, alpha, num)
    local zCoord = coord.z
    if numberedCheckpoint == checkpointType or plainCheckpoint == checkpointType then
        zCoord = zCoord - coord.r / 2.0
    else
        zCoord = zCoord + coord.r / 2.0
    end

    local checkpoint = CreateCheckpoint(checkpointType, coord.x, coord.y, zCoord, nextCoord.x, nextCoord.y, nextCoord.z, coord.r * 2.0, color.r, color.g, color.b, alpha, num)
    SetCheckpointCylinderHeight(checkpoint, 10.0, 10.0, coord.r * 2.0)

    return checkpoint
end

local function setStartToFinishCheckpoints()
    for i = 1, #waypoints do
        local color = getCheckpointColor(waypoints[i].color)
        local checkpointType = -1 == waypoints[i].number and checkeredFlagCheckpoint or numberedCheckpoint
        waypoints[i].checkpoint = makeCheckpoint(checkpointType, waypoints[i].coord, waypoints[i].coord, color, 127, i - 1)
    end
end

local function setBlipProperties(index)
    local waypoint = waypoints[index]
    SetBlipSprite(waypoint.blip, waypoint.sprite)
    SetBlipColour(waypoint.blip, waypoint.color)
    ShowNumberOnBlip(waypoint.blip, waypoint.number)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(waypoint.name)
    EndTextCommandSetBlipName(waypoint.blip)
end

local function setStartToFinishBlips()
    -- waypoints[] = {coord = {x, y, z, r}, checkpoint, blip, sprite, color, number, name}
    if true == startIsFinish then
        waypoints[1].sprite = checkeredFlagSprite
        waypoints[1].color = startFinishBlipColor
        waypoints[1].number = -1
        waypoints[1].name = "Start/Finish"

        if #waypoints > 1 then
            waypoints[#waypoints].sprite = numberedSprite
            waypoints[#waypoints].color = numberedBlipColor
            waypoints[#waypoints].number = #waypoints - 1
            waypoints[#waypoints].name = "Waypoint"
        end
    else -- #waypoints should be > 1
        waypoints[1].sprite = checkeredFlagSprite
        waypoints[1].color = startBlipColor
        waypoints[1].number = -1
        waypoints[1].name = "Start"

        waypoints[#waypoints].sprite = checkeredFlagSprite
        waypoints[#waypoints].color = finishBlipColor
        waypoints[#waypoints].number = -1
        waypoints[#waypoints].name = "Finish"
    end

    for i = 2, #waypoints - 1 do
        waypoints[i].sprite = numberedSprite
        waypoints[i].color = numberedBlipColor
        waypoints[i].number = i - 1
        waypoints[i].name = "Waypoint"
    end

    for i = 1, #waypoints do
        setBlipProperties(i)
    end
end

local function loadWaypointBlips(waypointCoords)
    for i = 1, #waypoints do
        RemoveBlip(waypoints[i].blip)
    end

    waypoints = {}

    for i = 1, #waypointCoords - 1 do
        local blip = AddBlipForCoord(waypointCoords[i].x, waypointCoords[i].y, waypointCoords[i].z)
        waypoints[i] = {coord = waypointCoords[i], checkpoint = nil, blip = blip, sprite = -1, color = -1, number = -1, name = nil}
    end

    startIsFinish =
        waypointCoords[1].x == waypointCoords[#waypointCoords].x and
        waypointCoords[1].y == waypointCoords[#waypointCoords].y and
        waypointCoords[1].z == waypointCoords[#waypointCoords].z

    if false == startIsFinish then
        local blip = AddBlipForCoord(waypointCoords[#waypointCoords].x, waypointCoords[#waypointCoords].y, waypointCoords[#waypointCoords].z)
        waypoints[#waypointCoords] = {coord = waypointCoords[#waypointCoords], checkpoint = nil, blip = blip, sprite = -1, color = -1, number = -1, name = nil}
    end

    setStartToFinishBlips()

    SetBlipRoute(waypoints[1].blip, true)
    SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
end

local function drawMsg(x, y, msg, scale, justify)
    SetTextFont(4)
    SetTextScale(0, scale)
    SetTextColour(255, 255, 0, 255)
    SetTextOutline()
    SetTextJustification(justify)
    SetTextWrap(0.0, 1.0)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayText(x, y)
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

local function loadModel(model)
    RequestModel(model)
    while false == HasModelLoaded(model) do
        Citizen.Wait(0)
    end
end

local function putPedInVehicle(ped, model, priColor, secColor, pearlColor, wheelColor, coord, pedHeading)
    local vehicle = CreateVehicle(model, coord.x, coord.y, coord.z, pedHeading, true, false)

    SetModelAsNoLongerNeeded(model)

    if priColor ~= -1 and secColor ~= -1 and pearlColor ~= -1 and wheelColor ~= -1 then
        SetVehicleColours(vehicle, priColor, secColor)
        SetVehicleExtraColours(vehicle, pearlColor, wheelColor)
    end

    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehRadioStation(vehicle, "OFF")

    SetPedIntoVehicle(ped, vehicle, -1)

    return vehicle
end

local function switchVehicle(ped, model, priColor, secColor, pearlColor, wheelColor)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if 0 == vehicle then
        loadModel(model)
        return putPedInVehicle(ped, model, priColor, secColor, pearlColor, wheelColor, GetEntityCoords(ped), GetEntityHeading(ped))
    end

    local newVehicle = nil

    if GetPedInVehicleSeat(vehicle, -1) == ped then
        local passengers = {}
        for seat = 0, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
            local passenger = GetPedInVehicleSeat(vehicle, seat)
            if passenger ~= 0 then
                passengers[#passengers + 1] = {ped = passenger, seat = seat}
            end
        end

        local coord = GetEntityCoords(vehicle)
        local speed = GetEntitySpeed(vehicle)

        loadModel(model)

        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)

        newVehicle = putPedInVehicle(ped, model, priColor, secColor, pearlColor, wheelColor, coord, GetEntityHeading(ped))
        SetVehicleForwardSpeed(newVehicle, speed)

        for _, passenger in pairs(passengers) do
            SetPedIntoVehicle(passenger.ped, newVehicle, passenger.seat)
        end
    end

    return newVehicle
end

local function getClassName(vclass)
    if -1 == vclass then
        return "'Custom'(-1)"
    elseif vclass >= 0 and vclass <= 22 then
        return "'" .. GetLabelText("VEH_CLASS_" .. vclass) .. "'(" .. vclass .. ")"
    else
        return "'Unknown'(" .. vclass .. ")"
    end
end

local function finishRace(time)
    TriggerServerEvent("races:finish", raceIndex, PedToNet(PlayerPedId()), nil, numWaypointsPassed, time, bestLapTime, bestLapVehicleName, nil)

    for i = 1, #waypoints do
        SetBlipDisplay(waypoints[i].blip, 2)
    end

    local curr = true == startIsFinish and currentWaypoint % #waypoints + 1 or currentWaypoint
    SetBlipColour(waypoints[curr].blip, waypoints[curr].color)

    SetBlipRoute(waypoints[1].blip, true)
    SetBlipRouteColour(waypoints[1].blip, blipRouteColor)

    speedo = preRaceSpeedo

    if "rand" == raceType and originalVehicleHash ~= nil then
        local vehicle = switchVehicle(PlayerPedId(), originalVehicleHash, originalColorPri, originalColorSec, originalColorPearl, originalColorWheel)
        if vehicle ~= nil then
            SetEntityAsNoLongerNeeded(vehicle)
        end
    end

    state = STATE_IDLE
end

local function setBlipCheckpointColor(waypoint, color)
    SetBlipColour(waypoint.blip, color)

    local cpColor = getCheckpointColor(color)
    SetCheckpointRgba(waypoint.checkpoint, cpColor.r, cpColor.g, cpColor.b, 127)
    SetCheckpointRgba2(waypoint.checkpoint, cpColor.r, cpColor.g, cpColor.b, 127)
end

local function editWaypoints(coord)
    local selectedIndex = 0
    local minDist = maxRadius
    for index, waypoint in ipairs(waypoints) do
        local dist = #(coord - vector3(waypoint.coord.x, waypoint.coord.y, waypoint.coord.z))
        if dist < waypoint.coord.r and dist < minDist then
            minDist = dist
            selectedIndex = index
        end
    end

    if 0 == selectedIndex then -- no existing waypoint selected
        if 0 == selectedIndex0 then -- no previous selected waypoints exist, add new waypoint
            local blip = AddBlipForCoord(coord.x, coord.y, coord.z)

            waypoints[#waypoints + 1] = {coord = {x = coord.x, y = coord.y, z = coord.z, r = defaultRadius}, checkpoint = nil, blip = blip, sprite = -1, color = -1, number = -1, name = nil}

            startIsFinish = 1 == #waypoints
            setStartToFinishBlips()
            deleteWaypointCheckpoints()
            setStartToFinishCheckpoints()
        else -- first selected waypoint exists
            if 0 == selectedIndex1 then -- second selected waypoint does not exist, move first selected waypoint to new location
                local selectedWaypoint0 = waypoints[selectedIndex0]
                selectedWaypoint0.coord = {x = coord.x, y = coord.y, z = coord.z, r = selectedWaypoint0.coord.r}

                SetBlipCoords(selectedWaypoint0.blip, coord.x, coord.y, coord.z)

                DeleteCheckpoint(selectedWaypoint0.checkpoint)
                local color = getCheckpointColor(selectedBlipColor)
                local checkpointType = -1 == selectedWaypoint0.number and checkeredFlagCheckpoint or numberedCheckpoint
                selectedWaypoint0.checkpoint = makeCheckpoint(checkpointType, selectedWaypoint0.coord, coord, color, 127, selectedIndex0 - 1)
            else -- second selected waypoint exists, add waypoint between first and second selected waypoints
                for i = #waypoints, selectedIndex1, -1 do
                    waypoints[i + 1] = waypoints[i]
                end

                local blip = AddBlipForCoord(coord.x, coord.y, coord.z)

                waypoints[selectedIndex1] = {coord = {x = coord.x, y = coord.y, z = coord.z, r = defaultRadius}, checkpoint = nil, blip = blip, sprite = -1, color = -1, number = -1, name = nil}

                setStartToFinishBlips()
                deleteWaypointCheckpoints()
                setStartToFinishCheckpoints()

                selectedIndex0 = 0
                selectedIndex1 = 0
            end
        end

        trackAccess = nil
        savedTrackName = nil

        SetBlipRoute(waypoints[1].blip, true)
        SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
    else -- existing waypoint selected
        local selectedWaypoint = waypoints[selectedIndex]
        if 0 == selectedIndex0 then -- no previous selected waypoint exists, show that waypoint is selected
            setBlipCheckpointColor(selectedWaypoint, selectedBlipColor)

            selectedIndex0 = selectedIndex
        else -- first selected waypoint exists
            if selectedIndex == selectedIndex0 then -- selected waypoint and first selected waypoint are the same, unselect
                setBlipCheckpointColor(selectedWaypoint, selectedWaypoint.color)

                if selectedIndex1 ~= 0 then
                    selectedIndex0 = selectedIndex1
                    selectedIndex1 = 0
                else
                    selectedIndex0 = 0
                end
            elseif selectedIndex == selectedIndex1 then -- selected waypoint and second selected waypoint are the same, unselect
                setBlipCheckpointColor(selectedWaypoint, selectedWaypoint.color)

                selectedIndex1 = 0
            else -- selected waypoint and first and second selected waypoints are different
                if 0 == selectedIndex1 then -- second selected waypoint does not exist
                    local splitCombine = false
                    local checkpointType = checkeredFlagCheckpoint
                    local waypointNum = 0
                    if true == startIsFinish then
                        if #waypoints == selectedIndex and 1 == selectedIndex0 then -- split start/finish waypoint
                            splitCombine = true

                            startIsFinish = false

                            waypoints[1].sprite = checkeredFlagSprite
                            waypoints[1].color = startBlipColor
                            waypoints[1].number = -1
                            waypoints[1].name = "Start"

                            waypoints[#waypoints].sprite = checkeredFlagSprite
                            waypoints[#waypoints].color = finishBlipColor
                            waypoints[#waypoints].number = -1
                            waypoints[#waypoints].name = "Finish"
                        end
                    else
                        if 1 == selectedIndex and #waypoints == selectedIndex0 then -- combine start and finish waypoints
                            splitCombine = true

                            startIsFinish = true

                            waypoints[1].sprite = checkeredFlagSprite
                            waypoints[1].color = startFinishBlipColor
                            waypoints[1].number = -1
                            waypoints[1].name = "Start/Finish"

                            waypoints[#waypoints].sprite = numberedSprite
                            waypoints[#waypoints].color = numberedBlipColor
                            waypoints[#waypoints].number = #waypoints - 1
                            waypoints[#waypoints].name = "Waypoint"

                            checkpointType = numberedCheckpoint
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

                        selectedIndex0 = 0
                        trackAccess = nil
                        savedTrackName = nil
                    else
                        if selectedIndex0 + 1 == selectedIndex then
                            setBlipCheckpointColor(selectedWaypoint, selectedBlipColor)

                            selectedIndex1 = selectedIndex
                        elseif selectedIndex0 - 1 == selectedIndex then
                            setBlipCheckpointColor(selectedWaypoint, selectedBlipColor)

                            selectedIndex1 = selectedIndex0
                            selectedIndex0 = selectedIndex
                        else
                            setBlipCheckpointColor(selectedWaypoint, selectedBlipColor)
                            setBlipCheckpointColor(waypoints[selectedIndex0], waypoints[selectedIndex0].color)

                            selectedIndex0 = selectedIndex
                        end
                    end
                else -- second selected waypoint exists
                    if selectedIndex1 + 1 == selectedIndex then
                        setBlipCheckpointColor(selectedWaypoint, selectedBlipColor)
                        setBlipCheckpointColor(waypoints[selectedIndex0], waypoints[selectedIndex0].color)

                        selectedIndex0 = selectedIndex1
                        selectedIndex1 = selectedIndex
                    elseif selectedIndex0 - 1 == selectedIndex then
                        setBlipCheckpointColor(selectedWaypoint, selectedBlipColor)
                        setBlipCheckpointColor(waypoints[selectedIndex1], waypoints[selectedIndex1].color)

                        selectedIndex1 = selectedIndex0
                        selectedIndex0 = selectedIndex
                    else
                        setBlipCheckpointColor(selectedWaypoint, selectedBlipColor)
                        setBlipCheckpointColor(waypoints[selectedIndex0], waypoints[selectedIndex0].color)
                        setBlipCheckpointColor(waypoints[selectedIndex1], waypoints[selectedIndex1].color)

                        selectedIndex0 = selectedIndex
                        selectedIndex1 = 0
                    end
                end
            end
        end
    end
end

local function removeAllRacerBlipGT()
    for _, racer in pairs(racerBlipGT) do
        RemoveBlip(racer.blip)
        RemoveMpGamerTag(racer.gamerTag)
    end

    racerBlipGT = {}
end

local function respawnAI(driver)
    local passengers = {}
    for seat = 0, GetVehicleModelNumberOfSeats(GetEntityModel(driver.vehicle)) - 2 do
        local ped = GetPedInVehicleSeat(driver.vehicle, seat)
        if ped ~= 0 then
            passengers[#passengers + 1] = {ped = ped, seat = seat}
        end
    end

    local priColor, secColor = GetVehicleColours(driver.vehicle)
    local pearlColor, wheelColor = GetVehicleExtraColours(driver.vehicle)

    local vehicleHash = GetEntityModel(driver.vehicle)
    loadModel(vehicleHash)

    SetEntityAsMissionEntity(driver.vehicle, true, true)
    DeleteVehicle(driver.vehicle)

    local coord = driver.startCoord
    if true == aiState.startIsFinish then
        if driver.currentWaypoint > 0 then
            coord = aiState.waypointCoords[driver.currentWaypoint]
        end
    else
        if driver.currentWaypoint > 1 then
            coord = aiState.waypointCoords[driver.currentWaypoint - 1]
        end
    end

    driver.vehicle = putPedInVehicle(driver.ped, vehicleHash, priColor, secColor, pearlColor, wheelColor, coord, driver.heading)

    for _, passenger in pairs(passengers) do
        SetPedIntoVehicle(passenger.ped, driver.vehicle, passenger.seat)
    end

    driver.destSet = true
end

local function updateVehicleList()
    table.sort(vehicleList)
    local html = ""
    for _, model in ipairs(vehicleList) do
        html = html .. "<option value = \"" .. model .. "\">" .. model .. " (" .. GetLabelText(GetDisplayNameFromVehicleModel(model)) .. ")</option>"
    end
    SendNUIMessage({
        action = "update",
        list = "vehicleList",
        vehicleList = html
    })
end

local function updateStartVehicleList(vclass)
    vclass = tonumber(vclass)

    local startVehiclesHTML = "<option value = \"any\">Any</option>"
    for _, model in ipairs(allVehiclesList) do
        if -1 == vclass or GetVehicleClassFromName(model) == vclass then
            startVehiclesHTML = startVehiclesHTML .. "<option value = \"" .. model .. "\">" .. model .. " (" .. GetLabelText(GetDisplayNameFromVehicleModel(model)) .. ")</option>"
        end
    end

    SendNUIMessage({
        action = "update",
        list = "svehicles",
        startVehicles = startVehiclesHTML
    })
end

local function deleteDriver(name, pIndex)
    local driver = aiState.drivers[name]
    if nil == driver then
        sendMessage("Cannot delete '" .. name .. "'.  AI driver not found.\n")
    elseif STATE_RACING == driver.state then
        sendMessage("Cannot delete '" .. name .. "'.  AI driver is in a race.\n")
    elseif driver.state ~= STATE_JOINING then
        sendMessage("Cannot delete '" .. name .. "'.  AI driver is not joined to a race.\n")
    else
        if driver.ped ~= nil then
            TriggerServerEvent("races:leave", pIndex, driver.netID, name)

            DeletePed(driver.ped)
            SetEntityAsMissionEntity(driver.vehicle, true, true)
            DeleteVehicle(driver.vehicle)
        end

        aiState.numRacing = aiState.numRacing - 1
        if aiState.numRacing ~= 0 then
            aiState.drivers[name] = nil
        else
            aiState = nil
        end

        sendMessage("AI driver '" .. name .. "' deleted.\n")
        return true
    end

    return false
end

local function edit()
    if STATE_IDLE == state then
        state = STATE_EDITING
        SetWaypointOff()
        setStartToFinishCheckpoints()
        sendMessage("Editing started.\n")
    elseif STATE_EDITING == state then
        state = STATE_IDLE
        highlightedIndex = 0
        if selectedIndex0 ~= 0 then
            SetBlipColour(waypoints[selectedIndex0].blip, waypoints[selectedIndex0].color)
            selectedIndex0 = 0
        end
        if selectedIndex1 ~= 0 then
            SetBlipColour(waypoints[selectedIndex1].blip, waypoints[selectedIndex1].color)
            selectedIndex1 = 0
        end
        deleteWaypointCheckpoints()
        sendMessage("Editing stopped.\n")
    else
        sendMessage("Cannot edit waypoints.  Leave race first.\n")
    end
end

local function clear()
    if STATE_IDLE == state then
        for i = 1, #waypoints do
            RemoveBlip(waypoints[i].blip)
        end
        waypoints = {}
        startIsFinish = false
        trackAccess = nil
        savedTrackName = nil
        sendMessage("Waypoints cleared.\n")
    elseif STATE_EDITING == state then
        highlightedIndex = 0
        selectedIndex0 = 0
        selectedIndex1 = 0
        for i = 1, #waypoints do
            RemoveBlip(waypoints[i].blip)
            DeleteCheckpoint(waypoints[i].checkpoint)
        end
        waypoints = {}
        startIsFinish = false
        trackAccess = nil
        savedTrackName = nil
        sendMessage("Waypoints cleared.\n")
    else
        sendMessage("Cannot clear waypoints.  Leave race first.\n")
    end
end

local function reverse()
    if #waypoints < 2 then
        sendMessage("Cannot reverse waypoints.  Track needs to have at least 2 waypoints.\n")
    elseif STATE_IDLE == state then
        trackAccess = nil
        savedTrackName = nil
        loadWaypointBlips(waypointsToCoordsRev())
        sendMessage("Waypoints reversed.\n")
    elseif STATE_EDITING == state then
        trackAccess = nil
        savedTrackName = nil
        highlightedIndex = 0
        selectedIndex0 = 0
        selectedIndex1 = 0
        deleteWaypointCheckpoints()
        loadWaypointBlips(waypointsToCoordsRev())
        setStartToFinishCheckpoints()
        sendMessage("Waypoints reversed.\n")
    else
        sendMessage("Cannot reverse waypoints.  Leave race first.\n")
    end
end

local function loadTrack(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot load track.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot load track.  Name required.\n")
    elseif STATE_JOINING == state or STATE_RACING == state then
        sendMessage("Cannot load track '" .. name .. "'.  Leave race first.\n")
    else
        TriggerServerEvent("races:load", access, name)
    end
end

local function saveTrack(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot save track.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot save track.  Name required.\n")
    elseif #waypoints < 2 then
        sendMessage("Cannot save track '" .. name .. "'.  Track needs to have at least 2 waypoints.\n")
    else
        TriggerServerEvent("races:save", access, name, waypointsToCoords())
    end
end

local function overwriteTrack(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot overwrite track.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot overwrite track.  Name required.\n")
    elseif #waypoints < 2 then
        sendMessage("Cannot overwrite track '" .. name .. "'.  Track needs to have at least 2 waypoints.\n")
    else
        TriggerServerEvent("races:overwrite", access, name, waypointsToCoords())
    end
end

local function deleteTrack(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot delete track.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot delete track.  Name required.\n")
    else
        TriggerServerEvent("races:delete", access, name)
    end
end

local function listTracks(access)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot list tracks.  Invalid access type.\n")
    else
        TriggerServerEvent("races:list", access)
    end
end

local function bestLapTimes(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot list best lap times.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot list best lap times.  Name required.\n")
    else
        TriggerServerEvent("races:blt", access, name)
    end
end

local function spawnAIDriver(name, model, coord, aiHeading)
    if nil == name then
        sendMessage("Cannot spawn AI driver.  Name required.\n")
        return false
    end

    model = model or defaultModel
    if false == IsModelInCdimage(model) or false == IsModelAVehicle(model) then
        sendMessage("Cannot spawn  '" .. name .. "'.  Invalid vehicle.\n")
        return false
    end

    local pIndex = GetPlayerServerId(PlayerId())
    local race = races[pIndex]
    if nil == race then
        sendMessage("Cannot spawn  '" .. name .. "'.  Race has not been registered.\n")
        return false
    elseif "no" == race.allowAI then
        sendMessage("Cannot spawn  '" .. name .. "'.  AI drivers not allowed.\n")
        return false
    end

    if nil == aiState then
        aiState = {
            waypointCoords = {},
            startIsFinish = false,
            numLaps = race.laps,
            DNFTimeout = race.timeout * 1000,
            beginDNFTimeout = false,
            DNFTimeoutStart = -1,
            raceType = race.rtype,
            startVehicle = race.svehicle,
            recurring = "yes" == race.recur,
            ordered = "yes" == race.order,
            raceStart = -1,
            raceDelay = -1,
            numRacing = 0,
            drivers = {}
        }
    end

    if nil == aiState.drivers[name] then
        aiState.drivers[name] = {
            state = STATE_JOINING,
            started = false,
            startCoord = coord,
            heading = aiHeading,
            destCoord = nil,
            destSet = false,
            numWaypointsPassed = 0,
            currentWaypoint = -1,
            currentLap = 1,
            lapTimeStart = -1,
            bestLapTime = -1,
            bestLapVehicleName = nil,
            raceVehicleList = nil,
            model = nil,
            vehicle = nil,
            colorPri = -1,
            colorSec = -1,
            colorPearl = -1,
            colorWheel = -1,
            ped = nil,
            netID = nil,
            enteringVehicle = false,
            stuckCoord = coord,
            stuckStart = -1
        }

        aiState.numRacing = aiState.numRacing + 1
    end

    if "rest" == race.rtype then
        if model ~= race.restrict then
            sendMessage("Cannot spawn '" .. name .. "'.  AI driver must be in '" .. race.restrict .. "' vehicle.\n")
            return false
        end
    elseif "class" == race.rtype then
        if race.vclass ~= -1 then
            if GetVehicleClassFromName(model) ~= race.vclass then
                sendMessage("Cannot spawn  '" .. name .. "'.  AI driver must be in vehicle of " .. getClassName(race.vclass) .. " class.\n")
                return false
            end
        else
            local found = false
            local list = ""
            for _, vehModel in pairs(race.vehicleList) do
                if model == vehModel then
                    found = true
                    break
                end
                list = list .. vehModel .. ", "
            end

            if false == found then
                sendMessage("Cannot spawn  '" .. name .. "'.  AI driver must be in one of the following vehicles: " .. string.sub(list, 1, -3) .. "\n")
                return false
            end
        end
    elseif "rand" == race.rtype then
        if race.vclass ~= nil and nil == race.svehicle and GetVehicleClassFromName(model) ~= race.vclass then
            sendMessage("Cannot spawn  '" .. name .. "'.  AI driver must be in vehicle of " .. getClassName(race.vclass) .. " class.\n")
            return false
        end
    end

    sendMessage("Attempting to spawn AI driver '" .. name .. "' in '" .. GetLabelText(GetDisplayNameFromVehicleModel(model)) .. "'.\n")

    local minimum, maximum = GetModelDimensions(model)
    local radius = (maximum.y - minimum.y) / 2.0 + 2.0
    local player = PlayerPedId()
    if 1 == IsPedInAnyVehicle(player, false) then
        minimum, maximum = GetModelDimensions(GetEntityModel(GetVehiclePedIsIn(player, false)))
        radius = radius + (maximum.y - minimum.y) / 2.0
    end
    local driver = aiState.drivers[name]
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if #(GetEntityCoords(player) - driver.startCoord) > radius then
                driver.raceVehicleList = copyTable(race.vehicleList)

                driver.model = model

                if driver.vehicle ~= nil then
                    driver.vehicle = switchVehicle(driver.ped, model, -1, -1, -1, -1)
                else
                    loadModel(model)

                    local pedModel = "a_m_y_skater_01"
                    loadModel(pedModel)

                    driver.vehicle = CreateVehicle(model, driver.startCoord.x, driver.startCoord.y, driver.startCoord.z, driver.heading, true, false)
                    SetModelAsNoLongerNeeded(model)

                    driver.ped = CreatePedInsideVehicle(driver.vehicle, PED_TYPE_CIVMALE, pedModel, -1, true, false)
                    SetModelAsNoLongerNeeded(pedModel)
                    SetDriverAbility(driver.ped, 1.0)
                    SetDriverAggressiveness(driver.ped, 0.0)
                    SetBlockingOfNonTemporaryEvents(driver.ped, true)
                    SetPedCanBeDraggedOut(driver.ped, false)

                    while false == NetworkGetEntityIsNetworked(driver.ped) do
                        Citizen.Wait(0)
                        NetworkRegisterEntityAsNetworked(driver.ped)
                    end
                    driver.netID = PedToNet(driver.ped)

                    TriggerServerEvent("races:join", pIndex, driver.netID, name)
                end

                if "rand" == aiState.raceType then
                    driver.colorPri, driver.colorSec = GetVehicleColours(driver.vehicle)
                    driver.colorPearl, driver.colorWheel = GetVehicleExtraColours(driver.vehicle)
                end

                driver.bestLapVehicleName = GetLabelText(GetDisplayNameFromVehicleModel(model))

                sendMessage("AI driver '" .. name .. "' spawned in '" .. driver.bestLapVehicleName .. "'.\n")

                break
            end
        end
    end)

    return true
end

local function deleteAIDriver(name)
    if nil == name then
        sendMessage("Cannot delete AI driver.  Name required.\n")
    else
        local pIndex = GetPlayerServerId(PlayerId())
        if nil == races[pIndex] then
            sendMessage("Cannot delete '" .. name .. "'.  Race has not been registered.\n")
        elseif "no" == races[pIndex].allowAI then
            sendMessage("Cannot delete '" .. name .. "'.  AI drivers not allowed.\n")
        elseif nil == aiState then
            sendMessage("Cannot delete '" .. name .. "'.  No AI drivers to delete.\n")
        else
            return deleteDriver(name, pIndex)
        end
    end

    return false
end

local function deleteAllAIDrivers()
    local pIndex = GetPlayerServerId(PlayerId())
    if nil == races[pIndex] then
        sendMessage("Cannot delete all AI drivers.  Race has not been registered.\n")
    elseif "no" == races[pIndex].allowAI then
        sendMessage("Cannot delete all AI drivers.  AI drivers not allowed.\n")
    else
        if nil == aiState then
            sendMessage("No AI drivers to delete.\n")
        else
            for name in pairs(aiState.drivers) do
                if false == deleteDriver(name, pIndex) then
                    sendMessage("Cannot delete all AI drivers.  Some AI drivers could not be deleted.\n")
                    return false
                end
            end
            sendMessage("All AI deleted.\n")
        end

        return true
    end

    return false
end

local function listAIDrivers()
    local race = races[GetPlayerServerId(PlayerId())]
    if nil == race then
        sendMessage("Cannot list AI drivers.  Race has not been registered.\n")
    elseif "no" == race.allowAI then
        sendMessage("Cannot list AI drivers.  AI drivers not allowed.\n")
    elseif nil == aiState then
        sendMessage("Cannot list AI drivers.  No AI drivers to list.\n")
    else
        local names = {}
        for name in pairs(aiState.drivers) do
            names[#names + 1] = name
        end
        table.sort(names)

        local msg = "AI drivers:\n"
        for _, name in ipairs(names) do
            msg = msg .. name .. " - "
            local driver = aiState.drivers[name]
            if driver.ped ~= nil then
                msg = msg .. driver.model .. " (" .. GetLabelText(GetDisplayNameFromVehicleModel(driver.model)) .. ")\n"
            else
                msg = msg .. "NO VEHICLE\n"
            end
        end
        sendMessage(msg)
    end
end

local function loadGrp(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot load AI group.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot load AI group.  Name required.\n")
    else
        local race = races[GetPlayerServerId(PlayerId())]
        if nil == race then
            sendMessage("Cannot load AI group '" .. name .. "'.  Race has not been registered.\n")
        elseif "no" == race.allowAI then
            sendMessage("Cannot load AI group '" .. name .. "'.  AI drivers not allowed.\n")
        else
            TriggerServerEvent("races:loadGrp", access, name)
        end
    end
end

local function saveGrp(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot save AI group.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot save AI group.  Name required.\n")
    else
        local race = races[GetPlayerServerId(PlayerId())]
        if nil == race then
            sendMessage("Cannot save AI group '" .. name .. "'.  Race has not been registered.\n")
        elseif "no" == race.allowAI then
            sendMessage("Cannot save AI group '" .. name .. "'.  AI drivers not allowed.\n")
        elseif nil == aiState then
            sendMessage("Cannot save AI group '" .. name .. "'.  No AI drivers added.\n")
        else
            local group = {}
            for aiName, driver in pairs(aiState.drivers) do
                if nil == driver.ped then
                    sendMessage("Cannot save AI group '" .. name .. "'.  Some AI drivers not spawned.\n")
                    return
                end
                group[aiName] = {startCoord = driver.startCoord, heading = driver.heading, model = driver.model}
            end
            TriggerServerEvent("races:saveGrp", access, name, group)
        end
    end
end

local function overwriteGrp(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot overwrite AI group.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot overwrite AI group.  Name required.\n")
    else
        local race = races[GetPlayerServerId(PlayerId())]
        if nil == race then
            sendMessage("Cannot overwrite AI group '" .. name .. "'.  Race has not been registered.\n")
        elseif "no" == race.allowAI then
            sendMessage("Cannot overwrite AI group '" .. name .. "'.  AI drivers not allowed.\n")
        elseif nil == aiState then
            sendMessage("Cannot overwrite AI group '" .. name .. "'.  No AI drivers added.\n")
        else
            local group = {}
            for aiName, driver in pairs(aiState.drivers) do
                if nil == driver.ped then
                    sendMessage("Cannot overwrite AI group '" .. name .. "'.  Some AI drivers not spawned.\n")
                    return
                end
                group[aiName] = {startCoord = driver.startCoord, heading = driver.heading, model = driver.model}
            end
            TriggerServerEvent("races:overwriteGrp", access, name, group)
        end
    end
end

local function deleteGrp(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot delete AI group.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot delete AI group.  Name required.\n")
    else
        TriggerServerEvent("races:deleteGrp", access, name)
    end
end

local function listGrps(access)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot list AI groups.  Invalid access type.\n")
    else
        TriggerServerEvent("races:listGrps", access)
    end
end

local function addVeh(model)
    if nil == model or false == IsModelInCdimage(model) or false == IsModelAVehicle(model) then
        sendMessage("Cannot add vehicle.  Invalid vehicle model.\n")
    else
        vehicleList[#vehicleList + 1] = model

        updateVehicleList()

        sendMessage("'" .. model .. "' added to vehicle list.\n")
    end
end

local function deleteVeh(model)
    if nil == model or false == IsModelInCdimage(model) or false == IsModelAVehicle(model) then
        sendMessage("Cannot delete vehicle.  Invalid vehicle model.\n")
    else
        for i = 1, #vehicleList do
            if vehicleList[i] == model then
                table.remove(vehicleList, i)

                updateVehicleList()

                sendMessage("'" .. model .. "' deleted from vehicle list.\n")
                return
            end
        end
        sendMessage("Cannot delete vehicle '" .. model .. "'.  Vehicle not found.\n")
    end
end

local function addClass(vclass)
    vclass = tonumber(vclass)
    if fail == vclass or math.type(vclass) ~= "integer" or vclass < 0 or vclass > 22 then
        sendMessage("Cannot add vehicles to vehicle list.  Invalid vehicle class.\n")
    else
        for _, model in ipairs(allVehiclesList) do
            if GetVehicleClassFromName(model) == vclass then
                vehicleList[#vehicleList + 1] = model
            end
        end

        updateVehicleList()

        sendMessage("Vehicles of " .. getClassName(vclass) .. " class added to vehicle list.\n")
    end
end

local function deleteClass(vclass)
    vclass = tonumber(vclass)
    if fail == vclass or math.type(vclass) ~= "integer" or vclass < 0 or vclass > 22 then
        sendMessage("Cannot delete vehicles from vehicle list.  Invalid vehicle class.\n")
    else
        local vehList = {}
        for _, model in pairs(vehicleList) do
            if GetVehicleClassFromName(model) ~= vclass then
                vehList[#vehList + 1] = model
            end
        end
        vehicleList = vehList

        updateVehicleList()

        sendMessage("Vehicles of " .. getClassName(vclass) .. " class deleted from vehicle list.\n")
    end
end

local function addAllVeh()
    for _, model in ipairs(allVehiclesList) do
        vehicleList[#vehicleList + 1] = model
    end

    updateVehicleList()

    sendMessage("Added all vehicles to vehicle list.\n")
end

local function deleteAllVeh()
    vehicleList = {}

    updateVehicleList()

    sendMessage("Deleted all vehicles from vehicle list.\n")
end

local function listVeh()
    if 0 == #vehicleList then
        sendMessage("Cannot list vehicles.  Vehicle list is empty.\n")
    else
        table.sort(vehicleList)
        local msg = "Vehicle list: "
        for _, model in ipairs(vehicleList) do
            msg = msg .. model .. " (" .. GetLabelText(GetDisplayNameFromVehicleModel(model)) .. "), "
        end
        sendMessage(string.sub(msg, 1, -3) .. "\n")
    end
end

local function loadLst(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot load vehicle list.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot load vehicle list.  Name required.\n")
    else
        TriggerServerEvent("races:loadLst", access, name)
    end
end

local function saveLst(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot save vehicle list.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot save vehicle list.  Name required.\n")
    elseif 0 == #vehicleList then
        sendMessage("Cannot save vehicle list '" .. name .. "'.  List is empty.\n")
    else
        TriggerServerEvent("races:saveLst", access, name, vehicleList)
    end
end

local function overwriteLst(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot overwrite vehicle list.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot overwrite vehicle list.  Name required.\n")
    elseif 0 == #vehicleList then
        sendMessage("Cannot overwrite vehicle list '" .. name .. "'.  List is empty.\n")
    else
        TriggerServerEvent("races:overwriteLst", access, name, vehicleList)
    end
end

local function deleteLst(access, name)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot delete vehicle list.  Invalid access type.\n")
    elseif nil == name then
        sendMessage("Cannot delete vehicle list.  Name required.\n")
    else
        TriggerServerEvent("races:deleteLst", access, name)
    end
end

local function listLsts(access)
    if access ~= "pvt" and access ~= "pub" then
        sendMessage("Cannot list vehicle lists.  Invalid access type.\n")
    else
        TriggerServerEvent("races:listLsts", access)
    end
end

local function register(buyin, laps, timeout, allowAI, rtype, arg0, arg1, arg2, arg3)
    if races[GetPlayerServerId(PlayerId())] ~= nil then
        sendMessage("Cannot register race.  Previous race registered.  Unregister first.\n")
        return
    elseif #waypoints < 2 then
        sendMessage("Cannot register race.  Track needs to have at least 2 waypoints.\n")
        return
    end

    buyin = (buyin == nil or buyin == ".") and defaultBuyin or tonumber(buyin)
    if fail == buyin or math.type(buyin) ~= "integer" or buyin < 0 then
        sendMessage("Cannot register race. Invalid buy-in amount.\n")
        return
    end

    laps = (laps == nil or laps == ".") and defaultLaps or tonumber(laps)
    if fail == laps or math.type(laps) ~= "integer" or laps < 1 then
        sendMessage("Cannot register race. Invalid number of laps.\n")
        return
    end

    timeout = (timeout == nil or timeout == ".") and defaultTimeout or tonumber(timeout)
    if fail == timeout or math.type(timeout) ~= "integer" or timeout < 0 then
        sendMessage("Cannot register race. Invalid DNF timeout.\n")
        return
    end

    allowAI = (allowAI == nil or allowAI == ".") and defaultAllowAI or allowAI
    if allowAI ~= "yes" and allowAI ~= "no" then
        sendMessage("Cannot register race. Invalid allow AI value.\n")
        return
    elseif STATE_JOINING == state or STATE_RACING == state then
        sendMessage("Cannot register race.  Leave race first.\n")
        return
    elseif laps > 1 and false == startIsFinish then
        sendMessage("Cannot register race.  Track needs to be converted to a circuit for multi-lap races.\n")
        return
    end

    local coord = vector3(waypoints[1].coord.x, waypoints[1].coord.y, waypoints[1].coord.z)
    for _, race in pairs(races) do
        if #(coord - GetBlipCoords(race.blip)) < defaultRadius then
            sendMessage("Cannot register race.  Registration point in use by another race.\n")
            return
        end
    end

    local restrict = nil
    local vclass = nil
    local className = nil
    local svehicle = nil
    local recur = nil
    local order = nil
    local vehList = nil
    if "rest" == rtype then
        restrict = arg0
        if nil == restrict or false == IsModelInCdimage(restrict) or false == IsModelAVehicle(restrict) then
            sendMessage("Cannot register race.  Invalid restricted vehicle.\n")
            return
        end
    elseif "class" == rtype then
        vclass = tonumber(arg0)
        if fail == vclass or math.type(vclass) ~= "integer" or vclass < -1 or vclass > 22 then
            sendMessage("Cannot register race.  Invalid vehicle class.\n")
            return
        end

        if -1 == vclass then
            if 0 == #vehicleList then
                sendMessage("Cannot register race.  Vehicle list is empty.\n")
                return
            end
            vehList = vehicleList
        end

        className = getClassName(vclass)
    elseif "rand" == rtype then
        if 0 == #vehicleList  then
            sendMessage("Cannot register race.  Vehicle list is empty.\n")
            return
        end

        if laps < 2 then
            sendMessage("Cannot register race.  Random races require at least 2 laps.\n")
            return
        end

        if "." == arg0 then
            arg0 = nil
        end
        if "." == arg1 then
            arg1 = nil
        end
        if "." == arg2 then
            arg2 = nil
        end
        if "." == arg3 then
            arg3 = nil
        end

        vclass = arg0
        if nil == vclass then
            vehList = vehicleList
        else
            vclass = tonumber(vclass)
            if fail == vclass or math.type(vclass) ~= "integer" or vclass < 0 or vclass > 22 then
                sendMessage("Cannot register race.  Invalid vehicle class.\n")
                return
            end

            className = getClassName(vclass)

            vehList = {}
            for _, model in pairs(vehicleList) do
                if GetVehicleClassFromName(model) == vclass then
                    vehList[#vehList + 1] = model
                end
            end
            if 0 == #vehList then
                sendMessage("Cannot register race.  No vehicles of " .. className .. " class in vehicle list.\n")
                return
            end
        end

        svehicle = arg1
        if svehicle ~= nil then
            if false == IsModelInCdimage(svehicle) or false == IsModelAVehicle(svehicle) then
                sendMessage("Cannot register race.  Invalid start vehicle.\n")
                return
            elseif vclass ~= nil and GetVehicleClassFromName(svehicle) ~= vclass then
                sendMessage("Cannot register race.  Start vehicle not of " .. className .. " class.\n")
                return
            end
        end

        recur = arg2 or defaultRecur
        if recur ~= "yes" and recur ~= "no" then
            sendMessage("Cannot register race.  Invalid recur value.\n")
            return
        end
        if "no" == recur then
            if #vehList < laps - 1 then
                if vclass ~= nil then
                    sendMessage("Cannot register race.  Number of vehicles of " .. className .. " class in vehicle list (currently " .. #vehList .. ") is less than number of laps minus one (currently " .. laps - 1 .. ").\n")
                else
                    sendMessage("Cannot register race.  Number of vehicles in vehicle list (currently " .. #vehList .. ") is less than number of laps minus one (currently " .. laps - 1 .. ").\n")
                end
                return
            end
        end

        order = arg3 or defaultOrder
        if order ~= "yes" and order ~= "no" then
            sendMessage("Cannot register race.  Invalid order value.\n")
            return
        end
        if "yes" == order then
            local tmpVehList = copyTable(vehList)
            vehList = {}
            for i = 1, laps - 1 do
                local index = math.random(#tmpVehList)
                vehList[i] = tmpVehList[index]
                if "no" == recur then
                    table.remove(tmpVehList, index)
                end
            end
        end
    elseif rtype ~= nil then
        sendMessage("Cannot register race.  Unknown race type.\n")
        return
    end

    if "yes" == allowAI or "rand" == rtype then
        buyin = 0
    end

    local rdata = {
        owner = GetPlayerName(PlayerId()),
        access = trackAccess,
        trackName = savedTrackName,
        buyin = buyin,
        laps = laps,
        timeout = timeout,
        allowAI = allowAI,
        rtype = rtype,
        restrict = restrict,
        vclass = vclass,
        className = className,
        svehicle = svehicle,
        recur = recur,
        order = order,
        vehicleList = vehList
    }
    TriggerServerEvent("races:register", waypointsToCoords(), rdata)
end

local function unregister()
    TriggerServerEvent("races:unregister")
end

local function startRace(delay)
    delay = nil == delay and defaultDelay or tonumber(delay)
    if fail == delay or math.type(delay) ~= "integer" or delay < minDelay then
        sendMessage("Cannot start race.  Invalid delay.\n")
    else
        if aiState ~= nil then
            for _, driver in pairs(aiState.drivers) do
                if nil == driver.ped then
                    sendMessage("Cannot start race.  Some AI drivers not spawned.\n")
                    return
                end
            end
        end

        TriggerServerEvent("races:start", delay)
    end
end

local function leave()
    local player = PlayerPedId()
    if STATE_JOINING == state then
        state = STATE_IDLE
        TriggerServerEvent("races:leave", raceIndex, PedToNet(player), nil)
        removeAllRacerBlipGT()
        raceIndex = -1
        sendMessage("Left race.\n")
    elseif STATE_RACING == state then
        if 1 == IsPedInAnyVehicle(player, false) then
            FreezeEntityPosition(GetVehiclePedIsIn(player, false), false)
        end
        RenderScriptCams(false, false, 0, true, true)
        DeleteCheckpoint(raceCheckpoint)
        finishRace(-1)
        removeAllRacerBlipGT()
        speedo = preRaceSpeedo
        sendMessage("Left race.\n")
    else
        sendMessage("Cannot leave.  Not joined to any race.\n")
    end
end

local function rivals()
    if STATE_EDITING == state or STATE_IDLE == state then
        sendMessage("Cannot list rivals.  Not joined to any race.\n")
    else
        TriggerServerEvent("races:rivals", raceIndex)
    end
end

local function respawn()
    if state ~= STATE_RACING then
        sendMessage("Cannot respawn.  Not in a race.\n")
        return
    end

    local player = PlayerPedId()
    local passengers = {}
    local vehicle = GetVehiclePedIsIn(player, false)
    if vehicle ~= 0 then
        if GetPedInVehicleSeat(vehicle, -1) ~= player then
            sendMessage("Cannot respawn.  Not driver of vehicle.\n")
            return
        end

        if respawnVehicleHash ~= nil then
            for seat = 0, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
                local passenger = GetPedInVehicleSeat(vehicle, seat)
                if passenger ~= 0 then
                    passengers[#passengers + 1] = {ped = passenger, seat = seat}
                end
            end

            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteVehicle(vehicle)
        end
    end

    local coord = startCoord
    if true == startIsFinish then
        if currentWaypoint > 0 then
            coord = waypoints[currentWaypoint].coord
        end
    else
        if currentWaypoint > 1 then
            coord = waypoints[currentWaypoint - 1].coord
        end
    end

    if respawnVehicleHash ~= nil then -- respawnVehicleHash should not be nil for raceType "rest", "class" or ("rand" where startVehicle is not nil)
        loadModel(respawnVehicleHash)
        vehicle = putPedInVehicle(player, respawnVehicleHash, respawnColorPri, respawnColorSec, respawnColorPearl, respawnColorWheel, coord, heading)
        SetEntityAsNoLongerNeeded(vehicle)
        for _, passenger in pairs(passengers) do
            SetPedIntoVehicle(passenger.ped, vehicle, passenger.seat)
        end
        SetGameplayCamRelativeRotation(GetEntityRotation(vehicle, 2))
    else -- raceType should be nil or ("rand" where startVehicle is nil)
        SetEntityCoords(player, coord.x, coord.y, coord.z, false, false, false, true)
        SetEntityHeading(player, heading)
        SetGameplayCamRelativeRotation(GetEntityRotation(player, 2))
    end
end

local function viewResults(chatOnly)
    local msg = "Race results:\n"
    if 0 == #results then
        msg = "No results to view.\n"
    else
        -- results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}
        for pos, result in ipairs(results) do
            if -1 == result.finishTime then
                msg = msg .. "DNF - " .. result.playerName

                if result.bestLapTime ~= -1 then
                    local minutes, seconds = minutesSeconds(result.bestLapTime)
                    msg = msg .. (" - best lap %02d:%05.2f"):format(minutes, seconds)
                end

                msg = msg .. " using " .. result.vehicleName .. "\n"
            else
                local fMinutes, fSeconds = minutesSeconds(result.finishTime)
                local lMinutes, lSeconds = minutesSeconds(result.bestLapTime)
                msg = msg .. ("%d - %02d:%05.2f - %s - best lap %02d:%05.2f using %s\n"):format(pos, fMinutes, fSeconds, result.playerName, lMinutes, lSeconds, result.vehicleName)
            end
        end
    end

    if true == chatOnly then
        notifyPlayer(msg)
    else
        sendMessage(msg)
    end
end

local function spawn(model)
    model = model or defaultModel
    if false == IsModelInCdimage(model) or false == IsModelAVehicle(model) then
        sendMessage("Cannot spawn vehicle.  Invalid vehicle.\n")
    elseif STATE_JOINING == state or STATE_RACING == state then
        sendMessage("Cannot spawn '" .. model .. "' vehicle.  Leave race first.\n")
    else
        local vehicle = switchVehicle(PlayerPedId(), model, -1, -1, -1, -1)
        if nil == vehicle then
            sendMessage("Cannot spawn '" .. model .. "' vehicle.  Not driver of current vehicle.\n")
        else
            SetEntityAsNoLongerNeeded(vehicle)
            sendMessage("'" .. GetLabelText(GetDisplayNameFromVehicleModel(model)) .. "' spawned.\n")
        end
    end
end

local function lvehicles(vclass)
    local msg = "Available vehicles"
    if vclass ~= nil then
        vclass = tonumber(vclass)
        if fail == vclass or math.type(vclass) ~= "integer" or vclass < 0 or vclass > 22 then
            sendMessage("Cannot list vehicles.  Invalid vehicle class.\n")
            return
        end
        msg = msg .. " of " .. getClassName(vclass) .. " class: "
    else
        msg = msg .. ": "
    end

    local vehicleFound = false
    for _, model in ipairs(allVehiclesList) do
        if nil == vclass or GetVehicleClassFromName(model) == vclass then
            msg = msg .. model .. " (" .. GetLabelText(GetDisplayNameFromVehicleModel(model)) .. "), "
            vehicleFound = true
        end
    end

    if false == vehicleFound then
        if vclass ~= nil then
            sendMessage("No vehicles of " .. getClassName(vclass) .. " class in list.\n")
        else
            sendMessage("No vehicles in list.\n")
        end
    else
        sendMessage(string.sub(msg, 1, -3) .. "\n")
    end
end

local function setSpeedo(unit)
    if unit ~= nil then
        if unit ~= "imperial" and unit ~= "metric" then
            sendMessage("Invalid unit of measurement.\n")
        else
            unitom = unit
            sendMessage("Unit of measurement changed to '" .. unit .. "'.\n")
        end
    elseif STATE_RACING == state then
        sendMessage("Cannot turn off speedometer while in a race.\n")
    else
        speedo = not speedo
        sendMessage(true == speedo and "Speedometer enabled.\n" or "Speedometer disabled.\n")
    end
end

local function viewFunds()
    TriggerServerEvent("races:funds")
end

local function showPanel(panel)
    if panel ~= nil and panel ~= "track" and panel ~= "ai" and panel ~= "list" and panel ~= "register" then
        notifyPlayer("Invalid panel.\n")
        return
    end
    panel = panel or "main"

    if false == panelsInitialized then
        panelsInitialized = true

        TriggerServerEvent("races:initPanels")

        updateVehicleList()

        local allVehiclesHTML = ""
        for _, model in ipairs(allVehiclesList) do
            allVehiclesHTML = allVehiclesHTML .. "<option value = \"" .. model .. "\">" .. model .. " (" .. GetLabelText(GetDisplayNameFromVehicleModel(model)) .. ")</option>"
        end

        local classesHTML = ""
        for vclass = 0, 22 do
            classesHTML = classesHTML .. "<option value = " .. vclass .. ">" .. vclass .. ":" .. GetLabelText("VEH_CLASS_" .. vclass) .. "</option>"
        end

        SendNUIMessage({
            action = "init",
            allVehicles = allVehiclesHTML,
            classes = classesHTML,
            defaultBuyin = defaultBuyin,
            defaultLaps = defaultLaps,
            defaultTimeout = defaultTimeout,
            defaultAllowAI = defaultAllowAI,
            defaultRecur = defaultRecur,
            defaultOrder = defaultOrder,
            defaultModel = defaultModel,
            defaultDelay = defaultDelay
        })
    end

    SendNUIMessage({
        action = "open",
        panel = panel
    })

    SetNuiFocus(true, true)

    panelShown = true
end

RegisterNUICallback("edit", function(_, cb)
    edit()
    cb()
end)

RegisterNUICallback("clear", function(_, cb)
    clear()
    cb()
end)

RegisterNUICallback("reverse", function(_, cb)
    reverse()
    cb()
end)

RegisterNUICallback("load", function(data, cb)
    loadTrack(data.access, data.name)
    cb()
end)

RegisterNUICallback("save", function(data, cb)
    local name = data.name
    if "" == name then
        name = nil
    end
    saveTrack(data.access, name)
    cb()
end)

RegisterNUICallback("overwrite", function(data, cb)
    overwriteTrack(data.access, data.name)
    cb()
end)

RegisterNUICallback("delete", function(data, cb)
    deleteTrack(data.access, data.name)
    cb()
end)

RegisterNUICallback("list", function(data, cb)
    listTracks(data.access)
    cb()
end)

RegisterNUICallback("blt", function(data, cb)
    bestLapTimes(data.access, data.name)
    cb()
end)

RegisterNUICallback("spawn_ai", function(data, cb)
    local name = data.name
    if "" == name then
        name = nil
    end
    local vehicle = data.vehicle
    if "" == vehicle then
        vehicle = nil
    end
    spawnAIDriver(name, vehicle, GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
    cb()
end)

RegisterNUICallback("delete_ai", function(data, cb)
    local name = data.name
    if "" == name then
        name = nil
    end
    deleteAIDriver(name)
    cb()
end)

RegisterNUICallback("delete_all_ai", function(_, cb)
    deleteAllAIDrivers()
    cb()
end)

RegisterNUICallback("list_ai", function(_, cb)
    listAIDrivers()
    cb()
end)

RegisterNUICallback("load_grp", function(data, cb)
    loadGrp(data.access, data.name)
    cb()
end)

RegisterNUICallback("save_grp", function(data, cb)
    local name = data.name
    if "" == name then
        name = nil
    end
    saveGrp(data.access, name)
    cb()
end)

RegisterNUICallback("overwrite_grp", function(data, cb)
    overwriteGrp(data.access, data.name)
    cb()
end)

RegisterNUICallback("delete_grp", function(data, cb)
    deleteGrp(data.access, data.name)
    cb()
end)

RegisterNUICallback("list_grps", function(data, cb)
    listGrps(data.access)
    cb()
end)

RegisterNUICallback("add_veh", function(data, cb)
    addVeh(data.vehicle)
    cb()
end)

RegisterNUICallback("delete_veh", function(data, cb)
    deleteVeh(data.vehicle)
    cb()
end)

RegisterNUICallback("add_class", function(data, cb)
    addClass(data.class)
    cb()
end)

RegisterNUICallback("delete_class", function(data, cb)
    deleteClass(data.class)
    cb()
end)

RegisterNUICallback("add_all_veh", function(_, cb)
    addAllVeh()
    cb()
end)

RegisterNUICallback("delete_all_veh", function(_, cb)
    deleteAllVeh()
    cb()
end)

RegisterNUICallback("list_veh", function(_, cb)
    listVeh()
    cb()
end)

RegisterNUICallback("load_list", function(data, cb)
    loadLst(data.access, data.name)
    cb()
end)

RegisterNUICallback("save_list", function(data, cb)
    local name = data.name
    if "" == name then
        name = nil
    end
    saveLst(data.access, name)
    cb()
end)

RegisterNUICallback("overwrite_list", function(data, cb)
    overwriteLst(data.access, data.name)
    cb()
end)

RegisterNUICallback("delete_list", function(data, cb)
    deleteLst(data.access, data.name)
    cb()
end)

RegisterNUICallback("list_lists", function(data, cb)
    listLsts(data.access)
    cb()
end)

RegisterNUICallback("vclass", function(data, cb)
    updateStartVehicleList(data.vclass)
    cb()
end)

RegisterNUICallback("register", function(data, cb)
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
    local vclass = data.vclass
    if "rand" == rtype and "-1" == vclass then
        vclass = nil
    end
    local svehicle = data.svehicle
    if "any" == svehicle then
        svehicle = nil
    end
    if nil == rtype then
        register(buyin, laps, timeout, data.allowAI, rtype, nil, nil, nil, nil)
    elseif "rest" == rtype then
        register(buyin, laps, timeout, data.allowAI, rtype, restrict, nil, nil, nil)
    elseif "class" == rtype then
        register(buyin, laps, timeout, data.allowAI, rtype, vclass, nil, nil, nil)
    elseif "rand" == rtype then
        register(buyin, laps, timeout, data.allowAI, rtype, vclass, svehicle, data.recur, data.order)
    end
    cb()
end)

RegisterNUICallback("unregister", function(_, cb)
    unregister()
    cb()
end)

RegisterNUICallback("start", function(data, cb)
    local delay = data.delay
    if "" == delay then
        delay = nil
    end
    startRace(delay)
    cb()
end)

RegisterNUICallback("leave", function(_, cb)
    leave()
    cb()
end)

RegisterNUICallback("rivals", function(_, cb)
    rivals()
    cb()
end)

RegisterNUICallback("respawn", function(_, cb)
    respawn()
    cb()
end)

RegisterNUICallback("results", function(_, cb)
    viewResults(false)
    cb()
end)

RegisterNUICallback("spawn", function(data, cb)
    local vehicle = data.vehicle
    if "" == vehicle then
        vehicle = nil
    end
    spawn(vehicle)
    cb()
end)

RegisterNUICallback("lvehicles", function(data, cb)
    local vclass = data.vclass
    if "-1" == vclass then
        vclass = nil
    end
    lvehicles(vclass)
    cb()
end)

RegisterNUICallback("speedo", function(data, cb)
    local unit = data.unit
    if "" == unit then
        unit = nil
    end
    setSpeedo(unit)
    cb()
end)

RegisterNUICallback("funds", function(_, cb)
    viewFunds()
    cb()
end)

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    panelShown = false
    cb()
end)

--[[
RegisterNetEvent("sounds")
AddEventHandler("sounds", function(sounds)
    print("start")
    for _, sound in pairs(sounds) do
        print(":" .. sound.set .. ":" .. sound.name .. ":")
        if
            fail == string.find(sound.name, string.upper("Loop")) and
            fail == string.find(sound.name, string.upper("Background")) and
            sound.name ~= string.upper("Pin_Movement") and
            sound.name ~= string.upper("WIND") and
            sound.name ~= string.upper("Trail_Custom") and
            sound.name ~= string.upper("Altitude_Warning") and
            sound.name ~= string.upper("OPENING") and
            sound.name ~= string.upper("CONTINUOUS_SLIDER") and
            sound.name ~= string.upper("SwitchWhiteWarning") and
            sound.name ~= string.upper("SwitchRedWarning") and
            sound.name ~= string.upper("ZOOM") and
            sound.name ~= string.upper("Microphone") and
            sound.set ~= string.upper("MP_CCTV_SOUNDSET") and
            sound.set ~= string.upper("SHORT_PLAYER_SWITCH_SOUND_SET")
        then
            PlaySoundFrontend(-1, sound.name, sound.set, true)
        else
            print("^^^^^^^^^^^^^")
        end
        Citizen.Wait(1000)
    end
    print("done")
end)

RegisterNetEvent("vehicleHashes")
AddEventHandler("vehicleHashes", function(vehicles)
    print("#vehicles = " .. #vehicles)
    print("#allVehiclesList = " .. #allVehiclesList)
    local count = 0
    local unk = 0
    for _, model in ipairs(vehicles) do
        if 1 == IsModelInCdimage(model) and 1 == IsModelAVehicle(model) then
            count = count + 1
            local found = false
            for _, vehModel in ipairs(allVehiclesList) do
                if model == vehModel then
                    found = true
                    break
                end
            end
            if false == found then
                print(model .. " not found in allVehiclesList")
            end
        else
            print("unknown '" .. model .. "'")
            unk = unk + 1
        end
    end
    print("count = " .. count)
    print("unk = " .. unk)
end)

local pedpassengers = {}

local vehicle0
local vehicle1
local humanPed
--]]

RegisterCommand("races", function(_, args)
    if nil == args[1] then
        notifyPlayer(
            "\n" ..
            "Commands:\n" ..
            "Required arguments are in square brackets.  Optional arguments are in parentheses.\n" ..
            "/races - display list of available /races commands\n" ..
            "/races edit - toggle editing track waypoints\n" ..
            "/races clear - clear track waypoints\n" ..
            "/races reverse - reverse order of track waypoints\n" ..
            "\n" ..
            "For the following '/races' commands, [access] = {pvt, pub} where 'pvt' operates on a private track and 'pub' operates on a public track\n" ..
            "/races load [access] [name] - load private or public track saved as [name]\n" ..
            "/races save [access] [name] - save new private or public track as [name]\n" ..
            "/races overwrite [access] [name] - overwrite existing private or public track saved as [name]\n" ..
            "/races delete [access] [name] - delete private or public track saved as [name]\n" ..
            "/races list [access] - list saved private or public tracks\n" ..
            "/races blt [access] [name] - list 10 best lap times of private or public track saved as [name]\n" ..
            "\n" ..
            "/races ai spawn [name] (vehicle) - spawn AI driver named [name] in (vehicle); (vehicle) defaults to 'adder' if not specified\n" ..
            "/races ai delete [name] - delete an AI driver named [name]\n" ..
            "/races ai deleteAll - delete all AI drivers\n" ..
            "/races ai list - list AI driver names\n" ..
            "\n" ..
            "For the following '/races ai' commands, [access] = {pvt, pub} where 'pvt' operates on a private AI group and 'pub' operates on a public AI group\n" ..
            "/races ai loadGrp [access] [name] - load private or public AI group saved as [name]\n" ..
            "/races ai saveGrp [access] [name] - save new private or public AI group as [name]\n" ..
            "/races ai overwriteGrp [access] [name] - overwrite existing private or public AI group saved as [name]\n" ..
            "/races ai deleteGrp [access] [name] - delete private or public AI group saved as [name]\n" ..
            "/races ai listGrps [access] - list saved private or public AI groups\n" ..
            "\n" ..
            "/races vl add [vehicle] - add [vehicle] to vehicle list\n" ..
            "/races vl delete [vehicle] - delete [vehicle] from vehicle list\n" ..
            "/races vl addClass [class] - add all vehicles of type [class] to vehicle list\n" ..
            "/races vl deleteClass [class] - delete all vehicles of type [class] from vehicle list\n" ..
            "/races vl addAll - add all vehicles to vehicle list\n" ..
            "/races vl deleteAll - delete all vehicles from vehicle list\n" ..
            "/races vl list - list all vehicles in vehicle list\n" ..
            "\n" ..
            "For the following '/races vl' commands, [access] = {pvt, pub} where 'pvt' operates on a private vehicle list and 'pub' operates on a public vehicle list\n" ..
            "/races vl loadLst [access] [name] - load private or public vehicle list saved as [name]\n" ..
            "/races vl saveLst [access] [name] - save new private or public vehicle list as [name]\n" ..
            "/races vl overwriteLst [access] [name] - overwrite existing private or public vehicle list saved as [name]\n" ..
            "/races vl deleteLst [access] [name] - delete private or public vehicle list saved as [name]\n" ..
            "/races vl listLsts [access] - list saved private or public vehicle lists\n" ..
            "\n" ..
            "For the following '/races register' commands, (buy-in) defaults to 500, (laps) defaults to 1 lap, (DNF timeout) defaults to 120 seconds and (allow AI) = {yes, no} defaults to 'no'\n" ..
            "/races register (buy-in) (laps) (DNF timeout) (allow AI) - register your race with no vehicle restrictions\n" ..
            "/races register (buy-in) (laps) (DNF timeout) (allow AI) rest [vehicle] - register your race restricted to [vehicle]\n" ..
            "/races register (buy-in) (laps) (DNF timeout) (allow AI) class [class] - register your race restricted to vehicles of type [class]; if [class] is '-1' then use custom vehicle list\n" ..
            "/races register (buy-in) (laps) (DNF timeout) (allow AI) rand (class) (start) (recur) (order) - register your race changing vehicles randomly every lap; (class) defaults to any; (start) defaults to any; (recur) = {yes, no} defaults to 'yes'; (order) = {yes, no} defaults to 'no'\n" ..
            "\n" ..
            "/races unregister - unregister your race\n" ..
            "/races start (delay) - start your registered race; (delay) defaults to 30 seconds if not specified\n" ..
            "\n" ..
            "/races leave - leave a race that you joined\n" ..
            "/races rivals - list players in a race that you joined\n" ..
            "/races respawn - respawn at last waypoint\n" ..
            "/races results - view latest race results\n" ..
            "/races spawn (vehicle) - spawn a vehicle; (vehicle) defaults to 'adder' if not specified\n" ..
            "/races lvehicles (class) - list available vehicles of type (class); (class) defaults to all classes if not specified\n" ..
            "/races speedo (unit) - change unit of speed measurement to (unit) = {imperial, metric}; otherwise toggle display of speedometer if (unit) is not specified\n" ..
            "/races funds - view available funds\n" ..
            "/races panel (panel) - display (panel) = {track, ai, list, register} panel; (panel) defaults to main panel if not specified\n"
        )
    elseif "edit" == args[1] then
        edit()
    elseif "clear" == args[1] then
        clear()
    elseif "reverse" == args[1] then
        reverse()
    elseif "load" == args[1] then
        loadTrack(args[2], args[3])
    elseif "save" == args[1] then
        saveTrack(args[2], args[3])
    elseif "overwrite" == args[1] then
        overwriteTrack(args[2], args[3])
    elseif "delete" == args[1] then
        deleteTrack(args[2], args[3])
    elseif "list" == args[1] then
        listTracks(args[2])
    elseif "blt" == args[1] then
        bestLapTimes(args[2], args[3])
    elseif "ai" == args[1] then
        if "spawn" == args[2] then
            spawnAIDriver(args[3], args[4], GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
        elseif "delete" == args[2] then
            deleteAIDriver(args[3])
        elseif "deleteAll" == args[2] then
            deleteAllAIDrivers()
        elseif "list" == args[2] then
            listAIDrivers()
        elseif "loadGrp" == args[2] then
            loadGrp(args[3], args[4])
        elseif "saveGrp" == args[2] then
            saveGrp(args[3], args[4])
        elseif "overwriteGrp" == args[2] then
            overwriteGrp(args[3], args[4])
        elseif "deleteGrp" == args[2] then
            deleteGrp(args[3], args[4])
        elseif "listGrps" == args[2] then
            listGrps(args[3])
        else
            notifyPlayer("Unknown AI command.\n")
        end
    elseif "vl" == args[1] then
        if "add" == args[2] then
            addVeh(args[3])
        elseif "delete" == args[2] then
            deleteVeh(args[3])
        elseif "addClass" == args[2] then
            addClass(args[3])
        elseif "deleteClass" == args[2] then
            deleteClass(args[3])
        elseif "addAll" == args[2] then
            addAllVeh()
        elseif "deleteAll" == args[2] then
            deleteAllVeh()
        elseif "list" == args[2] then
            listVeh()
        elseif "loadLst" == args[2] then
            loadLst(args[3], args[4])
        elseif "saveLst" == args[2] then
            saveLst(args[3], args[4])
        elseif "overwriteLst" == args[2] then
            overwriteLst(args[3], args[4])
        elseif "deleteLst" == args[2] then
            deleteLst(args[3], args[4])
        elseif "listLsts" == args[2] then
            listLsts(args[3])
        else
            notifyPlayer("Unknown vehicle list command.\n")
        end
    elseif "register" == args[1] then
        register(args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10])
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
        showPanel(args[2])
--[[
    elseif "test" == args[1] then
        if nil == args[2] then
            print("fin")
            print("mchkpt")
            print("psndf")
            print("tsevsnd0")
            print("tsevsnd1")
            print("svengh")
            print("gvengh")
            print("givwep")
            print("remallwep")
            print("clrwantlvl")
            print("ped2net")
            print("vstat")
            print("gpsrvid")
            print("classes")
            print("delpass")
            print("ppassinv")
            print("gpassinv")
            print("cpedinv")
            print("gv0")
            print("gpiv0")
            print("gv1")
            print("ppiv1")
            print("sct")
            print("swt")
            print("frz")
            print("ufrz")
            print("vh")
            print("ghost")
            print("unghost")
        elseif "fin" == args[2] then
            TriggerEvent("races:finish", GetPlayerServerId(PlayerId()), "John Doe", (5 * 60 + 24) * 1000, (1 * 60 + 32) * 1000, "Duck")
        elseif "mchkpt" == args[2] then
            local playerCoord = GetEntityCoords(PlayerPedId())
            local coord = {x = playerCoord.x, y = playerCoord.y, z = playerCoord.z, r = 5.0}
            local checkpoint = makeCheckpoint(tonumber(args[3]), coord, coord, yellow, 127, 5)
        elseif "psndf" == args[2] then
            PlaySoundFrontend(-1, args[3], args[4], true)
        elseif "tsevsnd0" == args[2] then
            TriggerServerEvent("sounds0")
        elseif "tsevsnd1" == args[2] then
            TriggerServerEvent("sounds1")
        elseif "svengh" == args[2] then
            local player = PlayerPedId()
            if 1 == IsPedInAnyVehicle(player, false) then
                SetVehicleEngineHealth(GetVehiclePedIsIn(player, false), tonumber(args[3]))
            end
        elseif "gvengh" == args[2] then
            local player = PlayerPedId()
            if 1 == IsPedInAnyVehicle(player, false) then
                print(GetVehicleEngineHealth(GetVehiclePedIsIn(player, false)))
            end
        elseif "givwep" == args[2] then
            local player = PlayerPedId()
            local weaponHash =
                "WEAPON_COMBATMG"
                --"WEAPON_PISTOL"
                --"WEAPON_REVOLVER"
            GiveWeaponToPed(player, weaponHash, 0, false, false)
            SetPedInfiniteAmmo(player, true, weaponHash)
        elseif "remallwep" == args[2] then
            RemoveAllPedWeapons(PlayerPedId(), false)
        elseif "clrwantlvl" == args[2] then
            ClearPlayerWantedLevel(PlayerId())
        elseif "ped2net" == args[2] then
            print(PedToNet(PlayerPedId()))
        elseif "vstat" == args[2] then
            local vehicle = GetPlayersLastVehicle()
            print("on wheels: " .. tostring(IsVehicleOnAllWheels(vehicle)))
            print("driveable: " .. tostring(IsVehicleDriveable(vehicle, false)))
            print("upside down: " .. tostring(IsEntityUpsidedown(vehicle)))
            print("is a car: " .. tostring(IsThisModelACar(GetEntityModel(vehicle))))
            print("can be damaged: " .. tostring(GetEntityCanBeDamaged(vehicle)))
            print("vehicle health %: " .. GetVehicleHealthPercentage(vehicle))
            print("entity health: " .. GetEntityHealth(vehicle))
            print("vehicle name: " .. GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))))
        elseif "gpsrvid" == args[2] then
            print(GetPlayerServerId(PlayerId()))
        elseif "classes" == args[2] then
            local classes = {}
            local maxName = nil
            local maxLen = 0
            local minName = nil
            local minLen = 0
            for _, vehicle in ipairs(allVehiclesList) do
                local vclass = GetVehicleClassFromName(vehicle)
                if nil == classes[vclass] then
                    classes[vclass] = {}
                end
                classes[vclass][#classes[vclass] + 1] = vehicle

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
            print("maxLen = " .. maxLen .. ":" .. maxName)
            print("minLen = " .. minLen .. ":" .. minName)
            local classNum = {}
            for vclass in pairs(classes) do
                classNum[#classNum + 1] = vclass
            end
            table.sort(classNum)
            for _, vclass in ipairs(classNum) do
                print("CLASS = " .. vclass .. ":name = " .. GetLabelText("VEH_CLASS_" .. vclass) .. ":num vehicles = " .. #classes[vclass])
                for _, vehicle in pairs(classes[vclass]) do
                    print(vehicle .. ":num seats = " .. GetVehicleModelNumberOfSeats(vehicle))
                end
            end
        elseif "delpass" == args[2] then
            for _, passenger in pairs(pedpassengers) do
                DeletePed(passenger.ped)
            end
            pedpassengers = {}
        elseif "ppassinv" == args[2] then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
            for _, passenger in pairs(pedpassengers) do
                SetPedIntoVehicle(passenger.ped, vehicle, passenger.seat)
                --TaskWarpPedIntoVehicle(passenger.ped, vehicle, passenger.seat)
                print("seat:" .. passenger.seat)
            end
        elseif "gpassinv" == args[2] then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
            for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
                local ped = GetPedInVehicleSeat(vehicle, seat)
                if DoesEntityExist(ped) then
                    pedpassengers[#pedpassengers + 1] = {ped = ped, seat = seat}
                    print("seat:" .. seat)
                end
            end
            print("num passengers:" .. #pedpassengers)
        elseif "cpedinv" == args[2] then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
            local pedModel = "a_m_y_skater_01"
            loadModel(pedModel)
            for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
                if 1 == IsVehicleSeatFree(vehicle, seat) then
                    CreatePedInsideVehicle(vehicle, PED_TYPE_CIVMALE, pedModel, seat, true, false)
                    print("seat:" .. seat)
                    break
                end
            end
            SetModelAsNoLongerNeeded(pedModel)
        elseif "gv0" == args[2] then
            vehicle0 = GetVehiclePedIsIn(PlayerPedId(), true)
            print("get vehicle 0")
            print(GetEntityModel(vehicle0) .. " =? " .. GetHashKey("adder"))
        elseif "gpiv0" == args[2] then
            humanPed = GetPedInVehicleSeat(vehicle0, -1)
            print("get ped in vehicle 0")
        elseif "gv1" == args[2] then
            vehicle1 = GetVehiclePedIsIn(PlayerPedId(), true)
            print("get vehicle 1")
        elseif "ppiv1" == args[2] then
            SetPedIntoVehicle(humanPed, vehicle1, -1)
            --TaskWarpPedIntoVehicle(humanPed, vehicle1, -1)
            print("put ped in vehicle 1")
        elseif "sct" == args[2] then
            local hr = math.tointeger(args[3])
            local min = math.tointeger(args[4])
            local sec = math.tointeger(args[5])
            if fail == hr or hr < 0 or hr > 23 or fail == min or min < 0 or min > 59 or fail == sec or sec < 0 or sec > 59 then
                print("Invalid time.")
            else
                NetworkOverrideClockTime(hr, min, sec)
            end
        elseif "swt" == args[2] then
            local weatherType = {}
            weatherType[#weatherType + 1] = "BLIZZARD"
            weatherType[#weatherType + 1] = "CLEAR"
            weatherType[#weatherType + 1] = "CLEARING"
            weatherType[#weatherType + 1] = "CLOUDS"
            weatherType[#weatherType + 1] = "EXTRASUNNY"
            weatherType[#weatherType + 1] = "FOGGY"
            weatherType[#weatherType + 1] = "HALLOWEEN"
            weatherType[#weatherType + 1] = "NEUTRAL"
            weatherType[#weatherType + 1] = "OVERCAST"
            weatherType[#weatherType + 1] = "RAIN"
            weatherType[#weatherType + 1] = "SMOG"
            weatherType[#weatherType + 1] = "SNOW"
            weatherType[#weatherType + 1] = "SNOWLIGHT"
            weatherType[#weatherType + 1] = "THUNDER"
            weatherType[#weatherType + 1] = "XMAS"
            local t = math.tointeger(args[3])
            if fail == t or t < 1 or t > #weatherType then
                print("Invalid weather type.")
                for i = 1, #weatherType do
                    print(i .. " " .. weatherType[i])
                end
            else
                SetWeatherOwnedByNetwork(false)
                SetWeatherTypeNow(weatherType[t])
                print("Weather type = " .. t .. " " .. weatherType[t])
            end
        elseif "frz" == args[2] and args[3] ~= nil and aiState ~= nil and aiState.drivers[ args[3] ] ~= nil then
            FreezeEntityPosition(aiState.drivers[ args[3] ].vehicle, true)
        elseif "ufrz" == args[2] and args[3] ~= nil and aiState ~= nil and aiState.drivers[ args[3] ] ~= nil then
            FreezeEntityPosition(aiState.drivers[ args[3] ].vehicle, false)
        elseif "vh" == args[2] then
            TriggerServerEvent("vehicleHashes")
        elseif "ghost" == args[2] then
            notifyPlayer("ghosting")
            SetLocalPlayerAsGhost(true)
            NetworkSetEntityGhostedWithOwner(GetVehiclePedIsIn(PlayerPedId(), false), true)
        elseif "unghost" == args[2] then
            notifyPlayer("unghosting")
            SetLocalPlayerAsGhost(false)
            NetworkSetEntityGhostedWithOwner(GetVehiclePedIsIn(PlayerPedId(), false), false)
        else
            print("unknown test command")
        end
--]]
    else
        notifyPlayer("Unknown command.\n")
    end
end)

RegisterNetEvent("races:message")
AddEventHandler("races:message", function(msg)
    if true == panelShown then
        SendNUIMessage({
            action = "reply",
            message = string.gsub(msg, "\n", "<br>")
        })
    end
    TriggerEvent("chat:addMessage", {
        color = {255, 0, 0},
        multiline = true,
        args = {"[races:server]", msg}
    })
end)

RegisterNetEvent("races:load")
AddEventHandler("races:load", function(access, trackName, waypointCoords)
    if nil == access or nil == trackName or nil == waypointCoords then
        notifyPlayer("Ignoring load event.  Invalid parameters.\n")
        return
    end

    if STATE_IDLE == state then
        trackAccess = access
        savedTrackName = trackName
        loadWaypointBlips(waypointCoords)
        sendMessage("Loaded " .. ("pub" == access and "public" or "private") .. " track '" .. trackName .. "'.\n")
    elseif STATE_EDITING == state then
        trackAccess = access
        savedTrackName = trackName
        highlightedIndex = 0
        selectedIndex0 = 0
        selectedIndex1 = 0
        deleteWaypointCheckpoints()
        loadWaypointBlips(waypointCoords)
        setStartToFinishCheckpoints()
        sendMessage("Loaded " .. ("pub" == access and "public" or "private") .. " track '" .. trackName .. "'.\n")
    else
        notifyPlayer("Ignoring load event.  Currently joined to race.\n")
    end
end)

RegisterNetEvent("races:save")
AddEventHandler("races:save", function(access, trackName)
    if nil == access or nil == trackName then
        notifyPlayer("Ignoring save event.  Invalid parameters.\n")
        return
    end

    trackAccess = access
    savedTrackName = trackName
    sendMessage("Saved " .. ("pub" == access and "public" or "private") .. " track '" .. trackName .. "'.\n")
end)

RegisterNetEvent("races:overwrite")
AddEventHandler("races:overwrite", function(access, trackName)
    if nil == access or nil == trackName then
        notifyPlayer("Ignoring overwrite event.  Invalid parameters.\n")
        return
    end

    trackAccess = access
    savedTrackName = trackName
    sendMessage("Overwrote " .. ("pub" == access and "public" or "private") .. " track '" .. trackName .. "'.\n")
end)

RegisterNetEvent("races:blt")
AddEventHandler("races:blt", function(access, trackName, bestLaps)
    if nil == access or nil == trackName or nil == bestLaps then
        notifyPlayer("Ignoring blt event.  Invalid parameters.\n")
        return
    end

    local msg = ("pub" == access and "public" or "private") .. " track '" .. trackName .. "'"
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
end)

RegisterNetEvent("races:loadGrp")
AddEventHandler("races:loadGrp", function(access, name, group)
    if nil == access or nil == name or nil == group then
        notifyPlayer("Ignoring loadGrp event.  Invalid parameters.\n")
        return
    end

    local loaded = true
    if true == deleteAllAIDrivers() then
        -- group[aiName] = {startCoord = {x, y, z}, heading, model}
        for aiName, driver in pairs(group) do
            if false == spawnAIDriver(aiName, driver.model, vector3(driver.startCoord.x, driver.startCoord.y, driver.startCoord.z), driver.heading) then
                loaded = false
            end
        end
    else
        loaded = false
    end

    if true == loaded then
        sendMessage(("pub" == access and "Public" or "Private") .. " AI group '" .. name .. "' loaded.\n")
    else
        sendMessage("Could not load all AI in " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'.\n")
    end
end)

RegisterNetEvent("races:loadLst")
AddEventHandler("races:loadLst", function(access, name, list)
    if nil == access or nil == name or nil == list then
        notifyPlayer("Ignoring loadLst event.  Invalid parameters.\n")
        return
    end

    vehicleList = list

    updateVehicleList()

    sendMessage(("pub" == access and "Public" or "Private") .. " vehicle list '" .. name .. "' loaded.\n")
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(rIndex, coord, rdata)
    if nil == rIndex or nil == coord or nil == rdata then
        notifyPlayer("Ignoring register event.  Invalid parameters.\n")
        return
    end

    local blip = AddBlipForCoord(coord.x, coord.y, coord.z) -- registration blip
    SetBlipSprite(blip, registerSprite)
    SetBlipColour(blip, registerBlipColor)
    local msg = ("%s:%d buy-in:%d lap(s):%d timeout"):format(rdata.owner, rdata.buyin, rdata.laps, rdata.timeout)
    if "yes" == rdata.allowAI then
        msg = msg .. ":AI allowed"
    end
    if "rest" == rdata.rtype then
        msg = msg .. ":using '" .. rdata.restrict .. "' vehicle"
    elseif "class" == rdata.rtype then
        msg = msg .. ":using " .. rdata.className .. " class vehicles"
    elseif "rand" == rdata.rtype then
        msg = msg .. ":using random "
        if rdata.vclass ~= nil then
            msg = msg .. rdata.className .. " class "
        end
        msg = msg .. "vehicles"
        if rdata.svehicle ~= nil then
            msg = msg .. ":start '" .. rdata.svehicle .. "'"
        end
        if "yes" == rdata.recur then
            msg = msg .. ":recurring"
        else
            msg = msg .. ":nonrecurring"
        end
        if "yes" == rdata.order then
            msg = msg .. ":ordered"
        else
            msg = msg .. ":unordered"
        end
    end
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(string.sub(msg, 1, 79)) -- blip name has limit of 79 characters
    EndTextCommandSetBlipName(blip)

    coord.r = defaultRadius
    local checkpoint = makeCheckpoint(plainCheckpoint, coord, coord, purple, 127, 0) -- registration checkpoint

    races[rIndex] = {
        owner = rdata.owner,
        access = rdata.access,
        trackName = rdata.trackName,
        buyin = rdata.buyin,
        laps = rdata.laps,
        timeout = rdata.timeout,
        allowAI = rdata.allowAI,
        rtype = rdata.rtype,
        restrict = rdata.restrict,
        vclass = rdata.vclass,
        className = rdata.className,
        svehicle = rdata.svehicle,
        recur = rdata.recur,
        order = rdata.order,
        vehicleList = rdata.vehicleList,
        blip = blip,
        checkpoint = checkpoint
    }
end)

RegisterNetEvent("races:unregister")
AddEventHandler("races:unregister", function(rIndex)
    if nil == rIndex then
        notifyPlayer("Ignoring unregister event.  Invalid parameters.\n")
        return
    end

    if races[rIndex] ~= nil then
        RemoveBlip(races[rIndex].blip) -- delete registration blip
        DeleteCheckpoint(races[rIndex].checkpoint) -- delete registration checkpoint
        races[rIndex] = nil
    end

    -- SCENARIO: rIndex = A, raceIndex = -1
    -- 1. register race 'A'
    -- 2. owner does not join any race -> raceIndex = -1
    -- 3. owner unregisters race 'A' -> owner receives unregister event from race 'A' -> rIndex = A
    -- do not unregister owner from race 'A' since owner did not join race 'A'
    -- SCENARIO: rIndex = A, raceIndex = B
    -- 1. register race 'A'
    -- 2. owner joins another race 'B' -> raceIndex = B
    -- 3. owner unregisters race 'A' -> owner receives unregister event from race 'A' -> rIndex = A
    -- do not unregister owner from race 'B'
    if rIndex == raceIndex then
        if STATE_JOINING == state then
            state = STATE_IDLE
            raceIndex = -1
            notifyPlayer("Race canceled.\n")
        elseif STATE_RACING == state then
            state = STATE_IDLE

            DeleteCheckpoint(raceCheckpoint)

            for i = 1, #waypoints do
                SetBlipDisplay(waypoints[i].blip, 2)
            end

            local curr = true == startIsFinish and currentWaypoint % #waypoints + 1 or currentWaypoint
            SetBlipColour(waypoints[curr].blip, waypoints[curr].color)

            SetBlipRoute(waypoints[1].blip, true)
            SetBlipRouteColour(waypoints[1].blip, blipRouteColor)

            RenderScriptCams(false, false, 0, true, true)

            local player = PlayerPedId()
            if 1 == IsPedInAnyVehicle(player, false) then
                FreezeEntityPosition(GetVehiclePedIsIn(player, false), false)
            end

            if "rand" == raceType and originalVehicleHash ~= nil then
                local vehicle = switchVehicle(player, originalVehicleHash, originalColorPri, originalColorSec, originalColorPearl, originalColorWheel)
                if vehicle ~= nil then
                    SetEntityAsNoLongerNeeded(vehicle)
                end
            end

            raceIndex = -1

            speedo = preRaceSpeedo

            notifyPlayer("Race canceled.\n")
        end
    end

    if aiState ~= nil then
        -- SCENARIO: rIndex = B, GetPlayerServerId(PlayerId()) = A
        -- 1. register race 'A' with AI -> GetPlayerServerId(PlayerId()) = A
        -- 2. owner joins another race 'B'
        -- 3. owner receives unregister event from race 'B' -> rIndex = B
        -- do not unregister AI from race 'A'
        if GetPlayerServerId(PlayerId()) == rIndex then
            for _, driver in pairs(aiState.drivers) do
                if false == IsEntityDead(driver.ped) and "rand" == aiState.raceType then
                    driver.vehicle = switchVehicle(driver.ped, driver.model, driver.colorPri, driver.colorSec, driver.colorPearl, driver.colorWheel)
                end
                SetEntityAsNoLongerNeeded(driver.vehicle)

                Citizen.CreateThread(function()
                    while true do
                        if 0 == GetVehicleNumberOfPassengers(driver.vehicle) then
                            Citizen.Wait(1000)
                            SetEntityAsNoLongerNeeded(driver.ped)
                            break
                        end
                        Citizen.Wait(1000)
                    end
                end)
            end

            aiState = nil
        end
    end
end)

RegisterNetEvent("races:start")
AddEventHandler("races:start", function(rIndex, delay)
    if nil == rIndex or nil == delay then
        notifyPlayer("Ignoring start event.  Invalid parameters.\n")
        return
    end

    if delay < minDelay then
        notifyPlayer("Ignoring start event.  Invalid delay.\n")
        return
    end

    local currentTime = GetNetworkTimeAccurate()

    -- SCENARIO: rIndex = A, raceIndex = -1
    -- 1. register race 'A' with AI
    -- 2. owner does not join any race -> raceIndex = -1
    -- 3. owner starts race 'A' -> owner receives start event for AI from race 'A' -> rIndex = A
    -- do not start race 'A' for owner since owner did not join race 'A'
    -- SCENARIO: rIndex = A, raceIndex = B
    -- 1. register race 'A' with AI
    -- 2. owner joins another race 'B' -> raceIndex = B
    -- 3. owner starts race 'A' -> owner receives start event for AI from race 'A' -> rIndex = A
    -- do not start race 'B' for owner since race 'B' was not started
    if rIndex == raceIndex then
        if STATE_RACING == state then
            notifyPlayer("Ignoring start event.  Already in a race.\n")
            return
        elseif STATE_EDITING == state then
            notifyPlayer("Ignoring start event.  Currently editing.\n")
            return
        elseif STATE_IDLE == state then
            notifyPlayer("Ignoring start event.  Currently idle.\n")
            return
        end

        state = STATE_RACING
        raceStart = currentTime
        raceDelay = delay
        startCoord = GetEntityCoords(PlayerPedId())
        heading = GetEntityHeading(PlayerPedId())
        vehicleFrozen = false
        camTransStarted = false
        countdown = 5
        started = false
        position = -1
        numWaypointsPassed = 0
        currentLap = 1
        bestLapTime = -1
        beginDNFTimeout = false
        preRaceSpeedo = speedo
        speedo = false
        results = {}

        numVisible = maxNumVisible < #waypoints and maxNumVisible or (#waypoints - 1)
        for i = numVisible + 1, #waypoints do
            SetBlipDisplay(waypoints[i].blip, 0)
        end

        SetBlipColour(waypoints[1].blip, currentWPBlipColor)

        raceCheckpoint = makeCheckpoint(arrow3Checkpoint, destCoord, waypoints[2].coord, yellow, 127, 0)

        SetBlipRoute(destCoord, true)
        SetBlipRouteColour(destCoord, blipRouteColor)

        if startVehicle ~= nil then
            respawnVehicleHash = startVehicle
            local vehicle = switchVehicle(PlayerPedId(), startVehicle, -1, -1, -1, -1)
            if vehicle ~= nil then
                SetEntityAsNoLongerNeeded(vehicle)
                respawnColorPri, respawnColorSec = GetVehicleColours(vehicle)
                respawnColorPearl, respawnColorWheel = GetVehicleExtraColours(vehicle)
                startVehicleSpawned = true
            else
                respawnColorPri = -1
                respawnColorSec = -1
                respawnColorPearl = -1
                respawnColorWheel = -1
            end
        end

        notifyPlayer("Race started.\n")
    end

    if aiState ~= nil then
        -- SCENARIO: rIndex = B, GetPlayerServerId(PlayerId()) = A
        -- 1. register race 'A' with AI -> GetPlayerServerId(PlayerId()) = A
        -- 2. owner joins another race 'B'
        -- 3. owner receives start event from race 'B' -> rIndex = B
        -- do not start race for AI's in race 'A'
        if GetPlayerServerId(PlayerId()) == rIndex then
            aiState.raceStart = currentTime
            aiState.raceDelay = delay
            for _, driver in pairs(aiState.drivers) do
                driver.state = STATE_RACING
                if aiState.startVehicle ~= nil then
                    driver.vehicle = switchVehicle(driver.ped, aiState.startVehicle, -1, -1, -1, -1)
                end
            end
        end
    end
end)

RegisterNetEvent("races:hide")
AddEventHandler("races:hide", function(rIndex)
    if nil == rIndex then
        notifyPlayer("Ignoring hide event.  Invalid parameters.\n")
        return
    end

    if nil == races[rIndex] then
        notifyPlayer("Ignoring hide event.  Race does not exist.\n")
        return
    end

    RemoveBlip(races[rIndex].blip) -- delete registration blip
    DeleteCheckpoint(races[rIndex].checkpoint) -- delete registration checkpoint
    races[rIndex] = nil
end)

RegisterNetEvent("races:join")
AddEventHandler("races:join", function(rIndex, aiName, waypointCoords)
    if nil == rIndex or nil == waypointCoords then
        notifyPlayer("Ignoring join event.  Invalid parameters.\n")
        return
    end

    local race = races[rIndex]
    if nil == race then
        notifyPlayer("Ignoring join event.  Race does not exist.\n")
        return
    end

    if nil == aiName then
        if STATE_EDITING == state then
            notifyPlayer("Ignoring join event.  Currently editing.\n")
            return
        elseif state ~= STATE_IDLE then
            notifyPlayer("Ignoring join event.  Already joined to a race.\n")
            return
        end

        state = STATE_JOINING
        raceIndex = rIndex
        raceType = race.rtype
        numLaps = race.laps
        DNFTimeout = race.timeout * 1000
        startVehicle = race.svehicle
        startVehicleSpawned = false
        recurring = "yes" == race.recur
        ordered = "yes" == race.order

        loadWaypointBlips(waypointCoords)

        destCoord = waypointCoords[1]
        currentWaypoint = true == startIsFinish and 0 or 1

        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
            respawnVehicleHash = GetEntityModel(vehicle)
            respawnColorPri, respawnColorSec = GetVehicleColours(vehicle)
            respawnColorPearl, respawnColorWheel = GetVehicleExtraColours(vehicle)
        else
            respawnVehicleHash = nil
        end
        originalVehicleHash = respawnVehicleHash

        local msg = "Joined race registered by '" .. race.owner .. "' using "
        if nil == race.trackName then
            msg = msg .. "unsaved track"
        else
            msg = msg .. ("pub" == race.access and "publicly" or "privately") .. " saved track '" .. race.trackName .. "'"
        end
        msg = msg .. (" : %d buy-in : %d lap(s) : %d timeout"):format(race.buyin, race.laps, race.timeout)
        if "yes" == race.allowAI then
            msg = msg .. " : AI allowed"
        end
        if "rest" == race.rtype then
            msg = msg .. " : using '" .. race.restrict .. "' vehicle"
        elseif "class" == race.rtype then
            msg = msg .. " : using " .. race.className .. " class vehicles"
        elseif "rand" == race.rtype then
            msg = msg .. " : using random "
            if race.vclass ~= nil then
                msg = msg .. race.className .. " class "
            end
            msg = msg .. "vehicles"
            if startVehicle ~= nil then
                msg = msg .. " : start '" .. startVehicle .. "'"
            end
            if true == recurring then
                msg = msg .. " : recurring"
            else
                msg = msg .. " : nonrecurring"
            end
            if true == ordered then
                msg = msg .. " : ordered"
            else
                msg = msg .. " : unordered"
            end

            if originalVehicleHash ~= nil then
                originalColorPri = respawnColorPri
                originalColorSec = respawnColorSec
                originalColorPearl = respawnColorPearl
                originalColorWheel = respawnColorWheel
            end

            raceVehicleList = race.vehicleList
        end
        notifyPlayer(msg .. "\n")
        return
    end

    if nil == aiState then
        notifyPlayer("Ignoring join event.  No AI drivers added.\n")
        return
    end

    local driver = aiState.drivers[aiName]
    if nil == driver then
        notifyPlayer("Ignoring join event.  AI driver '" .. aiName .. "' not found.\n")
        return
    end

    if 0 == #aiState.waypointCoords then
        aiState.waypointCoords = waypointCoords
        aiState.startIsFinish =
            waypointCoords[1].x == waypointCoords[#waypointCoords].x and
            waypointCoords[1].y == waypointCoords[#waypointCoords].y and
            waypointCoords[1].z == waypointCoords[#waypointCoords].z
        if true == aiState.startIsFinish then
            aiState.waypointCoords[#aiState.waypointCoords] = nil
        end
    end

    driver.destCoord = aiState.waypointCoords[1]
    driver.destSet = true
    driver.currentWaypoint = true == aiState.startIsFinish and 0 or 1

    notifyPlayer("AI driver '" .. aiName .. "' joined race.\n")
end)

RegisterNetEvent("races:finish")
AddEventHandler("races:finish", function(rIndex, playerName, raceFinishTime, raceBestLapTime, raceVehicleName)
    if nil == rIndex or nil == playerName or nil == raceFinishTime or nil == raceBestLapTime or nil == raceVehicleName then
        notifyPlayer("Ignoring finish event.  Invalid parameters.\n")
        return
    end

    local currentTime = GetNetworkTimeAccurate()

    -- SCENARIO: rIndex = A, raceIndex = -1
    -- 1. register race 'A' with AI
    -- 2. owner does not join any race -> raceIndex = -1
    -- 3. owner receives AI finish events from race 'A' -> rIndex = A
    -- do not notify owner/begin DNF timeout for owner
    -- SCENARIO: rIndex = A, raceIndex = B
    -- 1. register race 'A' with AI
    -- 2. owner joins race 'B' -> raceIndex = B
    -- 3. owner receives AI finish events from race 'A' -> rIndex = A
    -- do not notify owner/begin DNF timeout for owner for race 'B'
    -- SCENARIO: rIndex = A, raceIndex = B
    -- 1. player finishes race 'A'
    -- 2. player joins another race 'B' -> raceIndex = B
    -- 3. player receives finish events from race 'A' -> rIndex = A
    -- do not notify player/begin DNF timeout for player for race 'B'
    if rIndex == raceIndex then
        if -1 == raceFinishTime then
            if -1 == raceBestLapTime then
                notifyPlayer(playerName .. " did not finish using " .. raceVehicleName .. ".\n")
            else
                local minutes, seconds = minutesSeconds(raceBestLapTime)
                notifyPlayer(("%s did not finish and had a best lap time of %02d:%05.2f using %s.\n"):format(playerName, minutes, seconds, raceVehicleName))
            end
        else
            if false == beginDNFTimeout then
                beginDNFTimeout = true
                DNFTimeoutStart = currentTime
            end

            local fMinutes, fSeconds = minutesSeconds(raceFinishTime)
            local lMinutes, lSeconds = minutesSeconds(raceBestLapTime)
            notifyPlayer(("%s finished in %02d:%05.2f and had a best lap time of %02d:%05.2f using %s.\n"):format(playerName, fMinutes, fSeconds, lMinutes, lSeconds, raceVehicleName))
        end
    end

    if raceFinishTime ~= -1 and aiState ~= nil and false == aiState.beginDNFTimeout then
        -- SCENARIO: rIndex = B, GetPlayerServerId(PlayerId()) = A
        -- 1. register race 'A' with AI -> GetPlayerServerId(PlayerId()) = A
        -- 2. owner joins another race 'B'
        -- 3. owner receives finish events from race 'B' -> rIndex = B
        -- do not begin AI DNF timeout for race 'A'
        if GetPlayerServerId(PlayerId()) == rIndex then
            aiState.beginDNFTimeout = true
            aiState.DNFTimeoutStart = currentTime
        end
    end
end)

RegisterNetEvent("races:results")
AddEventHandler("races:results", function(rIndex, raceResults)
    if nil == rIndex or nil == raceResults then
        notifyPlayer("Ignoring results event.  Invalid parameters.\n")
        return
    end

    -- SCENARIO: rIndex = A, raceIndex = B
    -- 1. player finishes race 'A'
    -- 2. player joins another race 'B' -> raceIndex = B
    -- 3. player receives results event from race 'A' -> rIndex = A
    -- do not view results from race 'A'
    if rIndex == raceIndex then
        raceIndex = -1
        results = raceResults
        viewResults(true)
    end
end)

RegisterNetEvent("races:position")
AddEventHandler("races:position", function(rIndex, pos, numR)
    if nil == rIndex or nil == pos or nil == numR then
        notifyPlayer("Ignoring position event.  Invalid parameters.\n")
        return
    end

    -- SCENARIO: rIndex = A, raceIndex = -1
    -- 1. player finishes race 'A'
    -- 2. player receives results event from race 'A' -> raceIndex = -1
    -- 3. player receives position events from race 'A' -> rIndex = A
    -- do not update position
    -- SCENARIO: rIndex = A, raceIndex = B
    -- 1. player finishes race 'A'
    -- 2. player joins another race 'B' -> raceIndex = B
    -- 3. player receives position events from race 'A' -> rIndex = A
    -- do not update position for race 'A'
    if rIndex == raceIndex then
        position = pos
        numRacers = numR
    end
end)

RegisterNetEvent("races:addRacer")
AddEventHandler("races:addRacer", function(netID, name)
    if nil == netID or nil == name then
        notifyPlayer("Ignoring addRacer event.  Invalid parameters.\n")
        return
    end

    if racerBlipGT[netID] ~= nil then
        RemoveBlip(racerBlipGT[netID].blip)
        RemoveMpGamerTag(racerBlipGT[netID].gamerTag)
    end

    if 1 == NetworkDoesNetworkIdExist(netID) then
        local ped = NetToPed(netID)

        local blip = AddBlipForEntity(ped)
        SetBlipSprite(blip, racerSprite)
        SetBlipColour(blip, racerBlipColor)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Racer")
        EndTextCommandSetBlipName(blip)

        local gamerTag = CreateFakeMpGamerTag(ped, name, false, false, nil, 0)
        SetMpGamerTagVisibility(gamerTag, 0, true)

        racerBlipGT[netID] = {blip = blip, gamerTag = gamerTag, name = name}
    end
end)

RegisterNetEvent("races:deleteRacer")
AddEventHandler("races:deleteRacer", function(netID)
    if nil == netID then
        notifyPlayer("Ignoring deleteRacer event.  Invalid parameters.\n")
        return
    end

    if racerBlipGT[netID] ~= nil then
        RemoveBlip(racerBlipGT[netID].blip)
        RemoveMpGamerTag(racerBlipGT[netID].gamerTag)
        racerBlipGT[netID] = nil
    end
end)

RegisterNetEvent("races:deleteAllRacers")
AddEventHandler("races:deleteAllRacers", function()
    removeAllRacerBlipGT()
end)

RegisterNetEvent("races:initAllVehicles")
AddEventHandler("races:initAllVehicles", function(allVehicles)
    if nil == allVehicles then
        notifyPlayer("Ignoring allVehicles event.  Invalid parameters.\n")
        return
    end

    allVehiclesList = {}
    table.sort(allVehicles)
    for _, model in ipairs(allVehicles) do
        if 1 == IsModelInCdimage(model) and 1 == IsModelAVehicle(model) then
            allVehiclesList[#allVehiclesList + 1] = model
        end
    end
end)

RegisterNetEvent("races:updateTrackNames")
AddEventHandler("races:updateTrackNames", function(access, trackNames)
    if nil == access or nil == trackNames then
        notifyPlayer("Ignoring trackNames event.  Invalid parameters.\n")
        return
    end

    table.sort(trackNames)
    local html = ""
    for _, trackName in ipairs(trackNames) do
        html = html .. "<option value = \"" .. trackName .. "\">" .. trackName .. "</option>"
    end
    SendNUIMessage({
        action = "update",
        list = "trackNames",
        access = access,
        trackNames = html
    })
end)

RegisterNetEvent("races:updateAiGrpNames")
AddEventHandler("races:updateAiGrpNames", function(access, grpNames)
    if nil == access or nil == grpNames then
        notifyPlayer("Ignoring aiGrpNames event.  Invalid parameters.\n")
        return
    end

    table.sort(grpNames)
    local html = ""
    for _, grpName in ipairs(grpNames) do
        html = html .. "<option value = \"" .. grpName .. "\">" .. grpName .. "</option>"
    end
    SendNUIMessage({
        action = "update",
        list = "grpNames",
        access = access,
        grpNames = html
    })
end)

RegisterNetEvent("races:updateListNames")
AddEventHandler("races:updateListNames", function(access, listNames)
    if nil == access or nil == listNames then
        notifyPlayer("Ignoring listNames event.  Invalid parameters.\n")
        return
    end

    table.sort(listNames)
    local html = ""
    for _, listName in ipairs(listNames) do
        html = html .. "<option value = \"" .. listName .. "\">" .. listName .. "</option>"
    end
    SendNUIMessage({
        action = "update",
        list = "listNames",
        access = access,
        listNames = html
    })
end)

RegisterNetEvent("races:cash")
AddEventHandler("races:cash", function(cash)
    if nil == cash then
        notifyPlayer("Ignoring cash event.  Invalid parameters.\n")
        return
    end

    StatSetInt(`MP0_WALLET_BALANCE`, cash, true)
    SetMultiplayerWalletCash()
    Citizen.Wait(5000)
    RemoveMultiplayerWalletCash()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        if STATE_RACING == state then
            local player = PlayerPedId()
            local distance = #(GetEntityCoords(player) - vector3(destCoord.x, destCoord.y, destCoord.z))
            TriggerServerEvent("races:report", raceIndex, PedToNet(player), numWaypointsPassed, distance)
        end

        if aiState ~= nil then
            for _, driver in pairs(aiState.drivers) do
                if STATE_RACING == driver.state then
                    local distance = #(GetEntityCoords(driver.ped) - vector3(driver.destCoord.x, driver.destCoord.y, driver.destCoord.z))
                    TriggerServerEvent("races:report", GetPlayerServerId(PlayerId()), driver.netID, driver.numWaypointsPassed, distance)
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if STATE_EDITING == state then
            local playerCoord = GetEntityCoords(PlayerPedId())
            local closestIndex = 0
            local minDist = maxRadius
            for index, waypoint in ipairs(waypoints) do
                local dist = #(playerCoord - vector3(waypoint.coord.x, waypoint.coord.y, waypoint.coord.z))
                if dist < waypoint.coord.r and dist < minDist then
                    minDist = dist
                    closestIndex = index
                end
            end

            if closestIndex ~= 0 then
                if highlightedIndex ~= 0 and closestIndex ~= highlightedIndex then
                    local color = (highlightedIndex == selectedIndex0 or highlightedIndex == selectedIndex1) and getCheckpointColor(selectedBlipColor) or getCheckpointColor(waypoints[highlightedIndex].color)
                    SetCheckpointRgba(waypoints[highlightedIndex].checkpoint, color.r, color.g, color.b, 127)
                end
                local color = (closestIndex == selectedIndex0 or closestIndex == selectedIndex1) and getCheckpointColor(selectedBlipColor) or getCheckpointColor(waypoints[closestIndex].color)
                SetCheckpointRgba(waypoints[closestIndex].checkpoint, color.r, color.g, color.b, 255)
                highlightedIndex = closestIndex
                drawMsg(0.50, 0.50, "Press [ENTER] key, [A] button or [CROSS] button to select waypoint", 0.7, 0)
            elseif highlightedIndex ~= 0 then
                local color = (highlightedIndex == selectedIndex0 or highlightedIndex == selectedIndex1) and getCheckpointColor(selectedBlipColor) or getCheckpointColor(waypoints[highlightedIndex].color)
                SetCheckpointRgba(waypoints[highlightedIndex].checkpoint, color.r, color.g, color.b, 127)
                highlightedIndex = 0
            end

            if 1 == IsWaypointActive() then -- add waypoint from waypoint map
                SetWaypointOff()
                local coord = GetBlipCoords(GetFirstBlipInfoId(8))
                for height = 1000.0, 0.0, -50.0 do
                    RequestAdditionalCollisionAtCoord(coord.x, coord.y, height)
                    Citizen.Wait(0)
                    local foundZ, groundZ = GetGroundZFor_3dCoord(coord.x, coord.y, height, true)
                    if 1 == foundZ then
                        coord = vector3(coord.x, coord.y, groundZ + 1.0) -- add 1.0 to groundZ so it's not right at ground level
                        editWaypoints(coord)
                        break
                    end
                end
            elseif 1 == IsControlJustReleased(0, 215) then -- enter key or A button or cross button - add waypoint
                editWaypoints(playerCoord)
            elseif selectedIndex0 ~= 0 and 0 == selectedIndex1 then -- one waypoint selected
                local selectedWaypoint0 = waypoints[selectedIndex0]
                if 1 == IsControlJustReleased(2, 216) then -- space key or X button or square button - delete waypoint
                    DeleteCheckpoint(selectedWaypoint0.checkpoint)
                    RemoveBlip(selectedWaypoint0.blip)
                    table.remove(waypoints, selectedIndex0)

                    if highlightedIndex == selectedIndex0 then
                        highlightedIndex = 0
                    end
                    selectedIndex0 = 0

                    trackAccess = nil
                    savedTrackName = nil

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
                elseif 1 == IsControlJustReleased(0, 187) and selectedWaypoint0.coord.r > minRadius then -- arrow down or DPAD DOWN - decrease radius of waypoint
                    selectedWaypoint0.coord.r = selectedWaypoint0.coord.r - 0.5
                    DeleteCheckpoint(selectedWaypoint0.checkpoint)
                    local color = getCheckpointColor(selectedBlipColor)
                    local checkpointType = -1 == selectedWaypoint0.number and checkeredFlagCheckpoint or numberedCheckpoint
                    selectedWaypoint0.checkpoint = makeCheckpoint(checkpointType, selectedWaypoint0.coord, selectedWaypoint0.coord, color, 127, selectedIndex0 - 1)
                    trackAccess = nil
                    savedTrackName = nil
                elseif 1 == IsControlJustReleased(0, 188) and selectedWaypoint0.coord.r < maxRadius then -- arrow up or DPAD UP - increase radius of waypoint
                    selectedWaypoint0.coord.r = selectedWaypoint0.coord.r + 0.5
                    DeleteCheckpoint(selectedWaypoint0.checkpoint)
                    local color = getCheckpointColor(selectedBlipColor)
                    local checkpointType = -1 == selectedWaypoint0.number and checkeredFlagCheckpoint or numberedCheckpoint
                    selectedWaypoint0.checkpoint = makeCheckpoint(checkpointType, selectedWaypoint0.coord, selectedWaypoint0.coord, color, 127, selectedIndex0 - 1)
                    trackAccess = nil
                    savedTrackName = nil
                end
            end
        elseif STATE_RACING == state then
            local player = PlayerPedId()
            local currentTime = GetNetworkTimeAccurate()
            local elapsedTime = currentTime - raceStart - raceDelay * 1000
            if elapsedTime < 0 then
                drawMsg(0.50, 0.46, "Race starting in", 0.7, 0)
                drawMsg(0.50, 0.50, ("%05.2f"):format(-elapsedTime / 1000.0), 0.7, 0)
                drawMsg(0.50, 0.54, "seconds", 0.7, 0)

                if false == camTransStarted then
                    camTransStarted = true
                    Citizen.CreateThread(function()
                        local entity = 1 == IsPedInAnyVehicle(player, false) and GetVehiclePedIsIn(player, false) or player

                        local cam0 = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                        SetCamCoord(cam0, GetOffsetFromEntityInWorldCoords(entity, 0.0, 5.0, 1.0))
                        PointCamAtEntity(cam0, entity, 0.0, 0.0, 0.0, true)

                        local cam1 = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                        SetCamCoord(cam1, GetOffsetFromEntityInWorldCoords(entity, -5.0, 0.0, 1.0))
                        PointCamAtEntity(cam1, entity, 0.0, 0.0, 0.0, true)

                        local cam2 = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                        SetCamCoord(cam2, GetOffsetFromEntityInWorldCoords(entity, 0.0, -5.0, 1.0))
                        PointCamAtEntity(cam2, entity, 0.0, 0.0, 0.0, true)

                        RenderScriptCams(true, false, 0, true, true)

                        SetCamActiveWithInterp(cam1, cam0, 1000, 0, 0)
                        while 1 == IsCamInterpolating(cam1) do
                            Citizen.Wait(0)
                        end
                        Citizen.Wait(500)

                        SetCamActiveWithInterp(cam2, cam1, 1000, 0, 0)
                        while 1 == IsCamInterpolating(cam2) do
                            Citizen.Wait(0)
                        end
                        Citizen.Wait(500)

                        RenderScriptCams(false, true, 1000, true, true)

                        SetGameplayCamRelativeRotation(GetEntityRotation(entity, 2))

                        DestroyAllCams(true)
                    end)
                end

                if -elapsedTime <= countdown * 1000 then
                    countdown = countdown - 1
                    PlaySoundFrontend(-1, "MP_5_SECOND_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                end

                if countdown < 5 then
                    for i = 0, 4 - countdown do
                        drawRect(i * 0.2 + 0.05, 0.15, 0.1, 0.1, 255, 0, 0, 255)
                    end
                end

                if 1 == IsPedInAnyVehicle(player, false) then
                    local vehicle = GetVehiclePedIsIn(player, false)
                    if false == vehicleFrozen and (nil == startVehicle or true == startVehicleSpawned) then
                        if GetPedInVehicleSeat(vehicle, -1) == player then
                            vehicleFrozen = true
                            FreezeEntityPosition(vehicle, true)
                        end
                    end
                    bestLapVehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
                else
                    if true == vehicleFrozen then
                        vehicleFrozen = false
                        FreezeEntityPosition(GetVehiclePedIsIn(player, true), false)
                    end
                    bestLapVehicleName = "FEET"
                end
            else
                local vehicle = GetVehiclePedIsIn(player, false)
                if vehicle ~= 0 then
                    currentVehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
                else
                    currentVehicleName = "FEET"
                end

                if false == started then
                    started = true
                    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
                    bestLapVehicleName = currentVehicleName
                    lapTimeStart = currentTime
                    speedo = true
                    if vehicle ~= 0 then
                        FreezeEntityPosition(vehicle, false)
                    end
                end

                if 1 == IsControlPressed(0, 73) then -- X key or A button or cross button
                    if true == respawnCtrlPressed then
                        if currentTime - respawnStart > 1000 then
                            respawnCtrlPressed = false
                            respawn()
                        else
                            drawMsg(leftSide, topSide - 0.06, "Respawn", 0.5, 1)
                            drawRect(rightSide, topSide - 0.06, 0.11, 0.03, 0, 0, 0, 127)
                            drawRect(rightSide, topSide - 0.06, 0.11 * (currentTime - respawnStart) / 1000, 0.03, 255, 255, 0, 255)
                        end
                    else
                        respawnCtrlPressed = true
                        respawnStart = currentTime
                    end
                else
                    respawnCtrlPressed = false
                end

                drawRect(leftSide - 0.01, topSide - 0.01, 0.21, 0.35, 0, 0, 0, 127)

                drawMsg(leftSide, topSide, "Position", 0.5, 1)
                if position ~= -1 then
                    drawMsg(rightSide, topSide, ("%d of %d"):format(position, numRacers), 0.5, 1)
                else
                    drawMsg(rightSide, topSide, "-- of --", 0.5, 1)
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
                drawMsg(rightSide, topSide + 0.12, currentVehicleName, 0.5, 1)

                local lapTime = currentTime - lapTimeStart
                minutes, seconds = minutesSeconds(lapTime)
                drawMsg(leftSide, topSide + 0.17, "Lap time", 0.7, 1)
                drawMsg(rightSide, topSide + 0.17, ("%02d:%05.2f"):format(minutes, seconds), 0.7, 1)

                drawMsg(leftSide, topSide + 0.21, "Best lap", 0.7, 1)
                if bestLapTime ~= -1 then
                    minutes, seconds = minutesSeconds(bestLapTime)
                    drawMsg(rightSide, topSide + 0.21, ("%02d:%05.2f"):format(minutes, seconds), 0.7, 1)
                else
                    drawMsg(rightSide, topSide + 0.21, "- - : - -", 0.7, 1)
                end

                if true == beginDNFTimeout then
                    local milliseconds = DNFTimeoutStart + DNFTimeout - currentTime
                    if milliseconds > 0 then
                        minutes, seconds = minutesSeconds(milliseconds)
                        drawMsg(leftSide, topSide + 0.29, "DNF time", 0.7, 1)
                        drawMsg(rightSide, topSide + 0.29, ("%02d:%05.2f"):format(minutes, seconds), 0.7, 1)
                    else -- DNF
                        DeleteCheckpoint(raceCheckpoint)
                        finishRace(-1)
                    end
                end

                if
                    STATE_RACING == state and
                    #(GetEntityCoords(player) - vector3(destCoord.x, destCoord.y, destCoord.z)) < destCoord.r and
                    (
                        (
                            (nil == raceType or "rand" == raceType) and
                            (0 == vehicle or GetPedInVehicleSeat(vehicle, -1) == player)
                        )
                        or
                        (
                            ("rest" == raceType or "class" == raceType) and
                            vehicle ~= 0 and
                            GetPedInVehicleSeat(vehicle, -1) == player and
                            GetEntityModel(vehicle) == originalVehicleHash
                        )
                    )
                then
                    DeleteCheckpoint(raceCheckpoint)
                    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)

                    numWaypointsPassed = numWaypointsPassed + 1

                    if currentWaypoint < #waypoints then
                        currentWaypoint = currentWaypoint + 1
                    else
                        if -1 == bestLapTime or lapTime < bestLapTime then
                            bestLapTime = lapTime
                            bestLapVehicleName = currentVehicleName
                        end

                        if currentLap < numLaps then
                            currentWaypoint = 1
                            lapTimeStart = currentTime
                            currentLap = currentLap + 1
                            if "rand" == raceType then
                                local index = (true == ordered) and 1 or math.random(#raceVehicleList)
                                vehicle = switchVehicle(player, raceVehicleList[index], -1, -1, -1, -1)
                                if vehicle ~= nil then
                                    SetEntityAsNoLongerNeeded(vehicle)
                                end
                                if false == recurring or true == ordered then
                                    table.remove(raceVehicleList, index)
                                end
                                PlaySoundFrontend(-1, "CHARACTER_SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                            end
                        else
                            finishRace(elapsedTime)
                        end
                    end

                    if STATE_RACING == state then
                        if vehicle ~= 0 then
                            respawnVehicleHash = GetEntityModel(vehicle)
                            respawnColorPri, respawnColorSec = GetVehicleColours(vehicle)
                            respawnColorPearl, respawnColorWheel = GetVehicleExtraColours(vehicle)
                        end

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

                            checkpointType = (1 == curr and numLaps == currentLap) and checkeredFlagCheckpoint or arrow3Checkpoint
                        else
                            if last > #waypoints then
                                addLast = false
                            end

                            checkpointType = #waypoints == curr and checkeredFlagCheckpoint or arrow3Checkpoint
                        end

                        SetBlipDisplay(waypoints[prev].blip, 0)
                        SetBlipColour(waypoints[prev].blip, waypoints[prev].color)

                        if true == addLast then
                            SetBlipDisplay(waypoints[last].blip, 2)
                        end

                        SetBlipColour(waypoints[curr].blip, currentWPBlipColor)
                        SetBlipRoute(waypoints[curr].blip, true)
                        SetBlipRouteColour(waypoints[curr].blip, blipRouteColor)

                        destCoord = waypoints[curr].coord
                        heading = GetEntityHeading(player)

                        local nextCoord = destCoord
                        if arrow3Checkpoint == checkpointType then
                            nextCoord = curr < #waypoints and waypoints[curr + 1].coord or waypoints[1].coord
                        end

                        raceCheckpoint = makeCheckpoint(checkpointType, destCoord, nextCoord, yellow, 127, 0)
                    end
                end
            end
        elseif STATE_IDLE == state then
            local player = PlayerPedId()
            local playerCoord = GetEntityCoords(player)

            local closestIndex = -1
            local minDist = defaultRadius
            for rIndex, race in pairs(races) do
                local dist = #(playerCoord - GetBlipCoords(race.blip))
                if dist < minDist then
                    minDist = dist
                    closestIndex = rIndex
                end
            end

            if closestIndex ~= -1 then
                local race = races[closestIndex]

                local msg = "Join race registered by '" .. race.owner .. "' using "
                if nil == race.trackName then
                    msg = msg .. "unsaved track"
                else
                    msg = msg .. ("pub" == race.access and "publicly" or "privately") .. " saved track '" .. race.trackName .. "'"
                end
                drawMsg(0.50, 0.50, msg, 0.7, 0)

                msg = ("%d buy-in : %d lap(s) : %d timeout"):format(race.buyin, race.laps, race.timeout)
                if "yes" == race.allowAI then
                    msg = msg .. " : AI allowed"
                end
                drawMsg(0.50, 0.54, msg, 0.7, 0)

                if race.rtype ~= nil then
                    if "rest" == race.rtype then
                        msg = "using '" .. race.restrict .. "' vehicle"
                    elseif "class" == race.rtype then
                        msg = "using " .. race.className .. " class vehicles"
                    elseif "rand" == race.rtype then
                        msg = "using random "
                        if race.vclass ~= nil then
                            msg = msg .. race.className .. " class "
                        end
                        msg = msg .. "vehicles"
                        if race.svehicle ~= nil then
                            msg = msg .. " : start '" .. race.svehicle .. "'"
                        end
                        if "yes" == race.recur then
                            msg = msg .. " : recurring"
                        else
                            msg = msg .. " : nonrecurring"
                        end
                        if "yes" == race.order then
                            msg = msg .. " : ordered"
                        else
                            msg = msg .. " : unordered"
                        end
                    end
                    drawMsg(0.50, 0.58, msg, 0.7, 0)
                end

                if 1 == IsControlJustReleased(0, 51) then -- E key or DPAD RIGHT -- join race
                    local joinRace = true

                    local vehicle = GetVehiclePedIsIn(player, false)

                    if "rest" == race.rtype then
                        if 0 == vehicle or GetEntityModel(vehicle) ~= GetHashKey(race.restrict) then
                            joinRace = false
                            notifyPlayer("Cannot join race.  Player must be in '" .. race.restrict .. "' vehicle.\n")
                        end
                    elseif "class" == race.rtype then
                        if race.vclass ~= -1 then
                            if 0 == vehicle or GetVehicleClass(vehicle) ~= race.vclass then
                                joinRace = false
                                notifyPlayer("Cannot join race.  Player must be in vehicle of " .. race.className .. " class.\n")
                            end
                        elseif 0 == #race.vehicleList then
                            joinRace = false
                            notifyPlayer("Cannot join race.  Vehicle list is empty.\n")
                        else
                            joinRace = false
                            if vehicle ~= 0 then
                                local vehicleHash = GetEntityModel(vehicle)
                                for _, model in pairs(race.vehicleList) do
                                    if GetHashKey(model) == vehicleHash then
                                        joinRace = true
                                        break
                                    end
                                end
                            end
                            if false == joinRace then
                                local list = ""
                                for _, model in pairs(race.vehicleList) do
                                    list = list .. model .. ", "
                                end
                                notifyPlayer("Cannot join race.  Player must be in one of the following vehicles: " .. string.sub(list, 1, -3) .. "\n")
                            end
                        end
                    elseif "rand" == race.rtype then
                        if 0 == #race.vehicleList then
                            joinRace = false
                            notifyPlayer("Cannot join race.  Vehicle list is empty.\n")
                        elseif race.vclass ~= nil and nil == race.svehicle and (0 == vehicle or GetVehicleClass(vehicle) ~= race.vclass) then
                            joinRace = false
                            notifyPlayer("Cannot join race.  Player must be in vehicle of " .. race.className .. " class.\n")
                        end
                    end

                    if true == joinRace then
                        removeAllRacerBlipGT()
                        TriggerServerEvent("races:join", closestIndex, PedToNet(player), nil)
                    end
                end
            end
        elseif STATE_JOINING == state then
            local race = races[raceIndex]
            if race ~= nil and #(GetEntityCoords(PlayerPedId()) - GetBlipCoords(race.blip)) < defaultRadius then
                local msg = "Joined to race registered by '" .. race.owner .. "' using "
                if nil == race.trackName then
                    msg = msg .. "unsaved track"
                else
                    msg = msg .. ("pub" == race.access and "publicly" or "privately") .. " saved track '" .. race.trackName .. "'"
                end
                drawMsg(0.50, 0.50, msg, 0.7, 0)

                msg = ("%d buy-in : %d lap(s) : %d timeout"):format(race.buyin, race.laps, race.timeout)
                if "yes" == race.allowAI then
                    msg = msg .. " : AI allowed"
                end
                drawMsg(0.50, 0.54, msg, 0.7, 0)

                if race.rtype ~= nil then
                    if "rest" == race.rtype then
                        msg = "using '" .. race.restrict .. "' vehicle"
                    elseif "class" == race.rtype then
                        msg = "using " .. race.className .. " class vehicles"
                    elseif "rand" == race.rtype then
                        msg = "using random "
                        if race.vclass ~= nil then
                            msg = msg .. race.className .. " class "
                        end
                        msg = msg .. "vehicles"
                        if race.svehicle ~= nil then
                            msg = msg .. " : start '" .. race.svehicle .. "'"
                        end
                        if "yes" == race.recur then
                            msg = msg .. " : recurring"
                        else
                            msg = msg .. " : nonrecurring"
                        end
                        if "yes" == race.order then
                            msg = msg .. " : ordered"
                        else
                            msg = msg .. " : unordered"
                        end
                    end
                    drawMsg(0.50, 0.58, msg, 0.7, 0)
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if aiState ~= nil then
            local currentTime = GetNetworkTimeAccurate()
            for aiName, driver in pairs(aiState.drivers) do
                if STATE_RACING == driver.state then
                    local elapsedTime = currentTime - aiState.raceStart - aiState.raceDelay * 1000
                    if elapsedTime >= 0 then
                        if false == driver.started then
                            driver.started = true
                            driver.lapTimeStart = currentTime
                            driver.stuckStart = currentTime
                        elseif true == aiState.beginDNFTimeout and aiState.DNFTimeoutStart + aiState.DNFTimeout - currentTime <= 0 then
                            driver.state = STATE_IDLE
                            TriggerServerEvent("races:finish", GetPlayerServerId(PlayerId()), driver.netID, aiName, driver.numWaypointsPassed, -1, driver.bestLapTime, driver.bestLapVehicleName, nil)
                        elseif false == IsEntityDead(driver.ped) then
                            if false == IsVehicleDriveable(driver.vehicle, false) then
                                respawnAI(driver)
                            else
                                local coord = GetEntityCoords(driver.ped)
                                if #(coord - driver.stuckCoord) < 5.0 then
                                    if currentTime - driver.stuckStart > 10000 then
                                        driver.stuckStart = currentTime
                                        respawnAI(driver)
                                    end
                                else
                                    driver.stuckCoord = coord
                                    driver.stuckStart = currentTime
                                end

                                if false == IsPedInVehicle(driver.ped, driver.vehicle, true) then
                                    if false == driver.enteringVehicle then
                                        driver.enteringVehicle = true
                                        driver.destSet = true
                                        TaskEnterVehicle(driver.ped, driver.vehicle, 10.0, -1, 2.0, 1, 0)
                                    end
                                else
                                    driver.enteringVehicle = false

                                    if true == driver.destSet then
                                        driver.destSet = false
                                        -- TaskVehicleDriveToCoordLongrange(ped, vehicle, x, y, z, speed, driveMode, stopRange)
                                        -- driveMode: https://vespura.com/fivem/drivingstyle/
                                        -- TaskVehicleDriveToCoordLongrange(driver.ped, driver.vehicle, driver.destCoord.x, driver.destCoord.y, driver.destCoord.z, GetVehicleEstimatedMaxSpeed(driver.vehicle), 787004, driver.destCoord.r * 0.5)
                                        -- On public track '01' and waypoint 7, AI would miss waypoint 7, move past it, wander a long way around, then come back to waypoint 7 when using TaskVehicleDriveToCoordLongrange
                                        -- Using TaskVehicleDriveToCoord instead.  Waiting to see if there is any weird behaviour with this function.
                                        -- TaskVehicleDriveToCoord(ped, vehicle, x, y, z, speed, p6, vehicleModel, drivingMode, stopRange, p10)
                                        TaskVehicleDriveToCoord(driver.ped, driver.vehicle, driver.destCoord.x, driver.destCoord.y, driver.destCoord.z, GetVehicleEstimatedMaxSpeed(driver.vehicle), 1.0, driver.model, 787004, 1.0, true)
                                    else
                                        if #(GetEntityCoords(driver.ped) - vector3(driver.destCoord.x, driver.destCoord.y, driver.destCoord.z)) < driver.destCoord.r then
                                            driver.numWaypointsPassed = driver.numWaypointsPassed + 1

                                            if driver.currentWaypoint < #aiState.waypointCoords then
                                                driver.currentWaypoint = driver.currentWaypoint + 1
                                            else
                                                local lapTime = currentTime - driver.lapTimeStart
                                                if -1 == driver.bestLapTime or lapTime < driver.bestLapTime then
                                                    driver.bestLapTime = lapTime
                                                    driver.bestLapVehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(driver.vehicle)))
                                                end

                                                if driver.currentLap < aiState.numLaps then
                                                    driver.currentWaypoint = 1
                                                    driver.lapTimeStart = currentTime
                                                    driver.currentLap = driver.currentLap + 1

                                                    if "rand" == aiState.raceType then
                                                        local index = (true == aiState.ordered) and 1 or math.random(#driver.raceVehicleList)
                                                        driver.vehicle = switchVehicle(driver.ped, driver.raceVehicleList[index], -1, -1, -1, -1)
                                                        if false == aiState.recurring or true == aiState.ordered then
                                                            table.remove(driver.raceVehicleList, index)
                                                        end
                                                    end
                                                else
                                                    driver.state = STATE_IDLE
                                                    TriggerServerEvent("races:finish", GetPlayerServerId(PlayerId()), driver.netID, aiName, driver.numWaypointsPassed, elapsedTime, driver.bestLapTime, driver.bestLapVehicleName, nil)
                                                end
                                            end

                                            if STATE_RACING == driver.state then
                                                local curr = true == aiState.startIsFinish and driver.currentWaypoint % #aiState.waypointCoords + 1 or driver.currentWaypoint
                                                driver.destCoord = aiState.waypointCoords[curr]
                                                driver.destSet = true
                                                driver.heading = GetEntityHeading(driver.ped)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                elseif STATE_IDLE == driver.state then
                    if false == IsEntityDead(driver.ped) and "rand" == aiState.raceType then
                        driver.vehicle = switchVehicle(driver.ped, driver.model, driver.colorPri, driver.colorSec, driver.colorPearl, driver.colorWheel)
                    end
                    SetEntityAsNoLongerNeeded(driver.vehicle)

                    Citizen.CreateThread(function()
                        while true do
                            if 0 == GetVehicleNumberOfPassengers(driver.vehicle) then
                                Citizen.Wait(1000)
                                SetEntityAsNoLongerNeeded(driver.ped)
                                break
                            end
                            Citizen.Wait(1000)
                        end
                    end)

                    aiState.numRacing = aiState.numRacing - 1
                    if aiState.numRacing ~= 0 then
                        aiState.drivers[aiName] = nil
                    else
                        aiState = nil
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    local enteringVehicle = false
    local recreated = false

    while true do
        Citizen.Wait(0)

        local player = PlayerPedId()

        if false == IsPedInAnyVehicle(player, true) then
            local vehicle = GetVehiclePedIsTryingToEnter(player)
            if false == enteringVehicle and 1 == DoesEntityExist(vehicle) then
                enteringVehicle = true

                for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
                    if 1 == IsVehicleSeatFree(vehicle, seat) then
                        TaskEnterVehicle(player, vehicle, 10.0, seat, 1.0, 1, 0)
                        break
                    end
                end

                Citizen.CreateThread(function()
                    Citizen.Wait(10000)
                    if false == IsPedInVehicle(player, vehicle, true) then
                        ClearPedTasksImmediately(player)
                        enteringVehicle = false
                    end
                end)
            end
        else
            enteringVehicle = false
        end

        if true == speedo then
            local speed = GetEntitySpeed(player)
            if "imperial" == unitom then
                drawMsg(leftSide, topSide + 0.25, "Speed(mph)", 0.7, 1)
                drawMsg(rightSide, topSide + 0.25, ("%05.2f"):format(speed * 2.2369363), 0.7, 1)
            else
                drawMsg(leftSide, topSide + 0.25, "Speed(kph)", 0.7, 1)
                drawMsg(rightSide, topSide + 0.25, ("%05.2f"):format(speed * 3.6), 0.7, 1)
            end
        end

        if false == IsPauseMenuActive() then
            if false == recreated then
                recreated = true
                for netID, racer in pairs(racerBlipGT) do
                    if 1 == NetworkDoesNetworkIdExist(netID) then
                        racer.gamerTag = CreateFakeMpGamerTag(NetToPed(netID), racer.name, false, false, nil, 0)
                        SetMpGamerTagVisibility(racer.gamerTag, 0, true)
                    end
                end
            end
        else
            recreated = false
        end

        if true == panelShown then
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
        end

        --SetVehicleDensityMultiplierThisFrame(0.0) -- debug
        --SetPedDensityMultiplierThisFrame(0.0) -- debug
    end
end)
