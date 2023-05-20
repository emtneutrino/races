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

local function readFile(filename)
    return LoadResourceFile(GetCurrentResourceName(), filename)
end

local function readData(filename)
    return json.decode(readFile(filename))
end

local function writeFile(filename, data)
    return 1 == SaveResourceFile(GetCurrentResourceName(), filename, data, -1)
end

local function writeData(filename, data)
    return writeFile(filename, json.encode(data))
end

local STATE_REGISTERING <const> = 0 -- registering race state
local STATE_RACING <const> = 1 -- racing state

local trackDataFileName <const> = "trackData.json" -- track data filename
if nil == readData(trackDataFileName) then
    writeData(trackDataFileName, {})
end

local aiGroupDataFileName <const> = "aiGroupData.json" -- AI group data filename
if nil == readData(aiGroupDataFileName) then
    writeData(aiGroupDataFileName, {})
end

local vehicleListDataFileName <const> = "vehicleListData.json" -- vehicle list data filename
if nil == readData(vehicleListDataFileName) then
    writeData(vehicleListDataFileName, {})
end

local saveLog <const> = false -- flag indicating if certain events should be logged
local logFileName <const> = "log.txt" -- log filename

local allVehicles = readData("vehicles.json") or {} -- list of all vehicles
if #allVehicles ~= 0 then
    table.sort(allVehicles)
    local current = allVehicles[1]
    for i = 2, #allVehicles do
        while true do
            if allVehicles[i] ~= nil then
                if allVehicles[i] == current then
                    table.remove(allVehicles, i)
                else
                    current = allVehicles[i]
                    break
                end
            else
                break
            end
        end
    end
else
    print("^1Warning!  The file 'vehicles.json' does not exist or is empty.^0")
end

local defaultRadius <const> = 5.0 -- default waypoint radius

local races = {} -- races[playerID] = {state, waypointCoords[] = {x, y, z, r}, isPublic, trackName, owner, buyin, laps, timeout, rtype, restrict, vclass, svehicle, vehicleList, numRacing, players[netID] = {source, playerName, aiName, numWaypointsPassed, data, coord}, results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}}

local dist <const> = {60, 20, 10, 5, 3, 2} -- prize distribution
local distValid = true -- flag indicating if prize distribution is valid
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
    print("^1Warning!  The prize distribution table is invalid.^0")
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

local function logMessage(msg)
    if true == saveLog then
        local logFile = readFile(logFileName)
        logFile = (logFile or "") .. os.date() .. " : " .. msg .. "\n"
        if false == writeFile(logFileName, logFile) then
            print("logMessage: Error writing file '" .. logFileName .. "'")
        end
    end
end

local function getTrack(trackName)
    local track = readData(trackName .. ".json")
    if track ~= nil then
        if "table" == type(track) and "table" == type(track.waypointCoords) and "table" == type(track.bestLaps) then
            if #track.waypointCoords > 1 then
                for _, waypointCoord in ipairs(track.waypointCoords) do
                    if type(waypointCoord) ~= "table" or type(waypointCoord.x) ~= "number" or type(waypointCoord.y) ~= "number" or type(waypointCoord.z) ~= "number" or type(waypointCoord.r) ~= "number" then
                        print("getTrack: waypointCoord not a table or waypointCoord.x or waypointCoord.y or waypointCoord.z or waypointCoord.r not a number.")
                        return nil
                    end
                end
                for _, bestLap in ipairs(track.bestLaps) do
                    if type(bestLap) ~= "table" or type(bestLap.playerName) ~= "string" or type(bestLap.bestLapTime) ~= "number" or type(bestLap.vehicleName) ~= "string" then
                        print("getTrack: bestLap not a table or bestLap.playerName not a string or bestLap.bestLapTime not a number or bestLap.vehicleName not a string.")
                        return nil
                    end
                end
                return track
            else
                print("getTrack: Number of waypoints is less than 2.")
            end
        else
            print("getTrack: track or track.waypointCoords or track.bestLaps not a table.")
        end
    else
        print("getTrack: Could not load track data.")
    end
    return nil
end

local function export(trackName, withBLT)
    if trackName ~= nil then
        local trackData = readData(trackDataFileName)
        if trackData ~= nil then
            local publicTracks = trackData["PUBLIC"]
            if publicTracks ~= nil then
                if publicTracks[trackName] ~= nil then
                    local trackFileName = trackName .. ".json"
                    if nil == readData(trackFileName) then
                        if false == withBLT then
                            publicTracks[trackName].bestLaps = {}
                        end
                        if true == writeData(trackFileName, publicTracks[trackName]) then
                            local msg = "export: Exported track '" .. trackName .. "'."
                            print(msg)
                            logMessage(msg)
                        else
                            print("export: Could not write track data.")
                        end
                    else
                        print("export: '" .. trackFileName .. "' exists.  Remove or rename the existing file, then export again.")
                    end
                else
                    print("export: No public track named '" .. trackName .. "'.")
                end
            else
                print("export: No public track data.")
            end
        else
            print("export: Could not load track data.")
        end
    else
        print("export: Name required.")
    end
end

local function import(trackName, withBLT)
    if trackName ~= nil then
        local trackData = readData(trackDataFileName)
        if trackData ~= nil then
            local publicTracks = trackData["PUBLIC"] or {}
            if nil == publicTracks[trackName] then
                local track = getTrack(trackName)
                if track ~= nil then
                    if false == withBLT then
                        track.bestLaps = {}
                    end
                    publicTracks[trackName] = track
                    trackData["PUBLIC"] = publicTracks
                    if true == writeData(trackDataFileName, trackData) then
                        local msg = "import: Imported track '" .. trackName .. "'."
                        print(msg)
                        logMessage(msg)
                    else
                        print("import: Could not write track data.")
                    end
                else
                    print("import: Could not import '" .. trackName .. "'.")
                end
            else
                print("import: '" .. trackName .. "' already exists in the public tracks list.  Rename the file, then import with the new name.")
            end
        else
            print("import: Could not load track data.")
        end
    else
        print("import: Name required.")
    end
