// ================================================================
//  RoadSOS Emergency Portal — Main Application
//  Stack: Leaflet.js + OpenStreetMap + Overpass API + OSRM + Firebase
// ================================================================

import firebaseConfig from './firebase-config.js';

// ── Firebase Init ────────────────────────────────────────────────
firebase.initializeApp(firebaseConfig);
const db = firebase.database();

// ── State ────────────────────────────────────────────────────────
let userLocation   = null;
let map            = null;
let userMarker     = null;
let routingControl = null;
let activeCategory = 'all';
let searchQuery    = '';
let allServices    = [];
let serviceMarkers = {};      // id → Leaflet marker
let responderMarkers = {};    // uid → Leaflet marker
let selectedServiceId = null;
let responderTrackingInterval = null;
let isResponder    = false;
let responderUid   = null;

// ── Category → Overpass query map ───────────────────────────────
const CATEGORY_CONFIG = {
  hospital:  { icon: '🏥', color: '#58A6FF', label: 'Hospital',    queries: ['amenity=hospital','amenity=clinic'] },
  ambulance: { icon: '🚑', color: '#E53935', label: 'Ambulance',   queries: ['emergency=ambulance_station','amenity=ambulance_station'] },
  pharmacy:  { icon: '💊', color: '#BC8CFF', label: 'Pharmacy',    queries: ['amenity=pharmacy'] },
  towing:    { icon: '🚛', color: '#F0883E', label: 'Towing',      queries: ['shop=car_repair','service=towing'] },
  puncture:  { icon: '🔧', color: '#E3B341', label: 'Puncture',    queries: ['shop=tyres','shop=bicycle'] },
  trauma:    { icon: '🩺', color: '#39D2C0', label: 'Trauma Care', queries: ['amenity=hospital','healthcare=trauma_center'] },
  police:    { icon: '🚔', color: '#8B949E', label: 'Police',      queries: ['amenity=police'] },
  fire:      { icon: '🚒', color: '#FF6F60', label: 'Fire Station', queries: ['amenity=fire_station'] },
};

// ── Utilities ────────────────────────────────────────────────────
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2)**2 + Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLon/2)**2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
}

function etaMinutes(distKm, speedKmh = 40) {
  const mins = Math.round((distKm / speedKmh) * 60);
  if (mins < 1) return '< 1 min';
  if (mins < 60) return `${mins} min`;
  return `${Math.floor(mins/60)}h ${mins%60}m`;
}

function toast(msg, type = 'info', duration = 3500) {
  const c = document.getElementById('toast-container');
  const t = document.createElement('div');
  t.className = `toast ${type}`;
  t.textContent = msg;
  c.appendChild(t);
  setTimeout(() => {
    t.classList.add('fade-out');
    setTimeout(() => t.remove(), 320);
  }, duration);
}

function generateId() {
  return Math.random().toString(36).substr(2, 9);
}

function makePinIcon(emoji, bg, size = 36) {
  return L.divIcon({
    className: '',
    html: `<div style="width:${size}px;height:${size}px;border-radius:50% 50% 50% 0;background:${bg};transform:rotate(-45deg);display:flex;align-items:center;justify-content:center;box-shadow:0 3px 12px rgba(0,0,0,0.5)"><span style="transform:rotate(45deg);font-size:${size*0.42}px;line-height:1">${emoji}</span></div>`,
    iconSize: [size, size],
    iconAnchor: [size/2, size],
    popupAnchor: [0, -size],
  });
}

// ── Loading screen helpers ───────────────────────────────────────
function setLoaderStatus(msg) {
  document.getElementById('loader-status').textContent = msg;
}
function hideLoader() {
  const ls = document.getElementById('loading-screen');
  ls.classList.add('fade-out');
  setTimeout(() => ls.remove(), 600);
}

// ── Map Init ─────────────────────────────────────────────────────
function initMap(lat, lng) {
  map = L.map('map', { zoomControl: false, attributionControl: true }).setView([lat, lng], 14);

  // OpenStreetMap tile layer (free, no API key)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors | RoadSOS',
    maxZoom: 19,
  }).addTo(map);

  // Zoom control bottom-right
  L.control.zoom({ position: 'bottomright' }).addTo(map);

  // User marker
  userMarker = L.marker([lat, lng], {
    icon: makePinIcon('📍', '#58A6FF', 42),
    zIndexOffset: 1000,
  }).addTo(map).bindPopup('<b>📍 You are here</b>');
}

