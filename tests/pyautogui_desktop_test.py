#!/usr/bin/env python3
"""
PanchangApp Desktop UI Test Suite

Tests the macOS desktop app (PanchangApp) by:
1. Opening the app and navigating dates/locations/schools
2. Comparing displayed values (tithi, nakshatram, etc.) against CLI output
3. Taking screenshots and verifying UI text matches expected values

Test Matrix: 105 combinations (7 dates x 5 locations x 3 schools)
"""

import json
import subprocess
import time
import os
import sys
import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, List, Any

import pyautogui
from PIL import Image

# Try to import pytesseract, but make OCR optional
try:
    import pytesseract
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False
    print("WARNING: pytesseract not available, OCR will be disabled")

# Constants
APP_PATHS = [
    "/Users/thotas/Development/OpenCode/Panchangam/PanchangApp/build/Release/PanchangApp.app",
    "/Users/thotas/Applications/myApps/PanchangApp.app",
    "/Applications/PanchangApp.app"
]
CLI_PATH = "/usr/local/bin/panchang"
SCREENSHOTS_DIR = "/Users/thotas/Development/OpenCode/Panchangam/tests/screenshots"
REPORT_PATH = "/Users/thotas/Development/OpenCode/Panchangam/tests/test_results.json"

# Find the first existing app path
APP_PATH = None
for path in APP_PATHS:
    if os.path.exists(path):
        APP_PATH = path
        break

if APP_PATH is None:
    print(f"ERROR: Could not find PanchamApp.app in any of: {APP_PATHS}")

# Location mapping: UI display name -> CLI location slug
LOCATION_MAP = {
    "Hyderabad": "hyderabad",
    "Dublin, California, USA": "dublin-ca",
    "Houston, Texas, USA": "houston-tx",
    "New Jersey, USA": "new-jersey",
    "Philadelphia, USA": "philadelphia"
}

# Location presets in the app (from LocationPreset enum)
LOCATION_PRESETS = ["Hyderabad", "Dublin CA", "Houston TX", "New Jersey", "Philadelphia"]

# School mapping: UI display name -> CLI school slug
SCHOOL_MAP = {
    "Gantala": "gantala",
    "Nemani": "nemani",
    "TTD": "ttd"
}

SCHOOL_PRESETS = ["Gantala", "Nemani", "TTD"]

# Fields to verify (from test design)
VERIFY_FIELDS = [
    "samvatsaram",
    "ayanam",
    "maasam",
    "vaaram",
    "tithi",
    "nakshatram",
    "next_tithi",
    "next_nakshatram"
]

# Test gaps discovered during execution
TEST_GAPS: List[Dict[str, Any]] = []


def add_gap(gap_type: str, description: str, details: Optional[Dict] = None):
    """Record a test gap."""
    gap = {
        "type": gap_type,
        "description": description,
        "timestamp": datetime.now().isoformat(),
        "details": details or {}
    }
    TEST_GAPS.append(gap)
    print(f"  [GAP-{len(TEST_GAPS)}] {gap_type}: {description}")


def get_test_dates() -> Dict[str, datetime]:
    """Generate the 7 test dates as specified in the test design."""
    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)

    dates = {
        "Current": today,
        "Future 1": today + timedelta(days=365 + 7),  # +1 year + 7 days
        "Future 2": today + timedelta(days=730 + 14),  # +2 years + 14 days
        "Future 3": today + timedelta(days=1095 + 30), # +3 years + 30 days
        "Past 1": today - timedelta(days=365 * 3),     # -3 years
        "Past 2": today - timedelta(days=365 * 4),     # -4 years
        "Past 3": today - timedelta(days=365 * 5),     # -5 years
    }

    return dates


