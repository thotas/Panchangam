import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var selectedLocation: LocationPreset = .hyderabad
    @State private var selectedSchool: SchoolPreset = .gantala
    @State private var panchangResult: PankajamResponse? = nil
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // Header panel
            headerPanel

            // 2 Vertical Panels
            HSplitView {
                // Left Panel - Controls
                controlsPanel
                    .frame(minWidth: 180, maxWidth: 220)

                // Right Panel - Results
                resultsPanel
            }
        }
        .frame(minWidth: 550, minHeight: 380)
        .background(Color(hex: "#1C1C1E"))
        .onAppear {
            calculatePanchang()
        }
    }

    // MARK: - Header Panel
    private var headerPanel: some View {
        VStack(spacing: 6) {
            // Title
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text("Panchang")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
            }

            // Selected Location, Date, School
            HStack(spacing: 16) {
                // Location display
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text(selectedLocation.displayName)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))

                Text("|")
                    .foregroundColor(.gray)

                // Date display
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.orange)

                Text("|")
                    .foregroundColor(.gray)

                // School display
                HStack(spacing: 4) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 10))
                    Text(selectedSchool.displayName)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(hex: "#161616"))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Left Panel - Controls
    private var controlsPanel: some View {
        VStack(spacing: 10) {
            // Location Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Location")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)

                Picker("", selection: $selectedLocation) {
                    ForEach(LocationPreset.allCases) { loc in
                        Text(loc.displayName).tag(loc).foregroundColor(.white)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accentColor(.white)
                .onChange(of: selectedLocation) { _, _ in calculatePanchang() }
            }

            // Date Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Date")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)

                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: selectedDate) { _, _ in calculatePanchang() }
            }

            // School Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("School")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)

                Picker("", selection: $selectedSchool) {
                    ForEach(SchoolPreset.allCases) { school in
                        Text(school.displayName).tag(school).foregroundColor(.white)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accentColor(.white)
                .onChange(of: selectedSchool) { _, _ in calculatePanchang() }
            }

            Spacer()

            // Quick Actions - very close to pickers
            VStack(spacing: 6) {
                Text("Quick Actions")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                quickActionButton(title: "Today", shortcut: "T", action: {
                    selectedDate = Date()
                    calculatePanchang()
                })

                quickActionButton(title: "Yesterday", shortcut: "Y", action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                    calculatePanchang()
                })

                quickActionButton(title: "Tomorrow", shortcut: "N", action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                    calculatePanchang()
                })
            }

            // Shortcuts hint
            HStack(spacing: 4) {
                Text("Tab")
                    .shortcutKey
                Text("next")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color(hex: "#0A0A0A"))
    }

    private func quickActionButton(title: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(shortcut)
                    .shortcutKey
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(6)
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Right Panel - Results
    private var resultsPanel: some View {
        Group {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if let result = panchangResult {
                ScrollView {
                    VStack(spacing: 10) {
                        // Row 1: Samvatsaram, Ayanam
                        HStack(spacing: 10) {
                            InfoTile(title: "Samvatsaram", value: result.panchangam.samvatsaram, icon: "sun.dust.fill", color: .yellow)
                            InfoTile(title: "Ayanam", value: result.panchangam.ayanam, icon: "arrow.up.arrow.down", color: .cyan)
                        }

                        // Row 2: Maasam, Vaaram
                        HStack(spacing: 10) {
                            InfoTile(title: "Maasam", value: result.panchangam.maasam, icon: "moon.stars.fill", color: .purple)
                            InfoTile(title: "Vaaram", value: result.panchangam.vaaram.components(separatedBy: " (").first ?? "", icon: "calendar", color: .green)
                        }

                        // Row 3: Tithi, Nakshatram
                        HStack(spacing: 10) {
                            TithiTile(title: "Tithi", value: result.panchangam.tithi, icon: "moon.circle.fill", color: .orange)
                            NakshatramTile(title: "Nakshatram", value: result.panchangam.nakshatram, icon: "sparkles", color: .pink)
                        }

                        // Row 4: Sunrise, Sunset
                        if let ss = result.panchangam.sunrise_sunset {
                            HStack(spacing: 10) {
                                TimeTile(title: "Sunrise", time: ss.sunrise, icon: "sunrise.fill", color: .yellow)
                                TimeTile(title: "Sunset", time: ss.sunset, icon: "sunset.fill", color: .orange)
                            }
                        }

                        // Row 5: Varjyam, Durmuhurtam, Rahukalam
                        if result.panchangam.varjyam != nil || result.panchangam.durmuhurtam != nil || result.panchangam.rahukalam != nil {
                            HStack(spacing: 8) {
                                if let v = result.panchangam.varjyam {
                                    MuhurtTile(title: "Varjyam", time: "\(v.start) - \(v.end)", isGood: true)
                                }
                                if let d = result.panchangam.durmuhurtam {
                                    MuhurtTile(title: "Durmuhurtam", time: "\(d.start) - \(d.end)", isGood: false)
                                }
                                if let r = result.panchangam.rahukalam {
                                    MuhurtTile(title: "Rahukalam", time: "\(r.start) - \(r.end)", isGood: false)
                                }
                            }
                        }

                        // Row 6: Festivals
                        if !result.panchangam.festivals.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Festivals")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)

                                ForEach(result.panchangam.festivals) { festival in
                                    HStack {
                                        Image(systemName: festival.is_ekadashi == true ? "moon.stars.fill" : "sparkles")
                                            .foregroundColor(festival.is_ekadashi == true ? .orange : .yellow)
                                            .font(.system(size: 10))
                                        Text(festival.name_en)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if festival.is_ekadashi == true {
                                            Text("Ekadashi")
                                                .font(.system(size: 8, weight: .medium))
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(3)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color(hex: "#1E1E1E"))
                                    .cornerRadius(5)
                                }
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0A0A0A"))
    }

    private func calculatePanchang() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = PankajamEngine.calculate(
                date: selectedDate,
                location: selectedLocation,
                school: selectedSchool
            )
            DispatchQueue.main.async {
                self.panchangResult = result
                self.isLoading = false
            }
        }
    }
}

// MARK: - Info Tile
struct InfoTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(7)
    }
}

// MARK: - Tithi Tile (with subscript until)
struct TithiTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                tithiText
            }
            Spacer()
        }
        .padding(10)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(7)
    }

    @ViewBuilder
    private var tithiText: some View {
        if let untilIndex = value.range(of: " until ") {
            let namePart = String(value[..<untilIndex.lowerBound])
            let timePart = String(value[untilIndex.upperBound...])
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(namePart)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text("until")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                Text(timePart)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
            }
        } else {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Nakshatram Tile (with subscript until)
struct NakshatramTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                nakshatramText
            }
            Spacer()
        }
        .padding(10)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(7)
    }

    @ViewBuilder
    private var nakshatramText: some View {
        if let untilIndex = value.range(of: " until ") {
            let namePart = String(value[..<untilIndex.lowerBound])
            let timePart = String(value[untilIndex.upperBound...])
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(namePart)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text("until")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                Text(timePart)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
            }
        } else {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Time Tile
struct TimeTile: View {
    let title: String
    let time: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                Text(time)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(7)
    }
}

// MARK: - Muhurt Tile
struct MuhurtTile: View {
    let title: String
    let time: String
    let isGood: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.gray)
            Text(time)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(isGood ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: "#2A2A2A"))
        .cornerRadius(5)
    }
}

// MARK: - Text Extension for Shortcut Keys
extension Text {
    var shortcutKey: some View {
        self
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.3))
            .cornerRadius(3)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
