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

local STATE_REGISTERING <const> = 0 -- registering race state
local STATE_RACING <const> = 1 -- racing state

local saveLog <const> = false -- flag indicating if certain events should be logged
local logFileName <const> = "log.txt" -- log filename

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

local allVehicles = readData("vehicles.json") or {} -- list of all vehicles
if 0 == #allVehicles then
    print("^1Warning!  The file 'vehicles.json' does not exist or is empty.^0")
else
    local exists = {}
    local list = {}
    for _, model in pairs(allVehicles) do
        if nil == exists[model] then
            exists[model] = true
            list[#list + 1] = model
        end
    end
    table.sort(list)
    allVehicles = list
end

local races = {} -- races[source] = {owner, access, trackName, buyin, laps, timeout, rtype, restrict, vclass, className, svehicle, recur, order, vehicleList, state, waypointCoords[] = {x, y, z, r}, numRacing, players[netID] = {source, playerName, aiName, numWaypointsPassed, data}, results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}}

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

local function getTrack(name)
    local track = readData(name .. ".json")
    if nil == track then
        print("getTrack: Could not load track '" .. name .. "'.")
        return nil
    elseif type(track) ~= "table" or type(track.waypointCoords) ~= "table" or type(track.bestLaps) ~= "table" then
        print("getTrack: track or track.waypointCoords or track.bestLaps not a table.")
        return nil
    elseif #track.waypointCoords < 2 then
        print("getTrack: Number of waypoints is less than 2.")
        return nil
    end

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
end

