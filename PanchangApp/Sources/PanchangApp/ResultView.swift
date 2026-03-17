import SwiftUI

struct ResultView: View {
    let result: PanchangResponse
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header Card - High Contrast Deep Space Look
                headerCard
                
                // Key Elements Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))], spacing: 24) {
                    infoCard(title: "Samvatsaram", value: result.panchangam.samvatsaram, icon: "sun.dust.fill", hue: Color(red: 1.0, green: 0.6, blue: 0.0))
                    infoCard(title: "Ayanam", value: result.panchangam.ayanam, icon: "arrow.up.arrow.down.circle.fill", hue: Color(red: 0.0, green: 0.9, blue: 0.9)) // Cyan Neon
                    infoCard(title: "Maasam", value: result.panchangam.maasam, icon: "moon.stars.fill", hue: Color(red: 0.7, green: 0.3, blue: 1.0)) // Purple Neon
                    infoCard(title: "Vaaram", value: result.panchangam.vaaram, icon: "calendar.day.timeline.left", hue: Color(red: 0.0, green: 1.0, blue: 0.5)) // Matrix Green
                }
                
                // Detailed Elements
                VStack(spacing: 0) {
                    // Tithi with optional festival indicator
                    tithiRow
                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)

                    // Next Tithi (conditional)
                    if let nextTithi = result.panchangam.next_tithi {
                        detailRow(title: "Next Tithi", value: "\(nextTithi.name) until \(nextTithi.ends_at)", icon: "moon.circle", iconColor: .orange)
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                    }

                    detailRow(title: "Nakshatram", value: result.panchangam.nakshatram, icon: "sparkles")

                    // Next Nakshatram (conditional)
                    if let nextNakshatram = result.panchangam.next_nakshatram {
                        detailRow(title: "Next Nakshatram", value: "\(nextNakshatram.name) until \(nextNakshatram.ends_at)", icon: "sparkles", iconColor: .orange)
                    }
                }
                .background(Color(red: 0.07, green: 0.07, blue: 0.07)) // Very dark grey, OLED friendly #121212
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .padding(40)
        }
        .background(Color.black.ignoresSafeArea())
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
                Color(red: 0.05, green: 0.05, blue: 0.08)
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
    
    // Tithi row with optional Ekadashi festival indicator
    private var tithiRow: some View {
        HStack(alignment: .top) {
            Label("Tithi", systemImage: "moon.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 150, alignment: .leading)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.panchangam.tithi)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white)

                // Show Ekadashi festival indicator
                if let ekadashi = result.panchangam.festivals.first(where: { $0.is_ekadashi == true }) {
                    Text("(Festival Day: \(ekadashi.name_en))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
            Spacer()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func infoCard(title: String, value: String, icon: String, hue: Color) -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [hue.opacity(0.2), hue.opacity(0.05)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle().stroke(hue.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(hue)
                    .shadow(color: hue.opacity(0.6), radius: 8, x: 0, y: 0) // Neon Glow effect
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1.5)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(24)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07)) // #121212
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
    
    private func detailRow(title: String, value: String, icon: String, iconColor: Color = .white.opacity(0.7)) -> some View {
        HStack(alignment: .center) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(iconColor)
                .frame(width: 150, alignment: .leading)
                .lineLimit(2)

            Text(value)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
            Spacer()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .fixedSize(horizontal: false, vertical: true)
    }
}
