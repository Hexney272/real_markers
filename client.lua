-- real_markers v2 — Natív 3D DrawMarker rendszer (lebegő ikonok, NUI nélkül)
local activeMarkers = {}
local databaseMarkers = {}
local oxZones = {}
local demoEnabled = Config.EnableDemoMarkers == true
local ESX = nil
local playerJob = nil
local playerGrade = 0
local playerGroup = nil

local function getESX()
    if ESX then return ESX end
    if Config.UseESX and GetResourceState('es_extended') == 'started' then
        local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok then ESX = obj end
    end
    return ESX
end

local function refreshPlayerData()
    local esx = getESX()
    if not esx then return end
    local data = esx.GetPlayerData and esx.GetPlayerData() or {}
    if data.job then
        playerJob = data.job.name
        playerGrade = tonumber(data.job.grade or data.job.grade_level or 0) or 0
    end
    playerGroup = data.group or playerGroup
end

CreateThread(function()
    Wait(1000)
    refreshPlayerData()
    TriggerServerEvent('real_markers:server:requestMarkers')
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    if xPlayer and xPlayer.job then
        playerJob = xPlayer.job.name
        playerGrade = tonumber(xPlayer.job.grade or 0) or 0
    end
    refreshPlayerData()
end)

RegisterNetEvent('esx:setJob', function(job)
    if job then
        playerJob = job.name
        playerGrade = tonumber(job.grade or 0) or 0
    end
end)

local function toVec3(value)
    if type(value) == 'vector3' then return value end
    if type(value) == 'vector4' then return vec3(value.x, value.y, value.z) end
    if type(value) == 'table' then return vec3(value.x or value[1], value.y or value[2], value.z or value[3]) end
    return vec3(0.0, 0.0, 0.0)
end

local function showHelpText(message)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function hasItem(item, count)
    count = tonumber(count) or 1
    if not item or item == '' then return true end
    if Config.UseOxInventory and GetResourceState('ox_inventory') == 'started' then
        local ok, amount = pcall(function() return exports.ox_inventory:Search('count', item) end)
        if ok and (tonumber(amount) or 0) >= count then return true end
    end
    local esx = getESX()
    local pdata = esx and esx.GetPlayerData and esx.GetPlayerData() or {}
    if pdata.inventory then
        for _, invItem in pairs(pdata.inventory) do
            if invItem.name == item and (tonumber(invItem.count) or 0) >= count then return true end
        end
    end
    return false
end

local function localAccess(data)
    local permissions = data.visibility or data.permissions or data.access
    if not permissions then return true end
    if permissions.jobs then
        local minGrade = permissions.jobs[playerJob]
        if minGrade == nil then return false end
        if tonumber(playerGrade or 0) < tonumber(minGrade or 0) then return false end
    end
    if permissions.groups and playerGroup and not permissions.groups[playerGroup] then return false end
    if permissions.items then
        for item, required in pairs(permissions.items) do
            local cnt = required
            if type(required) == 'boolean' then cnt = required and 1 or 0 end
            if tonumber(cnt) and tonumber(cnt) > 0 and not hasItem(item, cnt) then return false end
        end
    end
    return true
end

local function mergeTable(base, override)
    local result = {}
    if base then for k, v in pairs(base) do result[k] = v end end
    if override then for k, v in pairs(override) do result[k] = v end end
    return result
end

local function prepareMarker(id, data, sourceType)
    if not id or not data or not data.coords then return nil end
    local styleName = data.style or 'info'
    local styleData = Config.Styles[styleName] or Config.Styles.info or {}
    local merged = mergeTable(styleData, data)
    merged.id = id
    merged.coords = toVec3(data.coords)
    merged.style = styleName
    merged.sourceType = sourceType or data.sourceType or 'local'
    return merged
end

-- ===== OX_TARGET =====

local function removeOxZone(id)
    if not oxZones[id] then return end
    if GetResourceState('ox_target') == 'started' then
        pcall(function() exports.ox_target:removeZone(oxZones[id]) end)
    end
    oxZones[id] = nil
end

