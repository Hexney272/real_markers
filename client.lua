
local activeMarkers = {}
local dbMarkers = {}
local nearbyMarkers = {}
local frameMarkers = {}
local lastPayload = ''
local editorRequest = 0
local createdTargets = {}
local permissionCache = {}

local function mergeTable(base, override)
    local result = {}
    if base then
        for k, v in pairs(base) do
            if type(v) == 'table' and type(v.x) ~= 'number' then result[k] = mergeTable(v, nil) else result[k] = v end
        end
    end
    if override then
        for k, v in pairs(override) do
            if type(v) == 'table' and type(result[k]) == 'table' and type(v.x) ~= 'number' then result[k] = mergeTable(result[k], v) else result[k] = v end
        end
    end
    return result
end

local function toVec3(value)
    if type(value) == 'vector3' then return value end
    if type(value) == 'vector4' then return vec3(value.x, value.y, value.z) end
    if type(value) == 'table' then return vec3(tonumber(value.x or value[1]) or 0.0, tonumber(value.y or value[2]) or 0.0, tonumber(value.z or value[3]) or 0.0) end
    return vec3(0.0, 0.0, 0.0)
end

local function showHelpText(message)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function notify(msg, typ)
    SendNUIMessage({ action = 'notify', message = msg, type = typ or 'info' })
end
RegisterNetEvent('real_markers:client:notify', notify)

local function prepareMarker(id, data)
    if not id or not data or not data.coords then return nil end
    local styleName = data.style or 'subtle_document'
    local styleData = Config.SubtleStyles[styleName] or Config.SubtleStyles.subtle_document or {}
    local merged = mergeTable(styleData, data)
    merged.id = id
    merged.coords = toVec3(data.coords)
    merged.style = styleName
    return merged
end

local function hasPermissions(id, data)
    local p = data.permissions
    if not p then return true end

    local now = GetGameTimer()
    local cached = permissionCache[id]
    if cached and cached.expires > now then return cached.ok end

    local okPermission = true

    if p.jobs then
        okPermission = false
        local ok, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and ESX and ESX.GetPlayerData then
            local pd = ESX.GetPlayerData()
            if pd and pd.job and p.jobs[pd.job.name] ~= nil then
                local minGrade = tonumber(p.jobs[pd.job.name]) or 0
                if (pd.job.grade or 0) >= minGrade then okPermission = true end
            end
        end
    end

    if okPermission and p.items and Config.UseOxInventory then
        for item, count in pairs(p.items) do
            local ok, amount = pcall(function() return exports.ox_inventory:Search('count', item) end)
            if not ok or (amount or 0) < (tonumber(count) or 1) then okPermission = false break end
        end
    end

    permissionCache[id] = { ok = okPermission, expires = now + (Config.PermissionCacheTime or 3000) }
    return okPermission
end

local function drawGroundDot(coords, data, distance)
    if not Config.EnableGroundDot or data.ground == false then return end
    if distance > (Config.GroundDotMaxDistance or 5.0) then return end
    local color = data.color or { r=92,g=190,b=230,a=100 }
    local alpha = math.floor((color.a or 100) * math.max(0.15, 1.0 - (distance / (Config.GroundDotMaxDistance or 5.0))))
    DrawMarker(1, coords.x, coords.y, coords.z + (Config.GroundDotZOffset or -0.96), 0.0,0.0,0.0, 0.0,0.0,0.0, 0.42,0.42,0.025, color.r or 255, color.g or 255, color.b or 255, alpha, false,false,2,false,nil,nil,false)
end


local function rotationToDirection(rotation)
    local adjustedRotation = {
        x = math.rad(rotation.x),
        y = math.rad(rotation.y),
        z = math.rad(rotation.z)
    }

    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y =  math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z =  math.sin(adjustedRotation.x)
    }

    return direction
end

local function clearNuiMarkers()
    SendNUIMessage({ action = 'clearMarkers' })
    lastPayload = '[]'
end

