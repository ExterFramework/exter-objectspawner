Core = nil
CoreName = 'standalone'
CoreReady = false

CreateThread(function()
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
end)

local function getStandaloneIdentifier(src)
    local identifiers = GetPlayerIdentifiers(src)
    for i = 1, #identifiers do
        if identifiers[i]:find('license:') == 1 then
            return identifiers[i]
        end
    end

    return ('src:%s'):format(src)
end

function GetPlayer(source)
    if CoreName == 'qb-core' or CoreName == 'qbx_core' then
        return Core and Core.Functions and Core.Functions.GetPlayer(source) or nil
    elseif CoreName == 'es_extended' then
        return Core and Core.GetPlayerFromId and Core.GetPlayerFromId(source) or nil
    end

    return { source = source }
end

function GetPlayerCid(source)
    if CoreName == 'qb-core' or CoreName == 'qbx_core' then
        local player = GetPlayer(source)
        return player and player.PlayerData and player.PlayerData.citizenid or nil
    elseif CoreName == 'es_extended' then
        local player = GetPlayer(source)
        return player and player.getIdentifier and player.getIdentifier() or nil
    end

    return getStandaloneIdentifier(source)
end

function Notify(source, text, msgType, length)
    if CoreName == 'qb-core' or CoreName == 'qbx_core' then
        if Core and Core.Functions and Core.Functions.Notify then
            Core.Functions.Notify(source, text, msgType or 'success', length or 5000)
            return
        end
    elseif CoreName == 'es_extended' then
        local player = GetPlayer(source)
        if player and player.showNotification then
            player.showNotification(text)
            return
        end
    end

    TriggerClientEvent('chat:addMessage', source, {
        args = { 'ObjectSpawner', text }
    })
end

function AddItem(source, name, amount, metadata)
    amount = tonumber(amount) or 1

    if CoreName == 'qb-core' or CoreName == 'qbx_core' then
        local player = GetPlayer(source)
        return player and player.Functions and player.Functions.AddItem and player.Functions.AddItem(name, amount, false, metadata)
    elseif CoreName == 'es_extended' then
        local player = GetPlayer(source)
        if not player then return false end

        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasOx = GetResourceState('ox_inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:AddItem(source, name, amount)
        elseif hasOx then
            return exports.ox_inventory:AddItem(source, name, amount, metadata)
        end

        player.addInventoryItem(name, amount)
        return true
    end

    return true
end

function RemoveItem(source, name, amount, metadata)
    amount = tonumber(amount) or 1

    if CoreName == 'qb-core' or CoreName == 'qbx_core' then
        local player = GetPlayer(source)
        return player and player.Functions and player.Functions.RemoveItem and player.Functions.RemoveItem(name, amount, false, metadata)
    elseif CoreName == 'es_extended' then
        local player = GetPlayer(source)
        if not player then return false end

        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasOx = GetResourceState('ox_inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:RemoveItem(source, name, amount, metadata)
        elseif hasOx then
            return exports.ox_inventory:RemoveItem(source, name, amount, metadata)
        end

        player.removeInventoryItem(name, amount)
        return true
    end

    return true
end

function GetItem(source, name)
    if CoreName == 'qb-core' or CoreName == 'qbx_core' then
        local player = GetPlayer(source)
        return player and player.Functions and player.Functions.GetItemByName and player.Functions.GetItemByName(name) or nil
    elseif CoreName == 'es_extended' then
        local player = GetPlayer(source)
        if not player then return nil end

        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasOx = GetResourceState('ox_inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:GetItem(source, name)
        elseif hasOx then
            return exports.ox_inventory:GetItem(source, name, nil, true)
        end

        return player.getInventoryItem(name)
    end

    return { name = name, amount = 9999, count = 9999 }
end

function GetInventory(source)
    if CoreName == 'qb-core' or CoreName == 'qbx_core' then
        local player = GetPlayer(source)
        return player and player.PlayerData and player.PlayerData.items or {}
    elseif CoreName == 'es_extended' then
        local player = GetPlayer(source)
        if not player then return {} end

        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasOx = GetResourceState('ox_inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:GetPlayerInventory(source)
        elseif hasOx then
            return exports.ox_inventory:GetInventoryItems(source)
        end

        return player.getInventory() or {}
    end

    return {}
end

function ItemCountControl(source, name, amount)
    amount = tonumber(amount) or 1

    if CoreName == 'standalone' then
        return true
    end

    local item = GetItem(source, name)
    if not item then return false end

    local qty = item.amount or item.count or 0
    return qty >= amount
end

PA.ServerCallbacks = {}

function CreateCallback(name, cb)
    PA.ServerCallbacks[name] = cb
end

function TriggerCallback(name, source, cb, ...)
    local callback = PA.ServerCallbacks[name]
    if not callback then return end
    callback(source, cb, ...)
end

RegisterNetEvent('exter-objectspawner:server:triggerCallback', function(name, ...)
    local src = source

    TriggerCallback(name, src, function(...)
        TriggerClientEvent('exter-objectspawner:client:triggerCallback', src, name, ...)
    end, ...)
end)
