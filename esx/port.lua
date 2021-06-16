local ESX = nil

function GetFunds(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer.getMoney()
end

function SetFunds(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.setMoney(amount)
end

function Withdraw(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeMoney(amount)
end

function Deposit(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addMoney(amount)
end

Citizen.CreateThread(function()
    while nil == ESX do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)
