
local cachedDbMarkers = {}

local function isAdmin(src)
    if src == 0 then return true end
    if Config.RequireAceForEditor == false then return true end
    return IsPlayerAceAllowed(src, Config.AdminAce or 'real_markers.admin')
end

local function dbg(msg)
    if Config.Debug then print('[real_markers] ' .. msg) end
end

local function encodePerms(value)
    if not value then return nil end
    if type(value) == 'string' then return value end
    return json.encode(value)
end

local function decodePerms(value)
    if not value or value == '' then return nil end
    if type(value) == 'table' then return value end
    local ok, decoded = pcall(json.decode, value)
    if ok then return decoded end
    return nil
end

local function rowToMarker(row)
    return {
        id = row.id,
        style = row.style,
        coords = { x = row.x, y = row.y, z = row.z },
        title = row.title,
        subtitle = row.subtitle,
        helpText = row.help_text,
        event = row.event,
        serverEvent = row.server_event == 1,
        target = row.target == 1,
        targetLabel = row.target_label,
        drawDistance = row.draw_distance,
        interactDistance = row.interact_distance,
        permissions = decodePerms(row.permissions),
        status = row.status,
        theme = row.theme,
        icon = row.icon,
        mode = row.mode,
        enabled = row.enabled == 1
    }
end

local function createTable()
    if not Config.AutoCreateTable then return end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `real_markers` (
          `id` varchar(80) NOT NULL,
          `style` varchar(80) NOT NULL DEFAULT 'subtle_document',
          `x` double NOT NULL DEFAULT 0,
          `y` double NOT NULL DEFAULT 0,
          `z` double NOT NULL DEFAULT 0,
          `title` varchar(120) DEFAULT NULL,
          `subtitle` varchar(180) DEFAULT NULL,
          `help_text` varchar(180) DEFAULT NULL,
          `event` varchar(120) DEFAULT NULL,
          `server_event` tinyint(1) NOT NULL DEFAULT 0,
          `target` tinyint(1) NOT NULL DEFAULT 0,
          `target_label` varchar(120) DEFAULT NULL,
          `draw_distance` double DEFAULT NULL,
          `interact_distance` double DEFAULT NULL,
          `permissions` longtext DEFAULT NULL,
          `status` varchar(80) DEFAULT NULL,
          `theme` varchar(40) DEFAULT NULL,
          `icon` varchar(80) DEFAULT NULL,
          `mode` varchar(40) DEFAULT NULL,
          `enabled` tinyint(1) NOT NULL DEFAULT 1,
          `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `enabled` (`enabled`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function loadDbMarkers()
    createTable()
    local rows = MySQL.query.await('SELECT * FROM real_markers WHERE enabled = 1') or {}
    cachedDbMarkers = {}
    for _, row in ipairs(rows) do
        cachedDbMarkers[#cachedDbMarkers + 1] = rowToMarker(row)
    end
    dbg(('Loaded %s MySQL markers'):format(#cachedDbMarkers))
    return cachedDbMarkers
end

local function broadcastMarkers()
    TriggerClientEvent('real_markers:client:setDbMarkers', -1, cachedDbMarkers)
end

CreateThread(function()
    Wait(800)
    loadDbMarkers()
    broadcastMarkers()
end)

RegisterNetEvent('real_markers:server:requestMarkers', function()
    TriggerClientEvent('real_markers:client:setDbMarkers', source, cachedDbMarkers)
end)

RegisterNetEvent('real_markers:server:reloadMarkers', function()
    local src = source
    if src ~= 0 and not isAdmin(src) then return end
    loadDbMarkers()
    broadcastMarkers()
    if src ~= 0 then TriggerClientEvent('real_markers:client:notify', src, 'Markerek újratöltve MySQL-ből.', 'success') end
end)

RegisterNetEvent('real_markers:server:editorRequest', function(requestId)
    local src = source
    if not isAdmin(src) then
        TriggerClientEvent('real_markers:client:editorResponse', src, requestId, false, {}, Config.SubtleStyles, 'Nincs jogosultságod. Add hozzá: add_ace group.admin real_markers.admin allow')
        return
    end
    TriggerClientEvent('real_markers:client:editorResponse', src, requestId, true, cachedDbMarkers, Config.SubtleStyles)
end)

RegisterNetEvent('real_markers:server:saveMarker', function(marker)
    local src = source
    if not isAdmin(src) then
        TriggerClientEvent('real_markers:client:notify', src, 'Nincs jogosultságod marker mentéshez.', 'error')
        return
    end
    if type(marker) ~= 'table' or not marker.id or marker.id == '' or not marker.coords then
        TriggerClientEvent('real_markers:client:notify', src, 'Hibás marker adat. ID és koordináta kötelező.', 'error')
        return
    end

    local c = marker.coords
    local permissions = encodePerms(marker.permissions)
    MySQL.update.await([[INSERT INTO real_markers
        (id, style, x, y, z, title, subtitle, help_text, event, server_event, target, target_label, draw_distance, interact_distance, permissions, status, theme, icon, mode, enabled)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        style=VALUES(style), x=VALUES(x), y=VALUES(y), z=VALUES(z), title=VALUES(title), subtitle=VALUES(subtitle), help_text=VALUES(help_text),
        event=VALUES(event), server_event=VALUES(server_event), target=VALUES(target), target_label=VALUES(target_label), draw_distance=VALUES(draw_distance),
        interact_distance=VALUES(interact_distance), permissions=VALUES(permissions), status=VALUES(status), theme=VALUES(theme), icon=VALUES(icon), mode=VALUES(mode), enabled=VALUES(enabled)]], {
        marker.id,
        marker.style or 'subtle_document',
        tonumber(c.x or c[1]) or 0.0,
        tonumber(c.y or c[2]) or 0.0,
        tonumber(c.z or c[3]) or 0.0,
        marker.title,
        marker.subtitle,
        marker.helpText,
        marker.event,
        marker.serverEvent and 1 or 0,
        marker.target and 1 or 0,
        marker.targetLabel,
        tonumber(marker.drawDistance),
        tonumber(marker.interactDistance),
        permissions,
        marker.status,
        marker.theme,
        marker.icon,
        marker.mode,
        marker.enabled == false and 0 or 1
    })

    loadDbMarkers()
    broadcastMarkers()
    TriggerClientEvent('real_markers:client:notify', src, 'Marker mentve MySQL-be.', 'success')
end)

RegisterNetEvent('real_markers:server:deleteMarker', function(id)
    local src = source
    if not isAdmin(src) then
        TriggerClientEvent('real_markers:client:notify', src, 'Nincs jogosultságod marker törléshez.', 'error')
        return
    end
    if not id or id == '' then
        TriggerClientEvent('real_markers:client:notify', src, 'Hiányzó marker ID.', 'error')
        return
    end
    MySQL.update.await('DELETE FROM real_markers WHERE id = ?', { id })
    loadDbMarkers()
    broadcastMarkers()
    TriggerClientEvent('real_markers:client:notify', src, 'Marker törölve.', 'success')
end)

RegisterCommand('rmreload', function(src)
    if not isAdmin(src) then return end
    loadDbMarkers()
    broadcastMarkers()
    if src ~= 0 then TriggerClientEvent('real_markers:client:notify', src, 'Markerek újratöltve MySQL-ből.', 'success') end
end, false)
