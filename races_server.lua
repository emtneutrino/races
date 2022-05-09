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

local STATE_REGISTERING <const> = 0
local STATE_RACING <const> = 1

local raceDataFile <const> = "./resources/races/raceData.json"

local randomVehicleFile <const> = "random.txt" -- default file used for random races

local allVehicleFile <const> = "vehicles.txt" -- list of all vehicles filename

local defaultRadius <const> = 5.0 -- default waypoint radius

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

local ROLE_EDIT <const> = 1 -- edit tracks role
local ROLE_REGISTER <const> = 2 -- register races role
local ROLE_SPAWN <const> = 4 -- spawn vehicles role

local requirePermissionToEdit <const> = false -- flag indicating if permission is required to edit tracks
local requirePermissionToRegister <const> = false -- flag indicating if permission is required to register races
local requirePermissionToSpawn <const> = false -- flag indicating if permission is required to spawn vehicles

local requirePermissionBits <const> =
    (true == requirePermissionToEdit and ROLE_EDIT or 0) |
    (true == requirePermissionToRegister and ROLE_REGISTER or 0) |
    (true == requirePermissionToSpawn and ROLE_SPAWN or 0)

local rolesDataFile <const> = "./resources/races/roles.json"
local roles = {} -- roles[license] = {name, roleBits} - list of players approved to edit tracks, register races and/or spawn vehicles
if requirePermissionBits ~= 0 then
    local file = io.open(rolesDataFile, "r")
    if file ~= fail then
        roles = json.decode(file:read("a"))
        file:close()
    end
end

local saveLog <const> = false
local logFile <const> = "./resources/races/log.txt"

local requests = {} -- requests[playerID] = {name, roleBit} - list of requests to edit tracks, register races and/or spawn vehicles

local races = {} -- races[playerID] = {state, waypointCoords[] = {x, y, z, r}, isPublic, trackName, owner, buyin, laps, timeout, rtype, restrict, vclass, svehicle, vehicleList, numRacing, players[playerID] = {playerName, aiName, numWaypointsPassed, data, coord}, results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}}

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
        local file, errMsg, errCode = io.open(logFile, "a")
        if file ~= fail then
            file:write(os.date() .. " : " .. msg .. "\n")
            file:close()
        else
            print("logMessage: Error opening file '" .. logFile .. "' for append : '" .. errMsg .. "' : " .. errCode)
        end
    end
end

local function getTrack(trackName)
    local trackFile = "./resources/races/" .. trackName .. ".json"
    local file, errMsg, errCode = io.open(trackFile, "r")
    if fail == file then
        print("getTrack: Error opening file '" .. trackFile .. "' for read : '" .. errMsg .. "' : " .. errCode)
        return nil
    end

    local track = json.decode(file:read("a"))
    file:close()

    if type(track) ~= "table" or type(track.waypointCoords) ~= "table" or type(track.bestLaps) ~= "table" then
        print("getTrack: track or track.waypointCoords or track.bestLaps not a table.")
        return nil
    end

    if #track.waypointCoords < 2 then
        print("getTrack: number of waypoints is less than 2.")
        return nil
    end

    for _, waypoint in ipairs(track.waypointCoords) do
        if type(waypoint) ~= "table" or type(waypoint.x) ~= "number" or type(waypoint.y) ~= "number" or type(waypoint.z) ~= "number" or type(waypoint.r) ~= "number" then
            print("getTrack: waypoint not a table or waypoint.x or waypoint.y or waypoint.z or waypoint.r not a number.")
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

