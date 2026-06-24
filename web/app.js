
const markerRoot = document.getElementById('markers');
const editor = document.getElementById('editor');
const toast = document.getElementById('toast');

const iconMap = {
  wrench:'icons/real_holo_wrench.png',
  document:'icons/real_holo_document.png',
  car:'icons/real_holo_car.png',
  basket:'icons/real_holo_basket.png',
  bank:'icons/real_holo_bank.png',
  shield:'icons/real_holo_shield.png',
  shield_star:'icons/real_holo_shield.png',
  hospital:'icons/real_holo_hospital.png',
  warning:'icons/real_warning.svg',
  house:'icons/real_house.svg',
  fuel:'icons/real_holo_fuel.png',
  clothing:'icons/real_holo_clothing.png',
  crown:'icons/real_holo_star.png',
  diamond:'icons/real_holo_star.png',
  mask:'icons/real_mask.svg',
  briefcase:'icons/real_holo_document.png',
  users:'icons/real_holo_shield.png',
  star:'icons/real_holo_star.png',
  truck:'icons/real_holo_car.png',
  atm:'icons/real_holo_bank.png',
  gear:'icons/real_holo_wrench.png',
  key:'icons/real_key.svg',
  handshake:'icons/real_handshake.svg',
  chart:'icons/real_holo_document.png',
  taxi:'icons/real_holo_car.png',
  box:'icons/real_holo_document.png',
  fishing:'icons/real_star.svg',
  pickaxe:'icons/real_wrench.svg',
  droplet:'icons/real_fuel.svg'
};

const themeOptions = [
  ['holo', 'Neon zöld'],
  ['sky', 'Világoskék'],
  ['blue', 'Kék'],
  ['cyan', 'Cián'],
  ['teal', 'Türkiz'],
  ['mint', 'Menta'],
  ['lime', 'Lime'],
  ['amber', 'Arany'],
  ['red', 'Piros'],
  ['pink', 'Pink'],
  ['purple', 'Lila'],
  ['white', 'Fehér']
];

const modeOptions = [
  ['icon', 'Csak ikon'],
  ['icon_label', 'Ikon + cím mindig'],
  ['icon_interact', 'Cím csak közelről'],
  ['dot_icon', 'Ikon + finom pont']
];

let markerNodes = new Map();
let editorStyles = {};
let editorMarkers = [];
let selectedId = null;

function esc(v){
  return String(v ?? '')
    .replaceAll('&','&amp;')
    .replaceAll('<','&lt;')
    .replaceAll('>','&gt;')
    .replaceAll('"','&quot;')
    .replaceAll("'",'&#039;');
}

function post(name,data={}){
  return fetch(`https://${GetParentResourceName()}/${name}`,{
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body:JSON.stringify(data)
  }).then(r=>r.json()).catch(()=>({ok:false}));
}

function notify(msg,type='info'){
  toast.innerHTML = `<div class="toast ${type}">${esc(msg)}</div>`;
  clearTimeout(window.__toastTimer);
  window.__toastTimer = setTimeout(()=>toast.innerHTML='',2800);
}

function createMarkerNode(id){
  const node = document.createElement('div');
  node.className = 'subtle-marker';
  node.dataset.id = id;
  node.innerHTML = `<div class="subtle-inner"><div class="subtle-glyph"><img></div><div class="subtle-label"><b></b><span></span></div><div class="subtle-key"></div></div>`;
  markerRoot.appendChild(node);
  const rec = {node,last:{},seen:performance.now()};
  markerNodes.set(id, rec);
  return rec;
}

function clearMarkers(){
  for(const [,rec] of markerNodes.entries()) rec.node.remove();
  markerNodes.clear();
}

