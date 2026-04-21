Core = nil
CoreName = nil
CoreReady = false
Citizen.CreateThread(function()
    for k, v in pairs(Cores) do
        if GetResourceState(v.ResourceName) == "starting" or GetResourceState(v.ResourceName) == "started" then
            CoreName = v.ResourceName
            Core = v.GetFramework()
            CoreReady = true
        end
    end
end)


RegisterCommand("propsystem", function()
    SetNuiFocus(1, 1)
    SendNUIMessage({
        action = "openProps",
        data = PA.PropsAll,
    })
end)


function TriggerCallback(name, cb, ...)
    PA.ServerCallbacks[name] = cb
    TriggerServerEvent('exter-moneywash:server:triggerCallback', name, ...)
end

RegisterNetEvent('exter-moneywash:client:triggerCallback', function(name, ...)
    if PA.ServerCallbacks[name] then
        PA.ServerCallbacks[name](...)
        PA.ServerCallbacks[name] = nil
    end
end)

function Notify(text, type, length)
    if CoreName == "qb-core" then
        Core.Functions.Notify(text, type, length)
    elseif CoreName == "es_extended" then
        Core.ShowNotification(text)
    end
end

function GetPlayerData()
    if CoreName == "qb-core" then
        local player = Core.Functions.GetPlayerData()
        return player
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerData()
        return player
    end
end
