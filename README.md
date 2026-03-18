# Salaty (صلاتي) 🕋

![Salaty Logo](assets/images/logo_premium.png)

A beautifully designed, premium Flutter application dedicated to helping Muslims maintain their daily prayers, track commitment, read the Holy Quran, and find the Qibla direction with a stunning modern aesthetic.

## ✨ New: Premium Quran Experience (القرآن الكريم)

The latest update introduces a full-featured Quran experience designed for both listening and reading:

*   **📖 Mushaf with Tashkeel:** Read the Holy Quran in beautiful Uthmani script with full diacritics (التشكيل) for an authentic and accurate reading experience.
*   **🔊 Synchronized Audio:** Listen to the renowned recitation by Mishary Rashid Alafasy.
*   **✨ Real-time Ayah Highlighting:** Watch the text glow gold and automatically scroll in perfect sync with the audio recitation.
*   **📥 Offline Playback:** Download any surah to listen without an internet connection, saving data and ensuring accessibility anywhere.
*   **🧹 Storage Management:** A built-in dashboard to monitor and manage your downloaded surahs, including one-tap "Delete All" for storage efficiency.
*   **🤲 Dedicated Reading Mode:** A focused Mushaf-style reading view for when you want to read without audio.

## 🕌 Core Features

*   **🕋 Accurate Prayer Times:** Precise calculations based on your geographic location.
*   **⏱️ Next Prayer Countdown:** A dynamic dashboard showing exactly how much time is left until the next prayer.
*   **🧭 Qibla Compass:** A visually stunning compass with a golden needle pointing directly to the Kaaba.
*   **📈 Prayer Tracker & Gamification:** Log your prayers, track streaks, and view interactive stats to maintain your commitment.
*   **📖 Daily Azkar:** Beautifully formatted morning and evening Azkar with a refined dark-mode UI.
*   **🔔 Smart Notifications:** Full Azan audio notifications for every prayer time.
*   **🔊 Customizable Azan:** Choose from multiple famous reciters (Makkah, Egypt, Abdelbaset, and more).
*   **🌍 Multi-language Support:** Full Arabic and English localization with premium typography (Cairo & Outfit).

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (v3.11.1 or higher)
*   Dart SDK
*   Android Studio / Xcode

### Installation

1.  **Clone & Fetch Dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Run the application:**
    ```bash
    flutter run
    ```
    *Note: If you have added new plugins, use a full build to avoid MissingPluginException.*

## 🛠️ Technology Stack

*   **Framework:** [Flutter](https://flutter.dev/)
*   **State Management:** `provider`
*   **Audio Powerhouse:** `just_audio` & `audioplayers`
*   **Network & Data:** `dio`, `connectivity_plus`
*   **Local Persistence:** `shared_preferences`, `path_provider`
*   **UI Helpers:** `scrollable_positioned_list`, `google_fonts`, `flutter_spinkit`
*   **Islamic Engines:** `adhan`, `hijri`, `flutter_qiblah`

## 🎨 Design Philosophy

Salaty is built with a **Premium Dark Aesthetic**. We use a curated palette of **Deep Navy (#0A0A0F)**, **Royal Purple**, and **Radiant Gold** to create a spiritual, modern, and distraction-free environment for the user.

---
*Built with ❤️ for the Ummah.*
