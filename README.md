# Water Meter Electronic Reader

A Flutter mobile application that integrates IoT technology with existing analog water meters to enable real-time water consumption monitoring. The system uses an **ESP32-CAM** microcontroller paired with a **TCRT5000 IR optical sensor** to automatically capture meter readings and transmit them to the cloud — no replacement of existing infrastructure required.

---

## Description

Manual water meter reading is time-consuming and prone to human error. This project addresses that challenge by attaching a TCRT5000 IR optical sensor to the meter's low-flow dial, which detects each rotation as a pulse and converts it into liters consumed. An ESP32-CAM periodically photographs the meter face for visual verification and posts all data to Firebase in real time. A Flutter app then displays live readings, usage history, cost estimates, and leak alerts — accessible from anywhere.

---

## Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x or higher
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Android Studio or Xcode (for running on device/emulator)
- Arduino IDE 2.x (for ESP32-CAM firmware)

### 1. Clone the repository

```bash
git clone https://github.com/your-username/water-meter-electronic-reader.git
cd water-meter-electronic-reader
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

1. Create a project at [Firebase Console](https://console.firebase.google.com).
2. Enable **Firestore**, **Authentication** (Email/Password), and **Storage**.
3. Run FlutterFire CLI to generate `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Run the app

```bash
# Android
flutter run

# iOS
flutter run -d ios
```

---