// ── Geolocation ──────────────────────────────────────────────────
function startLocationTracking() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocation not supported'));
      return;
    }
    navigator.geolocation.getCurrentPosition(
      pos => resolve(pos),
      err => reject(err),
      { enableHighAccuracy: true, timeout: 12000, maximumAge: 0 }
    );
  });
}

function watchUserLocation() {
  navigator.geolocation.watchPosition(
    pos => {
      const { latitude: lat, longitude: lng, accuracy } = pos.coords;
      userLocation = { lat, lng };
      if (userMarker) userMarker.setLatLng([lat, lng]);
      document.getElementById('location-accuracy').textContent = `±${Math.round(accuracy)}m`;
      // If responder mode active, push to Firebase
      if (isResponder && responderUid) pushResponderLocation(lat, lng);
    },
    () => {},
    { enableHighAccuracy: true, maximumAge: 5000, timeout: 10000 }
  );
}

// ── Overpass API — fetch nearby services ────────────────────────
async function fetchNearbyServices(lat, lng, radiusM = 10000) {
  const cats = activeCategory === 'all'
    ? Object.values(CATEGORY_CONFIG)
    : [CATEGORY_CONFIG[activeCategory]];

  const unionParts = cats.flatMap(c =>
    c.queries.map(q => {
      const [k, v] = q.split('=');
      return `node["${k}"="${v}"](around:${radiusM},${lat},${lng});way["${k}"="${v}"](around:${radiusM},${lat},${lng});`;
    })
  ).join('\n');

  const query = `[out:json][timeout:30];(\n${unionParts}\n);out center;`;
  const url = `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`;

  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`Overpass HTTP ${res.status}`);
    const data = await res.json();
    return parseOverpassResults(data.elements, lat, lng);
  } catch (err) {
    console.error('Overpass error:', err);
    toast('Could not fetch some services. Using cached data.', 'warning');
    return [];
  }
}

function parseOverpassResults(elements, userLat, userLng) {
  const results = [];
  const seen = new Set();

  for (const el of elements) {
    const elLat = el.lat ?? el.center?.lat;
    const elLng = el.lon ?? el.center?.lon;
    if (!elLat || !elLng) continue;

    const tags = el.tags || {};
    const name = tags.name || tags['name:en'] || 'Unknown Service';
    const key = `${name}_${Math.round(elLat*1000)}_${Math.round(elLng*1000)}`;
    if (seen.has(key)) continue;
    seen.add(key);

    const cat = detectCategory(tags);
    if (!cat) continue;

    const distKm = haversineKm(userLat, userLng, elLat, elLng);
    results.push({
      id:       el.id.toString(),
      name,
      cat,
      lat:      elLat,
      lng:      elLng,
      distKm,
      phone:    tags.phone || tags['contact:phone'] || null,
      opening:  tags.opening_hours || null,
    });
  }

  return results.sort((a, b) => a.distKm - b.distKm);
}

function detectCategory(tags) {
  const a = tags.amenity || '';
  const s = tags.shop || '';
  const e = tags.emergency || '';
  const h = tags.healthcare || '';
  if (a === 'hospital' || a === 'clinic' || h === 'hospital') return 'hospital';
  if (a === 'ambulance_station' || e === 'ambulance_station') return 'ambulance';
  if (a === 'pharmacy') return 'pharmacy';
  if (a === 'police') return 'police';
  if (a === 'fire_station') return 'fire';
  if (s === 'tyres' || s === 'bicycle') return 'puncture';
  if (s === 'car_repair') return 'towing';
  if (h === 'trauma_center') return 'trauma';
  return null;
}

// ── Render services to sidebar + map ────────────────────────────
function renderServices(services) {
  allServices = services;
  applyFilters();
}

function applyFilters() {
  let filtered = allServices;

  if (activeCategory !== 'all')
    filtered = filtered.filter(s => s.cat === activeCategory);

  if (searchQuery)
    filtered = filtered.filter(s =>
      s.name.toLowerCase().includes(searchQuery) ||
      (CATEGORY_CONFIG[s.cat]?.label || '').toLowerCase().includes(searchQuery)
    );

  renderServiceList(filtered);
  renderServiceMarkers(filtered);
  document.getElementById('services-count').textContent = filtered.length;
}

