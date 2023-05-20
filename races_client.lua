--[[

Copyright (c) 2023, Neil J. Tan
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
local racerBlipColor <const> = 2 -- green
local selectedBlipColor <const> = 1 -- red
local blipRouteColor <const> = 18 -- light blue

local startFinishSprite <const> = 38 -- checkered flag
local startSprite <const> = 38 -- checkered flag
local finishSprite <const> = 38 -- checkered flag
local midSprite <const> = 1 -- numbered circle
local registerSprite <const> = 58 -- circled star
local racerSprite <const> = 1 -- circle

local finishCheckpoint <const> = 9 -- cylinder checkered flag
local midCheckpoint <const> = 42 -- cylinder with number
local plainCheckpoint <const> = 45 -- cylinder
local arrow3Checkpoint <const> = 7 -- cylinder with 3 arrows

local defaultBuyin <const> = 500 -- default race buy-in
local defaultLaps <const> = 1 -- default number of laps in a race
local defaultTimeout <const> = 120 -- default DNF timeout
local defaultAllowAI <const> = "no" -- default allow AI value
local defaultDelay <const> = 30 -- default race start delay
local defaultModel <const> = "adder" -- default spawned vehicle model
local defaultRadius <const> = 5.0 -- default waypoint radius

local minRadius <const> = 0.5 -- minimum waypoint radius
local maxRadius <const> = 10.0 -- maximum waypoint radius

local waypoints = {} -- waypoints[] = {coord = {x, y, z, r}, checkpoint, blip, sprite, color, number, name}
local startIsFinish = false -- flag indicating if start and finish are same waypoint

local highlightedIndex = 0 -- index of highlighted checkpoint
local selectedIndex0 = 0 -- index of first selected waypoint
local selectedIndex1 = 0 -- index of second selected waypoint

local topSide <const> = 0.45 -- top position of HUD
local leftSide <const> = 0.02 -- left position of HUD
local rightSide <const> = leftSide + 0.08 -- right position of HUD

local maxNumVisible <const> = 3 -- maximum number of waypoints visible during a race
local numVisible = maxNumVisible -- number of waypoints visible during a race - may be less than maxNumVisible

local raceIndex = -1 -- index of race player has joined
local isPublicTrack = false -- flag indicating if saved track is public or not
local savedTrackName = nil -- name of saved track - nil if track not saved

local raceStart = -1 -- start time of race before delay
local raceDelay = -1 -- delay before official start of race

local started = false -- flag indicating if race started

local startCoord = nil -- coordinates of vehicle once race has started

local camTransStarted = false -- flag indicating if camera transition at start of race has started

local countdown = -1 -- countdown before start

local vehicleFrozen = false -- flag indicating if vehicle player is in is frozen before start of race

local position = -1 -- position in race out of numRacers players
local numRacers = -1 -- number of players in race - no DNF players included

local numWaypointsPassed = -1 -- number of waypoints player has passed
local currentWaypoint = -1 -- current waypoint index - for multi-lap races, actual current waypoint index is currentWaypoint % #waypoints + 1
local waypointCoord = nil -- coordinates of current waypoint
local raceCheckpoint = nil -- race checkpoint of current waypoint in world

local numLaps = -1 -- number of laps in current race
local currentLap = -1 -- current lap

local lapTimeStart = -1 -- start time of current lap
local bestLapTime = -1 -- best lap time
local bestLapVehicleName = nil -- name of vehicle in which player recorded best lap time

local DNFTimeout = -1 -- DNF timeout after first player finishes the race
local beginDNFTimeout = false -- flag indicating if DNF timeout should begin
local timeoutStart = -1 -- start time of DNF timeout

local vehicleList = {} -- vehicle list used for custom class races and random vehicle races
local customClassVehicleList = {} -- list of vehicles in 'Custom'(-1) class race
local randomVehicleList = {} -- list of vehicles used in random vehicle races

local restrictedHash = nil -- vehicle hash of race with restricted vehicle
local restrictedClass = nil -- vehicle class of race with restricted class

local originalVehicleHash = nil -- vehicle hash of original vehicle before switching to other vehicles in random vehicle races
local originalColorPri = -1 -- primary color of original vehicle
local originalColorSec = -1 -- secondary color of original vehicle
local originalColorPearl = -1 -- pearlescent color of original vehicle
local originalColorWheel = -1 -- wheel color of original vehicle
local startVehicle = nil -- vehicle model of starting vehicle used in random vehicle races

local currentVehicleHash = nil -- hash of current vehicle being driven
local currentColorPri = -1 -- primary color of current vehicle
local currentColorSec = -1 -- secondary color of current vehicle
local currentColorPearl = -1 -- pearlescent color of current vehicle
local currentColorWheel = -1 -- wheel color of current vehicle
local currentVehicleName = nil -- name of current vehicle being driven

local respawnCtrlPressed = false -- flag indicating if respawn crontrol is pressed
local respawnStart = -1 -- start time when respawn control pressed

local racerBlipGT = {} -- blips and gamer tags for all racers participating in race

local starts = {} -- starts[playerID] = {isPublic, trackName, owner, buyin, laps, timeout, rtype, restrict, vclass, svehicle, vehicleList, blip, checkpoint} - registration points

local results = {} -- results[] = {source, playerName, finishTime, bestLapTime, vehicleName}

local speedo = false -- flag indicating if speedometer is displayed
local unitom = "imperial" -- current unit of measurement

local panelShown = false -- flag indicating if main, track, ai, list or register panel is shown

local allVehiclesList = {} -- list of all vehicles from vehicles.json
local allVehiclesHTML = "" -- html option list of all vehicles

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
            panel = "reply",
            message = string.gsub(msg, "\n", "<br>")
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
    if 42 == checkpointType or 45 == checkpointType then
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
    local waypoint = waypoints[index]
    SetBlipSprite(waypoint.blip, waypoint.sprite)
    SetBlipColour(waypoint.blip, waypoint.color)
    ShowNumberOnBlip(waypoint.blip, waypoint.number)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(waypoint.name)
    EndTextCommandSetBlipName(waypoint.blip)
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

local function restoreBlips()
    for i = 1, #waypoints do
        SetBlipDisplay(waypoints[i].blip, 2)
    end
end

local function deleteRegistrationPoint(rIndex)
    RemoveBlip(starts[rIndex].blip) -- delete registration blip
    DeleteCheckpoint(starts[rIndex].checkpoint) -- delete registration checkpoint
    starts[rIndex] = nil
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

local function putPedInVehicle(ped, model, priColor, secColor, pearlColor, wheelColor, coord)
    local vehicle = CreateVehicle(model, coord.x, coord.y, coord.z, GetEntityHeading(ped), true, false)
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
    if vehicle ~= 0 then
        local newVehicle = nil
        if GetPedInVehicleSeat(vehicle, -1) == ped then
            RequestModel(model)
            while false == HasModelLoaded(model) do
                Citizen.Wait(0)
            end
            local passengers = {}
            for seat = 0, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
                local passenger = GetPedInVehicleSeat(vehicle, seat)
                if passenger ~= 0 then
                    passengers[#passengers + 1] = {ped = passenger, seat = seat}
                end
            end
            local coord = GetEntityCoords(vehicle)
            local speed = GetEntitySpeed(ped)
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteVehicle(vehicle)
            newVehicle = putPedInVehicle(ped, model, priColor, secColor, pearlColor, wheelColor, coord)
            SetVehicleForwardSpeed(newVehicle, speed)
            for _, passenger in pairs(passengers) do
                SetPedIntoVehicle(passenger.ped, newVehicle, passenger.seat)
            end
        end
        return newVehicle
    else
        RequestModel(model)
        while false == HasModelLoaded(model) do
            Citizen.Wait(0)
        end
        return putPedInVehicle(ped, model, priColor, secColor, pearlColor, wheelColor, GetEntityCoords(ped))
    end
end

local function getClassName(vclass)
    if -1 == vclass then
        return "'Custom'(-1)"
    elseif 0 == vclass then
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

local function vehicleInList(vehicle, list)
    for _, model in pairs(list) do
        if GetEntityModel(vehicle) == GetHashKey(model) then
            return true
        end
    end
    return false
end

local function finishRace(time)
    TriggerServerEvent("races:finish", raceIndex, PedToNet(PlayerPedId()), nil, numWaypointsPassed, time, bestLapTime, bestLapVehicleName, nil)
    restoreBlips()
    SetBlipRoute(waypoints[1].blip, true)
    SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
    speedo = false
    if originalVehicleHash ~= nil then -- in random vehicle race
        SetEntityAsNoLongerNeeded(switchVehicle(PlayerPedId(), originalVehicleHash, originalColorPri, originalColorSec, originalColorPearl, originalColorWheel))
    end
    raceState = STATE_IDLE
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
                local checkpointType = 38 == selectedWaypoint0.sprite and finishCheckpoint or midCheckpoint
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
                    local checkpointType = finishCheckpoint
                    local waypointNum = 0
                    if true == startIsFinish then
                        if #waypoints == selectedIndex and 1 == selectedIndex0 then -- split start/finish waypoint
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
                        if 1 == selectedIndex and #waypoints == selectedIndex0 then -- combine start and finish waypoints
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

                        selectedIndex0 = 0
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

local function removeRacerBlipGT()
    for _, racer in pairs(racerBlipGT) do
        RemoveBlip(racer.blip)
        RemoveMpGamerTag(racer.gamerTag)
    end
    racerBlipGT = {}
end

local function respawnAI(driver)
    local coord = driver.startCoord
    if true == aiState.startIsFinish then
        if driver.currentWP > 0 then
            coord = aiState.waypointCoords[driver.currentWP]
        end
    else
        if driver.currentWP > 1 then
            coord = aiState.waypointCoords[driver.currentWP - 1]
        end
    end
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
    RequestModel(vehicleHash)
    while false == HasModelLoaded(vehicleHash) do
        Citizen.Wait(0)
    end
    SetEntityAsMissionEntity(driver.vehicle, true, true)
    DeleteVehicle(driver.vehicle)
    driver.vehicle = putPedInVehicle(driver.ped, vehicleHash, priColor, secColor, pearlColor, wheelColor, coord)
    for _, passenger in pairs(passengers) do
        SetPedIntoVehicle(passenger.ped, driver.vehicle, passenger.seat)
    end
    driver.destSet = true
end

local function updateVehicleList()
    table.sort(vehicleList)
    local html = ""
    for _, model in ipairs(vehicleList) do
        html = html .. "<option value = \"" .. model .. "\">" .. model .. "</option>"
    end
    SendNUIMessage({
        update = "vehicleList",
        vehicleList = html
    })
end

local function deleteDriver(aiName, pIndex)
    local driver = aiState.drivers[aiName]
    if driver ~= nil then
        if STATE_JOINING == driver.raceState then
            TriggerServerEvent("races:leave", pIndex, driver.netID, aiName)
            DeletePed(driver.ped)
            SetEntityAsMissionEntity(driver.vehicle, true, true)
            DeleteVehicle(driver.vehicle)
            aiState.drivers[aiName] = nil
            aiState.numRacing = aiState.numRacing - 1
            if 0 == aiState.numRacing then
                aiState = nil
            end
            sendMessage("AI driver '" .. aiName .. "' deleted.\n")
            return true
        elseif STATE_RACING == driver.raceState then
            sendMessage("Cannot delete AI driver.  '" .. aiName .. "' is in a race.\n")
        else
            sendMessage("Cannot delete AI driver.  '" .. aiName .. "' is not joined to a race.\n")
        end
    else
        sendMessage("Cannot delete AI driver.  AI driver '" .. aiName .. "' not found.\n")
    end
    return false
end

local function edit()
    if STATE_IDLE == raceState then
        raceState = STATE_EDITING
        SetWaypointOff()
        setStartToFinishCheckpoints()
        sendMessage("Editing started.\n")
    elseif STATE_EDITING == raceState then
        raceState = STATE_IDLE
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
    if STATE_IDLE == raceState then
        deleteWaypointBlips()
        waypoints = {}
        startIsFinish = false
        savedTrackName = nil
        sendMessage("Waypoints cleared.\n")
    elseif STATE_EDITING == raceState then
        highlightedIndex = 0
        selectedIndex0 = 0
        selectedIndex1 = 0
        deleteWaypointCheckpoints()
        deleteWaypointBlips()
        waypoints = {}
        startIsFinish = false
        savedTrackName = nil
        sendMessage("Waypoints cleared.\n")
    else
        sendMessage("Cannot clear waypoints.  Leave race first.\n")
    end
end

local function reverse()
    if #waypoints > 1 then
        if STATE_IDLE == raceState then
            savedTrackName = nil
            loadWaypointBlips(waypointsToCoordsRev())
            sendMessage("Waypoints reversed.\n")
        elseif STATE_EDITING == raceState then
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
    else
        sendMessage("Cannot reverse waypoints.  Track needs to have at least 2 waypoints.\n")
    end
end

local function loadTrack(access, trackName)
    if "pvt" == access or "pub" == access then
        if trackName ~= nil then
            if STATE_IDLE == raceState or STATE_EDITING == raceState then
                TriggerServerEvent("races:load", "pub" == access, trackName)
            else
                sendMessage("Cannot load track.  Leave race first.\n")
            end
        else
            sendMessage("Cannot load track.  Name required.\n")
        end
    else
        sendMessage("Cannot load track.  Invalid access type.\n")
    end
end

local function saveTrack(access, trackName)
    if "pvt" == access or "pub" == access then
        if trackName ~= nil then
            if #waypoints > 1 then
                TriggerServerEvent("races:save", "pub" == access, trackName, waypointsToCoords())
            else
                sendMessage("Cannot save track.  Track needs to have at least 2 waypoints.\n")
            end
        else
            sendMessage("Cannot save track.  Name required.\n")
        end
    else
        sendMessage("Cannot save track.  Invalid access type.\n")
    end
end

local function overwriteTrack(access, trackName)
    if "pvt" == access or "pub" == access then
        if trackName ~= nil then
            if #waypoints > 1 then
                TriggerServerEvent("races:overwrite", "pub" == access, trackName, waypointsToCoords())
            else
                sendMessage("Cannot overwrite track.  Track needs to have at least 2 waypoints.\n")
            end
        else
            sendMessage("Cannot overwrite track.  Name required.\n")
        end
    else
        sendMessage("Cannot overwrite track.  Invalid access type.\n")
    end
end

local function deleteTrack(access, trackName)
    if "pvt" == access or "pub" == access then
        if trackName ~= nil then
            TriggerServerEvent("races:delete", "pub" == access, trackName)
        else
            sendMessage("Cannot delete track.  Name required.\n")
        end
    else
        sendMessage("Cannot delete track.  Invalid access type.\n")
    end
end

local function listTracks(access)
    if "pvt" == access or "pub" == access then
        TriggerServerEvent("races:list", "pub" == access)
    else
        sendMessage("Cannot list tracks.  Invalid access type.\n")
    end
end

local function bestLapTimes(access, trackName)
    if "pvt" == access or "pub" == access then
        if trackName ~= nil then
            TriggerServerEvent("races:blt", "pub" == access, trackName)
        else
            sendMessage("Cannot list best lap times.  Name required.\n")
        end
    else
        sendMessage("Cannot list best lap times.  Invalid access type.\n")
    end
end

local function addAIDriver(aiName, coord, heading)
    if aiName ~= nil then
        local start = starts[GetPlayerServerId(PlayerId())]
        if start ~= nil then
            if "yes" == start.allowAI then
                if nil == aiState then
                    aiState = {
                        numRacing = 0,
                        raceStart = -1,
                        raceDelay = -1,
                        numLaps = start.laps,
                        DNFTimeout = start.timeout * 1000,
                        beginDNFTimeout = false,
                        timeoutStart = -1,
                        rtype = start.rtype,
                        restrict = start.restrict,
                        vclass = start.vclass,
                        svehicle = start.svehicle,
                        vehicleList = start.vehicleList,
                        randomVehicleList = {},
                        waypointCoords = nil,
                        startIsFinish = false,
                        drivers = {}
                    }
                end
                if nil == aiState.drivers[aiName] then
                    aiState.drivers[aiName] = {
                        netID = nil,
                        raceState = STATE_JOINING,
                        started = false,
                        startCoord = coord,
                        heading = heading,
                        destSet = false,
                        destCoord = nil,
                        model = nil,
                        vehicle = nil,
                        colorPri = -1,
                        colorSec = -1,
                        colorPearl = -1,
                        colorWheel = -1,
                        ped = nil,
                        currentWP = -1,
                        numWaypointsPassed = 0,
                        currentLap = 1,
                        lapTimeStart = -1,
                        bestLapTime = -1,
                        bestLapVehicleName = nil,
                        enteringVehicle = false,
                        stuckCoord = coord,
                        stuckStart = -1
                    }
                    aiState.numRacing = aiState.numRacing + 1
                    sendMessage("AI driver '" .. aiName .. "' added.\n")
                    return true
                else
                    sendMessage("Cannot add AI driver.  AI driver '" .. aiName .. "' already exists.\n")
                end
            else
                sendMessage("Cannot add AI driver.  AI drivers not allowed.\n")
            end
        else
            sendMessage("Cannot add AI driver.  Race has not been registered.\n")
        end
    else
        sendMessage("Cannot add AI driver.  Name required.\n")
    end
    return false
end

local function spawnAIDriver(aiName, model)
    if aiName ~= nil then
        local pIndex = GetPlayerServerId(PlayerId())
        if starts[pIndex] ~= nil then
            if "yes" == starts[pIndex].allowAI then
                if aiState ~= nil then
                    local driver = aiState.drivers[aiName]
                    if driver ~= nil then
                        model = model or defaultModel
                        if 1 == IsModelInCdimage(model) and 1 == IsModelAVehicle(model) then
                            if "rest" == aiState.rtype then
                                if model ~= aiState.restrict then
                                    sendMessage("Cannot spawn '" .. aiName .. "'.  AI needs to be in '" .. aiState.restrict .. "' vehicle.\n")
                                    return false
                                end
                            elseif "class" == aiState.rtype then
                                if aiState.vclass ~= -1 then
                                    if GetVehicleClassFromName(model) ~= aiState.vclass then
                                        sendMessage("Cannot spawn  '" .. aiName .. "'.  AI needs to be in vehicle of " .. getClassName(aiState.vclass) .. " class.\n")
                                        return false
                                    end
                                elseif 0 == #aiState.vehicleList then
                                    sendMessage("Cannot spawn  '" .. aiName .. "'.  Vehicle list is empty.\n")
                                    return false
                                else
                                    local found = false
                                    local list = ""
                                    for _, vehModel in pairs(aiState.vehicleList) do
                                        if model == vehModel then
                                            found = true
                                            break
                                        end
                                        list = list .. vehModel .. ", "
                                    end
                                    if false == found then
                                        sendMessage("Cannot spawn  '" .. aiName .. "'.  AI needs to be in one of the following vehicles: " .. string.sub(list, 1, -3) .. "\n")
                                        return false
                                    end
                                end
                            elseif "rand" == aiState.rtype then
                                if 0 == #aiState.vehicleList then
                                    sendMessage("Cannot spawn  '" .. aiName .. "'.  Vehicle list is empty.\n")
                                    return false
                                elseif aiState.vclass ~= nil and nil == aiState.svehicle and GetVehicleClassFromName(model) ~= aiState.vclass then
                                    sendMessage("Cannot spawn  '" .. aiName .. "'.  AI needs to be in vehicle of " .. getClassName(aiState.vclass) .. " class.\n")
                                    return false
                                end
                            end

                            driver.model = model
                            if driver.ped ~= nil and driver.vehicle ~= nil then
                                driver.vehicle = switchVehicle(driver.ped, model, -1, -1, -1, -1)
                            else
                                local pedModel = "a_m_y_skater_01"
                                RequestModel(model)
                                RequestModel(pedModel)
                                while false == HasModelLoaded(model) or false == HasModelLoaded(pedModel) do
                                    Citizen.Wait(0)
                                end
                                driver.ped = CreatePed(PED_TYPE_CIVMALE, pedModel, driver.startCoord.x, driver.startCoord.y, driver.startCoord.z, driver.heading, true, false)
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

                                driver.vehicle = putPedInVehicle(driver.ped, model, -1, -1, -1, -1, driver.startCoord)

                                TriggerServerEvent("races:join", pIndex, driver.netID, aiName)
                            end

                            if "rand" == aiState.rtype then
                                driver.colorPri, driver.colorSec = GetVehicleColours(driver.vehicle)
                                driver.colorPearl, driver.colorWheel = GetVehicleExtraColours(driver.vehicle)
                            end
                            driver.bestLapVehicleName = GetLabelText(GetDisplayNameFromVehicleModel(model))

                            sendMessage("AI driver '" .. aiName .. "' spawned in '" .. driver.bestLapVehicleName .. "'.\n")

                            return true
                        else
                            sendMessage("Cannot spawn  '" .. aiName .. "'.  Invalid vehicle.\n")
                        end
                    else
                        sendMessage("Cannot spawn  '" .. aiName .. "'.  AI driver '" .. aiName .. "' not found.\n")
                    end
                else
                    sendMessage("Cannot spawn  '" .. aiName .. "'.  No AI drivers to spawn.\n")
                end
            else
                sendMessage("Cannot spawn  '" .. aiName .. "'.  AI drivers not allowed.\n")
            end
        else
            sendMessage("Cannot spawn  '" .. aiName .. "'.  Race has not been registered.\n")
        end
    else
        sendMessage("Cannot spawn AI driver.  Name required.\n")
    end
    return false
end

local function deleteAIDriver(aiName)
    if aiName ~= nil then
        local pIndex = GetPlayerServerId(PlayerId())
        if starts[pIndex] ~= nil then
            if "yes" == starts[pIndex].allowAI then
                if aiState ~= nil then
                    return deleteDriver(aiName, pIndex)
                else
                    sendMessage("Cannot delete AI driver.  No AI drivers to delete.\n")
                end
            else
                sendMessage("Cannot delete AI driver.  AI drivers not allowed.\n")
            end
        else
            sendMessage("Cannot delete AI driver.  Race has not been registered.\n")
        end
    else
        sendMessage("Cannot delete AI driver.  Name required.\n")
    end
    return false
end

local function deleteAllAIDrivers()
    local pIndex = GetPlayerServerId(PlayerId())
    if starts[pIndex] ~= nil then
        if "yes" == starts[pIndex].allowAI then
            if aiState ~= nil then
                for aiName in pairs(aiState.drivers) do
                    deleteDriver(aiName, pIndex)
                end
                sendMessage("All AI deleted.\n")
            else
                sendMessage("No AI drivers to delete.\n")
            end
            return true
        else
            sendMessage("Cannot delete all AI drivers.  AI drivers not allowed.\n")
        end
    else
        sendMessage("Cannot delete all AI drivers.  Race has not been registered.\n")
    end
    return false
end

local function listAIDrivers()
    local start = starts[GetPlayerServerId(PlayerId())]
    if start ~= nil then
        if "yes" == start.allowAI then
            if aiState ~= nil then
                local aiNames = {}
                for aiName in pairs(aiState.drivers) do
                    aiNames[#aiNames + 1] = aiName
                end
                table.sort(aiNames)
                local msg = "AI drivers:\n"
                for _, aiName in ipairs(aiNames) do
                    msg = msg .. aiName .. " - "
                    local driver = aiState.drivers[aiName]
                    if driver.ped ~= nil and driver.vehicle ~= nil then
                        msg = msg .. "'" .. driver.bestLapVehicleName .. "' (" .. driver.model .. ")\n"
                    else
                        msg = msg .. "NO VEHICLE\n"
                    end
                end
                sendMessage(msg)
            else
                sendMessage("Cannot list AI drivers.  No AI drivers to list.\n")
            end
        else
            sendMessage("Cannot list AI drivers.  AI drivers not allowed.\n")
        end
    else
        sendMessage("Cannot list AI drivers.  Race has not been registered.\n")
    end
end

local function loadGrp(access, name)
    local start = starts[GetPlayerServerId(PlayerId())]
    if start ~= nil then
        if "yes" == start.allowAI then
            if "pvt" == access or "pub" == access then
                if name ~= nil then
                    TriggerServerEvent("races:loadGrp", "pub" == access, name)
                else
                    sendMessage("Cannot load AI group.  Name required.\n")
                end
            else
                sendMessage("Cannot load AI group.  Invalid access type.\n")
            end
        else
            sendMessage("Cannot load AI group.  AI drivers not allowed.\n")
        end
    else
        sendMessage("Cannot load AI group.  Race has not been registered.\n")
    end
end

local function saveGrp(access, name)
    local start = starts[GetPlayerServerId(PlayerId())]
    if start ~= nil then
        if "yes" == start.allowAI then
            if "pvt" == access or "pub" == access then
                if name ~= nil then
                    if aiState ~= nil then
                        local group = {}
                        for aiName, driver in pairs(aiState.drivers) do
                            if driver.ped ~= nil and driver.vehicle ~= nil then
                                group[aiName] = {startCoord = driver.startCoord, heading = driver.heading, model = driver.model}
                            else
                                sendMessage("Cannot save AI group.  Some AI drivers not spawned.\n")
                                return
                            end
                        end
                        TriggerServerEvent("races:saveGrp", "pub" == access, name, group)
                    else
                        sendMessage("Cannot save AI group.  No AI drivers added.\n")
                    end
                else
                    sendMessage("Cannot save AI group.  Name required.\n")
                end
            else
                sendMessage("Cannot save AI group.  Invalid access type.\n")
            end
        else
            sendMessage("Cannot save AI group.  AI drivers not allowed.\n")
        end
    else
        sendMessage("Cannot save AI group.  Race has not been registered.\n")
    end
end

local function overwriteGrp(access, name)
    local start = starts[GetPlayerServerId(PlayerId())]
    if start ~= nil then
        if "yes" == start.allowAI then
            if "pvt" == access or "pub" == access then
                if name ~= nil then
                    if aiState ~= nil then
                        local group = {}
                        for aiName, driver in pairs(aiState.drivers) do
                            if driver.ped ~= nil and driver.vehicle ~= nil then
                                group[aiName] = {startCoord = driver.startCoord, heading = driver.heading, model = driver.model}
                            else
                                sendMessage("Cannot overwrite AI group.  Some AI drivers not spawned.\n")
                                return
                            end
                        end
                        TriggerServerEvent("races:overwriteGrp", "pub" == access, name, group)
                    else
                        sendMessage("Cannot overwrite AI group.  No AI drivers added.\n")
                    end
                else
                    sendMessage("Cannot overwrite AI group.  Name required.\n")
                end
            else
                sendMessage("Cannot overwrite AI group.  Invalid access type.\n")
            end
        else
            sendMessage("Cannot overwrite AI group.  AI drivers not allowed.\n")
        end
    else
        sendMessage("Cannot overwrite AI group.  Race has not been registered.\n")
    end
end

local function deleteGrp(access, name)
    if "pvt" == access or "pub" == access then
        if name ~= nil then
            TriggerServerEvent("races:deleteGrp", "pub" == access, name)
        else
            sendMessage("Cannot delete AI group.  Name required.\n")
        end
    else
        sendMessage("Cannot delete AI group.  Invalid access type.\n")
    end
end

local function listGrps(access)
    if "pvt" == access or "pub" == access then
        TriggerServerEvent("races:listGrps", "pub" == access)
    else
        sendMessage("Cannot list AI groups.  Invalid access type.\n")
    end
end

local function addVeh(model)
    if model ~= nil then
        if 1 == IsModelInCdimage(model) and 1 == IsModelAVehicle(model) then
            vehicleList[#vehicleList + 1] = model
            if true == panelShown then
                updateVehicleList()
            end
            sendMessage("'" .. model .. "' added to vehicle list.\n")
        else
            sendMessage("Cannot add vehicle.  Invalid vehicle.\n")
        end
    else
        sendMessage("Cannot add vehicle.  Vehicle model required.\n")
    end
end

local function deleteVeh(model)
    if model ~= nil then
        if 1 == IsModelInCdimage(model) and 1 == IsModelAVehicle(model) then
            for i = 1, #vehicleList do
                if vehicleList[i] == model then
                    table.remove(vehicleList, i)
                    if true == panelShown then
                        updateVehicleList()
                    end
                    sendMessage("'" .. model .. "' deleted from vehicle list.\n")
                    return
                end
            end
            sendMessage("Cannot delete vehicle.  '" .. model .. "' not found.\n")
        else
            sendMessage("Cannot delete vehicle.  Invalid vehicle.\n")
        end
    else
        sendMessage("Cannot delete vehicle.  Vehicle model required.\n")
    end
end

local function addClass(vclass)
    vclass = tonumber(vclass)
    if vclass ~= fail and "integer" == math.type(vclass) and vclass >= 0 and vclass <= 21 then
        for _, model in pairs(allVehiclesList) do
            if GetVehicleClassFromName(model) == vclass then
                vehicleList[#vehicleList + 1] = model
            end
        end
        if true == panelShown then
            updateVehicleList()
        end
        sendMessage("Vehicles of class " .. getClassName(vclass) .. " added to vehicle list.\n")
    else
        sendMessage("Cannot add vehicles to vehicle list.  Invalid vehicle class.\n")
    end
end

local function deleteClass(vclass)
    vclass = tonumber(vclass)
    if vclass ~= fail and "integer" == math.type(vclass) and vclass >= 0 and vclass <= 21 then
        for i = 1, #vehicleList do
            while true do
                if vehicleList[i] ~= nil and GetVehicleClassFromName(vehicleList[i]) == vclass then
                    table.remove(vehicleList, i)
                else
                    break
                end
            end
        end
        if true == panelShown then
            updateVehicleList()
        end
        sendMessage("Vehicles of class " .. getClassName(vclass) .. " deleted from vehicle list.\n")
    else
        sendMessage("Cannot delete vehicles from vehicle list.  Invalid vehicle class.\n")
    end
end

local function addAllVeh()
    for _, model in pairs(allVehiclesList) do
        vehicleList[#vehicleList + 1] = model
    end
    if true == panelShown then
        updateVehicleList()
    end
    sendMessage("Added all vehicles to vehicle list.\n")
end

local function deleteAllVeh()
    vehicleList = {}
    if true == panelShown then
        updateVehicleList()
    end
    sendMessage("Deleted all vehicles from vehicle list.\n")
end

local function listVeh()
    if #vehicleList > 0 then
        table.sort(vehicleList)
        local msg = "Vehicle list: "
        for i = 1, #vehicleList do
            msg = msg .. vehicleList[i] .. ", "
        end
        sendMessage(string.sub(msg, 1, -3) .. "\n")
    else
        sendMessage("Cannot list vehicles.  Vehicle list is empty.\n")
    end
end

local function loadLst(access, name)
    if "pvt" == access or "pub" == access then
        if name ~= nil then
            TriggerServerEvent("races:loadLst", "pub" == access, name)
        else
            sendMessage("Cannot load vehicle list.  Name required.\n")
        end
    else
        sendMessage("Cannot load vehicle list.  Invalid access type.\n")
    end
end

local function saveLst(access, name)
    if "pvt" == access or "pub" == access then
        if name ~= nil then
            if #vehicleList > 0 then
                TriggerServerEvent("races:saveLst", "pub" == access, name, vehicleList)
            else
                sendMessage("Cannot save vehicle list.  List is empty.\n")
            end
        else
            sendMessage("Cannot save vehicle list.  Name required.\n")
        end
    else
        sendMessage("Cannot save vehicle list.  Invalid access type.\n")
    end
end

local function overwriteLst(access, name)
    if "pvt" == access or "pub" == access then
        if name ~= nil then
            if #vehicleList > 0 then
                TriggerServerEvent("races:overwriteLst", "pub" == access, name, vehicleList)
            else
                sendMessage("Cannot overwrite vehicle list.  List is empty.\n")
            end
        else
            sendMessage("Cannot overwrite vehicle list.  Name required.\n")
        end
    else
        sendMessage("Cannot overwrite vehicle list.  Invalid access type.\n")
    end
end

local function deleteLst(access, name)
    if "pvt" == access or "pub" == access then
        if name ~= nil then
            TriggerServerEvent("races:deleteLst", "pub" == access, name)
        else
            sendMessage("Cannot delete vehicle list.  Name required.\n")
        end
    else
        sendMessage("Cannot delete vehicle list.  Invalid access type.\n")
    end
end

local function listLsts(access)
    if "pvt" == access or "pub" == access then
        TriggerServerEvent("races:listLsts", "pub" == access)
    else
        sendMessage("Cannot list vehicle lists.  Invalid access type.\n")
    end
end

local function register(buyin, laps, timeout, allowAI, rtype, arg0, arg1)
    if nil == starts[GetPlayerServerId(PlayerId())] then
        if #waypoints > 1 then
            local bton = tonumber(buyin)
            if nil == buyin or "." == buyin or ("integer" == math.type(bton) and bton >= 0) then
                buyin = (nil == buyin or "." == buyin) and defaultBuyin or bton
                local lton = tonumber(laps)
                if nil == laps or "." == laps or ("integer" == math.type(lton) and lton > 0) then
                    laps = (nil == laps or "." == laps) and defaultLaps or lton
                    local tton = tonumber(timeout)
                    if nil == timeout or "." == timeout or ("integer" == math.type(tton) and tton >= 0) then
                        timeout = (nil == timeout or "." == timeout) and defaultTimeout or tton
                        allowAI = (nil == allowAI or "." == allowAI) and defaultAllowAI or allowAI
                        if "yes" == allowAI or "no" == allowAI then
                            if STATE_IDLE == raceState or STATE_EDITING == raceState then
                                if 1 == laps or (laps > 1 and true == startIsFinish) then
                                    local coord = vector3(waypoints[1].coord.x, waypoints[1].coord.y, waypoints[1].coord.z)
                                    for _, start in pairs(starts) do
                                        if #(coord - GetBlipCoords(start.blip)) < defaultRadius then
                                            sendMessage("Cannot register race.  Registration point in use by another race.\n")
                                            return
                                        end
                                    end
                                    if "." == arg0 then
                                        arg0 = nil
                                    end
                                    local restrict = nil
                                    local vclass = nil
                                    local svehicle = nil
                                    local vehList = nil
                                    if "rest" == rtype then
                                        restrict = arg0
                                        if nil == restrict or IsModelInCdimage(restrict) ~= 1 or IsModelAVehicle(restrict) ~= 1 then
                                            sendMessage("Cannot register race.  Invalid restricted vehicle.\n")
                                            return
                                        end
                                    elseif "class" == rtype then
                                        vclass = tonumber(arg0)
                                        if fail == vclass or math.type(vclass) ~= "integer" or vclass < -1 or vclass > 21 then
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
                                    elseif "rand" == rtype then
                                        if 0 == #vehicleList  then
                                            sendMessage("Cannot register race.  Vehicle list is empty.\n")
                                            return
                                        end
                                        vclass = arg0
                                        if nil == vclass then
                                            vehList = vehicleList
                                        else
                                            vclass = tonumber(vclass)
                                            if fail == vclass or math.type(vclass) ~= "integer" or vclass < 0 or vclass > 21 then
                                                sendMessage("Cannot register race.  Invalid vehicle class.\n")
                                                return
                                            end
                                            vehList = {}
                                            for _, model in pairs(vehicleList) do
                                                if GetVehicleClassFromName(model) == vclass then
                                                    vehList[#vehList + 1] = model
                                                end
                                            end
                                            if 0 == #vehList then
                                                sendMessage("Cannot register race.  No vehicles of " .. getClassName(vclass) .. " class in vehicle list.\n")
                                                return
                                            end
                                        end
                                        svehicle = arg1
                                        if svehicle ~= nil then
                                            if IsModelInCdimage(svehicle) ~= 1 or IsModelAVehicle(svehicle) ~= 1 then
                                                sendMessage("Cannot register race.  Invalid start vehicle.\n")
                                                return
                                            elseif vclass ~= nil and GetVehicleClassFromName(svehicle) ~= vclass then
                                                sendMessage("Cannot register race.  Start vehicle not of " .. getClassName(vclass) .. " class.\n")
                                                return
                                            end
                                        end
                                    elseif rtype ~= nil then
                                        sendMessage("Cannot register race.  Unknown race type.\n")
                                        return
                                    end
                                    if "yes" == allowAI or "rand" == rtype then
                                        buyin = 0
                                    end
                                    local rdata = {rtype = rtype, restrict = restrict, vclass = vclass, svehicle = svehicle, vehicleList = vehList}
                                    TriggerServerEvent("races:register", waypointsToCoords(), isPublicTrack, savedTrackName, buyin, laps, timeout, allowAI, rdata)
                                else
                                    sendMessage("Cannot register race.  Track needs to be converted to a circuit for multi-lap races.\n")
                                end
                            else
                                sendMessage("Cannot register race.  Leave race first.\n")
                            end
                        else
                            sendMessage("Cannot register race.  Invalid AI allowed value.\n")
                        end
                    else
                        sendMessage("Cannot register race.  Invalid DNF timeout.\n")
                    end
                else
                    sendMessage("Cannot register race.  Invalid number of laps.\n")
                end
            else
                sendMessage("Cannot register race.  Invalid buy-in amount.\n")
            end
        else
            sendMessage("Cannot register race.  Track needs to have at least 2 waypoints.\n")
        end
    else
        sendMessage("Cannot register race.  Previous race registered.  Unregister first.\n")
    end
end

local function unregister()
    TriggerServerEvent("races:unregister")
end

local function startRace(delay)
    local dton = tonumber(delay)
    if nil == delay or ("integer" == math.type(dton) and dton >= 5) then
        if aiState ~= nil then
            for _, driver in pairs(aiState.drivers) do
                if nil == driver.ped and nil == driver.vehicle then
                    sendMessage("Cannot start race.  Some AI drivers not spawned.\n")
                    return
                end
            end
        end
        TriggerServerEvent("races:start", dton or defaultDelay)
    else
        sendMessage("Cannot start race.  Invalid delay.\n")
    end
end

local function leave()
    local player = PlayerPedId()
    if STATE_JOINING == raceState then
        raceState = STATE_IDLE
        TriggerServerEvent("races:leave", raceIndex, PedToNet(player), nil)
        removeRacerBlipGT()
        raceIndex = -1
        sendMessage("Left race.\n")
    elseif STATE_RACING == raceState then
        if 1 == IsPedInAnyVehicle(player, false) then
            FreezeEntityPosition(GetVehiclePedIsIn(player, false), false)
        end
        RenderScriptCams(false, false, 0, true, true)
        DeleteCheckpoint(raceCheckpoint)
        finishRace(-1)
        removeRacerBlipGT()
        raceIndex = -1
        sendMessage("Left race.\n")
    else
        sendMessage("Cannot leave.  Not joined to any race.\n")
    end
end

local function rivals()
    if STATE_JOINING == raceState or STATE_RACING == raceState then
        TriggerServerEvent("races:rivals", raceIndex)
    else
        sendMessage("Cannot list rivals.  Not joined to any race.\n")
    end
end

local function respawn()
    if STATE_RACING == raceState then
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
        local passengers = {}
        local player = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(player, false)
        if vehicle ~= 0 then
            if GetPedInVehicleSeat(vehicle, -1) == player then
                for i = 0, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
                    local passenger = GetPedInVehicleSeat(vehicle, i)
                    if passenger ~= 0 then
                        passengers[#passengers + 1] = {ped = passenger, seat = i}
                    end
                end
                SetEntityAsMissionEntity(vehicle, true, true)
                DeleteVehicle(vehicle)
            end
        end
        if currentVehicleHash ~= nil then
            RequestModel(currentVehicleHash)
            while false == HasModelLoaded(currentVehicleHash) do
                Citizen.Wait(0)
            end
            vehicle = putPedInVehicle(player, currentVehicleHash, currentColorPri, currentColorSec, currentColorPearl, currentColorWheel, coord)
            SetEntityAsNoLongerNeeded(vehicle)
            for _, passenger in pairs(passengers) do
                SetPedIntoVehicle(passenger.ped, vehicle, passenger.seat)
            end
        else
            SetEntityCoords(player, coord.x, coord.y, coord.z, false, false, false, true)
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
    else
        msg = "No results to view.\n"
    end
    if true == chatOnly then
        notifyPlayer(msg)
    else
        sendMessage(msg)
    end
end

local function spawn(model)
    if raceState ~= STATE_RACING and raceState ~= STATE_JOINING then
        model = model or defaultModel
        if 1 == IsModelInCdimage(model) and 1 == IsModelAVehicle(model) then
            local vehicle = switchVehicle(PlayerPedId(), model, -1, -1, -1, -1)
            if vehicle ~= nil then
                SetEntityAsNoLongerNeeded(vehicle)
                sendMessage("'" .. GetLabelText(GetDisplayNameFromVehicleModel(model)) .. "' spawned.\n")
            else
                sendMessage("Cannot spawn vehicle.  Not driver of current vehicle.\n")
            end
        else
            sendMessage("Cannot spawn vehicle.  Invalid vehicle.\n")
        end
    else
        sendMessage("Cannot spawn vehicle.  Leave race first.\n")
    end
end

local function lvehicles(vclass)
    local vton = tonumber(vclass)
    if nil == vclass or ("integer" == math.type(vton) and vton >= 0 and vton <= 21) then
        vclass = vton
        local msg = "Available vehicles"
        if fail == vclass then
            msg = msg .. ": "
        else
            msg = msg .. " of class " .. getClassName(vclass) .. ": "
        end
        local vehicleFound = false
        for _, model in ipairs(allVehiclesList) do
            if fail == vclass or GetVehicleClassFromName(model) == vclass then
                msg = msg .. model .. ", "
                vehicleFound = true
            end
        end
        if false == vehicleFound then
            sendMessage("No vehicles in list.\n")
        else
            sendMessage(string.sub(msg, 1, -3) .. "\n")
        end
    else
        sendMessage("Cannot list vehicles.  Invalid vehicle class.\n")
    end
end

local function setSpeedo(unit)
    if unit ~= nil then
        if "imperial" == unit then
            unitom = "imperial"
            sendMessage("Unit of measurement changed to Imperial.\n")
        elseif "metric" == unit then
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

local function showPanel(panel)
    panelShown = true
    if nil == panel then
        SetNuiFocus(true, true)
        TriggerServerEvent("races:trackNames", false, nil)
        TriggerServerEvent("races:trackNames", true, nil)
        SendNUIMessage({
            panel = "main",
            defaultModel = defaultModel,
            allVehicles = allVehiclesHTML
        })
    elseif "track" == panel then
        SetNuiFocus(true, true)
        TriggerServerEvent("races:trackNames", false, nil)
        TriggerServerEvent("races:trackNames", true, nil)
        SendNUIMessage({
            panel = "track"
        })
    elseif "ai" == panel then
        SetNuiFocus(true, true)
        TriggerServerEvent("races:aiGrpNames", false, nil)
        TriggerServerEvent("races:aiGrpNames", true, nil)
        SendNUIMessage({
            panel = "ai",
            defaultModel = defaultModel,
            allVehicles = allVehiclesHTML
        })
    elseif "list" == panel then
        SetNuiFocus(true, true)
        updateVehicleList()
        TriggerServerEvent("races:listNames", false, nil)
        TriggerServerEvent("races:listNames", true, nil)
        SendNUIMessage({
            panel = "list",
            allVehicles = allVehiclesHTML
        })
    elseif "register" == panel then
        SetNuiFocus(true, true)
        TriggerServerEvent("races:trackNames", false, nil)
        TriggerServerEvent("races:trackNames", true, nil)
        SendNUIMessage({
            panel = "register",
            defaultBuyin = defaultBuyin,
            defaultLaps = defaultLaps,
            defaultTimeout = defaultTimeout,
            defaultAllowAI = defaultAllowAI,
            defaultDelay = defaultDelay,
            allVehicles = allVehiclesHTML
        })
    else
        notifyPlayer("Invalid panel.\n")
        panelShown = false
    end
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
    loadTrack(data.access, data.trackName)
    cb()
end)

RegisterNUICallback("save", function(data, cb)
    local trackName = data.trackName
    if "" == trackName then
        trackName = nil
    end
    saveTrack(data.access, trackName)
    cb()
end)

RegisterNUICallback("overwrite", function(data, cb)
    overwriteTrack(data.access, data.trackName)
    cb()
end)

RegisterNUICallback("delete", function(data, cb)
    deleteTrack(data.access, data.trackName)
    cb()
end)

RegisterNUICallback("list", function(data, cb)
    listTracks(data.access)
    cb()
end)

RegisterNUICallback("blt", function(data, cb)
    bestLapTimes(data.access, data.trackName)
    cb()
end)

RegisterNUICallback("add_ai", function(data, cb)
    local aiName = data.aiName
    if "" == aiName then
        aiName = nil
    end
    addAIDriver(aiName, GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
    cb()
end)

RegisterNUICallback("spawn_ai", function(data, cb)
    local aiName = data.aiName
    if "" == aiName then
        aiName = nil
    end
    local vehicle = data.vehicle
    if "" == vehicle then
        vehicle = nil
    end
    spawnAIDriver(aiName, vehicle)
    cb()
end)

RegisterNUICallback("delete_ai", function(data, cb)
    local aiName = data.aiName
    if "" == aiName then
        aiName = nil
    end
    deleteAIDriver(aiName)
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
    local allowAI = data.allowAI
    local rtype = data.rtype
    if "norm" == rtype then
        rtype = nil
    end
    local restrict = data.restrict
    if "" == restrict then
        restrict = nil
    end
    local vclass = data.vclass
    if "-2" == vclass then
        vclass = nil
    end
    local svehicle = data.svehicle
    if "" == svehicle then
        svehicle = nil
    end
    if nil == rtype then
        register(buyin, laps, timeout, allowAI, rtype, nil, nil)
    elseif "rest" == rtype then
        register(buyin, laps, timeout, allowAI, rtype, restrict, nil)
    elseif "class" == rtype then
        register(buyin, laps, timeout, allowAI, rtype, vclass, nil)
    elseif "rand" == rtype then
        register(buyin, laps, timeout, allowAI, rtype, vclass, svehicle)
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

RegisterNUICallback("show", function(data, cb)
    local panel = data.panel
    if "main" == panel then
        panel = nil
    end
    showPanel(panel)
    cb()
end)

RegisterNUICallback("close", function(_, cb)
    panelShown = false
    SetNuiFocus(false, false)
    cb()
end)

--[[
local function testSound(audioRef, audioName)
    PlaySoundFrontend(-1, audioName, audioRef, true)
end

local function testCheckpoint(cptype)
    local playerCoord = GetEntityCoords(PlayerPedId())
    local coord = {x = playerCoord.x, y = playerCoord.y, z = playerCoord.z, r = 5.0}
    local checkpoint = makeCheckpoint(tonumber(cptype), coord, coord, yellow, 127, 5)
end

local function setEngineHealth(num)
    local player = PlayerPedId()
    if 1 == IsPedInAnyVehicle(player, false) then
        SetVehicleEngineHealth(GetVehiclePedIsIn(player, false), tonumber(num))
    end
end

local function getEngineHealth()
    local player = PlayerPedId()
    if 1 == IsPedInAnyVehicle(player, false) then
        print(GetVehicleEngineHealth(GetVehiclePedIsIn(player, false)))
    end
end

local function giveWeapon()
    local player = PlayerPedId()
    --local weaponHash = "WEAPON_PISTOL"
    --local weaponHash = "WEAPON_REVOLVER"
    local weaponHash = "WEAPON_COMBATMG"
    GiveWeaponToPed(player, weaponHash, 0, false, false)
    SetPedInfiniteAmmo(player, true, weaponHash)
end

local function removeWeapons()
    RemoveAllPedWeapons(PlayerPedId(), false)
end

local function clearWantedLevel()
    ClearPlayerWantedLevel(PlayerId())
end

local function getNetId()
    print(PedToNet(PlayerPedId()))
end

local function vehInfo()
    local player = PlayerPedId()
    local vehicle = GetPlayersLastVehicle()
    print("on wheels: " .. tostring(IsVehicleOnAllWheels(vehicle)))
    print("driveable: " .. tostring(IsVehicleDriveable(vehicle, false)))
    print("upside down: " .. tostring(IsEntityUpsidedown(vehicle)))
    print("is a car: " .. tostring(IsThisModelACar(GetEntityModel(vehicle))))
    print("can be damaged: " .. tostring(GetEntityCanBeDamaged(vehicle)))
    print("vehicle health %: " .. GetVehicleHealthPercentage(vehicle))
    print("entity health: " .. GetEntityHealth(vehicle))
    print("vehicle name: " .. GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))))
end

local function printSource()
    print(GetPlayerServerId(PlayerId()))
end

local pedpassengers = {}

local function deletePeds()
    for _, passenger in pairs(pedpassengers) do
        DeletePed(passenger.ped)
    end
    pedpassengers = {}
end

local function putPedInSeat()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    for _, passenger in pairs(pedpassengers) do
        --SetPedIntoVehicle(passenger.ped, vehicle, passenger.seat)
        TaskWarpPedIntoVehicle(passenger.ped, vehicle, passenger.seat)
        print("seat:" .. passenger.seat)
    end
end

local function getPedInSeat()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if DoesEntityExist(ped) then
            pedpassengers[#pedpassengers + 1] = {ped = ped, seat = seat}
            print("seat:" .. seat)
        end
    end
    print(#pedpassengers)
end

local function createPedInSeat()
    print("createPedInSeat")
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    local pedModel = "a_m_y_skater_01"
    RequestModel(pedModel)
    while false == HasModelLoaded(pedModel) do
        Citizen.Wait(0)
    end
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
        if 1 == IsVehicleSeatFree(vehicle, seat) then
            CreatePedInsideVehicle(vehicle, PED_TYPE_CIVMALE, pedModel, seat, true, false)
            print("seat:" .. seat)
            break
        end
    end
    SetModelAsNoLongerNeeded(pedModel)
end

local vehicle0
local vehicle1
local humanPed

local function getVeh0()
    vehicle0 = GetVehiclePedIsIn(PlayerPedId(), true)
    print("get vehicle 0")
end

local function getPedInVeh0()
    humanPed = GetPedInVehicleSeat(vehicle0, -1)
    print("get ped in vehicle 0")
end

local function getVeh1()
    vehicle1 = GetVehiclePedIsIn(PlayerPedId(), true)
    print("get vehicle 1")
end

local function putPedInVeh1()
    SetPedIntoVehicle(humanPed, vehicle1, -1)
    --TaskWarpPedIntoVehicle(humanPed, vehicle1, -1)
    print("put ped in vehicle 1")
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
            sound.name ~= "ZOOM" and
            sound.name ~= "Microphone" and
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
AddEventHandler("vehicles", function(list)
    local unknown = {}
    local classes = {}
    local maxName = nil
    local maxLen = 0
    local minName = nil
    local minLen = 0
    for _, vehicle in ipairs(list) do
        if IsModelInCdimage(vehicle) ~= 1 or IsModelAVehicle(vehicle) ~= 1 then
            unknown[#unknown + 1] = vehicle
        else
            print(vehicle .. ":" .. GetVehicleModelNumberOfSeats(vehicle))
            local class = GetVehicleClassFromName(vehicle)
            classes[class] = nil == classes[class] and 1 or classes[class] + 1
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
    local classNum = {}
    for class in pairs(classes) do
        classNum[#classNum + 1] = class
    end
    table.sort(classNum)
    for _, class in pairs(classNum) do
        print(class .. ":" .. classes[class])
    end
    TriggerServerEvent("unk", unknown)
    print(maxLen .. ":" .. maxName)
    print(minLen .. ":" .. minName)

    for vclass = 0, 21 do
        local vehicles = {}
        for _, vehicle in ipairs(list) do
            if 1 == IsModelInCdimage(vehicle) and 1 == IsModelAVehicle(vehicle) then
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
        msg = msg .. "/races edit - toggle editing track waypoints\n"
        msg = msg .. "/races clear - clear track waypoints\n"
        msg = msg .. "/races reverse - reverse order of track waypoints\n"
        msg = msg .. "\n"
        msg = msg .. "For the following '/races' commands, [access] = {pvt, pub} where 'pvt' operates on a private track and 'pub' operates on a public track\n"
        msg = msg .. "/races load [access] [name] - load private or public track saved as [name]\n"
        msg = msg .. "/races save [access] [name] - save new private or public track as [name]\n"
        msg = msg .. "/races overwrite [access] [name] - overwrite existing private or public track saved as [name]\n"
        msg = msg .. "/races delete [access] [name] - delete private or public track saved as [name]\n"
        msg = msg .. "/races list [access] - list saved private or public tracks\n"
        msg = msg .. "/races blt [access] [name] - list 10 best lap times of private or public track saved as [name]\n"
        msg = msg .. "\n"
        msg = msg .. "/races ai add [name] - add an AI driver named [name]\n"
        msg = msg .. "/races ai spawn [name] (vehicle) - spawn AI driver named [name] in (vehicle); (vehicle) defaults to 'adder'\n"
        msg = msg .. "/races ai delete [name] - delete an AI driver named [name]\n"
        msg = msg .. "/races ai deleteAll - delete all AI drivers\n"
        msg = msg .. "/races ai list - list AI driver names\n"
        msg = msg .. "\n"
        msg = msg .. "For the following '/races ai' commands, [access] = {pvt, pub} where 'pvt' operates on a private AI group and 'pub' operates on a public AI group\n"
        msg = msg .. "/races ai loadGrp [access] [name] - load private or public AI group saved as [name]\n"
        msg = msg .. "/races ai saveGrp [access] [name] - save new private or public AI group as [name]\n"
        msg = msg .. "/races ai overwriteGrp [access] [name] - overwrite existing private or public AI group saved as [name]\n"
        msg = msg .. "/races ai deleteGrp [access] [name] - delete private or public AI group saved as [name]\n"
        msg = msg .. "/races ai listGrps [access] - list saved private or public AI groups\n"
        msg = msg .. "\n"
        msg = msg .. "/races vl add [vehicle] - add [vehicle] to vehicle list\n"
        msg = msg .. "/races vl delete [vehicle] - delete [vehicle] from vehicle list\n"
        msg = msg .. "/races vl addClass [class] - add all vehicles of type [class] to vehicle list\n"
        msg = msg .. "/races vl deleteClass [class] - delete all vehicles of type [class] from vehicle list\n"
        msg = msg .. "/races vl addAll - add all vehicles to vehicle list\n"
        msg = msg .. "/races vl deleteAll - delete all vehicles from vehicle list\n"
        msg = msg .. "/races vl list - list all vehicles in vehicle list\n"
        msg = msg .. "\n"
        msg = msg .. "For the following '/races vl' commands, [access] = {pvt, pub} where 'pvt' operates on a private vehicle list and 'pub' operates on a public vehicle list\n"
        msg = msg .. "/races vl loadLst [access] [name] - load private or public vehicle list saved as [name]\n"
        msg = msg .. "/races vl saveLst [access] [name] - save new private or public vehicle list as [name]\n"
        msg = msg .. "/races vl overwriteLst [access] [name] - overwrite existing private or public vehicle list saved as [name]\n"
        msg = msg .. "/races vl deleteLst [access] [name] - delete private or public vehicle list saved as [name]\n"
        msg = msg .. "/races vl listLsts [access] - list saved private or public vehicle lists\n"
        msg = msg .. "\n"
        msg = msg .. "For the following '/races register' commands, (buy-in) defaults to 500, (laps) defaults to 1 lap, (DNF timeout) defaults to 120 seconds and (allow AI) = {yes, no} defaults to no\n"
        msg = msg .. "/races register (buy-in) (laps) (DNF timeout) (allow AI) - register your race with no vehicle restrictions\n"
        msg = msg .. "/races register (buy-in) (laps) (DNF timeout) (allow AI) rest [vehicle] - register your race restricted to [vehicle]\n"
        msg = msg .. "/races register (buy-in) (laps) (DNF timeout) (allow AI) class [class] - register your race restricted to vehicles of type [class]; if [class] is '-1' then use custom vehicle list\n"
        msg = msg .. "/races register (buy-in) (laps) (DNF timeout) (allow AI) rand (class) (vehicle) - register your race changing vehicles randomly every lap; (class) defaults to any; (vehicle) defaults to any\n"
        msg = msg .. "\n"
        msg = msg .. "/races unregister - unregister your race\n"
        msg = msg .. "/races start (delay) - start your registered race; (delay) defaults to 30 seconds\n"
        msg = msg .. "\n"
        msg = msg .. "/races leave - leave a race that you joined\n"
        msg = msg .. "/races rivals - list competitors in a race that you joined\n"
        msg = msg .. "/races respawn - respawn at last waypoint\n"
        msg = msg .. "/races results - view latest race results\n"
        msg = msg .. "/races spawn (vehicle) - spawn a vehicle; (vehicle) defaults to 'adder'\n"
        msg = msg .. "/races lvehicles (class) - list available vehicles of type (class); otherwise list all available vehicles if (class) is not specified\n"
        msg = msg .. "/races speedo (unit) - change unit of speed measurement to (unit) = {imperial, metric}; otherwise toggle display of speedometer if (unit) is not specified\n"
        msg = msg .. "/races funds - view available funds\n"
        msg = msg .. "/races panel (panel) - display (panel) = {track, ai, list, register} panel; otherwise display main panel if (panel) is not specified\n"
        notifyPlayer(msg)
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
        if "add" == args[2] then
            addAIDriver(args[3], GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
        elseif "spawn" == args[2] then
            spawnAIDriver(args[3], args[4])
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
        showPanel(args[2])
--[[
    elseif "test" == args[1] then
        if "0" == args[2] then
            TriggerEvent("races:finish", GetPlayerServerId(PlayerId()), "John Doe", (5 * 60 + 24) * 1000, (1 * 60 + 32) * 1000, "Duck")
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
        elseif "8" == args[2] then
            giveWeapon()
        elseif "9" == args[2] then
            removeWeapons()
        elseif "a" == args[2] then
            clearWantedLevel()
        elseif "b" == args[2] then
            getNetId()
        elseif "c" == args[2] then
            vehInfo()
        elseif "d" == args[2] then
            printSource()
        elseif "e" == args[2] then
            TriggerEvent("vehicles", allVehiclesList)
        elseif "dp" == args[2] then
            deletePeds()
        elseif "pp" == args[2] then
            putPedInSeat()
        elseif "gp" == args[2] then
            getPedInSeat()
        elseif "cp" == args[2] then
            createPedInSeat()
        elseif "gv0" == args[2] then
            getVeh0()
        elseif "gpiv0" == args[2] then
            getPedInVeh0()
        elseif "gv1" == args[2] then
            getVeh1()
        elseif "ppiv1" == args[2] then
            putPedInVeh1()
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
        end
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
AddEventHandler("races:load", function(isPublic, trackName, waypointCoords)
    if isPublic ~= nil and trackName ~= nil and waypointCoords ~= nil then
        if STATE_IDLE == raceState then
            isPublicTrack = isPublic
            savedTrackName = trackName
            loadWaypointBlips(waypointCoords)
            sendMessage("Loaded " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
        elseif STATE_EDITING == raceState then
            isPublicTrack = isPublic
            savedTrackName = trackName
            highlightedIndex = 0
            selectedIndex0 = 0
            selectedIndex1 = 0
            deleteWaypointCheckpoints()
            loadWaypointBlips(waypointCoords)
            setStartToFinishCheckpoints()
            sendMessage("Loaded " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
        else
            notifyPlayer("Ignoring load event.  Currently joined to race.\n")
        end
    else
        notifyPlayer("Ignoring load event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:save")
AddEventHandler("races:save", function(isPublic, trackName)
    if isPublic ~= nil and trackName ~= nil then
        isPublicTrack = isPublic
        savedTrackName = trackName
        sendMessage("Saved " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
    else
        notifyPlayer("Ignoring save event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:overwrite")
AddEventHandler("races:overwrite", function(isPublic, trackName)
    if isPublic ~= nil and trackName ~= nil then
        isPublicTrack = isPublic
        savedTrackName = trackName
        sendMessage("Overwrote " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
    else
        notifyPlayer("Ignoring overwrite event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:blt")
AddEventHandler("races:blt", function(isPublic, trackName, bestLaps)
    if isPublic ~= nil and trackName ~= nil and bestLaps ~= nil then
        local msg = (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'"
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

RegisterNetEvent("races:loadGrp")
AddEventHandler("races:loadGrp", function(isPublic, name, group)
    if isPublic ~= nil and name ~= nil and group ~= nil then
        local loaded = true
        if true == deleteAllAIDrivers() then
            -- group[aiName] = {startCoord = {x, y, z}, heading, model}
            for aiName, driver in pairs(group) do
                if false == addAIDriver(aiName, vector3(driver.startCoord.x, driver.startCoord.y, driver.startCoord.z), driver.heading) or false == spawnAIDriver(aiName, driver.model) then
                    loaded = false
                    break
                end
            end
        else
            loaded = false
        end
        if true == loaded then
            sendMessage((true == isPublic and "Public" or "Private") .. " AI group '" .. name .. "' loaded.\n")
        else
            sendMessage("Could not load " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
        end
    else
        notifyPlayer("Ignoring load AI group event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:loadLst")
AddEventHandler("races:loadLst", function(isPublic, name, list)
    if isPublic ~= nil and name ~= nil and list ~= nil then
        vehicleList = list
        if true == panelShown then
            updateVehicleList()
        end
        sendMessage((true == isPublic and "Public" or "Private") .. " vehicle list '" .. name .. "' loaded.\n")
    else
        notifyPlayer("Ignoring load vehicle list event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(rIndex, coord, isPublic, trackName, owner, buyin, laps, timeout, allowAI, rdata)
    if rIndex ~= nil and coord ~= nil and isPublic ~= nil and owner ~= nil and buyin ~= nil and laps ~= nil and timeout ~= nil and allowAI ~= nil and rdata ~= nil then
        local blip = AddBlipForCoord(coord.x, coord.y, coord.z) -- registration blip
        SetBlipSprite(blip, registerSprite)
        SetBlipColour(blip, registerBlipColor)
        local msg = ("%s:%d buy-in:%d lap(s):%d timeout"):format(owner, buyin, laps, timeout)
        if "yes" == allowAI then
            msg = msg .. ":AI allowed"
        end
        if "rest" == rdata.rtype then
            msg = msg .. ":using '" .. rdata.restrict .. "' vehicle"
        elseif "class" == rdata.rtype then
            msg = msg .. ":using " .. getClassName(rdata.vclass) .. " class vehicles"
        elseif "rand" == rdata.rtype then
            msg = msg .. ":using random "
            if rdata.vclass ~= nil then
                msg = msg .. getClassName(rdata.vclass) .. " class vehicles"
            else
                msg = msg .. "vehicles"
            end
            if rdata.svehicle ~= nil then
                msg = msg .. ":start '" .. rdata.svehicle .. "'"
            end
        end
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(string.sub(msg, 1, 79)) -- blip name has limit of 79 characters
        EndTextCommandSetBlipName(blip)

        coord.r = defaultRadius
        local checkpoint = makeCheckpoint(plainCheckpoint, coord, coord, purple, 127, 0) -- registration checkpoint

        starts[rIndex] = {
            isPublic = isPublic,
            trackName = trackName,
            owner = owner,
            buyin = buyin,
            laps = laps,
            timeout = timeout,
            allowAI = allowAI,
            rtype = rdata.rtype,
            restrict = rdata.restrict,
            vclass = rdata.vclass,
            svehicle = rdata.svehicle,
            vehicleList = rdata.vehicleList,
            blip = blip,
            checkpoint = checkpoint
        }
    else
        notifyPlayer("Ignoring register event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:unregister")
AddEventHandler("races:unregister", function(rIndex)
    if rIndex ~= nil then
        if starts[rIndex] ~= nil then
            deleteRegistrationPoint(rIndex)
        end
        -- SCENARIO: rIndex = A, raceIndex = -1
        -- 1. register race 'A'
        -- 2. do not join any registered race -> raceIndex = -1
        -- 3. unregister race 'A' -> receive unregister event from race 'A' -> rIndex = A
        -- do not unregister player from race 'A' since player did not join race 'A'
        -- SCENARIO: rIndex = A, raceIndex = B
        -- 1. register race 'A'
        -- 2. join another race 'B' -> raceIndex = B
        -- 3. unregister race 'A' -> receive unregister event from race 'A' -> rIndex = A
        -- do not unregister player from race 'B'
        if rIndex == raceIndex then
            if STATE_JOINING == raceState then
                raceState = STATE_IDLE
                removeRacerBlipGT()
                raceIndex = -1
                notifyPlayer("Race canceled.\n")
            elseif STATE_RACING == raceState then
                raceState = STATE_IDLE
                DeleteCheckpoint(raceCheckpoint)
                restoreBlips()
                SetBlipRoute(waypoints[1].blip, true)
                SetBlipRouteColour(waypoints[1].blip, blipRouteColor)
                speedo = false
                removeRacerBlipGT()
                RenderScriptCams(false, false, 0, true, true)
                local player = PlayerPedId()
                if 1 == IsPedInAnyVehicle(player, false) then
                    FreezeEntityPosition(GetVehiclePedIsIn(player, false), false)
                end
                if originalVehicleHash ~= nil then -- in random vehicle race
                    SetEntityAsNoLongerNeeded(switchVehicle(player, originalVehicleHash, originalColorPri, originalColorSec, originalColorPearl, originalColorWheel))
                end
                raceIndex = -1
                notifyPlayer("Race canceled.\n")
            end
        end
        if aiState ~= nil then
            -- SCENARIO: rIndex = B, GetPlayerServerId(PlayerId()) = A
            -- 1. register race 'A' with AI -> GetPlayerServerId(PlayerId()) = A
            -- 2. join another race 'B' with AI
            -- 3. receive unregister event from race 'B' -> rIndex = B
            -- do not unregister AI for race 'A'
            if GetPlayerServerId(PlayerId()) == rIndex then
                for _, driver in pairs(aiState.drivers) do
                    if false == IsEntityDead(driver.ped) and "rand" == aiState.rtype then
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
    else
        notifyPlayer("Ignoring unregister event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:start")
AddEventHandler("races:start", function(rIndex, delay)
    if rIndex ~= nil and delay ~= nil then
        if delay >= 5 then
            local currentTime = GetGameTimer()
            -- SCENARIO: rIndex = A, raceIndex = -1
            -- 1. register race 'A'
            -- 2. do not join any registered race -> raceIndex = -1
            -- 3. start race 'A' -> receive start event from race 'A' -> rIndex = A
            -- do not start race 'A' for player since player did not join race 'A'
            -- SCENARIO: rIndex = A, raceIndex = B
            -- 1. register race 'A'
            -- 2. join another race 'B' -> raceIndex = B
            -- 3. start race 'A' -> receive start event from race 'A' -> rIndex = A
            -- do not start race 'B' for player since race 'B' was not started
            if rIndex == raceIndex then
                if STATE_JOINING == raceState then
                    raceStart = currentTime
                    raceDelay = delay
                    beginDNFTimeout = false
                    timeoutStart = -1
                    started = false
                    vehicleFrozen = false
                    currentVehicleHash = nil
                    currentColorPri = -1
                    currentColorSec = -1
                    currentColorPearl = -1
                    currentColorWheel = -1
                    currentVehicleName = "FEET"
                    position = -1
                    numWaypointsPassed = 0
                    currentLap = 1
                    bestLapTime = -1
                    bestLapVehicleName = currentVehicleName
                    countdown = 5
                    numRacers = -1
                    results = {}
                    speedo = true
                    startCoord = GetEntityCoords(PlayerPedId())
                    camTransStarted = false

                    if startVehicle ~= nil then
                        SetEntityAsNoLongerNeeded(switchVehicle(PlayerPedId(), startVehicle, -1, -1, -1, -1))
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
            end

            if aiState ~= nil then
                -- SCENARIO: rIndex = B, GetPlayerServerId(PlayerId() = A
                -- 1. register race 'A' with AI -> GetPlayerServerId(PlayerId() = A
                -- 2. join another race 'B' with AI
                -- 3. receive start event from race 'B' -> rIndex = B
                -- do not start race for AI's in race 'A'
                if GetPlayerServerId(PlayerId()) == rIndex then
                    aiState.raceStart = currentTime
                    aiState.raceDelay = delay
                    for _, driver in pairs(aiState.drivers) do
                        if aiState.svehicle ~= nil then
                            driver.vehicle = switchVehicle(driver.ped, aiState.svehicle, -1, -1, -1, -1)
                        end
                        driver.raceState = STATE_RACING
                    end
                end
            end
        else
            notifyPlayer("Ignoring start event.  Invalid delay.\n")
        end
    else
        notifyPlayer("Ignoring start event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:hide")
AddEventHandler("races:hide", function(rIndex)
    if rIndex ~= nil then
        if starts[rIndex] ~= nil then
            deleteRegistrationPoint(rIndex)
        else
            notifyPlayer("Ignoring hide event.  Race does not exist.\n")
        end
    else
        notifyPlayer("Ignoring hide event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:join")
AddEventHandler("races:join", function(rIndex, aiName, waypointCoords)
    if rIndex ~= nil and waypointCoords ~= nil then
        local start = starts[rIndex]
        if start ~= nil then
            if nil == aiName then
                if STATE_IDLE == raceState then
                    raceState = STATE_JOINING
                    raceIndex = rIndex
                    numLaps = start.laps
                    DNFTimeout = start.timeout * 1000
                    restrictedHash = nil
                    restrictedClass = start.vclass
                    customClassVehicleList = {}
                    randomVehicleList = {}
                    startVehicle = start.svehicle
                    loadWaypointBlips(waypointCoords)
                    local msg = "Joined race registered by '" .. start.owner .. "' using "
                    if nil == start.trackName then
                        msg = msg .. "unsaved track"
                    else
                        msg = msg .. (true == start.isPublic and "publicly" or "privately") .. " saved track '" .. start.trackName .. "'"
                    end
                    msg = msg .. (" : %d buy-in : %d lap(s) : %d timeout"):format(start.buyin, start.laps, start.timeout)
                    if "yes" == start.allowAI then
                        msg = msg .. " : AI allowed"
                    end
                    if "rest" == start.rtype then
                        msg = msg .. " : using '" .. start.restrict .. "' vehicle"
                        restrictedHash = GetHashKey(start.restrict)
                    elseif "class" == start.rtype then
                        msg = msg .. " : using " .. getClassName(restrictedClass) .. " class vehicles"
                        customClassVehicleList = start.vehicleList
                    elseif "rand" == start.rtype then
                        msg = msg .. " : using random "
                        if restrictedClass ~= nil then
                            msg = msg .. getClassName(restrictedClass) .. " class vehicles"
                        else
                            msg = msg .. "vehicles"
                        end
                        if startVehicle ~= nil then
                            msg = msg .. " : start '" .. startVehicle .. "'"
                        end
                        randomVehicleList = start.vehicleList
                    end
                    msg = msg .. "\n"
                    notifyPlayer(msg)
                elseif STATE_EDITING == raceState then
                    notifyPlayer("Ignoring join event.  Currently editing.\n")
                else
                    notifyPlayer("Ignoring join event.  Already joined to a race.\n")
                end
            elseif aiState ~= nil then
                local driver = aiState.drivers[aiName]
                if driver ~= nil then
                    if nil == aiState.waypointCoords then
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
                    driver.currentWP = true == aiState.startIsFinish and 0 or 1
                    if "rand" == aiState.rtype then
                        aiState.randomVehicleList = aiState.vehicleList
                    end
                    notifyPlayer("AI driver '" .. aiName .. "' joined race.\n")
                else
                    notifyPlayer("Ignoring join event.  AI driver '" .. aiName .. "' not found.\n")
                end
            else
                notifyPlayer("Ignoring join event.  No AI drivers added.\n")
            end
        else
            notifyPlayer("Ignoring join event.  Race does not exist.\n")
        end
    else
        notifyPlayer("Ignoring join event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:finish")
AddEventHandler("races:finish", function(rIndex, playerName, raceFinishTime, raceBestLapTime, raceVehicleName)
    if rIndex ~= nil and playerName ~= nil and raceFinishTime ~= nil and raceBestLapTime ~= nil and raceVehicleName ~= nil then
        local currentTime = GetGameTimer()
        -- SCENARIO: rIndex = A, raceIndex = -1
        -- 1. finish race 'A' -> raceIndex = A
        -- 2. receive results event from race 'A' -> raceIndex = -1
        -- 3. receive finish events from race 'A' -> rIndex = A
        -- do not notify player/begin DNF timeout for race 'A' finish events
        -- SCENARIO: rIndex = A, raceIndex = B
        -- 1. finish race 'A' -> raceIndex = A
        -- 2. join another race 'B' -> raceIndex = B
        -- 3. receive finish events from race 'A' -> rIndex = A
        -- do not notify player/begin DNF timeout for race 'A' finish events
        if rIndex == raceIndex then
            if -1 == raceFinishTime then
                if -1 == raceBestLapTime then
                    notifyPlayer(playerName .. " did not finish.\n")
                else
                    local minutes, seconds = minutesSeconds(raceBestLapTime)
                    notifyPlayer(("%s did not finish and had a best lap time of %02d:%05.2f using %s.\n"):format(playerName, minutes, seconds, raceVehicleName))
                end
            else
                if false == beginDNFTimeout then
                    beginDNFTimeout = true
                    timeoutStart = currentTime
                end
                local fMinutes, fSeconds = minutesSeconds(raceFinishTime)
                local lMinutes, lSeconds = minutesSeconds(raceBestLapTime)
                notifyPlayer(("%s finished in %02d:%05.2f and had a best lap time of %02d:%05.2f using %s.\n"):format(playerName, fMinutes, fSeconds, lMinutes, lSeconds, raceVehicleName))
            end
        end

        if raceFinishTime ~= -1 and aiState ~= nil and false == aiState.beginDNFTimeout then
            -- SCENARIO: rIndex = B, GetPlayerServerId(PlayerId()) = A
            -- 1. register race 'A' with AI -> GetPlayerServerId(PlayerId()) = A
            -- 2. join another race 'B' with AI
            -- 3. joined race 'B' starts
            -- 4. receive finish events from race 'B' -> rIndex = B
            -- do not begin AI DNF timeout for race 'A'
            if GetPlayerServerId(PlayerId()) == rIndex then
                aiState.beginDNFTimeout = true
                aiState.timeoutStart = currentTime
            end
        end
    else
        notifyPlayer("Ignoring finish event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:results")
AddEventHandler("races:results", function(rIndex, raceResults)
    if rIndex ~= nil and raceResults ~= nil then
        -- SCENARIO: rIndex = A, raceIndex = B
        -- 1. finish race 'A' -> raceIndex = A
        -- 2. join another race 'B' -> raceIndex = B
        -- 3. receive results event from race 'A' -> rIndex = A
        -- do not view results from race 'A'
        if rIndex == raceIndex then
            raceIndex = -1
            results = raceResults
            viewResults(true)
        end
    else
        notifyPlayer("Ignoring results event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:position")
AddEventHandler("races:position", function(rIndex, pos, numR)
    if rIndex ~= nil and pos ~= nil and numR ~= nil then
        -- SCENARIO: rIndex = A, raceIndex = -1
        -- 1. finish race 'A' -> raceIndex = A
        -- 2. receive results event -> raceIndex = -1
        -- 3. receive position events from race 'A' -> rIndex = A
        -- do not update position for race 'A' position events
        -- SCENARIO: rIndex = A, raceIndex = B
        -- 1. finish race 'A' -> raceIndex = A
        -- 2. join another race 'B' -> raceIndex = B
        -- 3. receive position events from race 'A' -> rIndex = A
        -- do not update position for race 'A' position events
        if rIndex == raceIndex then
            position = pos
            numRacers = numR
        end
    else
        notifyPlayer("Ignoring position event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:addRacer")
AddEventHandler("races:addRacer", function(netID, name)
    if netID ~= nil and name ~= nil then
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
    else
        notifyPlayer("Ignoring addRacer event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:deleteRacer")
AddEventHandler("races:deleteRacer", function(netID)
    if netID ~= nil then
        if racerBlipGT[netID] ~= nil then
            RemoveBlip(racerBlipGT[netID].blip)
            RemoveMpGamerTag(racerBlipGT[netID].gamerTag)
            racerBlipGT[netID] = nil
        end
    else
        notifyPlayer("Ignoring deleteRacer event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:allVehicles")
AddEventHandler("races:allVehicles", function(allVehicles)
    if allVehicles ~= nil then
        allVehiclesList = {}
        allVehiclesHTML = ""
        table.sort(allVehicles)
        for _, model in ipairs(allVehicles) do
            if 1 == IsModelInCdimage(model) and 1 == IsModelAVehicle(model) then
                allVehiclesList[#allVehiclesList + 1] = model
                allVehiclesHTML = allVehiclesHTML .. "<option value = \"" .. model .. "\">" .. model .. "</option>"
            end
        end
    else
        notifyPlayer("Ignoring allVehicles event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:trackNames")
AddEventHandler("races:trackNames", function(isPublic, trackNames)
    if isPublic ~= nil and trackNames ~= nil then
        if true == panelShown then
            table.sort(trackNames)
            local html = ""
            for _, trackName in ipairs(trackNames) do
                html = html .. "<option value = \"" .. trackName .. "\">" .. trackName .. "</option>"
            end
            SendNUIMessage({
                update = "trackNames",
                access = false == isPublic and "pvt" or "pub",
                trackNames = html
            })
        end
    else
        notifyPlayer("Ignoring trackNames event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:aiGrpNames")
AddEventHandler("races:aiGrpNames", function(isPublic, grpNames)
    if isPublic ~= nil and grpNames ~= nil then
        if true == panelShown then
            table.sort(grpNames)
            local html = ""
            for _, grpName in ipairs(grpNames) do
                html = html .. "<option value = \"" .. grpName .. "\">" .. grpName .. "</option>"
            end
            SendNUIMessage({
                update = "grpNames",
                access = false == isPublic and "pvt" or "pub",
                grpNames = html
            })
        end
    else
        notifyPlayer("Ignoring grpNames event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:listNames")
AddEventHandler("races:listNames", function(isPublic, listNames)
    if isPublic ~= nil and listNames ~= nil then
        if true == panelShown then
            table.sort(listNames)
            local html = ""
            for _, listName in ipairs(listNames) do
                html = html .. "<option value = \"" .. listName .. "\">" .. listName .. "</option>"
            end
            SendNUIMessage({
                update = "listNames",
                access = false == isPublic and "pvt" or "pub",
                listNames = html
            })
        end
    else
        notifyPlayer("Ignoring listNames event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:cash")
AddEventHandler("races:cash", function(cash)
    StatSetInt(`MP0_WALLET_BALANCE`, cash, true)
    SetMultiplayerWalletCash()
    Citizen.Wait(5000)
    RemoveMultiplayerWalletCash()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if STATE_RACING == raceState then
            local player = PlayerPedId()
            local distance = #(GetEntityCoords(player) - vector3(waypointCoord.x, waypointCoord.y, waypointCoord.z))
            TriggerServerEvent("races:report", raceIndex, PedToNet(player), numWaypointsPassed, distance)
        end

        if aiState ~= nil then
            for _, driver in pairs(aiState.drivers) do
                if STATE_RACING == driver.raceState then
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
        if STATE_EDITING == raceState then
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

            if 1 == IsWaypointActive() then
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
            elseif 1 == IsControlJustReleased(0, 215) then -- enter key or A button or cross button
                editWaypoints(playerCoord)
            elseif selectedIndex0 ~= 0 and 0 == selectedIndex1 then
                local selectedWaypoint0 = waypoints[selectedIndex0]
                if 1 == IsControlJustReleased(2, 216) then -- space key or X button or square button
                    DeleteCheckpoint(selectedWaypoint0.checkpoint)
                    RemoveBlip(selectedWaypoint0.blip)
                    table.remove(waypoints, selectedIndex0)

                    if highlightedIndex == selectedIndex0 then
                        highlightedIndex = 0
                    end
                    selectedIndex0 = 0

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
                elseif 1 == IsControlJustReleased(0, 187) and selectedWaypoint0.coord.r > minRadius then -- arrow down or DPAD DOWN
                    selectedWaypoint0.coord.r = selectedWaypoint0.coord.r - 0.5
                    DeleteCheckpoint(selectedWaypoint0.checkpoint)
                    local color = getCheckpointColor(selectedBlipColor)
                    local checkpointType = 38 == selectedWaypoint0.sprite and finishCheckpoint or midCheckpoint
                    selectedWaypoint0.checkpoint = makeCheckpoint(checkpointType, selectedWaypoint0.coord, selectedWaypoint0.coord, color, 127, selectedIndex0 - 1)
                    savedTrackName = nil
                elseif 1 == IsControlJustReleased(0, 188) and selectedWaypoint0.coord.r < maxRadius then -- arrow up or DPAD UP
                    selectedWaypoint0.coord.r = selectedWaypoint0.coord.r + 0.5
                    DeleteCheckpoint(selectedWaypoint0.checkpoint)
                    local color = getCheckpointColor(selectedBlipColor)
                    local checkpointType = 38 == selectedWaypoint0.sprite and finishCheckpoint or midCheckpoint
                    selectedWaypoint0.checkpoint = makeCheckpoint(checkpointType, selectedWaypoint0.coord, selectedWaypoint0.coord, color, 127, selectedIndex0 - 1)
                    savedTrackName = nil
                end
            end
        elseif STATE_RACING == raceState then
            local player = PlayerPedId()
            local currentTime = GetGameTimer()
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
                    if false == vehicleFrozen then
                        vehicleFrozen = true
                        FreezeEntityPosition(GetVehiclePedIsIn(player, false), true)
                    end
                elseif true == vehicleFrozen then
                    vehicleFrozen = false
                    FreezeEntityPosition(GetVehiclePedIsIn(player, true), false)
                end
            else
                local vehicle = nil
                if 1 == IsPedInAnyVehicle(player, false) then
                    vehicle = GetVehiclePedIsIn(player, false)
                    currentVehicleHash = GetEntityModel(vehicle)
                    currentColorPri, currentColorSec = GetVehicleColours(vehicle)
                    currentColorPearl, currentColorWheel = GetVehicleExtraColours(vehicle)
                    currentVehicleName = GetLabelText(GetDisplayNameFromVehicleModel(currentVehicleHash))
                else
                    currentVehicleName = "FEET"
                end

                if false == started then
                    started = true
                    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
                    bestLapVehicleName = currentVehicleName
                    lapTimeStart = currentTime
                    if vehicle ~= nil then
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
                    local milliseconds = timeoutStart + DNFTimeout - currentTime
                    if milliseconds > 0 then
                        minutes, seconds = minutesSeconds(milliseconds)
                        drawMsg(leftSide, topSide + 0.29, "DNF time", 0.7, 1)
                        drawMsg(rightSide, topSide + 0.29, ("%02d:%05.2f"):format(minutes, seconds), 0.7, 1)
                    else -- DNF
                        DeleteCheckpoint(raceCheckpoint)
                        finishRace(-1)
                    end
                end

                if STATE_RACING == raceState then
                    if #(GetEntityCoords(player) - vector3(waypointCoord.x, waypointCoord.y, waypointCoord.z)) < waypointCoord.r then
                        local waypointPassed = true
                        if restrictedHash ~= nil then
                            if nil == vehicle or currentVehicleHash ~= restrictedHash then
                                waypointPassed = false
                            end
                        elseif restrictedClass ~= nil then
                            if vehicle ~= nil then
                                if -1 == restrictedClass then
                                    if false == vehicleInList(vehicle, customClassVehicleList) then
                                        waypointPassed = false
                                    end
                                elseif GetVehicleClass(vehicle) ~= restrictedClass then
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
                                if -1 == bestLapTime or lapTime < bestLapTime then
                                    bestLapTime = lapTime
                                    bestLapVehicleName = currentVehicleName
                                end
                                if currentLap < numLaps then
                                    currentWaypoint = 1
                                    lapTimeStart = currentTime
                                    currentLap = currentLap + 1
                                    if #randomVehicleList > 0 then -- in random vehicle race
                                        SetEntityAsNoLongerNeeded(switchVehicle(player, randomVehicleList[math.random(#randomVehicleList)], -1, -1, -1, -1))
                                        PlaySoundFrontend(-1, "CHARACTER_SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                    end
                                else
                                    finishRace(elapsedTime)
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
            local player = PlayerPedId()
            local playerCoord = GetEntityCoords(player)
            local closestIndex = -1
            local minDist = defaultRadius
            for rIndex, start in pairs(starts) do
                local dist = #(playerCoord - GetBlipCoords(start.blip))
                if dist < minDist then
                    minDist = dist
                    closestIndex = rIndex
                end
            end
            if closestIndex ~= -1 then
                local start = starts[closestIndex]

                local msg = "Join race registered by '" .. start.owner .. "' using "
                if nil == start.trackName then
                    msg = msg .. "unsaved track"
                else
                    msg = msg .. (true == start.isPublic and "publicly" or "privately") .. " saved track '" .. start.trackName .. "'"
                end
                drawMsg(0.50, 0.50, msg, 0.7, 0)

                msg = ("%d buy-in : %d lap(s) : %d timeout"):format(start.buyin, start.laps, start.timeout)
                if "yes" == start.allowAI then
                    msg = msg .. " : AI allowed"
                end
                drawMsg(0.50, 0.54, msg, 0.7, 0)

                if start.rtype ~= nil then
                    if "rest" == start.rtype then
                        msg = "using '" .. start.restrict .. "' vehicle"
                    elseif "class" == start.rtype then
                        msg = "using " .. getClassName(start.vclass) .. " class vehicles"
                    elseif "rand" == start.rtype then
                        msg = "using random "
                        if start.vclass ~= nil then
                            msg = msg .. getClassName(start.vclass) .. " class vehicles"
                        else
                            msg = msg .. "vehicles"
                        end
                        if start.svehicle ~= nil then
                            msg = msg .. " : start '" .. start.svehicle .. "'"
                        end
                    end
                    drawMsg(0.50, 0.58, msg, 0.7, 0)
                end

                if 1 == IsControlJustReleased(0, 51) then -- E key or DPAD RIGHT
                    local joinRace = true
                    originalVehicleHash = nil
                    originalColorPri = -1
                    originalColorSec = -1
                    originalColorPearl = -1
                    originalColorWheel = -1
                    local vehicle = nil
                    if 1 == IsPedInAnyVehicle(player, false) then
                        vehicle = GetVehiclePedIsIn(player, false)
                    end
                    if "rest" == start.rtype then
                        if nil == vehicle or GetEntityModel(vehicle) ~= GetHashKey(start.restrict) then
                            joinRace = false
                            notifyPlayer("Cannot join race.  Player needs to be in '" .. start.restrict .. "' vehicle.\n")
                        end
                    elseif "class" == start.rtype then
                        if start.vclass ~= -1 then
                            if nil == vehicle or GetVehicleClass(vehicle) ~= start.vclass then
                                joinRace = false
                                notifyPlayer("Cannot join race.  Player needs to be in vehicle of " .. getClassName(start.vclass) .. " class.\n")
                            end
                        elseif 0 == #start.vehicleList then
                            joinRace = false
                            notifyPlayer("Cannot join race.  Vehicle list is empty.\n")
                        elseif nil == vehicle or false == vehicleInList(vehicle, start.vehicleList) then
                            joinRace = false
                            local list = ""
                            for _, model in pairs(start.vehicleList) do
                                list = list .. model .. ", "
                            end
                            notifyPlayer("Cannot join race.  Player needs to be in one of the following vehicles: " .. string.sub(list, 1, -3) .. "\n")
                        end
                    elseif "rand" == start.rtype then
                        if 0 == #start.vehicleList then
                            joinRace = false
                            notifyPlayer("Cannot join race.  Vehicle list is empty.\n")
                        elseif start.vclass ~= nil and nil == start.svehicle and (nil == vehicle or GetVehicleClass(vehicle) ~= start.vclass) then
                            joinRace = false
                            notifyPlayer("Cannot join race.  Player needs to be in vehicle of " .. getClassName(start.vclass) .. " class.\n")
                        elseif vehicle ~= nil then
                            originalVehicleHash = GetEntityModel(vehicle)
                            originalColorPri, originalColorSec = GetVehicleColours(vehicle)
                            originalColorPearl, originalColorWheel = GetVehicleExtraColours(vehicle)
                        end
                    end
                    if true == joinRace then
                        removeRacerBlipGT()
                        TriggerServerEvent("races:join", closestIndex, PedToNet(player), nil)
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if aiState ~= nil then
            local currentTime = GetGameTimer()
            for aiName, driver in pairs(aiState.drivers) do
                if STATE_RACING == driver.raceState then
                    local elapsedTime = currentTime - aiState.raceStart - aiState.raceDelay * 1000
                    if elapsedTime >= 0 then
                        if false == driver.started then
                            driver.started = true
                            driver.lapTimeStart = currentTime
                            driver.stuckStart = currentTime
                        elseif true == aiState.beginDNFTimeout and aiState.timeoutStart + aiState.DNFTimeout - currentTime <= 0 then
                            driver.raceState = STATE_IDLE
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
                                        TaskVehicleDriveToCoord(driver.ped, driver.vehicle, driver.destCoord.x, driver.destCoord.y, driver.destCoord.z, GetVehicleEstimatedMaxSpeed(driver.vehicle), 1.0, driver.model, 787004, driver.destCoord.r * 0.5, true)
                                    else
                                        if #(GetEntityCoords(driver.ped) - vector3(driver.destCoord.x, driver.destCoord.y, driver.destCoord.z)) < driver.destCoord.r then
                                            driver.numWaypointsPassed = driver.numWaypointsPassed + 1
                                            if driver.currentWP < #aiState.waypointCoords then
                                                driver.currentWP = driver.currentWP + 1
                                            else
                                                local lapTime = currentTime - driver.lapTimeStart
                                                if -1 == driver.bestLapTime or lapTime < driver.bestLapTime then
                                                    driver.bestLapTime = lapTime
                                                    driver.bestLapVehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(driver.vehicle)))
                                                end
                                                if driver.currentLap < aiState.numLaps then
                                                    driver.currentWP = 1
                                                    driver.lapTimeStart = currentTime
                                                    driver.currentLap = driver.currentLap + 1
                                                    if #aiState.randomVehicleList > 0 then -- in random vehicle race
                                                        driver.vehicle = switchVehicle(driver.ped, aiState.randomVehicleList[math.random(#aiState.randomVehicleList)], -1, -1, -1, -1)
                                                    end
                                                else
                                                    driver.raceState = STATE_IDLE
                                                    TriggerServerEvent("races:finish", GetPlayerServerId(PlayerId()), driver.netID, aiName, driver.numWaypointsPassed, elapsedTime, driver.bestLapTime, driver.bestLapVehicleName, nil)
                                                end
                                            end
                                            if STATE_RACING == driver.raceState then
                                                local curr = true == startIsFinish and driver.currentWP % #aiState.waypointCoords + 1 or driver.currentWP
                                                driver.destCoord = aiState.waypointCoords[curr]
                                                driver.destSet = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                elseif STATE_IDLE == driver.raceState then
                    if false == IsEntityDead(driver.ped) and "rand" == aiState.rtype then
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
                    aiState.drivers[aiName] = nil
                    aiState.numRacing = aiState.numRacing - 1
                    if 0 == aiState.numRacing then
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
            if "metric" == unitom then
                drawMsg(leftSide, topSide + 0.25, "Speed(kph)", 0.7, 1)
                drawMsg(rightSide, topSide + 0.25, ("%05.2f"):format(speed * 3.6), 0.7, 1)
            else
                drawMsg(leftSide, topSide + 0.25, "Speed(mph)", 0.7, 1)
                drawMsg(rightSide, topSide + 0.25, ("%05.2f"):format(speed * 2.2369363), 0.7, 1)
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