local function registerOxZone(id, data)
    if not Config.UseOxTarget or not data.target then return end
    if GetResourceState('ox_target') ~= 'started' then return end
    removeOxZone(id)
    local coords = data.coords
    local distance = data.targetDistance or data.interactDistance or Config.TargetDistance or 2.0
    local label = data.title or id
    local icon = Config.TargetIcon or 'fa-solid fa-location-dot'
    local zoneId = exports.ox_target:addSphereZone({
        coords = coords,
        radius = distance,
        options = {
            {
                name = 'real_marker_' .. id,
                label = label,
                icon = icon,
                distance = distance,
                canInteract = function() return localAccess(data) end,
                onSelect = function() TriggerEvent('real_markers:client:interactMarker', id) end
            }
        }
    })
    oxZones[id] = zoneId
end

-- ===== MARKER INTERAKCIÓ =====

local function doMarkerAction(id, data)
    if not data then return end
    if data.event then
        if data.serverEvent then
            TriggerServerEvent(data.event, id, data.args)
        else
            TriggerEvent(data.event, id, data.args)
        end
    end
    if data.cb and type(data.cb) == 'function' then data.cb(id, data) end
end

RegisterNetEvent('real_markers:client:doAction', function(id, data)
    doMarkerAction(id, data)
end)

RegisterNetEvent('real_markers:client:accessDenied', function(_, reason)
    notify(reason or 'Nincs jogosultságod.')
end)

RegisterNetEvent('real_markers:client:interactMarker', function(id)
    local data = activeMarkers[id] or databaseMarkers[id]
    if not data then return end
    if not localAccess(data) then return notify('Nincs jogosultságod.') end
    if data.sourceType == 'db' and data.serverValidate ~= false then
        TriggerServerEvent('real_markers:server:interact', id)
    else
        doMarkerAction(id, data)
    end
end)

-- ===== EXPORTS =====

exports('RegisterImageMarker', function(id, data)
    local prepared = prepareMarker(id, data, 'local')
    if not prepared then return false end
    activeMarkers[id] = prepared
    registerOxZone(id, prepared)
    return true
end)

exports('RegisterCustomMarker', function(id, data)
    local prepared = prepareMarker(id, data, 'local')
    if not prepared then return false end
    activeMarkers[id] = prepared
    registerOxZone(id, prepared)
    return true
end)

exports('RegisterTargetMarker', function(id, data)
    data = data or {}
    data.target = true
    local prepared = prepareMarker(id, data, 'local')
    if not prepared then return false end
    activeMarkers[id] = prepared
    registerOxZone(id, prepared)
    return true
end)

exports('UpdateCustomMarker', function(id, data)
    if not id or not activeMarkers[id] then return false end
    activeMarkers[id] = mergeTable(activeMarkers[id], data or {})
    registerOxZone(id, activeMarkers[id])
    return true
end)

exports('RemoveCustomMarker', function(id)
    if not id then return false end
    activeMarkers[id] = nil
    removeOxZone(id)
    return true
end)

exports('ClearCustomMarkers', function()
    for id in pairs(activeMarkers) do removeOxZone(id) end
    activeMarkers = {}
    return true
end)

exports('GetMarkerStyles', function() return Config.Styles end)

-- ===== DATABASE MARKEREK =====

RegisterNetEvent('real_markers:client:setDatabaseMarkers', function(markers)
    for id in pairs(databaseMarkers) do removeOxZone(id) end
    databaseMarkers = {}
    for id, data in pairs(markers or {}) do
        local prepared = prepareMarker(id, data, 'db')
        if prepared then
            databaseMarkers[id] = prepared
            registerOxZone(id, prepared)
        end
    end
end)

RegisterNetEvent('real_markers:client:upsertDatabaseMarker', function(id, data)
    local prepared = prepareMarker(id, data, 'db')
    if not prepared then return end
    databaseMarkers[id] = prepared
    registerOxZone(id, prepared)
end)

RegisterNetEvent('real_markers:client:removeDatabaseMarker', function(id)
    databaseMarkers[id] = nil
    removeOxZone(id)
end)

-- ===== DEMO MARKEREK =====

local function applyDemoMarkers(state)
    demoEnabled = state == true
    for i, marker in ipairs(Config.DemoMarkers or {}) do
        local id = 'demo_' .. i
        if demoEnabled then
            local prepared = prepareMarker(id, marker, 'local')
            if prepared then activeMarkers[id] = prepared registerOxZone(id, prepared) end
        else
            activeMarkers[id] = nil
            removeOxZone(id)
        end
    end
end

CreateThread(function()
    if Config.EnableDemoMarkers then applyDemoMarkers(true) end
end)

