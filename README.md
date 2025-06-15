# SMS Ledger - Flutter Transaction Tracker

A Flutter app that automatically parses SMS messages from banks to track your income and expenses.

<!-- Build trigger: Updated with Android 13+ permission fixes -->

[![Build Flutter APK](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/actions/workflows/build-apk.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/actions/workflows/build-apk.yml)

## 🚀 **Quick Start - Get Your APK**

### **Option 1: Download from GitHub Releases (Recommended)**
1. Go to the [Releases page](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/releases)
2. Download the latest `app-release.apk`
3. Install on your Android device

### **Option 2: Build with GitHub Actions**
1. **Fork this repository**
2. **Push any change** to trigger the build
3. **Go to Actions tab** in your GitHub repo
4. **Download the APK** from the build artifacts

## Features

### 🏠 App Structure
- **Bottom Navigation Bar** with two tabs:
  - **Ledger** (default) - View your transactions
  - **Settings** - Configure app preferences

### 💰 Ledger Screen
- **Toggle Switch** to switch between:
  - **Expenses** (default) - Shows debit transactions in red
  - **Income** - Shows credit transactions in green
- **Transaction List** showing:
  - Sender name (e.g., HDFCBK, ICICIBK)
  - Transaction date (dd MMM yyyy format)
  - Amount with proper formatting (-₹100 for debits, +₹100 for credits)
  - Bank logo (circular icon on the right)
  - Total summary at the top
- **Pull to Refresh** to reload transactions
- **Last 30 days** of transactions by default

### ⚙️ Settings Screen
- **Transaction History Range** configuration:
  - Last 30 Days (default)
  - Last 3 Months
  - Last 6 Months
  - Custom Days (user-defined)
- Settings are saved using SharedPreferences

### 🏦 Bank Logo Support
The app includes support for major Indian banks:
- HDFC Bank
- ICICI Bank
- SBI (State Bank of India)
- Axis Bank
- Default logo for other banks

## 🔧 **GitHub Actions Build Setup**

This repository includes automated APK building using GitHub Actions. Here's how it works:

### **Automatic Builds**
- ✅ **Triggers on:** Push to main/master branch, Pull Requests, Manual trigger
- ✅ **Flutter Version:** 3.24.0 (stable version that works)
- ✅ **Output:** Release APK ready for installation
- ✅ **Artifacts:** APK available for download from Actions tab
- ✅ **Releases:** Automatic GitHub releases with APK attached

### **Manual Build Trigger**
1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Build Flutter APK** workflow
4. Click **Run workflow** button
5. Wait for build to complete (~5-10 minutes)
6. Download APK from **Artifacts** section

### **Build Status**
- ✅ **Java 17** setup
- ✅ **Flutter 3.24.0** (compatible version)
- ✅ **Dependencies** installation
- ✅ **Code analysis**
- ✅ **Tests** execution
- ✅ **APK** generation
- ✅ **Artifact** upload
- ✅ **Release** creation

## 📱 **Installation Instructions**

### **Android Device Setup**
1. **Download** the APK from GitHub Releases
2. **Enable** "Install from unknown sources":
   - Go to **Settings > Security**
   - Enable **Unknown Sources** or **Install unknown apps**
3. **Install** the APK file
4. **Grant SMS permissions** when prompted

### **Permissions Required**
- `READ_SMS` - To read SMS messages
- `RECEIVE_SMS` - To receive new SMS messages

### **⚠️ Important: Android 13+ Permission Issue**

If you see "App was denied access" or "Access to this permission can put your personal and financial info at risk", this is Android's **Restricted Settings** protection.

**Quick Fix:**
1. Open **Settings → Apps → SMS Ledger**
2. Tap **More** (three dots) → **Allow restricted settings**
3. Follow instructions and grant SMS permission

**📖 For detailed help, see:** [ANDROID_PERMISSIONS_GUIDE.md](ANDROID_PERMISSIONS_GUIDE.md)

**✅ Safe to use:** The app only reads transaction SMS locally on your device. No data is sent anywhere.

## 🛠️ **Development Setup**

### **Prerequisites**
- Flutter SDK (3.24.0 or compatible)
- Android Studio or VS Code with Flutter extensions
- Android device or emulator for testing

### **Local Development**
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME

# Get dependencies
flutter pub get

# Run the app
flutter run

# Build APK locally
flutter build apk --release
```

### **Bank Logo Setup**
Replace the placeholder files in `assets/bank_logos/` with actual PNG images:
- `hdfc.png` - HDFC Bank logo
- `icici.png` - ICICI Bank logo
- `sbi.png` - SBI logo
- `axis.png` - Axis Bank logo
- `default.png` - Default bank logo

Then uncomment the image loading code in `lib/widgets/transaction_item.dart`.

## 📁 **Project Structure**
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── transaction.dart      # Transaction data model
├── services/
│   └── sms_service.dart      # SMS reading and parsing
├── screens/
│   ├── ledger_screen.dart    # Main transaction list
│   └── settings_screen.dart  # App settings
└── widgets/
    └── transaction_item.dart # Individual transaction display

assets/
└── bank_logos/              # Bank logo images
    ├── hdfc.png
    ├── icici.png
    ├── sbi.png
    ├── axis.png
    └── default.png

.github/
└── workflows/
    └── build-apk.yml        # GitHub Actions workflow
```

## 🔍 **How It Works**

### **SMS Parsing Logic**
The app scans SMS messages for transaction keywords:

**Debit Keywords:** debited, withdrawn, spent, paid, debit, purchase, transaction, charged
**Credit Keywords:** credited, received, deposited, credit, refund, cashback, salary, transfer

### **Amount Extraction**
Uses multiple regex patterns to extract amounts:
- `Rs. 100`, `INR 100`, `₹100`
- `Amount: Rs. 100`
- Various formats with commas and decimals

### **Transaction Detection**
Only processes SMS messages that:
1. Contain transaction keywords
2. Have extractable amount values
3. Are within the configured date range
4. Come from recognized sender patterns

## 📊 **Dependencies**
- `telephony: ^0.2.0` - SMS reading functionality
- `permission_handler: ^11.0.1` - Runtime permissions
- `shared_preferences: ^2.2.2` - Settings storage
- `intl: ^0.18.1` - Date formatting

## 🧪 **Testing**
The app includes sample transaction data for testing when SMS permission is not granted or no transaction SMS are found.

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## 🔒 **Privacy & Security**
- Only transaction-related SMS messages are processed
- No personal messages are accessed
- All data stays on the device
- No network requests or data sharing

## 🐛 **Troubleshooting**

### **No Transactions Showing**
1. Grant SMS permission when prompted
2. Ensure you have transaction SMS in your inbox
3. Check if SMS are from the configured date range
4. Verify SMS contain recognized transaction keywords

### **GitHub Actions Build Fails**
1. Check the Actions tab for error details
2. Ensure all files are committed and pushed
3. Verify the workflow file syntax
4. Check if Flutter version is compatible

### **APK Installation Issues**
1. Enable "Install from unknown sources"
2. Check Android version compatibility (API 21+)
3. Ensure sufficient storage space
4. Try downloading APK again

## 🤝 **Contributing**
Feel free to add support for more banks by updating the `getBankLogo` method in `transaction.dart` and adding corresponding logo files.

## 📄 **License**
This project is for educational purposes. Make sure to comply with local regulations regarding SMS access and financial data processing.

---

## 🎯 **Quick Actions**

- 📥 **[Download Latest APK](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/releases/latest)**
- 🔧 **[View Build Status](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/actions)**
- 🐛 **[Report Issues](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/issues)**
- 🍴 **[Fork Repository](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/fork)**

**Replace `YOUR_USERNAME/YOUR_REPO_NAME` with your actual GitHub repository details.** 