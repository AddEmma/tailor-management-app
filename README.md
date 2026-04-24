# Tailor Management App 🧵👗

A comprehensive Flutter-based management system designed for professional tailors and fashion designers to digitize their customer records, measurements, and orders.

## ✨ Features

- **📊 Smart Dashboard**: Monitor total customers, active orders, and monthly revenue in real-time.
- **📏 Measurement Tracking**: Store detailed customer measurements securely in the cloud.
- **📋 Order Lifecycle Management**: Track orders from "Pending" to "Delivered" with urgency indicators.
- **💰 Financial Overview**: Monitor payments, balances, and revenue with Ghanaian Cedi (GH₵) support.
- **📥 Data Export**: Generate Excel reports of all your business data for offline use.
- **📱 Cross-Platform**: Optimized for Mobile, Tablet, and Desktop.

## 🚀 Tech Stack

- **Frontend**: [Flutter](https://flutter.dev)
- **Backend**: [Firebase](https://firebase.google.com) (Auth & Firestore)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Reporting**: Excel export support

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Firebase Account
- Android Studio / VS Code

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/tailor-management-app.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Create a project on [Firebase Console](https://console.firebase.google.com/).
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
   - Run `flutterfire configure` to update `firebase_options.dart`.

4. Run the app:
   ```bash
   flutter run
   ```

## 📖 Documentation

For detailed product requirements and future roadmap, see the [Product Requirements Document (PRD)](./PRD.md).

