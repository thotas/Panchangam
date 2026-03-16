# CLI Enhancement: Next Tithi/Nakshatram Display

## Overview
Enhance the CLI to display the next tithi and nakshatram when the current one ends before end of day, and indicate festival associations.

## Background
The current CLI displays tithi and nakshatram with their end times. Users want to see what comes next if the current one completes within the day.

## Requirements

### 1. Next Tithi Display
- If current tithi ends before 23:59, display the next tithi with its end time
- Format in plain output: `Next Tithi: <name> until <HH:MM>`
- Format in JSON: `next_tithi: { name: string, ends_at: string }`
- Next tithi's end time can be after midnight (next calendar day)

### 2. Next Nakshatram Display
- If current nakshatram ends before 23:59, display the next nakshatram with its end time
- Format in plain output: `Next Nakshatram: <name> until <HH:MM>`
- Format in JSON: `next_nakshatram: { name: string, ends_at: string }`
- Next nakshatram's end time can be after midnight (next calendar day)

### 3. Festival Indicators
- If current or next tithi has a festival, show indicator in plain output
- Format: `Tithi: Tritiya until 14:30 (Festival Day: Ekadashi)`
- In JSON, the festival names are already in the `festivals` array - match by tithi index

## Technical Design

### Data Model Changes

** PankajamResult (engine.rs)**
```rust
pub struct PankajamResult {
    // ... existing fields ...
    pub next_tithi: Option<TimedInfo>,      // NEW
    pub next_nakshatram: Option<TimedInfo>, // NEW
}

pub struct TimedInfo {
    pub name: String,
    pub ends_at: String,  // "HH:MM" format
}
```

** PankajamamOut (main.rs)**
```rust
struct TimedInfoOut {
    name: String,
    ends_at: String,
}

struct PankajamamOut {
    // ... existing fields ...
    #[serde(skip_serializing_if = "Option::is_none")]
    next_tithi: Option<TimedInfoOut>,
    #[serde(skip_serializing_if = "Option::is_none")]
    next_nakshatram: Option<TimedInfoOut>,
}
```

### Calculation Logic

**Engine.calculate()** (engine.rs, around lines 140-148):

Current tithi/nakshatram end time is calculated as:
```rust
let hours_left_tithi = (1.0 - tithi_exact.fract()) * 24.0;
let end_tithi = local_dt + Duration::minutes((hours_left_tithi * 60.0) as i64);
```

For next tithi:
1. Compute current tithi remaining hours
2. Compute next tithi index: `(tithi_idx % 30) + 1`
3. Next tithi ends at: `end_tithi + Duration::minutes(remaining_hours_of_current_tithi)`
4. Check if `end_tithi.hour() < 24` (ends before or at midnight)

For next nakshatram:
- Same logic with 27 nakshatras instead of 30

### Output Format

**Plain format example:**
```
Tithi: Tritiya until 14:30 (Festival Day: Ekadashi)
Next Tithi: Chaturthi until 18:45
Nakshatram: Ashvini until 10:20
Next Nakshatram: Bharani until 13:15
```

**JSON format:**
```json
{
  "panchangam": {
    "tithi": "Tritiya until 14:30",
    "next_tithi": {
      "name": "Chaturthi",
      "ends_at": "18:45"
    },
    "nakshatram": "Ashvini until 10:20",
    "next_nakshatram": {
      "name": "Bharani",
      "ends_at": "13:15"
    },
    "festivals": [...]
  }
}
```

### Festival Matching
- Tithi index 11 = Ekadashi (all months have Ekadashi festivals)
- Other festivals are matched by month + paksha + tithi
- For festival indicator, check if any festival corresponds to current or next tithi index

## Acceptance Criteria

1. [ ] If tithi ends before 23:59, plain output shows "Next Tithi: X until HH:MM"
2. [ ] If nakshatram ends before 23:59, plain output shows "Next Nakshatram: Y until HH:MM"
3. [ ] If tithi has festival, plain output shows "(Festival Day: Z)" after tithi line
4. [ ] JSON output includes next_tithi field when applicable
5. [ ] JSON output includes next_nakshatram field when applicable
6. [ ] Next end times can be after 23:59 (into next day)

## Files to Modify
- `panchang-engine/src/engine.rs` - Add calculation for next tithi/nakshatram
- `panchang-engine/src/main.rs` - Add output fields for CLI display