function renderServiceList(services) {
  const list = document.getElementById('services-list');
  if (!services.length) {
    list.innerHTML = '<div class="empty-state"><span class="empty-icon">🔍</span><p>No services found in this area</p></div>';
    return;
  }
  list.innerHTML = services.slice(0, 40).map(s => {
    const cfg = CATEGORY_CONFIG[s.cat] || { icon: '📍', label: s.cat };
    return `
      <div class="service-card${selectedServiceId === s.id ? ' active' : ''}"
           id="svc-card-${s.id}"
           onclick="window._selectService('${s.id}')">
        <span class="svc-icon">${cfg.icon}</span>
        <div class="svc-info">
          <div class="svc-name">${s.name}</div>
          <div class="svc-type">${cfg.label}</div>
        </div>
        <div class="svc-meta">
          <div class="svc-dist">${s.distKm < 1 ? (s.distKm*1000).toFixed(0)+'m' : s.distKm.toFixed(1)+'km'}</div>
          <div class="svc-eta">${etaMinutes(s.distKm)}</div>
        </div>
      </div>`;
  }).join('');
}

function renderServiceMarkers(services) {
  // Remove old markers
  Object.values(serviceMarkers).forEach(m => map.removeLayer(m));
  serviceMarkers = {};

  services.forEach(s => {
    const cfg = CATEGORY_CONFIG[s.cat] || { icon: '📍', color: '#8B949E' };
    const marker = L.marker([s.lat, s.lng], {
      icon: makePinIcon(cfg.icon, cfg.color, 32),
    }).addTo(map);

    marker.bindPopup(`
      <div style="min-width:180px">
        <div class="popup-title">${cfg.icon} ${s.name}</div>
        <div class="popup-type">${cfg.label}</div>
        <div class="popup-meta">
          📏 ${s.distKm < 1 ? (s.distKm*1000).toFixed(0)+'m' : s.distKm.toFixed(1)+'km'} away
          &nbsp;|&nbsp; ⏱ ${etaMinutes(s.distKm)}
          ${s.phone ? `<br>📞 ${s.phone}` : ''}
          ${s.opening ? `<br>🕐 ${s.opening}` : ''}
        </div>
        <button class="popup-btn" onclick="window._selectService('${s.id}')">Get Directions</button>
      </div>
    `);

    marker.on('click', () => window._selectService(s.id));
    serviceMarkers[s.id] = marker;
  });
}

// ── Select service & show ETA card ──────────────────────────────
window._selectService = function(id) {
  const svc = allServices.find(s => s.id === id);
  if (!svc || !userLocation) return;

  selectedServiceId = id;
  const cfg = CATEGORY_CONFIG[svc.cat] || { icon: '📍', label: svc.cat };

  // Update ETA card
  document.getElementById('eta-icon').textContent = cfg.icon;
  document.getElementById('eta-name').textContent = svc.name;
  document.getElementById('eta-type').textContent = cfg.label;
  document.getElementById('eta-distance').textContent =
    svc.distKm < 1 ? `${(svc.distKm*1000).toFixed(0)}m` : `${svc.distKm.toFixed(1)}km`;
  document.getElementById('eta-time').textContent = etaMinutes(svc.distKm);
  document.getElementById('eta-card').classList.remove('hidden');

  // Highlight card in list
  document.querySelectorAll('.service-card').forEach(el => el.classList.remove('active'));
  const card = document.getElementById(`svc-card-${id}`);
  if (card) card.classList.add('active');

  // Fly to marker
  map.flyTo([svc.lat, svc.lng], 15, { duration: 1 });
  if (serviceMarkers[id]) serviceMarkers[id].openPopup();

  // Wire up directions button
  document.getElementById('btn-navigate').onclick = () => getRoute(svc);
};

// ── OSRM Routing via Leaflet Routing Machine ─────────────────────
function getRoute(svc) {
  if (routingControl) { map.removeControl(routingControl); routingControl = null; }

  routingControl = L.Routing.control({
    waypoints: [
      L.latLng(userLocation.lat, userLocation.lng),
      L.latLng(svc.lat, svc.lng),
    ],
    router: L.Routing.osrmv1({
      serviceUrl: 'https://router.project-osrm.org/route/v1',
      profile: 'driving',
    }),
    lineOptions: { styles: [{ color: '#E53935', weight: 4, opacity: 0.85 }] },
    show: false,            // hide the turn-by-turn panel
    addWaypoints: false,
    draggableWaypoints: false,
    fitSelectedRoutes: true,
    createMarker: () => null,
  }).addTo(map);

  routingControl.on('routesfound', e => {
    const route = e.routes[0].summary;
    const distKm = (route.totalDistance / 1000).toFixed(1);
    const mins = Math.round(route.totalTime / 60);
    document.getElementById('eta-distance').textContent = `${distKm} km`;
    document.getElementById('eta-time').textContent = mins < 60 ? `${mins} min` : `${Math.floor(mins/60)}h ${mins%60}m`;
    toast(`Route found: ${distKm} km, ~${mins} min`, 'success');
  });

  routingControl.on('routingerror', () => toast('Routing failed. Check your connection.', 'error'));
  map.flyTo([svc.lat, svc.lng], 13, { duration: 1.2 });
}