function updateMarkers(markers){
  if(!Array.isArray(markers)) markers = [];

  const now = performance.now();
  const alive = new Set();

  for(const m of markers){
    if(!m || !m.id) continue;
    alive.add(m.id);

    const rec = markerNodes.get(m.id) || createMarkerNode(m.id);
    rec.seen = now;

    const {node,last} = rec;
    const theme = m.theme || 'sky';
    const cls = `subtle-marker theme-${theme} mode-${m.mode || 'icon_interact'} ${m.near ? 'near' : ''} ${m.showLabel ? 'show-label' : ''} ${m.showInteract ? 'show-interact' : ''}`;
    if(last.cls !== cls){ node.className = cls; last.cls = cls; }

    const x = Math.max(-8, Math.min(108, (m.x || 0) * 100));
    const y = Math.max(-8, Math.min(108, (m.y || 0) * 100));
    const left = `${x}vw`;
    const top = `${y}vh`;
    const opacity = String(m.alpha ?? 1);
    const transform = `translate3d(-50%,-100%,0) scale(${m.scale || 1})`;

    if(last.left !== left){ node.style.left = left; last.left = left; }
    if(last.top !== top){ node.style.top = top; last.top = top; }
    if(last.opacity !== opacity){ node.style.opacity = opacity; last.opacity = opacity; }
    if(last.transform !== transform){ node.style.transform = transform; last.transform = transform; }

    const icon = iconMap[m.icon] || iconMap.document;
    if(last.icon !== icon){ node.querySelector('img').src = icon; last.icon = icon; }
    if(last.title !== m.title){ node.querySelector('b').textContent = m.title || ''; last.title = m.title; }
    if(last.subtitle !== m.subtitle){ node.querySelector('span').textContent = m.subtitle || ''; last.subtitle = m.subtitle; }
    if(last.key !== m.keyText){ node.querySelector('.subtle-key').textContent = m.keyText || 'E'; last.key = m.keyText; }
  }

  for(const [id,rec] of markerNodes.entries()){
    if(!alive.has(id)){
      rec.node.remove();
      markerNodes.delete(id);
    }
  }
}

// Beragadas elleni watchdog: ha a kliens oldali Lua bármilyen okból nem küld üres listát,
// a NUI akkor is eltakarítja az elavult ikonokat.
setInterval(() => {
  const now = performance.now();
  for(const [id,rec] of markerNodes.entries()){
    if(now - rec.seen > 650){
      rec.node.remove();
      markerNodes.delete(id);
    }
  }
}, 250);

function parsePerms(job, item){
  const permissions = {};
  if(job){
    const [n,g] = job.split(':');
    if(n) permissions.jobs = {[n.trim()]: Number(g || 0)};
  }
  if(item){
    const [n,c] = item.split(':');
    if(n) permissions.items = {[n.trim()]: Number(c || 1)};
  }
  return Object.keys(permissions).length ? permissions : null;
}
function permToJob(p){ if(!p || !p.jobs) return ''; const k = Object.keys(p.jobs)[0]; return k ? `${k}:${p.jobs[k]}` : ''; }
function permToItem(p){ if(!p || !p.items) return ''; const k = Object.keys(p.items)[0]; return k ? `${k}:${p.items[k]}` : ''; }

function optionList(items, selected){
  return items.map(([v,t]) => `<option value="${esc(v)}" ${v === selected ? 'selected' : ''}>${esc(t)}</option>`).join('');
}
function iconOptions(selected){
  return Object.keys(iconMap).map(i => `<option value="${esc(i)}" ${i === selected ? 'selected' : ''}>${esc(i)}</option>`).join('');
}

function styleDefault(style, key, fallback){
  return editorStyles?.[style]?.[key] ?? fallback;
}