local function buildNuiMarker(marker, distance)
    local data = marker.data
    local coords = marker.coords
    local zOffset = data.zOffset or 1.0

    -- Beragadas elleni vedelem: ha a marker a kamera mogott van, vagy kicsuszott a kepernyorol, nem kuldjuk NUI-ba.
    local markerPos = vec3(coords.x, coords.y, coords.z + zOffset)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local camForward = rotationToDirection(camRot)
    local toMarker = markerPos - camCoords
    local dot = (camForward.x * toMarker.x) + (camForward.y * toMarker.y) + (camForward.z * toMarker.z)
    if dot <= 0.05 then return nil end

    local onScreen, x, y = World3dToScreen2d(markerPos.x, markerPos.y, markerPos.z)
    if not onScreen then return nil end
    if x < -0.08 or x > 1.08 or y < -0.08 or y > 1.08 then return nil end

    local drawDistance = data.drawDistance or Config.DefaultDrawDistance
    local fadeStart = data.fadeStart or (drawDistance * 0.45)
    local alpha = 1.0
    if distance > fadeStart then
        alpha = 1.0 - ((distance - fadeStart) / (drawDistance - fadeStart))
        if alpha < 0.04 then alpha = 0.04 end
    end

    local near = distance <= (data.interactDistance or Config.DefaultInteractDistance)
    local mode = data.mode or 'icon_interact'
    local scale = (data.scale or 0.82) * math.max(0.74, math.min(1.05, 7.0 / math.max(distance, 6.0)))

    return {
        id = marker.id,
        x = x,
        y = y,
        alpha = alpha,
        scale = scale,
        theme = data.theme or 'sky',
        mode = mode,
        icon = data.icon or 'document',
        title = data.title or 'Interakció',
        subtitle = data.status or data.subtitle or '',
        near = near,
        keyText = data.keyText or 'E',
        showLabel = mode == 'icon_label' or near,
        showInteract = near and mode ~= 'icon'
    }
end

local function refreshOxTargets()
    if not Config.UseOxTarget then return end
    if GetResourceState(Config.OxTargetResource or 'ox_target') ~= 'started' then return end
    for id, zoneId in pairs(createdTargets) do
        pcall(function() exports.ox_target:removeZone(zoneId) end)
        createdTargets[id] = nil
    end
    for id, data in pairs(activeMarkers) do
        if data.target and hasPermissions(id, data) then
            local zoneId = exports.ox_target:addSphereZone({
                coords = data.coords,
                radius = data.interactDistance or Config.DefaultInteractDistance,
                debug = false,
                options = {{
                    label = data.targetLabel or data.title or 'Interakció',
                    icon = 'fa-solid fa-circle-dot',
                    onSelect = function()
                        if data.event then
                            if data.serverEvent then TriggerServerEvent(data.event, id, data.args) else TriggerEvent(data.event, id, data.args) end
                        end
                    end
                }}
            })
            createdTargets[id] = zoneId
        end
    end
end

local function rebuildActiveMarkers()
    activeMarkers = {}
    permissionCache = {}
    for id, marker in pairs(dbMarkers) do
        local prepared = prepareMarker(id, marker)
        if prepared and prepared.enabled ~= false then activeMarkers[id] = prepared end
    end
    if Config.EnableDemoMarkers then
        for i, marker in ipairs(Config.DemoMarkers or {}) do
            local id = marker.id or ('demo_'..i)
            local prepared = prepareMarker(id, marker)
            if prepared then activeMarkers[id] = prepared end
        end
    end
    refreshOxTargets()
end

RegisterNetEvent('real_markers:client:setDbMarkers', function(markers)
    dbMarkers = {}
    for _, m in ipairs(markers or {}) do
        if m.id then dbMarkers[m.id] = m end
    end
    rebuildActiveMarkers()
end)

RegisterNetEvent('real_markers:client:editorResponse', function(requestId, ok, markers, styles, message)
    if requestId ~= editorRequest then return end
    SendNUIMessage({ action='editorData', ok=ok, markers=markers or {}, styles=styles or Config.SubtleStyles, message=message })
end)

