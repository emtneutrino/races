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

local STATE_REGISTERING <const> = 0
local STATE_RACING <const> = 1

local raceDataFile <const> = "./resources/races/raceData.json"

local defaultFilename <const> = "random.txt" -- default random vehicle filename
local allVehicleFilename <const> = "vehicles.txt" -- all vehicle filename
local defaultRadius <const> = 5.0 -- default waypoint radius

local races = {} -- races[] = {state, waypointCoords[] = {x, y, z, r}, publicRace, savedRaceName, owner, buyin, laps, timeout, vehicle, filename, vclass, numRacing, players[] = {playerName, numWaypointsPassed, data, finished}, results[] = {source, playerName, finishTime, bestLapTime, vehicleName}}

local dist <const> = {60, 20, 10, 5, 3, 2}
local distValid = true

if #dist > 0 and dist[1] > 0 then
    local sum = dist[1]
    for i = 2, #dist do
        if dist[i] > 0 and dist[i - 1] >= dist[i] then
            sum = sum + dist[i]
        else
            distValid = false
            break
        end
    end
    distValid = distValid and 100 == sum
else
    distValid = false
end
if false == distValid then
    print("^1Prize distribution table is invalid.")
end

local function notifyPlayer(source, msg)
    TriggerClientEvent("chat:addMessage", source, {
        color = {255, 0, 0},
        multiline = true,
        args = {"[races:server]", msg}
    })
end

local function sendMessage(source, msg)
    TriggerClientEvent("races:message", source, msg)
end

