# App Store Release & Transporter Guide

This document details the configuration, build steps, and solutions for App Store Transporter submission for **SAT Prep Bytes**.

---

## 1. Transporter Submission Errors & Resolutions

During Transporter upload, Apple enforces strict validation rules regarding icon assets, `Info.plist` entries, and versioning trains:

| Error Code | Error Message Summary | Root Cause | Resolution |
| :--- | :--- | :--- | :--- |
| **90022** | `Missing required icon file ... 120x120 pixels` | Missing iPhone `@2x` 60pt icon in bundle | Created `icon_120x120.png` in `AppIcon.appiconset` |
| **90023** | `Missing required icon file ... 152x152 pixels` | Missing iPad `@2x` 76pt icon in bundle | Created `icon_152x152.png` in `AppIcon.appiconset` |
| **90713** | `Missing Info.plist value ... CFBundleIconName` | Missing `CFBundleIconName` key in `Info.plist` | Set `INFOPLIST_KEY_CFBundleIconName = AppIcon` in `project.pbxproj` |
| **90062** | `CFBundleShortVersionString [1.0.6] must contain a higher version than approved [1.0.6]` | Uploading against an already closed version train | Bumped `MARKETING_VERSION` to `1.6` in project settings |
| **90186** | `Invalid Pre-Release Train ... version '1.0.6' is closed` | Version `1.0.6` closed in App Store Connect | Matched project `MARKETING_VERSION` (`1.6`) to active release train |

---

## 2. App Icon & Asset Catalog Architecture

App Icon assets are organized in `SAT Prep/Assets.xcassets/AppIcon.appiconset`:

- `icon_1024x1024.png` (App Store Marketing - 1024x1024)
- `icon_180x180.png` (iPhone 60pt @3x)
- `icon_120x120.png` (iPhone 60pt @2x - **Required for Error 90022**)
- `icon_167x167.png` (iPad Pro 83.5pt @2x)
- `icon_152x152.png` (iPad 76pt @2x - **Required for Error 90023**)
- `icon_76x76.png` (iPad 76pt @1x)
- `icon_87x87.png` / `icon_58x58.png` / `icon_29x29.png` (Settings)
- `icon_80x80.png` / `icon_40x40.png` (Spotlight)
- `icon_60x60.png` / `icon_20x20.png` (Notifications)

### Required Build Settings in `project.pbxproj`:
```text
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
INFOPLIST_KEY_CFBundleIconName = AppIcon;
MARKETING_VERSION = 1.6;
CURRENT_PROJECT_VERSION = 8;
```

---

## 3. How to Build, Archive, Export & Upload

### Step 1: Create Xcode Archive
Run from project root directory:
```bash
xcodebuild -project "SAT Prep.xcodeproj" \
           -scheme "SAT Prep" \
           -configuration Release \
           -archivePath "build/SATPrep.xcarchive" archive
```

### Step 2: Register Archive in Xcode Organizer (Optional)
To make the archive visible in Xcode's **Organizer** window (`Window > Organizer`):
```bash
mkdir -p "$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)"
cp -R "build/SATPrep.xcarchive" "$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/SAT Prep 1.6 (Build 8).xcarchive"
```

### Step 3: Export Signed App Store `.ipa`
Export using `ExportOptions.plist`:
```bash
xcodebuild -exportArchive \
           -archivePath "build/SATPrep.xcarchive" \
           -exportPath "build/export" \
           -exportOptionsPlist ExportOptions.plist \
           -allowProvisioningUpdates
```

### Step 4: Upload via Transporter
Pre-load the exported `.ipa` directly into Transporter:
```bash
open -a Transporter "build/export/SAT Prep.ipa"
```
Or upload via Xcode Organizer: **Window > Organizer > Select Archive > Distribute App**.

---

## 4. Developer Testing & Inspection Menu

To inspect questions, correct answer indices, and detailed question metadata directly in-app:

1. Launch **SAT Prep Bytes** on device/simulator.
2. Navigate to **Progress** tab (bar chart icon).
3. Tap **✨ Sparkles** icon (top-right navigation bar).
4. Scroll to bottom and select **🛠 Developer Testing Menu**.
5. Use **Search Question Bank / Inspector** to lookup by question text or ID (e.g. `basketball` or `28e2673a`).