def get_cli_output(date: datetime, location: str, school: str) -> Optional[dict]:
    """
    Get expected values from the panchang CLI.

    Args:
        date: The date to query
        location: Location name (e.g., "Hyderabad")
        school: School name (e.g., "Gantala")

    Returns:
        Dictionary with CLI output or None if error
    """
    cli_location = LOCATION_MAP.get(location, location.lower().replace(" ", "-"))
    cli_school = SCHOOL_MAP.get(school, school.lower())

    date_str = date.strftime("%Y-%m-%d")

    try:
        result = subprocess.run(
            [CLI_PATH, "--location", cli_location, "--date", date_str, "--school", cli_school, "--format", "json"],
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            return json.loads(result.stdout)
        else:
            add_gap("CLI_ERROR", f"CLI returned error: {result.stderr}", {
                "date": date_str,
                "location": location,
                "school": school,
                "stderr": result.stderr
            })
            return None
    except subprocess.TimeoutExpired:
        add_gap("CLI_TIMEOUT", f"CLI timed out for {date_str} {location} {school}", {
            "date": date_str,
            "location": location,
            "school": school
        })
        return None
    except Exception as e:
        add_gap("CLI_EXCEPTION", f"CLI exception: {e}", {
            "date": date_str,
            "location": location,
            "school": school,
            "exception": str(e)
        })
        return None


def launch_app() -> bool:
    """Launch the PanchamApp."""
    print("Launching PanchamApp...")

    # First, try to close any existing instances
    try:
        subprocess.run(["pkill", "-f", "PanchangApp"], timeout=5)
        time.sleep(1)
    except Exception:
        pass

    try:
        subprocess.run(["open", "-a", APP_PATH], timeout=10)
        # Wait for app to fully launch
        time.sleep(3)
        return True
    except Exception as e:
        add_gap("APP_LAUNCH_FAILED", f"Failed to launch app: {e}", {"app_path": APP_PATH})
        return False


def close_app():
    """Close the PanchamApp."""
    print("Closing PanchamApp...")
    try:
        subprocess.run(["pkill", "-f", "PanchangApp"], timeout=10)
        time.sleep(1)
    except Exception as e:
        add_gap("APP_CLOSE_FAILED", f"Failed to close app: {e}")


def capture_screenshot(test_name: str) -> Optional[Image.Image]:
    """
    Capture a screenshot using screencapture command.

    Args:
        test_name: Name for the screenshot file

    Returns:
        PIL Image or None
    """
    try:
        # Use screencapture command to capture the screen
        # This gives us the full screen
        screenshot_path = os.path.join(SCREENSHOTS_DIR, f"{test_name}.png")

        # Capture screen to file
        result = subprocess.run(
            ["screencapture", "-x", screenshot_path],
            capture_output=True,
            timeout=10
        )

        if result.returncode != 0:
            add_gap("SCREENSHOT_FAILED", f"screencapture failed: {result.stderr.decode()}", {
                "test_name": test_name,
                "returncode": result.returncode
            })
            return None

        # Load the image
        img = Image.open(screenshot_path)
        print(f"  Screenshot saved: {screenshot_path}")
        return img

    except Exception as e:
        add_gap("SCREENSHOT_EXCEPTION", f"Screenshot exception: {e}", {
            "test_name": test_name,
            "exception": str(e)
        })
        return None


def extract_text_from_screenshot(image: Image.Image) -> str:
    """
    Extract text from a screenshot using OCR.

    Args:
        image: PIL Image

    Returns:
        Extracted text string
    """
    if not OCR_AVAILABLE:
        return ""

    try:
        # Use tesseract to extract text
        text = pytesseract.image_to_string(image)
        return text
    except Exception as e:
        add_gap("OCR_EXCEPTION", f"OCR exception: {e}", {"exception": str(e)})
        return ""


def find_text_in_screenshot(image: Image.Image, search_text: str) -> bool:
    """
    Check if specific text is visible in the screenshot.

    Args:
        image: PIL Image
        search_text: Text to search for

    Returns:
        True if text is found
    """
    if OCR_AVAILABLE:
        extracted_text = extract_text_from_screenshot(image)
        return search_text.lower() in extracted_text.lower()

    # Fallback: use pytesseract to get searchable image
    return False


def compare_values(ui_text: str, cli_value: str, field_name: str) -> tuple:
    """
    Compare a UI extracted value against CLI expected value.

    Args:
        ui_text: Text extracted from UI
        cli_value: Expected value from CLI
        field_name: Name of the field being compared

    Returns:
        (passed: bool, details: str)
    """
    # Normalize both values for comparison
    ui_normalized = ui_text.lower().strip()
    cli_normalized = cli_value.lower().strip()

    if field_name == "vaaram":
        # Vaaram might have format "Shanivaram (Saturday)" or just "Shanivaram"
        if cli_normalized in ui_normalized or ui_normalized in cli_normalized:
            return True, f"Match (partial): UI='{ui_text}', CLI='{cli_value}'"
        else:
            return False, f"Mismatch: UI='{ui_text}', CLI='{cli_value}'"

    elif field_name in ["tithi", "nakshatram"]:
        # These might have " until HH:MM" appended
        ui_name = ui_text.split(" until ")[0].strip()
        cli_name = cli_value.split(" until ")[0].strip()

        if ui_name.lower() == cli_name.lower():
            return True, f"Match: {ui_name}"
        else:
            return False, f"Mismatch: UI='{ui_name}', CLI='{cli_name}'"

    else:
        # Direct comparison
        if ui_normalized == cli_normalized:
            return True, f"Match: '{ui_text}'"
        else:
            return False, f"Mismatch: UI='{ui_text}', CLI='{cli_value}'"


def try_activate_app():
    """Try to bring PanchamApp to foreground using AppleScript."""
    try:
        script = '''
        tell application "System Events"
            if exists (first process whose name is "PanchangApp") then
                set frontmost of (first process whose name is "PanchangApp") to true
                return "activated"
            end if
        end tell
        return "not found"
        '''
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=5
        )
        return "activated" in result.stdout
    except Exception as e:
        add_gap("APP_ACTIVATE_FAILED", f"Failed to activate app: {e}")
        return False