// ── Firebase — Live Responders ───────────────────────────────────
function listenToLiveResponders() {
  db.ref('responders').on('value', snapshot => {
    const data = snapshot.val() || {};

    // Remove stale markers
    Object.keys(responderMarkers).forEach(uid => {
      if (!data[uid]) {
        map.removeLayer(responderMarkers[uid]);
        delete responderMarkers[uid];
      }
    });

    const list = document.getElementById('responders-list');
    const entries = Object.entries(data).filter(([, v]) => v.active);

    document.getElementById('responders-count').textContent = entries.length;

    if (!entries.length) {
      list.innerHTML = '<div class="empty-state"><span class="empty-icon">📡</span><p>No live responders yet</p></div>';
      return;
    }

    list.innerHTML = entries.map(([uid, v]) => {
      const cfg = CATEGORY_CONFIG[v.type] || { icon: '🚑', label: v.type };
      const distKm = userLocation ? haversineKm(userLocation.lat, userLocation.lng, v.lat, v.lng) : null;
      return `
        <div class="responder-card" onclick="window._flyToResponder(${v.lat},${v.lng})">
          <div class="resp-live-dot"></div>
          <div class="svc-info">
            <div class="svc-name">${cfg.icon} ${v.name || 'Unnamed'}</div>
            <div class="svc-type">${cfg.label} · Live</div>
          </div>
          ${distKm !== null ? `<div class="svc-meta"><div class="svc-dist">${distKm < 1 ? (distKm*1000).toFixed(0)+'m' : distKm.toFixed(1)+'km'}</div></div>` : ''}
        </div>`;
    }).join('');

    // Update markers
    entries.forEach(([uid, v]) => {
      const cfg = CATEGORY_CONFIG[v.type] || { icon: '🚑', color: '#3FB950' };
      const latlng = L.latLng(v.lat, v.lng);
      if (responderMarkers[uid]) {
        responderMarkers[uid].setLatLng(latlng);
      } else {
        const m = L.marker(latlng, {
          icon: makePinIcon(cfg.icon, '#3FB950', 38),
          zIndexOffset: 500,
        }).addTo(map);
        m.bindPopup(`<div class="popup-title">🟢 ${cfg.icon} ${v.name || 'Responder'}</div><div class="popup-type">LIVE · ${cfg.label}</div>`);
        responderMarkers[uid] = m;
      }
    });
  });
}

window._flyToResponder = function(lat, lng) {
  map.flyTo([lat, lng], 15, { duration: 1 });
};

// ── Responder mode ───────────────────────────────────────────────
function pushResponderLocation(lat, lng) {
  if (!responderUid) return;
  db.ref(`responders/${responderUid}`).update({ lat, lng, ts: Date.now() });
}

function startResponderBroadcast() {
  const name = document.getElementById('resp-name').value.trim() || 'Anonymous';
  const type = document.getElementById('resp-type').value;
  responderUid = `resp_${generateId()}`;
  isResponder = true;

  db.ref(`responders/${responderUid}`).set({
    name, type, active: true, ts: Date.now(),
    lat: userLocation?.lat || 0,
    lng: userLocation?.lng || 0,
  });

  // Remove on disconnect
  db.ref(`responders/${responderUid}/active`).onDisconnect().set(false);

  document.getElementById('btn-start-tracking').classList.add('hidden');
  document.getElementById('btn-stop-tracking').classList.remove('hidden');
  toast(`📡 Broadcasting as ${name} (${type})`, 'success');
}

function stopResponderBroadcast() {
  if (!responderUid) return;
  db.ref(`responders/${responderUid}/active`).set(false);
  isResponder = false;
  document.getElementById('btn-start-tracking').classList.remove('hidden');
  document.getElementById('btn-stop-tracking').classList.add('hidden');
  toast('Stopped broadcasting.', 'info');
}

// ── SOS Modal ────────────────────────────────────────────────────
function openSosModal() {
  document.getElementById('sos-modal').classList.remove('hidden');
  const locText = userLocation
    ? `Your GPS: ${userLocation.lat.toFixed(5)}, ${userLocation.lng.toFixed(5)}`
    : 'Location not detected yet';
  document.getElementById('sos-location-text').textContent = locText;
}

