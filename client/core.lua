Core = nil
CoreName = 'standalone'
CoreReady = false

local function detectCore()
    for _, v in pairs(Cores) do
        local state = GetResourceState(v.ResourceName)
        if state == 'starting' or state == 'started' then
            local ok, framework = pcall(v.GetFramework)
            if ok and framework then
                CoreName = v.ResourceName
                Core = framework
                break
            end
        end
    end

    CoreReady = true
end

CreateThread(function()
    detectCore()
end)

function TriggerCallback(name, cb, ...)
    if type(cb) ~= 'function' then return end
    PA.ServerCallbacks[name] = cb
    TriggerServerEvent('exter-objectspawner:server:triggerCallback', name, ...)
end

RegisterNetEvent('exter-objectspawner:client:triggerCallback', function(name, ...)
    local callback = PA.ServerCallbacks[name]
    if callback then
        callback(...)
        PA.ServerCallbacks[name] = nil
    end
end)

function Notify(text, msgType, length)
    if CoreName == 'qb-core' or CoreName == 'qbx_core' then
        if Core and Core.Functions and Core.Functions.Notify then
            Core.Functions.Notify(text, msgType or 'success', length or 5000)
            return
        end
    elseif CoreName == 'es_extended' then
        if Core and Core.ShowNotification then
            Core.ShowNotification(text)
            return
        end
    end

    print(('[exter-objectspawner] %s'):format(text))
end

function GetPlayerData()
    if CoreName == 'qb-core' or CoreName == 'qbx_core' then
        return (Core and Core.Functions and Core.Functions.GetPlayerData and Core.Functions.GetPlayerData()) or {}
    elseif CoreName == 'es_extended' then
        return (Core and Core.GetPlayerData and Core.GetPlayerData()) or {}
    end

    return {
        source = GetPlayerServerId(PlayerId())
    }
end
