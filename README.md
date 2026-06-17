# real_markers 5.1.0 – Subtle RP Fixed

Javított subtle / RP-barát marker rendszer.

## Javítva
- kamera forgatás közbeni darabos NUI követés
- `Config.Styles` / `Config.SubtleStyles` hiba
- editor NUI callbackök
- MySQL save/delete után editor lista frissítés
- ACE hiba már látható értesítésként jelenik meg
- NUI DOM már nem épül újra minden kamera mozdulatra, csak transform/opacity frissül

## Fontos telepítés
```cfg
ensure oxmysql
ensure real_markers
add_ace group.admin real_markers.admin allow
```

Ha tesztelni akarod ACE nélkül:
```lua
Config.RequireAceForEditor = false
```

## Smooth / resmon beállítás
Alapból simább kamera követésre van állítva:
```lua
Config.NuiRefreshInterval = 0
Config.MaxVisibleMarkers = 5
Config.EnableGroundDot = false
```

Ha még kevesebb resmon kell, de picit darabosabb lehet:
```lua
Config.NuiRefreshInterval = 50
Config.MaxVisibleMarkers = 4
```

## Editor
```txt
/rmeditor
```

## Példa
```lua
exports['real_markers']:RegisterImageMarker('inspection_1', {
    style = 'subtle_wrench',
    coords = vec3(451.2, -975.4, 25.7),
    title = 'Szerviz',
    subtitle = 'Interakció',
    helpText = '~INPUT_CONTEXT~ Szerviz megnyitása',
    interactDistance = 1.8,
    drawDistance = 12.0,
    event = 'real_mechanic:openInspection'
})
```


## 5.3.0 javítás
Az előző server icon buildben a `config.lua`-ban hiányzott egy vessző a `subtle_faction` után, ezért a resource nem indult el, így nem látszott marker és a `/rmeditor` sem jött elő. Ez a verzió javítva van.

## Új RealRPG ikon style-ok
`real_service`, `real_registry`, `real_garage`, `real_shop`, `real_police`, `real_hospital`, `real_warning`, `real_property`, `real_fuel`, `real_bank`, `real_clothing`, `real_vip`, `real_faction`, `real_illegal`, `real_job`, `real_event`, `real_car_dealer`, `real_inspection`, `real_impound`, `real_company`, `real_atm`, `real_taxi`, `real_trucker`, `real_illegal_drop`


## 5.3.0 javítás – valódi hologram ikon assetek

Az előző csomagban a generált preview kinézete és a scriptben lévő ikonok nem egyeztek, mert a script még egyszerű vonal SVG-ket használt.

Ebben a verzióban már külön `web/icons/real_*.svg` assetek vannak:
- kitöltött, áttetsző világoskék ikon
- beépített glow
- beépített alsó chevron marker jel
- halvány talaj-halo az SVG-ben

Használd például:
```lua
style = 'real_service'
style = 'real_registry'
style = 'real_garage'
style = 'real_shop'
style = 'real_police'
style = 'real_hospital'
style = 'real_vip'
```


## 5.4.0 javítás
- Javítva: kamera forgatás / marker eltűnés után beragadó NUI ikon.
- Kliens oldali plusz culling: kamera mögötti és képernyőről kicsúszó ikon nem kerül NUI-ba.
- NUI watchdog: ha egy marker 650 ms-ig nem kap frissítést, automatikusan törlődik a DOM-ból.
- `/rmeditor` kapott színválasztót, ikonválasztót és módválasztót.
- A kiválasztott `theme`, `icon`, `mode` MySQL-be mentődik.

Színek: `sky`, `blue`, `cyan`, `teal`, `mint`, `lime`, `amber`, `red`, `pink`, `purple`, `white`.
