Config = {}

-- ===== ALAP BEÁLLÍTÁSOK =====
Config.DefaultDrawDistance = 30.0
Config.DefaultInteractDistance = 2.0
Config.DefaultKey = 38

-- MySQL mentés. oxmysql szükséges.
Config.UseDatabase = true
Config.AutoCreateTable = true
Config.DatabaseTable = 'real_markers'
Config.LoadDatabaseMarkersOnStart = true

-- Admin jogosultság. ACE: add_ace group.admin real_markers.admin allow
Config.AdminAce = 'real_markers.admin'
Config.AdminGroups = {
    admin = true,
    superadmin = true,
    owner = true,
    developer = true
}

-- Parancsok
Config.EnableAdminCommands = true
Config.EnableDemoMarkers = true
Config.EnableDemoCommand = true
Config.EnableClearCommand = true

-- Permission check beállítások
Config.UseESX = true
Config.UseOxInventory = true
Config.UseOxTarget = false
Config.TargetDistance = 2.0
Config.TargetIcon = 'fa-solid fa-location-dot'

-- ===== 3D MARKER BEÁLLÍTÁSOK =====
Config.Marker = {
    Type = 2,
    Size = { x = 0.55, y = 0.55, z = 0.55 },
    ZOffset = 1.35,
    Bob = true,
    BobSpeed = 1.8,
    BobHeight = 0.12,
    Rotate = true,
    RotateSpeed = 1.0,
    FaceCamera = false,

    GroundRing = true,
    GroundType = 1,
    GroundSize = 1.2,
    GroundZOffset = -0.95,
    GroundAlpha = 100,

    NearPulse = true,
    NearPulseMin = 0.92,
    NearPulseMax = 1.08,
    NearPulseSpeed = 2.5,

    -- Közelről megjelenő NUI badge (apró címke a marker felett)
    BadgeDistance = 5.0   -- ezen belül jelenik meg a kis NUI badge
}

-- ===== STÍLUSOK =====
-- theme: NUI szín téma | icon: ikon név (web/icons/ mappából) | color: DrawMarker RGBA
Config.Styles = {
    garage         = { theme='holo', icon='car',       color = { r=120, g=255, b=160, a=165 }, title = 'Garázs',              helpText = '~INPUT_CONTEXT~ Garázs' },
    mechanic       = { theme='holo',   icon='wrench',    color = { r=120, g=255, b=160, a=165 }, title = 'Szerviz',             helpText = '~INPUT_CONTEXT~ Szerviz' },
    impound        = { theme='amber', icon='truck',     color = { r=255, g=140, b=50,  a=160 }, title = 'Telephely',           helpText = '~INPUT_CONTEXT~ Telephely' },
    document       = { theme='holo',  icon='document',  color = { r=120, g=255, b=160, a=165 }, title = 'Okmányiroda',         helpText = '~INPUT_CONTEXT~ Okmányiroda' },
    shop           = { theme='holo',  icon='basket',    color = { r=120, g=255, b=160, a=165 }, title = 'Bolt',                helpText = '~INPUT_CONTEXT~ Bolt' },
    police         = { theme='holo',  icon='shield',    color = { r=120, g=255, b=160, a=175 }, title = 'Rendőrség',           helpText = '~INPUT_CONTEXT~ Rendőrség' },
    hospital       = { theme='holo',  icon='hospital',  color = { r=120, g=255, b=160, a=165 }, title = 'Kórház',              helpText = '~INPUT_CONTEXT~ Kórház' },
    warning        = { theme='red',   icon='warning',   color = { r=255, g=60,  b=60,  a=180 }, title = 'Veszély',             helpText = '~INPUT_CONTEXT~ Veszély' },
    info           = { theme='holo',  icon='star',      color = { r=120, g=255, b=160, a=150 }, title = 'Információ',          helpText = '~INPUT_CONTEXT~ Információ' },
    bank           = { theme='holo',  icon='bank',      color = { r=120, g=255, b=160, a=165 }, title = 'Bank',                helpText = '~INPUT_CONTEXT~ Bank' },
    jobcenter      = { theme='holo',icon='briefcase', color = { r=120, g=255, b=160, a=165 }, title = 'Munkaügyi központ',   helpText = '~INPUT_CONTEXT~ Munkafelvétel' },
    fuel           = { theme='holo',  icon='fuel',      color = { r=120, g=255, b=160, a=165 }, title = 'Tankolás',            helpText = '~INPUT_CONTEXT~ Tankolás' },
    clothing       = { theme='holo',  icon='clothing',  color = { r=120, g=255, b=160, a=165 }, title = 'Ruhabolt',            helpText = '~INPUT_CONTEXT~ Öltözés' },
    house          = { theme='amber', icon='house',     color = { r=255, g=200, b=60,  a=150 }, title = 'Ingatlan',            helpText = '~INPUT_CONTEXT~ Belépés' },
    warehouse      = { theme='white', icon='box',       color = { r=200, g=215, b=240, a=150 }, title = 'Raktár',              helpText = '~INPUT_CONTEXT~ Raktár' },
    faction        = { theme='holo',icon='users',     color = { r=120, g=255, b=160, a=165 }, title = 'Frakció',             helpText = '~INPUT_CONTEXT~ Frakció' },
    blackmarket    = { theme='red',   icon='mask',      color = { r=220, g=50,  b=90,  a=170 }, title = 'Feketepiac',          helpText = '~INPUT_CONTEXT~ Feketepiac' },
    teleport       = { theme='holo',  icon='star',      color = { r=120, g=255, b=160, a=165 }, title = 'Teleport',            helpText = '~INPUT_CONTEXT~ Teleport' },
    event          = { theme='purple',icon='crown',     color = { r=170, g=110, b=255, a=170 }, title = 'Esemény',             helpText = '~INPUT_CONTEXT~ Esemény' },
    crafting       = { theme='holo', icon='gear',      color = { r=120, g=255, b=160, a=165 }, title = 'Crafting',            helpText = '~INPUT_CONTEXT~ Készítés' },
    fishing        = { theme='cyan',  icon='fishing',   color = { r=80,  g=210, b=240, a=150 }, title = 'Horgászat',           helpText = '~INPUT_CONTEXT~ Horgászat' },
    mining         = { theme='amber', icon='pickaxe',   color = { r=240, g=200, b=80,  a=160 }, title = 'Bányászat',           helpText = '~INPUT_CONTEXT~ Bányászat' },
    carwash        = { theme='cyan',  icon='droplet',   color = { r=90,  g=210, b=240, a=150 }, title = 'Autómosó',            helpText = '~INPUT_CONTEXT~ Mosás' },

    -- REALRPG stílusok
    real_registry     = { theme='holo',   icon='document',  color = { r=120, g=255, b=160, a=170 }, title = 'Okmányiroda',       helpText = '~INPUT_CONTEXT~ Okmányiroda' },
    real_inspection   = { theme='holo',    icon='wrench',    color = { r=120, g=255, b=160, a=170 }, title = 'Műszaki vizsga',    helpText = '~INPUT_CONTEXT~ Műszaki vizsga' },
    real_dealership   = { theme='holo',  icon='car',       color = { r=120, g=255, b=160, a=170 }, title = 'Autókereskedés',    helpText = '~INPUT_CONTEXT~ Autókereskedés' },
    real_faction_hq   = { theme='holo', icon='users',     color = { r=120, g=255, b=160, a=170 }, title = 'Frakció központ',   helpText = '~INPUT_CONTEXT~ Frakció központ' },
    real_company      = { theme='holo',   icon='briefcase', color = { r=120, g=255, b=160, a=170 }, title = 'Cég dashboard',     helpText = '~INPUT_CONTEXT~ Cég' },
    real_illegal      = { theme='red',    icon='mask',      color = { r=220, g=55,  b=95,  a=175 }, title = 'Illegál piac',      helpText = '~INPUT_CONTEXT~ Illegál piac' },
    real_mining       = { theme='amber',  icon='pickaxe',   color = { r=240, g=200, b=80,  a=160 }, title = 'Bánya',             helpText = '~INPUT_CONTEXT~ Bánya' },
    real_fishing      = { theme='cyan',   icon='fishing',   color = { r=90,  g=220, b=245, a=160 }, title = 'Horgászhely',       helpText = '~INPUT_CONTEXT~ Horgászhely' },
    real_vip          = { theme='holo',   icon='crown',     color = { r=120, g=255, b=160, a=170 }, title = 'VIP zóna',          helpText = '~INPUT_CONTEXT~ VIP zóna' },
    real_cityhall     = { theme='holo',  icon='star',      color = { r=120, g=255, b=160, a=170 }, title = 'Városháza',         helpText = '~INPUT_CONTEXT~ Városháza' }
}

