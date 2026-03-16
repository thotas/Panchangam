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
            // Header: Title + Location + Date (centered)
            headerSection

            // Results Panel
            resultsPanel
        }
        .frame(minWidth: 500, minHeight: 450)
        .background(Color(hex: "#1C1C1E"))
        .onAppear {
            calculatePanchang()
        }
    }

    // MARK: - Header Section (centered)
    private var headerSection: some View {
        VStack(spacing: 8) {
            // Title
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text("Panchang")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
            }

            // Location & Date (centered)
            HStack(spacing: 20) {
                // Location Picker
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Picker("", selection: $selectedLocation) {
                        ForEach(LocationPreset.allCases) { loc in
                            Text(loc.displayName).tag(loc)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 150)
                    .onChange(of: selectedLocation) { _, _ in calculatePanchang() }
                }

                Text("|")
                    .foregroundColor(.gray)

                // Date Picker
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: selectedDate) { _, _ in calculatePanchang() }
                }

                Text("|")
                    .foregroundColor(.gray)

                // School Picker
                HStack(spacing: 6) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Picker("", selection: $selectedSchool) {
                        ForEach(SchoolPreset.allCases) { school in
                            Text(school.displayName).tag(school)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .onChange(of: selectedSchool) { _, _ in calculatePanchang() }
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(hex: "#161616"))
    }

    // MARK: - Results Panel
    private var resultsPanel: some View {
        Group {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if let result = panchangResult {
                ScrollView {
                    VStack(spacing: 12) {
                        // Row 1: Samvatsaram, Ayanam
                        HStack(spacing: 12) {
                            InfoTile(title: "Samvatsaram", value: result.panchangam.samvatsaram, icon: "sun.dust.fill", color: .yellow)
                            InfoTile(title: "Ayanam", value: result.panchangam.ayanam, icon: "arrow.up.arrow.down", color: .cyan)
                        }

                        // Row 2: Maasam, Vaaram
                        HStack(spacing: 12) {
                            InfoTile(title: "Maasam", value: result.panchangam.maasam, icon: "moon.stars.fill", color: .purple)
                            InfoTile(title: "Vaaram", value: result.panchangam.vaaram.components(separatedBy: " (").first ?? "", icon: "calendar", color: .green)
                        }

                        // Row 3: Tithi, Nakshatram
                        HStack(spacing: 12) {
                            InfoTile(title: "Tithi", value: result.panchangam.tithi.components(separatedBy: " until").first ?? "", icon: "moon.circle.fill", color: .orange)
                            InfoTile(title: "Nakshatram", value: result.panchangam.nakshatram.components(separatedBy: " until").first ?? "", icon: "sparkles", color: .pink)
                        }

                        // Row 4: Sunrise, Sunset
                        if let ss = result.panchangam.sunrise_sunset {
                            HStack(spacing: 12) {
                                TimeTile(title: "Sunrise", time: ss.sunrise, icon: "sunrise.fill", color: .yellow)
                                TimeTile(title: "Sunset", time: ss.sunset, icon: "sunset.fill", color: .orange)
                            }
                        }

                        // Row 5: Varjyam, Durmuhurtam, Rahukalam
                        if result.panchangam.varjyam != nil || result.panchangam.durmuhurtam != nil || result.panchangam.rahukalam != nil {
                            HStack(spacing: 12) {
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
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)

                                ForEach(result.panchangam.festivals) { festival in
                                    HStack {
                                        Image(systemName: festival.is_ekadashi == true ? "moon.stars.fill" : "sparkles")
                                            .foregroundColor(festival.is_ekadashi == true ? .orange : .yellow)
                                            .font(.system(size: 11))
                                        Text(festival.name_en)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if festival.is_ekadashi == true {
                                            Text("Ekadashi")
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color(hex: "#1E1E1E"))
                                    .cornerRadius(6)
                                }
                            }
                        }

                        // Quick Actions + Shortcuts
                        HStack(spacing: 12) {
                            quickActionButton(title: "Today", icon: "calendar.badge.clock", action: {
                                selectedDate = Date()
                                calculatePanchang()
                            })

                            quickActionButton(title: "Yesterday", icon: "chevron.left", action: {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                                calculatePanchang()
                            })

                            quickActionButton(title: "Tomorrow", icon: "chevron.right", action: {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                                calculatePanchang()
                            })

                            Spacer()

                            HStack(spacing: 4) {
                                Text("T")
                                    .shortcutKey
                                Text("Y")
                                    .shortcutKey
                                Text("N")
                                    .shortcutKey
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0A0A0A"))
    }

    private func quickActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: "#3C3C3E"))
            .cornerRadius(5)
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(8)
    }
}

// MARK: - Time Tile
struct TimeTile: View {
    let title: String
    let time: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Text(time)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(8)
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
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gray)
            Text(time)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(isGood ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(hex: "#2A2A2A"))
        .cornerRadius(6)
    }
}

// MARK: - Text Extension for Shortcut Keys
extension Text {
    var shortcutKey: some View {
        self
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundColor(.orange)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.15))
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
