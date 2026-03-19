# Panchanga - Hindu Calendar App

A native macOS application for calculating and displaying Hindu panchang (calendar) information including tithi, nakshatram, yoga, karana, and festivals.

## Features

- **Tithi & Nakshatram**: Display current lunar day and star with end times, plus next tithi/nakshatram shown inline when the current one ends before midnight
- **Multiple Locations**: Support for Hyderabad, Dublin CA, Houston TX, New Jersey, and Philadelphia
- **Three Schools**: Gantala, Nemani, and TTD tradition calculations
- **Festivals**: Comprehensive festival detection including Ekadashi, Diwali, Dussehra, Ganesh Chaturthi, Maha Shivaratri, Makara Sankranti, Bonalu, and more
- **Sunrise/Sunset**: Accurate solar times for your location
- **Muhurtams**: Varjyam, Durmuhurtam, and Rahukalam display
- **Dark Mode UI**: Beautiful dark theme inspired by modern macOS design

## Installation

### Option 1: Pre-built App
The compiled app is located at:
```
~/Applications/myApps/PanchangApp.app
```

### Option 2: Build from Source

#### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- Rust toolchain (for the panchang engine)

#### Build Steps

```bash
# Navigate to the app directory
cd PanchangApp

# Generate Xcode project
xcodegen generate

# Build the app
xcodebuild -scheme PanchangApp -configuration Release build

# The built app will be in:
# ~/Library/Developer/Xcode/DerivedData/PanchangApp-*/Build/Products/Release/PanchangApp.app
```

## Project Structure

```
Panchangam/
├── PanchangApp/           # macOS SwiftUI app
│   ├── Sources/
│   │   └── PanchangApp/
│   │       ├── PankajApp.swift       # Main app entry
│   │       ├── ContentView.swift     # Main UI
│   │       ├── ResultView.swift      # Results display
│   │       ├── PankajamEngineWrapper.swift  # FFI wrapper
│   │       └── Assets.xcassets/      # App icons
│   └── project.yml           # XcodeGen config
├── panchang-engine/         # Rust core engine
│   ├── src/                 # Rust source
│   ├── libpanchang_engine_universal.a  # Pre-built library
│   └── swisseph/            # Swiss Ephemeris
├── PanchangSpec.md          # Technical specification
└── README.md                # This file
```

## Engine Architecture

The application uses a two-layer architecture:

1. **Rust Core Engine** (`panchang-engine/`)
   - Uses Swiss Ephemeris for astronomical calculations
   - Supports Drik Siddhanta
   - Calculates Lahiri Ayanamsa
   - JSON output via FFI

2. **SwiftUI Frontend** (`PanchangApp/`)
   - Native macOS UI
   - Calls Rust engine via C FFI
   - Reactive UI with SwiftUI

## Supported Locations

| Location | Coordinates | Timezone |
|----------|-------------|----------|
| Hyderabad | 17.3850° N, 78.4867° E | Asia/Kolkata |
| Dublin, CA | 37.7022° N, 121.9358° W | America/Los_Angeles |
| Houston, TX | 29.7604° N, 95.3698° W | America/Chicago |
| New Jersey | 40.0583° N, 74.4057° W | America/New_York |
| Philadelphia | 39.9526° N, 75.1652° W | America/New_York |

## Schools/Traditions

- **Gantala**: Drik Siddhanta, Lahiri Ayanamsa, Udaya Vyapini Tithi logic
- **Nemani**: Drik Siddhanta, Lahiri Ayanamsa, optimized for USA timezones
- **TTD**: Tirumala Devasthanam standard

## Usage

1. Launch the app
2. Select a location from the dropdown
3. Choose a date
4. Select your preferred tradition (school)
5. View the panchang information

Keyboard shortcuts:
- `T` - Jump to today
- `Y` - Jump to yesterday
- `N` - Jump to tomorrow

## Development

### Requirements
- macOS 14.0+
- Xcode 15.0+
- Rust (for engine modifications)
- Python 3 (for icon generation)

### Rebuilding the Engine

If you modify the Rust engine:

```bash
cd panchang-engine
cargo build --release --target universal-apple-darwin
```

This generates `libpanchang_engine_universal.a` which the macOS app links against.

### Python Icon Generator

The app includes a Python script (`generate_icon.py`) that generates high-resolution app icons using PIL (Pillow). The icons follow an Apple News-inspired design with a deep purple/indigo gradient background, crescent moon, and stars.

To regenerate icons:
```bash
python3 generate_icon.py
```

This project is for educational and personal use. The Swiss Ephemeris has its own licensing terms.
