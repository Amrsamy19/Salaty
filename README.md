# Salaty (صلاتي)

A beautifully designed, cross-platform Flutter application dedicated to helping Muslims maintain their daily prayers, track their commitment, find the Qibla direction, and read daily Azkar.

## ✨ Features

*   **🕋 Accurate Prayer Times:** Automatically calculates precise prayer times based on the user's current geographic location.
*   **⏱️ Next Prayer Countdown:** Displays a dynamic countdown timer for the upcoming prayer in the Home Screen.
*   **📅 Hijri & Gregorian Dates:** Displays today's date in both Hijri and Gregorian formats directly on the dashboard.
*   **🧭 Qibla Compass:** A visually stunning, easily readable compass with a golden needle pointing directly to the Kaaba.
*   **📈 Prayer Tracker:** Allows users to log their daily prayers and viewing an interactive commitment history with mini-progress bars and statistics.
*   **📖 Daily Azkar:** Dedicated screens for morning (أذكار الصباح) and evening (أذكار المساء) Azkar, perfectly formatted for readability.
*   **🔔 Smart Notifications:** Get timely reminders for every prayer, along with scheduled notifications for morning and evening Azkar. Play the full Azan audio upon notification.
*   **🔊 Customizable Azan Sounds:** Choose from multiple renowned Azan reciters (Makkah, Egypt, Abdelbaset, Mohamed Refaat) and preview the sounds directly in the settings.
*   **🌍 Bilingual Support:** Full localization in **Arabic** (Default) and **English**, with tailored typography (Cairo for Arabic, Outfit for English).
*   **🎨 Premium UI/UX:** A rich, dark-themed aesthetic utilizing a custom brand palette (Navy Blue, Gold, Cream, and Slate) with smooth, glassmorphism-inspired components and micro-animations.
*   **🔠 Accessibility:** Adjustable application-wide font sizes for comfortable viewing.

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (v3.11.1 or higher)
*   Dart SDK
*   Android Studio / Xcode (for emulation/building)

### Installation

1.  **Clone the repository** (if applicable):
    ```bash
    git clone https://github.com/yourusername/salaty.git
    cd salaty
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```
    *Note: Ensure you have an emulator running or a physical device connected.*

## 🛠️ Technology Stack & Libraries

*   **Framework:** [Flutter](https://flutter.dev/)
*   **State Management:** `provider`
*   **Local Storage:** `shared_preferences`
*   **Prayer Times Calculation:** `adhan`
*   **Location Services:** `geolocator`
*   **Compass & Qibla:** `flutter_qiblah`
*   **Notifications:** `flutter_local_notifications`
*   **Audio Playback:** `audioplayers`
*   **Dates & Formatting:** `intl`, `hijri`
*   **Fonts:** `google_fonts`

## 📁 Project Structure

*   `lib/main.dart` - Entry point, sets up Providers and Theme dependencies.
*   `lib/screens/` - Contains the UI for the Home, Qibla, Tracker, Azkar, and Settings.
*   `lib/providers/` - Logic and state management (e.g., `PrayerProvider`).
*   `lib/services/` - Handles external configurations like Notifications, Storage, and Location.
*   `lib/models/` - Data definitions (e.g., `TrackerModel`).
*   `lib/l10n/` - Localization files and string mappings.

## 📱 Screenshots

*(Add screenshots of your application here)*
*   Home Screen & Next Prayer
*   Qibla Compass
*   Prayer Tracker History
*   Morning / Evening Azkar
*   Settings & Preferences

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check [issues page](https://github.com/yourusername/salaty/issues).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
