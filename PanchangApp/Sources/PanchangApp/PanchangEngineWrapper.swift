import Foundation
import panchang_engine

public enum LocationPreset: Int32, CaseIterable, Identifiable {
    case hyderabad = 0
    case dublinCa = 1
    case houstonTx = 2
    case newJersey = 3
    case philadelphia = 4
    
    public var id: Self { self }
    
    public var displayName: String {
        switch self {
        case .hyderabad: return "Hyderabad"
        case .dublinCa: return "Dublin, CA, USA"
        case .houstonTx: return "Houston, TX, USA"
        case .newJersey: return "New Jersey, USA"
        case .philadelphia: return "Philadelphia, USA"
        }
    }
}

public enum SchoolPreset: Int32, CaseIterable, Identifiable {
    case gantala = 0
    case nemani = 1
    case ttd = 2
    
    public var id: Self { self }
    
    public var displayName: String {
        switch self {
        case .gantala: return "Gantala"
        case .nemani: return "Nemani"
        case .ttd: return "TTD"
        }
    }
}

// Codable models mapping to Rust JSON
public struct HeaderOut: Codable {
    public let location: String
    public let coordinates: String
    public let timezone: String
    public let school: String
}

public struct PanchangamOut: Codable {
    public let samvatsaram: String
    public let ayanam: String
    public let maasam: String
    public let vaaram: String
    public let tithi: String
    public let nakshatram: String
}

public struct FestivalOut: Codable, Hashable {
    public let en: String
    public let te: String
}

public struct PanchangResponse: Codable {
    public let header: HeaderOut
    public let panchangam: PanchangamOut
    public let festivals: [FestivalOut]
}

public class PanchangEngine {
    
    public static func calculate(date: Date, location: LocationPreset, school: SchoolPreset) -> PanchangResponse? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard let year = components.year, 
              let month = components.month, 
              let day = components.day else { return nil }
        
        // Pass integers into Rust FFI
        guard let cStringPtr = get_panchang_json(
            Int32(year),
            Int32(month),
            Int32(day),
            location.rawValue,
            school.rawValue
        ) else {
            print("Engine returned null pointer")
            return nil
        }
        
        // Ensure Rust frees the memory once we're done
        defer {
            free_json_string(cStringPtr)
        }
        
        let jsonString = String(cString: cStringPtr)
        
        guard let data = jsonString.data(using: .utf8) else {
            print("Failed to convert CString to Data")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(PanchangResponse.self, from: data)
            return response
        } catch {
            print("Failed to decode JSON from Rust: \(error)")
            print("JSON Content was: \(jsonString)")
            return nil
        }
    }
}