def click_on_app_menu(menu_label: str, item_label: str) -> bool:
    """
    Try to click on a menu item in the app using keyboard navigation.

    This is a fallback when direct UI automation isn't available.
    """
    try:
        # First try to click on the dropdown
        # Based on ContentView.swift, the controls panel is on the left
        # Location is at approximately (100, 110)
        # Date picker at (100, 160)
        # School at (100, 200)

        if menu_label.lower() == "location":
            pyautogui.click(100, 110)
        elif menu_label.lower() == "date":
            pyautogui.click(100, 160)
        elif menu_label.lower() == "school":
            pyautogui.click(100, 200)

        time.sleep(0.5)
        return True
    except Exception as e:
        add_gap("MENU_CLICK_FAILED", f"Failed to click {menu_label}: {e}")
        return False


def select_location(location: str) -> bool:
    """
    Select a location from the Location menu.
    """
    if not click_on_app_menu("location", location):
        return False

    # Navigate to the correct location using keyboard
    # This is app-specific and may need adjustment
    location_shortcuts = {
        "Hyderabad": "H",
        "Dublin CA": "D",
        "Houston TX": "H",
        "New Jersey": "N",
        "Philadelphia": "P"
    }

    if location in location_shortcuts:
        try:
            pyautogui.typewrite(location_shortcuts[location], interval=0.05)
            time.sleep(0.3)
            pyautogui.press("enter")
            time.sleep(0.3)
            return True
        except Exception as e:
            add_gap("LOCATION_SELECT_FAILED", f"Failed to select location {location}: {e}")
            return False

    add_gap("LOCATION_NOT_FOUND", f"Location not found in shortcuts: {location}")
    return False


def select_date(date: datetime) -> bool:
    """
    Select a date using the DatePicker.
    """
    if not click_on_app_menu("date", ""):
        return False

    try:
        # Focus the date picker and enter new date
        pyautogui.hotkey("command", "a")
        time.sleep(0.2)

        # Type date in MM/DD/YYYY format
        date_str = date.strftime("%m/%d/%Y")
        pyautogui.typewrite(date_str, interval=0.05)
        time.sleep(0.2)
        pyautogui.press("enter")
        time.sleep(0.5)
        return True
    except Exception as e:
        add_gap("DATE_SELECT_FAILED", f"Failed to select date {date}: {e}")
        return False


