# Salaty (صلاتي)

Salaty is a premium, cross-platform prayer times application built with **React Native** and **Expo**. It offers a minimalist, modern Islamic aesthetic with a high-performance bottom tab navigation system, real-time Qibla compass, and automated prayer tracking.

## ✨ Key Features

-   **Precision Prayer Times**: Calculates accurate prayer times based on your current geographical location.
-   **Bottom Tab Navigation**: A sleek, native-feeling interface to switch between Home, Qibla, Azkar, Tracker, and Settings.
-   **Qibla Compass**: Real-time direction finding using device sensors with a beautiful SVG-based compass.
-   **Azkar Library**: Comprehensive morning and evening remembrances with interactive counters and social sharing.
-   **Prayer Tracker**: Log your daily prayers to monitor your consistency.
-   **Customizable Azan**: Choose from multiple world-renowned Azan voices (Makah, Egypt, Abdelbaset, etc.).
-   **Localization**: Optimized for both **Arabic (RTL)** and **English** languages with adaptive font scaling.
-   **Background Notifications**: Native push notifications that trigger full-screen Azan modals even when the app is closed.

## 🚀 Tech Stack

-   **Framework**: [React Native](https://reactnative.dev/) / [Expo SDK 52+](https://expo.dev/)
-   **Language**: TypeScript
-   **Icons**: [Lucide React Native](https://lucide.dev/)
-   **Date/Time**: Adhan JS, Date-fns, moment-hijri
-   **Sensors**: Expo Sensors (Magnetometer)
-   **Audio**: Expo AV

## 🛠️ Performance & Size Optimization

Salaty is built for efficiency. The Android production build utilizes several optimization techniques:
-   **ABI Splitting**: Generates separate, lightweight APKs optimized for specific phone architectures (arm64, v7a, etc.), reducing download size from 80MB+ to ~25MB.
-   **Code Minification**: Uses R8/Proguard to strip unused code and optimize runtime performance.
-   **Resource Shrinking**: Identifies and removes unused assets during the build process.

## 📦 Getting Started

### Prerequisites
- Node.js & npm
- Expo CLI (`npm install -g expo-cli`)
- Android Studio / Xcode for native runs

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Amrsamy19/Salaty.git
   cd Salaty
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm start
   ```

### Building for Android
To generate an optimized production APK:
```bash
npx expo run:android --variant release
```
The output will be located in `android/app/build/outputs/apk/release/`.

## 🎨 Design Philosophy
The app follows a "Gold on Deep Night" palette (`#c5a35e` on `#061026`), emphasizing spiritual focus and readability for both day and night use.

## 📄 License
This project is licensed under the MIT License.

---
*Created with ❤️ by Amr Samy*