end

local function loadTrack(isPublic, source, trackName)
    local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if license ~= nil then
        local trackData = readData(trackDataFileName)
        if trackData ~= nil then
            local tracks = trackData[license]
            if tracks ~= nil then
                return tracks[trackName]
            end
        else
            notifyPlayer(source, "loadTrack: Could not load track data.\n")
        end
    else
        notifyPlayer(source, "loadTrack: Could not get license for player source ID: " .. source .. "\n")
    end
    return nil
end

local function saveTrack(isPublic, source, trackName, track)
    local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if license ~= nil then
        local trackData = readData(trackDataFileName)
        if trackData ~= nil then
            local tracks = trackData[license] or {}
            tracks[trackName] = track
            trackData[license] = tracks
            if true == writeData(trackDataFileName, trackData) then
                return true
            else
                notifyPlayer(source, "saveTrack: Could not write track data.\n")
            end
        else
            notifyPlayer(source, "saveTrack: Could not load track data.\n")
        end
    else
        notifyPlayer(source, "saveTrack: Could not get license for player source ID: " .. source .. "\n")
    end
    return false
end

local function loadVehicleList(isPublic, source, name)
    local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if license ~= nil then
        local vehicleListData = readData(vehicleListDataFileName)
        if vehicleListData ~= nil then
            local lists = vehicleListData[license]
            if lists ~= nil then
                return lists[name]
            end
        else
            notifyPlayer(source, "loadVehicleList: Could not load vehicle list data.\n")
        end
    else
        notifyPlayer(source, "loadVehicleList: Could not get license for player source ID: " .. source .. "\n")
    end
    return nil
end

local function saveVehicleList(isPublic, source, name, vehicleList)
    local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if license ~= nil then
        local vehicleListData = readData(vehicleListDataFileName)
        if vehicleListData ~= nil then
            local lists = vehicleListData[license] or {}
            lists[name] = vehicleList
            vehicleListData[license] = lists
            if true == writeData(vehicleListDataFileName, vehicleListData) then
                return true
            else
                notifyPlayer(source, "saveVehicleList: Could not write vehicle list data.\n")
            end
        else
            notifyPlayer(source, "saveVehicleList: Could not load vehicle list data.\n")
        end
    else
        notifyPlayer(source, "saveVehicleList: Could not get license for player source ID: " .. source .. "\n")
    end
    return false
end

local function loadAIGroup(isPublic, source, name)
    local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if license ~= nil then
        local aiGroupData = readData(aiGroupDataFileName)
        if aiGroupData ~= nil then
            local groups = aiGroupData[license]
            if groups ~= nil then
                return groups[name]
            end
        else
            notifyPlayer(source, "loadAIGroup: Could not load AI group data.\n")
        end
    else
        notifyPlayer(source, "loadAIGroup: Could not get license for player source ID: " .. source .. "\n")
    end
    return nil
end

local function saveAIGroup(isPublic, source, name, group)
    local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if license ~= nil then
        local aiGroupData = readData(aiGroupDataFileName)
        if aiGroupData ~= nil then
            local groups = aiGroupData[license] or {}
            groups[name] = group
            aiGroupData[license] = groups
            if true == writeData(aiGroupDataFileName, aiGroupData) then
                return true
            else
                notifyPlayer(source, "saveAIGroup: Could not write AI group data.\n")
            end
        else
            notifyPlayer(source, "saveAIGroup: Could not load AI group data.\n")
        end
    else
        notifyPlayer(source, "saveAIGroup: Could not get license for player source ID: " .. source .. "\n")
    end
    return false
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

local function updateBestLapTimes(rIndex)
    local race = races[rIndex]
    local track = loadTrack(race.isPublic, rIndex, race.trackName)
    if track ~= nil then -- saved track still exists - not deleted in middle of race
        local bestLaps = track.bestLaps
        for _, result in pairs(race.results) do
            if result.bestLapTime ~= -1 and nil == result.aiName then
                bestLaps[#bestLaps + 1] = {playerName = result.playerName, bestLapTime = result.bestLapTime, vehicleName = result.vehicleName}
            end
        end
        table.sort(bestLaps, function(p0, p1)
            return p0.bestLapTime < p1.bestLapTime
        end)
        for i = 11, #bestLaps do
            bestLaps[i] = nil
        end
        track.bestLaps = bestLaps
        if false == saveTrack(race.isPublic, rIndex, race.trackName, track) then
            notifyPlayer(rIndex, "Save error updating best lap times.\n")
        end
    else
        notifyPlayer(rIndex, "Cannot save best lap times.  Track '" .. race.trackName .. "' has been deleted.\n")
    end
end

local function minutesSeconds(milliseconds)
    local seconds = milliseconds / 1000.0
    local minutes = math.floor(seconds / 60.0)
    seconds = seconds - minutes * 60.0
    return minutes, seconds
end

local function saveResults(race)
    -- races[playerID] = {state, waypointCoords[] = {x, y, z, r}, isPublic, trackName, owner, buyin, laps, timeout, rtype, restrict, vclass, svehicle, vehicleList, numRacing, players[netID] = {source, playerName, aiName, numWaypointsPassed, data, coord}, results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}}
    local msg = "Race registered by '" .. race.owner .. "' using "
    if nil == race.trackName then
        msg = msg .. "unsaved track "
    else
        msg = msg .. (true == race.isPublic and "publicly" or "privately") .. " saved track '" .. race.trackName .. "'"
    end
    msg = msg .. (" : %d buy-in : %d lap(s) : %d timeout"):format(race.buyin, race.laps, race.timeout)
    if "yes" == race.allowAI then
        msg = msg .. " : AI allowed"
    end
    if "rest" == race.rtype then
        msg = msg .. " : using '" .. race.restrict .. "' vehicle"
    elseif "class" == race.rtype then
        msg = msg .. " : using " .. getClassName(race.vclass) .. " class vehicles"
    elseif "rand" == race.rtype then
        msg = msg .. " : using random "
        if race.vclass ~= nil then
            msg = msg .. getClassName(race.vclass) .. " class vehicles"
        else
            msg = msg .. "vehicles"
        end
        if race.svehicle ~= nil then
            msg = msg .. " : start '" .. race.svehicle .. "'"
        end
    end
    msg = msg .. "\n"

    -- results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}
    msg = msg .. "Results:\n"
    for pos, result in ipairs(race.results) do
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

    local resultsFileName = "results_" .. race.owner .. ".txt"
    if false == writeFile(resultsFileName, msg) then
        print("Error writing file '" .. resultsFileName .. "'")
    end
