
Config = {}

Config.AutoCreateTable = true
Config.UseOxTarget = false
Config.OxTargetResource = 'ox_target'
Config.UseOxInventory = true
Config.AdminAce = 'real_markers.admin'
Config.RequireAceForEditor = true -- ha nincs ACE beallitva teszthez tedd false-ra

-- Optimalizált, RP-barát beállítások
Config.DefaultDrawDistance = 13.0
Config.DefaultInteractDistance = 1.8
Config.DefaultKey = 38 -- E
Config.CoarseRefreshInterval = 650       -- marker közelség cache, nem frame alapon fut
Config.NuiRefreshInterval = 0            -- 0 = smooth kamera követés, csak közeli markereknél aktív
Config.MaxVisibleMarkers = 5
Config.HideWhenPauseMenu = true
Config.EnableGroundDot = false           -- legjobb resmonhoz false. Ha kell kis földpont: true
Config.GroundDotMaxDistance = 5.0
Config.GroundDotZOffset = -0.96
Config.PermissionCacheTime = 3000
Config.EnableDemoMarkers = true
Config.EnableEditorNui = true
Config.EditorCommand = 'rmeditor'
Config.EditorPreviewId = '__editor_preview__'
Config.EditorPreviewDuration = 30000
Config.EnableCommands = true
Config.Debug = false

-- Új csomag: a NUI már a web/icons/real_*.svg hologram asseteket használja.
-- mode:
-- icon = csak ikon
-- icon_label = ikon + kis cím mindig
-- icon_interact = ikon, cím csak közelről
-- dot_icon = ikon + opcionális ground dot

-- Editorben választható színek. A NUI ezekhez tartozó theme-* CSS classokat használja.
Config.AvailableColorThemes = {
    'sky', 'blue', 'cyan', 'teal', 'mint', 'lime', 'amber', 'red', 'pink', 'purple', 'white'
}

Config.SubtleStyles = {
    -- Régi subtle style-ok, ha már használtad őket más scriptben
    subtle_wrench = { mode='icon_interact', theme='sky', icon='wrench', title='Szerviz', subtitle='Interakció', color={r=92,g=190,b=230,a=115}, drawDistance=13.0, interactDistance=1.8, scale=0.82, zOffset=1.02, ground=true },
    subtle_document = { mode='icon_interact', theme='sky', icon='document', title='Okmány', subtitle='Ügyintézés', color={r=92,g=190,b=230,a=115}, drawDistance=13.0, interactDistance=1.8, scale=0.82, zOffset=1.02, ground=true },
    subtle_garage = { mode='icon_interact', theme='amber', icon='car', title='Garázs', subtitle='Járművek', color={r=255,g=196,b=72,a=115}, drawDistance=13.0, interactDistance=2.0, scale=0.82, zOffset=1.02, ground=true },
    subtle_shop = { mode='icon_interact', theme='mint', icon='basket', title='Bolt', subtitle='Vásárlás', color={r=105,g=235,b=150,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.80, zOffset=1.0, ground=true },
    subtle_bank = { mode='icon_interact', theme='teal', icon='bank', title='Bank', subtitle='Pénzügyek', color={r=75,g=220,b=210,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.80, zOffset=1.0, ground=true },
    subtle_police = { mode='icon_interact', theme='blue', icon='shield', title='Rendőrség', subtitle='Belépés', color={r=70,g=150,b=255,a=115}, drawDistance=13.0, interactDistance=1.8, scale=0.82, zOffset=1.05, ground=true },
    subtle_hospital = { mode='icon_interact', theme='cyan', icon='hospital', title='Kórház', subtitle='Ellátás', color={r=95,g=225,b=255,a=115}, drawDistance=13.0, interactDistance=1.8, scale=0.82, zOffset=1.05, ground=true },
    subtle_warning = { mode='icon_interact', theme='red', icon='warning', title='Figyelem', subtitle='Korlátozott', color={r=255,g=80,b=70,a=120}, drawDistance=11.0, interactDistance=1.6, scale=0.82, zOffset=1.0, ground=true },
    subtle_house = { mode='icon_interact', theme='white', icon='house', title='Ingatlan', subtitle='Belépés', color={r=230,g=240,b=255,a=110}, drawDistance=12.0, interactDistance=1.8, scale=0.80, zOffset=1.0, ground=true },
    subtle_fuel = { mode='icon_interact', theme='lime', icon='fuel', title='Tankolás', subtitle='Üzemanyag', color={r=180,g=245,b=85,a=115}, drawDistance=12.0, interactDistance=2.0, scale=0.80, zOffset=1.0, ground=true },
    subtle_clothing = { mode='icon_interact', theme='pink', icon='clothing', title='Ruhabolt', subtitle='Öltözés', color={r=255,g=130,b=195,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.80, zOffset=1.0, ground=true },
    subtle_vip = { mode='icon_interact', theme='pink', icon='crown', title='VIP', subtitle='Prémium', color={r=255,g=130,b=195,a=125}, drawDistance=11.0, interactDistance=1.6, scale=0.82, zOffset=1.0, ground=true },
    subtle_illegal = { mode='icon_interact', theme='red', icon='mask', title='Kapcsolat', subtitle='Rejtett', color={r=255,g=80,b=70,a=110}, drawDistance=10.0, interactDistance=1.6, scale=0.80, zOffset=1.0, ground=false },
    subtle_job = { mode='icon_interact', theme='white', icon='briefcase', title='Munka', subtitle='Felvétel', color={r=230,g=240,b=255,a=110}, drawDistance=12.0, interactDistance=1.8, scale=0.80, zOffset=1.0, ground=true },
    subtle_faction = { mode='icon_interact', theme='purple', icon='users', title='Frakció', subtitle='Központ', color={r=170,g=115,b=255,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.80, zOffset=1.0, ground=true },

    -- Új RealRPG ikon pakk: képedhez hasonló, egységes világoskék RP marker kinézet
    real_service = { mode='icon_interact', theme='sky', icon='wrench', title='Szerviz', subtitle='Interakció', color={r=120,g=205,b=255,a=115}, drawDistance=13.0, interactDistance=1.8, scale=0.84, zOffset=1.02, ground=true },
    real_registry = { mode='icon_interact', theme='sky', icon='document', title='Okmányiroda', subtitle='Forgalmi • Ügyintézés', color={r=120,g=205,b=255,a=115}, drawDistance=13.0, interactDistance=1.8, scale=0.84, zOffset=1.02, ground=true },
    real_garage = { mode='icon_interact', theme='sky', icon='car', title='Autószerviz / Garázs', subtitle='Járművek', color={r=120,g=205,b=255,a=115}, drawDistance=13.0, interactDistance=2.0, scale=0.84, zOffset=1.02, ground=true },
    real_shop = { mode='icon_interact', theme='sky', icon='basket', title='Bolt', subtitle='Vásárlás', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.84, zOffset=1.0, ground=true },
    real_police = { mode='icon_interact', theme='sky', icon='shield_star', title='Rendőrség', subtitle='Belépés', color={r=120,g=205,b=255,a=115}, drawDistance=13.0, interactDistance=1.8, scale=0.84, zOffset=1.05, ground=true },
    real_hospital = { mode='icon_interact', theme='sky', icon='hospital', title='Kórház', subtitle='Ellátás', color={r=120,g=205,b=255,a=115}, drawDistance=13.0, interactDistance=1.8, scale=0.84, zOffset=1.05, ground=true },
    real_warning = { mode='icon_interact', theme='sky', icon='warning', title='Figyelmeztetés', subtitle='Óvatosan', color={r=120,g=205,b=255,a=115}, drawDistance=11.0, interactDistance=1.6, scale=0.84, zOffset=1.0, ground=true },
    real_property = { mode='icon_interact', theme='sky', icon='house', title='Ingatlan', subtitle='Belépés', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.84, zOffset=1.0, ground=true },
    real_fuel = { mode='icon_interact', theme='sky', icon='fuel', title='Benzinkút', subtitle='Tankolás', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=2.0, scale=0.84, zOffset=1.0, ground=true },
    real_bank = { mode='icon_interact', theme='sky', icon='bank', title='Bank', subtitle='Pénzügyek', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.84, zOffset=1.0, ground=true },
    real_clothing = { mode='icon_interact', theme='sky', icon='clothing', title='Ruházat', subtitle='Öltözés', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.84, zOffset=1.0, ground=true },
    real_vip = { mode='icon_interact', theme='sky', icon='diamond', title='VIP', subtitle='Prémium', color={r=120,g=205,b=255,a=120}, drawDistance=11.0, interactDistance=1.6, scale=0.84, zOffset=1.0, ground=true },
    real_faction = { mode='icon_interact', theme='sky', icon='users', title='Frakció', subtitle='Központ', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.84, zOffset=1.0, ground=true },
    real_illegal = { mode='icon_interact', theme='sky', icon='mask', title='Illegális', subtitle='Kapcsolat', color={r=120,g=205,b=255,a=110}, drawDistance=10.0, interactDistance=1.6, scale=0.84, zOffset=1.0, ground=false },
    real_job = { mode='icon_interact', theme='sky', icon='briefcase', title='Munka', subtitle='Felvétel', color={r=120,g=205,b=255,a=110}, drawDistance=12.0, interactDistance=1.8, scale=0.84, zOffset=1.0, ground=true },
    real_event = { mode='icon_interact', theme='sky', icon='star', title='Esemény', subtitle='Aktuális', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.84, zOffset=1.0, ground=true },

    -- Extra RealRPG pontok
    real_car_dealer = { mode='icon_interact', theme='sky', icon='car', title='Autókereskedés', subtitle='Jármű vásárlás', color={r=120,g=205,b=255,a=115}, drawDistance=13.0, interactDistance=2.0, scale=0.84, zOffset=1.02, ground=true },
    real_inspection = { mode='icon_interact', theme='sky', icon='wrench', title='Műszaki vizsga', subtitle='Jármű ellenőrzés', color={r=120,g=205,b=255,a=115}, drawDistance=13.0, interactDistance=1.8, scale=0.84, zOffset=1.02, ground=true },
    real_impound = { mode='icon_interact', theme='sky', icon='car', title='Telephely', subtitle='Lefoglalt járművek', color={r=120,g=205,b=255,a=115}, drawDistance=13.0, interactDistance=2.0, scale=0.84, zOffset=1.02, ground=true },
    real_company = { mode='icon_interact', theme='sky', icon='chart', title='Cégközpont', subtitle='Dashboard', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.84, zOffset=1.0, ground=true },
    real_atm = { mode='icon_interact', theme='sky', icon='atm', title='ATM', subtitle='Pénzfelvétel', color={r=120,g=205,b=255,a=115}, drawDistance=10.0, interactDistance=1.5, scale=0.78, zOffset=0.92, ground=true },
    real_taxi = { mode='icon_interact', theme='sky', icon='taxi', title='Taxi', subtitle='Munkafelvétel', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=1.8, scale=0.84, zOffset=1.0, ground=true },
    real_trucker = { mode='icon_interact', theme='sky', icon='truck', title='Fuvarozás', subtitle='Munka indítása', color={r=120,g=205,b=255,a=115}, drawDistance=12.0, interactDistance=2.0, scale=0.84, zOffset=1.0, ground=true },
    real_illegal_drop = { mode='icon_interact', theme='sky', icon='box', title='Leadási pont', subtitle='Rejtett átadás', color={r=120,g=205,b=255,a=105}, drawDistance=9.0, interactDistance=1.5, scale=0.80, zOffset=0.95, ground=false }
}

Config.DemoMarkers = {
    { id='demo_service', style='real_service', coords=vec3(215.86, -810.12, 30.73), helpText='~INPUT_CONTEXT~ Szerviz', event='real_markers:demo:use' },
    { id='demo_registry', style='real_registry', coords=vec3(219.30, -806.70, 30.72), helpText='~INPUT_CONTEXT~ Okmányiroda', event='real_markers:demo:use' },
    { id='demo_garage', style='real_garage', coords=vec3(222.70, -803.20, 30.70), helpText='~INPUT_CONTEXT~ Garázs', event='real_markers:demo:use' },
    { id='demo_shop', style='real_shop', coords=vec3(226.30, -799.90, 30.66), helpText='~INPUT_CONTEXT~ Bolt', event='real_markers:demo:use' },
    { id='demo_police', style='real_police', coords=vec3(229.40, -796.60, 30.66), helpText='~INPUT_CONTEXT~ Rendőrség', event='real_markers:demo:use' },
    { id='demo_hospital', style='real_hospital', coords=vec3(232.80, -793.20, 30.66), helpText='~INPUT_CONTEXT~ Kórház', event='real_markers:demo:use' },
    { id='demo_company', style='real_company', coords=vec3(236.10, -790.00, 30.66), helpText='~INPUT_CONTEXT~ Cégközpont', event='real_markers:demo:use' },
    { id='demo_vip', style='real_vip', coords=vec3(239.40, -786.70, 30.66), helpText='~INPUT_CONTEXT~ VIP', event='real_markers:demo:use' }
}