local function listTracks()
    local trackData = readData(trackDataFileName)
    if nil == trackData then
        print("Could not load track data.\n")
        return
    end

    local tracks = trackData["PUBLIC"]
    if nil == tracks then
        print("No saved public tracks.\n")
        return
    end

    local names = {}
    for name in pairs(tracks) do
        names[#names + 1] = name
    end
    if 0 == #names then
        print("No saved public tracks.\n")
        return
    end
    table.sort(names)

    local msg = "Saved public tracks:\n"
    for _, name in ipairs(names) do
        msg = msg .. name .. "\n"
    end
    print(msg)
end

local function export(name, withBLT)
    if nil == name then
        print("export: Name required.")
        return
    end

    local trackData = readData(trackDataFileName)
    if nil == trackData then
        print("export: Could not load track data.")
        return
    end

    local publicTracks = trackData["PUBLIC"]
    if nil == publicTracks then
        print("export: No public track data.")
        return
    end

    if nil == publicTracks[name] then
        print("export: Public track '" .. name .. "' not found.")
        return
    end

    local trackFileName = name .. ".json"
    if readData(trackFileName) ~= nil then
        print("export: '" .. trackFileName .. "' exists.  Remove or rename the existing file, then export again.")
        return
    end

    if false == withBLT then
        publicTracks[name].bestLaps = {}
    end

    if false == writeData(trackFileName, publicTracks[name]) then
        print("export: Could not write track data.")
        return
    end

    local msg = "export: Exported track '" .. name .. "' " .. (true == withBLT and "with" or "with out") .. " best lap times."
    print(msg)
    logMessage(msg)
end

local function import(name, withBLT)
    if nil == name then
        print("import: Name required.")
        return
    end

    local trackData = readData(trackDataFileName)
    if nil == trackData then
        print("import: Could not load track data.")
        return
    end

    local publicTracks = trackData["PUBLIC"] or {}
    if publicTracks[name] ~= nil then
        print("import: '" .. name .. "' already exists in the public tracks list.  Rename the file, then import with the new name.")
        return
    end

    local track = getTrack(name)
    if nil == track then
        print("import: Could not import '" .. name .. "'.")
        return
    end

    if false == withBLT then
        track.bestLaps = {}
    end

    publicTracks[name] = track

    trackData["PUBLIC"] = publicTracks

    if false == writeData(trackDataFileName, trackData) then
        print("import: Could not write track data.")
        return
    end

    local msg = "import: Imported track '" .. name .. "' " .. (true == withBLT and "with" or "with out") .. " best lap times."
    print(msg)
    logMessage(msg)
end

local function loadTrack(access, source, name)
    local license = "pub" == access and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if nil == license then
        notifyPlayer(source, "loadTrack: Could not get license for player source ID: " .. source .. "\n")
        return nil
    end

    local trackData = readData(trackDataFileName)
    if nil == trackData then
        notifyPlayer(source, "loadTrack: Could not load track data.\n")
        return nil
    end

    local tracks = trackData[license]
    if tracks ~= nil then
        return tracks[name]
    end

    return nil
end

local function saveTrack(access, source, name, track)
    local license = "pub" == access and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if nil == license then
        notifyPlayer(source, "saveTrack: Could not get license for player source ID: " .. source .. "\n")
        return false
    end

    local trackData = readData(trackDataFileName)
    if nil == trackData then
        notifyPlayer(source, "saveTrack: Could not load track data.\n")
        return false
    end

    local tracks = trackData[license] or {}

    tracks[name] = track

    trackData[license] = tracks

    if false == writeData(trackDataFileName, trackData) then
        notifyPlayer(source, "saveTrack: Could not write track data.\n")
        return false
    end

    return true
end

local function loadAIGroup(access, source, name)
    local license = "pub" == access and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if nil == license then
        notifyPlayer(source, "loadAIGroup: Could not get license for player source ID: " .. source .. "\n")
        return nil
    end

    local aiGroupData = readData(aiGroupDataFileName)
    if nil == aiGroupData then
        notifyPlayer(source, "loadAIGroup: Could not load AI group data.\n")
        return nil
    end

    local groups = aiGroupData[license]
    if groups ~= nil then
        return groups[name]
    end

    return nil
end

local function saveAIGroup(access, source, name, group)
    local license = "pub" == access and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if nil == license then
        notifyPlayer(source, "saveAIGroup: Could not get license for player source ID: " .. source .. "\n")
        return false
    end

    local aiGroupData = readData(aiGroupDataFileName)
    if nil == aiGroupData then
        notifyPlayer(source, "saveAIGroup: Could not load AI group data.\n")
        return false
    end

    local groups = aiGroupData[license] or {}

    groups[name] = group

    aiGroupData[license] = groups

    if false == writeData(aiGroupDataFileName, aiGroupData) then
        notifyPlayer(source, "saveAIGroup: Could not write AI group data.\n")
        return false
    end

    return true
end

local function loadVehicleList(access, source, name)
    local license = "pub" == access and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if nil == license then
        notifyPlayer(source, "loadVehicleList: Could not get license for player source ID: " .. source .. "\n")
        return nil
    end

    local vehicleListData = readData(vehicleListDataFileName)
    if nil == vehicleListData then
        notifyPlayer(source, "loadVehicleList: Could not load vehicle list data.\n")
        return nil
    end

    local lists = vehicleListData[license]
    if lists ~= nil then
        return lists[name]
    end

    return nil
end

local function saveVehicleList(access, source, name, vehicleList)
    local license = "pub" == access and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if nil == license then
        notifyPlayer(source, "saveVehicleList: Could not get license for player source ID: " .. source .. "\n")
        return false
    end

    local vehicleListData = readData(vehicleListDataFileName)
    if nil == vehicleListData then
        notifyPlayer(source, "saveVehicleList: Could not load vehicle list data.\n")
        return false
    end

    local lists = vehicleListData[license] or {}

    lists[name] = vehicleList

    vehicleListData[license] = lists

    if false == writeData(vehicleListDataFileName, vehicleListData) then
        notifyPlayer(source, "saveVehicleList: Could not write vehicle list data.\n")
        return false
    end

    return true
end

local function updateBestLapTimes(rIndex)
    local race = races[rIndex]

    local track = loadTrack(race.access, rIndex, race.trackName)
    if nil == track then -- saved track doesn't exist - deleted in middle of race
        notifyPlayer(rIndex, "Cannot update best lap times.  Track '" .. race.trackName .. "' has been deleted.\n")
        return
    end

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
    if false == saveTrack(race.access, rIndex, race.trackName, track) then
        notifyPlayer(rIndex, "Save error updating best lap times.\n")
    end
end

local function minutesSeconds(milliseconds)
    local seconds = milliseconds / 1000.0
    local minutes = math.floor(seconds / 60.0)

    seconds = seconds - minutes * 60.0

    return minutes, seconds
end

local function saveResults(race)
    local results = {}

    -- results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}
    for pos, result in ipairs(race.results) do
        local finishTime = "DNF"
        local bestLapTime = "DNF"
        if result.finishTime ~= -1 then
            local minutes, seconds = minutesSeconds(result.finishTime)
            finishTime = ("%02d:%05.2f"):format(minutes, seconds)
        end
        if result.bestLapTime ~= -1 then
            local minutes, seconds = minutesSeconds(result.bestLapTime)
            bestLapTime = ("%02d:%05.2f"):format(minutes, seconds)
        end
        results[#results + 1] = {
            position = pos,
            playerName = result.playerName,
            isAI = result.aiName ~= nil and "yes" or "no",
            finishTime = finishTime,
            bestLapTime = bestLapTime,
            vehicleName = result.vehicleName
        }
    end

    -- races[source] = {owner, access, trackName, buyin, laps, timeout, rtype, restrict, vclass, className, svehicle, recur, order, vehicleList, state, waypointCoords[] = {x, y, z, r}, numRacing, players[netID] = {source, playerName, aiName, numWaypointsPassed, data}, results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}}
    local raceResults = {
        owner = race.owner,
        access = race.access or "none",
        trackName = race.trackName or "unsaved",
        buyin = race.buyin,
        laps = race.laps,
        timeout = race.timeout,
        allowAI = race.allowAI,
        rtype = race.rtype or "norm",
        restrict = race.restrict or "none",
        class = race.className or "any",
        svehicle = race.svehicle or "any",
        recur = race.recur or "N/A",
        order = race.order or "N/A",
        results = results
    }

    local resultsFileName = "results_" .. race.owner .. ".json"
    if false == writeData(resultsFileName, raceResults) then
        print("Error writing file '" .. resultsFileName .. "'")
    end
