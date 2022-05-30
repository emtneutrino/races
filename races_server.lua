--[[

Copyright (c) 2022, Neil J. Tan
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

local function writeData(path, data)
    local file, errMsg, errCode = io.open(path, "w+")
    if file ~= fail then
        file:write(json.encode(data))
        file:close()
        return true
    else
        print("writeData: Error opening file '" .. path .. "' for write : '" .. errMsg .. "' : " .. errCode)
    end
    return false
end

local function readData(path)
    local data = nil
    local file, errMsg, errCode = io.open(path, "r")
    if file ~= fail then
        data = json.decode(file:read("a"))
        file:close()
    else
        print("readData: Error opening file '" .. path .. "' for read : '" .. errMsg .. "' : " .. errCode)
    end
    return data
end

local STATE_REGISTERING <const> = 0 -- registering race status
local STATE_RACING <const> = 1 -- racing race status

local ROLE_EDIT <const> = 1 -- edit tracks role
local ROLE_REGISTER <const> = 2 -- register races role
local ROLE_SPAWN <const> = 4 -- spawn vehicles role

local requirePermissionToEdit <const> = false -- flag indicating if permission is required to edit tracks
local requirePermissionToRegister <const> = false -- flag indicating if permission is required to register races
local requirePermissionToSpawn <const> = false -- flag indicating if permission is required to spawn vehicles

local requirePermissionBits <const> = -- bit flag indicating if permission is required to edit tracks, register races or spawn vehicles
    (true == requirePermissionToEdit and ROLE_EDIT or 0) |
    (true == requirePermissionToRegister and ROLE_REGISTER or 0) |
    (true == requirePermissionToSpawn and ROLE_SPAWN or 0)

local rolesDataFilePath <const> = "./resources/races/rolesData.json" -- roles data file path
if readData(rolesDataFilePath) == nil then
    writeData(rolesDataFilePath, {})
end

local aiGroupDataFilePath <const> = "./resources/races/aiGroupData.json" -- AI group data file path
if readData(aiGroupDataFilePath) == nil then
    writeData(aiGroupDataFilePath, {})
end

local raceDataFilePath <const> = "./resources/races/raceData.json" -- race data file path
if readData(raceDataFilePath) == nil then
    writeData(raceDataFilePath, {})
end

local saveLog <const> = false -- flag indicating if certain events should be logged
local logFilePath <const> = "./resources/races/log.txt" -- log file path

local randomVehicleFileName <const> = "random.txt" -- default file used for random races

local allVehicleFileName <const> = "vehicles.txt" -- list of all vehicles filename

local defaultRadius <const> = 5.0 -- default waypoint radius

local requests = {} -- requests[playerID] = {name, roleBit} - list of requests to edit tracks, register races and/or spawn vehicles

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

local function logMessage(msg)
    if true == saveLog then
        local file, errMsg, errCode = io.open(logFilePath, "a")
        if file ~= fail then
            file:write(os.date() .. " : " .. msg .. "\n")
            file:close()
        else
            print("logMessage: Error opening file '" .. logFilePath .. "' for append : '" .. errMsg .. "' : " .. errCode)
        end
    end
end

local function getTrack(trackName)
    local track = readData("./resources/races/" .. trackName .. ".json")
    if track ~= nil then
        if type(track) == "table" and type(track.waypointCoords) == "table" and type(track.bestLaps) == "table" then
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
                print("getTrack: number of waypoints is less than 2.")
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
        local raceData = readData(raceDataFilePath)
        if raceData ~= nil then
            local publicTracks = raceData["PUBLIC"]
            if publicTracks ~= nil then
                if publicTracks[trackName] ~= nil then
                    local trackFilePath = "./resources/races/" .. trackName .. ".json"
                    local file = io.open(trackFilePath, "r")
                    if fail == file then
                        if false == withBLT then
                            publicTracks[trackName].bestLaps = {}
                        end
                        if true == writeData(trackFilePath, publicTracks[trackName]) then
                            local msg = "export: Exported track '" .. trackName .. "'."
                            print(msg)
                            logMessage(msg)
                        else
                            print("export: Could not export track '" .. trackName .. "'.")
                        end
                    else
                        file:close()
                        print("export: '" .. trackFilePath .. "' exists.  Remove or rename the existing file, then export again.")
                    end
                else
                    print("export: No public track named '" .. trackName .. "'.")
                end
            else
                print("export: No public track data.")
            end
        else
            print("export: Could not load race data.")
        end
    else
        print("export: Name required.")
    end
end

local function import(trackName, withBLT)
    if trackName ~= nil then
        local raceData = readData(raceDataFilePath)
        if raceData ~= nil then
            local publicTracks = raceData["PUBLIC"] ~= nil and raceData["PUBLIC"] or {}
            if nil == publicTracks[trackName] then
                local track = getTrack(trackName)
                if track ~= nil then
                    if false == withBLT then
                        track.bestLaps = {}
                    end
                    publicTracks[trackName] = track
                    raceData["PUBLIC"] = publicTracks
                    if true == writeData(raceDataFilePath, raceData) then
                        local msg = "import: Imported track '" .. trackName .. "'."
                        print(msg)
                        logMessage(msg)
                    else
                        print("import: Could not import '" .. trackName .. "'.")
                    end
                else
                    print("import: Could not import '" .. trackName .. "'.")
                end
            else
                print("import: '" .. trackName .. "' already exists in the public tracks list.  Rename the file, then import with the new name.")
            end
        else
            print("import: Could not load race data.")
        end
    else
        print("import: Name required.")
    end
end

local function listReqs()
    --requests[playerID] = {name, roleBit}
    for playerID, request in pairs(requests) do
        local role = "INVALID ROLE"
        if ROLE_EDIT == request.roleBit then
            role = "EDIT"
        elseif ROLE_REGISTER == request.roleBit then
            role = "REGISTER"
        elseif ROLE_SPAWN == request.roleBit then
            role = "SPAWN"
        end
        print(playerID .. " : " .. request.name .. " : " .. role)
    end
end

local function approve(playerID)
    if playerID ~= nil then
        local name = GetPlayerName(playerID)
        if name ~= nil then
            playerID = tonumber(playerID)
            if requests[playerID] ~= nil then
                local license = GetPlayerIdentifier(playerID, 0)
                if license ~= nil then
                    local rolesData = readData(rolesDataFilePath)
                    if rolesData ~= nil then
                        license = string.sub(license, 9)
                        --requests[playerID] = {name, roleBit}
                        if rolesData[license] ~= nil then
                            rolesData[license].roleBits = rolesData[license].roleBits | requests[playerID].roleBit
                        else
                            rolesData[license] = {name = name, roleBits = requests[playerID].roleBit}
                        end
                        if true == writeData(rolesDataFilePath, rolesData) then
                            local roleType = "SPAWN"
                            if ROLE_EDIT == requests[playerID].roleBit then
                                roleType = "EDIT"
                            elseif ROLE_REGISTER == requests[playerID].roleBit then
                                roleType = "REGISTER"
                            end
                            local msg = "approve: Request by '" .. name .. "' for " .. roleType .. " role approved."
                            print(msg)
                            logMessage(msg)
                            TriggerClientEvent("races:roles", playerID, rolesData[license].roleBits)
                            notifyPlayer(playerID, "Request for " .. roleType .. " role approved.\n")
                            requests[playerID] = nil
                        else
                            print("approve: Could not approve role.")
                        end
                    else
                        print("approve: Could not load race data.")
                    end
                else
                    print("approve: Could not get license for player source ID: " .. playerID)
                end
            else
                print("approve: Player did not request approval.")
            end
        else
            print("approve: Invalid player ID.")
        end
    else
        print("approve: Player ID required.")
    end
end

local function deny(playerID)
    if playerID ~= nil then
        local name = GetPlayerName(playerID)
        if name ~= nil then
            playerID = tonumber(playerID)
            if requests[playerID] ~= nil then
                local roleType = "SPAWN"
                if ROLE_EDIT == requests[playerID].roleBit then
                    roleType = "EDIT"
                elseif ROLE_REGISTER == requests[playerID].roleBit then
                    roleType = "REGISTER"
                end
                local msg = "deny: Request by '" .. name .. "' for " .. roleType .. " role denied."
                print(msg)
                logMessage(msg)
                notifyPlayer(playerID, "Request for " .. roleType .. " role denied.\n")
                requests[playerID] = nil
            else
                print("deny: Player did not request approval.")
            end
        else
            print("deny: Invalid player ID.")
        end
    else
        print("deny: Player ID required.")
    end
end

local function listRoles()
    print("Permission to edit tracks: " .. (true == requirePermissionToEdit and "required" or "NOT required"))
    print("Permission to register races: " .. (true == requirePermissionToRegister and "required" or "NOT required"))
    print("Permission to spawn vehicles: " .. (true == requirePermissionToSpawn and "required" or "NOT required"))
    -- rolesData[license] = {name, roleBits}
    local rolesData = readData(rolesDataFilePath)
    if rolesData ~= nil then
        local rolesFound = false
        for _, role in pairs(rolesData) do
            rolesFound = true
            local roleNames = ""
            if 0 == role.roleBits & ~(ROLE_EDIT | ROLE_REGISTER | ROLE_SPAWN) then
                if role.roleBits & ROLE_EDIT ~= 0 then
                    roleNames = " EDIT"
                end
                if role.roleBits & ROLE_REGISTER ~= 0 then
                    roleNames = roleNames .. " REGISTER"
                end
                if role.roleBits & ROLE_SPAWN ~= 0 then
                    roleNames = roleNames .. " SPAWN"
                end
            else
                roleNames = "INVALID ROLE"
            end
            print(role.name .. " :" .. roleNames)
        end
        if false == rolesFound then
            print("listRoles: No roles found.")
        end
    else
        print("listRoles: Could not load roles data.")
    end
end

local function removeRole(playerName, roleName)
    if playerName ~= nil then
        local rolesData = readData(rolesDataFilePath)
        if rolesData ~= nil then
            local roleBits = (ROLE_EDIT | ROLE_REGISTER | ROLE_SPAWN)
            local roleType = ""
            if "edit" == roleName then
                roleBits = ROLE_EDIT
                roleType = "EDIT"
            elseif "register" == roleName then
                roleBits = ROLE_REGISTER
                roleType = "REGISTER"
            elseif "spawn" == roleName then
                roleBits = ROLE_SPAWN
                roleType = "SPAWN"
            elseif roleName ~= nil then
                print("removeRole: Invalid role.")
                return
            end
            local lic = nil
            for license, role in pairs(rolesData) do
                if role.name == playerName then
                    lic = license
                    if 0 == role.roleBits & roleBits then
                        print("removeRole: Role was not assigned.")
                        return
                    end
                    rolesData[lic].roleBits = rolesData[lic].roleBits & ~roleBits
                    break
                end
            end
            if lic ~= nil then
                if roleBits & ROLE_REGISTER ~= 0 then
                    for _, rIndex in pairs(GetPlayers()) do
                        local license = GetPlayerIdentifier(rIndex, 0)
                        if license ~= nil then
                            if string.sub(license, 9) == lic then
                                rIndex = tonumber(rIndex)
                                if races[rIndex] ~= nil and STATE_REGISTERING == races[rIndex].state then
                                    if races[rIndex].buyin > 0 then
                                        for _, player in pairs(races[rIndex].players) do
                                            if player.aiName ~= nil then -- NO AI DRIVERS BECAUSE races[rIndex].buyin > 0
                                                Deposit(player.source, races[rIndex].buyin)
                                                notifyPlayer(player.source, races[rIndex].buyin .. " was deposited in your funds.\n")
                                            end
                                        end
                                    end
                                    races[rIndex] = nil
                                    TriggerClientEvent("races:unregister", -1, rIndex)
                                end
                                TriggerClientEvent("races:roles", rIndex, rolesData[lic].roleBits)
                                break
                            end
                        else
                            print("removeRole: Could not get license for player source ID: " .. rIndex)
                        end
                    end
                end
                local msg = ""
                if 0 == rolesData[lic].roleBits then
                    rolesData[lic] = nil
                    msg = "removeRole: All '" .. playerName .. "' roles removed."
                else
                    msg = "removeRole: '" .. playerName .. "' role " .. roleType .. " removed."
                end
                if true == writeData(rolesDataFilePath, rolesData) then
                    print(msg)
                    logMessage(msg)
                else
                    print("removeRole: Could not remove role.")
                end
            else
                print("removeRole: '" .. playerName .. "' not found.")
            end
        else
            print("removeRole: Could not load roles data.")
        end
    else
        print("removeRole: Name required.")
    end
end

local function updateRaceData()
    local raceData = readData(raceDataFilePath)
    if raceData ~= nil then
        local update = false
        local newRaceData = {}
        for license, tracks in pairs(raceData) do
            local newTracks = {}
            for trackName, track in pairs(tracks) do
                local newWaypointCoords = {}
                for i, waypointCoord in ipairs(track.waypointCoords) do
                    local coordRad = waypointCoord
                    if nil == waypointCoord.r then
                        coordRad.r = defaultRadius
                        update = true
                    end
                    newWaypointCoords[i] = coordRad
                end
                if true == update then
                    newTracks[trackName] = {waypointCoords = newWaypointCoords, bestLaps = track.bestLaps}
                end
            end
            if true == update then
                newRaceData[license] = newTracks
            end
        end
        if true == update then
            local updatedRaceDataFilePath = "./resources/races/raceData_updated.json"
            if true == writeData(updatedRaceDataFilePath, newRaceData) then
                local msg = "updateRaceData: raceData.json updated to current format in '" .. updatedRaceDataFilePath .. "'."
                print(msg)
                logMessage(msg)
            else
                print("updateRaceData: Could not update raceData.json.")
            end
        else
            print("updateRaceData: raceData.json not updated.")
        end
    else
        print("updateRaceData: Could not load race data.")
    end
end

local function updateTrack(trackName)
    if trackName ~= nil then
        local track = readData("./resources/races/" .. trackName .. ".json")
        if track ~= nil then
            if type(track) == "table" and type(track.waypointCoords) == "table" and type(track.bestLaps) == "table" then
                if #track.waypointCoords > 1 then
                    local update = false
                    local newWaypointCoords = {}
                    for i, waypointCoord in ipairs(track.waypointCoords) do
                        if type(waypointCoord) ~= "table" or type(waypointCoord.x) ~= "number" or type(waypointCoord.y) ~= "number" or type(waypointCoord.z) ~= "number" then
                            print("updateTrack: waypointCoord not a table or waypointCoord.x or waypointCoord.y or waypointCoord.z not a number.")
                            return
                        end
                        local coordRad = waypointCoord
                        if nil == waypointCoord.r then
                            update = true
                            coordRad.r = defaultRadius
                        elseif type(waypointCoord.r) ~= "number" then
                            print("updateTrack: waypointCoord.r not a number.")
                            return
                        end
                        newWaypointCoords[i] = coordRad
                    end

                    if true == update then
                        for _, bestLap in ipairs(track.bestLaps) do
                            if type(bestLap) ~= "table" or type(bestLap.playerName) ~= "string" or type(bestLap.bestLapTime) ~= "number" or type(bestLap.vehicleName) ~= "string" then
                                print("updateTrack: bestLap not a table or bestLap.playerName not a string or bestLap.bestLapTime not a number or bestLap.vehicleName not a string.")
                                return
                            end
                        end

                        local trackFilePath = "./resources/races/" .. trackName .. "_updated.json"
                        if true == writeData(trackFilePath, {waypointCoords = newWaypointCoords, bestLaps = track.bestLaps}) then
                            local msg = "updateTrack: '" .. trackName .. ".json' updated to current format in '" .. trackFilePath .. "'."
                            print(msg)
                            logMessage(msg)
                        else
                            print("updateTrack: Could not update track.")
                        end
                    else
                        print("updateTrack: '" .. trackName .. ".json' not updated.")
                    end
                else
                    print("updateTrack: number of waypoints is less than 2.")
                end
            else
                print("updateTrack: track or track.waypointCoords or track.bestLaps not a table.")
            end
        else
            print("updateTrack: Could not load track data.")
        end
    else
        print("updateTrack: Name required.")
    end
end

local function loadTrack(isPublic, source, trackName)
    local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)
    if license ~= nil then
        local raceData = readData(raceDataFilePath)
        if raceData ~= nil then
            if license ~= "PUBLIC" then
                license = string.sub(license, 9)
            end
            local tracks = raceData[license]
            if tracks ~= nil then
                return tracks[trackName]
            end
        else
            notifyPlayer(source, "loadTrack: Could not load race data.\n")
        end
    else
        notifyPlayer(source, "loadTrack: Could not get license for player source ID: " .. source .. "\n")
    end
    return nil
end

local function saveTrack(isPublic, source, trackName, track)
    local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)
    if license ~= nil then
        local raceData = readData(raceDataFilePath)
        if raceData ~= nil then
            if license ~= "PUBLIC" then
                license = string.sub(license, 9)
            end
            local tracks = raceData[license] ~= nil and raceData[license] or {}
            tracks[trackName] = track
            raceData[license] = tracks
            if true == writeData(raceDataFilePath, raceData) then
                return true
            else
                notifyPlayer(source, "saveTrack: Could not write race data.\n")
            end
        else
            notifyPlayer(source, "saveTrack: Could not load race data.\n")
        end
    else
        notifyPlayer(source, "saveTrack: Could not get license for player source ID: " .. source .. "\n")
    end
    return false
