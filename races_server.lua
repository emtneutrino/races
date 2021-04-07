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

local races = {} -- races[] = {state, laps, race[] = {x, y, z}, numRacers, players[] = {numWaypoints, data}, results[] = {playerName, finishTime}}

local raceDataFile = "./resources/races/raceData.txt"

RegisterNetEvent("races:load")
AddEventHandler("races:load", function(public, name)
    local playerRaces = loadPlayerData(public, source)
    local race = playerRaces[name]
    if race ~= nil then
        TriggerClientEvent("races:load", source, name, race)
    else
        notifyPlayer(source, "No race found with name '" .. name .. "'")
    end
end)

RegisterNetEvent("races:save")
AddEventHandler("races:save", function(public, name, race)
    local playerRaces = loadPlayerData(public, source)
    if playerRaces[name] ~= nil then
        notifyPlayer(source, ("'%s' exists.  Use '/races overwrite %s'"):format(name, name))
    else
        playerRaces[name] = race
        savePlayerData(public, source, playerRaces)    
        notifyPlayer(source, "Saved '" .. name .. "'")
     end
end)

RegisterNetEvent("races:overwrite")
AddEventHandler("races:overwrite", function(public, name, race)
    local playerRaces = loadPlayerData(public, source)
    if playerRaces[name] ~= nil then
        playerRaces[name] = race
        savePlayerData(public, source, playerRaces)    
        notifyPlayer(source, "Saved '" .. name .. "'")
    else
        notifyPlayer(source, ("'%s' does not exist.  Use '/races save %s'"):format(name, name))
    end
end)

RegisterNetEvent("races:delete")
AddEventHandler("races:delete", function(public, name)
    local playerRaces = loadPlayerData(public, source)
    if playerRaces[name] ~= nil then
        playerRaces[name] = nil
        savePlayerData(public, source, playerRaces)
        notifyPlayer(source, "Deleted '" .. name .. "'")
    else
        notifyPlayer(source, "No race found with name '" .. name .. "'")
    end
end)

RegisterNetEvent("races:list")
AddEventHandler("races:list", function(public)
    local playerRaces = loadPlayerData(public, source)
    local empty = true
    local msg = "Saved races: "
    for name, _ in pairs(playerRaces) do
        msg = msg .. "'" .. name .. "', "
        empty = false
    end
    if not empty then
        msg = string.sub(msg, 1, -3)
        notifyPlayer(source, msg)
    else
        notifyPlayer(source, "No saved races")
    end
end)

RegisterNetEvent("races:register")
AddEventHandler("races:register", function(coord, laps, timeout, race)
    if coord and laps > 0 and race then
        if races[source] == nil then
            races[source] = {state = STATE_REGISTERING, laps = laps, timeout = timeout, race = race, numRacers = 0, players = {}, results = {}}
            TriggerClientEvent("races:register", -1, source, GetPlayerName(source), coord)
            notifyPlayer(source, "Race registered")
        else
            if STATE_RACING == races[source].state then
                notifyPlayer(source, "Cannot register.  Race in progress.")
            else
                notifyPlayer(source, "Cannot register new race.  Prevouse race registered.  Unregister first.")
            end
        end
    else
        notifyPlayer(source, "Cannot register race")
    end
end)

RegisterNetEvent("races:unregister")
AddEventHandler("races:unregister", function()
    if races[source] ~= nil then
        races[source] = nil
        TriggerClientEvent("races:unregister", -1, source)
        notifyPlayer(source, "Race unregistered")
    else
        notifyPlayer(source, "No race registered")
    end
end)

RegisterNetEvent("races:join")
AddEventHandler("races:join", function(index)
    if races[index] ~= nil then
        if STATE_REGISTERING == races[index].state then
            races[index].numRacers = races[index].numRacers + 1
            races[index].players[source] = {numWaypoints = 0, data = 0}
            TriggerClientEvent("races:join", source, index, races[index].laps, races[index].timeout, races[index].race)
        else
            notifPlayer(source, "Cannot join race in progress")
        end
    else
        notifyPlayer(source, "Cannot join unkown race")
    end
end)

RegisterNetEvent("races:leave")
AddEventHandler("races:leave", function(index)
    if races[index] ~= nil then
        if races[index].players[source] ~= nil then
            if STATE_RACING == races[index].state then
                TriggerEvent("races:finish", index, false, source, -1)
            else
                races[index].players[source] = nil
                races[index].numRacers = races[index].numRacers - 1
            end
            TriggerClientEvent("races:leave", source)
        else
            notifyPlayer(source, "Not a member of this race")
        end
    else
        notifyPlayer(source, "Race does not exist")
    end
end)

RegisterNetEvent("races:start")
AddEventHandler("races:start", function(delay)
    if races[source] ~= nil then
        if STATE_REGISTERING == races[source].state then
            if delay >= 0 then
                if next(races[source].players) ~= nil then
                    races[source].state = STATE_RACING
                    for player, _ in pairs(races[source].players) do
                        TriggerClientEvent("races:start", player, delay)
                    end
                    TriggerClientEvent("races:hide", -1, source) -- hide race so no one else can join
                else
                    notifyPlayer(source, "No players have joined race")
                end
            else
                notifyPlayer(source, "Invalid delay")
            end
        else
            notifyPlayer(source, "Race already started")
        end
    else
        notifyPlayer(source, "No race registered")
    end
end)

