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

local ESX = nil

function GetFunds(source)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer ~= nil then
        return xPlayer.getMoney()
    else
        return -1
    end
end

function SetFunds(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer ~= nil then
        if amount < 0 then
            xPlayer.setMoney(0)
        else
            xPlayer.setMoney(amount)
        end
    end
end

function Withdraw(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer ~= nil then
        if xPlayer.getMoney() < amount then
            xPlayer.setMoney(0)
        else
            xPlayer.removeMoney(amount)
        end
    end
end

function Deposit(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer ~= nil then
        xPlayer.addMoney(amount)
    end
end

function Remove(source)
    -- do nothing
end

Citizen.CreateThread(function()
    while nil == ESX do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)
