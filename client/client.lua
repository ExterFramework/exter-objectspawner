local playerData = {}
local cacheData = {}
local allObject = {}
local currentObject = nil
local objectHash = nil
local lastPropItem = nil

local function getIdentifierForClient()
    local data = GetPlayerData() or {}
    if CoreName == 'es_extended' then
        return data.identifier
    end

    return data.citizenid or tostring(GetPlayerServerId(PlayerId()))
end

local function deleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local function spawnCachedProps()
    for i = 1, #allObject do
        deleteEntitySafe(allObject[i])
    end
    allObject = {}

    local myIdentifier = getIdentifierForClient()
    if not myIdentifier then return end

    for _, entry in pairs(cacheData or {}) do
        if tostring(entry.identifier) == tostring(myIdentifier) then
            for _, prop in pairs(entry.props or {}) do
                local model = tonumber(prop.hash) or GetHashKey(prop.propname)
                if not IsModelInCdimage(model) then
                    model = GetHashKey(prop.propname)
                end

                RequestModel(model)
                local timeout = GetGameTimer() + 5000
                while not HasModelLoaded(model) and GetGameTimer() < timeout do
                    Wait(25)
                end

                if HasModelLoaded(model) then
                    local obj = CreateObject(model, prop.position.x, prop.position.y, prop.position.z, true, true, false)
                    SetEntityAsMissionEntity(obj, true, true)
                    SetEntityHeading(obj, prop.heading or 0.0)
                    FreezeEntityPosition(obj, true)
                    SetModelAsNoLongerNeeded(model)
                    allObject[#allObject + 1] = obj
                end
            end
        end
    end
end

RegisterCommand('openprops', function()
    TriggerEvent('exter-objectspawner:openProps')
end)

RegisterNetEvent('exter-objectspawner:openProps', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openProps',
        data = PA.PropsAll,
    })
end)

RegisterNUICallback('openProps', function(data, cb)
    TriggerCallback('exter-objectspawner:propItemControl', function(serverCb)
        if not serverCb then
            cb(false)
            return
        end

        lastPropItem = data.itemName
        objectHash = tonumber(data.hash)

        local model = GetHashKey(data.propName)
        if not IsModelInCdimage(model) then
            cb(false)
            return
        end

        RequestModel(model)
        local timeout = GetGameTimer() + 5000
        while not HasModelLoaded(model) and GetGameTimer() < timeout do
            Wait(25)
        end

        if not HasModelLoaded(model) then
            cb(false)
            return
        end

        local playerPed = PlayerPedId()
        local offset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)

        currentObject = CreateObject(model, offset.x, offset.y, offset.z, true, false, false)
        local result = exports.object_gizmo:useGizmo(currentObject)
        if result then
            FreezeEntityPosition(currentObject, true)
        end

        cb(true)
    end, data)
end)

RegisterNUICallback('deleteProp', function(_, cb)
    deleteEntitySafe(currentObject)
    currentObject = nil

    if lastPropItem then
        TriggerServerEvent('exter-money:addLastProp', lastPropItem)
    end

    lastPropItem = nil
    cb(true)
end)

RegisterNUICallback('saveBuild', function(_, cb)
    if not currentObject or not DoesEntityExist(currentObject) then
        cb(false)
        return
    end

    for _, propCfg in pairs(PA.PropsAll) do
        if tostring(propCfg.hash) == tostring(objectHash) then
            local data = {
                rotation = GetEntityRotation(currentObject),
                position = GetEntityCoords(currentObject),
                heading = GetEntityHeading(currentObject),
                hash = propCfg.hash,
                propname = propCfg.propname,
                objId = math.random(1, 1000000),
            }

            TriggerServerEvent('exter-objectspawner:createProp', data)
            break
        end
    end

    cb(true)
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNetEvent('exter-objectspawner:deleteLastProp', function()
    Notify('Since you already have one table, you cannot create another.', 'error', 5000)
    deleteEntitySafe(currentObject)
    currentObject = nil
end)

RegisterNetEvent('exter-objectspawner:setClient', function(data)
    cacheData = data or {}
end)

RegisterNetEvent('exter-objectspawner:notify', function(data)
    Notify(data)
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    playerData = GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded', function()
    playerData = GetPlayerData()
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(250)
    end

    playerData = GetPlayerData()
    TriggerServerEvent('exter-objectspawner:dataPostClient')

    Wait(1000)
    spawnCachedProps()
end)

CreateThread(function()
    while true do
        Wait(3000)
        if #cacheData > 0 then
            spawnCachedProps()
            Wait(15000)
        end
    end
end)

RegisterNetEvent('exter-objectspawner:deleteProp', function()
    deleteEntitySafe(currentObject)
    currentObject = nil

    for i = 1, #allObject do
        deleteEntitySafe(allObject[i])
    end

    allObject = {}
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for i = 1, #allObject do
        deleteEntitySafe(allObject[i])
    end

    deleteEntitySafe(currentObject)
    currentObject = nil
    allObject = {}
end)
