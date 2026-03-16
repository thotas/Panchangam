import SwiftUI

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var selectedLocation: LocationPreset = .hyderabad
    @State private var selectedSchool: SchoolPreset = .gantala
    
    @State private var panchangResult: PanchangResponse? = nil
    @State private var isLoading = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar for Controls - High Contrast Dark Profile
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.1) // #1A1A1A
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Settings")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.bottom, 5)
                            .shadow(color: .white.opacity(0.2), radius: 5, x: 0, y: 0)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Date")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            DatePicker(
                                "Date",
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .colorScheme(.dark)
                            .accentColor(.purple)
                            .background(Color(red: 0.05, green: 0.05, blue: 0.05))
                            .cornerRadius(12)
                            .onChange(of: selectedDate) { calculatePanchang() }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Location")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            Picker("Location", selection: $selectedLocation) {
                                ForEach(LocationPreset.allCases) { location in
                                    Text(location.displayName).tag(location)
                                }
                            }
                            .pickerStyle(.menu)
                            .colorScheme(.dark)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(red: 0.05, green: 0.05, blue: 0.05))
                            .cornerRadius(8)
                            .onChange(of: selectedLocation) { calculatePanchang() }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("School")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            Picker("School", selection: $selectedSchool) {
                                ForEach(SchoolPreset.allCases) { school in
                                    Text(school.displayName).tag(school)
                                }
                            }
                            .pickerStyle(.menu)
                            .colorScheme(.dark)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(red: 0.05, green: 0.05, blue: 0.05))
                            .cornerRadius(8)
                            .onChange(of: selectedSchool) { calculatePanchang() }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedDate = Date()
                            calculatePanchang()
                        }) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                Text("Select Today")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 350)
            
        } detail: {
            // Main Content Area - OLED Deep Black
            ZStack {
                Color.black // Deep OLED Black
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                        Text("Calculating celestial positions...")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else if let result = panchangResult {
                    ResultView(result: result)
                } else {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "moon.stars",
                        description: Text("Select a date and location to calculate the Panchangam.")
                    )
                    .foregroundColor(.gray)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            calculatePanchang()
        }
    }
    
    private func calculatePanchang() {
        isLoading = true
        let dateToCalc = selectedDate
        let locToCalc = selectedLocation
        let schoolToCalc = selectedSchool
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = PanchangEngine.calculate(
                date: dateToCalc,
                location: locToCalc,
                school: schoolToCalc
            )
            
            DispatchQueue.main.async {
                self.panchangResult = result
                self.isLoading = false
            }
        }
    }
}
