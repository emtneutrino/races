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

local STATE_REGISTERING = 0
local STATE_RACING = 1

local races = {} -- races[] = {state, laps, timeout, waypoints[] = {x, y, z}, numRacing, players[] = {numWaypointsPassed, data}, results[] = {playerName, finishTime, bestLapTime}}

local raceDataFile = "./resources/races/raceData.json"

local function notifyPlayer(source, msg)
    TriggerClientEvent("chat:addMessage", source, {
        color = {255, 0, 0},
        multiline = true,
        args = {"[races:server]", msg}
    })
end

local function loadPlayerData(public, source)
    local license = true == public and "PUBLIC" or GetPlayerIdentifier(source, 0)

    local playerData = nil

    if license ~= nil then
        if license ~= "PUBLIC" then
            license = string.sub(license, 9)
        end

        local raceData = nil

        local file = io.open(raceDataFile, "r")
        if file ~= nil then
            raceData = json.decode(file:read("*a"));
            io.close(file)
        else
            notifyPlayer(source, "loadPlayerData: Error opening file '" .. raceDataFile .. "' for read.\n")
            return nil
        end

        if nil == raceData then
            notifyPlayer(source, "loadPlayerData: No race data.\n")
            return nil
        end

        playerData = raceData[license]

        if nil == playerData then
            playerData = {}
        end
    else
        notifyPlayer(source, "loadPlayerData: Could not get license.\n")
        return nil
    end

    return playerData
end

local function savePlayerData(public, source, data)
    local license = true == public and "PUBLIC" or GetPlayerIdentifier(source, 0)

    if license ~= nil then
        if license ~= "PUBLIC" then
            license = string.sub(license, 9)
        end

        local raceData = nil

        local file = io.open(raceDataFile, "r")
        if file ~= nil then
            raceData = json.decode(file:read("*a"));
            io.close(file)
        else
            notifyPlayer(source, "savePlayerData: Error opening file '" .. raceDataFile .. "' for read.\n")
            return false
        end

        if nil == raceData then
            notifyPlayer(source, "savePlayerData: No race data.\n")
            return false
        end

        raceData[license] = data

        file = io.open(raceDataFile, "w+")
        if file ~= nil then
            file:write(json.encode(raceData))
            io.close(file)
        else
            notifyPlayer(source, "savePlayerData: Error opening file '" .. raceDataFile .. "' for write.\n")
            return false
        end
    else
        notifyPlayer(source, "savePlayerData: Could not get license.\n")
        return false
    end

    return true
end

RegisterNetEvent("races:load")
AddEventHandler("races:load", function(public, name)
    if public ~= nil and name ~= nil then
        local source = source
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            local waypoints = playerRaces[name]
            if waypoints ~= nil then
                TriggerClientEvent("races:load", source, name, waypoints)
            else
                notifyPlayer(source, "Cannot load.  '" .. name .. "' not found.\n")
            end
        else
            notifyPlayer(source, "Cannot load.  Error loading data.\n")
        end
    end
end)

RegisterNetEvent("races:save")
AddEventHandler("races:save", function(public, name, waypoints)
    if public ~= nil and name ~= nil and waypoints ~= nil then
        local source = source
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            if nil == playerRaces[name] then
                playerRaces[name] = waypoints
                if true == savePlayerData(public, source, playerRaces) then
                    notifyPlayer(source, "Saved '" .. name .. "'.\n")
                else
                    notifyPlayer(source, "Error saving '" .. name .. "'.\n")
                end
            else
                if true == public then
                    notifyPlayer(source, ("'%s' exists.  Type '/races overwritePublic %s'.\n"):format(name, name))
                else
                    notifyPlayer(source, ("'%s' exists.  Type '/races overwrite %s'.\n"):format(name, name))
                end
            end
        else
            notifyPlayer(source, "Cannot save.  Error loading data.\n")
        end
    end
end)

RegisterNetEvent("races:overwrite")
AddEventHandler("races:overwrite", function(public, name, waypoints)
    if public ~= nil and name ~= nil and waypoints ~= nil then
        local source = source
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            if playerRaces[name] ~= nil then
                playerRaces[name] = waypoints
                if true == savePlayerData(public, source, playerRaces) then
                    notifyPlayer(source, "Overwrote '" .. name .. "'.\n")
                else
                    notifyPlayer(source, "Error overwriting '" .. name .. "'.\n")
                end
            else
                if true == public then
                    notifyPlayer(source, ("'%s' does not exist.  Type '/races savePublic %s'.\n"):format(name, name))
                else
                    notifyPlayer(source, ("'%s' does not exist.  Type '/races save %s'.\n"):format(name, name))
                end
            end
        else
            notifyPlayer(source, "Cannot overwrite.  Error loading data.\n")
        end
    end
end)

