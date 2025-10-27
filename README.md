# Flutter News App (Enhanced)\n\nThis project is an enhanced student-version Flutter News App ready for web and mobile (development).\n# 📰 Flutter News App

A modern, responsive Flutter application that displays the latest news from **[NewsAPI.org](https://newsapi.org)** in real time.
Developed as a school project — this app demonstrates **API integration**, **UI/UX design**, and **state management** in Flutter.

---

## 🚀 Features

✅ Fetches live data from NewsAPI
✅ Displays **Top Headlines** (default: United States)
✅ **Search bar** with instant query
✅ **Category chips** — filter by topics like Business, Sports, Health, Technology, etc.
✅ **Shimmer loading animation** for smooth UX
✅ **Placeholder images** for missing thumbnails
✅ **Detail page** with image, author, and estimated read time
✅ **Web support** (with proxy for CORS bypass)
✅ Clean and modular codebase: `models/`, `services/`, `screens/`, `widgets/`

---

## 🧠 Tech Stack

* **Flutter SDK:** 3.x or later
* **Language:** Dart
* **Packages Used:**

  * `http` → for REST API calls
  * `cached_network_image` → efficient image loading
  * `url_launcher` → open original article in browser
  * `shimmer` → skeleton loading effect

---

## 🗂️ Project Structure

```
lib/
├── constants.dart          # API key and base URL
├── main.dart               # App entry point
│
├── models/
│   └── article.dart        # Data model for article
│
├── services/
│   └── api_service.dart    # API handling and parsing
│
├── screens/
│   ├── home_screen.dart    # News list with categories & search
│   └── detail_screen.dart  # Detailed article view
│
└── widgets/
    └── article_tile.dart   # News card widget
```

---

## ⚙️ Setup Instructions

### 1️⃣ Clone or Extract

Download the ZIP and extract it, or clone from your GitHub:

```bash
git clone https://github.com/<your-username>/flutter_news_app.git
cd flutter_news_app
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

### 3️⃣ Run on Web or Mobile

```bash
flutter run -d chrome
```

or

```bash
flutter run -d android
```

---

## 🔑 API Configuration

This app uses [NewsAPI.org](https://newsapi.org).
Your API key is stored in:

```
lib/constants.dart
```

```dart
const String NEWS_API_KEY = 'YOUR_API_KEY';
const String BASE_URL = 'https://newsapi.org/v2';
```

> ⚠️ **Important:**
> Do **not** commit your API key to public repositories.
> Add `lib/constants.dart` to your `.gitignore` if publishing your project.

---

## 🧩 Extra Features (Bonus Ideas)

If you’d like to improve this project further:

* 🗂 **Bookmark feature** using Hive or SharedPreferences
* 🎙 **Text-to-speech** reading for articles
* 🌓 **Dark mode** toggle
* 🔔 **Push notifications** for breaking news
* 💾 **Offline caching**

---

## 🖼️ Screenshots

| Home                            | Detail                              | Loading                               |
| ------------------------------- | ----------------------------------- | ------------------------------------- |
| ![Home](./screenshots/home.png) | ![Detail](./screenshots/detail.png) | ![Loading](./screenshots/loading.png) |

*(You can capture your own screenshots and save them in a `screenshots/` folder.)*

---

## 💡 Troubleshooting

If you see `CORS policy` errors while running on **Web**, the app automatically uses a free proxy:

```
https://api.allorigins.win/raw?url=
```

This allows development in Chrome, but for production use, set up your own backend proxy.

---

## 👨‍💻 Developer Info

**Name:** [Your Name]
**Project:** Flutter News App — School Assignment
**Mentor:** Mr. Alfarobi ([alfarobi.dev@gmail.com](mailto:alfarobi.dev@gmail.com))
**Date:** October 2025

---

## 🏁 License

This project is open source and free to use for educational purposes.
Feel free to fork and customize!

---

> “Good design is as little design as possible.” – *Dieter Rams*
