# RoadSoS — Emergency Road Accident Response App

**Hackathon:** Road Safety Hackathon 2026, CoERS, IIT Madras

RoadSoS helps accident victims and bystanders instantly locate and contact nearby emergency services during road accidents. The app works in low/no network conditions with an offline-first architecture.

---

## Features

### 1. Location-Based Emergency Services
- Detects user's GPS location in real-time
- Shows nearest: **Hospitals, Police stations, Ambulance services, Towing services, Trauma centres, Puncture shops**
- Display as a **sorted list** (by distance) or on an **interactive map**
- Uses **OpenStreetMap Overpass API** for global POI data
- Each result shows: name, distance, phone number, call button, and directions button

### 2. Offline-First Architecture
- Pre-downloads all emergency services within **50km radius** on sync
- Stores in local **SQLite database** (sqflite)
- When offline, serves from SQLite cache automatically
- Shows a clear **"Offline Mode"** indicator banner
- Auto-syncs when connection is restored (checked every 30 seconds)

### 3. Smart Accident Detection
- Monitors sensors continuously in background:
  - **Accelerometer** — detects sudden G-force spike > 3G
  - **GPS speed** — detects sudden drop to near 0 from >30 km/h
- If **both triggers** fire within 3 seconds:
  - Shows popup with **30-second countdown**
  - If user doesn't dismiss → **auto-triggers SOS**
- SOS sends GPS location + emergency message via SMS to saved contacts

### 4. One-Tap SOS Button
- Large **250px red SOS button** on home screen
- On tap: immediately sends SMS with location to emergency contacts
- Also **auto-calls** the nearest hospital/ambulance

### 5. Emergency Contacts Management
- Save up to **3 emergency contacts** (name + phone)
- Indian mobile number validation (10 digits, starts with 6-9)
- Contacts receive SMS during any SOS trigger

### 6. Multilingual Support
- Supports: **English, Hindi (हिंदी), Tamil (தமிழ்)**
- 60+ translated strings in `.arb` files
- Language selector in Settings (persisted via SharedPreferences)

### 7. AI Emergency Assistant (Bonus)
- Integrated **Cerebras LLM chatbot** for emergency guidance
- Helps with first aid tips, locating services, and app usage
- Accessible via floating chat button on home screen

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Maps | flutter_map + OpenStreetMap tiles |
| POI Data | OpenStreetMap Overpass API |
| Local Database | sqflite (SQLite) |
| Location | geolocator |
| Sensors | sensors_plus (accelerometer) |
| SMS/Calls | url_launcher (sms: / tel: URI) |
| State Management | Provider |
| AI Chatbot | Cerebras API (LLaMA 3.1 8B) |
| Environment | flutter_dotenv (.env file) |
| Localization | flutter_localizations + .arb files |

---

## Project Structure

```
lib/
  main.dart                          # App entry point, locale, providers
  screens/
    home_screen.dart                 # SOS button, quick cards, offline banner
    map_screen.dart                  # OpenStreetMap with service markers
    services_list_screen.dart        # Sorted list of nearby services
    settings_screen.dart             # Language, sync, contacts access
    emergency_contacts_screen.dart   # Add/delete emergency contacts
    signup_screen.dart               # User onboarding + profile
    chatbot_screen.dart              # AI assistant chat interface
  services/
    location_service.dart            # GPS location + distance calculation
    accident_detection_service.dart  # Accelerometer + speed monitoring
    database_service.dart            # SQLite CRUD operations
    sms_service.dart                 # SMS and phone call via url_launcher
    api_service.dart                 # Overpass API + Cerebras API
  models/
    emergency_service.dart           # Service data model (hospital, police, etc.)
    emergency_contact.dart           # Contact data model (name, phone)
  widgets/
    sos_button.dart                  # Large red SOS button widget
    service_card.dart                # Service detail card with call/directions
    offline_banner.dart              # Offline mode indicator banner
  utils/
    constants.dart                   # Colors, text styles, constants
    helpers.dart                     # Connectivity check, formatting utilities
  l10n/
    app_en.arb                       # English translations
    app_hi.arb                       # Hindi translations
    app_ta.arb                       # Tamil translations
```

---

## Setup & Run

### Prerequisites
- Flutter SDK ≥ 3.2.0
- Android SDK (API 21+) for Android builds

### Steps

```bash
# Clone and enter the project
cd RoadSoS

# Install dependencies
flutter pub get

# Set up environment variables
cp .env.example .env
# Edit .env with your API keys

# Run on connected device or emulator
flutter run
```

### Environment Variables (`.env`)
```
GOOGLE_PLACES_API_KEY=your_api_key_here
CEREBRAS_API_KEY=your_cerebras_api_key_here
```

---

## UI Design

- **Color scheme:** Red (#D32F2F) + White + Dark Grey
- **Panic-friendly UI:** Large text, high contrast, big tap targets
- **2-tap navigation:** Everything reachable within 2 taps
- **Home screen:** SOS button (center) → Quick service cards → Bottom nav
- **Bottom navigation:** Home | Map | Settings

---

## Android Permissions

The app requires the following permissions (configured in `AndroidManifest.xml`):

- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — GPS
- `ACCESS_BACKGROUND_LOCATION` — Background accident detection
- `INTERNET` / `ACCESS_NETWORK_STATE` — API calls
- `SEND_SMS` — Emergency SMS
- `CALL_PHONE` — Auto-call nearest hospital
- `HIGH_SAMPLING_RATE_SENSORS` — Accelerometer (Android 12+)

---

## Evaluation Criteria

| Criteria | How It's Addressed |
|----------|-------------------|
| Reliability & data accuracy | SQLite cache + real-time Overpass API sync |
| Number of contacts/services | 50km radius pre-download, 30+ results per type |
| Offline functionality | SQLite offline-first with auto-sync |
| Innovation | Dual-sensor accident detection (accelerometer + GPS speed) |
| Global compatibility | OpenStreetMap works worldwide |

---

## Team

**Hackathon:** Road Safety Hackathon 2026, CoERS, IIT Madras
