import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var selectedLocation: LocationPreset = .hyderabad
    @State private var selectedSchool: SchoolPreset = .gantala

    @State private var panchangResult: PankajamResponse? = nil
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else if let result = panchangResult {
                CompactResultView(
                    result: result,
                    selectedDate: $selectedDate,
                    selectedLocation: $selectedLocation,
                    selectedSchool: $selectedSchool,
                    onDateChange: { calculatePanchang() }
                )
            } else {
                EmptyStateView(onCalculate: { calculatePanchang() })
            }
        }
        .frame(width: 380, height: 480)
        .onAppear {
            calculatePanchang()
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
    let onDateChange: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            headerSection

            // Main content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    coreElementsRow
                    detailSection
                    timingSection

                    if result.panchangam.varjyam != nil || result.panchangam.durmuhurtam != nil || result.panchangam.rahukalam != nil {
                        muhurtamSection
                    }

                    if !result.panchangam.festivals.isEmpty {
                        festivalsSection
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 8) {
            // Compact date picker
            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
                .scaleEffect(0.7)
                .onChange(of: selectedDate) { _, _ in onDateChange() }

            // Compact pickers stacked
            HStack(spacing: 4) {
                Picker("", selection: $selectedLocation) {
                    ForEach(LocationPreset.allCases) { loc in
                        Text(loc.displayName.components(separatedBy: ",").first ?? "").tag(loc)
                    }
                }
                .labelsHidden()
                .frame(width: 90)
                .onChange(of: selectedLocation) { _, _ in onDateChange() }

                Picker("", selection: $selectedSchool) {
                    ForEach(SchoolPreset.allCases) { school in
                        Text(school.displayName).tag(school)
                    }
                }
                .labelsHidden()
                .frame(width: 55)
                .onChange(of: selectedSchool) { _, _ in onDateChange() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "#2C2C2E"))
    }

    private var coreElementsRow: some View {
        HStack(spacing: 8) {
            MiniCard(title: "Vaaram", value: result.panchangam.vaaram.components(separatedBy: " (").first ?? "", icon: "calendar", color: .cyan)
            MiniCard(title: "Paksha", value: result.panchangam.paksha, icon: "moonphase.first.quarter", color: .purple)
            MiniCard(title: "Maasam", value: result.panchangam.maasam, icon: "moon.stars.fill", color: .orange)
        }
    }

    private var detailSection: some View {
        HStack(spacing: 8) {
            MiniPill(title: "Tithi", value: result.panchangam.tithi.components(separatedBy: " until").first ?? "", icon: "moon.circle.fill")
            MiniPill(title: "Nakshatra", value: result.panchangam.nakshatram.components(separatedBy: " until").first ?? "", icon: "sparkles")
        }
    }

    private var timingSection: some View {
        HStack(spacing: 8) {
            if let ss = result.panchangam.sunrise_sunset {
                MiniTiming(icon: "sunrise.fill", time: ss.sunrise, color: .yellow)
                MiniTiming(icon: "sunset.fill", time: ss.sunset, color: .orange)
            }
        }
    }

    private var muhurtamSection: some View {
        HStack(spacing: 6) {
            if let v = result.panchangam.varjyam {
                MiniMuhurt(title: "Varj", time: "\(v.start)", isGood: true)
            }
            if let r = result.panchangam.rahukalam {
                MiniMuhurt(title: "Rahu", time: "\(r.start)", isGood: false)
            }
            if let d = result.panchangam.durmuhurtam {
                MiniMuhurt(title: "Dur", time: "\(d.start)", isGood: false)
            }
        }
    }

    private var festivalsSection: some View {
        HStack(spacing: 6) {
            ForEach(result.panchangam.festivals.prefix(2)) { festival in
                MiniFestival(festival: festival)
            }
        }
    }
}

struct MiniCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(title)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(8)
    }
}

struct MiniPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.orange)

            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(6)
    }
}

struct MiniTiming: View {
    let icon: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)

            Text(time)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(6)
    }
}

struct MiniMuhurt: View {
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
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(hex: "#3C3C3E"))
        .cornerRadius(4)
    }
}

struct MiniFestival: View {
    let festival: FestivalOut

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: festival.is_ekadashi == true ? "moon.stars.fill" : "sparkles")
                .font(.system(size: 8))
                .foregroundColor(festival.is_ekadashi == true ? .orange : .yellow)

            Text(festival.name_en)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(6)
    }
}

struct EmptyStateView: View {
    let onCalculate: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange.opacity(0.6))

            Text("Panchang")
                .font(.system(size: 16, weight: .bold))
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
