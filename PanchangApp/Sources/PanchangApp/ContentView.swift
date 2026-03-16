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
        .frame(width: 420, height: 520)
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
            // Header with date picker
            headerSection

            // Main content - all visible
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Core elements row
                    coreElementsRow

                    // Tithi & Nakshatram
                    detailSection

                    // Sunrise/Sunset
                    timingSection

                    // Muhurtam times
                    if result.panchangam.varjyam != nil || result.panchangam.durmuhurtam != nil || result.panchangam.rahukalam != nil {
                        muhurtamSection
                    }

                    // Festivals
                    if !result.panchangam.festivals.isEmpty {
                        festivalsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            // Date picker
            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
                .scaleEffect(0.85)
                .onChange(of: selectedDate) { _, _ in onDateChange() }

            Spacer()

            // Location picker
            Picker("", selection: $selectedLocation) {
                ForEach(LocationPreset.allCases) { loc in
                    Text(loc.displayName).tag(loc)
                }
            }
            .labelsHidden()
            .frame(width: 120)
            .onChange(of: selectedLocation) { _, _ in onDateChange() }

            // School picker
            Picker("", selection: $selectedSchool) {
                ForEach(SchoolPreset.allCases) { school in
                    Text(school.displayName).tag(school)
                }
            }
            .labelsHidden()
            .frame(width: 70)
            .onChange(of: selectedSchool) { _, _ in onDateChange() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#2C2C2E"))
    }

    private var coreElementsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            CompactCard(title: "Vaaram", value: result.panchangam.vaaram.components(separatedBy: " (").first ?? "", icon: "calendar", color: .cyan)
            CompactCard(title: "Paksha", value: result.panchangam.paksha, icon: "moonphase.first.quarter", color: .purple)
            CompactCard(title: "Maasam", value: result.panchangam.maasam, icon: "moon.stars.fill", color: .orange)
        }
    }

    private var detailSection: some View {
        HStack(spacing: 12) {
            DetailPill(title: "Tithi", value: result.panchangam.tithi.components(separatedBy: " until").first ?? "", icon: "moon.circle.fill")
            DetailPill(title: "Nakshatra", value: result.panchangam.nakshatram.components(separatedBy: " until").first ?? "", icon: "sparkles")
        }
    }

    private var timingSection: some View {
        HStack(spacing: 12) {
            if let ss = result.panchangam.sunrise_sunset {
                TimingCard(icon: "sunrise.fill", title: "Sunrise", time: ss.sunrise, color: .yellow)
                TimingCard(icon: "sunset.fill", title: "Sunset", time: ss.sunset, color: .orange)
            }
        }
    }

    private var muhurtamSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Muhurtam")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                if let v = result.panchangam.varjyam {
                    MuhurtBadge(title: "Varjyam", time: "\(v.start)-\(v.end)", isGood: true)
                }
                if let r = result.panchangam.rahukalam {
                    MuhurtBadge(title: "Rahukalam", time: "\(r.start)-\(r.end)", isGood: false)
                }
                if let d = result.panchangam.durmuhurtam {
                    MuhurtBadge(title: "Durmuhurtam", time: "\(d.start)-\(d.end)", isGood: false)
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(10)
    }

    private var festivalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Festivals")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
                .textCase(.uppercase)

            ForEach(result.panchangam.festivals.prefix(3)) { festival in
                HStack {
                    Image(systemName: festival.is_ekadashi == true ? "moon.stars.fill" : "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(festival.is_ekadashi == true ? .orange : .yellow)

                    Text(festival.name_en)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if festival.is_ekadashi == true {
                        Text("Ekadashi")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(10)
    }
}

struct CompactCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(10)
    }
}

struct DetailPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(8)
    }
}

struct TimingCard: View {
    let icon: String
    let title: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                Text(time)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(8)
    }
}

struct MuhurtBadge: View {
    let title: String
    let time: String
    let isGood: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gray)
            Text(time)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(isGood ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(hex: "#3C3C3E"))
        .cornerRadius(6)
    }
}

struct EmptyStateView: View {
    let onCalculate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange.opacity(0.6))

            Text("Panchang")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Button("Calculate", action: onCalculate)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
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
