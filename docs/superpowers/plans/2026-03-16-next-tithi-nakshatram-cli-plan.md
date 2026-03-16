# Next Tithi/Nakshatram CLI Enhancement Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add display of next tithi and nakshatram when current one ends before midnight, with festival indicators in CLI output.

**Architecture:** Extend PankajamResult struct with next_tithi and next_nakshatram fields. Calculate end times for next tithi/nakshatram by adding current remaining duration to current end time. Check if current ends before 23:59 before showing next.

**Tech Stack:** Rust, chrono crate for time calculations, serde for JSON output

---

## File Structure

- **Modify:** `panchang-engine/src/engine.rs` - Add TimedInfo struct, extend PankajamResult, add calculation logic
- **Modify:** `panchang-engine/src/main.rs` - Add output struct fields, update CLI display

---

## Chunk 1: Engine Changes

### Task 1: Add TimedInfo struct and extend PankajamResult

**Files:**
- Modify: `panchang-engine/src/engine.rs:25-38`

- [ ] **Step 1: Write the failing test**

Add test for next_tithi and next_nakshatram fields - they should be None initially.

```rust
#[test]
fn test_pankajam_result_has_next_fields() {
    use crate::LocationPreset;
    use crate::School;
    let date = chrono::NaiveDate::from_ymd_opt(2026, 3, 16).unwrap();
    let loc = LocationPreset::Hyderabad.details();
    let eng = Engine::new(School::Gantala);
    let res = eng.calculate(date, &loc);
    // These fields should exist
    let _ = res.next_tithi;
    let _ = res.next_nakshatram;
    Engine::cleanup();
}
```

Run: `cd panchang-engine && cargo test test_pankajam_result_has_next_fields`
Expected: FAIL with "no field `next_tithi`"

- [ ] **Step 2: Add TimedInfo struct after TimedResult**

Add at line ~24 (after TimedResult struct):

```rust
pub struct TimedInfo {
    pub name: String,
    pub ends_at: String,
}
```

- [ ] **Step 3: Add fields to PankajamResult**

Add to PankajamResult struct around line 37:

```rust
pub next_tithi: Option<TimedInfo>,
pub next_nakshatram: Option<TimedInfo>,
```

- [ ] **Step 4: Run test to verify it compiles**

Run: `cd panchang-engine && cargo test test_pankajam_result_has_next_fields`
Expected: PASS (compilation succeeds)

- [ ] **Step 5: Commit**

```bash
git add panchang-engine/src/engine.rs
git commit -m "feat: add TimedInfo struct and next_tithi/next_nakshatram fields to PankajamResult"
```

---

### Task 2: Calculate next tithi end time

**Files:**
- Modify: `panchang-engine/src/engine.rs:141-148`

- [ ] **Step 1: Write failing test for next tithi calculation**

```rust
#[test]
fn test_next_tithi_calculated_when_current_ends_before_midnight() {
    use crate::LocationPreset;
    use crate::School;
    // March 16, 2026 - should have a tithi ending before midnight
    let date = chrono::NaiveDate::from_ymd_opt(2026, 3, 16).unwrap();
    let loc = LocationPreset::Hyderabad.details();
    let eng = Engine::new(School::Gantala);
    let res = eng.calculate(date, &loc);

    // If current tithi ends before 23:59, next should be populated
    let tithi_str = &res.tithi;
    if tithi_str.contains("until") {
        let parts: Vec<&str> = tithi_str.split(" until ").collect();
        if parts.len() == 2 {
            let end_time = parts[1];
            let hour: u32 = end_time[..2].parse().unwrap();
            if hour < 23 {
                assert!(res.next_tithi.is_some(), "Next tithi should be populated when current ends before midnight");
            }
        }
    }
    Engine::cleanup();
}
```

Run: `cd panchang-engine && cargo test test_next_tithi_calculated_when_current_ends_before_midnight`
Expected: FAIL - next_tithi is None