RegisterNetEvent("races:delete")
AddEventHandler("races:delete", function(public, name)
    if public ~= nil and name ~= nil then
        local source = source
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            if playerRaces[name] ~= nil then
                playerRaces[name] = nil
                if true == savePlayerData(public, source, playerRaces) then
                    notifyPlayer(source, "Deleted '" .. name .. "'.\n")
                else
                    notifyPlayer(source, "Error deleting '" .. name .. "'.\n")
                end
            else
                notifyPlayer(source, "Cannot delete.  '" .. name .. "' not found.\n")
            end
        else
            notifyPlayer(source, "Cannot delete.  Error loading data.\n")
        end
    end
end)

RegisterNetEvent("races:list")
AddEventHandler("races:list", function(public)
    if public ~= nil then
        local source = source
        local playerRaces = loadPlayerData(public, source)
        if playerRaces ~= nil then
            local empty = true
            local msg = "Saved races:\n"
            for name, _ in pairs(playerRaces) do
                msg = msg .. name .. "\n"
                empty = false
            end
            if false == empty then
                notifyPlayer(source, msg)
            else
                notifyPlayer(source, "No saved races.\n")
            end
        else
            notifyPlayer(source, "Cannot list.  Error loading data.\n")
        end
    end
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(coord, laps, timeout, waypoints)
    if coord ~= nil and laps ~= nil and timeout ~= nil and waypoints ~= nil then
        local source = source
        if laps > 0 then
            if timeout >= 0 then
                if nil == races[source] then
                    races[source] = {state = STATE_REGISTERING, laps = laps, timeout = timeout, waypoints = waypoints, numRacing = 0, players = {}, results = {}}
                    TriggerClientEvent("races:register", -1, source, GetPlayerName(source), coord)
                    notifyPlayer(source, "Race registered.\n")
                else
                    if STATE_RACING == races[source].state then
                        notifyPlayer(source, "Previous race already started.\n")
                    else
                        notifyPlayer(source, "Previous race registered.  Unregister first.\n")
                    end
                end
            else
                notifyPlayer(source, "Invalid timeout.\n")
            end
        else
            notifyPlayer(source, "Invalid laps.\n")
        end
    end
end)

RegisterNetEvent("races:unregister")
AddEventHandler("races:unregister", function()
    local source = source
    if races[source] ~= nil then
        races[source] = nil
        TriggerClientEvent("races:unregister", -1, source)
        notifyPlayer(source, "Race unregistered.\n")
    else
        notifyPlayer(source, "Cannot unregister.  No race registered.\n")
    end
end)

RegisterNetEvent("races:join")
AddEventHandler("races:join", function(index)
    if index ~= nil then
        local source = source
        if races[index] ~= nil then
            if STATE_REGISTERING == races[index].state then
                races[index].numRacing = races[index].numRacing + 1
                races[index].players[source] = {numWaypointsPassed = -1, data = -1}
                TriggerClientEvent("races:join", source, index, races[index].laps, races[index].timeout, races[index].waypoints)
            else
                notifyPlayer(source, "Cannot join race in progress.\n")
            end
        else
            notifyPlayer(source, "Cannot join unkown race.\n")
        end
    end
end)

RegisterNetEvent("races:leave")
AddEventHandler("races:leave", function(index)
    if index ~= nil then
        local source = source
        if races[index] ~= nil then
            if STATE_REGISTERING == races[index].state then
                if races[index].players[source] ~= nil then
                    races[index].players[source] = nil
                    races[index].numRacing = races[index].numRacing - 1
                else
                    notifyPlayer(source, "Cannot leave.  Not a member of this race.\n")
                end
            else
                notifyPlayer(source, "Cannot leave.  Race already started.\n")
            end
        else
            notifyPlayer(source, "Cannot leave.  Race does not exist.\n")
        end
    end
end)

