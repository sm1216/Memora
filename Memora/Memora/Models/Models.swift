import Foundation
import SwiftUI
import CoreLocation

// MARK: - User

struct AppUser: Codable, Equatable, Identifiable {
    var id: String
    var displayName: String
    var email: String?
    var photoURL: String?
    var provider: AuthProvider
    var createdAt: Date

    enum AuthProvider: String, Codable {
        case apple, google, guest, email
    }
}

// MARK: - Memory

struct Memory: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var shortId: String
    var title: String
    var story: String
    var locationName: String
    var countryCode: String
    var latitude: Double
    var longitude: Double
    var startDate: Date
    var endDate: Date
    var isPublic: Bool
    var coverImageData: Data?
    var photoData: [Data]
    var steps: [MemoryStep]
    var tagIds: [UUID]
    var collaboratorNames: [String]
    var createdAt: Date
    var updatedAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var year: Int {
        Calendar.current.component(.year, from: startDate)
    }

    var dateRangeText: String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy"
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return f.string(from: startDate)
        }
        return "\(f.string(from: startDate)) · \(f.string(from: endDate))"
    }

    var shareURL: URL {
        // Prefer deep link; NFC also accepts https host + /m/SHORT when you host a page
        deepLinkURL
    }

    /// URL written to NFC tags (absolute https when possible)
    var nfcURL: URL {
        URL(string: "\(AppConfig.urlScheme)://m/\(shortId)")!
    }

    var deepLinkURL: URL {
        URL(string: "\(AppConfig.urlScheme)://m/\(shortId)")!
    }

    static func makeShortId() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

struct MemoryStep: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var note: String
    var latitude: Double?
    var longitude: Double?
    var placeName: String?
    var dayIndex: Int
    var photoIndices: [Int]
    var emoji: String

    init(
        id: UUID = UUID(),
        title: String,
        note: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        placeName: String? = nil,
        dayIndex: Int = 0,
        photoIndices: [Int] = [],
        emoji: String = ""
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
        self.dayIndex = dayIndex
        self.photoIndices = photoIndices
        self.emoji = emoji
    }
}

// MARK: - NFC Tag

struct NFCTagItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var memoryId: UUID?
    var shortId: String?
    var lastWrittenAt: Date?
    var isConnected: Bool

    var statusText: String {
        isConnected ? "Connected" : "Unlinked"
    }
}

// MARK: - Sample seed

enum SampleData {
    static func memories() -> [Memory] {
        let cal = Calendar.current
        func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
            cal.date(from: DateComponents(year: y, month: m, day: d)) ?? Date()
        }

        return [
            Memory(
                id: UUID(),
                shortId: "ROME26",
                title: "Our First Trip",
                story: "Cobblestones, gelato, and golden hour at the Colosseum.",
                locationName: "Rome, Italy",
                countryCode: "IT",
                latitude: 41.9028,
                longitude: 12.4964,
                startDate: date(2024, 6, 12),
                endDate: date(2024, 6, 18),
                isPublic: true,
                coverImageData: nil,
                photoData: [],
                steps: [
                    MemoryStep(title: "Colosseum", placeName: "Colosseum", dayIndex: 0, emoji: ""),
                    MemoryStep(title: "Trastevere dinner", placeName: "Trastevere", dayIndex: 1, emoji: "")
                ],
                tagIds: [],
                collaboratorNames: ["You", "Alex"],
                createdAt: date(2024, 6, 20),
                updatedAt: date(2024, 6, 20)
            ),
            Memory(
                id: UUID(),
                shortId: "LISB25",
                title: "Summer Festival",
                story: "I still feel the warmth of the day whenever I think back — the music, the crowd, the golden light in the evening.",
                locationName: "Lisbon, Portugal",
                countryCode: "PT",
                latitude: 38.7223,
                longitude: -9.1393,
                startDate: date(2025, 6, 28),
                endDate: date(2025, 7, 7),
                isPublic: true,
                coverImageData: nil,
                photoData: [],
                steps: [
                    MemoryStep(title: "Beach Day", placeName: "Cascais", dayIndex: 0, emoji: ""),
                    MemoryStep(title: "Night market", placeName: "LxFactory", dayIndex: 2, emoji: "")
                ],
                tagIds: [],
                collaboratorNames: ["You"],
                createdAt: date(2025, 7, 8),
                updatedAt: date(2025, 7, 8)
            ),
            Memory(
                id: UUID(),
                shortId: "SANTA",
                title: "Hiking Trip near Santa Marta",
                story: "Trail dust, ocean air, and the best views of the coast.",
                locationName: "Santa Marta, Colombia",
                countryCode: "CO",
                latitude: 11.2408,
                longitude: -74.1990,
                startDate: date(2025, 4, 17),
                endDate: date(2025, 4, 23),
                isPublic: false,
                coverImageData: nil,
                photoData: [],
                steps: [
                    MemoryStep(title: "Start", placeName: "Santa Marta", dayIndex: 0, emoji: ""),
                    MemoryStep(title: "Summit", placeName: "Coast trail", dayIndex: 1, emoji: "")
                ],
                tagIds: [],
                collaboratorNames: ["You", "Sam"],
                createdAt: date(2025, 4, 24),
                updatedAt: date(2025, 4, 24)
            ),
            Memory(
                id: UUID(),
                shortId: "KYOTO",
                title: "Kyoto Temples",
                story: "Quiet mornings in bamboo light.",
                locationName: "Kyoto, Japan",
                countryCode: "JP",
                latitude: 35.0116,
                longitude: 135.7681,
                startDate: date(2023, 10, 3),
                endDate: date(2023, 10, 10),
                isPublic: true,
                coverImageData: nil,
                photoData: [],
                steps: [],
                tagIds: [],
                collaboratorNames: ["You"],
                createdAt: date(2023, 10, 11),
                updatedAt: date(2023, 10, 11)
            ),
            Memory(
                id: UUID(),
                shortId: "COFFEE",
                title: "Coffee Date",
                story: "Rainy afternoon, warm cups.",
                locationName: "Berlin, Germany",
                countryCode: "DE",
                latitude: 52.5200,
                longitude: 13.4050,
                startDate: date(2022, 11, 14),
                endDate: date(2022, 11, 14),
                isPublic: false,
                coverImageData: nil,
                photoData: [],
                steps: [],
                tagIds: [],
                collaboratorNames: ["You"],
                createdAt: date(2022, 11, 14),
                updatedAt: date(2022, 11, 14)
            )
        ]
    }

    static func tags(for memories: [Memory]) -> [NFCTagItem] {
        guard let first = memories.first, let second = memories.dropFirst().first else {
            return [
                NFCTagItem(id: UUID(), name: "Fridge magnet", memoryId: nil, shortId: nil, lastWrittenAt: nil, isConnected: false)
            ]
        }
        return [
            NFCTagItem(
                id: UUID(),
                name: "Rome souvenir",
                memoryId: first.id,
                shortId: first.shortId,
                lastWrittenAt: Date().addingTimeInterval(-86400 * 10),
                isConnected: true
            ),
            NFCTagItem(
                id: UUID(),
                name: "Lisbon pin",
                memoryId: second.id,
                shortId: second.shortId,
                lastWrittenAt: Date().addingTimeInterval(-86400 * 3),
                isConnected: true
            ),
            NFCTagItem(
                id: UUID(),
                name: "Blank sticker #3",
                memoryId: nil,
                shortId: nil,
                lastWrittenAt: nil,
                isConnected: false
            )
        ]
    }
}