end

local function getTrackNames(access, source)
    local license = "pub" == access and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if nil == license then
        sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        return {}
    end

    local trackData = readData(trackDataFileName)
    if nil == trackData then
        sendMessage(source, "Could not load track data.\n")
        return {}
    end

    local trackNames = {}
    local tracks = trackData[license]
    if tracks ~= nil then
        for trackName in pairs(tracks) do
            trackNames[#trackNames + 1] = trackName
        end
    end

    return trackNames
end

local function getGrpNames(access, source)
    local license = "pub" == access and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if nil == license then
        sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        return {}
    end

    local aiGroupData = readData(aiGroupDataFileName)
    if nil == aiGroupData then
        sendMessage(source, "Could not load AI group data.\n")
        return {}
    end

    local grpNames = {}
    local groups = aiGroupData[license]
    if groups ~= nil then
        for grpName in pairs(groups) do
            grpNames[#grpNames + 1] = grpName
        end
    end

    return grpNames
end

local function getListNames(access, source)
    local license = "pub" == access and "PUBLIC" or string.sub(GetPlayerIdentifier(source, 0), 9)
    if nil == license then
        sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        return {}
    end

    local vehicleListData = readData(vehicleListDataFileName)
    if nil == vehicleListData then
        sendMessage(source, "Could not load vehicle list data.\n")
        return {}
    end

    local listNames = {}
    local lists = vehicleListData[license]
    if lists ~= nil then
        for listName in pairs(lists) do
            listNames[#listNames + 1] = listName
        end
    end

    return listNames
end

local function round(f)
    return (f - math.floor(f) >= 0.5) and math.ceil(f) or math.floor(f)
end

RegisterCommand("races", function(_, args)
    if nil == args[1] then
        print(
            "Commands:\n" ..
            "races - display list of available races commands\n" ..
            "races list - list public tracks\n" ..
            "races export [name] - export public track saved as [name] without best lap times to file named '[name].json'\n" ..
            "races import [name] - import track file named '[name].json' into public tracks without best lap times\n" ..
            "races exportwblt [name] - export public track saved as [name] with best lap times to file named '[name].json'\n" ..
            "races importwblt [name] - import track file named '[name].json' into public tracks with best lap times\n"
        )
    elseif "list" == args[1] then
        listTracks()
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
        if races[source].buyin > 0 then -- assume no AI players since buyin > 0
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
    local exists = {}
    local list = {}
    for _, sound in pairs(sounds) do
        if nil == exists[sound.set] then
            exists[sound.set] = {}
        end
        if nil == exists[sound.set][sound.name] then
            exists[sound.set][sound.name] = true
            list[#list + 1] = {set = sound.set, name = sound.name}
        end
    end
    table.sort(list, function(p0, p1)
        return (p0.set < p1.set) or (p0.set == p1.set and p0.name < p1.name)
    end)
    return list
end

RegisterNetEvent("sounds0")
AddEventHandler("sounds0", function()
    local source = source
    -- https://wiki.gtanet.work/index.php?title=FrontEndSoundlist
    local filePath = "./resources/races/sounds/sounds.csv"
    local file, errMsg, errCode = io.open(filePath, "r")
    if fail == file then
        print("Error opening file '" .. filePath .. "' for read : '" .. errMsg .. "' : " .. errCode)
        return
    end
    local sounds = {}
    for line in file:lines() do
        local i = string.find(line, ",")
        if i ~= fail then
            sounds[#sounds + 1] = {set = string.upper(string.sub(line, i + 1, -1)), name = string.upper(string.sub(line, 1, i - 1))}
        else
            print(line)
        end
    end
    file:close()
    TriggerClientEvent("sounds", source, sortRemDup(sounds))
end)

RegisterNetEvent("sounds1")
AddEventHandler("sounds1", function()
    local source = source
    -- https://altv.stuyk.com/docs/articles/tables/frontend-sounds.html
    local filePath = "./resources/races/sounds/altv.stuyk.com.txt"
    local file, errMsg, errCode = io.open(filePath, "r")
    if fail == file then
        print("Error opening file '" .. filePath .. "' for read : '" .. errMsg .. "' : " .. errCode)
        return
    end
    local sounds = {}
    for line in file:lines() do
        local name, set = string.match(line, "(\t.*)(\t.*)")
        if name ~= nil and set ~= nil then
            sounds[#sounds + 1] = {set = string.upper(string.sub(set, 2, -1)), name = string.upper(string.sub(name, 2, -1))}
        else
            print(line)
        end
    end
    file:close()
    TriggerClientEvent("sounds", source, sortRemDup(sounds))
end)

RegisterNetEvent("vehicleHashes")
AddEventHandler("vehicleHashes", function()
    local source = source
    -- https://wiki.rage.mp/index.php?title=Vehicles
    local filePath = "./resources/races/vehicles/vehicleHashes from wiki.rage.mp.txt"
    local file, errMsg, errCode = io.open(filePath, "r")
    if fail == file then
        print("Error opening file '" .. filePath .. "' for read : '" .. errMsg .. "' : " .. errCode)
        return
    end
    local vehicles = {}
    for line in file:lines() do
        local i = string.find(line, ": ")
        if i ~= fail then
            vehicles[#vehicles + 1] = string.sub(line, 3, i - 1)
        else
            print(line)
        end
    end
    file:close()

    local exists = {}
    local list = {}
    for _, model in pairs(vehicles) do
        if nil == exists[model] then
            exists[model] = true
            list[#list + 1] = model
        end
    end
    table.sort(list)

    writeData("vehicles_latest.json", list)
    TriggerClientEvent("vehicleHashes", source, list)
end)
--]]

RegisterNetEvent("races:init")
AddEventHandler("races:init", function()
    local source = source

    TriggerClientEvent("races:initAllVehicles", source, allVehicles)

    -- if funds < 5000, set funds to 5000
    if GetFunds(source) < 5000 then
        SetFunds(source, 5000)
    end
    TriggerClientEvent("races:cash", source, GetFunds(source))

    -- register any races created before player joined
    for rIndex, race in pairs(races) do
        if STATE_REGISTERING == race.state then
            local rdata = {
                owner = race.owner,
                access = race.access,
                trackName = race.trackName,
                buyin = race.buyin,
                laps = race.laps,
                timeout = race.timeout,
                allowAI = race.allowAI,
                rtype = race.rtype,
                restrict = race.restrict,
                vclass = race.vclass,
                className = race.className,
                svehicle = race.svehicle,
                recur = race.recur,
                order = race.order,
                vehicleList = race.vehicleList
            }
            TriggerClientEvent("races:register", source, rIndex, race.waypointCoords[1], rdata)
        end
    end
end)

RegisterNetEvent("races:initPanels")
AddEventHandler("races:initPanels", function()
    local source = source

    TriggerClientEvent("races:updateTrackNames", source, "pub", getTrackNames("pub", source))
    TriggerClientEvent("races:updateTrackNames", source, "pvt", getTrackNames("pvt", source))
    TriggerClientEvent("races:updateAiGrpNames", source, "pub", getGrpNames("pub", source))
    TriggerClientEvent("races:updateAiGrpNames", source, "pvt", getGrpNames("pvt", source))
    TriggerClientEvent("races:updateListNames", source, "pub", getListNames("pub", source))
    TriggerClientEvent("races:updateListNames", source, "pvt", getListNames("pvt", source))
end)

RegisterNetEvent("races:load")
AddEventHandler("races:load", function(access, name)
    local source = source

    if nil == access or nil == name then
        sendMessage(source, "Ignoring load event.  Invalid parameters.\n")
        return
    end

    local track = loadTrack(access, source, name)
    if nil == track then
        sendMessage(source, "Cannot load.   " .. ("pub" == access and "Public" or "Private") .. " track '" .. name .. "' not found.\n")
        return
    end

    TriggerClientEvent("races:load", source, access, name, track.waypointCoords)
end)

RegisterNetEvent("races:save")
AddEventHandler("races:save", function(access, name, waypointCoords)
    local source = source

    if nil == access or nil == name or nil == waypointCoords then
        sendMessage(source, "Ignoring save event.  Invalid parameters.\n")
        return
    end

    if loadTrack(access, source, name) ~= nil then
        sendMessage(source, ("pub" == access and "Public" or "Private") .. " track '" .. name .. "' exists.  Use 'overwrite' command instead.\n")
        return
    elseif false == saveTrack(access, source, name, {waypointCoords = waypointCoords, bestLaps = {}}) then
        sendMessage(source, "Error saving " .. ("pub" == access and "public" or "private") .. " track '" .. name .. "'.\n")
        return
    end

    TriggerClientEvent("races:save", source, access, name)

    TriggerClientEvent("races:updateTrackNames", "pub" == access and -1 or source, access, getTrackNames(access, source))

    logMessage("'" .. GetPlayerName(source) .. "' saved " .. ("pub" == access and "public" or "private") .. " track '" .. name .. "'")
end)

RegisterNetEvent("races:overwrite")
AddEventHandler("races:overwrite", function(access, name, waypointCoords)
    local source = source

    if nil == access or nil == name or nil == waypointCoords then
        sendMessage(source, "Ignoring overwrite event.  Invalid parameters.\n")
        return
    end

    if nil == loadTrack(access, source, name) then
        sendMessage(source, ("pub" == access and "Public" or "Private") .. " track '" .. name .. "' does not exist.  Use 'save' command instead.\n")
        return
    elseif false == saveTrack(access, source, name, {waypointCoords = waypointCoords, bestLaps = {}}) then
        sendMessage(source, "Error overwriting " .. ("pub" == access and "public" or "private") .. " track '" .. name .. "'.\n")
        return
    end

    TriggerClientEvent("races:overwrite", source, access, name)

    logMessage("'" .. GetPlayerName(source) .. "' overwrote " .. ("pub" == access and "public" or "private") .. " track '" .. name .. "'")
end)

RegisterNetEvent("races:delete")
AddEventHandler("races:delete", function(access, name)
    local source = source

    if nil == access or nil == name then
        sendMessage(source, "Ignoring delete event.  Invalid parameters.\n")
        return
    end

    if nil == loadTrack(access, source, name) then
        sendMessage(source, "Cannot delete.  " .. ("pub" == access and "Public" or "Private") .. " track '" .. name .. "' not found.\n")
        return
    elseif false == saveTrack(access, source, name, nil) then
        sendMessage(source, "Error deleting " .. ("pub" == access and "public" or "private") .. " track '" .. name .. "'.\n")
        return
    end

    TriggerClientEvent("races:updateTrackNames", "pub" == access and -1 or source, access, getTrackNames(access, source))

    sendMessage(source, "Deleted " .. ("pub" == access and "public" or "private") .. " track '" .. name .. "'.\n")

    logMessage("'" .. GetPlayerName(source) .. "' deleted " .. ("pub" == access and "public" or "private") .. " track '" .. name .. "'")
end)

RegisterNetEvent("races:list")
AddEventHandler("races:list", function(access)
    local source = source

    if nil == access then
        sendMessage(source, "Ignoring list event.  Invalid parameters.\n")
        return
    end

    local trackNames = getTrackNames(access, source)
    if 0 == #trackNames then
        sendMessage(source, "No saved " .. ("pub" == access and "public" or "private") .. " tracks.\n")
        return
    end
    table.sort(trackNames)

    local msg = "Saved " .. ("pub" == access and "public" or "private") .. " tracks:\n"
    for _, trackName in ipairs(trackNames) do
        msg = msg .. trackName .. "\n"
    end
    sendMessage(source, msg)
end)

RegisterNetEvent("races:blt")
AddEventHandler("races:blt", function(access, name)
    local source = source

    if nil == access or nil == name then
        sendMessage(source, "Ignoring blt event.  Invalid parameters.\n")
        return
    end

    local track = loadTrack(access, source, name)
    if nil == track then
        sendMessage(source, "Cannot list best lap times.   " .. ("pub" == access and "Public" or "Private") .. " track '" .. name .. "' not found.\n")
        return
    end

    TriggerClientEvent("races:blt", source, access, name, track.bestLaps)
end)

RegisterNetEvent("races:loadGrp")
AddEventHandler("races:loadGrp", function(access, name)
    local source = source

    if nil == access or nil == name then
        sendMessage(source, "Ignoring loadGrp event.  Invalid parameters.\n")
        return
    end

    local group = loadAIGroup(access, source, name)
    if nil == group then
        sendMessage(source, "Cannot load.   " .. ("pub" == access and "Public" or "Private") .. " AI group '" .. name .. "' not found.\n")
        return
    end

    TriggerClientEvent("races:loadGrp", source, access, name, group)
end)

RegisterNetEvent("races:saveGrp")
AddEventHandler("races:saveGrp", function(access, name, group)
    local source = source

    if nil == access or nil == name or nil == group then
        sendMessage(source, "Ignoring saveGrp event.  Invalid parameters.\n")
        return
    end

    if loadAIGroup(access, source, name) ~= nil then
        sendMessage(source, ("pub" == access and "Public" or "Private") .. " AI group '" .. name .. "' exists.  Use 'overwriteGrp' command instead.\n")
        return
    elseif false == saveAIGroup(access, source, name, group) then
        sendMessage(source, "Error saving " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'.\n")
        return
    end

    TriggerClientEvent("races:updateAiGrpNames", "pub" == access and -1 or source, access, getGrpNames(access, source))

    sendMessage(source, "Saved " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'.\n")

    logMessage("'" .. GetPlayerName(source) .. "' saved " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'")
end)

RegisterNetEvent("races:overwriteGrp")
AddEventHandler("races:overwriteGrp", function(access, name, group)
    local source = source

    if nil == access or nil == name or nil == group then
        sendMessage(source, "Ignoring overwriteGrp event.  Invalid parameters.\n")
        return
    end

    if nil == loadAIGroup(access, source, name) then
        sendMessage(source, ("pub" == access and "Public" or "Private") .. " AI group '" .. name .. "' does not exist.  Use 'saveGrp' command instead.\n")
        return
    elseif false == saveAIGroup(access, source, name, group) then
        sendMessage(source, "Error overwriting " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'.\n")
        return
    end

    sendMessage(source, "Overwrote " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'.\n")

    logMessage("'" .. GetPlayerName(source) .. "' overwrote " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'")
end)

RegisterNetEvent("races:deleteGrp")
AddEventHandler("races:deleteGrp", function(access, name)
    local source = source

    if nil == access or nil == name then
        sendMessage(source, "Ignoring deleteGrp event.  Invalid parameters.\n")
        return
    end

    if nil == loadAIGroup(access, source, name) then
        sendMessage(source, "Cannot delete.  " .. ("pub" == access and "Public" or "Private") .. " AI group '" .. name .. "' not found.\n")
        return
    elseif false == saveAIGroup(access, source, name, nil) then
        sendMessage(source, "Error deleting " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'.\n")
        return
    end

    TriggerClientEvent("races:updateAiGrpNames", "pub" == access and -1 or source, access, getGrpNames(access, source))

    sendMessage(source, "Deleted " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'.\n")

    logMessage("'" .. GetPlayerName(source) .. "' deleted " .. ("pub" == access and "public" or "private") .. " AI group '" .. name .. "'")
end)

RegisterNetEvent("races:listGrps")
AddEventHandler("races:listGrps", function(access)
    local source = source

    if nil == access then
        sendMessage(source, "Ignoring listGrps event.  Invalid parameters.\n")
        return
    end

    local grpNames = getGrpNames(access, source)
    if 0 == #grpNames then
        sendMessage(source, "No saved " .. ("pub" == access and "public" or "private") .. " AI groups.\n")
        return
    end
    table.sort(grpNames)

    local msg = "Saved " .. ("pub" == access and "public" or "private") .. " AI groups:\n"
    for _, grpName in ipairs(grpNames) do
        msg = msg .. grpName .. "\n"
    end
    sendMessage(source, msg)
end)

RegisterNetEvent("races:loadLst")
AddEventHandler("races:loadLst", function(access, name)
    local source = source

    if nil == access or nil == name then
        sendMessage(source, "Ignoring loadLst event.  Invalid parameters.\n")
        return
    end

    local list = loadVehicleList(access, source, name)
    if nil == list then
        sendMessage(source, "Cannot load.   " .. ("pub" == access and "Public" or "Private") .. " vehicle list '" .. name .. "' not found.\n")
        return
    end

    TriggerClientEvent("races:loadLst", source, access, name, list)
end)

RegisterNetEvent("races:saveLst")
AddEventHandler("races:saveLst", function(access, name, vehicleList)
    local source = source

    if nil == access or nil == name or nil == vehicleList then
        sendMessage(source, "Ignoring saveLst event.  Invalid parameters.\n")
        return
    end

    if loadVehicleList(access, source, name) ~= nil then
        sendMessage(source, ("pub" == access and "Public" or "Private") .. " vehicle list '" .. name .. "' exists.  Use 'overwriteLst' command instead.\n")
        return
    elseif false == saveVehicleList(access, source, name, vehicleList) then
        sendMessage(source, "Error saving " .. ("pub" == access and "public" or "private") .. " vehicle list '" .. name .. "'.\n")
        return
    end

    TriggerClientEvent("races:updateListNames", "pub" == access and -1 or source, access, getListNames(access, source))

    sendMessage(source, "Saved " .. ("pub" == access and "public" or "private") .. " vehicle list '" .. name .. "'.\n")

    logMessage("'" .. GetPlayerName(source) .. "' saved " .. ("pub" == access and "public" or "private") .. " vehicle list '" .. name .. "'")
end)

RegisterNetEvent("races:overwriteLst")
AddEventHandler("races:overwriteLst", function(access, name, vehicleList)
    local source = source

    if nil == access or nil == name or nil == vehicleList then
        sendMessage(source, "Ignoring overwriteLst event.  Invalid parameters.\n")
        return
    end

    if nil == loadVehicleList(access, source, name) then
        sendMessage(source, ("pub" == access and "Public" or "Private") .. " vehicle list '" .. name .. "' does not exist.  Use 'saveLst' command instead.\n")
        return
    elseif false == saveVehicleList(access, source, name, vehicleList) then
        sendMessage(source, "Error overwriting " .. ("pub" == access and "public" or "private") .. " vehicle list '" .. name .. "'.\n")
        return
    end

    sendMessage(source, "Overwrote " .. ("pub" == access and "public" or "private") .. " vehicle list '" .. name .. "'.\n")

    logMessage("'" .. GetPlayerName(source) .. "' overwrote " .. ("pub" == access and "public" or "private") .. " vehicle list '" .. name .. "'")
end)

RegisterNetEvent("races:deleteLst")
AddEventHandler("races:deleteLst", function(access, name)
    local source = source

    if nil == access or nil == name then
        sendMessage(source, "Ignoring deleteLst event.  Invalid parameters.\n")
        return
    end

    if nil == loadVehicleList(access, source, name) then
        sendMessage(source, "Cannot delete.  " .. ("pub" == access and "Public" or "Private") .. " vehicle list '" .. name .. "' not found.\n")
        return
    elseif false == saveVehicleList(access, source, name, nil) then
        sendMessage(source, "Error deleting " .. ("pub" == access and "public" or "private") .. " vehicle list '" .. name .. "'.\n")
        return
    end

    TriggerClientEvent("races:updateListNames", "pub" == access and -1 or source, access, getListNames(access, source))

    sendMessage(source, "Deleted " .. ("pub" == access and "public" or "private") .. " vehicle list '" .. name .. "'.\n")

    logMessage("'" .. GetPlayerName(source) .. "' deleted " .. ("pub" == access and "public" or "private") .. " vehicle list '" .. name .. "'")
end)

RegisterNetEvent("races:listLsts")
AddEventHandler("races:listLsts", function(access)
    local source = source

    if nil == access then
        sendMessage(source, "Ignoring listLsts event.  Invalid parameters.\n")
        return
    end

    local listNames = getListNames(access, source)
    if 0 == #listNames then
        sendMessage(source, "No saved " .. ("pub" == access and "public" or "private") .. " vehicle lists.\n")
        return
    end
    table.sort(listNames)

    local msg = "Saved " .. ("pub" == access and "public" or "private") .. " vehicle lists:\n"
    for _, listName in ipairs(listNames) do
        msg = msg .. listName .. "\n"
    end
    sendMessage(source, msg)
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(waypointCoords, rdata)
    local source = source

    if nil == waypointCoords or nil == rdata then
        sendMessage(source, "Ignoring register event.  Invalid parameters.\n")
        return
    end

    if races[source] ~= nil then
        if STATE_RACING == races[source].state then
            sendMessage(source, "Cannot register race.  Previous race in progress.\n")
        else
            sendMessage(source, "Cannot register race.  Previous race registered.  Unregister first.\n")
        end
        return
    end

    local invalidDistMsg = ""
    if false == distValid then
        rdata.buyin = 0
        invalidDistMsg = "Warning!  Prize distribution table is invalid.  There will be no prize payouts.\n"
    end

    local msg = "Registered race by '" .. rdata.owner .. "' using "

    if nil == rdata.trackName then
        msg = msg .. "unsaved track"
    else
        msg = msg .. ("pub" == rdata.access and "publicly" or "privately") .. " saved track '" .. rdata.trackName .. "'"
    end

    msg = msg .. (" : %d buy-in : %d lap(s) : %d timeout"):format(rdata.buyin, rdata.laps, rdata.timeout)

    if "yes" == rdata.allowAI then
        msg = msg .. " : AI allowed"
    end

    if "rest" == rdata.rtype then
        msg = msg .. " : using '" .. rdata.restrict .. "' vehicle"
    elseif "class" == rdata.rtype then
        msg = msg .. " : using " .. rdata.className.. " class vehicles"
    elseif "rand" == rdata.rtype then
        msg = msg .. " : using random "
        if rdata.vclass ~= nil then
            msg = msg .. rdata.className .. " class "
        end
        msg = msg .. "vehicles"

        if rdata.svehicle ~= nil then
            msg = msg .. " : start '" .. rdata.svehicle .. "'"
        end

        if "yes" == rdata.recur then
            msg = msg .. " : recurring"
        else
            msg = msg .. " : nonrecurring"
        end

        if "yes" == rdata.order then
            msg = msg .. " : ordered"
        else
            msg = msg .. " : unordered"
        end
    end

    msg = msg .. "\n" .. invalidDistMsg

    sendMessage(source, msg)

    races[source] = {
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
        state = STATE_REGISTERING,
        waypointCoords = waypointCoords,
        numRacing = 0,
        players = {},
        results = {}
    }

    TriggerClientEvent("races:register", -1, source, waypointCoords[1], rdata)
end)

RegisterNetEvent("races:unregister")
AddEventHandler("races:unregister", function()
    local source = source

    local race = races[source]
    if nil == race then
        sendMessage(source, "Cannot unregister.  No race registered.\n")
        return
    end

    for _, player in pairs(race.players) do
        if nil == player.aiName then
            TriggerClientEvent("races:deleteAllRacers", player.source)
            if race.buyin > 0 then
                Deposit(player.source, race.buyin)
                TriggerClientEvent("races:cash", player.source, GetFunds(player.source))
                notifyPlayer(player.source, race.buyin .. " was deposited in your funds.\n")
            end
        end
    end

    races[source] = nil

    TriggerClientEvent("races:unregister", -1, source)

    sendMessage(source, "Race unregistered.\n")
end)

RegisterNetEvent("races:start")
AddEventHandler("races:start", function(delay)
    local source = source

    if nil == delay then
        sendMessage(source, "Ignoring start event.  Invalid parameters.\n")
        return
    end

    local race = races[source]
    if nil == race then
        sendMessage(source, "Cannot start.  Race does not exist.\n")
        return
    elseif STATE_RACING == race.state then
        sendMessage(source, "Cannot start.  Race already in progress.\n")
        return
    elseif 0 == race.numRacing then
        sendMessage(source, "Cannot start.  No racers have joined race.\n")
        return
    end

    race.state = STATE_RACING

    local aiJoined = false
    local ownerJoined = false
    for _, player in pairs(race.players) do
        if nil == player.aiName then
            if player.source == source then
                ownerJoined = true
            end

            -- trigger races:start event for human drivers (also AI drivers if owner joined race)
            TriggerClientEvent("races:start", player.source, source, delay)
        else
            aiJoined = true
        end
    end
    if true == aiJoined and false == ownerJoined then
        -- trigger races:start event for AI drivers since owner did not join race
        TriggerClientEvent("races:start", source, source, delay)
    end

    TriggerClientEvent("races:hide", -1, source) -- hide race so no one else can join

    sendMessage(source, "Race started.\n")
end)

RegisterNetEvent("races:leave")
AddEventHandler("races:leave", function(rIndex, netID, aiName)
    local source = source

    if nil == rIndex or nil == netID then
        sendMessage(source, "Ignoring leave event.  Invalid parameters.\n")
        return
    end

    local race = races[rIndex]
    if nil == race then
        sendMessage(source, "Cannot leave.  Race does not exist.\n")
        return
    elseif STATE_RACING == race.state then
        -- player will trigger races:finish event
        sendMessage(source, "Cannot leave.  Race in progress.\n")
        return
    elseif nil == race.players[netID] then
        sendMessage(source, "Cannot leave.  Not a member of this race.\n")
        return
    end

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
end)

RegisterNetEvent("races:rivals")
AddEventHandler("races:rivals", function(rIndex)
    local source = source

    if nil == rIndex then
        sendMessage(source, "Ignoring rivals event.  Invalid parameters.\n")
        return
    end

    if nil == races[rIndex] then
        sendMessage(source, "Cannot list competitors.  Race does not exist.\n")
        return
    end

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

    if nil == rIndex or nil == netID then
        notifyPlayer(source, "Ignoring join event.  Invalid parameters.\n")
        return
    end

    local race = races[rIndex]
    if nil == race then
        notifyPlayer(source, "Cannot join.  Race does not exist.\n")
        return
    elseif nil == aiName and GetFunds(source) < race.buyin then
        notifyPlayer(source, "Cannot join.  Insufficient funds.\n")
        return
    elseif STATE_RACING == race.state then
        notifyPlayer(source, "Cannot join.  Race in progress.\n")
        return
    end

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
        data = -1
    }

    TriggerClientEvent("races:join", source, rIndex, aiName, race.waypointCoords)
end)

RegisterNetEvent("races:finish")
AddEventHandler("races:finish", function(rIndex, netID, aiName, numWaypointsPassed, finishTime, bestLapTime, vehicleName, altSource)
    local source = altSource or source

    if nil == rIndex or nil == netID or nil == numWaypointsPassed or nil == finishTime or nil == bestLapTime or nil == vehicleName then
        notifyPlayer(source, "Ignoring finish event.  Invalid parameters.\n")
        return
    end

    local race = races[rIndex]
    if nil == race then
        notifyPlayer(source, "Cannot finish.  Race does not exist.\n")
        return
    elseif STATE_REGISTERING == race.state then
        notifyPlayer(source, "Cannot finish.  Race not in progress.\n")
        return
    elseif nil == race.players[netID] then
        notifyPlayer(source, "Cannot finish.  Not a member of this race.\n")
        return
    end

    race.players[netID].numWaypointsPassed = numWaypointsPassed
    race.players[netID].data = finishTime

    local aiJoined = false
    local ownerJoined = false
    for nID, player in pairs(race.players) do
        if nil == player.aiName then
            if player.source == rIndex then
                ownerJoined = true
            end

            -- trigger races:finish event for human drivers (also AI drivers if owner joined race)
            TriggerClientEvent("races:finish", player.source, rIndex, race.players[netID].playerName, finishTime, bestLapTime, vehicleName)

            if nID ~= netID then
                TriggerClientEvent("races:deleteRacer", player.source, netID)
            end
        else
            aiJoined = true
        end
    end

    if true == aiJoined and false == ownerJoined then
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
    if race.numRacing > 0 then
        return
    end

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
end)

RegisterNetEvent("races:report")
AddEventHandler("races:report", function(rIndex, netID, numWaypointsPassed, distance)
    local source = source

    if nil == rIndex or nil == netID or nil == numWaypointsPassed or nil == distance then
        notifyPlayer(source, "Ignoring report event.  Invalid parameters.\n")
        return
    end

    local race = races[rIndex]
    if nil == race then
        return
    end

    if race.players[netID] ~= nil then
        race.players[netID].numWaypointsPassed = numWaypointsPassed
        race.players[netID].data = distance
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        for rIndex, race in pairs(races) do
            if STATE_RACING == race.state then
                local sortedPlayers = {} -- will contain players still racing and players that finished without DNF
                local complete = true

                -- race.players[netID] = {source, playerName, aiName, numWaypointsPassed, data}
                for _, player in pairs(race.players) do
                    if -1 == player.numWaypointsPassed then -- player client hasn't updated player.numWaypointsPassed and player.data
                        complete = false
                        break
                    end

                    -- player.data will be travel distance to next waypoint or finish time; finish time will be -1 if player DNF
                    -- if player DNF, do not include in sortedPlayers
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
