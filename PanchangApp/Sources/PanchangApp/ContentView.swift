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
            // Premium dark background
            LinearGradient(
                colors: [Color(hex: "#0A0A0F"), Color(hex: "#121218")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if isLoading {
                loadingView()
            } else if let result = panchangResult {
                mainContent(result: result)
            } else {
                emptyView()
            }
        }
        .frame(width: 360, height: 400)
        .onAppear {
            calculatePanchang()
        }
    }

    private func loadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            Text("Calculating...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private func emptyView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Panchang")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Button("Calculate") { calculatePanchang() }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
    }

    @ViewBuilder
    private func mainContent(result: PankajamResponse) -> some View {
        VStack(spacing: 0) {
            // Premium header
            headerView(result: result)

            // Scrollable content
            ScrollView {
                VStack(spacing: 16) {
                    // Primary info cards
                    primaryCards(result: result)

                    // Secondary info
                    secondaryCards(result: result)

                    // Muhurtam section
                    if hasMuhurtam(result: result) {
                        muhurtamSection(result: result)
                    }

                    // Festivals
                    if !result.panchangam.festivals.isEmpty {
                        festivalsSection(festivals: result.panchangam.festivals)
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
    }

    private func headerView(result: PankajamResponse) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.header.location)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(result.header.coordinates)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedDate)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                Text(result.header.school)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: selectedDate)
    }

    private func primaryCards(result: PankajamResponse) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            PremiumCard(
                title: "Vaaram",
                value: result.panchangam.vaaram.components(separatedBy: " (").first ?? "",
                icon: "calendar",
                color: .cyan
            )
            PremiumCard(
                title: "Paksha",
                value: result.panchangam.paksha,
                icon: "moonphase.first.quarter",
                color: .purple
            )
            PremiumCard(
                title: "Maasam",
                value: result.panchangam.maasam,
                icon: "moon.stars.fill",
                color: .orange
            )
            PremiumCard(
                title: "Samvatsaram",
                value: result.panchangam.samvatsaram,
                icon: "sun.dust.fill",
                color: .yellow
            )
        }
    }

    private func secondaryCards(result: PankajamResponse) -> some View {
        VStack(spacing: 10) {
            // Tithi & Nakshatram
            HStack(spacing: 10) {
                DetailCard(
                    title: "Tithi",
                    value: result.panchangam.tithi.components(separatedBy: " until").first ?? "",
                    icon: "moon.circle.fill"
                )
                DetailCard(
                    title: "Nakshatram",
                    value: result.panchangam.nakshatram.components(separatedBy: " until").first ?? "",
                    icon: "sparkles"
                )
            }

            // Sunrise & Sunset
            if let ss = result.panchangam.sunrise_sunset {
                HStack(spacing: 10) {
                    TimeCard(title: "Sunrise", time: ss.sunrise, icon: "sunrise.fill", color: .yellow)
                    TimeCard(title: "Sunset", time: ss.sunset, icon: "sunset.fill", color: .orange)
                }
            }
        }
    }

    private func hasMuhurtam(result: PankajamResponse) -> Bool {
        result.panchangam.varjyam != nil ||
        result.panchangam.rahukalam != nil ||
        result.panchangam.durmuhurtam != nil
    }

    private func muhurtamSection(result: PankajamResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Muhurtam")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)

            HStack(spacing: 8) {
                if let v = result.panchangam.varjyam {
                    MuhurtBadge(title: "Varjyam", time: v.start, isGood: true)
                }
                if let r = result.panchangam.rahukalam {
                    MuhurtBadge(title: "Rahukalam", time: r.start, isGood: false)
                }
                if let d = result.panchangam.durmuhurtam {
                    MuhurtBadge(title: "Durmuhurtam", time: d.start, isGood: false)
                }
            }
        }
    }

    private func festivalsSection(festivals: [FestivalOut]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Festivals")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)

            VStack(spacing: 6) {
                ForEach(festivals.prefix(2)) { festival in
                    FestivalRow(festival: festival)
                }
            }
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

// MARK: - Premium Card Components

struct PremiumCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TimeCard: View {
    let title: String
    let time: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(time)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .foregroundColor(.white.opacity(0.5))
            Text(time)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(isGood ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(hex: "#1E1E24"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct FestivalRow: View {
    let festival: FestivalOut

    var body: some View {
        HStack {
            Image(systemName: festival.is_ekadashi == true ? "moon.stars.fill" : "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(festival.is_ekadashi == true ? .orange : .yellow)

            Text(festival.name_en)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            if festival.is_ekadashi == true {
                Text("Ekadashi")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