local function export(trackName, withBLT)
    if trackName ~= nil then
        local file, errMsg, errCode = io.open(raceDataFile, "r")
        if file ~= fail then
            local raceData = json.decode(file:read("a"))
            file:close()
            if raceData ~= nil then
                local publicTracks = raceData["PUBLIC"]
                if publicTracks ~= nil then
                    if publicTracks[trackName] ~= nil then
                        local trackFile = "./resources/races/" .. trackName .. ".json"
                        file = io.open(trackFile, "r")
                        if fail == file then
                            file, errMsg, errCode = io.open(trackFile, "w+")
                            if file ~= fail then
                                if false == withBLT then
                                    publicTracks[trackName].bestLaps = {}
                                end
                                file:write(json.encode(publicTracks[trackName]))
                                file:close()
                                local msg = "Exported '" .. trackName .. "'."
                                print(msg)
                                logMessage(msg)
                            else
                                print("export: Error opening file '" .. trackFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
                            end
                        else
                            file:close()
                            print("export: '" .. trackFile .. "' exists. Remove or rename the existing file, then export again.")
                        end
                    else
                        print("export: No public track named '" .. trackName .. "'.")
                    end
                else
                    print("export: No public track data.")
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

local function import(trackName, withBLT)
    if trackName ~= nil then
        local file, errMsg, errCode = io.open(raceDataFile, "r")
        if file ~= fail then
            local raceData = json.decode(file:read("a"))
            file:close()
            if raceData ~= nil then
                local publicTracks = raceData["PUBLIC"]
                if publicTracks ~= nil then
                    if nil == publicTracks[trackName] then
                        local track = getTrack(trackName)
                        if track ~= nil then
                            file, errMsg, errCode = io.open(raceDataFile, "w+")
                            if file ~= fail then
                                if false == withBLT then
                                    track.bestLaps = {}
                                end
                                publicTracks[trackName] = track
                                raceData["PUBLIC"] = publicTracks
                                file:write(json.encode(raceData))
                                file:close()
                                local msg = "Imported '" .. trackName .. "'."
                                print(msg)
                                logMessage(msg)
                            else
                                print("import: Error opening file '" .. raceDataFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
                            end
                        else
                            print("import: Could not import '" .. trackName .. "'.")
                        end
                    else
                        print("import: '" .. trackName .. "' already exists in the public tracks list.  Rename the file, then import with the new name.")
                    end
                else
                    print("import: No public track data.")
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
        print(playerID .. ":" .. request.name .. ":" .. role)
    end
end

local function approve(playerID)
    if playerID ~= nil then
        local name = GetPlayerName(playerID)
        if name ~= nil then
            if requests[tonumber(playerID)] ~= nil then
                local license = GetPlayerIdentifier(playerID, 0)
                if license ~= nil then
                    license = string.sub(license, 9)
                    --requests[playerID] = {name, roleBit}
                    if roles[license] ~= nil then
                        roles[license].roleBits = roles[license].roleBits | requests[tonumber(playerID)].roleBit
                    else
                        roles[license] = {name = name, roleBits = requests[tonumber(playerID)].roleBit}
                    end
                    local file, errMsg, errCode = io.open(rolesDataFile, "w+")
                    if file ~= fail then
                        file:write(json.encode(roles))
                        file:close()
                        local roleType = "SPAWN"
                        if ROLE_EDIT == requests[tonumber(playerID)].roleBit then
                            roleType = "EDIT"
                        elseif ROLE_REGISTER == requests[tonumber(playerID)].roleBit then
                            roleType = "REGISTER"
                        end
                        local msg = "approve: Request by '" .. name .. "' for " .. roleType .. " role approved."
                        print(msg)
                        logMessage(msg)
                        TriggerClientEvent("races:roles", playerID, roles[license].roleBits)
                        notifyPlayer(playerID, "Request for " .. roleType .. " role approved.\n")
                        requests[tonumber(playerID)] = nil
                    else
                        print("approve: Error opening file '" .. rolesDataFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
                    end
                else
                    print("approve: Could not get license.")
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
            if requests[tonumber(playerID)] ~= nil then
                local roleType = "SPAWN"
                if ROLE_EDIT == requests[tonumber(playerID)].roleBit then
                    roleType = "EDIT"
                elseif ROLE_REGISTER == requests[tonumber(playerID)].roleBit then
                    roleType = "REGISTER"
                end
                local msg = "deny: Request by '" .. name .. "' for " .. roleType .. " role denied."
                print(msg)
                logMessage(msg)
                notifyPlayer(playerID, "Request for " .. roleType .. " role denied.\n")
                requests[tonumber(playerID)] = nil
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
    --roles[license] = {name, roleBits}
    print("Permission to edit tracks: " .. (true == requirePermissionToEdit and "required" or "NOT required"))
    print("Permission to register races: " .. (true == requirePermissionToRegister and "required" or "NOT required"))
    print("Permission to spawn vehicles: " .. (true == requirePermissionToSpawn and "required" or "NOT required"))
    for _, role in pairs(roles) do
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
        print(role.name .. ":" .. roleNames)
    end
end

local function removeRole(playerName, roleName)
    if playerName ~= nil then
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
        for license, role in pairs(roles) do
            if role.name == playerName then
                lic = license
                if 0 == role.roleBits & roleBits then
                    print("removeRole: Role was not assigned.")
                    return
                end
                roles[lic].roleBits = roles[lic].roleBits & ~roleBits
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
                                    for i in pairs(races[rIndex].players) do
                                        Deposit(i, races[rIndex].buyin)
                                        notifyPlayer(i, races[rIndex].buyin .. " was deposited in your funds.\n")
                                    end
                                end
                                races[rIndex] = nil
                                TriggerClientEvent("races:unregister", -1, rIndex)
                            end
                            TriggerClientEvent("races:roles", rIndex, roles[lic].roleBits)
                            break
                        end
                    else
                        print("removeRole: Could not get license for player index '" .. rIndex .. "'.")
                    end
                end
            end
            local file, errMsg, errCode = io.open(rolesDataFile, "w+")
            if file ~= fail then
                file:write(json.encode(roles))
                file:close()
                local msg = ""
                if 0 == roles[lic].roleBits then
                    roles[lic] = nil
                    msg = "removeRole: All '" .. playerName .. "' roles removed."
                else
                    msg = "removeRole: '" .. playerName .. "' role " .. roleType .. " removed."
                end
                print(msg)
                logMessage(msg)
            else
                print("removeRole: Error opening file '" .. rolesDataFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
            end
        else
            print("removeRole: '" .. playerName .. "' not found.")
        end
    else
        print("removeRole: Name required.")
    end
end

local function updateRaceData()
    local file, errMsg, errCode = io.open(raceDataFile, "r")
    if file ~= fail then
        local raceData = json.decode(file:read("a"))
        file:close()
        if raceData ~= nil then
            local update = false
            local newRaceData = {}
            for license, tracks in pairs(raceData) do
                local newTracks = {}
                for trackName, track in pairs(tracks) do
                    local newWaypointCoords = {}
                    for _, waypointCoord in ipairs(track.waypointCoords) do
                        if nil == waypointCoord.r then
                            update = true
                            newWaypointCoords[#newWaypointCoords + 1] = {x = waypointCoord.x, y = waypointCoord.y, z = waypointCoord.z, r = defaultRadius}
                        end
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
                local updatedRaceDataFile = "./resources/races/raceData_updated.json"
                file, errMsg, errCode = io.open(updatedRaceDataFile, "w+")
                if file ~= fail then
                    file:write(json.encode(newRaceData))
                    file:close()
                    local msg = "updateRaceData: raceData.json updated to current format in '" .. updatedRaceDataFile .. "'."
                    print(msg)
                    logMessage(msg)
                else
                    print("updateRaceData: Error opening file '" .. updatedRaceDataFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
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

local function updateTrack(trackName)
    if nil == trackName then
        print("updateTrack: Name required.")
        return
    end

    local update = false
    local trackFile = "./resources/races/" .. trackName .. ".json"
    local file, errMsg, errCode = io.open(trackFile, "r")
    if fail == file then
        print("updateTrack: Error opening file '" .. trackFile .. "' for read : '" .. errMsg .. "' : " .. errCode)
        return
    end

    local track = json.decode(file:read("a"))
    file:close()

    if type(track) ~= "table" or type(track.waypointCoords) ~= "table" or type(track.bestLaps) ~= "table" then
        print("updateTrack: track or track.waypointCoords or track.bestLaps not a table.")
        return
    end

    if #track.waypointCoords < 2 then
        print("updateTrack: number of waypoints is less than 2.")
        return
    end

    local newWaypointCoords = {}
    for _, waypoint in ipairs(track.waypointCoords) do
        if type(waypoint) ~= "table" or type(waypoint.x) ~= "number" or type(waypoint.y) ~= "number" or type(waypoint.z) ~= "number" then
            print("updateTrack: waypoint not a table or waypoint.x or waypoint.y or waypoint.z not a number.")
            return
        end
        if nil == waypoint.r then
            update = true
            newWaypointCoords[#newWaypointCoords + 1] = {x = waypoint.x, y = waypoint.y, z = waypoint.z, r = defaultRadius}
        elseif type(waypoint.r) == "number" then
            newWaypointCoords[#newWaypointCoords + 1] = {x = waypoint.x, y = waypoint.y, z = waypoint.z, r = waypoint.r}
        else
            print("updateTrack: waypoint.r not a number.")
            return
        end
    end

    if true == update then
        for _, bestLap in ipairs(track.bestLaps) do
            if type(bestLap) ~= "table" or type(bestLap.playerName) ~= "string" or type(bestLap.bestLapTime) ~= "number" or type(bestLap.vehicleName) ~= "string" then
                print("updateTrack: bestLap not a table or bestLap.playerName not a string or bestLap.bestLapTime not a number or bestLap.vehicleName not a string.")
                return
            end
        end

        trackFile = "./resources/races/" .. trackName .. "_updated.json"
        file, errMsg, errCode = io.open(trackFile, "w+")
        if file ~= fail then
            file:write(json.encode({waypointCoords = newWaypointCoords, bestLaps = track.bestLaps}))
            file:close()
            local msg = "updateTrack: '" .. trackName .. ".json' updated to current format in '" .. trackFile .. "'."
            print(msg)
            logMessage(msg)
        else
            print("updateTrack: Error opening file '" .. trackFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
        end
    else
        print("updateTrack: '" .. trackName .. ".json' not updated.")
    end
end

local function loadTracks(isPublic, source)
    local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)

    local tracks = nil

    if license ~= nil then
        if license ~= "PUBLIC" then
            license = string.sub(license, 9)
        end

        local raceData = nil

        local file, errMsg, errCode = io.open(raceDataFile, "r")
        if file ~= fail then
            raceData = json.decode(file:read("a"))
            file:close()
        else
            notifyPlayer(source, "loadTracks: Error opening file '" .. raceDataFile .. "' for read : '" .. errMsg .. "' : " .. errCode .. "\n")
            return nil
        end

        if nil == raceData then
            notifyPlayer(source, "loadTracks: No race data.\n")
            return nil
        end

        tracks = raceData[license]

        if nil == tracks then
            tracks = {}
        end
    else
        notifyPlayer(source, "loadTracks: Could not get license.\n")
        return nil
    end

    return tracks
end

local function saveTracks(isPublic, source, tracks)
    local license = true == isPublic and "PUBLIC" or GetPlayerIdentifier(source, 0)

    if license ~= nil then
        if license ~= "PUBLIC" then
            license = string.sub(license, 9)
        end

        local raceData = nil

        local file, errMsg, errCode = io.open(raceDataFile, "r")
        if file ~= fail then
            raceData = json.decode(file:read("a"))
            file:close()
        else
            notifyPlayer(source, "saveTracks: Error opening file '" .. raceDataFile .. "' for read : '" .. errMsg .. "' : " .. errCode .. "\n")
            return false
        end

        if nil == raceData then
            notifyPlayer(source, "saveTracks: No race data.\n")
            return false
        end

        raceData[license] = tracks

        file, errMsg, errCode = io.open(raceDataFile, "w+")
        if file ~= fail then
            file:write(json.encode(raceData))
            file:close()
        else
            notifyPlayer(source, "saveTracks: Error opening file '" .. raceDataFile .. "' for write : '" .. errMsg .. "' : " .. errCode .. "\n")
            return false
        end
    else
        notifyPlayer(source, "saveTracks: Could not get license.\n")
        return false
    end

    return true
end

local function loadVehicleFile(source, vehicleFile)
    vehicleFile = "./resources/races/" .. vehicleFile
    local vehicles = {}
    local file, errMsg, errCode = io.open(vehicleFile, "r")
    if fail == file then
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
    local tracks = loadTracks(races[rIndex].isPublic, rIndex)
    if tracks ~= nil then
        if tracks[races[rIndex].trackName] ~= nil then -- saved track still exists - not deleted in middle of race
            local bestLaps = tracks[races[rIndex].trackName].bestLaps
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
            tracks[races[rIndex].trackName].bestLaps = bestLaps
            if false == saveTracks(races[rIndex].isPublic, rIndex, tracks) then
                notifyPlayer(rIndex, "Save error updating best lap times.\n")
            end
        else
            notifyPlayer(rIndex, "Cannot save best lap times.  Track '" .. races[rIndex].trackName .. "' has been deleted.\n")
        end
    else
        notifyPlayer(rIndex, "Load error updating best lap times.\n")
    end
end

local function minutesSeconds(milliseconds)
    local seconds = milliseconds / 1000.0
    local minutes = math.floor(seconds / 60.0)
    seconds = seconds - minutes * 60.0
    return minutes, seconds
end

local function saveResults(race)
    -- races[playerID] = {state, waypointCoords[] = {x, y, z, r}, isPublic, trackName, owner, buyin, laps, timeout, rtype, restrict, vclass, svehicle, vehicleList, numRacing, players[playerID] = {playerName, aiName, numWaypointsPassed, data, coord}, results[] = {source, playerName, aiName, finishTime, bestLapTime, vehicleName}}
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
    local resultsFile = "./resources/races/results_" .. race.owner .. ".txt"
    local file, errMsg, errCode = io.open(resultsFile, "w+")
    if file ~= fail then
        file:write(msg)
        file:close()
    else
        print("Error opening file '" .. resultsFile .. "' for write : '" .. errMsg .. "' : " .. errCode)
    end
end

local function round(f)
    return (f - math.floor(f) >= 0.5) and math.ceil(f) or math.floor(f)
end

local function getRoleBits(source)
    local roleBits = (ROLE_EDIT | ROLE_REGISTER | ROLE_SPAWN) & ~requirePermissionBits
    local license = GetPlayerIdentifier(source, 0)
    if license ~= nil then
        license = string.sub(license, 9)
        if roles[license] ~= nil then
            return roles[license].roleBits | roleBits
        end
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

    -- unregister race registered by dropped player that has not started
    if races[source] ~= nil and STATE_REGISTERING == races[source].state then
        if races[source].buyin > 0 then
            for i in pairs(races[source].players) do
                Deposit(i, races[source].buyin)
                notifyPlayer(i, races[source].buyin .. " was deposited in your funds.\n")
            end
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
                TriggerEvent("races:finish", i, nil, 0, -1, -1, "", source)
            end
            break
        end
    end

    -- remove dropped player's bank account
    Remove(source)
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
                        license = string.sub(license, 9)
                        local roleType = "SPAWN"
                        if ROLE_EDIT == roleBit then
                            roleType = "EDIT"
                        elseif ROLE_REGISTER == roleBit then
                            roleType = "REGISTER"
                        end
                        if nil == roles[license] then
                            requests[source] = {name = GetPlayerName(source), roleBit = roleBit}
                            sendMessage(source, "Request for " .. roleType .. " role submitted.")
                        else
                            if 0 == roles[license].roleBits & roleBit then
                                requests[source] = {name = GetPlayerName(source), roleBit = roleBit}
                                sendMessage(source, "Request for " .. roleType .. " role submitted.")
                            else
                                sendMessage(source, "Request for " .. roleType .. " role already approved.\n")
                            end
                        end
                    else
                        sendMessage(source, "Could not get license.\n")
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
    if 0 == getRoleBits(source) & (ROLE_EDIT | ROLE_REGISTER) then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil and trackName ~= nil then
        local tracks = loadTracks(isPublic, source)
        if tracks ~= nil then
            if tracks[trackName] ~= nil then
                TriggerClientEvent("races:load", source, isPublic, trackName, tracks[trackName].waypointCoords)
            else
                sendMessage(source, "Cannot load.  '" .. trackName .. "' not found.\n")
            end
        else
            sendMessage(source, "Cannot load.  Error loading data.\n")
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
        local tracks = loadTracks(isPublic, source)
        if tracks ~= nil then
            if nil == tracks[trackName] then
                tracks[trackName] = {waypointCoords = waypointCoords, bestLaps = {}}
                if true == saveTracks(isPublic, source, tracks) then
                    TriggerClientEvent("races:save", source, isPublic, trackName)
                    logMessage("'" .. GetPlayerName(source) .. "' saved " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'")
                else
                    sendMessage(source, "Error saving '" .. trackName .. "'.\n")
                end
            else
                if true == isPublic then
                    sendMessage(source, "Public track '" .. trackName .. "' exists.  Use 'overwritePublic' command instead.\n")
                else
                    sendMessage(source, "Private track '" .. trackName .. "' exists.  Use 'overwrite' command instead.\n")
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
AddEventHandler("races:overwrite", function(isPublic, trackName, waypointCoords)
    local source = source
    if 0 == getRoleBits(source) & ROLE_EDIT then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil and trackName ~= nil and waypointCoords ~= nil then
        local tracks = loadTracks(isPublic, source)
        if tracks ~= nil then
            if tracks[trackName] ~= nil then
                tracks[trackName] = {waypointCoords = waypointCoords, bestLaps = {}}
                if true == saveTracks(isPublic, source, tracks) then
                    TriggerClientEvent("races:overwrite", source, isPublic, trackName)
                    logMessage("'" .. GetPlayerName(source) .. "' overwrote " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'")
                else
                    sendMessage(source, "Error overwriting '" .. trackName .. "'.\n")
                end
            else
                if true == isPublic then
                    sendMessage(source, "Public track '" .. trackName .. "' does not exist.  Use 'savePublic' command instead.\n")
                else
                    sendMessage(source, "Private track '" .. trackName .. "' does not exist.  Use 'save' command instead.\n")
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
AddEventHandler("races:delete", function(isPublic, trackName)
    local source = source
    if 0 == getRoleBits(source) & ROLE_EDIT then
        sendMessage(source, "Permission required.\n")
        return
    end
    if isPublic ~= nil and trackName ~= nil then
        local tracks = loadTracks(isPublic, source)
        if tracks ~= nil then
            if tracks[trackName] ~= nil then
                tracks[trackName] = nil
                if true == saveTracks(isPublic, source, tracks) then
                    sendMessage(source, "Deleted " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'.\n")
                    logMessage("'" .. GetPlayerName(source) .. "' deleted " .. (true == isPublic and "public" or "private") .. " track '" .. trackName .. "'")
                else
                    sendMessage(source, "Error deleting '" .. trackName .. "'.\n")
                end
            else
                sendMessage(source, "Cannot delete.  '" .. trackName .. "' not found.\n")
            end
        else
            sendMessage(source, "Cannot delete.  Error loading data.\n")
        end
    else
        sendMessage(source, "Ignoring delete event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:blt")
AddEventHandler("races:blt", function(isPublic, trackName)
    local source = source
    if isPublic ~= nil and trackName ~= nil then
        local tracks = loadTracks(isPublic, source)
        if tracks ~= nil then
            if tracks[trackName] ~= nil then
                TriggerClientEvent("races:blt", source, isPublic, trackName, tracks[trackName].bestLaps)
            else
                sendMessage(source, "Cannot list best lap times.  '" .. trackName .. "' not found.\n")
            end
        else
            sendMessage(source, "Cannot list best lap times.  Error loading data.\n")
        end
    else
        sendMessage(source, "Ignoring best lap times event.  Invalid parameters.\n")
    end
end)

RegisterNetEvent("races:list")
AddEventHandler("races:list", function(isPublic)
    local source = source
    if isPublic ~= nil then
        local tracks = loadTracks(isPublic, source)
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
                sendMessage(source, "No saved tracks.\n")
            end
        else
            sendMessage(source, "Cannot list.  Error loading data.\n")
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
                                    rdata.filename = randomVehicleFile
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
                                msg = msg .. umsg .. ".\n"
                                if false == distValid then
                                    msg = msg .. "Prize distribution table is invalid.\n"
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
            for i in pairs(races[source].players) do
                Deposit(i, races[source].buyin)
                notifyPlayer(i, races[source].buyin .. " was deposited in your funds.\n")
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
                        for i, player in pairs(races[source].players) do
                            if nil == player.aiName then
                                -- trigger races:start event for non AI drivers
                                TriggerClientEvent("races:start", i, source, delay)
                                if i == source then
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

RegisterNetEvent("races:leave")
AddEventHandler("races:leave", function(rIndex, aiName)
    local source = source
    if rIndex ~= nil then
        if races[rIndex] ~= nil then
            if STATE_REGISTERING == races[rIndex].state then
                local playerSource = aiName ~= nil and (source .. aiName) or source
                if races[rIndex].players[playerSource] ~= nil then
                    races[rIndex].players[playerSource] = nil
                    races[rIndex].numRacing = races[rIndex].numRacing - 1
                    if races[rIndex].buyin > 0 and nil == aiName then
                        Deposit(source, races[rIndex].buyin)
                        sendMessage(source, races[rIndex].buyin .. " was deposited in your funds.\n")
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
    local vehicleList = loadVehicleFile(source, allVehicleFile)
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
AddEventHandler("races:join", function(rIndex, aiName)
    local source = source
    if rIndex ~= nil then
        if races[rIndex] ~= nil then
            if (nil == aiName and GetFunds(source) >= races[rIndex].buyin) or aiName ~= nil then
                if STATE_REGISTERING == races[rIndex].state then
                    races[rIndex].numRacing = races[rIndex].numRacing + 1
                    local playerSource = aiName ~= nil and (source .. aiName) or source
                    local playerName = aiName ~= nil and ("(AI) " .. aiName) or GetPlayerName(source)
                    races[rIndex].players[playerSource] = {playerName = playerName, aiName = aiName, numWaypointsPassed = -1, data = -1, coord = nil}
                    TriggerClientEvent("races:join", source, rIndex, aiName, races[rIndex].waypointCoords)
                    if races[rIndex].buyin > 0 and nil == aiName then
                        Withdraw(source, races[rIndex].buyin)
                        notifyPlayer(source, races[rIndex].buyin .. " was withdrawn from your funds.\n")
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
AddEventHandler("races:finish", function(rIndex, aiName, numWaypointsPassed, finishTime, bestLapTime, vehicleName, altSource)
    local source = altSource ~= nil and altSource or source
    if rIndex ~= nil and numWaypointsPassed ~= nil and finishTime ~= nil and bestLapTime ~= nil and vehicleName ~= nil then
        if races[rIndex] ~= nil then
            if STATE_RACING == races[rIndex].state then
                local playerSource = aiName ~= nil and (source .. aiName) or source
                if races[rIndex].players[playerSource] ~= nil then
                    races[rIndex].players[playerSource].numWaypointsPassed = numWaypointsPassed
                    races[rIndex].players[playerSource].data = finishTime

                    for i, player in pairs(races[rIndex].players) do
                        if nil == player.aiName then
                            TriggerClientEvent("races:finish", i, rIndex, races[rIndex].players[playerSource].playerName, finishTime, bestLapTime, vehicleName)
                        end
                    end

                    races[rIndex].results[#races[rIndex].results + 1] = {
                        source = source,
                        playerName = races[rIndex].players[playerSource].playerName,
                        aiName = aiName,
                        finishTime = finishTime,
                        bestLapTime = bestLapTime,
                        vehicleName = vehicleName
                    }

                    races[rIndex].numRacing = races[rIndex].numRacing - 1
                    if 0 == races[rIndex].numRacing then
                        table.sort(races[rIndex].results, function(p0, p1)
                            return
                                (p0.finishTime >= 0 and (-1 == p1.finishTime or p0.finishTime < p1.finishTime)) or
                                (-1 == p0.finishTime and -1 == p1.finishTime and (p0.bestLapTime >= 0 and (-1 == p1.bestLapTime or p0.bestLapTime < p1.bestLapTime)))
                        end)

                        if true == distValid and races[rIndex].rtype ~= "rand" and "no" == races[rIndex].allowAI then
                            local numRacers = #races[rIndex].results
                            local numFinished = 0
                            local totalPool = numRacers * races[rIndex].buyin
                            local pool = totalPool
                            local winnings = {}

                            local winningsRL = {}
                            for _, result in pairs(races[rIndex].results) do
                                winningsRL[result.source] = races[rIndex].buyin
                            end
    
                            for i, result in ipairs(races[rIndex].results) do
                                winnings[i] = {payout = races[rIndex].buyin, source = result.source}
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

                            for i in pairs(races[rIndex].players) do
                                if winningsRL[i] > 0 then
                                    Deposit(i, winningsRL[i])
                                    notifyPlayer(i, winningsRL[i] .. " was deposited in your funds.\n")
                                end
                            end
                        end

                        for i, player in pairs(races[rIndex].players) do
                            if nil == player.aiName then
                                TriggerClientEvent("races:results", i, rIndex, races[rIndex].results)
                            end
                        end

                        saveResults(races[rIndex])

                        if races[rIndex].trackName ~= nil then
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
AddEventHandler("races:report", function(rIndex, aiName, numWaypointsPassed, distance, coord)
    local playerSource = aiName ~= nil and (source .. aiName) or source
    if rIndex ~= nil and numWaypointsPassed ~= nil and distance ~= nil and coord ~= nil then
        if races[rIndex] ~= nil then
            if races[rIndex].players[playerSource] ~= nil then
                races[rIndex].players[playerSource].numWaypointsPassed = numWaypointsPassed
                races[rIndex].players[playerSource].data = distance
                races[rIndex].players[playerSource].coord = coord
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
        Citizen.Wait(500)
        for rIndex, race in pairs(races) do
            if STATE_RACING == race.state then
                local sortedPlayers = {} -- will contain players still racing and players that finished without DNF
                local coords = {}
                local complete = true

                -- race.players[playerID] = {playerName, aiName, numWaypointsPassed, data, coord}
                for i, player in pairs(race.players) do
                    if -1 == player.numWaypointsPassed then -- player client hasn't updated numWaypointsPassed, data and coord
                        complete = false
                        break
                    end

                    -- player.data will be travel distance to next waypoint or finish time; finish time will be -1 if player DNF
                    -- if player.data == -1 then player did not finish race - do not include in sortedPlayers
                    if player.data ~= -1 then
                        sortedPlayers[#sortedPlayers + 1] = {
                            index = i,
                            aiName = player.aiName,
                            numWaypointsPassed = player.numWaypointsPassed,
                            data = player.data
                        }
                        coords[i] = player.coord
                    end
                end

                if true == complete then -- all player clients have updated numWaypointsPassed and data
                    table.sort(sortedPlayers, function(p0, p1)
                        return (p0.numWaypointsPassed > p1.numWaypointsPassed) or (p0.numWaypointsPassed == p1.numWaypointsPassed and p0.data < p1.data)
                    end)
                    -- players sorted into sortedPlayers table
                    for position, sortedPlayer in pairs(sortedPlayers) do
                        if nil == sortedPlayer.aiName then
                            TriggerClientEvent("races:position", sortedPlayer.index, rIndex, position, #sortedPlayers, coords)
                        end
                    end
                end
            end
        end
    end
end)
