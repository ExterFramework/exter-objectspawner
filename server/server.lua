local cacheData = {}

local function decodeProps(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return {} end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        return {}
    end

    return decoded
end

local function findByIdentifier(identifier)
    for i = 1, #cacheData do
        if cacheData[i].identifier == identifier then
            return cacheData[i], i
        end
    end

    return nil, nil
end

local function broadcastCache()
    TriggerClientEvent('exter-objectspawner:setClient', -1, cacheData)
end

local function ensureUser(identifier)
    local existing = findByIdentifier(identifier)
    if existing then return existing end

    MySQL.Async.execute('INSERT INTO exter_object (`identifier`, `props`) VALUES (@identifier, @props)', {
        ['@identifier'] = identifier,
        ['@props'] = json.encode({})
    })

    local created = {
        identifier = identifier,
        props = {}
    }
    table.insert(cacheData, created)
    return created
end

RegisterNetEvent('exter-objectspawner:dataPostClient', function()
    TriggerClientEvent('exter-objectspawner:setClient', source, cacheData)
end)

RegisterNetEvent('exter-objectspawner:createProp', function(prop)
    local src = source
    local identifier = GetPlayerCid(src)
    if not identifier then
        Notify(src, 'Identifier player tidak ditemukan.', 'error', 5000)
        return
    end

    if type(prop) ~= 'table' or not prop.propname or not prop.position then
        Notify(src, 'Data prop tidak valid.', 'error', 5000)
        return
    end

    local entry = ensureUser(identifier)
    entry.props = decodeProps(entry.props)

    prop.objId = prop.objId or math.random(100000, 999999)
    table.insert(entry.props, prop)

    MySQL.Async.execute('UPDATE exter_object SET `props` = @props WHERE identifier = @identifier', {
        ['@props'] = json.encode(entry.props),
        ['@identifier'] = identifier
    })

    Notify(src, PA.Notify.notify.text, PA.Notify.notify.msgType, PA.Notify.notify.length)
    broadcastCache()
end)

RegisterNetEvent('exter-money:addLastProp', function(item)
    if not item then return end
    AddItem(source, item, 1, {})
end)

RegisterNetEvent('exter-objectspawner:getData', function()
    MySQL.Async.fetchAll('SELECT * FROM exter_object', {}, function(result)
        cacheData = {}

        for i = 1, #result do
            local row = result[i]
            cacheData[#cacheData + 1] = {
                id = row.id,
                identifier = row.identifier,
                props = decodeProps(row.props)
            }
        end

        broadcastCache()
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TriggerEvent('exter-objectspawner:getData')
end)

CreateCallback('exter-objectspawner:getInventory', function(source, cb, searchItem)
    local items = GetInventory(source)
    local result = {}

    local lookup = {}
    if type(searchItem) == 'table' then
        for i = 1, #searchItem do
            local item = searchItem[i]
            if item and item.itemName then
                lookup[item.itemName] = true
            end
        end
    end

    for _, v in pairs(items or {}) do
        if v and v.name and lookup[v.name] then
            result[#result + 1] = v
        end
    end

    cb(result)
end)

CreateCallback('exter-objectspawner:propItemControl', function(source, cb, data)
    if type(data) ~= 'table' or not data.itemName then
        cb(false)
        return
    end

    if CoreName == 'standalone' then
        cb(true)
        return
    end

    local item = GetItem(source, data.itemName)
    if item and ItemCountControl(source, data.itemName, 1) then
        RemoveItem(source, data.itemName, 1, {})
        cb(true)
        return
    end

    cb(false)
end)
