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
            } else if let result = panchangResult {
                ResultCardView(result: result)
            } else {
                EmptyStateView(onCalculate: { calculatePanchang() })
            }
        }
        .frame(width: 380, height: 340)
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

struct ResultCardView: View {
    let result: PankajamResponse

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.header.location)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(result.header.coordinates)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDate(Date()))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                    Text(result.header.school)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Divider()
                .background(Color.white.opacity(0.1))

            // Main grid - 2x2
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                DataTile(title: "Vaaram", value: result.panchangam.vaaram.components(separatedBy: " (").first ?? "", icon: "calendar", color: .cyan)
                DataTile(title: "Paksha", value: result.panchangam.paksha, icon: "moonphase.first.quarter", color: .purple)
                DataTile(title: "Maasam", value: result.panchangam.maasam, icon: "moon.stars.fill", color: .orange)
                DataTile(title: "Samvatsaram", value: result.panchangam.samvatsaram, icon: "sun.dust.fill", color: .yellow)
            }
            .padding(.horizontal, 16)

            // Tithi & Nakshatram
            HStack(spacing: 10) {
                DetailTile(title: "Tithi", value: result.panchangam.tithi.components(separatedBy: " until").first ?? "", icon: "moon.circle.fill")
                DetailTile(title: "Nakshatram", value: result.panchangam.nakshatram.components(separatedBy: " until").first ?? "", icon: "sparkles")
            }
            .padding(.horizontal, 16)

            // Sunrise/Sunset
            if let ss = result.panchangam.sunrise_sunset {
                HStack(spacing: 10) {
                    TimeTile(icon: "sunrise.fill", title: "Sunrise", time: ss.sunrise, color: .yellow)
                    TimeTile(icon: "sunset.fill", title: "Sunset", time: ss.sunset, color: .orange)
                }
                .padding(.horizontal, 16)
            }

            // Muhurtam
            HStack(spacing: 8) {
                if let v = result.panchangam.varjyam {
                    MuhurtTile(title: "Varjyam", time: "\(v.start)-\(v.end)", isGood: true)
                }
                if let r = result.panchangam.rahukalam {
                    MuhurtTile(title: "Rahukalam", time: "\(r.start)-\(r.end)", isGood: false)
                }
                if let d = result.panchangam.durmuhurtam {
                    MuhurtTile(title: "Durmuhurtam", time: "\(d.start)-\(d.end)", isGood: false)
                }
            }
            .padding(.horizontal, 16)

            // Festivals
            if !result.panchangam.festivals.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Festivals")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    ForEach(result.panchangam.festivals.prefix(2)) { festival in
                        HStack {
                            Image(systemName: festival.is_ekadashi == true ? "moon.stars.fill" : "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(festival.is_ekadashi == true ? .orange : .yellow)
                            Text(festival.name_en)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            } else {
                Spacer()
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}

struct DataTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(12)
    }
}

struct DetailTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(10)
    }
}

struct TimeTile: View {
    let icon: String
    let title: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Text(time)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(10)
    }
}

struct MuhurtTile: View {
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: "#3C3C3E"))
        .cornerRadius(10)
    }
}

struct EmptyStateView: View {
    let onCalculate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange.opacity(0.6))
            Text("Panchang")
                .font(.system(size: 22, weight: .bold))
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
