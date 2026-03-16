import SwiftUI

struct ResultView: View {
    let result: PankajamResponse

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header Card
                headerCard

                // Key Elements Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 20) {
                    infoCard(title: "Samvatsaram", value: result.panchangam.samvatsaram, icon: "sun.dust.fill", hue: Color(hex: "#FF9933"))
                    infoCard(title: "Ayanam", value: result.panchangam.ayanam, icon: "arrow.up.arrow.down.circle.fill", hue: Color(hex: "#00E5FF"))
                    infoCard(title: "Maasam", value: result.panchangam.maasam, icon: "moon.stars.fill", hue: Color(hex: "#B366FF"))
                    infoCard(title: "Vaaram", value: result.panchangam.vaaram, icon: "calendar.day.timeline.left", hue: Color(hex: "#00FF80"))
                    infoCard(title: "Paksha", value: result.panchangam.paksha, icon: "moonphase.first.quarter", hue: Color(hex: "#FF6B6B"))
                }

                // Detailed Elements
                VStack(spacing: 0) {
                    detailRow(title: "Tithi", value: result.panchangam.tithi, icon: "moon.circle.fill")
                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                    detailRow(title: "Nakshatram", value: result.panchangam.nakshatram, icon: "sparkles")
                }
                .background(Color(hex: "#121212"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

                // Sunrise & Sunset
                if let ss = result.panchangam.sunrise_sunset {
                    HStack(spacing: 20) {
                        timedInfoCard(title: "Sunrise", value: ss.sunrise, icon: "sunrise.fill", hue: Color(hex: "#FFB74D"))
                        timedInfoCard(title: "Sunset", value: ss.sunset, icon: "sunset.fill", hue: Color(hex: "#FF8A65"))
                    }
                }

                // Auspicious & Inauspicious Times
                if result.panchangam.varjyam != nil || result.panchangam.durmuhurtam != nil || result.panchangam.rahukalam != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Muhurtam")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(1)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                            if let v = result.panchangam.varjyam {
                                muhurtCard(title: "Varjyam", time: "\(v.start) - \(v.end)", icon: "star.fill", hue: Color(hex: "#4CAF50"))
                            }
                            if let d = result.panchangam.durmuhurtam {
                                muhurtCard(title: "Durmuhurtam", time: "\(d.start) - \(d.end)", icon: "exclamationmark.triangle.fill", hue: Color(hex: "#FF5252"))
                            }
                            if let r = result.panchangam.rahukalam {
                                muhurtCard(title: "Rahukalam", time: "\(r.start) - \(r.end)", icon: "clock.badge.exclamationmark.fill", hue: Color(hex: "#FFA726"))
                            }
                        }
                    }
                }

                // Festivals
                if !result.panchangam.festivals.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Festivals")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(1)

                        VStack(spacing: 8) {
                            ForEach(result.panchangam.festivals) { festival in
                                festivalRow(festival: festival)
                            }
                        }
                    }
                }
            }
            .padding(40)
        }
        .background(Color(hex: "#0A0A0A").ignoresSafeArea())
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            Text(result.header.location)
                .font(.system(size: 38, weight: .heavy, design: .default))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: 0)

            HStack(spacing: 24) {
                Label(result.header.coordinates, systemImage: "location.fill")
                Label(result.header.timezone, systemImage: "clock.fill")
                Label(result.header.school, systemImage: "book.closed.fill")
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
        .background(
            ZStack {
                Color(hex: "#0D0D14")
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.15), Color.clear]), startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.purple.opacity(0.1), radius: 20, x: 0, y: 10)
    }

    private func infoCard(title: String, value: String, icon: String, hue: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [hue.opacity(0.2), hue.opacity(0.05)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle().stroke(hue.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(hue)
                    .shadow(color: hue.opacity(0.6), radius: 6, x: 0, y: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1.2)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "#121212"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private func timedInfoCard(title: String, value: String, icon: String, hue: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(hue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#121212"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func muhurtCard(title: String, time: String, icon: String, hue: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(hue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(time)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(hex: "#1A1A1A"))
        .cornerRadius(10)
    }

    private func festivalRow(festival: FestivalOut) -> some View {
        HStack(spacing: 12) {
            if festival.is_ekadashi == true {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
            }

            Text(festival.name_en)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            if festival.is_ekadashi == true {
                Text("Ekadashi")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#141414"))
        .cornerRadius(10)
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 150, alignment: .leading)

            Text(value)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview
