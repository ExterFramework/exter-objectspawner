cacheData = {}
objId = {}
obj = nil

-- ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
--                                                        EVENT                                                        
-- ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛

RegisterNetEvent('exter-objectspawner:dataPostClient')
AddEventHandler('exter-objectspawner:dataPostClient',function()
    TriggerClientEvent('exter-objectspawner:setClient',source,cacheData)
end)

RegisterNetEvent('exter-objectspawner:createUser')
AddEventHandler('exter-objectspawner:createUser', function(xPlayer,identifier)
    if not cacheData then
        cacheData = {}
    end

    for _, v in ipairs(cacheData) do
        if v.identifier == identifier then
            return  
        end
    end
     
    MySQL.Async.execute('INSERT INTO exter_object (`identifier`, `props`) VALUES (@identifier,@props)',
    {
        ['@identifier'] = identifier, 
        ['@props'] = json.encode({}), 
    })

    Wait(2000)

    MySQL.Async.fetchAll('SELECT * FROM exter_object WHERE identifier = @identifier', {['@identifier'] = identifier}, function(result)
        for k, v in pairs(result) do
            data = {
                id = v.id,
                identifier = v.identifier,
                props = v.props and json.decode(v.props) or {},
            }
            table.insert(cacheData, data)
        end
    end)

    TriggerClientEvent('exter-objectspawner:setClient', -1, cacheData)
    
end)

RegisterNetEvent('exter-objectspawner:createProp')
AddEventHandler('exter-objectspawner:createProp',function(prop,id)
    local src = source
    local xPlayer = GetPlayer(src)
    local identifier = GetPlayerCid(src)
    local propData = {} 
    local flag = false
            
            TriggerEvent('exter-objectspawner:createUser', xPlayer,identifier)
    
            Wait(5000)
    
            table.insert(propData, prop)

            if PA.CraftSystem then 
                if prop.propname == "prop_tool_bench02_ld" or prop.propname == "gr_prop_gr_bench_02b" then 
                    TriggerEvent('exter-craft:create', src, propData, function(success)
                        if not success then
                            TriggerClientEvent('exter-objectspawner:deleteLastProp', src, id)
                            return false
                        end
                    end)
                end            
            end

            print("kod devam ediyor")
        
            updateCacheDataForIdentifier(identifier, "props", propData)
            MySQL.Async.execute('UPDATE exter_object SET `props` = @props WHERE identifier = @identifier', 
            {
                ['@props'] = json.encode(propData), 
                ['@identifier'] = identifier
            })
            TriggerClientEvent('exter-objectspawner:setClient', -1, cacheData)


    for k,v in pairs(cacheData) do 
        if v.identifier == identifier then
            flag = true
            propData = type(v.props) == 'string' and json.decode(v.props) or v.props or {}
        end
    end

    for k , v in pairs(cacheData) do 
        if flag then 
            for x , y in pairs(v.props) do
                local coords1 = y.position
                local coords2 = prop.position
                    Notify(src,PA.Notify["notify"]["text"],PA.Notify["notify"]["msgType"],PA.Notify["notify"]["length"])
                    table.insert(propData, prop)
                    updateCacheDataForIdentifier(identifier, "props", propData)
                    MySQL.Async.execute('UPDATE exter_object SET `props` = @props WHERE identifier = @identifier', 
                    {
                        ['@props'] = json.encode(propData), 
                        ['@identifier'] = identifier
                    })
                    TriggerClientEvent('exter-objectspawner:setClient', -1, cacheData)
                    return
            end
        end
    end
end)

RegisterNetEvent('exter-money:addLastProp')
AddEventHandler('exter-money:addLastProp', function(item)
    local xPlayer =  GetPlayer(source)
    if item == nil then return end
    AddItem(source, item, 1, {})
end)

function NotifyClient(src, message, data)
    TriggerClientEvent(message, src, data)
end


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then 
        return
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then 
        TriggerEvent('exter-objectspawner:getData')
        return
    end
end)


RegisterNetEvent('exter-objectspawner:getData')
AddEventHandler('exter-objectspawner:getData', function()

    local function fetchData(callback)
        MySQL.Async.fetchAll('SELECT * FROM exter_object', {}, function(result)
            callback(result)
        end)
    end

    fetchData(function(result)
        for k, v in pairs(result) do
            local data = {
                id = v.id,
                identifier = v.identifier,
                props = v.props and json.decode(v.props) or {},
            }
            table.insert(cacheData, data)
        end
    end)
end)


-- ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
--                                                        FUNCTION                                                    
-- ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛


function updateCacheData(id, property, value)
    for k, v in pairs(cacheData) do
        if v.id == id then
            v[property] = value
        end
    end
end

function updateCacheDataForIdentifier(identifier, property, value)
    for k, v in pairs(cacheData) do
        if v.identifier == identifier then
            v[property] = value
        end
    end
end




-- ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
--                                                        CALLBACK                                                    
-- ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛


CreateCallback('exter-objectspawner:getInventory', function(source,cb,searchItem)
    local xPlayer =  GetPlayer(source)
    local items = GetInventory(source)
    local itemArr = {}
    for k, v in pairs(items) do
        for x , y in pairs(searchItem) do 
        if v.name == y.itemName  then
                table.insert(itemArr, v)
            end 
        end
    end
    cb(itemArr)
end)


CreateCallback('exter-objectspawner:propItemControl', function(source,cb,data)
    local xPlayer =  GetPlayer(source)
    local item = GetItem(source, data.itemName)
    if item ~= nil then 
        if ItemCountControl(source, data.itemName,1) then
            RemoveItem(source, data.itemName, 1, {})
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end

end)




-- ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
--                                                        THREAD                                                    
-- ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛


