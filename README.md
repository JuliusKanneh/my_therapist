# AI Therapist Chat App 🧠💬

An AI-powered personalized therapy chat mobile app built with Flutter and Google AI technologies to help patients struggling with depression and mental health challenges.

## 🏗️ Tech Stack

- **Frontend**: Flutter (Dart)
- **State Management**: GetX
- **Backend**: Firebase (Firestore, Authentication, Cloud Functions)
- **AI/ML**: Google Vertex AI, Gemini API
- **Platform**: Android (iOS support planned)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.10.0 or higher)
- **Dart SDK** (3.0.0 or higher)
- **Java Development Kit** (JDK 17) - **Important: Use JDK 17, not newer versions**
- **Android Studio** with Android SDK
- **Firebase CLI**
- **Git**

### Java Version Check
```bash
java --version
# Should show version 17.x.x
```

If you have Java 22 or newer, you must downgrade to Java 17 for compatibility.

## 🚀 Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/my_therapist.git
cd my_therapist
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### Install Firebase CLI
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login
```

#### Configure Firebase for the Project
```bash
# Configure Firebase (this will create firebase_options.dart)
flutterfire configure --platforms=android

# Select your Firebase project or create a new one
# Use package name: com.example.my_therapist
```

#### Initialize Firebase Services
```bash
# Initialize Firestore
firebase init firestore

# Deploy security rules
firebase deploy --only firestore:rules
```

### 4. Android Configuration

Ensure your `android/app/build.gradle` has:
```gradle
android {
    defaultConfig {
        minSdk = 23  // Required for Firebase
        multiDexEnabled = true
    }
}
```

### 5. Environment Variables

Create a `.env` file in the project root (this file is gitignored):
```env
# Add your API keys here
VERTEX_AI_API_KEY=your_vertex_ai_key
GEMINI_API_KEY=your_gemini_key
```

## 🔧 Running the App

### Development Mode
```bash
flutter run
```

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
```

## 📁 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── bindings/          # GetX dependency injection
│   ├── controllers/       # Business logic & state management
│   ├── data/
│   │   ├── models/        # Data models
│   │   ├── services/      # API services (Firebase, AI)
│   │   └── repositories/  # Data access layer
│   ├── routes/            # App routing with GetX
│   ├── ui/
│   │   ├── pages/         # App screens
│   │   ├── widgets/       # Reusable UI components
│   │   └── theme/         # App theming
│   └── utils/             # Helper functions
├── firebase_options.dart  # Auto-generated Firebase config
└── test/                  # Unit tests
```

## 🔐 Security & Privacy

- **HIPAA Compliance**: Implemented for handling sensitive health data
- **End-to-End Encryption**: All therapy conversations are encrypted
- **Crisis Detection**: AI monitors for emergency situations
- **Data Privacy**: User data is strictly protected and anonymized

## 🧪 Testing Firebase Connection

Run the app in debug mode and check the console for:
```
✅ Firebase initialized successfully
✅ Firestore connection successful
✅ Firebase Auth initialized
```

## 🚨 Troubleshooting

### Common Issues

1. **Java Version Error**
   ```
   Solution: Install JDK 17 and set JAVA_HOME environment variable
   ```

2. **Gradle Build Failed**
   ```bash
   flutter clean
   cd android && ./gradlew clean && cd ..
   flutter pub get
   ```

3. **Firebase Connection Issues**
   ```bash
   # Reconfigure Firebase
   flutterfire configure --platforms=android
   ```

4. **GetX Dependencies Not Found**
   ```bash
   flutter pub get
   flutter pub deps
   ```

## 🔄 Firebase Services Used

- **Authentication**: User registration and login
- **Firestore**: Real-time chat messages and user data
- **Cloud Functions**: AI processing and crisis detection
- **Firebase Messaging**: Push notifications for urgent alerts

## 📱 Features

- [x] Firebase authentication setup
- [x] Real-time chat interface
- [x] AI-powered therapeutic responses
- [x] Crisis detection and emergency protocols
- [x] User progress tracking
- [ ] Mood analytics dashboard
- [ ] Appointment scheduling
- [ ] Multi-language support

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

Coming Soon! For now, it is open source.

## 📞 Support

For development setup issues:
- Check the troubleshooting section above
- Create an issue on GitHub
- Contact the development team

## 🔒 Important Security Notes

- Never commit `google-services.json` to version control
- Keep API keys in environment variables
- Use Firebase security rules for data protection
- Regularly audit dependencies for vulnerabilities

---

**Note**: This app handles sensitive mental health data. Please ensure compliance with local healthcare regulations (HIPAA, GDPR, etc.) before deployment.