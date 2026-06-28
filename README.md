<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.9.2%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-3.5%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Android-API%2021%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
<img src="https://img.shields.io/badge/iOS-13%2B-000000?style=for-the-badge&logo=apple&logoColor=white" />
<img src="https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge" />

<br />

# 🏥 Sanjeevani Mobile Apps

**A next-generation pharmacy ecosystem — two powerful Flutter apps powering the complete medicine delivery & management experience.**

[📦 Sanjeevani Hub](#-sanjeevani-hub--delivery--customer-app) · [🖥️ Sanjeevani Nexus](#️-sanjeevani-nexus--pharmacy-os-app) · [🚀 Quick Start](#-getting-started) · [🗂️ Architecture](#️-architecture)

</div>

---

## 🌿 About the Project

**Sanjeevani** (Sanskrit: *"life-giving"*) is a full-stack pharmacy platform built to digitize and intelligently automate the entire medicine delivery pipeline. This repository contains **two cross-platform Flutter applications** that work together with the Sanjeevani backend:

| App | Folder | Purpose |
|-----|--------|---------|
| 🚀 **Sanjeevani Hub** | `Sanjeevani-Hub/` | Customer & Delivery Agent App |
| 🖥️ **Sanjeevani Nexus** | `Sanjeevani-Nexus/` | Pharmacist / Pharmacy OS App |

Together these apps cover every actor in the pharmacy delivery ecosystem — **customers, delivery agents, and pharmacists**.

---

## 📦 Sanjeevani Hub — Delivery & Customer App

> The field-operations app — used by **customers** to order medicines and by **delivery agents** to manage and complete deliveries.

### ✨ Key Features

#### 👤 Customer Side
- 🗺️ **Interactive Map** — Real-time order tracking with live delivery agent location (Mapbox + Flutter Map)
- 📋 **Order Management** — Place, track, and review medicine orders
- 💬 **AI Chatbot** — Integrated conversational assistant for prescription help
- 🔔 **Smart Notifications** — Order status updates via push + in-app alerts
- 🏪 **Pharmacy & Shop Profiles** — Browse nearby pharmacies with availability info
- 🔍 **Medicine Search** — Search and discover medicines by name, category, or condition

#### 🛵 Delivery Agent Side
- 📍 **Live Delivery Map** — GPS-powered navigation with real-time route updates
- 📦 **Order Queue Management** — Accept, reject, and complete deliveries
- 📊 **Delivery Analytics** — Track earnings, completed deliveries, and performance
- 🔔 **Delivery Notifications** — Instant assignment alerts
- 👤 **Agent Profile** — Status toggling (online/offline), profile management

#### 🔐 Auth & Security
- Role-based onboarding (Customer / Delivery Agent)
- OTP verification + device binding
- Biometric authentication (fingerprint/face)
- Flutter Secure Storage for credential management
- Screen protection against unauthorized capture

### 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.9.2 (Dart 3.9+) |
| Maps | Mapbox Maps Flutter + Flutter Map |
| Real-time | WebSocket Channel |
| Auth | Local Auth (Biometrics), Flutter Secure Storage |
| Notifications | Firebase Cloud Messaging + Flutter Local Notifications |
| Location | Geolocator |
| Camera | Camera + Image Picker |
| HTTP | `http` package |
| UI/UX | Glass Kit, Flutter Animate, Google Fonts |
| Storage | Shared Preferences |

### 📂 Project Structure

```
Sanjeevani-Hub/
├── lib/
│   ├── main.dart                    # App entry, routing, theme
│   ├── auth/
│   │   ├── login_screen.dart        # Login flow
│   │   ├── register_screen.dart     # Full registration
│   │   ├── role_select_screen.dart  # Customer / Delivery role picker
│   │   ├── welcome_screen.dart      # Onboarding splash
│   │   └── short_register_screen.dart
│   ├── customer/
│   │   ├── customer_home.dart             # Customer shell
│   │   ├── customer_map_tab.dart          # Live order tracking map
│   │   ├── customer_orders_page.dart      # Order history
│   │   ├── customer_notifications_page.dart
│   │   └── customer_profile_page.dart
│   ├── delivery/
│   │   ├── delivery_home.dart             # Delivery shell
│   │   ├── delivery_map_tab.dart          # Agent navigation map
│   │   ├── delivery_orders_tab.dart       # Active & past deliveries
│   │   ├── delivery_notifications_tab.dart
│   │   ├── delivery_profile_tab.dart
│   │   ├── chatbot_page.dart              # AI chat interface
│   │   ├── search_page.dart               # Medicine search
│   │   ├── pharmacy_profile_page.dart
│   │   └── shop_profile_page.dart
│   ├── core/
│   │   └── config/                        # API endpoints, constants
│   └── services/                          # API services, WebSocket
├── android/                               # Android platform config
├── ios/                                   # iOS platform config
├── assets/icons/                          # App icons & images
└── pubspec.yaml
```

---

## 🖥️ Sanjeevani Nexus — Pharmacy OS App

> The back-office powerhouse — used by **pharmacists** to manage inventory, orders, patients, and AI-powered insights.

### ✨ Key Features

#### 📊 Dashboard
- Real-time stats: orders, patients, revenue, stock alerts
- KPI cards with visual charts (fl_chart)
- Quick-action shortcuts

#### 📦 Order Management
- View and manage incoming orders from all channels (WhatsApp, SMS, Web, Telegram)
- Approve / reject orders with one tap
- Order history and filtering

#### 🧑‍⚕️ Patient Management
- Browse patient profiles and prescription history
- Patient notes and communication

#### 🗃️ Inventory Management
- Stock level tracking per medicine
- Add medicines via barcode scan (Mobile Scanner + ML Kit)
- Low-stock alerts

#### 🤖 AI Insights
- AI-powered refill predictions
- Demand forecasting
- Prescription pattern analysis

#### 📸 Scan & Add Products
- OCR-powered medicine label scanning (Google ML Kit Text Recognition)
- QR/Barcode product lookup

#### 🔐 Authentication
- Role selection (Pharmacist / Delivery)
- Google Sign-In support
- Persistent sessions via Shared Preferences

### 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.5+ (Dart 3.5+) |
| State Management | Provider |
| Charts | fl_chart |
| Barcode / QR Scan | Mobile Scanner |
| OCR | Google ML Kit Text Recognition |
| Local DB | SQLite (sqflite) |
| HTTP | `http` package |
| Auth | Google Sign-In |
| UI/UX | Google Fonts, Material 3 |
| WebView | webview_flutter |

### 📂 Project Structure

```
Sanjeevani-Nexus/
├── lib/
│   ├── main.dart                          # App entry, routing, theme
│   ├── models/
│   │   └── order_model.dart              # Data models
│   ├── services/
│   │   ├── api_config.dart               # 🔧 Backend URL config
│   │   └── order_service.dart            # API service layer
│   ├── screens/
│   │   ├── welcome_screen.dart           # Welcome / Onboarding
│   │   ├── role_select_screen.dart       # Pharmacist / Delivery picker
│   │   ├── pharmacist/
│   │   │   ├── pharmacist_home.dart      # Main shell with tab bar
│   │   │   ├── pharmacist_profile_screen.dart
│   │   │   ├── add_medicine_screen.dart
│   │   │   ├── scan_product_screen.dart  # ML Kit barcode scanner
│   │   │   └── tabs/
│   │   │       ├── pharma_overview_tab.dart   # Dashboard
│   │   │       ├── pharma_orders_tab.dart     # Orders
│   │   │       ├── pharma_patients_tab.dart   # Patients
│   │   │       ├── pharma_inventory_tab.dart  # Inventory
│   │   │       └── pharma_ai_tab.dart         # AI Insights
│   │   ├── auth/                         # Auth screens
│   │   └── delivery/                     # Delivery screens
│   ├── theme/
│   │   └── app_theme.dart               # Color palette, typography
│   └── widgets/
│       ├── stat_card.dart               # Reusable KPI cards
│       └── section_header.dart
├── assets/logo.png
└── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites

Before running either app, ensure you have:

- **Flutter SDK 3.9.2+** → [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Android Studio** or **VS Code** with Flutter/Dart extensions
- **Android Emulator** (API 21+) or a physical device
- **The Sanjeevani Backend** running (see backend repo)

Verify your Flutter setup:
```bash
flutter doctor
```

---

### 🔧 Running Sanjeevani Hub

```bash
# 1. Navigate to the Hub app
cd Sanjeevani-Hub

# 2. Install dependencies
flutter pub get

# 3. Configure your backend URL
#    Open: lib/core/config/api_config.dart
#    Update the base URL to point to your backend server

# 4. Run the app
flutter run
```

**Build for production:**
```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

---

### 🔧 Running Sanjeevani Nexus

```bash
# 1. Navigate to the Nexus app
cd Sanjeevani-Nexus

# 2. Install dependencies
flutter pub get

# 3. Configure your backend URL
#    Open: lib/services/api_config.dart
#    Set the baseUrl per your environment:

# | Environment              | URL                          |
# |--------------------------|------------------------------|
# | Android Emulator (local) | http://10.0.2.2:8000         |
# | Physical device (WiFi)   | http://YOUR_PC_IP:8000       |
# | Production               | https://api.sanjeevani.com   |

# 4. Run the app
flutter run
```

**Build for production:**
```bash
flutter build apk --release
flutter build appbundle --release
```

---

### Android Permissions (Hub)

The following permissions are required in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 🗂️ Architecture

Both apps follow a **clean layered architecture**:

```
┌─────────────────────────────────────┐
│              UI Layer               │
│   Screens, Tabs, Widgets, Theme     │
├─────────────────────────────────────┤
│           State Management          │
│   Provider (Nexus) / setState (Hub) │
├─────────────────────────────────────┤
│            Service Layer            │
│   API Services, WebSocket, Storage  │
├─────────────────────────────────────┤
│              Data Layer             │
│   Models, Local DB (sqflite), Prefs │
├─────────────────────────────────────┤
│         External Services           │
│  Backend API, Firebase, Mapbox, ML  │
└─────────────────────────────────────┘
```

### System Overview

```
┌──────────────────┐     REST/WS     ┌─────────────────────┐
│  Sanjeevani Hub  │ ◄──────────────► │                     │
│  (Customer App)  │                  │  Sanjeevani Backend │
│  (Delivery App)  │                  │  (FastAPI + MongoDB) │
└──────────────────┘                  │                     │
                                      └─────────────────────┘
┌──────────────────┐     REST/WS              ▲
│ Sanjeevani Nexus │ ◄────────────────────────┘
│  (Pharmacy App)  │
└──────────────────┘
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| App can't connect to backend | Check `api_config.dart` URL; ensure backend is running |
| No orders appearing | Run backend seed script; verify DB connection |
| Maps not loading | Verify Mapbox API token is configured |
| Build errors after pulling code | Run `flutter clean && flutter pub get && flutter run` |
| iOS build fails | Ensure Xcode CLI tools are installed and up to date |
| Biometrics not working | Check device has biometrics enrolled; verify permissions |
| FCM push not received | Verify `google-services.json` is placed in `android/app/` |

---

## 📱 Platform Support

| Platform | Sanjeevani Hub | Sanjeevani Nexus |
|----------|:--------------:|:----------------:|
| ✅ Android (API 21+) | ✅ Full | ✅ Full |
| ✅ iOS (13+) | ✅ Full | ✅ Full |
| ⚠️ Web | Partial | Partial |
| ⚠️ Windows / macOS / Linux | Partial | Partial |

---

## 🤝 Contributing

We love contributions! Whether you're a student, a friend, or an open-source contributor, we'd love your help.

👉 **[Please read our full Contributing Guide (CONTRIBUTING.md) here!](./CONTRIBUTING.md)** 👈

It contains everything you need to know about:
- What this project is and how it helps the world 🌍
- What kind of solutions we accept (Bug fixes, UI improvements, etc.) 💡
- A step-by-step beginner's guide to making your first Pull Request! 🛠️

*When contributing, please follow these project-specific standards:*
- Run `flutter format .` before committing
- Run `flutter analyze` — resolve all warnings
- All API calls must go through `services/` — **never write raw HTTP calls in screens**
- Follow the existing theme system in `theme/app_theme.dart`

---

## 🔒 Security

- All API communication over HTTPS in production
- JWT tokens for API authentication
- Sensitive credentials stored using Flutter Secure Storage (AES-256)
- Device binding prevents token reuse on unauthorized devices
- Screen protection prevents unauthorized screenshots

> ⚠️ **Never commit `.env` files, API keys, or Firebase config files (`google-services.json`, `GoogleService-Info.plist`) to version control.**

---

## 📄 License

This project is **proprietary software**. All rights reserved © Sanjeevani / Samay AI Verse.

Unauthorized copying, distribution, or modification is strictly prohibited.

---

<div align="center">

Made with ❤️ by the **Sanjeevani Team**

*Empowering healthcare, one delivery at a time.*

</div>