end

local function loadAIGroup(isPublic, source, name)
    local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)
    if license ~= nil then
        local aiGroupData = readData(aiGroupDataFilePath)
        if aiGroupData ~= nil then
            if license ~= "PUBLIC" then
                license = string.sub(license, 9)
            end
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
    local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)
    if license ~= nil then
        local aiGroupData = readData(aiGroupDataFilePath)
        if aiGroupData ~= nil then
            if license ~= "PUBLIC" then
                license = string.sub(license, 9)
            end
            local groups = aiGroupData[license] ~= nil and aiGroupData[license] or {}
            groups[name] = group
            aiGroupData[license] = groups
            if true == writeData(aiGroupDataFilePath, aiGroupData) then
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

local function loadVehicleFile(source, vehicleFileName)
    local vehicleFilePath = "./resources/races/" .. vehicleFileName
    local vehicles = {}
    local file, errMsg, errCode = io.open(vehicleFilePath, "r")
    if file ~= fail then
        for vehicle in file:lines() do
            if string.len(vehicle) > 0 then
                vehicles[#vehicles + 1] = vehicle
            end
        end
    else
        notifyPlayer(source, "Error opening file '" .. vehicleFilePath .. "' for read : '" .. errMsg .. "' : " .. errCode)
    end

    return vehicles
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
    local track = loadTrack(races[rIndex].isPublic, rIndex, races[rIndex].trackName)
    if track ~= nil then -- saved track still exists - not deleted in middle of race
        local bestLaps = track.bestLaps
        for _, result in pairs(races[rIndex].results) do
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
        if false == saveTrack(races[rIndex].isPublic, rIndex, races[rIndex].trackName, track) then
            notifyPlayer(rIndex, "Save error updating best lap times.\n")
        end
    else
        notifyPlayer(rIndex, "Cannot save best lap times.  Track '" .. races[rIndex].trackName .. "' has been deleted.\n")
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
    local msg = "Race using "
    if nil == race.trackName then
        msg = msg .. "unsaved track "
    else
        msg = msg .. (true == race.isPublic and "publicly" or "privately") .. " saved track '" .. race.trackName .. "' "
    end
    msg = msg .. ("registered by %s : %d buy-in : %d lap(s)"):format(race.owner, race.buyin, race.laps)
    if "yes" == race.allowAI then
        msg = msg .. " : AI allowed"
    end
    if "rest" == race.rtype then
        msg = msg .. " : using '" .. race.restrict .. "' vehicle"
    elseif "class" == race.rtype then
        msg = msg .. " : using " .. getClassName(race.vclass) .. " vehicle class"
    elseif "rand" == race.rtype then
        msg = msg .. " : using random "
        if race.vclass ~= nil then
            msg = msg .. getClassName(race.vclass) .. " vehicle class"
        else
            msg = msg .. "vehicles"
        end
        if race.svehicle ~= nil then
            msg = msg .. " : '" .. race.svehicle .. "'"
        end
    end
    msg = msg .. "\n"
    if #race.results > 0 then
        -- results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}
        msg = msg .. "Results:\n"
        for pos, result in ipairs(race.results) do
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
        msg = msg .. "No results.\n"
    end
    local resultsFilePath = "./resources/races/results_" .. race.owner .. ".txt"
    local file, errMsg, errCode = io.open(resultsFilePath, "w+")
    if file ~= fail then
        file:write(msg)
        file:close()
    else
        print("Error opening file '" .. resultsFilePath .. "' for write : '" .. errMsg .. "' : " .. errCode)
    end