RegisterNetEvent("races:finish")
AddEventHandler("races:finish", function(index, fromSource, playerSource, finishTime)
    if races[index] ~= nil then
        playerSource = true == fromSource and source or playerSource
        if races[index].players[playerSource] ~= nil then
            if STATE_RACING == races[index].state then
                local playerName = GetPlayerName(playerSource)

                for player, _ in pairs(races[index].players) do
                    TriggerClientEvent("races:finish", player, index, playerName, finishTime)
                end

                local playerResult = {playerName = playerName, finishTime = finishTime}
                if finishTime < 0 then
                    table.insert(races[index].results, playerResult)
                else
                    local inserted = false
                    for i, result in pairs(races[index].results) do
                        if result.finishTime < 0 then
                            table.insert(races[index].results, i, playerResult)
                            inserted = true
                            break
                        elseif finishTime < result.finishTime then
                            table.insert(races[index].results, i, playerResult)
                            inserted = true
                            break
                        end
                    end
                    if not inserted then
                        table.insert(races[index].results, playerResult)
                    end
                end

                races[index].numRacers = races[index].numRacers - 1
                if 0 == races[index].numRacers then
                    for player, _ in pairs(races[index].players) do
                        TriggerClientEvent("races:results", player, races[index].results)
                    end
                    races[index] = nil -- delete race after all players finish
                end
            else
                notifyPlayer(playerSource, "Race not in progress")
            end
        else
            notifyPlayer(playerSource, "Not a member of this race")
        end
    else
        notifyPlayer(playerSource, "Race does not exist")
    end
end)

RegisterNetEvent("races:position")
AddEventHandler("races:position", function(index)
    if races[index] ~= nil and STATE_RACING == races[index].state and races[index].players[source] ~= nil then
        local position = -1
        local numPlayers = -1
        local sortedPlayers = {}
        local complete = true
        for i, player in pairs(races[index].players) do
            if 0 == player.numWaypoints then
                -- player client hasn't updated numWaypoints and data - abandon updating position and numPlayers
                complete = false
                break
            end

            -- if player.data == -1 then player did not finish race - do not include in numPlayers
            if player.data ~= -1 then
                local inserted = false
                local playerInfo = {index = i, numWaypoints = player.numWaypoints, data = player.data}
                -- sort player into sortedPlayers table
                for j, sortedPlayer in pairs(sortedPlayers) do
                    if player.numWaypoints > sortedPlayer.numWaypoints then
                        table.insert(sortedPlayers, j, playerInfo)
                        inserted = true
                        break
                    elseif player.numWaypoints == sortedPlayer.numWaypoints then
                        if player.data < sortedPlayer.data then
                            table.insert(sortedPlayers, j, playerInfo)
                            inserted = true
                            break
                        end
                    end
                end

                if not inserted then
                    table.insert(sortedPlayers, playerInfo)
                end
            end
        end

        if true == complete then
            -- all player clients in races[index] have updated numWaypoints and data
            -- players sorted into sortedPlayers table
            numPlayers = #sortedPlayers
            for i, sortedPlayer in pairs(sortedPlayers) do
                if sortedPlayer.index == source then
                    position = i
                    break
                end
            end
            TriggerClientEvent("races:position", source, position, numPlayers)
        end
    end
end)

RegisterNetEvent("races:report")
AddEventHandler("races:report", function(index, numWaypoints, data)
    if races[index] ~= nil and races[index].players[source] ~= nil then
        races[index].players[source].numWaypoints = numWaypoints
        races[index].players[source].data = data
    end
end)

-- update position and numPlayers on client every second in race information display
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        for _, race in pairs(races) do
            if STATE_RACING == race.state then
                for player, _ in pairs(race.players) do
                    TriggerClientEvent("races:report", player)
                end
            end
        end
    end
end)

function notifyPlayer(source, msg)
    TriggerClientEvent("chat:addMessage", source, {
        color = {255, 0, 0},
        multiline = true,
        args = {"[races:server]",  msg}
    })
end

function loadPlayerData(public, source)
    local license = public == true and "PUBLIC" or GetPlayerIdentifier(source, 0)

    local playerData = nil

    if license ~= nil then
        if license ~= "PUBLIC" then
            license = string.sub(license, 9)
        end

        local raceData = nil

        local file = io.open(raceDataFile, "r")
        if file ~= nil then
            local contents = file:read("*a")
            raceData = json.decode(contents);
            io.close(file)
        end

        if raceData ~= nil then
            playerData = raceData[license]
        end
    end

    if nil == playerData then
        playerData = {}
    end

    return playerData
end

function savePlayerData(public, source, data)
    local license = public == true and "PUBLIC" or GetPlayerIdentifier(source, 0)

    if license ~= nil then
        if license ~= "PUBLIC" then
            license = string.sub(license, 9)
        end

        local raceData = nil

        local file = io.open(raceDataFile, "r")
        if file ~= nil then
            local contents = file:read("*a")
            raceData = json.decode(contents);
            io.close(file)
        end

        if nil == raceData then
            raceData = {}
        end

        raceData[license] = data

        file = io.open(raceDataFile, "w+")
        if file then
            local contents = json.encode(raceData)
            file:write(contents)
            io.close(file)
        end
    end
end