CreateThread(function()
    Wait(1200)
    TriggerServerEvent('real_markers:server:requestMarkers')
    rebuildActiveMarkers()
end)

exports('RegisterImageMarker', function(id, data)
    local prepared = prepareMarker(id, data)
    if not prepared then return false end
    activeMarkers[id] = prepared
    refreshOxTargets()
    return true
end)
exports('RegisterCustomMarker', function(id, data)
    local prepared = prepareMarker(id, data)
    if not prepared then return false end
    activeMarkers[id] = prepared
    refreshOxTargets()
    return true
end)
exports('RegisterTargetMarker', function(id, data)
    data = data or {}; data.target = true
    local prepared = prepareMarker(id, data)
    if not prepared then return false end
    activeMarkers[id] = prepared
    refreshOxTargets()
    return true
end)
exports('DrawCustomMarker', function(styleName, coords, options)
    local id = 'frame_' .. tostring(#frameMarkers + 1)
    local data = mergeTable(options or {}, { style=styleName, coords=coords })
    local prepared = prepareMarker(id, data)
    if prepared then frameMarkers[#frameMarkers+1] = { id=id, coords=prepared.coords, data=prepared } end
    return true
end)
exports('UpdateCustomMarker', function(id, data)
    if not activeMarkers[id] then return false end
    activeMarkers[id] = mergeTable(activeMarkers[id], data or {})
    activeMarkers[id].coords = toVec3(activeMarkers[id].coords)
    refreshOxTargets()
    return true
end)
exports('RemoveCustomMarker', function(id)
    activeMarkers[id] = nil
    refreshOxTargets()
    return true
end)
exports('ClearCustomMarkers', function()
    activeMarkers = {}; nearbyMarkers = {}; frameMarkers = {}; refreshOxTargets()
    return true
end)
exports('GetMarkerStyles', function() return Config.SubtleStyles end)

CreateThread(function()
    while true do
        local pc = GetEntityCoords(PlayerPedId())
        local list = {}
        for id, data in pairs(activeMarkers) do
            if hasPermissions(id, data) then
                local c = data.coords
                local dx,dy,dz = pc.x-c.x, pc.y-c.y, pc.z-c.z
                local distSq = dx*dx+dy*dy+dz*dz
                local dd = data.drawDistance or Config.DefaultDrawDistance
                if distSq <= dd*dd then list[#list+1] = { id=id, coords=c, data=data, distSq=distSq } end
            end
        end
        table.sort(list, function(a,b) return a.distSq < b.distSq end)
        nearbyMarkers = {}
        for i=1, math.min(#list, Config.MaxVisibleMarkers or 5) do nearbyMarkers[i] = list[i] end
        Wait(Config.CoarseRefreshInterval or 650)
    end
end)

CreateThread(function()
    while true do
        if Config.HideWhenPauseMenu and IsPauseMenuActive() then
            if lastPayload ~= '[]' then clearNuiMarkers() end
            Wait(250)
        else
            local has = #nearbyMarkers > 0 or #frameMarkers > 0
            if not has then
                if lastPayload ~= '[]' then clearNuiMarkers() end
                Wait(300)
            else
                local pc = GetEntityCoords(PlayerPedId())
                local output = {}
                local nearest, nearestDist = nil, 9999.0
                local combined = {}
                for i=1,#nearbyMarkers do combined[#combined+1] = nearbyMarkers[i] end
                for i=1,#frameMarkers do combined[#combined+1] = frameMarkers[i] end
                frameMarkers = {}

                for i=1,#combined do
                    local m = combined[i]
                    local c = m.coords
                    local dist = #(pc - c)
                    if dist <= (m.data.drawDistance or Config.DefaultDrawDistance) then
                        drawGroundDot(c, m.data, dist)
                        local nui = buildNuiMarker(m, dist)
                        if nui then output[#output+1] = nui end
                        if not Config.UseOxTarget and dist <= (m.data.interactDistance or Config.DefaultInteractDistance) and dist < nearestDist then
                            nearest, nearestDist = m, dist
                        end
                    end
                end

                if nearest then
                    local data = nearest.data
                    if data.helpText then showHelpText(data.helpText) end
                    if IsControlJustReleased(0, data.key or Config.DefaultKey) then
                        if data.event then
                            if data.serverEvent then TriggerServerEvent(data.event, nearest.id, data.args) else TriggerEvent(data.event, nearest.id, data.args) end
                        end
                        if type(data.cb) == 'function' then data.cb(nearest.id, data) end
                    end
                end

                -- Smooth kamera: a NUI csak meglévő DOM node-ok transformját frissíti, nem építi újra.
                local payload = json.encode(output)
                if payload ~= lastPayload or (Config.NuiRefreshInterval or 0) == 0 then
                    SendNUIMessage({action='setMarkers', markers=output})
                    lastPayload=payload
                end
                Wait(Config.NuiRefreshInterval or 0)
            end
        end
    end
end)

local function openEditor()
    if not Config.EnableEditorNui then return end
    SetNuiFocus(true, true)
    editorRequest = editorRequest + 1
    SendNUIMessage({ action='openEditor', styles=Config.SubtleStyles })
    TriggerServerEvent('real_markers:server:editorRequest', editorRequest)
end

RegisterNUICallback('closeEditor', function(_, cb)
    SetNuiFocus(false, false)
    cb({ok=true})
end)
RegisterNUICallback('getPlayerCoords', function(_, cb)
    local c = GetEntityCoords(PlayerPedId())
    cb({ ok=true, x=tonumber(string.format('%.3f', c.x)), y=tonumber(string.format('%.3f', c.y)), z=tonumber(string.format('%.3f', c.z)) })
end)
RegisterNUICallback('previewMarker', function(data, cb)
    if not data.coords then data.coords = GetEntityCoords(PlayerPedId()) end
    data.id = Config.EditorPreviewId
    exports['real_markers']:RegisterImageMarker(Config.EditorPreviewId, data)
    SetTimeout(Config.EditorPreviewDuration or 30000, function() activeMarkers[Config.EditorPreviewId] = nil end)
    notify('Preview marker lerakva 30 másodpercre.', 'success')
    cb({ok=true})
end)
RegisterNUICallback('saveMarker', function(data, cb)
    TriggerServerEvent('real_markers:server:saveMarker', data)
    SetTimeout(500, function()
        editorRequest = editorRequest + 1
        TriggerServerEvent('real_markers:server:editorRequest', editorRequest)
    end)
    cb({ok=true})
end)
RegisterNUICallback('deleteMarker', function(data, cb)
    if data and data.id then TriggerServerEvent('real_markers:server:deleteMarker', data.id) end
    SetTimeout(500, function()
        editorRequest = editorRequest + 1
        TriggerServerEvent('real_markers:server:editorRequest', editorRequest)
    end)
    cb({ok=true})
end)

if Config.EnableCommands then
    RegisterCommand(Config.EditorCommand or 'rmeditor', openEditor, false)
    RegisterCommand('rmpreview', function(_, args)
        local style = args[1] or 'subtle_wrench'
        local c = GetEntityCoords(PlayerPedId())
        exports['real_markers']:RegisterImageMarker(Config.EditorPreviewId, { style=style, coords=c, title='Preview', subtitle=style })
        notify('Preview marker lerakva.', 'success')
    end, false)
    RegisterCommand('rmreload', function() TriggerServerEvent('real_markers:server:reloadMarkers') end, false)
    RegisterCommand('markerclear', function() activeMarkers = {}; nearbyMarkers = {}; clearNuiMarkers() end, false)
end

RegisterNetEvent('real_markers:demo:use', function(id)
    print('[real_markers] subtle demo marker: ' .. tostring(id))
end)


AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    clearNuiMarkers()
end)