end

local function round(f)
    return (f - math.floor(f) >= 0.5) and math.ceil(f) or math.floor(f)
end

RegisterCommand("races", function(_, args)
    if nil == args[1] then
        local msg = "Commands:\n"
        msg = msg .. "races - display list of available races commands\n"
        msg = msg .. "races export [name] - export public track saved as [name] without best lap times to file named '[name].json'\n"
        msg = msg .. "races import [name] - import track file named '[name].json' into public tracks without best lap times\n"
        msg = msg .. "races exportwblt [name] - export public track saved as [name] with best lap times to file named '[name].json'\n"
        msg = msg .. "races importwblt [name] - import track file named '[name].json' into public tracks with best lap times\n"
        print(msg)
    elseif "export" == args[1] then
        export(args[2], false)
    elseif "import" == args[1] then
        import(args[2], false)
    elseif "exportwblt" == args[1] then
        export(args[2], true)
    elseif "importwblt" == args[1] then
        import(args[2], true)
    else
        print("Unknown command.")
    end
end, true)

AddEventHandler("playerDropped", function()
    local source = source

    -- unregister race registered by dropped player that has not started
    if races[source] ~= nil and STATE_REGISTERING == races[source].state then
        if races[source].buyin > 0 then
            for _, player in pairs(races[source].players) do
                Deposit(player.source, races[source].buyin)
                TriggerClientEvent("races:cash", player.source, GetFunds(player.source))
                notifyPlayer(player.source, races[source].buyin .. " was deposited in your funds.\n")
            end
        end
        races[source] = nil
        TriggerClientEvent("races:unregister", -1, source)
    end

    -- remove dropped player's bank account
    Remove(source)

    -- remove dropped player from the race they are joined to
    for i, race in pairs(races) do
        for netID, player in pairs(race.players) do
            if player.source == source then
                if STATE_REGISTERING == race.state then
                    race.players[netID] = nil
                    race.numRacing = race.numRacing - 1
                else
                    TriggerEvent("races:finish", i, netID, nil, 0, -1, -1, "", source)
                end
                return
            end
        end
    end
end)