local function getRace(raceName)
    local raceFile = "./resources/races/" .. raceName .. ".json"
    local file, errMsg, errCode = io.open(raceFile, "r")
    if nil == file then
        print("getRace: Error opening file '" .. raceFile .. "' for read : '" .. errMsg .. "' : " .. errCode)
        return nil
    end

    local race = json.decode(file:read("a"))
    file:close()

    if type(race) ~= "table" or type(race.waypointCoords) ~= "table" or type(race.bestLaps) ~= "table" then
        print("getRace: race or race.waypointCoords or race.bestLaps not a table.")
        return nil
    end

    local newWaypointCoords = {}
    for _, waypoint in ipairs(race.waypointCoords) do
        if type(waypoint) ~= "table" or type(waypoint.x) ~= "number" or type(waypoint.y) ~= "number" or type(waypoint.z) ~= "number" or type(waypoint.r) ~= "number" then
            print("getRace: waypoint not a table or waypoint.x or waypoint.y or waypoint.z or waypoint.r not a number.")
            return nil
        end
        newWaypointCoords[#newWaypointCoords + 1] = {x = waypoint.x, y = waypoint.y, z = waypoint.z, r = waypoint.r}
    end

    if #newWaypointCoords < 2 then
        print("getRace: number of waypoints is less than 2.")
        return nil
    end

    local newBestLaps = {}
    for _, bestLap in ipairs(race.bestLaps) do
        if type(bestLap) ~= "table" or type(bestLap.playerName) ~= "string" or type(bestLap.bestLapTime) ~= "number" or type(bestLap.vehicleName) ~= "string" then
            print("getRace: bestLap not a table or bestLap.playerName not a string or bestLap.bestLapTime not a number or bestLap.vehicleName not a string.")
            return nil
        end
        newBestLaps[#newBestLaps + 1] = {playerName = bestLap.playerName, bestLapTime = bestLap.bestLapTime, vehicleName = bestLap.vehicleName}
    end

    return {waypointCoords = newWaypointCoords, bestLaps = newBestLaps}
end

local function export(raceName, withBLT)
    if raceName ~= nil then
        local file, errMsg, errCode = io.open(raceDataFile, "r")
        if file ~= nil then
            local raceData = json.decode(file:read("a"))
            file:close()
            if raceData ~= nil then
                local publicRaces = raceData["PUBLIC"]
                if publicRaces ~= nil then
                    if publicRaces[raceName] ~= nil then
                        local raceFile = "./resources/races/" .. raceName .. ".json"
                        file = io.open(raceFile, "r")
                        if nil == file then
                            file, errMsg, errCode = io.open(raceFile, "w+")
                            if file ~= nil then
                                if false == withBLT then
                                    publicRaces[raceName].bestLaps = {}
                                end
                                file:write(json.encode(publicRaces[raceName]))
                                file:close()
                                print("Exported '" .. raceName .. "'.")
                            else
                                print("export: Error opening file '" .. raceFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
                            end
                        else
                            file:close()
                            print("export: '" .. raceFile .. "' exists. Remove or rename the existing file, then export again.")
                        end
                    else
                        print("export: No public race named '" .. raceName .. "'.")
                    end
                else
                    print("export: No public race data.")
                end
            else
                print("export: No race data.")
            end
        else
            print("export: Error opening file '" .. raceDataFile .. "' for read : '" .. errMsg .. "' : " .. errCode)
        end
    else
        print("export: Name required.")
    end
end

local function import(raceName, withBLT)
    if raceName ~= nil then
        local file, errMsg, errCode = io.open(raceDataFile, "r")
        if file ~= nil then
            local raceData = json.decode(file:read("a"))
            file:close()
            if raceData ~= nil then
                local publicRaces = raceData["PUBLIC"]
                if publicRaces ~= nil then
                    if nil == publicRaces[raceName] then
                        local race = getRace(raceName)
                        if race ~= nil then
                            file, errMsg, errCode = io.open(raceDataFile, "w+")
                            if file ~= nil then
                                if false == withBLT then
                                    race.bestLaps = {}
                                end
                                publicRaces[raceName] = race
                                raceData["PUBLIC"] = publicRaces
                                file:write(json.encode(raceData))
                                file:close()
                                print("Imported '" .. raceName .. "'.")
                            else
                                print("import: Error opening file '" .. raceDataFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
                            end
                        else
                            print("import: Could not import '" .. raceName .. "'.")
                        end
                    else
                        print("import: '" .. raceName .. "' already exists in the public races list.  Rename the file, then import with the new name.")
                    end
                else
                    print("import: No public race data.")
                end
            else
                print("import: No race data.")
            end
        else
            print("import: Error opening file '" .. raceDataFile .. "' for read : '" .. errMsg .. "' : " .. errCode)
        end
    else
        print("import: Name required.")
    end
end

local function updateRaceData()
    local file, errMsg, errCode = io.open(raceDataFile, "r")
    if file ~= nil then
        local raceData = json.decode(file:read("a"))
        file:close()
        if raceData ~= nil then
            local update = false
            local newRaceData = {}
            for license, playerRaces in pairs(raceData) do
                local newPlayerRaces = {}
                for raceName, race in pairs(playerRaces) do
                    local waypointCoords = race.waypointCoords
                    local newWaypointCoords = {}
                    local bestLaps = race.bestLaps
                    for _, waypointCoord in ipairs(waypointCoords) do
                        if nil == waypointCoord.r then
                            update = true
                            newWaypointCoords[#newWaypointCoords + 1] = {x = waypointCoord.x, y = waypointCoord.y, z = waypointCoord.z, r = defaultRadius}
                        end
                    end
                    if true == update then
                        newPlayerRaces[raceName] = {waypointCoords = newWaypointCoords, bestLaps = bestLaps}
                    end
                end
                if true == update then
                    newRaceData[license] = newPlayerRaces
                end
            end
            if true == update then
                local raceFile = "./resources/races/raceData_updated.json"
                file, errMsg, errCode = io.open(raceFile, "w+")
                if file ~= nil then
                    file:write(json.encode(newRaceData))
                    file:close()
                    print("updateRaceData: raceData.json updated to new format in '" .. raceFile .. "'.")
                else
                    print("updateRaceData: Error opening file '" .. raceFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
                end
            else
                print("updateRaceData: raceData.json not updated.")
            end
        else
            print("updateRaceData: No race data.")
        end
    else
        print("updateRaceData: Error opening file '" .. raceDataFile .. "' for read : '" .. errMsg .. "' : " .. errCode)
    end
end

local function updateRace(raceName)
    if nil == raceName then
        print("updateRace: Name required.")
        return
    end

    local update = false
    local raceFile = "./resources/races/" .. raceName .. ".json"
    local file, errMsg, errCode = io.open(raceFile, "r")
    if nil == file then
        print("updateRace: Error opening file '" .. raceFile .. "' for read : '" .. errMsg .. "' : " .. errCode)
        return
    end

    local race = json.decode(file:read("a"))
    file:close()

    if type(race) ~= "table" or type(race.waypointCoords) ~= "table" or type(race.bestLaps) ~= "table" then
        print("updateRace: race or race.waypointCoords or race.bestLaps not a table.")
        return
    end

    local newWaypointCoords = {}
    for _, waypoint in ipairs(race.waypointCoords) do
        if type(waypoint) ~= "table" or type(waypoint.x) ~= "number" or type(waypoint.y) ~= "number" or type(waypoint.z) ~= "number" then
            print("updateRace: waypoint not a table or waypoint.x or waypoint.y or waypoint.z not a number.")
            return
        end
        if nil == waypoint.r then
            update = true
            newWaypointCoords[#newWaypointCoords + 1] = {x = waypoint.x, y = waypoint.y, z = waypoint.z, r = defaultRadius}
        elseif type(waypoint.r) == "number" then
            newWaypointCoords[#newWaypointCoords + 1] = {x = waypoint.x, y = waypoint.y, z = waypoint.z, r = waypoint.r}
        else
            print("updateRace: waypoint.r not a number.")
            return
        end
    end

    if #newWaypointCoords < 2 then
        print("updateRace: number of waypoints is less than 2.")
        return
    end

    local newBestLaps = {}
    for _, bestLap in ipairs(race.bestLaps) do
        if type(bestLap) ~= "table" or type(bestLap.playerName) ~= "string" or type(bestLap.bestLapTime) ~= "number" or type(bestLap.vehicleName) ~= "string" then
            print("updateRace: bestLap not a table or bestLap.playerName not a string or bestLap.bestLapTime not a number or bestLap.vehicleName not a string.")
            return
        end
        newBestLaps[#newBestLaps + 1] = {playerName = bestLap.playerName, bestLapTime = bestLap.bestLapTime, vehicleName = bestLap.vehicleName}
    end

    if true == update then
        raceFile = "./resources/races/" .. raceName .. "_updated.json"
        file, errMsg, errCode = io.open(raceFile, "w+")
        if file ~= nil then
            file:write(json.encode({waypointCoords = newWaypointCoords, bestLaps = newBestLaps}))
            file:close()
            print("updateRace: '" .. raceName .. ".json' updated to new format in '" .. raceFile .. "'.")
        else
            print("updateRace: Error opening file '" .. raceFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
        end
    else
        print("updateRace: '" .. raceName .. ".json' not updated.")
    end
end

local function loadPlayerData(public, source)
    local license = true == public and "PUBLIC" or GetPlayerIdentifier(source, 0)

    local playerRaces = nil

    if license ~= nil then
        if license ~= "PUBLIC" then
            license = string.sub(license, 9)
        end

        local raceData = nil

        local file, errMsg, errCode = io.open(raceDataFile, "r")
        if file ~= nil then
            raceData = json.decode(file:read("a"))
            file:close()
        else
            notifyPlayer(source, "loadPlayerData: Error opening file '" .. raceDataFile .. "' for read : '" .. errMsg .. "' : " .. errCode .. "\n")
            return nil
        end

        if nil == raceData then
            notifyPlayer(source, "loadPlayerData: No race data.\n")
            return nil
        end

        playerRaces = raceData[license]

        if nil == playerRaces then
            playerRaces = {}
        end
    else
        notifyPlayer(source, "loadPlayerData: Could not get license.\n")
        return nil
    end

    return playerRaces
end

local function savePlayerData(public, source, data)
    local license = true == public and "PUBLIC" or GetPlayerIdentifier(source, 0)

    if license ~= nil then
        if license ~= "PUBLIC" then
            license = string.sub(license, 9)
        end

        local raceData = nil

        local file, errMsg, errCode = io.open(raceDataFile, "r")
        if file ~= nil then
            raceData = json.decode(file:read("a"))
            file:close()
        else
            notifyPlayer(source, "savePlayerData: Error opening file '" .. raceDataFile .. "' for read : '" .. errMsg .. "' : " .. errCode .. "\n")
            return false
        end

        if nil == raceData then
            notifyPlayer(source, "savePlayerData: No race data.\n")
            return false
        end

        raceData[license] = data

        file, errMsg, errCode = io.open(raceDataFile, "w+")
        if file ~= nil then
            file:write(json.encode(raceData))
            file:close()
        else
            notifyPlayer(source, "savePlayerData: Error opening file '" .. raceDataFile .. "' for write : '" .. errMsg .. "' : " .. errCode .. "\n")
            return false
        end
    else
        notifyPlayer(source, "savePlayerData: Could not get license.\n")
        return false
    end

    return true
end

local function loadVehicleFile(source, vehicleFile)
    local vehicles = {}
    local file, errMsg, errCode = io.open("./resources/races/" .. vehicleFile, "r")
    if nil == file then
        notifyPlayer(source, "Error opening file '" .. vehicleFile .. "' for read : '" .. errMsg .. "' : " .. errCode)
    else
        for vehicle in file:lines() do
            if string.len(vehicle) > 0 then
                vehicles[#vehicles + 1] = vehicle
            end
        end
    end
    return vehicles
end

local function getClass(vclass)
    if 0 == vclass then
        return "'Compacts'(" .. vclass .. ")"
    elseif 1 == vclass then
        return "'Sedans'(" .. vclass .. ")"
    elseif 2 == vclass then
        return "'SUVs'(" .. vclass .. ")"
    elseif 3 == vclass then
        return "'Coupes'(" .. vclass .. ")"
    elseif 4 == vclass then
        return "'Muscle'(" .. vclass .. ")"
    elseif 5 == vclass then
        return "'Sports Classics'(" .. vclass .. ")"
    elseif 6 == vclass then
        return "'Sports'(" .. vclass .. ")"
    elseif 7 == vclass then
        return "'Super'(" .. vclass .. ")"
    elseif 8 == vclass then
        return "'Motorcycles'(" .. vclass .. ")"
    elseif 9 == vclass then
        return "'Off-road'(" .. vclass .. ")"
    elseif 10 == vclass then
        return "'Industrial'(" .. vclass .. ")"
    elseif 11 == vclass then
        return "'Utility'(" .. vclass .. ")"
    elseif 12 == vclass then
        return "'Vans'(" .. vclass .. ")"
    elseif 13 == vclass then
        return "'Cycles'(" .. vclass .. ")"
    elseif 14 == vclass then
        return "'Boats'(" .. vclass .. ")"
    elseif 15 == vclass then
        return "'Helicopters'(" .. vclass .. ")"
    elseif 16 == vclass then
        return "'Planes'(" .. vclass .. ")"
    elseif 17 == vclass then
        return "'Service'(" .. vclass .. ")"
    elseif 18 == vclass then
        return "'Emergency'(" .. vclass .. ")"
    elseif 19 == vclass then
        return "'Military'(" .. vclass .. ")"
    elseif 20 == vclass then
        return "'Commercial'(" .. vclass .. ")"
    else
        return "'Trains'(" .. vclass .. ")"
    end
end

local function updateBestLapTimes(index)
    local playerRaces = loadPlayerData(races[index].publicRace, index)
    if playerRaces ~= nil then
        if playerRaces[races[index].savedRaceName] ~= nil then -- saved race still exists - not deleted in middle of race
            local bestLaps = playerRaces[races[index].savedRaceName].bestLaps
            for _, result in pairs(races[index].results) do
                if result.bestLapTime ~= -1 then
                    bestLaps[#bestLaps + 1] = {playerName = result.playerName, bestLapTime = result.bestLapTime, vehicleName = result.vehicleName}
                end
            end
            table.sort(bestLaps, function(p0, p1)
                return p0.bestLapTime < p1.bestLapTime
            end)
            for i = 11, #bestLaps do
                bestLaps[i] = nil
            end
            playerRaces[races[index].savedRaceName].bestLaps = bestLaps
            if false == savePlayerData(races[index].publicRace, index, playerRaces) then
                notifyPlayer(index, "Save error updating best lap times.\n")
            end
        else
            notifyPlayer(index, "Cannot save best lap times.  Race '" .. races[index].savedRaceName .. "' has been deleted.\n")
        end
    else
        notifyPlayer(index, "Load error updating best lap times.\n")
    end
end

local function round(f)
    return (f - math.floor(f) >= 0.5) and (math.floor(f) + 1) or math.floor(f)
end

RegisterCommand("races", function(_, args)
    if nil == args[1] then
        local msg = "Commands:\n"
        msg = msg .. "races - display list of available races commands\n"
        msg = msg .. "races export [name] - export public race saved as [name] without best lap times to file named '[name].json'\n"
        msg = msg .. "races import [name] - import race file named '[name].json' into public races without best lap times\n"
        msg = msg .. "races exportwblt [name] - export public race saved as [name] with best lap times to file named '[name].json'\n"
        msg = msg .. "races importwblt [name] - import race file named '[name].json' into public races with best lap times\n"
        msg = msg .. "races updateRaceData - update 'raceData.json' to new format\n"
        msg = msg .. "races updateRace [name] - update exported race '[name].json' to new format\n"
        print(msg)
    elseif "export" == args[1] then
        export(args[2], false)
    elseif "import" == args[1] then
        import(args[2], false)
    elseif "exportwblt" == args[1] then
        export(args[2], true)
    elseif "importwblt" == args[1] then
        import(args[2], true)
    elseif "updateRaceData" == args[1] then
        updateRaceData()
    elseif "updateRace" == args[1] then
        updateRace(args[2])
    else
        print("Unknown command.")
    end
end, true)

AddEventHandler("playerDropped", function()
    local source = source

    -- unregister race registered by dropped player that has not started
    if races[source] ~= nil and STATE_REGISTERING == races[source].state then
        for i in pairs(races[source].players) do
            Deposit(i, races[source].buyin)
            notifyPlayer(i, races[source].buyin .. " was deposited in your funds.\n")
        end
        races[source] = nil
        TriggerClientEvent("races:unregister", -1, source)
    end

    -- remove dropped player from the race they are joined to
    for i, race in pairs(races) do
        if race.players[source] ~= nil then
            if STATE_REGISTERING == race.state then
                race.players[source] = nil
                race.numRacing = race.numRacing - 1
            else
                TriggerEvent("races:finish", i, 0, -1, -1, "", source)
            end
            break
        end
    end
end)

--[[
RegisterNetEvent("sounds")
AddEventHandler("sounds", function()
    local source = source
    local filePath = "./resources/races/sounds/sounds.csv"
    local file, errMsg, errCode = io.open(filePath, "r")
    if file ~= nil then
        local sounds = {}
        for line in file:lines() do
            local i = string.find(line, ",")
            local name = string.sub(line, 1, i - 1)
            local ref = string.sub(line, i + 1, -1)
            sounds[#sounds + 1] = {name = name, ref = ref}
        end
        file:close()
        TriggerClientEvent("sounds", source, sounds)
    else
        print("Error opening file '" .. filePath .. "' for read : '" .. errMsg .. "' : " .. errCode)
    end
end)

RegisterNetEvent("vehicles")
AddEventHandler("vehicles", function()
    local source = source
    local filePath = "./resources/races/vehicles/vehicles.txt"
    local file, errMsg, errCode = io.open(filePath, "r")
    if file ~= nil then
        local vehicleList = {}
        for line in file:lines() do
            vehicleList[#vehicleList + 1] = line
        end
        file:close()
        TriggerClientEvent("vehicles", source, vehicleList)
    else
        print("Error opening file '" .. filePath .. "' for read : '" .. errMsg .. "' : " .. errCode)
    end
end)

RegisterNetEvent("unk")
AddEventHandler("unk", function(unknown)
    local filePath = "./resources/races/vehicles/unknown.txt"
    local file, errMsg, errCode = io.open(filePath, "w+")
    if file ~= nil then
        for _, vehicle in ipairs(unknown) do
            file:write(vehicle .. "\n")
        end
        file:close()
    else
        print("Error opening file '" .. filePath .. "' for write : '" .. errMsg .. "' : " .. errCode)
    end
end)

RegisterNetEvent("veh")
AddEventHandler("veh", function(vclass, vehicles)
    local filePath = ("./resources/races/vehicles/%02d.txt"):format(vclass)
    local file, errMsg, errCode = io.open(filePath, "w+")
    if file ~= nil then
        for _, vehicle in ipairs(vehicles) do
            file:write(vehicle .. "\n")
        end
        file:close()
    else
        print("Error opening file '" .. filePath .. "' for write : '" .. errMsg .. "' : " .. errCode)
    end
end)
--]]

RegisterNetEvent("races:init")
AddEventHandler("races:init", function()
    local source = source

    TriggerClientEvent("races:init", source, defaultFilename, defaultRadius)

    -- if funds < 5000, set funds to 5000
    if GetFunds(source) < 5000 then
        SetFunds(source, 5000)
    end

    -- register any races created before player joined
    for i, race in pairs(races) do
        if STATE_REGISTERING == race.state then
            TriggerClientEvent("races:register", source, i, race.waypointCoords[1], race.publicRace, race.savedRaceName, race.owner, race.buyin, race.laps, race.timeout, race.rtype, race.restrict, race.filename, race.vclass)
        end
    end
end)

RegisterNetEvent("races:load")
AddEventHandler("races:load", function(public, raceName)
    local source = source
    if public ~= nil and raceName ~= nil then
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            if playerRaces[raceName] ~= nil then
                TriggerClientEvent("races:load", source, public, raceName, playerRaces[raceName].waypointCoords)
            else
                sendMessage(source, "Cannot load.  '" .. raceName .. "' not found.\n")
            end
        else
            sendMessage(source, "Cannot load.  Error loading data.\n")
        end
    else
        sendMessage(source, "Ignoring load event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:save")
AddEventHandler("races:save", function(public, raceName, waypointCoords)
    local source = source
    if public ~= nil and raceName ~= nil and waypointCoords ~= nil then
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            if nil == playerRaces[raceName] then
                playerRaces[raceName] = {waypointCoords = waypointCoords, bestLaps = {}}
                if true == savePlayerData(public, source, playerRaces) then
                    TriggerClientEvent("races:save", source, public, raceName)
                else
                    sendMessage(source, "Error saving '" .. raceName .. "'.\n")
                end
            else
                if true == public then
                    sendMessage(source, ("Public race '%s' exists.  Use 'overwritePublic' command instead.\n"):format(raceName))
                else
                    sendMessage(source, ("Private race '%s' exists.  Use 'overwrite' command instead.\n"):format(raceName))
                end
            end
        else
            sendMessage(source, "Cannot save.  Error loading data.\n")
        end
    else
        sendMessage(source, "Ignoring save event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:overwrite")
AddEventHandler("races:overwrite", function(public, raceName, waypointCoords)
    local source = source
    if public ~= nil and raceName ~= nil and waypointCoords ~= nil then
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            if playerRaces[raceName] ~= nil then
                playerRaces[raceName] = {waypointCoords = waypointCoords, bestLaps = {}}
                if true == savePlayerData(public, source, playerRaces) then
                    TriggerClientEvent("races:overwrite", source, public, raceName)
                else
                    sendMessage(source, "Error overwriting '" .. raceName .. "'.\n")
                end
            else
                if true == public then
                    sendMessage(source, ("Public race '%s' does not exist.  Use 'savePublic' command instead.\n"):format(raceName))
                else
                    sendMessage(source, ("Private race '%s' does not exist.  Use 'save' command instead.\n"):format(raceName))
                end
            end
        else
            sendMessage(source, "Cannot overwrite.  Error loading data.\n")
        end
    else
        sendMessage(source, "Ignoring overwrite event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:delete")
AddEventHandler("races:delete", function(public, raceName)
    local source = source
    if public ~= nil and raceName ~= nil then
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            if playerRaces[raceName] ~= nil then
                playerRaces[raceName] = nil
                if true == savePlayerData(public, source, playerRaces) then
                    local msg = "Deleted "
                    msg = msg .. (true == public and "public" or "private")
                    msg = msg .. " race '" .. raceName .. "'.\n"
                    sendMessage(source, msg)
                else
                    sendMessage(source, "Error deleting '" .. raceName .. "'.\n")
                end
            else
                sendMessage(source, "Cannot delete.  '" .. raceName .. "' not found.\n")
            end
        else
            sendMessage(source, "Cannot delete.  Error loading data.\n")
        end
    else
        sendMessage(source, "Ignoring delete event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:blt")
AddEventHandler("races:blt", function(public, raceName)
    local source = source
    if public ~= nil and raceName ~= nil then
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            if playerRaces[raceName] ~= nil then
                TriggerClientEvent("races:blt", source, public, raceName, playerRaces[raceName].bestLaps)
            else
                sendMessage(source, "Cannot list best lap times.  '" .. raceName .. "' not found.\n")
            end
        else
            sendMessage(source, "Cannot list best lap times.  Error loading data.\n")
        end
    else
        sendMessage(source, "Ignoring best lap times event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:list")
AddEventHandler("races:list", function(public)
    local source = source
    if public ~= nil then
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            local names = {}
            for name in pairs(playerRaces) do
                names[#names + 1] = name
            end
            if #names > 0 then
                table.sort(names)
                local msg = "Saved "
                msg = msg .. (true == public and "public" or "private")
                msg = msg .. " races:\n"
                for _, name in ipairs(names) do
                    msg = msg .. name .. "\n"
                end
                sendMessage(source, msg)
            else
                sendMessage(source, "No saved races.\n")
            end
        else
            sendMessage(source, "Cannot list.  Error loading data.\n")
        end
    else
        sendMessage(source, "Ignoring list event.  Invalid parameters.\n")
   end
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(waypointCoords, publicRace, savedRaceName, buyin, laps, timeout, rtype, restrict, filename, vclass)
    local source = source
    if waypointCoords ~= nil and publicRace ~= nil and buyin ~= nil and laps ~= nil and timeout ~= nil then
        if buyin >= 0 then
            if laps > 0 then
                if timeout >= 0 then
                    if nil == races[source] then
                        local registerRace = true
                        local umsg = ""
                        if "rest" == rtype then
                            if nil == restrict then
                                registerRace = false
                                sendMessage("Cannot register.  Invalid restricted vehicle.\n")
                            else
                                umsg = " : using '" .. restrict .. "' vehicle"
                            end
                        elseif "class" == rtype then
                            if nil == vclass or vclass < 0 or vclass > 21 then
                                registerRace = false
                                sendMessage("Cannot register.  Invalid vehicle class.\n")
                            else
                                umsg = " : using " .. getClass(vclass) .. " vehicle class"
                            end
                        elseif "rand" == rtype then
                            buyin = 0
                            if nil == filename then
                                filename = defaultFilename
                            end
                            local file, errMsg, errCode = io.open("./resources/races/" .. filename, "r")
                            if nil == file then
                                sendMessage(source, "Cannot register.  Error opening file '" .. filename .. "' for read : '" .. errMsg .. "' : " .. errCode .. "\n")
                                registerRace = false
                            else
                                file:close()
                                if vclass ~= nil and (vclass < 0 or vclass > 21) then
                                    registerRace = false
                                    sendMessage("Cannot register.  Invalid vehicle class.\n")
                                else
                                    umsg = " : using random "
                                    if vclass ~= nil then
                                        umsg = umsg .. getClass(vclass) .. " vehicle class"
                                    else
                                        umsg = umsg .. "vehicles"
                                    end
                                end
                            end
                        elseif rtype ~= nil then
                            registerRace = false
                            sendMessage("Cannot register.  Unknown race type.\n")
                        end
                        if true == registerRace then
                            local owner = GetPlayerName(source)
                            local msg = "Registered "
                            if nil == savedRaceName then
                                msg = msg .. "unsaved race "
                            else
                                msg = msg .. (true == publicRace and "publicly" or "privately")
                                msg = msg .. " saved race '" .. savedRaceName .. "' "
                            end
                            msg = msg .. ("by %s : %d buy-in : %d lap(s)"):format(owner, buyin, laps)
                            msg = msg .. umsg .. ".\n"
                            if false == distValid then
                                msg = msg .. "Prize distribution table is invalid.\n"
                            end
                            sendMessage(source, msg)
                            races[source] = {
                                state = STATE_REGISTERING,
                                waypointCoords = waypointCoords,
                                publicRace = publicRace,
                                savedRaceName = savedRaceName,
                                owner = owner,
                                buyin = buyin,
                                laps = laps,
                                timeout = timeout,
                                rtype = rtype,
                                restrict = restrict,
                                filename = filename,
                                vclass = vclass,
                                numRacing = 0,
                                players = {},
                                results = {}
                            }
                            TriggerClientEvent("races:register", -1, source, waypointCoords[1], publicRace, savedRaceName, owner, buyin, laps, timeout, rtype, restrict, filename, vclass)
                        end
                    else
                        if STATE_RACING == races[source].state then
                            sendMessage(source, "Cannot register.  Previous race in progress.\n")
                        else
                            sendMessage(source, "Cannot register.  Previous race registered.  Unregister first.\n")
                        end
                    end
                else
                    sendMessage(source, "Invalid DNF timeout.\n")
                end
            else
                sendMessage(source, "Invalid number of laps.\n")
            end
        else
            sendMessage(source, "Invalid buy-in amount.\n")
        end
    else
        sendMessage(source, "Ignoring register event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:unregister")
AddEventHandler("races:unregister", function()
    local source = source
    if races[source] ~= nil then
        for i in pairs(races[source].players) do
            Deposit(i, races[source].buyin)
            notifyPlayer(i, races[source].buyin .. " was deposited in your funds.\n")
        end
        races[source] = nil
        TriggerClientEvent("races:unregister", -1, source)
        sendMessage(source, "Race unregistered.\n")
    else
        sendMessage(source, "Cannot unregister.  No race registered.\n")
    end
end)

RegisterNetEvent("races:start")
AddEventHandler("races:start", function(delay)
    local source = source
    if delay ~= nil then
        if races[source] ~= nil then
            if STATE_REGISTERING == races[source].state then
                if delay >= 0 then
                    if races[source].numRacing > 0 then
                        races[source].state = STATE_RACING
                        for i in pairs(races[source].players) do
                            TriggerClientEvent("races:start", i, delay)
                        end
                        TriggerClientEvent("races:hide", -1, source) -- hide race so no one else can join
                        sendMessage(source, "Race started.\n")
                    else
                        sendMessage(source, "Cannot start.  No players have joined race.\n")
                    end
                else
                    sendMessage(source, "Cannot start.  Invalid delay.\n")
                end
            else
                sendMessage(source, "Cannot start.  Race in progress.\n")
            end
        else
            sendMessage(source, "Cannot start.  Race does not exist.\n")
        end
    else
        sendMessage(source, "Ignoring start event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:leave")
AddEventHandler("races:leave", function(index)
    local source = source
    if index ~= nil then
        if races[index] ~= nil then
            if STATE_REGISTERING == races[index].state then
                if races[index].players[source] ~= nil then
                    races[index].players[source] = nil
                    races[index].numRacing = races[index].numRacing - 1
                    if races[index].rtype ~= "rand" then
                        Deposit(source, races[index].buyin)
                        sendMessage(source, races[index].buyin .. " was deposited in your funds.\n")
                    end
                else
                    sendMessage(source, "Cannot leave.  Not a member of this race.\n")
                end
            else
                sendMessage(source, "Cannot leave.  Race in progress.\n")
            end
        else
            sendMessage(source, "Cannot leave.  Race does not exist.\n")
        end
    else
        sendMessage(source, "Ignoring leave event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:rivals")
AddEventHandler("races:rivals", function(index)
    local source = source
    if index ~= nil then
        if races[index] ~= nil then
            if races[index].players[source] ~= nil then
                local names = {}
                for i, player in pairs(races[index].players) do
                    names[#names + 1] = player.playerName
                end
                table.sort(names)
                local msg = "Competitors:\n"
                for _, name in ipairs(names) do
                    msg = msg .. name .. "\n"
                end
                sendMessage(source, msg)
            else
                sendMessage(source, "Cannot list competitors.  Not a member of this race.\n")
            end
        else
            sendMessage(source, "Cannot list competitors.  Race does not exist.\n")
        end
    else
        sendMessage(source, "Ignoring rivals event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:lvehicles")
AddEventHandler("races:lvehicles", function(vclass)
    local source = source
    local vehicleList = loadVehicleFile(source, allVehicleFilename)
    if #vehicleList > 0 then
        TriggerClientEvent("races:lvehicles", source, vehicleList, vclass)
    else
        sendMessage(source, "Cannot list vehicles.  Vehicle list not loaded.\n")
    end
end)

RegisterNetEvent("races:funds")
AddEventHandler("races:funds", function()
    local source = source
    sendMessage(source, "Available funds: " .. GetFunds(source) .. "\n")
end)

RegisterNetEvent("races:join")
AddEventHandler("races:join", function(index)
    local source = source
    if index ~= nil then
        if races[index] ~= nil then
            if GetFunds(source) >= races[index].buyin then
                if STATE_REGISTERING == races[index].state then
                    races[index].numRacing = races[index].numRacing + 1
                    races[index].players[source] = {playerName = GetPlayerName(source), numWaypointsPassed = -1, data = -1, finished = false}
                    if "rand" == races[index].rtype then
                        local randVehicles = loadVehicleFile(source, races[index].filename)
                        if #randVehicles > 0 then
                            TriggerClientEvent("races:join", source, index, races[index].waypointCoords, randVehicles)
                        else
                            notifyPlayer(source, "Cannot join.  Random vehicle list not loaded.\n")
                        end
                    else
                        TriggerClientEvent("races:join", source, index, races[index].waypointCoords, nil)
                        Withdraw(source, races[index].buyin)
                        notifyPlayer(source, races[index].buyin .. " was withdrawn from your funds.\n")
                    end
                else
                    notifyPlayer(source, "Cannot join.  Race in progress.\n")
                end
            else
                notifyPlayer(source, "Cannot join.  Insufficient funds.\n")
            end
        else
            notifyPlayer(source, "Cannot join.  Race does not exist.\n")
        end
    else
        notifyPlayer(source, "Ignoring join event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:finish")
AddEventHandler("races:finish", function(index, numWaypointsPassed, finishTime, bestLapTime, vehicleName, playerSource)
    local source = playerSource ~=nil and playerSource or source
    if index ~= nil and numWaypointsPassed ~= nil and finishTime ~= nil and bestLapTime ~= nil and vehicleName ~= nil then
        if races[index] ~= nil then
            if STATE_RACING == races[index].state then
                if races[index].players[source] ~= nil then
                    races[index].players[source].numWaypointsPassed = numWaypointsPassed
                    races[index].players[source].data = finishTime
                    races[index].players[source].finished = true

                    local playerName = races[index].players[source].playerName

                    for i in pairs(races[index].players) do
                        TriggerClientEvent("races:finish", i, playerName, finishTime, bestLapTime, vehicleName)
                    end

                    races[index].results[#(races[index].results) + 1] = {source = source, playerName = playerName, finishTime = finishTime, bestLapTime = bestLapTime, vehicleName = vehicleName}

                    races[index].numRacing = races[index].numRacing - 1
                    if 0 == races[index].numRacing then
                        table.sort(races[index].results, function(p0, p1)
                            return
                                (p0.finishTime >= 0 and (-1 == p1.finishTime or p0.finishTime < p1.finishTime)) or
                                (-1 == p0.finishTime and -1 == p1.finishTime and (p0.bestLapTime >= 0 and (-1 == p1.bestLapTime or p0.bestLapTime < p1.bestLapTime)))
                        end)

                        local winningsRL = {}
                        for _, result in pairs(races[index].results) do
                            winningsRL[result.source] = races[index].buyin
                        end

                        if true == distValid and races[index].rtype ~= "rand" then
                            local numRacers = #(races[index].results)
                            local numFinished = 0
                            local totalPool = numRacers * races[index].buyin
                            local pool = totalPool
                            local winnings = {}

                            for i, result in ipairs(races[index].results) do
                                winnings[i] = {payout = races[index].buyin, source = result.source}
                                if result.finishTime ~= -1 then
                                    numFinished = numFinished + 1
                                end
                            end

                            if numFinished >= #dist then
                                for i = numFinished + 1, numRacers do
                                    winnings[i].payout = 0
                                end
                                local payout = round(dist[#dist] / 100 * totalPool / (numFinished - #dist + 1))
                                for i = #dist, numFinished do
                                    winnings[i].payout = payout
                                    pool = pool - payout
                                end
                                for i = 2, #dist - 1 do
                                    payout = round(dist[i] / 100 * totalPool)
                                    winnings[i].payout = payout
                                    pool = pool - payout
                                end
                                winnings[1].payout = pool
                            elseif numFinished > 0 then
                                for i = numFinished + 1, numRacers do
                                    winnings[i].payout = 0
                                end
                                local bonus = dist[numFinished + 1]
                                for i = numFinished + 2, #dist do
                                    bonus = bonus + dist[i]
                                end
                                bonus = bonus / numFinished
                                for i = 2, numFinished do
                                    local payout = round((dist[i] + bonus) / 100 * totalPool)
                                    winnings[i].payout = payout
                                    pool = pool - payout
                                end
                                winnings[1].payout = pool
                            end

                            for _, winning in pairs(winnings) do
                                winningsRL[winning.source] = winning.payout
                            end
                        end

                        for i in pairs(races[index].players) do
                            TriggerClientEvent("races:results", i, races[index].results)
                            if races[index].rtype ~= "rand" then
                                Deposit(i, winningsRL[i])
                                notifyPlayer(i, winningsRL[i] .. " was deposited in your funds.\n")
                            end
                        end

                        if races[index].savedRaceName ~= nil then
                            updateBestLapTimes(index)
                        end
                        races[index] = nil -- delete race after all players finish
                    end
                else
                    notifyPlayer(source, "Cannot finish.  Not a member of this race.\n")
                end
            else
                notifyPlayer(source, "Cannot finish.  Race not in progress.\n")
            end
        else
            notifyPlayer(source, "Cannot finish.  Race does not exist.\n")
        end
    else
        notifyPlayer(source, "Ignoring finish event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:report")
AddEventHandler("races:report", function(index, numWaypointsPassed, distance)
    local source = source
    if index ~= nil and numWaypointsPassed ~= nil and distance ~= nil then
        if races[index] ~= nil then
            if races[index].players[source] ~= nil then
                races[index].players[source].numWaypointsPassed = numWaypointsPassed
                races[index].players[source].data = distance
            else
                notifyPlayer(source, "Cannot report.  Not a member of this race.\n")
            end
        else
            notifyPlayer(source, "Cannot report.  Race does not exist.\n")
        end
    else
        notifyPlayer(source, "Ignoring report event.  Invalid parameters.\n")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        for _, race in pairs(races) do
            if STATE_RACING == race.state then
                local sortedPlayers = {} -- will contain players still racing and players that finished without DNF
                local complete = true

                -- race.players[] = {playerName, numWaypointsPassed, data, finished}
                for i, player in pairs(race.players) do
                    if -1 == player.numWaypointsPassed then -- player client hasn't updated numWaypointsPassed and data
                        complete = false
                        break
                    end

                    -- player.data will be travel distance to next waypoint or finish time; finish time will be -1 if player DNF
                    -- if player.data == -1 then player did not finish race - do not include in sortedPlayers
                    if player.data ~= -1 then
                        sortedPlayers[#sortedPlayers + 1] = {index = i, numWaypointsPassed = player.numWaypointsPassed, data = player.data, finished = player.finished}
                    end
                end

                if true == complete then -- all player clients have updated numWaypointsPassed and data
                    table.sort(sortedPlayers, function(p0, p1)
                        return (p0.numWaypointsPassed > p1.numWaypointsPassed) or (p0.numWaypointsPassed == p1.numWaypointsPassed and p0.data < p1.data)
                    end)
                    -- players sorted into sortedPlayers table
                    for position, sortedPlayer in pairs(sortedPlayers) do
                        if false == sortedPlayer.finished then
                            TriggerClientEvent("races:position", sortedPlayer.index, position, #sortedPlayers)
                        end
                    end
                end
            end
        end
    end
end)
