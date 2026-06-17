local DB_MARKERS = {}
local ESX = nil

local function getESX()
    if ESX then return ESX end
    if GetResourceState('es_extended') == 'started' then
        local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok then ESX = obj end
    end
    return ESX
end

local function decodeData(value)
    if not value or value == '' then return {} end
    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then return decoded end
    return {}
end

local function encodeData(value)
    return json.encode(value or {})
end


local function isAdmin(src)
    if src == 0 then return true end
    local srcStr = tostring(src)
    if Config.AdminAce and IsPlayerAceAllowed(srcStr, Config.AdminAce) then return true end

    local esx = getESX()
    if esx and esx.GetPlayerFromId then
        local xPlayer = esx.GetPlayerFromId(src)
        if xPlayer then
            local group = nil
            if xPlayer.getGroup then group = xPlayer.getGroup() end
            if group and Config.AdminGroups[group] then return true end
        end
    end

    return false
end

local function notify(src, msg)
    if not src or src == 0 then
        print('[real_markers] ' .. tostring(msg))
        return
    end
    TriggerClientEvent('chat:addMessage', src, { args = { '^3real_markers', tostring(msg) } })
end


local function ensureTable()
    if not Config.AutoCreateTable then return end
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` VARCHAR(80) NOT NULL,
            `style` VARCHAR(80) NOT NULL DEFAULT 'info',
            `label` VARCHAR(120) DEFAULT NULL,
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `data` LONGTEXT NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `enabled` (`enabled`),
            KEY `style` (`style`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]):format(Config.DatabaseTable))
end

local function loadMarkers()
    if not Config.UseDatabase then return end
    ensureTable()
    local rows = MySQL.query.await(('SELECT id, style, label, enabled, data FROM `%s` WHERE enabled = 1'):format(Config.DatabaseTable)) or {}
    DB_MARKERS = {}
    for _, row in ipairs(rows) do
        local data = decodeData(row.data)
        data.id = row.id
        data.style = data.style or row.style or 'info'
        data.label = data.label or row.label
        data.db = true
        DB_MARKERS[row.id] = data
    end
    TriggerClientEvent('real_markers:client:setDatabaseMarkers', -1, DB_MARKERS)
    print(('[real_markers] %s MySQL marker betoltve'):format(#rows))
end


local function upsertMarker(id, data)
    if not id or id == '' or type(data) ~= 'table' then return false end
    data.id = id
    local style = data.style or 'info'
    local label = data.label or data.title or id
    local encoded = encodeData(data)
    MySQL.insert.await(([[
        INSERT INTO `%s` (`id`, `style`, `label`, `enabled`, `data`)
        VALUES (?, ?, ?, 1, ?)
        ON DUPLICATE KEY UPDATE
            `style` = VALUES(`style`),
            `label` = VALUES(`label`),
            `enabled` = VALUES(`enabled`),
            `data` = VALUES(`data`)
    ]]):format(Config.DatabaseTable), { id, style, label, encoded })
    DB_MARKERS[id] = data
    TriggerClientEvent('real_markers:client:upsertDatabaseMarker', -1, id, data)
    return true
end

local function deleteMarker(id)
    if not id or id == '' then return false end
    MySQL.update.await(('UPDATE `%s` SET enabled = 0 WHERE id = ?'):format(Config.DatabaseTable), { id })
    DB_MARKERS[id] = nil
    TriggerClientEvent('real_markers:client:removeDatabaseMarker', -1, id)
    return true
end


local function getPlayerJobAndGrade(src)
    local esx = getESX()
    if not esx or not esx.GetPlayerFromId then return nil, 0 end
    local xPlayer = esx.GetPlayerFromId(src)
    if not xPlayer then return nil, 0 end
    local job = xPlayer.job
    if xPlayer.getJob then job = xPlayer.getJob() end
    if not job then return nil, 0 end
    return job.name, tonumber(job.grade or job.grade_level or 0) or 0
end

local function getPlayerGroup(src)
    local esx = getESX()
    if not esx or not esx.GetPlayerFromId then return nil end
    local xPlayer = esx.GetPlayerFromId(src)
    if not xPlayer then return nil end
    if xPlayer.getGroup then return xPlayer.getGroup() end
    return nil
end

local function hasItem(src, item, count)
    count = tonumber(count) or 1
    if not item or item == '' then return true end
    if Config.UseOxInventory and GetResourceState('ox_inventory') == 'started' then
        local ok, amount = pcall(function()
            return exports.ox_inventory:Search(src, 'count', item)
        end)
        if ok and (tonumber(amount) or 0) >= count then return true end
    end
    local esx = getESX()
    if esx and esx.GetPlayerFromId then
        local xPlayer = esx.GetPlayerFromId(src)
        if xPlayer and xPlayer.getInventoryItem then
            local invItem = xPlayer.getInventoryItem(item)
            if invItem and (tonumber(invItem.count) or 0) >= count then return true end
        end
    end
    return false
end


local function checkAccess(src, data)
    local permissions = data.permissions or data.access
    if not permissions then return true end
    if permissions.ace and not IsPlayerAceAllowed(tostring(src), permissions.ace) then
        return false, 'Nincs ACE jogosultságod.'
    end
    if permissions.groups then
        local group = getPlayerGroup(src)
        if type(permissions.groups) == 'table' and not permissions.groups[group] then
            return false, 'Nincs megfelelő rangod.'
        end
    end
    if permissions.jobs then
        local jobName, grade = getPlayerJobAndGrade(src)
        local minGrade = permissions.jobs[jobName]
        if minGrade == nil then
            return false, 'Ehhez nincs megfelelő munkád.'
        end
        if tonumber(grade) < tonumber(minGrade or 0) then
            return false, 'Túl alacsony a rangod.'
        end
    end
    if permissions.items then
        for item, required in pairs(permissions.items) do
            local cnt = required
            if type(required) == 'boolean' then cnt = required and 1 or 0 end
            if tonumber(cnt) and tonumber(cnt) > 0 and not hasItem(src, item, cnt) then
                return false, ('Hiányzó item: %s'):format(item)
            end
        end
    end
    return true
end


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(700)
        if Config.UseDatabase then loadMarkers() end
    end)
end)

RegisterNetEvent('real_markers:server:requestMarkers', function()
    local src = source
    TriggerClientEvent('real_markers:client:setDatabaseMarkers', src, DB_MARKERS)
end)

RegisterNetEvent('real_markers:server:interact', function(id)
    local src = source
    local data = DB_MARKERS[id]
    if not data then return end
    local allowed, reason = checkAccess(src, data)
    if not allowed then
        TriggerClientEvent('real_markers:client:accessDenied', src, id, reason or 'Nincs jogosultságod.')
        return
    end
    TriggerClientEvent('real_markers:client:doAction', src, id, data)
end)

RegisterNetEvent('real_markers:server:adminCreate', function(payload)
    local src = source
    if not isAdmin(src) then return notify(src, 'Nincs jogosultságod marker létrehozáshoz.') end
    if type(payload) ~= 'table' or not payload.id or not payload.coords then return notify(src, 'Hibás marker adat.') end
    payload.style = payload.style or 'info'
    payload.title = payload.title or (Config.Styles[payload.style] and Config.Styles[payload.style].title) or payload.id
    payload.helpText = payload.helpText or '~INPUT_CONTEXT~ Interakció'
    payload.interactDistance = payload.interactDistance or Config.DefaultInteractDistance
    payload.drawDistance = payload.drawDistance or Config.DefaultDrawDistance
    upsertMarker(payload.id, payload)
    notify(src, ('Marker létrehozva/mentve: %s'):format(payload.id))
end)

RegisterNetEvent('real_markers:server:adminUpdate', function(id, patch)
    local src = source
    if not isAdmin(src) then return notify(src, 'Nincs jogosultságod marker módosításhoz.') end
    if not DB_MARKERS[id] then return notify(src, 'Nincs ilyen marker: ' .. tostring(id)) end
    if type(patch) ~= 'table' then return end
    for k, v in pairs(patch) do DB_MARKERS[id][k] = v end
    upsertMarker(id, DB_MARKERS[id])
    notify(src, ('Marker módosítva: %s'):format(id))
end)

RegisterNetEvent('real_markers:server:adminDelete', function(id)
    local src = source
    if not isAdmin(src) then return notify(src, 'Nincs jogosultságod marker törléshez.') end
    if deleteMarker(id) then notify(src, ('Marker törölve: %s'):format(id)) end
end)


RegisterCommand('rmreload', function(src)
    if not isAdmin(src) then return notify(src, 'Nincs jogosultságod.') end
    loadMarkers()
    notify(src, 'Markerek újratöltve MySQL-ből.')
end, true)

RegisterCommand('rmlist', function(src)
    if not isAdmin(src) then return notify(src, 'Nincs jogosultságod.') end
    local count = 0
    for id in pairs(DB_MARKERS) do
        count = count + 1
        if src ~= 0 and count <= 15 then notify(src, ('%s'):format(id)) end
    end
    notify(src, ('Aktív MySQL markerek: %s'):format(count))
end, true)

exports('GetDatabaseMarkers', function()
    return DB_MARKERS
end)

exports('SaveDatabaseMarker', function(id, data)
    return upsertMarker(id, data)
end)

exports('DeleteDatabaseMarker', function(id)
    return deleteMarker(id)
end)



RegisterNetEvent('real_markers:server:editorGetData', function()
    local src = source
    if not isAdmin(src) then
        TriggerClientEvent('real_markers:client:editorData', src, { ok = false, message = 'Nincs jogosultságod az editorhoz.', markers = {} })
        return
    end

    -- DB markerek lista formátumban az editornak
    local list = {}
    for id, data in pairs(DB_MARKERS) do
        list[#list + 1] = data
    end
    table.sort(list, function(a, b) return (a.id or '') < (b.id or '') end)

    TriggerClientEvent('real_markers:client:editorData', src, { ok = true, markers = list })
end)