--[[
local function sortRemDup(sounds)
    table.sort(sounds, function(p0, p1)
        return (p0.ref < p1.ref) or (p0.ref == p1.ref and p0.name < p1.name)
    end)
    local current = sounds[1]
    for i = 2, #sounds do
        while true do
            if sounds[i] ~= nil then
                if sounds[i].ref == current.ref and sounds[i].name == current.name then
                    table.remove(sounds, i)
                else
                    current = sounds[i]
                    break
                end
            else
                break
            end
        end
    end
end

RegisterNetEvent("sounds0")
AddEventHandler("sounds0", function()
    local source = source
    local filePath = "./resources/races/sounds/sounds.csv"
    local file, errMsg, errCode = io.open(filePath, "r")
    if file ~= fail then
        local sounds = {}
        for line in file:lines() do
            local i = string.find(line, ",")
            if i ~= fail then
                local name = string.sub(line, 1, i - 1)
                local ref = string.sub(line, i + 1, -1)
                sounds[#sounds + 1] = {name = name, ref = ref}
            else
                print(line)
            end
        end
        file:close()
        sortRemDup(sounds)
        TriggerClientEvent("sounds", source, sounds)
    else
        print("Error opening file '" .. filePath .. "' for read : '" .. errMsg .. "' : " .. errCode)
    end
end)

RegisterNetEvent("sounds1")
AddEventHandler("sounds1", function()
    local source = source
    local filePath = "./resources/races/sounds/altv.stuyk.com.txt"
    local file, errMsg, errCode = io.open(filePath, "r")
    if file ~= fail then
        local sounds = {}
        for line in file:lines() do
            local name, ref = string.match(line, "(\t.*)(\t.*)")
            if name ~= nil and ref ~= nil then
                name = string.sub(name, 2, -1)
                ref = string.sub(ref, 2, -1)
                sounds[#sounds + 1] = {name = name, ref = ref}
            end
        end
        file:close()
        sortRemDup(sounds)
        TriggerClientEvent("sounds", source, sounds)
    else
        print("Error opening file '" .. filePath .. "' for read : '" .. errMsg .. "' : " .. errCode)
    end
end)

RegisterNetEvent("vehicles")
AddEventHandler("vehicles", function()
    local source = source
    local filePath = "./resources/races/vehicles.txt"
    local file, errMsg, errCode = io.open(filePath, "r")
    if file ~= fail then
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
    if file ~= fail then
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
    if file ~= fail then
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

    TriggerClientEvent("races:allVehicles", source, allVehicles)

    -- if funds < 5000, set funds to 5000
    if GetFunds(source) < 5000 then
        SetFunds(source, 5000)
    end
    TriggerClientEvent("races:cash", source, GetFunds(source))

    -- register any races created before player joined
    for rIndex, race in pairs(races) do
        if STATE_REGISTERING == race.state then
            local rdata = {rtype = race.rtype, restrict = race.restrict, vclass = race.vclass, svehicle = race.svehicle, vehicleList = race.vehicleList}
            TriggerClientEvent("races:register", source, rIndex, race.waypointCoords[1], race.isPublic, race.trackName, race.owner, race.buyin, race.laps, race.timeout, race.allowAI, rdata)
        end
    end
end)

RegisterNetEvent("races:load")
AddEventHandler("races:load", function(isPublic, trackName)
    local source = source
    if isPublic ~= nil and trackName ~= nil then
        local track = loadTrack(isPublic, source, trackName)
        if track ~= nil then
            TriggerClientEvent("races:load", source, isPublic, trackName, track.waypointCoords)
        else
            sendMessage(source, "Cannot load.   " .. (true == isPublic and "Public" or "Private") .. " track '" .. trackName .. "' not found.\n")
        end
    else
        sendMessage(source, "Ignoring load track event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:save")
AddEventHandler("races:save", function(isPublic, trackName, waypointCoords)
    local source = source
    if isPublic ~= nil and trackName ~= nil and waypointCoords ~= nil then
        local track = loadTrack(isPublic, source, trackName)
        if nil == track then
            track = {waypointCoords = waypointCoords, bestLaps = {}}
            if true == saveTrack(isPublic, source, trackName, track) then
                TriggerClientEvent("races:save", source, isPublic, trackName)
                TriggerEvent("races:trackNames", isPublic, source)
                logMessage("'" .. GetPlayerName(source) .. "' saved " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'")
            else
                sendMessage(source, "Error saving " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
            end
        else
            sendMessage(source, (true == isPublic and "Public" or "Private") .. " track '" .. trackName .. "' exists.  Use 'overwrite' command instead.\n")
        end
    else
        sendMessage(source, "Ignoring save track event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:overwrite")
AddEventHandler("races:overwrite", function(isPublic, trackName, waypointCoords)
    local source = source
    if isPublic ~= nil and trackName ~= nil and waypointCoords ~= nil then
        local track = loadTrack(isPublic, source, trackName)
        if track ~= nil then
            track = {waypointCoords = waypointCoords, bestLaps = {}}
            if true == saveTrack(isPublic, source, trackName, track) then
                TriggerClientEvent("races:overwrite", source, isPublic, trackName)
                logMessage("'" .. GetPlayerName(source) .. "' overwrote " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'")
            else
                sendMessage(source, "Error overwriting " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
            end
        else
            sendMessage(source, (true == isPublic and "Public" or "Private") .. " track '" .. trackName .. "' does not exist.  Use 'save' command instead.\n")
        end
    else
        sendMessage(source, "Ignoring overwrite track event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:delete")
AddEventHandler("races:delete", function(isPublic, trackName)
    local source = source
    if isPublic ~= nil and trackName ~= nil then
        local track = loadTrack(isPublic, source, trackName)
        if track ~= nil then
            if true == saveTrack(isPublic, source, trackName, nil) then
                TriggerEvent("races:trackNames", isPublic, source)
                sendMessage(source, "Deleted " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' deleted " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'")
            else
                sendMessage(source, "Error deleting " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
            end
        else
            sendMessage(source, "Cannot delete.  " .. (true == isPublic and "Public" or "Private") .. " track '" .. trackName .. "' not found.\n")
        end
    else
        sendMessage(source, "Ignoring delete track event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:blt")
AddEventHandler("races:blt", function(isPublic, trackName)
    local source = source
    if isPublic ~= nil and trackName ~= nil then
        local track = loadTrack(isPublic, source, trackName)
        if track ~= nil then
            TriggerClientEvent("races:blt", source, isPublic, trackName, track.bestLaps)
        else
            sendMessage(source, "Cannot list best lap times.   " .. (true == isPublic and "Public" or "Private") .. " track '" .. trackName .. "' not found.\n")
        end
    else
        sendMessage(source, "Ignoring best lap times event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:list")
AddEventHandler("races:list", function(isPublic)
    local source = source
    if isPublic ~= nil then
        local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
        if license ~= nil then
            local trackData = readData(trackDataFileName)
            if trackData ~= nil then
                local tracks = trackData[license]
                if tracks ~= nil then
                    local names = {}
                    for name in pairs(tracks) do
                        names[#names + 1] = name
                    end
                    if #names > 0 then
                        table.sort(names)
                        local msg = "Saved " .. (true == isPublic and "public" or "private") .. " tracks:\n"
                        for _, name in ipairs(names) do
                            msg = msg .. name .. "\n"
                        end
                        sendMessage(source, msg)
                    else
                        sendMessage(source, "No saved " .. (true == isPublic and "public" or "private") .. " tracks.\n")
                    end
                else
                    sendMessage(source, "No saved " .. (true == isPublic and "public" or "private") .. " tracks.\n")
                end
            else
                sendMessage(source, "Could not load track data.\n")
            end
        else
            sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        end
    else
        sendMessage(source, "Ignoring list event.  Invalid parameters.\n")
   end
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(waypointCoords, isPublic, trackName, buyin, laps, timeout, allowAI, rdata)
    local source = source
    if waypointCoords ~= nil and isPublic ~= nil and buyin ~= nil and laps ~= nil and timeout ~= nil and allowAI ~= nil and rdata ~= nil then
        if buyin >= 0 then
            if laps > 0 then
                if timeout >= 0 then
                    if "yes" == allowAI or "no" == allowAI then
                        if nil == races[source] then
                            if false == distValid or "yes" == allowAI or "rand" == rdata.rtype then
                                buyin = 0
                            end
                            local owner = GetPlayerName(source)
                            local msg = "Registered race by '" .. owner .. "' using "
                            if nil == trackName then
                                msg = msg .. "unsaved track"
                            else
                                msg = msg .. (true == isPublic and "publicly" or "privately") .. " saved track '" .. trackName .. "'"
                            end
                            msg = msg .. (" : %d buy-in : %d lap(s) : %d timeout"):format(buyin, laps, timeout)
                            if "yes" == allowAI then
                                msg = msg .. " : AI allowed"
                            end
                            if "rest" == rdata.rtype then
                                if nil == rdata.restrict then
                                    sendMessage(source, "Cannot register.  Invalid restricted vehicle.\n")
                                    return
                                end
                                msg = msg .. " : using '" .. rdata.restrict .. "' vehicle"
                            elseif "class" == rdata.rtype then
                                if nil == rdata.vclass or rdata.vclass < -1 or rdata.vclass > 21 then
                                    sendMessage(source, "Cannot register.  Invalid vehicle class.\n")
                                    return
                                end
                                if -1 == rdata.vclass and 0 == #rdata.vehicleList then
                                    sendMessage(source, "Cannot register.  Vehicle list is empty.\n")
                                    return
                                end
                                msg = msg .. " : using " .. getClassName(rdata.vclass) .. " class vehicles"
                            elseif "rand" == rdata.rtype then
                                if 0 == #rdata.vehicleList then
                                    sendMessage(source, "Cannot register.  Vehicle list is empty.\n")
                                    return
                                end
                                msg = msg .. " : using random "
                                if rdata.vclass ~= nil then
                                    if (rdata.vclass < 0 or rdata.vclass > 21) then
                                        sendMessage(source, "Cannot register.  Invalid vehicle class.\n")
                                        return
                                    end
                                    msg = msg .. getClassName(rdata.vclass) .. " class vehicles"
                                else
                                    msg = msg .. "vehicles"
                                end
                                if rdata.svehicle ~= nil then
                                    msg = msg .. " : start '" .. rdata.svehicle .. "'"
                                end
                            elseif rdata.rtype ~= nil then
                                sendMessage(source, "Cannot register.  Unknown race type.\n")
                                return
                            end
                            msg = msg .. "\n"
                            if false == distValid then
                                msg = msg .. "Warning!  Prize distribution table is invalid.  There will be no prize payouts.\n"
                            end
                            sendMessage(source, msg)
                            races[source] = {
                                state = STATE_REGISTERING,
                                waypointCoords = waypointCoords,
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
                                numRacing = 0,
                                players = {},
                                results = {}
                            }
                            TriggerClientEvent("races:register", -1, source, waypointCoords[1], isPublic, trackName, owner, buyin, laps, timeout, allowAI, rdata)
                        else
                            if STATE_RACING == races[source].state then
                                sendMessage(source, "Cannot register.  Previous race in progress.\n")
                            else
                                sendMessage(source, "Cannot register.  Previous race registered.  Unregister first.\n")
                            end
                        end
                    else
                        sendMessage(source, "Invalid AI allowed value.\n")
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
        if races[source].buyin > 0 then
            for _, player in pairs(races[source].players) do
                Deposit(player.source, races[source].buyin)
                TriggerClientEvent("races:cash", player.source, GetFunds(player.source))
                notifyPlayer(player.source, races[source].buyin .. " was deposited in your funds.\n")
            end
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
                if delay >= 5 then
                    if races[source].numRacing > 0 then
                        races[source].state = STATE_RACING
                        local aiStart = false
                        local ownerJoined = false
                        for _, player in pairs(races[source].players) do
                            if nil == player.aiName then
                                if player.source == source then
                                    ownerJoined = true
                                end
                                -- trigger races:start event for non AI drivers
                                TriggerClientEvent("races:start", player.source, source, delay)
                            else
                                aiStart = true
                            end
                        end
                        if true == aiStart and false == ownerJoined then
                            -- trigger races:start event for AI drivers since owner did not join race
                            TriggerClientEvent("races:start", source, source, delay)
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
                sendMessage(source, "Cannot start.  Race already in progress.\n")
            end
        else
            sendMessage(source, "Cannot start.  Race does not exist.\n")
        end
    else
        sendMessage(source, "Ignoring start event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:loadGrp")
AddEventHandler("races:loadGrp", function(isPublic, name)
    local source = source
    if isPublic ~= nil and name ~= nil then
        local group = loadAIGroup(isPublic, source, name)
        if group ~= nil then
            TriggerClientEvent("races:loadGrp", source, isPublic, name, group)
        else
            sendMessage(source, "Cannot load.   " .. (true == isPublic and "Public" or "Private") .. " AI group '" .. name .. "' not found.\n")
        end
    else
        sendMessage(source, "Ignoring load AI group event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:saveGrp")
AddEventHandler("races:saveGrp", function(isPublic, name, group)
    local source = source
    if isPublic ~= nil and name ~= nil and group ~= nil then
        if nil == loadAIGroup(isPublic, source, name) then
            if true == saveAIGroup(isPublic, source, name, group) then
                TriggerEvent("races:aiGrpNames", isPublic, source)
                sendMessage(source, "Saved " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' saved " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'")
            else
                sendMessage(source, "Error saving " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
            end
        else
            sendMessage(source, (true == isPublic and "Public" or "Private") .. " AI group '" .. name .. "' exists.  Use 'overwriteGrp' command instead.\n")
        end
    else
        sendMessage(source, "Ignoring save AI group event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:overwriteGrp")
AddEventHandler("races:overwriteGrp", function(isPublic, name, group)
    local source = source
    if isPublic ~= nil and name ~= nil and group ~= nil then
        if loadAIGroup(isPublic, source, name) ~= nil then
            if true == saveAIGroup(isPublic, source, name, group) then
                sendMessage(source, "Overwrote " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' overwrote " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'")
            else
                sendMessage(source, "Error overwriting " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
            end
        else
            sendMessage(source, (true == isPublic and "Public" or "Private") .. " AI group '" .. name .. "' does not exist.  Use 'saveGrp' command instead.\n")
        end
    else
        sendMessage(source, "Ignoring overwrite AI group event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:deleteGrp")
AddEventHandler("races:deleteGrp", function(isPublic, name)
    local source = source
    if isPublic ~= nil and name ~= nil then
        local group = loadAIGroup(isPublic, source, name)
        if group ~= nil then
            if true == saveAIGroup(isPublic, source, name, nil) then
                TriggerEvent("races:aiGrpNames", isPublic, source)
                sendMessage(source, "Deleted " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' deleted " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'")
            else
                sendMessage(source, "Error deleting " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
            end
        else
            sendMessage(source, "Cannot delete.  " .. (true == isPublic and "Public" or "Private") .. " AI group '" .. name .. "' not found.\n")
        end
    else
        sendMessage(source, "Ignoring delete AI group event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:listGrps")
AddEventHandler("races:listGrps", function(isPublic)
    local source = source
    if isPublic ~= nil then
        local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
        if license ~= nil then
            local aiGroupData = readData(aiGroupDataFileName)
            if aiGroupData ~= nil then
                local groups = aiGroupData[license]
                if groups ~= nil then
                    local names = {}
                    for name in pairs(groups) do
                        names[#names + 1] = name
                    end
                    if #names > 0 then
                        table.sort(names)
                        local msg = "Saved " .. (true == isPublic and "public" or "private") .. " AI groups:\n"
                        for _, name in ipairs(names) do
                            msg = msg .. name .. "\n"
                        end
                        sendMessage(source, msg)
                    else
                        sendMessage(source, "No saved " .. (true == isPublic and "public" or "private") .. " AI groups.\n")
                    end
                else
                    sendMessage(source, "No saved " .. (true == isPublic and "public" or "private") .. " AI groups.\n")
                end
            else
                sendMessage(source, "Could not load AI group data.\n")
            end
        else
            sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        end
    else
        sendMessage(source, "Ignoring list AI groups event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:loadLst")
AddEventHandler("races:loadLst", function(isPublic, name)
    local source = source
    if isPublic ~= nil and name ~= nil then
        local list = loadVehicleList(isPublic, source, name)
        if list ~= nil then
            TriggerClientEvent("races:loadLst", source, isPublic, name, list)
        else
            sendMessage(source, "Cannot load.   " .. (true == isPublic and "Public" or "Private") .. " vehicle list '" .. name .. "' not found.\n")
        end
    else
        sendMessage(source, "Ignoring load vehicle list event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:saveLst")
AddEventHandler("races:saveLst", function(isPublic, name, vehicleList)
    local source = source
    if isPublic ~= nil and name ~= nil and vehicleList ~= nil then
        if nil == loadVehicleList(isPublic, source, name) then
            if true == saveVehicleList(isPublic, source, name, vehicleList) then
                TriggerEvent("races:listNames", isPublic, source)
                sendMessage(source, "Saved " .. (true == isPublic and "public" or "private") .. " vehicle list '" .. name .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' saved " .. (true == isPublic and "public" or "private") .. " vehicle list '" .. name .. "'")
            else
                sendMessage(source, "Error saving " .. (true == isPublic and "public" or "private") .. " vehicle list '" .. name .. "'.\n")
            end
        else
            sendMessage(source, (true == isPublic and "Public" or "Private") .. " vehicle list '" .. name .. "' exists.  Use 'overwrite' command instead.\n")
        end
    else
        sendMessage(source, "Ignoring save vehicle list event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:overwriteLst")
AddEventHandler("races:overwriteLst", function(isPublic, name, vehicleList)
    local source = source
    if isPublic ~= nil and name ~= nil and vehicleList ~= nil then
        local list = loadVehicleList(isPublic, source, name)
        if list ~= nil then
            if true == saveVehicleList(isPublic, source, name, vehicleList) then
                sendMessage(source, "Overwrote " .. (true == isPublic and "public" or "private") .. " vehicle list '" .. name .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' overwrote " .. (true == isPublic and "public" or "private") .. " vehicle list '" .. name .. "'")
            else
                sendMessage(source, "Error overwriting " .. (true == isPublic and "public" or "private") .. " vehicle list '" .. name .. "'.\n")
            end
        else
            sendMessage(source, (true == isPublic and "Public" or "Private") .. " vehicle list '" .. name .. "' does not exist.  Use 'save' command instead.\n")
        end
    else
        sendMessage(source, "Ignoring overwrite vehicle list event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:deleteLst")
AddEventHandler("races:deleteLst", function(isPublic, name)
    local source = source
    if isPublic ~= nil and name ~= nil then
        local list = loadVehicleList(isPublic, source, name)
        if list ~= nil then
            if true == saveVehicleList(isPublic, source, name, nil) then
                TriggerEvent("races:listNames", isPublic, source)
                sendMessage(source, "Deleted " .. (true == isPublic and "public" or "private") .. " vehicle list '" .. name .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' deleted " .. (true == isPublic and "public" or "private") .. " vehicle list '" .. name .. "'")
            else
                sendMessage(source, "Error deleting " .. (true == isPublic and "public" or "private") .. " vehicle list '" .. name .. "'.\n")
            end
        else
            sendMessage(source, "Cannot delete.  " .. (true == isPublic and "Public" or "Private") .. " vehicle list '" .. name .. "' not found.\n")
        end
    else
        sendMessage(source, "Ignoring delete vehicle list event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:listLsts")
AddEventHandler("races:listLsts", function(isPublic)
    local source = source
    if isPublic ~= nil then
        local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
        if license ~= nil then
            local vehicleListData = readData(vehicleListDataFileName)
            if vehicleListData ~= nil then
                local lists = vehicleListData[license]
                if lists ~= nil then
                    local names = {}
                    for name in pairs(lists) do
                        names[#names + 1] = name
                    end
                    if #names > 0 then
                        table.sort(names)
                        local msg = "Saved " .. (true == isPublic and "public" or "private") .. " vehicle lists:\n"
                        for _, name in ipairs(names) do
                            msg = msg .. name .. "\n"
                        end
                        sendMessage(source, msg)
                    else
                        sendMessage(source, "No saved " .. (true == isPublic and "public" or "private") .. " vehicle lists.\n")
                    end
                else
                    sendMessage(source, "No saved " .. (true == isPublic and "public" or "private") .. " vehicle lists.\n")
                end
            else
                sendMessage(source, "Could not load vehicle list data.\n")
            end
        else
            sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        end
    else
        sendMessage(source, "Ignoring list vehicle lists event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:leave")
AddEventHandler("races:leave", function(rIndex, netID, aiName)
    local source = source
    if rIndex ~= nil and netID ~= nil then
        local race = races[rIndex]
        if race ~= nil then
            if STATE_REGISTERING == race.state then
                if race.players[netID] ~= nil then
                    race.players[netID] = nil
                    race.numRacing = race.numRacing - 1
                    if nil == aiName and race.buyin > 0 then
                        Deposit(source, race.buyin)
                        TriggerClientEvent("races:cash", source, GetFunds(source))
                        sendMessage(source, race.buyin .. " was deposited in your funds.\n")
                    end
                    for _, player in pairs(race.players) do
                        if nil == player.aiName then
                            TriggerClientEvent("races:deleteRacer", player.source, netID)
                        end
                    end
                else
                    sendMessage(source, "Cannot leave.  Not a member of this race.\n")
                end
            else
                -- player will trigger races:finish event
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
AddEventHandler("races:rivals", function(rIndex)
    local source = source
    if rIndex ~= nil then
        if races[rIndex] ~= nil then
            local names = {}
            for _, player in pairs(races[rIndex].players) do
                names[#names + 1] = player.playerName
            end
            table.sort(names)
            local msg = "Competitors:\n"
            for _, name in ipairs(names) do
                msg = msg .. name .. "\n"
            end
            sendMessage(source, msg)
        else
            sendMessage(source, "Cannot list competitors.  Race does not exist.\n")
        end
    else
        sendMessage(source, "Ignoring rivals event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:funds")
AddEventHandler("races:funds", function()
    local source = source
    sendMessage(source, "Available funds: " .. GetFunds(source) .. "\n")
    TriggerClientEvent("races:cash", source, GetFunds(source))
end)

RegisterNetEvent("races:join")
AddEventHandler("races:join", function(rIndex, netID, aiName)
    local source = source
    if rIndex ~= nil and netID ~= nil then
        local race = races[rIndex]
        if race ~= nil then
            if (nil == aiName and GetFunds(source) >= race.buyin) or aiName ~= nil then
                if STATE_REGISTERING == race.state then
                    local playerName = aiName ~= nil and ("(AI) " .. aiName) or GetPlayerName(source)
                    for _, player in pairs(race.players) do
                        if nil == player.aiName then
                            TriggerClientEvent("races:addRacer", player.source, netID, playerName)
                        end
                    end
                    if nil == aiName then
                        for nID, player in pairs(race.players) do
                            TriggerClientEvent("races:addRacer", source, nID, player.playerName)
                        end
                        if race.buyin > 0 then
                            Withdraw(source, race.buyin)
                            TriggerClientEvent("races:cash", source, GetFunds(source))
                            notifyPlayer(source, race.buyin .. " was withdrawn from your funds.\n")
                        end
                    end
                    race.numRacing = race.numRacing + 1
                    race.players[netID] = {
                        source = source,
                        playerName = playerName,
                        aiName = aiName,
                        numWaypointsPassed = -1,
                        data = -1,
                    }
                    TriggerClientEvent("races:join", source, rIndex, aiName, race.waypointCoords)
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
AddEventHandler("races:finish", function(rIndex, netID, aiName, numWaypointsPassed, finishTime, bestLapTime, vehicleName, altSource)
    local source = altSource or source
    if rIndex ~= nil and netID ~= nil and numWaypointsPassed ~= nil and finishTime ~= nil and bestLapTime ~= nil and vehicleName ~= nil then
        local race = races[rIndex]
        if race ~= nil then
            if STATE_RACING == race.state then
                if race.players[netID] ~= nil then
                    race.players[netID].numWaypointsPassed = numWaypointsPassed
                    race.players[netID].data = finishTime

                    local ownerJoined = false
                    for nID, player in pairs(race.players) do
                        if nil == player.aiName then
                            if player.source == rIndex then
                                ownerJoined = true
                            end
                            -- trigger races:finish event for non AI drivers
                            TriggerClientEvent("races:finish", player.source, rIndex, race.players[netID].playerName, finishTime, bestLapTime, vehicleName)
                            if nID ~= netID then
                                TriggerClientEvent("races:deleteRacer", player.source, netID)
                            end
                        end
                    end
                    if false == ownerJoined then
                            -- trigger races:finish event for AI drivers since owner did not join race
                            TriggerClientEvent("races:finish", rIndex, rIndex, race.players[netID].playerName, finishTime, bestLapTime, vehicleName)
                    end

                    race.results[#race.results + 1] = {
                        source = source,
                        playerName = race.players[netID].playerName,
                        aiName = aiName,
                        finishTime = finishTime,
                        bestLapTime = bestLapTime,
                        vehicleName = vehicleName
                    }

                    race.numRacing = race.numRacing - 1
                    if 0 == race.numRacing then
                        table.sort(race.results, function(p0, p1)
                            return
                                (p0.finishTime >= 0 and (-1 == p1.finishTime or p0.finishTime < p1.finishTime)) or
                                (-1 == p0.finishTime and -1 == p1.finishTime and (p0.bestLapTime >= 0 and (-1 == p1.bestLapTime or p0.bestLapTime < p1.bestLapTime)))
                        end)

                        if race.buyin > 0 then
                            local numRacers = #race.results
                            local numFinished = 0
                            local totalPool = numRacers * race.buyin
                            local pool = totalPool
                            local winnings = {}

                            for i, result in ipairs(race.results) do
                                winnings[i] = {payout = race.buyin, source = result.source}
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
                                if winning.payout > 0 then
                                    Deposit(winning.source, winning.payout)
                                    TriggerClientEvent("races:cash", winning.source, GetFunds(winning.source))
                                    notifyPlayer(winning.source, winning.payout .. " was deposited in your funds.\n")
                                end
                            end
                        end

                        for _, player in pairs(race.players) do
                            if nil == player.aiName then
                                TriggerClientEvent("races:results", player.source, rIndex, race.results)
                            end
                        end

                        saveResults(race)

                        if race.trackName ~= nil then
                            updateBestLapTimes(rIndex)
                        end

                        races[rIndex] = nil -- delete race after all players finish
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
AddEventHandler("races:report", function(rIndex, netID, numWaypointsPassed, distance)
    if rIndex ~= nil and netID ~= nil and numWaypointsPassed ~= nil and distance ~= nil then
        local race = races[rIndex]
        if race ~= nil then
            if race.players[netID] ~= nil then
                race.players[netID].numWaypointsPassed = numWaypointsPassed
                race.players[netID].data = distance
            else
                notifyPlayer(source, "Cannot report.  Not a member of this race.\n")
            end
        end
    else
        notifyPlayer(source, "Ignoring report event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:trackNames")
AddEventHandler("races:trackNames", function(isPublic, altSource)
    local source = altSource or source
    if isPublic ~= nil then
        local trackNames = {}

        local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
        if license ~= nil then
            local trackData = readData(trackDataFileName)
            if trackData ~= nil then
                local tracks = trackData[license]
                if tracks ~= nil then
                    for trackName in pairs(tracks) do
                        trackNames[#trackNames + 1] = trackName
                    end
                end
            else
                sendMessage(source, "Could not load track data.\n")
            end
        else
            sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        end

        TriggerClientEvent("races:trackNames", source, isPublic, trackNames)
    else
        sendMessage(source, "Ignoring list event.  Invalid parameters.\n")
   end
end)

RegisterNetEvent("races:aiGrpNames")
AddEventHandler("races:aiGrpNames", function(isPublic, altSource)
    local source = altSource or source
    if isPublic ~= nil then
        local grpNames = {}

        local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
        if license ~= nil then
            local aiGroupData = readData(aiGroupDataFileName)
            if aiGroupData ~= nil then
                local groups = aiGroupData[license]
                if groups ~= nil then
                    for grpName in pairs(groups) do
                        grpNames[#grpNames + 1] = grpName
                    end
                end
            else
                sendMessage(source, "Could not load AI group data.\n")
            end
        else
            sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        end

        TriggerClientEvent("races:aiGrpNames", source, isPublic, grpNames)
    else
        sendMessage(source, "Ignoring list AI groups event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:listNames")
AddEventHandler("races:listNames", function(isPublic, altSource)
    local source = altSource or source
    if isPublic ~= nil then
        local listNames = {}

        local license = true == isPublic and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
        if license ~= nil then
            local vehicleListData = readData(vehicleListDataFileName)
            if vehicleListData ~= nil then
                local lists = vehicleListData[license]
                if lists ~= nil then
                    for listName in pairs(lists) do
                        listNames[#listNames + 1] = listName
                    end
                end
            else
                sendMessage(source, "Could not load vehicle list data.\n")
            end
        else
            sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        end

        TriggerClientEvent("races:listNames", source, isPublic, listNames)
    else
        sendMessage(source, "Ignoring list vehicle lists event.  Invalid parameters.\n")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        for rIndex, race in pairs(races) do
            if STATE_RACING == race.state then
                local sortedPlayers = {} -- will contain players still racing and players that finished without DNF
                local complete = true

                -- race.players[netID] = {source, playerName, aiName, numWaypointsPassed, data, coord}
                for _, player in pairs(race.players) do
                    if -1 == player.numWaypointsPassed then -- player client hasn't updated numWaypointsPassed and data
                        complete = false
                        break
                    end

                    -- player.data will be travel distance to next waypoint or finish time; finish time will be -1 if player DNF
                    -- if -1 == player.data then player did not finish race - do not include in sortedPlayers
                    if player.data ~= -1 then
                        sortedPlayers[#sortedPlayers + 1] = {
                            source = player.source,
                            aiName = player.aiName,
                            numWaypointsPassed = player.numWaypointsPassed,
                            data = player.data
                        }
                    end
                end

                if true == complete then -- all player clients have updated numWaypointsPassed and data
                    table.sort(sortedPlayers, function(p0, p1)
                        return (p0.numWaypointsPassed > p1.numWaypointsPassed) or (p0.numWaypointsPassed == p1.numWaypointsPassed and p0.data < p1.data)
                    end)
                    -- players sorted into sortedPlayers table
                    for position, sortedPlayer in pairs(sortedPlayers) do
                        if nil == sortedPlayer.aiName then
                            TriggerClientEvent("races:position", sortedPlayer.source, rIndex, position, #sortedPlayers)
                        end
                    end
                end
            end
        end
    end
end)
