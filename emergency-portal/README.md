# RoadSOS — Emergency Assistance Map Portal

> **Real-time emergency & roadside assistance map · 100 % free · no billing required**

A standalone web portal (HTML + CSS + JS, no framework) that shows users the nearest hospitals, ambulances, pharmacies, towing services, puncture shops, trauma centers, police stations, and fire brigades — all on an interactive map with live routing and live responder tracking.

---

## ✨ Feature Overview

| Feature | Technology | Cost |
|---|---|---|
| Interactive Map | Leaflet.js + OpenStreetMap | Free |
| User GPS Location | Browser Geolocation API | Free |
| Nearby Services | Overpass API (OSM) | Free |
| Route + ETA | OSRM (router.project-osrm.org) | Free |
| Live Responder Tracking | Firebase Realtime Database | Free tier |
| Emergency SOS modal | Native `tel:` links + Web Share API | Free |

---

## 📁 File Structure

```
emergency-portal/
├── index.html          ← Main app shell
├── style.css           ← Dark glassmorphism UI
├── app.js              ← All application logic
├── firebase-config.js  ← 🔑 YOUR Firebase credentials go here
├── firebase-rules.json ← Database security rules (paste into Firebase Console)
├── start-server.bat    ← One-click local dev server (Windows)
└── README.md           ← This file
```

---

## 🚀 Quick Start

### Step 1 — Create a free Firebase project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **"Add project"** → give it a name (e.g. `roadsos-portal`) → Continue
3. Disable Google Analytics (optional) → **Create project**
4. In the left sidebar: **Build → Realtime Database → Create Database**
   - Choose a location (e.g. `asia-southeast1`)
   - Start in **test mode** (you can apply the rules file later)
5. Go to **Project Settings (⚙️) → General → Your apps → Add app → Web (`</>`)**
   - Register the app, then copy the `firebaseConfig` object

### Step 2 — Add your credentials

Open `firebase-config.js` and replace the placeholder values:

```js
const firebaseConfig = {
  apiKey:            "AIzaSy...",
  authDomain:        "roadsos-portal.firebaseapp.com",
  databaseURL:       "https://roadsos-portal-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId:         "roadsos-portal",
  storageBucket:     "roadsos-portal.appspot.com",
  messagingSenderId: "123456789",
  appId:             "1:123456789:web:abc123"
};
```

> **Important:** The `databaseURL` must match the Realtime Database URL shown in the Firebase console.

### Step 3 — Apply Firebase Security Rules

1. Firebase Console → **Realtime Database → Rules**
2. Paste the contents of `firebase-rules.json` → **Publish**

### Step 4 — Run locally

> ⚠️ ES modules (`import`/`export`) **do not work** when you open `index.html` directly from the file system (`file://`). You must use a local HTTP server.

Double-click **`start-server.bat`** (requires Python 3 or Node.js), then open:

```
http://localhost:8080
```

Alternatively, use the VS Code **Live Server** extension — right-click `index.html` → **Open with Live Server**.

---

## 🗺️ How It Works

### User Flow
1. Browser asks for GPS permission
2. Leaflet map centres on the user's position
3. Overpass API is queried for all service types within **10 km**
4. Results are sorted by straight-line distance and shown in the sidebar
5. Click any service card → ETA card appears + marker highlighted
6. Click **Get Directions** → OSRM calculates a real driving route drawn on the map
7. The map auto-refreshes services every 3 minutes

### Responder / Driver Flow
1. Enable the **"I am a Responder / Driver"** toggle in the sidebar
2. Enter your name/vehicle and service type
3. Click **Start Broadcasting Location**
4. Your GPS is pushed to Firebase every few seconds
5. All users watching the portal see your live position as a green marker

### SOS Button
Taps open a modal with:
- **Exact GPS coordinates**
- Quick-dial for 112 / 108 (Ambulance) / 101 (Fire) / 100 (Police)
- **Share Location** — uses Web Share API on mobile or copies a Google Maps link to clipboard

---

## 🛠️ Customisation

### Change search radius
In `app.js`, find the `bootstrap()` function:
```js
const services = await fetchNearbyServices(lat, lng, 10000); // ← metres
```
Change `10000` to any value (e.g. `20000` for 20 km).

### Add more service categories
In `app.js`, add an entry to `CATEGORY_CONFIG`:
```js
fuel: { icon: '⛽', color: '#E3B341', label: 'Fuel Station', queries: ['amenity=fuel'] },
```
Then add a chip button in `index.html`:
```html
<button class="chip" data-cat="fuel" id="chip-fuel">⛽ Fuel</button>
```

### Change map tile style (dark/satellite/etc.)
Replace the tile URL in `app.js` `initMap()`:
```js
// Dark (CartoDB):
'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'

// Satellite (Esri, free):
'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
```

---

## 🌐 Free Deployment Options

| Platform | Steps |
|---|---|
| **GitHub Pages** | Push the `emergency-portal/` folder as a repo → Settings → Pages → Deploy from `main` |
| **Netlify** | Drag & drop the `emergency-portal/` folder at [netlify.com/drop](https://netlify.com/drop) |
| **Vercel** | `npx vercel` inside the folder |
| **Firebase Hosting** | `firebase init hosting` → set public dir to `.` → `firebase deploy` |

---

## ⚠️ Limitations (Student / MVP)

- Overpass API may be slow during peak hours (add a loading spinner or increase timeout if needed)
- OSRM public instance has rate limits; for production, self-host OSRM or use a paid routing service
- Firebase free tier allows 100 simultaneous connections and 1 GB storage — plenty for demos
- Service data quality depends on OpenStreetMap contributions in your region

---

## 📜 Licence

MIT — free for academic, personal, and hackathon use.