-- ===== FŐ RENDER LOOP — natív 3D DrawMarker =====

CreateThread(function()
    local M = Config.Marker
    local mType = M.Type or 2
    local mSize = M.Size or { x = 0.55, y = 0.55, z = 0.55 }
    local mZOff = M.ZOffset or 1.35
    local bob = M.Bob ~= false
    local bobSpeed = M.BobSpeed or 1.8
    local bobHeight = M.BobHeight or 0.12
    local rotate = M.Rotate ~= false
    local rotateSpeed = M.RotateSpeed or 1.0
    local faceCamera = M.FaceCamera == true
    local groundRing = M.GroundRing ~= false
    local groundType = M.GroundType or 1
    local groundSize = M.GroundSize or 1.2
    local groundZOff = M.GroundZOffset or -0.95
    local groundAlpha = M.GroundAlpha or 100
    local nearPulse = M.NearPulse ~= false
    local nearPulseMin = M.NearPulseMin or 0.92
    local nearPulseMax = M.NearPulseMax or 1.08
    local nearPulseSpeed = M.NearPulseSpeed or 2.5
    local drawDist = Config.DefaultDrawDistance or 30.0
    local interactDist = Config.DefaultInteractDistance or 2.0
    local interactKey = Config.DefaultKey or 38

    local rotAngle = 0.0

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local closestMarker = nil
        local closestDist = 999999.0

        local allMarkers = {}
        for id, data in pairs(activeMarkers) do allMarkers[id] = data end
        for id, data in pairs(databaseMarkers) do allMarkers[id] = data end

        local hasAny = false
        for id, data in pairs(allMarkers) do
            if localAccess(data) then
                local coords = data.coords
                local dx = playerCoords.x - coords.x
                local dy = playerCoords.y - coords.y
                local dz = playerCoords.z - coords.z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                local dd = data.drawDistance or drawDist

                if dist <= dd then
                    hasAny = true
                    local col = data.color or { r=100, g=180, b=255, a=160 }
                    local r, g, b, a = col.r or 100, col.g or 180, col.b or 255, col.a or 160

                    local id2 = data.interactDistance or interactDist
                    local isNear = dist <= id2

                    -- Ha useImage=true, nem rajzolunk natív DrawMarker-t (a NUI kép lesz a marker)
                    if not data.useImage then
                        local zOff = data.zOffset or mZOff
                        if bob then
                            local t = GetGameTimer() / 1000.0 * bobSpeed
                            zOff = zOff + math.sin(t) * bobHeight
                        end

                        local rotX, rotY, rotZ = 0.0, 0.0, 0.0
                        if faceCamera then
                            local camRot = GetGameplayCamRot(2)
                            rotZ = -camRot.z
                        elseif rotate then
                            rotAngle = rotAngle + rotateSpeed
                            if rotAngle > 360.0 then rotAngle = rotAngle - 360.0 end
                            rotZ = rotAngle
                        end

                        local sx, sy, sz = mSize.x, mSize.y, mSize.z
                        if data.scale then
                            sx = sx * data.scale
                            sy = sy * data.scale
                            sz = sz * data.scale
                        end
                        if isNear and nearPulse then
                            local t = GetGameTimer() / 1000.0 * nearPulseSpeed
                            local pulse = nearPulseMin + (nearPulseMax - nearPulseMin) * ((math.sin(t) + 1.0) / 2.0)
                            sx = sx * pulse
                            sy = sy * pulse
                            sz = sz * pulse
                        end

                        local markerType = data.markerType or mType
                        DrawMarker(
                            markerType,
                            coords.x, coords.y, coords.z + zOff,
                            0.0, 0.0, 0.0,
                            rotX, rotY, rotZ,
                            sx, sy, sz,
                            r, g, b, a,
                            bob, faceCamera, 2, rotate, nil, nil, false
                        )

                        if groundRing and dist <= dd * 0.6 then
                            local gs = data.groundSize or groundSize
                            local ga = data.groundAlpha or groundAlpha
                            DrawMarker(
                                groundType,
                                coords.x, coords.y, coords.z + groundZOff,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                gs, gs, 0.06,
                                r, g, b, ga,
                                false, false, 2, false, nil, nil, false
                            )
                        end
                    else
                        -- useImage mode: csak ground ring marad
                        if groundRing and dist <= dd * 0.6 then
                            local gs = data.groundSize or groundSize
                            local ga = data.groundAlpha or groundAlpha
                            DrawMarker(
                                groundType,
                                coords.x, coords.y, coords.z + groundZOff,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                gs, gs, 0.06,
                                r, g, b, ga,
                                false, false, 2, false, nil, nil, false
                            )
                        end
                    end

                    if isNear and dist < closestDist and not (Config.UseOxTarget and data.target) then
                        closestDist = dist
                        closestMarker = data
                    end
                end
            end
        end

        if closestMarker then
            local helpTxt = closestMarker.helpText or '~INPUT_CONTEXT~ Interakció'
            showHelpText(helpTxt)
            if IsControlJustReleased(0, closestMarker.key or interactKey) then
                TriggerEvent('real_markers:client:interactMarker', closestMarker.id)
            end
        end

        -- NUI badge: közelről (5m) apró címke a marker felett
        if not editorOpen then
            local badgeDist = Config.Marker.BadgeDistance or 5.0
            local badges = {}
            for _, data in pairs(allMarkers) do
                if localAccess(data) then
                    local coords = data.coords
                    local dx = playerCoords.x - coords.x
                    local dy = playerCoords.y - coords.y
                    local dz = playerCoords.z - coords.z
                    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                    local thisBadgeDist = badgeDist
                    if data.useImage then
                        thisBadgeDist = data.drawDistance or drawDist
                    end

                    if dist <= thisBadgeDist then
                        local zOff = (data.zOffset or mZOff) + 0.45
                        if data.useImage then
                            zOff = (data.zOffset or mZOff)
                            if bob then
                                local t = GetGameTimer() / 1000.0 * bobSpeed
                                zOff = zOff + math.sin(t) * bobHeight
                            end
                        end
                        local onScreen, sx, sy = World3dToScreen2d(coords.x, coords.y, coords.z + zOff)
                        if onScreen then
                            local alpha = 1.0
                            if not data.useImage then
                                if dist > thisBadgeDist * 0.6 then
                                    alpha = 1.0 - ((dist - thisBadgeDist * 0.6) / (thisBadgeDist * 0.4))
                                end
                            else
                                local fadeStart = thisBadgeDist * 0.75
                                if dist > fadeStart then
                                    alpha = 1.0 - ((dist - fadeStart) / (thisBadgeDist - fadeStart))
                                end
                            end

                            local scale = 1
                            if data.useImage then
                                local baseScale = data.imageScale or 2.5
                                local distFactor = 1.0 - (dist / thisBadgeDist) * 0.4
                                scale = baseScale * distFactor
                                if dist <= (data.interactDistance or interactDist) and nearPulse then
                                    local t = GetGameTimer() / 1000.0 * nearPulseSpeed
                                    local pulse = nearPulseMin + (nearPulseMax - nearPulseMin) * ((math.sin(t) + 1.0) / 2.0)
                                    scale = scale * pulse
                                end
                            end

                            local labelDist = data.labelDistance or 3.0
                            badges[#badges + 1] = {
                                id = data.id,
                                x = sx,
                                y = sy,
                                alpha = alpha,
                                title = data.title or '',
                                keyText = 'E',
                                near = dist <= (data.interactDistance or interactDist),
                                showLabel = dist <= labelDist,
                                showInteract = dist <= (data.interactDistance or interactDist),
                                theme = data.theme or 'sky',
                                icon = data.icon or 'wrench',
                                subtitle = '',
                                scale = scale,
                                useImage = data.useImage or false,
                            }
                        end
                    end
                end
            end
            SendNUIMessage({ action = 'setMarkers', markers = badges })
        end

        if hasAny then
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ===== ADMIN PARANCSOK =====

if Config.EnableAdminCommands then
    RegisterCommand('rmcreate', function(_, args)
        local id, style = args[1], args[2]
        if not id or not style then return notify('Használat: /rmcreate id style') end
        local coords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('real_markers:server:adminCreate', {
            id = id,
            style = style,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            helpText = '~INPUT_CONTEXT~ Interakció'
        })
    end, false)

    RegisterCommand('rmmove', function(_, args)
        local id = args[1]
        if not id then return notify('Használat: /rmmove id') end
        local coords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('real_markers:server:adminUpdate', id, { coords = { x = coords.x, y = coords.y, z = coords.z } })
    end, false)

    RegisterCommand('rmdelete', function(_, args)
        local id = args[1]
        if not id then return notify('Használat: /rmdelete id') end
        TriggerServerEvent('real_markers:server:adminDelete', id)
    end, false)

    RegisterCommand('rmstatus', function(_, args)
        local id, status = args[1], args[2]
        if not id or not status then return notify('Használat: /rmstatus id STATUS') end
        TriggerServerEvent('real_markers:server:adminUpdate', id, { status = status })
    end, false)
end

if Config.EnableDemoCommand then
    RegisterCommand('markerdemo', function()
        applyDemoMarkers(not demoEnabled)
        notify(('Demo markerek: %s'):format(demoEnabled and 'bekapcsolva' or 'kikapcsolva'))
    end, false)
end

if Config.EnableClearCommand then
    RegisterCommand('markerclear', function()
        for id in pairs(activeMarkers) do removeOxZone(id) end
        activeMarkers = {}
        notify('Lokális markerek törölve.')
    end, false)
end

-- Demo eventek
local demoEvents = { 'garage', 'mechanic', 'document', 'shop', 'police', 'warning', 'hospital', 'jobcenter', 'bank', 'blackmarket', 'event', 'real_registry', 'real_inspection', 'real_dealership', 'real_faction_hq', 'real_company_dashboard', 'real_illegal_market', 'real_mining', 'real_fishing', 'real_vip', 'real_cityhall' }
for _, name in ipairs(demoEvents) do
    RegisterNetEvent('real_markers:demo:' .. name, function()
        print(('[real_markers] Demo marker hasznalva: %s'):format(name))
    end)
end



-- ===== NUI EDITOR (rmeditor parancs) =====
-- A NUI CSAK az editor megnyitásakor aktív (SetNuiFocus),
-- a markerek továbbra is natív DrawMarker-ek, nincs NUI resmon.

local editorOpen = false

local function openEditor()
    if editorOpen then return end
    editorOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openEditor',
        styles = Config.Styles
    })
    -- Kérjük a szerveri marker listát az editorhoz
    TriggerServerEvent('real_markers:server:editorGetData')