function renderEditor(){
  const styleOptions = Object.keys(editorStyles || {}).map(s => `<option value="${esc(s)}">${esc(s)}</option>`).join('');
  const rows = editorMarkers.map(m => `<button class="row ${m.id === selectedId ? 'active' : ''}" data-id="${esc(m.id)}"><b>${esc(m.id)}</b><span>${esc(m.title || m.style || 'marker')}</span></button>`).join('');

  if(selectedId && !editorMarkers.find(m => m.id === selectedId)) selectedId = null;
  const current = editorMarkers.find(m => m.id === selectedId) || {
    id:'', style:'real_service', coords:{x:0,y:0,z:0}, title:'', subtitle:'', helpText:'', event:'', target:false, serverEvent:false, permissions:null
  };

  const curStyle = current.style || 'real_service';
  const curTheme = current.theme || styleDefault(curStyle, 'theme', 'sky');
  const curIcon = current.icon || styleDefault(curStyle, 'icon', 'wrench');
  const curMode = current.mode || styleDefault(curStyle, 'mode', 'icon_interact');

  editor.innerHTML = `
    <div class="editor-shell">
      <div class="editor-head"><div><b>RealRPG Subtle Marker Editor</b><span>RP-barát ikon marker készítő / MySQL mentéssel / színválasztással</span></div><button id="close">×</button></div>
      <div class="editor-body">
        <aside><input id="search" placeholder="Keresés..."><div class="rows">${rows}</div><button id="new">+ Új marker</button></aside>
        <main>
          <div class="grid">
            <label>ID<input id="id" value="${esc(current.id)}"></label>
            <label>Style<select id="style">${styleOptions}</select></label>
            <label>Szín<select id="theme">${optionList(themeOptions, curTheme)}</select></label>
            <label>Ikon<select id="icon">${iconOptions(curIcon)}</select></label>
            <label>Mód<select id="mode">${optionList(modeOptions, curMode)}</select></label>
            <label>Cím<input id="title" value="${esc(current.title || '')}"></label>
            <label>Alcím<input id="subtitle" value="${esc(current.subtitle || '')}"></label>
            <label>HelpText<input id="helpText" value="${esc(current.helpText || '')}"></label>
            <label>Event<input id="eventName" value="${esc(current.event || '')}"></label>
            <label>X<input id="x" value="${esc(current.coords?.x ?? 0)}"></label>
            <label>Y<input id="y" value="${esc(current.coords?.y ?? 0)}"></label>
            <label>Z<input id="z" value="${esc(current.coords?.z ?? 0)}"></label>
            <label>Draw distance<input id="drawDistance" value="${esc(current.drawDistance ?? '')}"></label>
            <label>Interact distance<input id="interactDistance" value="${esc(current.interactDistance ?? '')}"></label>
            <label>Job perm pl. police:0<input id="jobPerm" value="${esc(permToJob(current.permissions))}"></label>
            <label>Item perm pl. realrpg_clubtagsag:1<input id="itemPerm" value="${esc(permToItem(current.permissions))}"></label>
          </div>
          <div class="checks"><label><input id="target" type="checkbox" ${current.target ? 'checked' : ''}> ox_target</label><label><input id="serverEvent" type="checkbox" ${current.serverEvent ? 'checked' : ''}> server event</label></div>
          <div class="preview"><div id="fakeMarker" class="fake-marker theme-${esc(curTheme)}"><div class="fake-glyph"><img id="pIcon" src="${esc(iconMap[curIcon] || iconMap.wrench)}"></div><div><b id="pTitle">${esc(current.title || 'Marker')}</b><span id="pSub">${esc(current.subtitle || 'Subtle RP')}</span></div><kbd>E</kbd></div></div>
          <div class="actions"><button id="coords">Jelenlegi pozíció</button><button id="preview">Preview</button><button id="save">Mentés MySQL</button><button id="delete">Törlés</button></div>
        </main>
      </div>
    </div>`;

  const st = document.getElementById('style'); if(st) st.value = curStyle;
  bindEditor();
  updatePreview();
}

function collect(){
  const dd = document.getElementById('drawDistance').value.trim();
  const int = document.getElementById('interactDistance').value.trim();
  const id = document.getElementById('id').value.trim();
  return {
    id,
    style:document.getElementById('style').value,
    theme:document.getElementById('theme').value,
    icon:document.getElementById('icon').value,
    mode:document.getElementById('mode').value,
    coords:{x:Number(document.getElementById('x').value), y:Number(document.getElementById('y').value), z:Number(document.getElementById('z').value)},
    title:document.getElementById('title').value,
    subtitle:document.getElementById('subtitle').value,
    helpText:document.getElementById('helpText').value,
    event:document.getElementById('eventName').value,
    target:document.getElementById('target').checked,
    serverEvent:document.getElementById('serverEvent').checked,
    drawDistance:dd === '' ? null : Number(dd),
    interactDistance:int === '' ? null : Number(int),
    permissions:parsePerms(document.getElementById('jobPerm').value.trim(), document.getElementById('itemPerm').value.trim()),
    enabled:true
  };
}

