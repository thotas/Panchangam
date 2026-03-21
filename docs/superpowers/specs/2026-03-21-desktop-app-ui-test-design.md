# Desktop App UI Test Suite Design

## Overview

Two independent test scripts that validate the macOS desktop app (`PanchangApp`) by:
1. Opening the app and navigating dates/locations/schools
2. Comparing displayed values (tithi, nakshatram, etc.) against CLI output and independent engine calculations
3. Taking screenshots and verifying UI text matches expected values

---

## Test Matrix

**105 total combinations:**
- 7 dates × 5 locations × 3 schools

### Date Selections

| Label | Selection Logic |
|-------|-----------------|
| Current | `datetime.today()` |
| Future 1 | Today + 1 year + 7 days |
| Future 2 | Today + 2 years + 14 days |
| Future 3 | Today + 3 years + 30 days |
| Past 1 | Today - 3 years |
| Past 2 | Today - 4 years |
| Past 3 | Today - 5 years |

### Locations

- Hyderabad
- Dublin, California, USA
- Houston, Texas, USA
- New Jersey, USA
- Philadelphia, USA

### Schools

- Gantala
- Nemani
- TTD

---

## Script 1: Python + PyAutoGUI/SSOT

### Architecture

```
tests/
├── pyautogui_desktop_test.py      # Main test runner
├── panchang_verify.py              # Independent verification (CLI wrapper)
└── screenshots/                    # Captured screenshots per test case
```

### Dependencies

- `pyautoGUI` — UI automation and screenshot capture
- `subprocess` — CLI invocation
- `Pillow` — Image processing
- `pytesseract` (optional) — OCR for screenshot text extraction

### Verification Flow

1. Launch app via `open /Applications/PanchangApp.app`
2. Use DatePicker to select target date
3. Iterate all 5 locations × 3 schools
4. Screenshot results panel
5. Run `panchang` CLI with same params → get expected values
6. Compare screenshot text against expected values
7. Report pass/fail with screenshot diff

### Key Functions

- `launch_app()` — Opens PanchangApp
- `select_date(date)` — Navigates DatePicker
- `select_location(location)` — Selects from Location menu
- `select_school(school)` — Selects from School menu
- `capture_screenshot()` — Returns UI screenshot
- `get_cli_output(date, location, school)` — Returns expected values from CLI
- `verify_results()` — Compares UI vs CLI

---

## Script 2: Swift + XCTest

### Architecture

```
PanchangAppTests/
├── DesktopAppUITests.swift         # Main XCTest subclass
├── PankajamVerifier.swift          # CLI wrapper for verification
└── Assets/                         # Expected screenshots baseline
```

### Dependencies

- `XCTest` — Native macOS UI testing framework
- `XCUIApplication` — App launch and lifecycle
- `XCUIElement` — UI element queries

### Verification Flow

1. `XCUIApplication().launch()` — launch app
2. `datePicker.setDate()` — navigate to target date
3. `menuBarItem.click()` — change location/school
4. `XCUIScreen.main.screenshot()` — capture screenshot
5. Compare screenshot against CLI output
6. Report pass/fail

### Key Test Methods

- `test_currentDay_allLocationsSchools()` — Tests today × all combos
- `test_futureDates()` — Tests 3 future dates × all combos
- `test_pastDates()` — Tests 3 past dates × all combos
- `verifyAgainstCLI(date:location:school:)` — Cross-validates with CLI

---

## Verification Strategy

### CLI Wrapper (shared)

Both scripts use the same CLI verification:

```bash
./target/release/panchang --location <loc> --date <YYYY-MM-DD> --school <school> --format json
```

### Fields to Verify

- `panchangam.samvatsaram`
- `panchangam.ayanam`
- `panchangam.maasam`
- `panchangam.vaaram`
- `panchangam.tithi`
- `panchangam.nakshatram`
- `panchangam.next_tithi` (when present)
- `panchangam.next_nakshatram` (when present)

### Screenshot Verification

1. Capture screenshot of results panel
2. Extract visible text via OCR (Python) or native snapshot (Swift)
3. Compare extracted values against CLI JSON output
4. Store passing screenshots as baselines

---

## Output

- **Console output:** Pass/fail per combination with details
- **Screenshots:** Stored in `screenshots/` (Python) or `Assets/` (Swift)
- **JUnit-style XML:** For CI integration

---

## Success Criteria

- All 105 combinations tested for both scripts
- No false positives: UI showing wrong value should fail test
- Screenshots captured for all test cases
- CLI verification confirms engine calculation accuracy
