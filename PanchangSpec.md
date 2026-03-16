This is the finalized, end-to-end technical specification for the **Panchangam Core Engine**. This spec is optimized for **Antigravity** to generate a high-performance, calculation-only system with a CLI-first architecture.

---

## 1. Project Identity & Architecture

* **Name:** `Panchang-Engine-X`
* **Architecture:** Monorepo using **Rust** as the shared mathematical core.
* **Logic Model:** **Zero-Storage / Compute-On-Demand**. All astronomical positions are calculated using the Swiss Ephemeris library.
* **Deployment:** * **Phase 1:** Rust CLI (Linux/macOS).
* **Phase 2:** Swift/SwiftUI (Native macOS via FFI).
* **Phase 3:** React/Next.js (via WebAssembly).



---

## 2. Location Configuration (Static Bounds)

The application must strictly support and prioritize the following five geographic regions. The CLI should accept these as `enum` presets or via direct coordinates.

| Location | Latitude | Longitude | Default Timezone |
| --- | --- | --- | --- |
| **Hyderabad** | 17.3850° N | 78.4867° E | Asia/Kolkata |
| **Dublin, CA, USA** | 37.7022° N | 121.9358° W | America/Los_Angeles |
| **Houston, TX, USA** | 29.7604° N | 95.3698° W | America/Chicago |
| **New Jersey, USA** | 40.0583° N | 74.4057° W | America/New_York |
| **Philadelphia, USA** | 39.9526° N | 75.1652° W | America/New_York |

---

## 3. Core Engine Specification (Rust)

### A. Dependencies

* `cpp-bridge` / `rust-bindgen`: To interface with the **Swiss Ephemeris (sweph)** C library.
* `chrono` & `chrono-tz`: For high-precision time and historical timezone offsets.
* `clap`: For CLI argument parsing.
* `serde`: For JSON output.

### B. Tradition Profiles (Schools)

1. **Gantala:** Drik Siddhanta, Lahiri Ayanamsa, Udaya Vyapini Tithi logic.
2. **Nemani:** Drik Siddhanta, Lahiri Ayanamsa, Optimized for Western Date Line (USA timezones).
3. **TTD:** Tirumala Devasthanam standard; specific sunrise-to-sunset rules.

### C. Festival Rule Engine (Regional Focus)

The engine will run a `match_festivals()` function after the daily Panchang calculation.

* **Logic:** `(Month, Paksha, Tithi) -> FestivalName`.
* **Hyderabad Specials:**
* **Bonalu:** Sunday-based logic in Ashada Maasam (Golconda, Secunderabad, Lal Darwaza).
* **Bathukamma:** 9-day sequence ending at Saddula Bathukamma (Ashwayuja Ashtami).
* **Sammakka Sarakka Jatara:** Biennial logic based on Magha Purnima.



---

## 4. CLI Technical Interface

### Command Syntax

```bash
panchang --location "Dublin, CA" --date "2026-03-15" --school nemani --format json

```

### Response Schema (English + Transliterated Telugu)

```json
{
  "header": {
    "location": "Dublin, California, USA",
    "coordinates": "37.7022 N, 121.9358 W",
    "timezone": "PDT (UTC-7)",
    "school": "Nemani"
  },
  "panchangam": {
    "samvatsaram": "Krodhi (క్రోధి)",
    "ayanam": "Uttarayanam (ఉత్తరాయణం)",
    "maasam": "Phalguna (ఫాల్గుణ మాసం)",
    "vaaram": "Adivaram (ఆదివారం / Sunday)",
    "tithi": "Ekadasi (ఏకాదశి) until 15:45",
    "nakshatram": "Shravana (శ్రవణ) until 18:20"
  },
  "festivals": [
    {
      "en": "No Major Festival",
      "te": "పండుగలు లేవు"
    }
  ]
}

```

---

## 5. Comprehensive Test Plan

### Test Set 1: Precision (The "Past/Future" Test)

* **Input:** August 15, 1947 (Independence Day) at Hyderabad.
* **Validation:** Verify Tithi and Nakshatra match historical Gantala records.

### Test Set 2: Timezone Synchronization

* **Input:** Dec 31, 2025, 11:59 PM in **Dublin, CA** vs **Hyderabad**.
* **Validation:** Confirm the engine correctly identifies different Lunar days due to the 13.5-hour time gap.

### Test Set 3: Hyderabad Regional Logic

* **Input:** Ashada Sundays, 2026.
* **Validation:** Confirm "Bonalu" is listed only for the Hyderabad location and not for USA locations unless specified.

### Test Set 4: Boundary Edge Cases

* **Input:** Midnight calculations (00:01 AM).
* **Validation:** Ensure the "Vara" (Weekday) remains the previous day until the local **Sunrise** (as per Vedic tradition).

---
