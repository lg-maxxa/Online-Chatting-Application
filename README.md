# NexusChat – Professional Social Media Platform

A full-featured **WhatsApp-style** social media application with real-time messaging, media sharing, and a professional mobile UI. Built as part of the GitHub Student Developer Pack.

---

## ✨ Features

- 🔐 **JWT Authentication** – secure register & login with bcrypt password hashing
- 💬 **Real-time Messaging** – Socket.io for instant delivery, typing indicators, and read receipts
- 📸 **Media Sharing** – send images, videos, audio, and files (stored on **AWS S3**)
- 👥 **Group Chats** – create group conversations with admin controls
- 🟢 **Presence Indicators** – online/offline status & last seen timestamps
- 🔔 **Push Notifications** – local notification support (Firebase-ready)
- 🌙 **Dark Mode** – full light and dark theme support
- 🎨 **Icons8 UI** – professional icons via Icons8 Fluent/Material packs

---

## 🏗️ Architecture

```
Mobile APK (Flutter)
       │
       ▼
Azure App Service  ◄──►  MongoDB Atlas
  (Node.js API)              (Database)
       │
       ▼
    AWS S3
  (Media Files)
```

### Tech Stack

| Layer          | Technology                        |
|----------------|-----------------------------------|
| Mobile APK     | Flutter 3.22 (Dart)               |
| Backend API    | Node.js 20 + Express 4            |
| Real-time      | Socket.io 4                       |
| Database       | MongoDB Atlas (GitHub Student Pack) |
| Media Storage  | AWS S3                            |
| Cloud Hosting  | Azure App Service                 |
| Auth           | JWT + bcryptjs                    |
| UI Icons       | Icons8 (Fluent / Material)        |

---

## 📁 Project Structure

```
.
├── nexus-backend/         # Node.js/Express API server
│   ├── server.js          # Main entry point
│   ├── models/            # Mongoose schemas (User, Chat, Message)
│   ├── routes/            # REST API routes (auth, users, chats, messages)
│   ├── middleware/        # JWT auth middleware
│   ├── config/            # DB connection & AWS S3 setup
│   ├── __tests__/         # Jest + Supertest tests
│   └── .env.example       # Environment variable template
│
├── nexus-frontend/        # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart      # App entry point & routing
│   │   ├── models/        # Dart data models
│   │   ├── screens/       # Login, Register, Home, Chat, Profile
│   │   ├── services/      # API, Auth, Socket.io services
│   │   ├── widgets/       # ChatBubble, ContactTile components
│   │   └── utils/         # Theme & Constants
│   ├── android/           # Android build configuration
│   ├── test/              # Flutter unit tests
│   └── pubspec.yaml       # Flutter dependencies
│
├── .github/workflows/     # CI/CD (tests + APK build + Azure deploy)
├── DEPLOYMENT.md          # Full deployment guide
└── README.md
```

---

## 🚀 Quick Start

### Backend

```bash
cd nexus-backend
cp .env.example .env          # Fill in your credentials
npm install
npm run dev                   # Starts on http://localhost:5000
```

### Frontend

```bash
cd nexus-frontend
flutter pub get
# Update lib/utils/constants.dart with your backend URL
flutter run                   # Run on connected device / emulator
flutter build apk --release   # Build release APK
```

---

## 🧪 Running Tests

```bash
# Backend tests
cd nexus-backend && npm test

# Frontend tests
cd nexus-frontend && flutter test
```

---

## ☁️ Deployment

See **[DEPLOYMENT.md](DEPLOYMENT.md)** for full instructions covering:
- MongoDB Atlas cluster setup (GitHub Student Pack)
- AWS S3 bucket creation and IAM configuration
- Azure App Service deployment
- Release APK signing and build
- Icons8 integration

---

## 🔐 Security Notes

- All passwords are hashed with **bcrypt** (salt rounds = 12)
- Rate limiting is applied to all auth endpoints (10 req/15 min)
- JWT tokens expire after **7 days** by default
- All file uploads are validated for MIME type and size (max 25 MB)
- HTTPS is enforced in production (`usesCleartextTraffic="false"`)
- Never commit the `.env` file — use Azure App Service application settings

---

## 📜 License

MIT License. See LICENSE for details.