def select_school(school: str) -> bool:
    """
    Select a school from the School menu.
    """
    if not click_on_app_menu("school", school):
        return False

    school_shortcuts = {
        "Gantala": "G",
        "Nemani": "N",
        "TTD": "T"
    }

    if school in school_shortcuts:
        try:
            pyautogui.typewrite(school_shortcuts[school], interval=0.05)
            time.sleep(0.3)
            pyautogui.press("enter")
            time.sleep(0.3)
            return True
        except Exception as e:
            add_gap("SCHOOL_SELECT_FAILED", f"Failed to select school {school}: {e}")
            return False

    add_gap("SCHOOL_NOT_FOUND", f"School not found in shortcuts: {school}")
    return False


def try_extract_field(image: Image.Image, field_name: str, full_text: str) -> Optional[str]:
    """
    Try to extract a specific field value from the screenshot.
    """
    if not OCR_AVAILABLE:
        return None

    try:
        ocr_data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)

        field_labels = {
            "samvatsaram": ["samvatsaram"],
            "ayanam": ["ayanam"],
            "maasam": ["maasam"],
            "vaaram": ["vaaram"],
            "tithi": ["tithi"],
            "nakshatram": ["nakshatram"],
            "next_tithi": ["next tithi"],
            "next_nakshatram": ["next nakshatram"]
        }

        labels = field_labels.get(field_name, [])

        for i, text in enumerate(ocr_data.get("text", [])):
            if any(label in text.lower() for label in labels):
                if i + 1 < len(ocr_data["text"]):
                    return ocr_data["text"][i + 1].strip()

        return None
    except Exception as e:
        add_gap("FIELD_EXTRACT_FAILED", f"Failed to extract field {field_name}: {e}")
        return None


def run_single_test(date_label: str, date: datetime, location: str, school: str) -> dict:
    """
    Run a single test combination.
    """
    test_name = f"{date_label}_{location.replace(' ', '_')}_{school}"
    print(f"\n  Testing: {test_name}")

    # Get CLI expected values
    cli_output = get_cli_output(date, location, school)

    if cli_output is None:
        return {
            "test_name": test_name,
            "date_label": date_label,
            "date": date.strftime("%Y-%m-%d"),
            "location": location,
            "school": school,
            "passed": False,
            "error": "CLI returned no output",
            "fields": {}
        }

    # Try to interact with the app
    try:
        select_date(date)
        time.sleep(0.5)

        select_location(location)
        time.sleep(0.5)

        select_school(school)
        time.sleep(1)

        # Try to bring app to front
        try_activate_app()
        time.sleep(0.5)
    except Exception as e:
        add_gap("UI_INTERACTION_FAILED", f"UI interaction failed: {e}", {
            "test_name": test_name,
            "exception": str(e)
        })

    # Capture screenshot
    screenshot = capture_screenshot(test_name)

    if screenshot is None:
        return {
            "test_name": test_name,
            "date_label": date_label,
            "date": date.strftime("%Y-%m-%d"),
            "location": location,
            "school": school,
            "passed": False,
            "error": "Screenshot capture failed",
            "fields": {}
        }

    # Extract text from screenshot
    extracted_text = extract_text_from_screenshot(screenshot)

    if not extracted_text:
        add_gap("OCR_NO_TEXT", f"No text extracted from screenshot", {
            "test_name": test_name
        })

    # Verify each field
    panchangam = cli_output.get("panchangam", {})
    fields_result = {}
    all_passed = True

    for field in VERIFY_FIELDS:
        cli_value = panchangam.get(field)

        if cli_value is None:
            fields_result[field] = {"status": "skipped", "cli_value": None, "ui_value": None}
            continue

        # Check if the value appears in extracted text
        check_value = cli_value
        if isinstance(cli_value, str) and " until " in cli_value:
            check_value = cli_value.split(" until ")[0]

        found = check_value.lower() in extracted_text.lower() if extracted_text else False

        if found:
            fields_result[field] = {"status": "passed", "cli_value": cli_value, "ui_value": check_value}
        else:
            # Try to extract more specifically
            ui_value = try_extract_field(screenshot, field, extracted_text)
            if ui_value and compare_values(ui_value, cli_value, field)[0]:
                fields_result[field] = {"status": "passed", "cli_value": cli_value, "ui_value": ui_value}
            else:
                fields_result[field] = {"status": "failed", "cli_value": cli_value, "ui_value": ui_value}
                all_passed = False
                add_gap("FIELD_MISMATCH", f"Field {field} mismatch", {
                    "test_name": test_name,
                    "field": field,
                    "cli_value": cli_value,
                    "ui_value": ui_value
                })

    return {
        "test_name": test_name,
        "date_label": date_label,
        "date": date.strftime("%Y-%m-%d"),
        "location": location,
        "school": school,
        "passed": all_passed,
        "error": None,
        "fields": fields_result,
        "cli_output": cli_output,
        "extracted_text": extracted_text[:500] if extracted_text else ""
    }