end

local function closeEditor()
    if not editorOpen then return end
    editorOpen = false
    SetNuiFocus(false, false)
end

RegisterNetEvent('real_markers:client:editorData', function(data)
    SendNUIMessage({
        action = 'editorData',
        ok = data.ok ~= false,
        styles = Config.Styles,
        markers = data.markers or {},
        message = data.message
    })
end)

RegisterNUICallback('closeEditor', function(_, cb)
    closeEditor()
    cb({ ok = true })
end)

RegisterNUICallback('getPlayerCoords', function(_, cb)
    local coords = GetEntityCoords(PlayerPedId())
    cb({ ok = true, x = tonumber(string.format('%.3f', coords.x)), y = tonumber(string.format('%.3f', coords.y)), z = tonumber(string.format('%.3f', coords.z)) })
end)

RegisterNUICallback('previewMarker', function(data, cb)
    if type(data) ~= 'table' or not data.coords then
        cb({ ok = false })
        return
    end
    -- Helyi preview: regisztrálunk egy ideiglenes markert 20 mp-re
    local id = '__editor_preview__'
    exports['real_markers']:RemoveCustomMarker(id)
    exports['real_markers']:RegisterImageMarker(id, data)
    SetTimeout(20000, function()
        exports['real_markers']:RemoveCustomMarker(id)
    end)
    cb({ ok = true })
end)

RegisterNUICallback('saveMarker', function(data, cb)
    if type(data) ~= 'table' or not data.id or data.id == '' then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('real_markers:server:adminCreate', data)
    -- Frissítjük az editor listáját
    Wait(300)
    TriggerServerEvent('real_markers:server:editorGetData')
    cb({ ok = true })
end)

RegisterNUICallback('deleteMarker', function(data, cb)
    if type(data) ~= 'table' or not data.id or data.id == '' then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('real_markers:server:adminDelete', data.id)
    Wait(300)
    TriggerServerEvent('real_markers:server:editorGetData')
    cb({ ok = true })
end)

RegisterCommand('rmeditor', function()
    openEditor()
end, false)

-- ESC bezárás kezelés (ha a NUI-ban nem kapja el)
CreateThread(function()
    while true do
        if editorOpen and IsControlJustReleased(0, 177) then -- 177 = ESC / Backspace
            closeEditor()
        end
        Wait(editorOpen and 0 or 500)
    end
end)
