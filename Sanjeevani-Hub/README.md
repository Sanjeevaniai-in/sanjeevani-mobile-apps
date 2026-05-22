# Sanjeevani

Sanjeevani is a comprehensive mobile application designed for pharmacy delivery and healthcare services, providing real-time tracking, incident reporting, and secure communication capabilities. Built with Flutter for cross-platform compatibility, it integrates with a robust backend for reliable data handling and real-time updates.

## Overview

Sanjeevani (representing "life-giving" in Sanskrit) serves as an advanced digital pharmacy hub that enhances delivery operations and situational awareness. The application combines mobile technology with precision tracking to deliver a powerful tool for modern healthcare logistics.

### Key Components

- **Mobile App (Flutter)**: Cross-platform application for Android and iOS devices
- **Backend Server**: Python-based API server with real-time WebSocket support
- **AI Integration**: YOLOv8 models for enhanced object recognition
- **Database**: MongoDB for data persistence
- **Communication**: Integrated notification systems

## Features

### 🔐 Authentication & Security
- Role-based access control (Officer authentication)
- Device binding with OTP verification
- Secure storage using Flutter Secure Storage
- Biometric authentication support
- Screen protection to prevent unauthorized access

### 🚁 Drone Management
- Real-time drone tracking and monitoring
- Live location updates via WebSocket
- Drone status monitoring (battery, altitude, speed)
- Interactive map integration with Flutter Map
- Custom markers for officers and drones

### 📍 Location Services
- GPS tracking with Geolocator
- Real-time location sharing
- Altitude and heading information
- Location history and analytics

### 📷 Camera & Media
- Camera access for evidence collection
- Image picker for gallery access
- Photo capture and storage
- Media upload to backend server

### 📊 Reporting & Analytics
- Incident reporting with PDF generation
- File upload capabilities
- Report storage and retrieval
- Analytics dashboard

### 🔄 Real-time Communication
- WebSocket-based real-time updates
- Live status monitoring
- Push notifications via SMS
- Cross-device synchronization

## Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.9.2+
- **State Management**: Provider pattern
- **UI Components**: Material Design, Glass Kit, Flutter Animate
- **Maps**: Flutter Map with LatLong2
- **Storage**: Shared Preferences, Secure Storage
- **Networking**: HTTP client, WebSocket Channel

### Backend (Python)
- **Framework**: FastAPI
- **Database**: MongoDB with Motor (async driver)
- **Real-time**: WebSocket support
- **File Handling**: ReportLab for PDF generation
- **Communication**: Twilio for SMS
- **Environment**: Python 3.8+

### AI/ML
- **Models**: YOLOv8 (Object Detection & Pose Estimation)
- **Framework**: PyTorch/Ultralytics

## Installation

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Python 3.8+
- MongoDB
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd sanjeevani_backend
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Set up environment variables:
   Create a `.env` file with:
   ```
   MONGODB_URL=mongodb://localhost:27017/sanjeevani
   TWILIO_ACCOUNT_SID=your_twilio_sid
   TWILIO_AUTH_TOKEN=your_twilio_token
   TWILIO_PHONE_NUMBER=your_twilio_number
   ```

4. Start MongoDB service

5. Run the backend server:
   ```bash
   python main.py
   ```

### Mobile App Setup

1. Navigate to the Flutter project:
   ```bash
   cd sanjeevani_hub
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Configure API endpoints:
   Update `lib/core/config/api_config.dart` with your backend URL

4. Run the app:
   ```bash
   flutter run
   ```

   For Android specifically:
   ```bash
   flutter run --flavor android
   ```

## Android-Specific Setup

### Build Configuration
- **Min SDK Version**: API 21 (Android 5.0)
- **Target SDK Version**: API 34 (Android 14)
- **Permissions**: Camera, Location, Storage, Phone State

### Required Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

### Build APK
```bash
flutter build apk --release
```

### Build App Bundle (AAB)
```bash
flutter build appbundle --release
```

## Usage

### First Launch
1. Select officer role
2. Complete registration process
3. Wait for admin approval
4. Bind device with OTP verification
5. Set up PIN for quick access

### Main Features
- **Dashboard**: View active drones and officers on map
- **Reports**: Create and view incident reports
- **Camera**: Capture evidence photos
- **Settings**: Configure app preferences

## API Documentation

The backend provides RESTful APIs and WebSocket endpoints:

### REST Endpoints
- `POST /register-officer` - Officer registration
- `POST /check-device` - Device verification
- `POST /upload-report` - File upload
- `GET /reports` - Retrieve reports

### WebSocket Endpoints
- `/ws/drone/{drone_id}` - Drone location updates
- `/ws/officer/{officer_id}` - Officer status updates

## Project Structure

```
sanjeevani_hub/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── auth/                     # Authentication screens
│   ├── core/                     # Core utilities and config
│   ├── officer/                  # Officer dashboard and features
│   └── services/                 # API services and utilities
├── android/                      # Android-specific configuration
├── assets/                       # Static assets
└── test/                        # Unit tests

sanjeevani_backend/
├── main.py                      # FastAPI application
├── requirements.txt             # Python dependencies
├── static/                      # Static web files
└── __pycache__/                 # Python cache
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Flutter/Dart best practices
- Use `flutter format` for code formatting
- Run `flutter analyze` before committing
- Write unit tests for new features

## Testing

### Backend Tests
```bash
cd trinetra_backend
python -m pytest
```

### Flutter Tests
```bash
cd trinetra
flutter test
```

## Deployment

### Backend Deployment
- Use Docker for containerization
- Deploy to cloud platforms (AWS, GCP, Azure)
- Set up MongoDB Atlas for production database

### Mobile App Deployment
- **Android**: Publish to Google Play Store
- **iOS**: Publish to App Store

## Security Considerations

- All sensitive data encrypted in transit and at rest
- JWT tokens for API authentication
- Device binding prevents unauthorized access
- Regular security audits recommended

## License

This project is proprietary software. All rights reserved.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation for common solutions

## Changelog

### Version 1.0.0
- Initial release
- Basic officer authentication
- Drone tracking functionality
- Incident reporting
- Real-time updates via WebSocket