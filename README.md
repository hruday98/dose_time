# DoseTime - Medication Management App

[![CI/CD](https://github.com/your-username/dosetime/actions/workflows/ci_cd.yml/badge.svg)](https://github.com/your-username/dosetime/actions/workflows/ci_cd.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.16.0-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Integrated-orange.svg)](https://firebase.google.com/)

DoseTime is a comprehensive medication management and reminder system designed specifically for elderly users, built with Flutter and Firebase. The app supports three user roles: Patients, Doctors, and Caretakers, providing a complete ecosystem for medication management.

## 🌟 Features

### 🧑‍⚕️ For Patients
- **Medication Reminders**: Smart notifications with customizable schedules
- **Prescription Management**: Upload and manage prescriptions with OCR text recognition
- **Medication History**: Track adherence and medication logs
- **Large UI Elements**: Elderly-friendly interface with large fonts and buttons
- **Offline Support**: Works without internet connection using local storage

### 👨‍⚕️ For Doctors
- **Patient Management**: Manage multiple patients and their prescriptions
- **Prescription Creation**: Create and manage prescriptions for patients
- **Adherence Monitoring**: Track patient medication compliance
- **Cloud Synchronization**: Real-time updates across all devices

### 👪 For Caretakers
- **Family Care**: Manage medications for family members
- **Reminder Assistance**: Help ensure medications are taken on time
- **Progress Tracking**: Monitor medication adherence for care recipients

## 🏗️ Architecture

### Frontend (Flutter)
- **State Management**: Riverpod for reactive state management
- **Local Database**: Hive for offline data storage
- **Authentication**: Firebase Auth with email, Google, and Apple sign-in
- **Routing**: Go Router for navigation
- **UI/UX**: Material 3 design optimized for elderly users

### Backend (Firebase)
- **Database**: Cloud Firestore with real-time synchronization
- **Authentication**: Firebase Auth with role-based access control
- **Storage**: Firebase Storage for prescription images
- **Functions**: Cloud Functions for automated tasks and notifications
- **Messaging**: Firebase Cloud Messaging for push notifications

### Features Integration
- **OCR**: Google ML Kit for prescription text recognition
- **Notifications**: Local and push notifications for medication reminders
- **Security**: Comprehensive Firestore security rules
- **CI/CD**: GitHub Actions with automated testing and deployment

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.16.0 or later)
- Firebase CLI
- Node.js (18 or later) for Firebase Functions
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/dosetime.git
   cd dosetime
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Setup Firebase**
   ```bash
   # Install Firebase CLI if not already installed
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Initialize Firebase project
   firebase init
   ```

5. **Configure Firebase Options**
   - Update `lib/firebase_options.dart` with your Firebase project configuration
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

6. **Install Firebase Functions dependencies**
   ```bash
   cd functions
   npm install
   cd ..
   ```

7. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

1. **Create a Firebase project** at [Firebase Console](https://console.firebase.google.com/)

2. **Enable the following services:**
   - Authentication (Email/Password, Google, Apple)
   - Cloud Firestore
   - Firebase Storage
   - Cloud Functions
   - Firebase Cloud Messaging

3. **Configure authentication providers:**
   - Enable Email/Password authentication
   - Add Google and Apple sign-in (optional)

4. **Deploy Firestore rules and indexes:**
   ```bash
   firebase deploy --only firestore
   ```

5. **Deploy Cloud Functions:**
   ```bash
   firebase deploy --only functions
   ```

## 📋 Project Structure

```
dosetime/
├── lib/
│   ├── core/                  # Core utilities, themes, constants
│   │   ├── constants/
│   │   ├── models/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   ├── features/              # Feature modules
│   │   ├── auth/             # Authentication
│   │   ├── dashboard/        # Dashboard
│   │   ├── prescriptions/    # Prescription management
│   │   ├── reminders/        # Medication reminders
│   │   └── profile/          # User profile
│   ├── providers/            # Riverpod providers
│   ├── services/             # Business logic services
│   ├── firebase_options.dart
│   └── main.dart
├── functions/                # Firebase Cloud Functions
│   ├── src/
│   ├── package.json
│   └── tsconfig.json
├── .github/                  # GitHub Actions workflows
├── firestore.rules          # Firestore security rules
├── firestore.indexes.json   # Firestore indexes
├── firebase.json            # Firebase configuration
└── README.md
```

## 🔒 Security

### Authentication & Authorization
- **Multi-factor Authentication**: Email, Google, Apple sign-in
- **Role-based Access Control**: Patient, Doctor, Caretaker roles
- **Firestore Security Rules**: Comprehensive data access control

### Data Protection
- **Encryption**: All data encrypted in transit and at rest
- **Privacy**: HIPAA-compliant data handling practices
- **Local Storage**: Sensitive data encrypted using Hive

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ for better healthcare management