def run_all_tests() -> List[dict]:
    """Run the full test suite (105 combinations)."""
    print("=" * 60)
    print("PanchamApp Desktop UI Test Suite")
    print("=" * 60)

    # Get test dates
    test_dates = get_test_dates()

    # Locations and schools
    locations = list(LOCATION_PRESETS)
    schools = list(SCHOOL_PRESETS)

    print(f"\nTest Matrix: {len(test_dates)} dates x {len(locations)} locations x {len(schools)} schools = {len(test_dates) * len(locations) * len(schools)} combinations")
    print(f"App path: {APP_PATH}")
    print(f"CLI path: {CLI_PATH}")
    print(f"OCR available: {OCR_AVAILABLE}")

    # Ensure screenshots directory exists
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

    # Launch the app
    if not launch_app():
        print("Failed to launch app. Exiting.")
        return []

    # Wait for app to be ready
    print("Waiting for app to initialize...")
    time.sleep(2)

    # Results collection
    all_results = []
    passed_count = 0
    failed_count = 0

    try:
        for date_label, date in test_dates.items():
            print(f"\n--- Date: {date_label} ({date.strftime('%Y-%m-%d')}) ---")

            for location in locations:
                for school in schools:
                    result = run_single_test(date_label, date, location, school)
                    all_results.append(result)

                    if result["passed"]:
                        passed_count += 1
                        print(f"  PASSED")
                    else:
                        failed_count += 1
                        print(f"  FAILED: {result.get('error', 'Unknown error')}")

                    time.sleep(0.3)

    except KeyboardInterrupt:
        print("\n\nTest interrupted by user.")
    except Exception as e:
        add_gap("TEST_SUITE_EXCEPTION", f"Test suite exception: {e}", {
            "exception": str(e)
        })
    finally:
        close_app()

    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    print(f"Total tests: {len(all_results)}")
    print(f"Passed: {passed_count}")
    print(f"Failed: {failed_count}")
    print(f"Gaps discovered: {len(TEST_GAPS)}")

    # Save results to JSON
    report = {
        "timestamp": datetime.now().isoformat(),
        "summary": {
            "total": len(all_results),
            "passed": passed_count,
            "failed": failed_count,
            "gaps": len(TEST_GAPS)
        },
        "gaps": TEST_GAPS,
        "results": all_results
    }

    with open(REPORT_PATH, "w") as f:
        json.dump(report, f, indent=2)

    print(f"\nFull report saved to: {REPORT_PATH}")

    return all_results


def main():
    """Main entry point."""
    print("Starting PanchamApp UI tests...")

    # Check prerequisites
    if APP_PATH is None:
        print(f"ERROR: App not found in any of: {APP_PATHS}")
        sys.exit(1)

    if not os.path.exists(CLI_PATH):
        print(f"ERROR: CLI not found at {CLI_PATH}")
        sys.exit(1)

    # Run tests
    results = run_all_tests()

    # Exit with appropriate code
    failed = sum(1 for r in results if not r["passed"])
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
