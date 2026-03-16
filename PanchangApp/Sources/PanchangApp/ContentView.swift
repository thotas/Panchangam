import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var selectedLocation: LocationPreset = .hyderabad
    @State private var selectedSchool: SchoolPreset = .gantala
    @State private var panchangResult: PankajamResponse? = nil
    @State private var isLoading = false

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case date, location, school
    }

    var body: some View {
        ZStack {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if let result = panchangResult {
                CompactResultView(
                    result: result,
                    selectedDate: $selectedDate,
                    selectedLocation: $selectedLocation,
                    selectedSchool: $selectedSchool,
                    focusedField: focusedField,
                    onDateChange: { calculatePanchang() }
                )
            } else {
                EmptyStateView(onCalculate: { calculatePanchang() })
            }
        }
        .frame(width: 340, height: 380)
        .onAppear {
            calculatePanchang()
        }
        .onKeyPress(.init("t")) {
            selectedDate = Date()
            calculatePanchang()
            return .handled
        }
        .onKeyPress(.init("y")) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
            calculatePanchang()
            return .handled
        }
        .onKeyPress(.init("n")) {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
            calculatePanchang()
            return .handled
        }
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

struct CompactResultView: View {
    let result: PankajamResponse
    @Binding var selectedDate: Date
    @Binding var selectedLocation: LocationPreset
    @Binding var selectedSchool: SchoolPreset
    var focusedField: ContentView.Field?
    let onDateChange: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Ultra-compact header
            HStack(spacing: 4) {
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .scaleEffect(0.55)
                    .onChange(of: selectedDate) { _, _ in onDateChange() }

                Picker("", selection: $selectedLocation) {
                    ForEach(LocationPreset.allCases) { loc in
                        Text(loc.displayName.components(separatedBy: ",").first ?? "").tag(loc)
                    }
                }
                .labelsHidden()
                .frame(width: 70)
                .onChange(of: selectedLocation) { _, _ in onDateChange() }

                Picker("", selection: $selectedSchool) {
                    ForEach(SchoolPreset.allCases) { school in
                        Text(school.displayName).tag(school)
                    }
                }
                .labelsHidden()
                .frame(width: 40)
                .onChange(of: selectedSchool) { _, _ in onDateChange() }

                // Keyboard shortcuts help
                Text("T|Y|N")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(hex: "#2C2C2E"))

            VStack(spacing: 4) {
                // Samvatsaram, Ayanam, Maasam, Vaaram, Paksha
                InfoCard(rows: [
                    ("Samvatsaram", result.panchangam.samvatsaram),
                    ("Ayanam", result.panchangam.ayanam),
                    ("Maasam", result.panchangam.maasam),
                    ("Vaaram", result.panchangam.vaaram.components(separatedBy: " (").first ?? ""),
                    ("Paksha", result.panchangam.paksha)
                ])

                // Tithi, Nakshatram
                InfoCard(rows: [
                    ("Tithi", result.panchangam.tithi.components(separatedBy: " until").first ?? ""),
                    ("Nakshatram", result.panchangam.nakshatram.components(separatedBy: " until").first ?? "")
                ])

                // Sunrise, Sunset
                HStack(spacing: 4) {
                    if let ss = result.panchangam.sunrise_sunset {
                        TimeCard(icon: "sunrise.fill", title: "Sunrise", time: ss.sunrise, color: .yellow)
                        TimeCard(icon: "sunset.fill", title: "Sunset", time: ss.sunset, color: .orange)
                    }
                }

                // Muhurtam
                HStack(spacing: 4) {
                    if let v = result.panchangam.varjyam {
                        MuhurtCard(title: "Varjyam", time: "\(v.start)-\(v.end)", isGood: true)
                    }
                    if let r = result.panchangam.rahukalam {
                        MuhurtCard(title: "Rahukalam", time: "\(r.start)-\(r.end)", isGood: false)
                    }
                    if let d = result.panchangam.durmuhurtam {
                        MuhurtCard(title: "Durmuhurtam", time: "\(d.start)-\(d.end)", isGood: false)
                    }
                }

                // Festivals
                if !result.panchangam.festivals.isEmpty {
                    FestivalCard(festivals: result.panchangam.festivals)
                }
            }
            .padding(4)
        }
    }
}

struct InfoCard: View {
    let rows: [(String, String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(rows, id: \.0) { row in
                VStack(spacing: 2) {
                    Text(row.1)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(row.0)
                        .font(.system(size: 6, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                if row.0 != rows.last?.0 {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(6)
    }
}

struct TimeCard: View {
    let icon: String
    let title: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 6, weight: .medium))
                    .foregroundColor(.gray)
                Text(time)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(6)
    }
}

struct MuhurtCard: View {
    let title: String
    let time: String
    let isGood: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 6, weight: .medium))
                .foregroundColor(.gray)
            Text(time)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(isGood ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(hex: "#3C3C3E"))
        .cornerRadius(6)
    }
}

struct FestivalCard: View {
    let festivals: [FestivalOut]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(festivals.prefix(3)) { festival in
                HStack(spacing: 3) {
                    Image(systemName: festival.is_ekadashi == true ? "moon.stars.fill" : "sparkles")
                        .font(.system(size: 8))
                        .foregroundColor(festival.is_ekadashi == true ? .orange : .yellow)
                    Text(festival.name_en)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(4)
            }
        }
    }
}

struct EmptyStateView: View {
    let onCalculate: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange.opacity(0.6))
            Text("Panchang")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Button("Calculate", action: onCalculate)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
        }
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