end

local function round(f)
    return (f - math.floor(f) >= 0.5) and math.ceil(f) or math.floor(f)
end

local function getRoleBits(source)
    local roleBits = (ROLE_EDIT | ROLE_REGISTER | ROLE_SPAWN) & ~requirePermissionBits
    local rolesData = readData(rolesDataFilePath)
    if rolesData ~= nil then
        local license = GetPlayerIdentifier(source, 0)
        if license ~= nil then
            license = string.sub(license, 9)
            if rolesData[license] ~= nil then
                return rolesData[license].roleBits | roleBits
            end
        else
            print("getRoleBits: Could not get license for player source ID: " .. source)
        end
    else
        print("getRoleBits: Could not load roles data.")
    end
    return roleBits
end

RegisterCommand("races", function(_, args)
    if nil == args[1] then
        local msg = "Commands:\n"
        msg = msg .. "races - display list of available races commands\n"
        msg = msg .. "races export [name] - export public track saved as [name] without best lap times to file named '[name].json'\n"
        msg = msg .. "races import [name] - import track file named '[name].json' into public tracks without best lap times\n"
        msg = msg .. "races exportwblt [name] - export public track saved as [name] with best lap times to file named '[name].json'\n"
        msg = msg .. "races importwblt [name] - import track file named '[name].json' into public tracks with best lap times\n"
        msg = msg .. "races listReqs - list requests to edit tracks, register races and spawn vehicles\n"
        msg = msg .. "races approve [playerID] - approve request of [playerID] to edit tracks, register races or spawn vehicles\n"
        msg = msg .. "races deny [playerID] - deny request of [playerID] to edit tracks, register races or spawn vehicles\n"
        msg = msg .. "races listRoles - list approved players' roles\n"
        msg = msg .. "races removeRole [name] (role) - remove player [name]'s (role) = {edit, register, spawn} role; otherwise remove all roles if (role) is not specified\n"
        msg = msg .. "races updateRaceData - update 'raceData.json' to new format\n"
        msg = msg .. "races updateTrack [name] - update exported track '[name].json' to new format\n"
        print(msg)
    elseif "export" == args[1] then
        export(args[2], false)
    elseif "import" == args[1] then
        import(args[2], false)
    elseif "exportwblt" == args[1] then
        export(args[2], true)
    elseif "importwblt" == args[1] then
        import(args[2], true)
    elseif "listReqs" == args[1] then
        listReqs()
    elseif "approve" == args[1] then
        approve(args[2])
    elseif "deny" == args[1] then
        deny(args[2])
    elseif "listRoles" == args[1] then
        listRoles()
    elseif "removeRole" == args[1] then
        removeRole(args[2], args[3])
    elseif "updateRaceData" == args[1] then
        updateRaceData()
    elseif "updateTrack" == args[1] then
        updateTrack(args[2])
    else
        print("Unknown command.")
    end
end, true)

