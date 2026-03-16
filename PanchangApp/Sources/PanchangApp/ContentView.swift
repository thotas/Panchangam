import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var selectedLocation: LocationPreset = .hyderabad
    @State private var selectedSchool: SchoolPreset = .gantala

    @State private var panchangResult: PankajamResponse? = nil
    @State private var isLoading = false

    @FocusState private var focusedSection: FocusedSection?

    enum FocusedSection: Hashable {
        case date, location, school
    }

    var body: some View {
        HSplitView {
            // Settings Sidebar
            settingsPanel
                .frame(minWidth: 280, idealWidth: 300, maxWidth: 320)

            // Main Content
            mainContent
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color(hex: "#0D0D0D"))
        .preferredColorScheme(.dark)
        .onAppear {
            calculatePanchang()
        }
        .onKeyPress(.leftArrow) {
            moveToPreviousField()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            moveToNextField()
            return .handled
        }
        .onKeyPress(.tab) {
            moveToNextField()
            return .handled
        }
    }

    // MARK: - Settings Panel
    private var settingsPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.orange)
                Text("Panchang")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(hex: "#161616"))

            Divider()
                .background(Color.white.opacity(0.1))

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Date Section
                    settingsSection(title: "DATE", icon: "calendar") {
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .focused($focusedSection, equals: .date)
                            .onChange(of: selectedDate) { _, _ in
                                calculatePanchang()
                            }
                    }

                    // Location Section
                    settingsSection(title: "LOCATION", icon: "location") {
                        Picker("", selection: $selectedLocation) {
                            ForEach(LocationPreset.allCases) { location in
                                Text(location.displayName).tag(location)
                            }
                        }
                        .labelsHidden()
                        .focused($focusedSection, equals: .location)
                        .onChange(of: selectedLocation) { _, _ in
                            calculatePanchang()
                        }
                    }

                    // School Section
                    settingsSection(title: "SCHOOL", icon: "book.closed") {
                        Picker("", selection: $selectedSchool) {
                            ForEach(SchoolPreset.allCases) { school in
                                Text(school.displayName).tag(school)
                            }
                        }
                        .labelsHidden()
                        .focused($focusedSection, equals: .school)
                        .onChange(of: selectedSchool) { _, _ in
                            calculatePanchang()
                        }
                    }

                    Spacer().frame(height: 20)

                    // Quick Actions
                    VStack(spacing: 12) {
                        quickActionButton(title: "Today", icon: "calendar.badge.clock", shortcut: "T") {
                            selectedDate = Date()
                            calculatePanchang()
                        }

                        quickActionButton(title: "Yesterday", icon: "chevron.left", shortcut: "Y") {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                            calculatePanchang()
                        }

                        quickActionButton(title: "Tomorrow", icon: "chevron.right", shortcut: "N") {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                            calculatePanchang()
                        }
                    }

                    // Keyboard Shortcuts Help
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keyboard Shortcuts")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.gray)
                            .textCase(.uppercase)
                            .tracking(1)

                        VStack(alignment: .leading, spacing: 4) {
                            shortcutRow("↑/↓", "Navigate fields")
                            shortcutRow("Tab", "Next field")
                            shortcutRow("T", "Today")
                            shortcutRow("Y", "Yesterday")
                            shortcutRow("N", "Tomorrow")
                            shortcutRow("⌘1-5", "Select location")
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(20)
            }
        }
        .background(Color(hex: "#121212"))
    }

    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.gray)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            content()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func quickActionButton(title: String, icon: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text(shortcut)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: "#1E1E1E"))
            .cornerRadius(8)
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func shortcutRow(_ key: String, _ action: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.orange.opacity(0.8))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(3)
            Text(action)
                .font(.system(size: 11))
                .foregroundStyle(.gray)
            Spacer()
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        Group {
            if isLoading {
                loadingView
            } else if let result = panchangResult {
                ResultView(result: result)
            } else {
                emptyView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0A0A0A"))
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
            Text("Calculating...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.gray)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars")
                .font(.system(size: 48))
                .foregroundStyle(.gray.opacity(0.5))
            Text("Select a date to view Panchang")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.gray)
        }
    }

    // MARK: - Actions
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

    private func moveToNextField() {
        switch focusedSection {
        case .date:
            focusedSection = .location
        case .location:
            focusedSection = .school
        case .school, .none:
            focusedSection = .date
        }
    }

    private func moveToPreviousField() {
        switch focusedSection {
        case .date:
            focusedSection = .school
        case .location:
            focusedSection = .date
        case .school, .none:
            focusedSection = .location
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
