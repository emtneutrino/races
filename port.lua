local playerFunds = {} -- playerFunds[] = funds

function GetFunds(source)
    return playerFunds[source]
end

function SetFunds(source, amount)
    playerFunds[source] = amount
end

function Withdraw(source, amount)
    playerFunds[source] = playerFunds[source] - amount
end

function Deposit(source, amount)
    playerFunds[source] = playerFunds[source] + amount
end