function updatePreview(){
  const style = document.getElementById('style')?.value || 'real_service';
  const icon = document.getElementById('icon')?.value || styleDefault(style, 'icon', 'wrench');
  const theme = document.getElementById('theme')?.value || styleDefault(style, 'theme', 'sky');
  const img = document.getElementById('pIcon');
  const fake = document.getElementById('fakeMarker');
  if(img) img.src = iconMap[icon] || iconMap.wrench;
  if(fake){
    fake.className = `fake-marker theme-${theme}`;
  }
  const t = document.getElementById('pTitle');
  const s = document.getElementById('pSub');
  if(t) t.innerText = document.getElementById('title')?.value || 'Marker';
  if(s) s.innerText = document.getElementById('subtitle')?.value || 'Subtle RP';
}

function applyStyleDefaults(){
  const style = document.getElementById('style')?.value || 'real_service';
  const theme = document.getElementById('theme');
  const icon = document.getElementById('icon');
  const mode = document.getElementById('mode');
  if(theme) theme.value = styleDefault(style, 'theme', 'sky');
  if(icon) icon.value = styleDefault(style, 'icon', 'wrench');
  if(mode) mode.value = styleDefault(style, 'mode', 'icon_interact');
  updatePreview();
}

function bindEditor(){
  document.getElementById('close').onclick = () => { editor.classList.add('hidden'); post('closeEditor'); };
  document.getElementById('new').onclick = () => {
    const marker = {id:`marker_${Date.now()}`, style:'real_service', theme:'sky', icon:'wrench', mode:'icon_interact', coords:{x:0,y:0,z:0}, title:'Új marker', subtitle:'Interakció'};
    editorMarkers.unshift(marker); selectedId = marker.id; renderEditor();
  };
  document.querySelectorAll('.row').forEach(b => b.onclick = () => { selectedId = b.dataset.id; renderEditor(); });
  document.getElementById('search').oninput = (e) => {
    const q = e.target.value.toLowerCase();
    document.querySelectorAll('.row').forEach(r => r.style.display = r.innerText.toLowerCase().includes(q) ? 'flex' : 'none');
  };
  ['title','subtitle'].forEach(id => document.getElementById(id).oninput = updatePreview);
  document.getElementById('style').onchange = applyStyleDefaults;
  document.getElementById('theme').onchange = updatePreview;
  document.getElementById('icon').onchange = updatePreview;
  document.getElementById('mode').onchange = updatePreview;
  document.getElementById('coords').onclick = async () => {
    const c = await post('getPlayerCoords');
    if(c.ok !== false){
      document.getElementById('x').value = c.x;
      document.getElementById('y').value = c.y;
      document.getElementById('z').value = c.z;
      notify('Pozíció beolvasva.','success');
    }
  };
  document.getElementById('preview').onclick = () => {
    const m = collect();
    if(!m.id) m.id = 'preview';
    post('previewMarker', m);
  };
  document.getElementById('save').onclick = async () => {
    const m = collect();
    if(!m.id){ notify('Az ID kötelező.','error'); return; }
    await post('saveMarker', m);
    notify('Mentés elküldve a szervernek.','info');
  };
  document.getElementById('delete').onclick = async () => {
    const id = document.getElementById('id').value.trim();
    if(!id){ notify('Nincs ID.','error'); return; }
    await post('deleteMarker', {id});
    notify('Törlés elküldve.','info');
  };
}

window.addEventListener('message', e => {
  const d = e.data || {};
  if(d.action === 'setMarkers') updateMarkers(d.markers || []);
  if(d.action === 'clearMarkers') clearMarkers();
  if(d.action === 'openEditor'){
    editor.classList.remove('hidden');
    editorStyles = d.styles || {};
    renderEditor();
  }
  if(d.action === 'editorData'){
    if(d.ok === false){ notify(d.message || 'Nincs jogosultság vagy szerver hiba.','error'); }
    editorStyles = d.styles || editorStyles;
    editorMarkers = d.markers || [];
    if(!selectedId && editorMarkers[0]) selectedId = editorMarkers[0].id;
    renderEditor();
  }
  if(d.action === 'notify') notify(d.message || '', d.type || 'info');
});

window.addEventListener('keydown', e => {
  if(e.key === 'Escape' && !editor.classList.contains('hidden')){
    editor.classList.add('hidden');
    post('closeEditor');
  }
});