AddEventHandler("playerDropped", function()
    local source = source

    -- remove dropped player's bank account
    Remove(source)

    -- unregister race registered by dropped player that has not started
    if races[source] ~= nil and STATE_REGISTERING == races[source].state then
        if races[source].buyin > 0 then
            for _, player in pairs(races[source].players) do
                if player.aiName ~= nil then -- NO AI DRIVERS BECAUSE races[source].buyin > 0
                    Deposit(player.source, races[source].buyin)
                    notifyPlayer(player.source, races[source].buyin .. " was deposited in your funds.\n")
                end
            end
        end
        races[source] = nil
        TriggerClientEvent("races:unregister", -1, source)
    end

    -- make sure this is last code block in function because of early return if player found in race
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

    TriggerClientEvent("races:roles", source, getRoleBits(source))

    -- if funds < 5000, set funds to 5000
    if GetFunds(source) < 5000 then
        SetFunds(source, 5000)
    end

    -- register any races created before player joined
    for rIndex, race in pairs(races) do
        if STATE_REGISTERING == race.state then
            local rdata = {rtype = race.rtype, restrict = race.restrict, filename = race.filename, vclass = race.vclass, svehicle = race.svehicle}
            TriggerClientEvent("races:register", source, rIndex, race.waypointCoords[1], race.isPublic, race.trackName, race.owner, race.buyin, race.laps, race.timeout, race.allowAI, race.vehicleList, rdata)
        end
    end
end)

