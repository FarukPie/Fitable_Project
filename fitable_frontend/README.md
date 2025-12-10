# Fitable Frontend

This is the Flutter-based mobile application for Fitable. It allows users to manage their digital wardrobe and analyze clothing items using AI by pasting product links.

## 🚀 Features
- **State Management**: Powered by `flutter_riverpod` for clean and testable architecture.
- **Firebase Integration**: Uses Firestore for database and Auth for user sessions.
- **Secure Configuration**: Uses `flutter_dotenv` to manage sensitive API keys securely.
- **Dynamic UI**: Responsive design with `CurvedNavigationBar` and custom animations.

## 🛠️ Installation

### Prerequisites
- Flutter SDK (3.0+)
- Dart (3.0+)
- Firebase Project Setup

### Setup
1.  **Clone the repository.**
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure Environment:**
    *   Create a `.env` file in the root directory (same level as `pubspec.yaml`).
    *   Add your Firebase configuration keys:
        ```env
        API_KEY=your_api_key
        APP_ID=your_app_id
        MESSAGING_SENDER_ID=your_sender_id
        PROJECT_ID=your_project_id
        ```
    *   *Note: This file is ignored by Git for security.*

4.  **Backend Connection:**
    *   Ensure the `ApiService` in `lib/services/api_service.dart` points to your active Backend URL (e.g., `http://10.0.2.2:8000` for Android Emulator or your server IP).

## 🏃‍♂️ Running the App

Run on a connected device or emulator:
```bash
flutter run
```

## 🧪 Testing

Run unit and widget tests:
```bash
flutter test
```
