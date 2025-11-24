# Nepali Date Mac Menu Bar

<div align="center">

![License](https://img.shields.io/badge/license-GPL%20v3-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![Version](https://img.shields.io/badge/version-0.0.1-green.svg)

**A beautiful, minimal macOS menu bar application that displays Nepali (Bikram Sambat) dates with seamless Calendar integration.**

[Download](#download) • [Features](#features) • [Setup](#setup-guide)

</div>

---

## Screenshots

<div align="center">
<table>
<tr>
<td width="50%">
<img src="doc/screenshots/monthly_view.png" alt="Monthly Calendar View" width="100%"/>
<p><em>Monthly calendar with Nepali dates and event indicators</em></p>
</td>
<td width="50%">
<img src="doc/screenshots/list_view.png" alt="Schedule List View" width="100%"/>
<p><em>Timeline view showing upcoming events</em></p>
</td>
</tr>
</table>
</div>

---

## Features

- **Dual Calendar System** - Bikram Sambat (BS) and Gregorian calendar support (2000-2100 BS)
- **Multi-Language** - English and Nepali (नेपाली) with proper numerals
- **Multiple Views** - Monthly grid and schedule timeline modes
- **Customizable Formats** - Short, long, and full date display options
- **Calendar Integration** - View macOS Calendar events in Nepali dates
- **System Integration** - Menu bar app with launch on login
- **Privacy-Focused** - All conversions local, no internet required

---

## Download

### Latest Release (v0.0.1)

**Direct Download:**

[Latest Release](https://github.com/yourusername/NepaliDaateMenuBar/releases/latest) - Download the `.dmg` file

**System Requirements:**
- macOS 12.0 (Monterey) or later
- **Universal Binary** - Works on both Apple Silicon (M1/M2/M3) and Intel Macs
- ~10 MB disk space

**Important**: This app is unsigned and not notarized. You'll need to bypass Gatekeeper on first launch (see installation instructions below).

---

## Setup Guide

### Installation

1. **Download** the latest `.dmg` file from [Releases](https://github.com/yourusername/NepaliDaateMenuBar/releases/latest)

2. **Open** the downloaded DMG file

3. **Drag** the app to your Applications folder

4. **Bypass Gatekeeper** (Required - app is not notarized):
   
   **For ALL warnings** (damaged, malware, unidentified developer):
   
   Open **Terminal** and run this command:
   ```bash
   xattr -cr "/Applications/NepaliDateMacMenuBar.app"
   ```
   
   Then double-click the app to open normally.
   
   **What this does:**
   - Removes the quarantine attribute macOS adds to downloaded apps
   - Allows the unsigned app to run
   - Only needs to be done once
   
   **Alternative method (if Terminal method doesn't work):**
   ```bash
   sudo spctl --master-disable
   # Open the app
   sudo spctl --master-enable
   ```
   ⚠️ This temporarily disables Gatekeeper system-wide. Re-enable it immediately after opening the app.

5. **Grant Permissions** (Optional):
   - Calendar access will be requested on first launch
   - This allows viewing your events alongside Nepali dates
   - You can grant or deny - the app works either way

> **Note**: This app is not signed with an Apple Developer certificate. macOS will show a security warning on first launch. This is normal for non-notarized apps. Use the methods above to bypass Gatekeeper.

### First-Time Setup

The app will guide you through an onboarding process:

1. **Select Language** - Choose between English or Nepali (नेपाली)
2. **Choose Display Format** - Pick how dates appear in your menu bar
3. **Calendar Access** - Decide whether to integrate with macOS Calendar
4. **Launch Preferences** - Set whether to start on login

### Menu Bar Controls

Once installed, you'll see the Nepali date in your menu bar:

- **Click** the menu bar icon to open the calendar popover
- **Select** between Month or Schedule view
- **Click** any date to see events for that day
- **Navigate** months using arrow buttons or "Today" to return

### Settings

Access settings by:
1. Click the menu bar icon
2. Right-click on the app (or access via menu)
3. Adjust:
   - Language preference
   - Date format
   - Launch on login
   - Calendar permissions



## Release Process

This project uses **automated releases** with semantic versioning based on commit messages.

### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature (bumps minor version: 0.0.1 → 0.1.0)
- `fix:` - Bug fix (bumps patch version: 0.0.1 → 0.0.2)
- `ci:` - Rebuild without version bump (creates v0.0.1-latest)
- `feat!:` or `BREAKING CHANGE:` - Breaking change (bumps major: 0.0.1 → 1.0.0)
- `docs:`, `chore:`, etc. - No build or release

### What Happens on Merge to Main

GitHub Actions automatically:
1. Determines version from commit messages
2. Updates `Info.plist`
3. Builds the app
4. Creates DMG installer
5. Generates changelog
6. Creates GitHub release

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## FAQ

### Why does macOS say the app is "damaged" or "contains malware"?

The app is **not** actually damaged or malicious. macOS shows these warnings for ANY unsigned app. Since this app is not signed with an Apple Developer certificate (costs $99/year), macOS blocks it with scary warnings.

**Quick fix - Remove quarantine:**
```bash
xattr -cr "/Applications/NepaliDateMacMenuBar.app"
```

This removes the quarantine flag and allows the app to run.

### Why does macOS block the app?

This app is not signed or notarized with an Apple Developer certificate (which costs $99/year). macOS Gatekeeper blocks unsigned apps by default for security.

### Is it safe to bypass Gatekeeper?

Yes, if you trust the source. This is open-source software - you can review the code yourself. The app:
- Doesn't require internet access
- Only accesses your Calendar if you grant permission
- Performs all date conversions locally
- Doesn't collect or send any data

### Do I need to bypass Gatekeeper every time?

No, only on the first launch. After running `xattr -cr` or using the right-click method once, macOS remembers your choice.

### Can I build it myself instead?

Yes! Clone the repository and build with Xcode:
```bash
git clone https://github.com/yourusername/NepaliDaateMenuBar.git
cd NepaliDaateMenuBar
open NepaliDateMacMenuBar.xcodeproj
# Press Cmd+R to build and run
```

---

## License

Licensed under **GNU General Public License v3.0** - see [LICENSE](LICENSE) file for details.

---

## Support

- **Bug Reports**: [Open an issue](https://github.com/yourusername/NepaliDaateMenuBar/issues)
- **Feature Requests**: [Request features](https://github.com/yourusername/NepaliDaateMenuBar/issues)

---

## Acknowledgments

**[pyBSDate](https://github.com/SushilShrestha/pyBSDate)** by Sushil Shrestha - Date conversion algorithm (MIT License)

---

<div align="center">

**Made with love for the Nepali community worldwide**

[Back to Top](#nepali-date-mac-menu-bar)

</div>