-- ===== DEMO MARKEREK =====
Config.DemoMarkers = {
    { style='real_registry',   coords=vec3(215.86, -810.12, 30.73), helpText='~INPUT_CONTEXT~ Okmányiroda',     event='real_markers:demo:real_registry' },
    { style='real_inspection', coords=vec3(221.12, -804.80, 30.68), helpText='~INPUT_CONTEXT~ Műszaki vizsga',  event='real_markers:demo:real_inspection' },
    { style='real_dealership', coords=vec3(227.10, -799.10, 30.60), helpText='~INPUT_CONTEXT~ Autókereskedés',  event='real_markers:demo:real_dealership' },
    { style='real_faction_hq', coords=vec3(233.00, -793.30, 30.54), helpText='~INPUT_CONTEXT~ Frakció központ', event='real_markers:demo:real_faction_hq' },
    { style='real_company',    coords=vec3(239.10, -787.60, 30.50), helpText='~INPUT_CONTEXT~ Cég dashboard',   event='real_markers:demo:real_company_dashboard' },
    { style='real_illegal',    coords=vec3(245.20, -781.70, 30.50), helpText='~INPUT_CONTEXT~ Illegál piac',    event='real_markers:demo:real_illegal_market' },
    { style='real_mining',     coords=vec3(251.00, -776.00, 30.50), helpText='~INPUT_CONTEXT~ Bánya pont',      event='real_markers:demo:real_mining' },
    { style='real_fishing',    coords=vec3(256.80, -770.50, 30.50), helpText='~INPUT_CONTEXT~ Horgászhely',     event='real_markers:demo:real_fishing' },
    { style='real_vip',        coords=vec3(262.40, -765.10, 30.50), helpText='~INPUT_CONTEXT~ VIP zóna',        event='real_markers:demo:real_vip' },
    { style='real_cityhall',   coords=vec3(268.30, -759.60, 30.50), helpText='~INPUT_CONTEXT~ Városháza',       event='real_markers:demo:real_cityhall' }
}