document.getElementById('btn-sos').addEventListener('click', openSosModal);
document.getElementById('sos-close').addEventListener('click', () => {
  document.getElementById('sos-modal').classList.add('hidden');
});
document.getElementById('sos-share-location').addEventListener('click', () => {
  if (!userLocation) { toast('Location not ready yet.', 'warning'); return; }
  const text = `🚨 EMERGENCY! I need help. My location: https://maps.google.com/?q=${userLocation.lat},${userLocation.lng}`;
  if (navigator.share) {
    navigator.share({ title: 'RoadSOS Emergency', text });
  } else {
    navigator.clipboard.writeText(text);
    toast('Location link copied to clipboard!', 'success');
  }
});

// ── Category chip filters ────────────────────────────────────────
document.getElementById('category-chips').addEventListener('click', e => {
  const chip = e.target.closest('.chip');
  if (!chip) return;
  document.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
  chip.classList.add('active');
  activeCategory = chip.dataset.cat;
  applyFilters();
});

// ── Search ───────────────────────────────────────────────────────
const searchInput = document.getElementById('search-input');
const searchClear = document.getElementById('search-clear');
searchInput.addEventListener('input', e => {
  searchQuery = e.target.value.toLowerCase().trim();
  searchClear.classList.toggle('visible', searchQuery.length > 0);
  applyFilters();
});
searchClear.addEventListener('click', () => {
  searchInput.value = '';
  searchQuery = '';
  searchClear.classList.remove('visible');
  applyFilters();
});

// ── Panel toggle ─────────────────────────────────────────────────
document.getElementById('btn-menu-toggle').addEventListener('click', () => {
  document.getElementById('side-panel').classList.toggle('panel-open');
});

// ── My Location button ───────────────────────────────────────────
document.getElementById('btn-my-location').addEventListener('click', () => {
  if (userLocation) {
    map.flyTo([userLocation.lat, userLocation.lng], 15, { duration: 1 });
    userMarker?.openPopup();
  }
});

// ── ETA card close ───────────────────────────────────────────────
document.getElementById('eta-close').addEventListener('click', () => {
  document.getElementById('eta-card').classList.add('hidden');
  selectedServiceId = null;
  if (routingControl) { map.removeControl(routingControl); routingControl = null; }
  document.querySelectorAll('.service-card').forEach(c => c.classList.remove('active'));
});

// ── Responder toggle ─────────────────────────────────────────────
document.getElementById('responder-toggle').addEventListener('change', e => {
  document.getElementById('responder-form').classList.toggle('hidden', !e.target.checked);
});
document.getElementById('btn-start-tracking').addEventListener('click', startResponderBroadcast);
document.getElementById('btn-stop-tracking').addEventListener('click', stopResponderBroadcast);

// ── Close SOS on overlay click ───────────────────────────────────
document.getElementById('sos-modal').addEventListener('click', e => {
  if (e.target === document.getElementById('sos-modal'))
    document.getElementById('sos-modal').classList.add('hidden');
});

// ═══════════════════════════════════════════════════════════════
//  BOOTSTRAP
// ═══════════════════════════════════════════════════════════════
async function bootstrap() {
  setLoaderStatus('Requesting GPS access…');

  let lat, lng;
  try {
    const pos = await startLocationTracking();
    lat = pos.coords.latitude;
    lng = pos.coords.longitude;
    userLocation = { lat, lng };
    setLoaderStatus('Location found! Loading map…');
    document.getElementById('location-text').textContent =
      `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
    document.getElementById('location-accuracy').textContent =
      `±${Math.round(pos.coords.accuracy)}m`;
  } catch (err) {
    // Fallback to a central Indian location for demo
    lat = 20.5937; lng = 78.9629;
    userLocation = { lat, lng };
    setLoaderStatus('Using approximate location…');
    toast('GPS denied — showing demo location (India center).', 'warning', 5000);
    document.getElementById('location-text').textContent = 'Approximate location';
    document.getElementById('loc-dot').style.background = '#F0883E';
  }

  setLoaderStatus('Initializing map…');
  initMap(lat, lng);

  setLoaderStatus('Fetching nearby services…');
  const services = await fetchNearbyServices(lat, lng, 10000);
  renderServices(services);

  setLoaderStatus('Connecting to live feed…');
  listenToLiveResponders();

  // Start continuous GPS watch
  watchUserLocation();

  // Done!
  hideLoader();

  if (services.length) {
    toast(`Found ${services.length} services near you`, 'success');
  } else {
    toast('No services in 10 km. Try zooming out.', 'warning');
  }

  // Auto-refresh services every 3 minutes
  setInterval(async () => {
    if (!userLocation) return;
    const fresh = await fetchNearbyServices(userLocation.lat, userLocation.lng, 10000);
    renderServices(fresh);
  }, 180_000);
}

bootstrap();
