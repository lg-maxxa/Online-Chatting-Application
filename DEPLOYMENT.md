# NexusChat – Deployment Guide

This guide covers the full deployment of the NexusChat backend to **Azure App Service**
and the storage layer to **AWS S3**, using your GitHub Student Developer Pack.

---

## 1. MongoDB Atlas Setup (GitHub Student Pack)

1. Go to [MongoDB Atlas](https://www.mongodb.com/students) and redeem your Student Pack offer.
2. Create a **free M0 cluster** (or Shared cluster with your Student credits).
3. Under **Database Access**, create a user with `readWriteAnyDatabase` role.
4. Under **Network Access**, add `0.0.0.0/0` (all IPs, required for Azure) **or** add only your Azure App Service outbound IPs for security.
5. Click **Connect → Connect your application** and copy the `Connection String`.
   It will look like:
   ```
   mongodb+srv://<user>:<password>@cluster0.xxxxx.mongodb.net/nexuschat?retryWrites=true&w=majority
   ```
6. Paste this string as `MONGO_URI` in your Azure App Service **Application Settings**.

---

## 2. AWS S3 Setup (Media Storage)

### 2.1 Create an S3 Bucket

```bash
aws s3api create-bucket --bucket nexuschat-media --region us-east-1
```

### 2.2 Set CORS on the bucket

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag"]
  }
]
```

### 2.3 Create an IAM user

1. Go to **IAM → Users → Add users**.
2. Attach the policy `AmazonS3FullAccess` (or a scoped custom policy for the bucket only).
3. Download the **Access Key ID** and **Secret Access Key**.
4. Add them to your Azure App Service **Application Settings** as:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` = `us-east-1`
   - `AWS_S3_BUCKET_NAME` = `nexuschat-media`

---

## 3. Azure App Service Deployment

### 3.1 Create the App Service

```bash
# Login
az login

# Create a resource group
az group create --name nexuschat-rg --location eastus

# Create an App Service Plan (free tier)
az appservice plan create \
  --name nexuschat-plan \
  --resource-group nexuschat-rg \
  --sku F1 \
  --is-linux

# Create the Web App (Node.js 18)
az webapp create \
  --name nexuschat-api \
  --resource-group nexuschat-rg \
  --plan nexuschat-plan \
  --runtime "NODE:18-lts"
```

### 3.2 Configure Environment Variables on Azure

```bash
az webapp config appsettings set \
  --name nexuschat-api \
  --resource-group nexuschat-rg \
  --settings \
    NODE_ENV=production \
    PORT=8080 \
    JWT_SECRET="<your_secret>" \
    JWT_EXPIRES_IN=7d \
    MONGO_URI="<your_atlas_uri>" \
    AWS_ACCESS_KEY_ID="<key>" \
    AWS_SECRET_ACCESS_KEY="<secret>" \
    AWS_REGION="us-east-1" \
    AWS_S3_BUCKET_NAME="nexuschat-media" \
    WEBSITE_NODE_DEFAULT_VERSION="~18"
```

### 3.3 Deploy via GitHub Actions (CI/CD)

The repository includes a workflow at `.github/workflows/deploy-backend.yml`.
Push to `main` to trigger auto-deployment.

Alternatively, deploy manually:

```bash
cd nexus-backend
zip -r ../deploy.zip . --exclude "node_modules/*" ".env"
az webapp deployment source config-zip \
  --name nexuschat-api \
  --resource-group nexuschat-rg \
  --src ../deploy.zip
```

### 3.4 Update the Flutter Frontend

After deployment, update `nexus-frontend/lib/utils/constants.dart`:

```dart
static const String baseUrl    = 'https://nexuschat-api.azurewebsites.net/api';
static const String socketUrl  = 'https://nexuschat-api.azurewebsites.net';
```

---

## 4. Building the APK

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.22
- Android SDK + Android Studio (or `sdkmanager`)
- Java 17+

### Steps

```bash
cd nexus-frontend

# Get packages
flutter pub get

# (Optional) Run tests
flutter test

# Build release APK
flutter build apk --release

# APK location
# build/app/outputs/flutter-apk/app-release.apk
```

### Signing for Play Store (Optional)

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore nexuschat.jks \
     -alias nexuschat -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Create `nexus-frontend/android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=nexuschat
   storeFile=../nexuschat.jks
   ```
3. Update `android/app/build.gradle` to use `signingConfigs.release`.
4. Run `flutter build apk --release` again.

---

## 5. Icons8 Integration

Icons8 provides high-quality SVG/PNG icons. To use them:

1. Go to [icons8.com](https://icons8.com) and download the **Fluent** or **Material** pack.
2. Place SVG files in `nexus-frontend/assets/icons/`.
3. Reference them in Flutter:
   ```dart
   import 'package:flutter_svg/flutter_svg.dart';
   SvgPicture.asset('assets/icons/chat.svg', width: 24, height: 24);
   ```

---

## 6. Production Checklist

- [ ] Replace `JWT_SECRET` with a cryptographically strong random string (≥ 32 chars)
- [ ] Restrict MongoDB Atlas Network Access to Azure App Service IPs only
- [ ] Enable Azure App Service **HTTPS Only** setting
- [ ] Create a scoped AWS IAM policy (instead of `AmazonS3FullAccess`)
- [ ] Sign the APK with a release keystore before distributing
- [ ] Enable Azure **Application Insights** for monitoring
- [ ] Set up **Azure Redis Cache** for Socket.io scaling (required for multiple instances)