RegisterNetEvent("races:rivals")
AddEventHandler("races:rivals", function(index)
    if index ~= nil then
        local source = source
        if races[index] ~= nil then
            if races[index].players[source] ~= nil then
                local msg = "Competitors:\n"
                local empty = true
                for i, _ in pairs(races[index].players) do
                    msg = msg .. GetPlayerName(i) .. "\n"
                    empty = false
                end
                if false == empty then
                    notifyPlayer(source, msg)
                else
                    notifyPlayer(source, "No competitors yet.\n")
                end
            else
                notifyPlayer(source, "Cannot list competitors.  Not a member of this race.\n")
            end
        else
            notifyPlayer(source, "Cannot list competitors.  Race does not exist.\n")
        end
    end
end)

RegisterNetEvent("races:start")
AddEventHandler("races:start", function(delay)
    if delay ~= nil then
        local source = source
        if races[source] ~= nil then
            if STATE_REGISTERING == races[source].state then
                if delay >= 0 then
                    if next(races[source].players) ~= nil then
                        races[source].state = STATE_RACING
                        for i, _ in pairs(races[source].players) do
                            TriggerClientEvent("races:start", i, delay)
                        end
                        TriggerClientEvent("races:hide", -1, source) -- hide race so no one else can join
                    else
                        notifyPlayer(source, "Cannot start.  No players have joined race.\n")
                    end
                else
                    notifyPlayer(source, "Cannot start.  Invalid delay.\n")
                end
            else
                notifyPlayer(source, "Cannot start.  Race already started.\n")
            end
        else
            notifyPlayer(source, "Cannot start.  No race registered.\n")
        end
    end
end)

RegisterNetEvent("races:finish")
AddEventHandler("races:finish", function(index, numWaypointsPassed, finishTime, bestLapTime)
    if index ~= nil and numWaypointsPassed ~= nil and finishTime ~= nil and bestLapTime ~= nil then
        local source = source
        if races[index] ~= nil then
            if STATE_RACING == races[index].state then
                if races[index].players[source] ~= nil then
                    races[index].players[source].numWaypointsPassed = numWaypointsPassed
                    races[index].players[source].data = finishTime

                    local playerName = GetPlayerName(source)

                    for i, _ in pairs(races[index].players) do
                        TriggerClientEvent("races:finish", i, playerName, finishTime, bestLapTime)
                    end

                    races[index].results[#(races[index].results) + 1] = {playerName = playerName, finishTime = finishTime, bestLapTime = bestLapTime}

                    races[index].numRacing = races[index].numRacing - 1
                    if 0 == races[index].numRacing then
                        for i, _ in pairs(races[index].players) do
                            TriggerClientEvent("races:results", i, races[index].results)
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
    end
end)

RegisterNetEvent("races:report")
AddEventHandler("races:report", function(index, numWaypointsPassed, dist)
    if index ~= nil and numWaypointsPassed ~= nil and dist ~= nil then
        local source = source
        if races[index] ~= nil and races[index].players[source] ~= nil then
            races[index].players[source].numWaypointsPassed = numWaypointsPassed
            races[index].players[source].data = dist
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        for _, race in pairs(races) do
            if STATE_RACING == race.state then
                local sortedPlayers = {} -- will contain players still racing and players that finished without DNF
                local complete = true

                -- race.players[] = {numWaypointsPassed, data}
                for i, player in pairs(race.players) do
                    if -1 == player.numWaypointsPassed then -- player client hasn't updated numWaypointsPassed and data
                        complete = false
                        break
                    end

                    -- if player.data == -1 then player did not finish race - do not include in sortedPlayers
                    if player.data ~= -1 then
                        sortedPlayers[#sortedPlayers + 1] = {index = i, numWaypointsPassed = player.numWaypointsPassed, data = player.data}
                    end
                end

                if true == complete then -- all player clients have updated numWaypointsPassed and data
                    table.sort(sortedPlayers, function(p0, p1)
                        return (p0.numWaypointsPassed > p1.numWaypointsPassed) or (p0.numWaypointsPassed == p1.numWaypointsPassed and p0.data < p1.data)
                    end)
                    -- players sorted into sortedPlayers table
                    for position, sortedPlayer in pairs(sortedPlayers) do
                        TriggerClientEvent("races:position", sortedPlayer.index, position, #sortedPlayers)
                    end
                end
            end
        end
    end
end)
