# PanchamApp UI Test Gaps - Initial Run

## Test Execution Summary

- **Test Script**: `/Users/thotas/Development/OpenCode/Panchangam/tests/pyautogui_desktop_test.py`
- **Date of Run**: 2026-03-21
- **Total Combinations**: 105 (7 dates x 5 locations x 3 schools)
- **Combinations Tested**: 69 (completed before crash/interruption)
- **Combinations Not Tested**: 36 (Past 2, Past 3 dates, and some Past 1)

## Test Environment

- **App Path**: `/Users/thotas/Development/OpenCode/Panchangam/PanchangApp/build/Release/PanchangApp.app`
- **CLI Path**: `/usr/local/bin/panchang`
- **OCR**: Tesseract 5.5.2 with pytesseract
- **Screenshots Captured**: 69 (in `/Users/thotas/Development/OpenCode/Panchangam/tests/screenshots/`)

## Identified Gaps

### 1. CLI Missing `next_tithi` and `next_nakshatram` Fields

**Type**: DATA_GAP
**Severity**: HIGH

The CLI output does NOT include `next_tithi` and `next_nakshatram` fields, but the UI displays them.

**CLI Output (Current Hyderabad Gantala)**:
```json
{
  "panchangam": {
    "samvatsaram": "Parabhava",
    "ayanam": "Uttarayanam",
    "maasam": "Chaitra",
    "vaaram": "Shanivaram (Saturday)",
    "tithi": "Tritiya until 02:07",
    "nakshatram": "Ashvini until 02:11"
  }
}
```

**UI OCR Extract (Current Hyderabad Gantala)**:
```
Samvatsaram: Parabhava
Ayanam: Uttarayanam
Maasam: Chaitra
Vaaram: Shanivaram
Tithi: Tritiya until 02:07
Next Tithi: Chaturthi until 22:14
Nakshatram: Ashvini until 02:11
Next Nakshatram: Bharani until 22:22
```

**Gap**: The CLI response lacks `next_tithi` and `next_nakshatram` which are displayed in the UI. This is a **verification gap** - the test cannot compare UI values against CLI for these fields.

---

### 2. UI Automation - Location Selection Not Working

**Type**: UI_AUTOMATION_GAP
**Severity**: HIGH

The pyautogui keyboard-based location selection is not reliably selecting the correct location.

**Evidence**:
- Past 1_Dublin_CA_Nemani.png shows "Hyderabad" instead of "Dublin CA"
- Past 1_Houston_TX_Nemani.png shows "Hyderabad" instead of "Houston TX"

**Root Cause**: The `select_location()` function uses keyboard shortcuts (first letter typing) to select from dropdown menus, but this approach is unreliable on macOS due to:
1. Focus issues with menu popovers
2. Keyboard shortcut conflicts
3. Timing issues between click and type

**Impact**: All location tests after "Current" date may have incorrect location values in the UI, making verification unreliable.

---

### 3. `vaaram` Field Missing Day Name in UI

**Type**: DATA_MISMATCH
**Severity**: LOW

The CLI returns `vaaram: "Shanivaram (Saturday)"` but the UI tile shows just `Vaaram: Shanivaram` (without the day name in parentheses).

**CLI**: `"vaaram": "Shanivaram (Saturday)"`
**UI**: `Vaaram: Shanivaram`

The test script's `compare_values()` function has a workaround (partial match), but this is technically a display inconsistency.

---

### 4. Test Crash/Incomplete - Past 2 and Past 3 Not Tested

**Type**: TEST_INFRASTRUCTURE_GAP
**Severity**: MEDIUM

The test script did not complete - it crashed or was interrupted after Past 1 (partial).

**Not Tested**:
- Past 1 (partially - only Dublin CA, Houston TX, Hyderabad completed)
- Past 2 (0 of 15 combinations)
- Past 3 (0 of 15 combinations)

**Likely Cause**: The date picker may have issues navigating to dates 4-5 years in the past, or the test script encountered an exception while handling UI interactions for old dates.

---

### 5. Screenshot Capture Includes Full Screen (Not Just App Window)

**Type**: UI_AUTOMATION_GAP
**Severity**: MEDIUM

The `screencapture` command captures the entire screen, not just the PanchamApp window. This causes OCR to pick up text from:
- Desktop icons
- Menu bar
- Other open applications
- Browser tabs (if open)

**Current Workaround**: The test filters OCR output for panchang-related keywords, but this is fragile.

**Recommendation**: Use `screencapture -l <window_id>` to capture just the app window, or use pyautogui's screenshot with window region.

---

### 6. UI Coordinate-Based Selection is Fragile

**Type**: UI_AUTOMATION_GAP
**Severity**: MEDIUM

The test uses hardcoded coordinates for UI elements:
- Location dropdown: (100, 110)
- Date picker: (100, 160)
- School dropdown: (100, 200)

These coordinates are based on estimated positions and may vary based on:
- Display resolution
- Retina scaling
- App window position

**Recommendation**: Use accessibility APIs (NSAccessibility) or image-based detection (pyautogui.locateOnScreen) for more robust UI element detection.

---

### 7. Missing `next_tithi` and `next_nakshatram` in CLI

**Type**: CLI_DATA_GAP
**Severity**: HIGH

As noted in Gap #1, the CLI does not return `next_tithi` and `next_nakshatram` data, but the UI does. This means:

1. **Verification cannot be complete** - We cannot verify these UI values against CLI
2. **Inconsistency** - The engine calculates this data (UI shows it) but CLI doesn't expose it

**Recommended Fix**: Add `next_tithi` and `next_nakshatram` to CLI output.

---

## Test Results Summary

| Metric | Value |
|--------|-------|
| Total Combinations | 105 |
| Tested | 69 |
| Passed | Unknown (no results JSON) |
| Failed | Unknown (no results JSON) |
| Gaps Identified | 7 major gaps |

## Recommendations

1. **Fix CLI to include `next_tithi` and `next_nakshatram`** - This is blocking complete verification
2. **Implement proper window-based screenshot capture** - Use window ID instead of full screen
3. **Improve location/school selection automation** - Use AppleScript or accessibility APIs instead of keyboard shortcuts
4. **Add better error handling and recovery** - Test should continue even if one combination fails
5. **Re-run test for incomplete date ranges** - Past 2 and Past 3 need testing

---

## Files Generated

- **Test Script**: `/Users/thotas/Development/OpenCode/Panchangam/tests/pyautogui_desktop_test.py`
- **Screenshots**: `/Users/thotas/Development/OpenCode/Panchangam/tests/screenshots/` (69 PNG files)
- **This Report**: `/Users/thotas/Development/OpenCode/Panchangam/tests/TEST_GAPS_INITIAL.md`
