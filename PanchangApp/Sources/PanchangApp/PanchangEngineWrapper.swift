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

public struct SunriseSunsetOut: Codable {
    public let sunrise: String
    public let sunset: String
}

public struct TimedResultOut: Codable {
    public let start: String
    public let end: String
}

public struct TimedInfoOut: Codable {
    public let name: String
    public let ends_at: String
}

public struct FestivalOut: Codable, Hashable, Identifiable {
    public let name_en: String
    public let name_te: String
    public let is_ekadashi: Bool?

    public var id: String { name_en }
}

public struct PanchangamOut: Codable {
    public let samvatsaram: String
    public let ayanam: String
    public let maasam: String
    public let vaaram: String
    public let tithi: String
    public let paksha: String
    public let nakshatram: String
    public let next_tithi: TimedInfoOut?
    public let next_nakshatram: TimedInfoOut?
    public let sunrise_sunset: SunriseSunsetOut?
    public let varjyam: TimedResultOut?
    public let durmuhurtam: TimedResultOut?
    public let rahukalam: TimedResultOut?
    public let festivals: [FestivalOut]
}

public struct PankajamResponse: Codable {
    public let header: HeaderOut
    public let panchangam: PanchangamOut
}

// Legacy alias for compatibility
public typealias PanchangResponse = PankajamResponse

public class PankajamEngine {

    public static func calculate(date: Date, location: LocationPreset, school: SchoolPreset) -> PankajamResponse? {
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
            let response = try decoder.decode(PankajamResponse.self, from: data)
            return response
        } catch {
            print("Failed to decode JSON from Rust: \(error)")
            print("JSON Content was: \(jsonString)")
            return nil
        }
    }
}

// Legacy alias for compatibility
public typealias PanchangEngine = PankajamEngine