- [ ] **Step 2: Add next tithi calculation logic**

Find the tithi calculation section around line 141-147 in engine.rs. After the existing tithi string construction, add:

```rust
// Calculate next tithi if current ends before midnight
let next_tithi = if end_tithi.hour() < 23 {
    let next_tithi_idx = (tithi_idx % 30) + 1;
    // Next tithi ends at: end of current tithi + duration of current tithi
    let current_duration_hours = (1.0 - tithi_exact.fract()) * 24.0;
    let next_end = end_tithi + chrono::Duration::minutes((current_duration_hours * 60.0) as i64);
    Some(TimedInfo {
        name: tithis[(next_tithi_idx - 1) as usize].to_string(),
        ends_at: format!("{:02}:{:02}", next_end.hour(), next_end.minute()),
    })
} else {
    None
};
```

- [ ] **Step 3: Run test to verify it passes**

Run: `cd panchang-engine && cargo test test_next_tithi_calculated_when_current_ends_before_midnight`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add panchang-engine/src/engine.rs
git commit -m "feat: calculate next tithi end time when current ends before midnight"
```

---

### Task 3: Calculate next nakshatram end time

**Files:**
- Modify: `panchang-engine/src/engine.rs:145-155`

- [ ] **Step 1: Write failing test for next nakshatram**

```rust
#[test]
fn test_next_nakshatram_calculated_when_current_ends_before_midnight() {
    use crate::LocationPreset;
    use crate::School;
    let date = chrono::NaiveDate::from_ymd_opt(2026, 3, 16).unwrap();
    let loc = LocationPreset::Hyderabad.details();
    let eng = Engine::new(School::Gantala);
    let res = eng.calculate(date, &loc);

    let nak_str = &res.nakshatram;
    if nak_str.contains("until") {
        let parts: Vec<&str> = nak_str.split(" until ").collect();
        if parts.len() == 2 {
            let end_time = parts[1];
            let hour: u32 = end_time[..2].parse().unwrap();
            if hour < 23 {
                assert!(res.next_nakshatram.is_some(), "Next nakshatram should be populated when current ends before midnight");
            }
        }
    }
    Engine::cleanup();
}
```

Run: `cd panchang-engine && cargo test test_next_nakshatram_calculated_when_current_ends_before_midnight`
Expected: FAIL - next_nakshatram is None

- [ ] **Step 2: Add next nakshatram calculation**

After the tithi calculation (after line ~163), add:

```rust
// Calculate next nakshatram if current ends before midnight
let next_nakshatram = if end_nak.hour() < 23 {
    let next_nak_idx = (nak_idx % 27) + 1;
    let current_duration_hours = (1.0 - nak_exact.fract()) * 24.0;
    let next_end = end_nak + chrono::Duration::minutes((current_duration_hours * 60.0) as i64);
    Some(TimedInfo {
        name: naks[(next_nak_idx - 1) as usize].to_string(),
        ends_at: format!("{:02}:{:02}", next_end.hour(), next_end.minute()),
    })
} else {
    None
};
```

- [ ] **Step 3: Update PankajamResult to include next fields**

In the return statement around line 262, add:

```rust
PankajamResult {
    // ... existing fields ...
    next_tithi,
    next_nakshatram,
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd panchang-engine && cargo test test_next_nakshatram_calculated_when_current_ends_before_midnight`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add panchang-engine/src/engine.rs
git commit -m "feat: calculate next nakshatram end time when current ends before midnight"
```

---

## Chunk 2: CLI Output Changes

### Task 4: Add JSON output fields

**Files:**
- Modify: `panchang-engine/src/main.rs:74-106`

- [ ] **Step 1: Add TimedInfoOut struct**

Add after TimedResultOut (around line 78):

```rust
#[derive(Serialize)]
struct TimedInfoOut {
    name: String,
    ends_at: String,
}
```

- [ ] **Step 2: Add next fields to PankajamamOut**

In PankajamamOut struct, add:

```rust
#[serde(skip_serializing_if = "Option::is_none")]
next_tithi: Option<TimedInfoOut>,
#[serde(skip_serializing_if = "Option::is_none")]
next_nakshatram: Option<TimedInfoOut>,
```

- [ ] **Step 3: Populate next fields in output**

In the output construction (around line 140), add:

```rust
next_tithi: p_res.next_tithi.map(|n| TimedInfoOut {
    name: n.name,
    ends_at: n.ends_at,
}),
next_nakshatram: p_res.next_nakshatram.map(|n| TimedInfoOut {
    name: n.name,
    ends_at: n.ends_at,
}),
```

- [ ] **Step 4: Test JSON output**

Run: `cd panchang-engine && cargo run -- --location hyderabad --date 2026-03-16 --school gantala --format json`
Check output includes next_tithi and next_nakshatram fields

- [ ] **Step 5: Commit**

```bash
git add panchang-engine/src/main.rs
git commit -m "feat: add next_tithi and next_nakshatram to JSON output"
```

---

### Task 5: Add plain format output

**Files:**
- Modify: `panchang-engine/src/main.rs:186-216`

- [ ] **Step 1: Add plain output for next tithi**

After the tithi print line (~186), add:

```rust
if let Some(next_t) = &out.panchangam.next_tithi {
    println!("Next Tithi: {} until {}", next_t.name, next_t.ends_at);
}
```

- [ ] **Step 2: Add plain output for next nakshatram**

After the nakshatram print line (~187), add:

```rust
if let Some(next_n) = &out.panchangam.next_nakshatram {
    println!("Next Nakshatram: {} until {}", next_n.name, next_n.ends_at);
}
```

- [ ] **Step 3: Test plain output**

Run: `cd panchang-engine && cargo run -- --location hyderabad --date 2026-03-16 --school gantala --format plain`
Verify next tithi and nakshatram lines appear when applicable

- [ ] **Step 4: Commit**

```bash
git add panchang-engine/src/main.rs
git commit -m "feat: add next tithi and nakshatram to plain output"
```

---

### Task 6: Add festival indicator for tithis

**Files:**
- Modify: `panchang-engine/src/main.rs:186-190`

- [ ] **Step 1: Modify tithi output to include festival indicator**

Replace the tithi line with logic to check if any festival matches current tithi:

```rust
// Check if current tithi has festival
let tithi_has_festival = out.panchangam.festivals.iter().any(|f| {
    // Ekadashi is tithi 11 - check if any festival name contains Ekadashi
    f.name_en.contains("Ekadashi")
});

let festival_marker = if tithi_has_festival {
    let festival_name = out.panchangam.festivals.iter()
        .find(|f| f.name_en.contains("Ekadashi"))
        .map(|f| f.name_en.clone())
        .unwrap_or_default();
    format!(" (Festival Day: {})", festival_name)
} else {
    String::new()
};

println!("Tithi: {}{}", out.panchangam.tithi, festival_marker);
```

- [ ] **Step 2: Test with a date that has Ekadashi**

Need to find a date with Ekadashi - let's test with the current implementation first to ensure it compiles.

Run: `cd panchang-engine && cargo build`
Expected: Compiles without error

- [ ] **Step 3: Find a date with Ekadashi for testing**

Run a few dates to find one with Ekadashi:
- 2026-03-17 (Phalguna Krishna 11) - should be Ekadashi
- Check output for festival indicator

- [ ] **Step 4: Commit**

```bash
git add panchang-engine/src/main.rs
git commit -m "feat: add festival day indicator to tithi output"
```

---

## Final Verification

- [ ] Run full CLI with various dates to verify output format
- [ ] Run all existing tests to ensure no regression
- [ ] Verify both JSON and plain formats show next tithi/nakshatram correctly

---

## Plan Complete

**Ready to execute?** This plan has 6 tasks with approximately 20 steps total. Engine changes are in Chunk 1, CLI output changes in Chunk 2.