RegisterNetEvent("races:request")
AddEventHandler("races:request", function(roleBit)
    local source = source
    if roleBit ~= nil then
        if ROLE_EDIT == roleBit or ROLE_REGISTER == roleBit or ROLE_SPAWN == roleBit then
            if nil == requests[source] then
                if roleBit & requirePermissionBits ~= 0 then
                    local license = GetPlayerIdentifier(source, 0)
                    if license ~= nil then
                        local rolesData = readData(rolesDataFilePath)
                        if rolesData ~= nil then
                            local roleType = "SPAWN"
                            if ROLE_EDIT == roleBit then
                                roleType = "EDIT"
                            elseif ROLE_REGISTER == roleBit then
                                roleType = "REGISTER"
                            end
                            license = string.sub(license, 9)
                            if nil == rolesData[license] then
                                requests[source] = {name = GetPlayerName(source), roleBit = roleBit}
                                sendMessage(source, "Request for " .. roleType .. " role submitted.")
                            else
                                if 0 == rolesData[license].roleBits & roleBit then
                                    requests[source] = {name = GetPlayerName(source), roleBit = roleBit}
                                    sendMessage(source, "Request for " .. roleType .. " role submitted.")
                                else
                                    sendMessage(source, "Request for " .. roleType .. " role already approved.\n")
                                end
                            end
                        else
                            sendMessage("Could not load roles data.")
                        end
                    else
                        sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
                    end
                else
                    sendMessage(source, "Permission not required.\n")
                end
            else
                sendMessage(source, "Previous request is pending approval.")
            end
        else
            sendMessage(source, "Invalid role.\n")
        end
    else
        sendMessage(source, "Ignoring request event.  Invalid parameters.\n")
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
        sendMessage(source, "Ignoring load event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:save")
AddEventHandler("races:save", function(isPublic, trackName, waypointCoords)
    local source = source
    if 0 == getRoleBits(source) & ROLE_EDIT then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil and trackName ~= nil and waypointCoords ~= nil then
        local track = loadTrack(isPublic, source, trackName)
        if nil == track then
            track = {waypointCoords = waypointCoords, bestLaps = {}}
            if true == saveTrack(isPublic, source, trackName, track) then
                TriggerClientEvent("races:save", source, isPublic, trackName)
                logMessage("'" .. GetPlayerName(source) .. "' saved " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'")
            else
                sendMessage(source, "Error saving '" .. trackName .. "'.\n")
            end
        else
            sendMessage(source, (true == isPublic and "Public" or "Private") .. " track '" .. trackName .. "' exists.  Use 'overwrite' command instead.\n")
        end
    else
        sendMessage(source, "Ignoring save event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:overwrite")
AddEventHandler("races:overwrite", function(isPublic, trackName, waypointCoords)
    local source = source
    if 0 == getRoleBits(source) & ROLE_EDIT then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil and trackName ~= nil and waypointCoords ~= nil then
        local track = loadTrack(isPublic, source, trackName)
        if track ~= nil then
            track = {waypointCoords = waypointCoords, bestLaps = {}}
            if true == saveTrack(isPublic, source, trackName, track) then
                TriggerClientEvent("races:overwrite", source, isPublic, trackName)
                logMessage("'" .. GetPlayerName(source) .. "' overwrote " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'")
            else
                sendMessage(source, "Error overwriting '" .. trackName .. "'.\n")
            end
        else
            sendMessage(source, (true == isPublic and "Public" or "Private") .. " track '" .. trackName .. "' does not exist.  Use 'save' command instead.\n")
        end
    else
        sendMessage(source, "Ignoring overwrite event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:delete")
AddEventHandler("races:delete", function(isPublic, trackName)
    local source = source
    if 0 == getRoleBits(source) & ROLE_EDIT then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil and trackName ~= nil then
        local track = loadTrack(isPublic, source, trackName)
        if track ~= nil then
            if true == saveTrack(isPublic, source, trackName, nil) then
                TriggerClientEvent("races:delete", source, isPublic)
                sendMessage(source, "Deleted " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' deleted " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'")
            else
                sendMessage(source, "Error deleting '" .. trackName .. "'.\n")
            end
        else
            sendMessage(source, "Cannot delete.  " .. (true == isPublic and "Public" or "Private") .. " track '" .. trackName .. "' not found.\n")
        end
    else
        sendMessage(source, "Ignoring delete event.  Invalid parameters.\n")
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
        local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)
        if license ~= nil then
            local raceData = readData(raceDataFilePath)
            if raceData ~= nil then
                if license ~= "PUBLIC" then
                    license = string.sub(license, 9)
                end
                local tracks = raceData[license]
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
                sendMessage(source, "Could not load race data.\n")
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
    if 0 == getRoleBits(source) & ROLE_REGISTER then
        sendMessage(source, "Permission required.\n")
        return
    end
    if waypointCoords ~= nil and isPublic ~= nil and buyin ~= nil and laps ~= nil and timeout ~= nil and allowAI ~= nil and rdata ~= nil then
        if buyin >= 0 then
            if laps > 0 then
                if timeout >= 0 then
                    if "yes" == allowAI or "no" == allowAI then
                        if nil == races[source] then
                            local registerRace = true
                            local umsg = ""
                            local vehicleList = {}
                            if "rest" == rdata.rtype then
                                if nil == rdata.restrict then
                                    registerRace = false
                                    sendMessage(source, "Cannot register.  Invalid restricted vehicle.\n")
                                else
                                    umsg = " : using '" .. rdata.restrict .. "' vehicle"
                                end
                            elseif "class" == rdata.rtype then
                                if nil == rdata.vclass or rdata.vclass < -1 or rdata.vclass > 21 then
                                    registerRace = false
                                    sendMessage(source, "Cannot register.  Invalid vehicle class.\n")
                                else
                                    umsg = " : using " .. getClassName(rdata.vclass) .. " vehicle class"
                                    if -1 == rdata.vclass then
                                        if nil == rdata.filename then
                                            registerRace = false
                                            sendMessage(source, "Cannot register.  Invalid file name.\n")
                                        else
                                            vehicleList = loadVehicleFile(source, rdata.filename)
                                            if #vehicleList == 0 then
                                                registerRace = false
                                                sendMessage(source, "Cannot register.  No vehicles loaded from " .. rdata.filename .. ".\n")
                                            end
                                        end
                                    end
                                end
                            elseif "rand" == rdata.rtype then
                                buyin = 0
                                if nil == rdata.filename then
                                    rdata.filename = randomVehicleFileName
                                end
                                vehicleList = loadVehicleFile(source, rdata.filename)
                                if #vehicleList == 0 then
                                    registerRace = false
                                    sendMessage(source, "Cannot register.  No vehicles loaded from " .. rdata.filename .. ".\n")
                                else
                                    umsg = " : using random "
                                    if rdata.vclass ~= nil then
                                        if (rdata.vclass < 0 or rdata.vclass > 21) then
                                            registerRace = false
                                            sendMessage(source, "Cannot register.  Invalid vehicle class.\n")
                                        else
                                            umsg = umsg .. getClassName(rdata.vclass) .. " vehicle class"
                                        end
                                    else
                                        umsg = umsg .. "vehicles"
                                    end
                                    if true == registerRace and rdata.svehicle ~= nil then
                                        umsg = umsg .. " : '" .. rdata.svehicle .. "'"
                                    end
                                end
                            elseif rdata.rtype ~= nil then
                                registerRace = false
                                sendMessage(source, "Cannot register.  Unknown race type.\n")
                            end
                            if true == registerRace then
                                local owner = GetPlayerName(source)
                                local msg = "Registered race using "
                                if nil == trackName then
                                    msg = msg .. "unsaved track "
                                else
                                    msg = msg .. (true == isPublic and "publicly" or "privately") .. " saved track '" .. trackName .. "' "
                                end
                                msg = msg .. ("by %s : %d buy-in : %d lap(s)"):format(owner, buyin, laps)
                                if "yes" == allowAI then
                                    msg = msg .. " : AI allowed"
                                end
                                msg = msg .. umsg .. "\n"
                                if false == distValid then
                                    msg = msg .. "Prize distribution table is invalid\n"
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
                                    vehicleList = vehicleList,
                                    numRacing = 0,
                                    players = {},
                                    results = {}
                                }
                                TriggerClientEvent("races:register", -1, source, waypointCoords[1], isPublic, trackName, owner, buyin, laps, timeout, allowAI, vehicleList, rdata)
                            end
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
    if 0 == getRoleBits(source) & ROLE_REGISTER then
        sendMessage(source, "Permission required.\n")
        return
    end
    if races[source] ~= nil then
        if races[source].buyin > 0 then
            for _, player in pairs(races[source].players) do
                if player.aiName ~= nil then -- NO AI DRIVERS BECAUSE races[source].buyin > 0
                    Deposit(player.source, races[source].buyin)
                    notifyPlayer(player.source, races[source].buyin .. " was deposited in your funds.\n")
                end
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
    if 0 == getRoleBits(source) & ROLE_REGISTER then
        sendMessage(source, "Permission required.\n")
        return
    end
    if delay ~= nil then
        if races[source] ~= nil then
            if STATE_REGISTERING == races[source].state then
                if delay >= 5 then
                    if races[source].numRacing > 0 then
                        races[source].state = STATE_RACING
                        local aiStart = false
                        local sourceJoined = false
                        for _, player in pairs(races[source].players) do
                            if nil == player.aiName then
                                -- trigger races:start event for non AI drivers
                                TriggerClientEvent("races:start", player.source, source, delay)
                                if player.source == source then
                                    sourceJoined = true
                                end
                            else
                                aiStart = true
                            end
                        end
                        if true == aiStart and false == sourceJoined then
                            -- trigger races:start event for AI drivers at source since source did not join race
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
                sendMessage(source, "Cannot start.  Race in progress.\n")
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
    if 0 == getRoleBits(source) & ROLE_REGISTER then
        sendMessage(source, "Permission required.\n")
        return
    end
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
    if 0 == getRoleBits(source) & ROLE_REGISTER then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil and name ~= nil and group ~= nil then
        if loadAIGroup(isPublic, source, name) == nil then
            if true == saveAIGroup(isPublic, source, name, group) then
                TriggerClientEvent("races:updateGrp", source, isPublic)
                sendMessage(source, "Saved " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' saved " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'")
            else
                sendMessage(source, "Error saving '" .. name .. "'.\n")
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
    if 0 == getRoleBits(source) & ROLE_REGISTER then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil and name ~= nil and group ~= nil then
        if loadAIGroup(isPublic, source, name) ~= nil then
            if true == saveAIGroup(isPublic, source, name, group) then
                sendMessage(source, "Overwrote " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' overwrote " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'")
            else
                sendMessage(source, "Error overwriting '" .. name .. "'.\n")
            end
        else
            sendMessage(source, (true == isPublic and "Public" or "Private") .. " AI group '" .. name .. "' does not exist.  Use 'saveGrp' command instead.\n")
        end
    else
        sendMessage(source, "Ignoring save AI group event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:deleteGrp")
AddEventHandler("races:deleteGrp", function(isPublic, name)
    local source = source
    if 0 == getRoleBits(source) & ROLE_REGISTER then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil and name ~= nil then
        local group = loadAIGroup(isPublic, source, name)
        if group ~= nil then
            if true == saveAIGroup(isPublic, source, name, nil) then
                TriggerClientEvent("races:updateGrp", source, isPublic)
                sendMessage(source, "Deleted " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'.\n")
                logMessage("'" .. GetPlayerName(source) .. "' deleted " .. (true == isPublic and "public" or "private") .. " AI group '" .. name .. "'")
            else
                sendMessage(source, "Error deleting '" .. trackName .. "'.\n")
            end
        else
            sendMessage(source, "Cannot delete.  " .. (true == isPublic and "Public" or "Private") .. " AI group '" .. name .. "' not found.\n")
        end
    else
        sendMessage(source, "Ignoring delete AI group event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:listGrp")
AddEventHandler("races:listGrp", function(isPublic)
    local source = source
    if 0 == getRoleBits(source) & ROLE_REGISTER then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil then
        local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)
        if license ~= nil then
            local aiGroupData = readData(aiGroupDataFilePath)
            if aiGroupData ~= nil then
                if license ~= "PUBLIC" then
                    license = string.sub(license, 9)
                end
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

RegisterNetEvent("races:leave")
AddEventHandler("races:leave", function(rIndex, netID, aiName)
    local source = source
    if rIndex ~= nil and netID ~= nil then
        if races[rIndex] ~= nil then
            if STATE_REGISTERING == races[rIndex].state then
                if races[rIndex].players[netID] ~= nil then
                    races[rIndex].players[netID] = nil
                    races[rIndex].numRacing = races[rIndex].numRacing - 1
                    if races[rIndex].buyin > 0 and nil == aiName then
                        Deposit(source, races[rIndex].buyin)
                        sendMessage(source, races[rIndex].buyin .. " was deposited in your funds.\n")
                    end
                    for nID, player in pairs(races[rIndex].players) do
                        if player.aiName ~= nil then -- don't need to check nID == netID because player removed from table already
                            TriggerClientEvent("races:delRacer", player.source, netID)
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
            if races[rIndex].players[source] ~= nil then
                local names = {}
                for i, player in pairs(races[rIndex].players) do
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
    local vehicleList = loadVehicleFile(source, allVehicleFileName)
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
AddEventHandler("races:join", function(rIndex, netID, aiName)
    local source = source
    if rIndex ~= nil and netID ~= nil then
        if races[rIndex] ~= nil then
            if (nil == aiName and GetFunds(source) >= races[rIndex].buyin) or aiName ~= nil then
                if STATE_REGISTERING == races[rIndex].state then
                    local playerName = aiName ~= nil and ("(AI) " .. aiName) or GetPlayerName(source)
                    for nID, player in pairs(races[rIndex].players) do
                        if nil == player.aiName then
                            TriggerClientEvent("races:addRacer", player.source, netID, playerName)
                        end
                    end
                    if nil == aiName then
                        for nID, player in pairs(races[rIndex].players) do
                            TriggerClientEvent("races:addRacer", source, nID, player.playerName)
                        end
                        if races[rIndex].buyin > 0 then
                            Withdraw(source, races[rIndex].buyin)
                            notifyPlayer(source, races[rIndex].buyin .. " was withdrawn from your funds.\n")
                        end
                    end
                    races[rIndex].numRacing = races[rIndex].numRacing + 1
                    races[rIndex].players[netID] = {
                        source = source,
                        playerName = playerName,
                        aiName = aiName,
                        numWaypointsPassed = -1,
                        data = -1,
                    }
                    TriggerClientEvent("races:join", source, rIndex, aiName, races[rIndex].waypointCoords)
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
    local source = altSource ~= nil and altSource or source
    if rIndex ~= nil and netID ~= nil and numWaypointsPassed ~= nil and finishTime ~= nil and bestLapTime ~= nil and vehicleName ~= nil then
        local race = races[rIndex]
        if race ~= nil then
            if STATE_RACING == race.state then
                if race.players[netID] ~= nil then
                    race.players[netID].numWaypointsPassed = numWaypointsPassed
                    race.players[netID].data = finishTime

                    for nID, player in pairs(race.players) do
                        if nil == player.aiName then
                            TriggerClientEvent("races:finish", player.source, rIndex, race.players[netID].playerName, finishTime, bestLapTime, vehicleName)
                        end
                        if nID ~= netID then
                            TriggerClientEvent("races:delRacer", player.source, netID)
                        end
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

                        if true == distValid and race.rtype ~= "rand" and "no" == race.allowAI then
                            local numRacers = #race.results
                            local numFinished = 0
                            local totalPool = numRacers * race.buyin
                            local pool = totalPool
                            local winnings = {}

                            local winningsRL = {}
                            for _, result in pairs(race.results) do
                                winningsRL[result.source] = race.buyin
                            end

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
                                winningsRL[winning.source] = winning.payout
                            end

                            for _, player in pairs(race.players) do
                                if winningsRL[player.source] > 0 then
                                    if player.aiName ~= nil then -- NO AI DRIVERS BECAUSE race.allowAI == "no"
                                        Deposit(player.source, winningsRL[player.source])
                                        notifyPlayer(player.source, winningsRL[player.source] .. " was deposited in your funds.\n")
                                    end
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
AddEventHandler("races:report", function(rIndex, netID, aiName, numWaypointsPassed, distance)
    if rIndex ~= nil and netID ~= nil and numWaypointsPassed ~= nil and distance ~= nil then
        if races[rIndex] ~= nil then
            if races[rIndex].players[netID] ~= nil then
                races[rIndex].players[netID].numWaypointsPassed = numWaypointsPassed
                races[rIndex].players[netID].data = distance
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

RegisterNetEvent("races:trackNames")
AddEventHandler("races:trackNames", function(isPublic)
    local source = source
    if isPublic ~= nil then
        local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)
        if license ~= nil then
            local raceData = readData(raceDataFilePath)
            if raceData ~= nil then
                if license ~= "PUBLIC" then
                    license = string.sub(license, 9)
                end
                local tracks = raceData[license]
                if tracks ~= nil then
                    local trackNames = {}
                    for trackName in pairs(tracks) do
                        trackNames[#trackNames + 1] = trackName
                    end
                    table.sort(trackNames)
                    TriggerClientEvent("races:trackNames", source, isPublic, trackNames)
                else
                    sendMessage(source, "No saved " .. (true == isPublic and "public" or "private") .. " tracks.\n")
                end
            else
                sendMessage(source, "Could not load race data.\n")
            end
        else
            sendMessage(source, "Could not get license for player source ID: " .. source .. "\n")
        end
    else
        sendMessage(source, "Ignoring list event.  Invalid parameters.\n")
   end
end)

RegisterNetEvent("races:aiGrpNames")
AddEventHandler("races:aiGrpNames", function(isPublic)
    local source = source
    if isPublic ~= nil then
        local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)
        if license ~= nil then
            local aiGroupData = readData(aiGroupDataFilePath)
            if aiGroupData ~= nil then
                if license ~= "PUBLIC" then
                    license = string.sub(license, 9)
                end
                local groups = aiGroupData[license]
                if groups ~= nil then
                    local grpNames = {}
                    for grpName in pairs(groups) do
                        grpNames[#grpNames + 1] = grpName
                    end
                    table.sort(grpNames)
                    TriggerClientEvent("races:aiGrpNames", source, isPublic, grpNames)
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

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        for rIndex, race in pairs(races) do
            if STATE_RACING == race.state then
                local sortedPlayers = {} -- will contain players still racing and players that finished without DNF
                local complete = true

                -- race.players[netID] = {source, playerName, aiName, numWaypointsPassed, data, coord}
                for _, player in pairs(race.players) do
                    if -1 == player.numWaypointsPassed then -- player client hasn't updated numWaypointsPassed, data and coord
                        complete = false
                        break
                    end

                    -- player.data will be travel distance to next waypoint or finish time; finish time will be -1 if player DNF
                    -- if player.data == -1 then player did not finish race - do not include in sortedPlayers
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
