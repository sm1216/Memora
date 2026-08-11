import Foundation
import ImageIO
import CoreLocation
import UIKit
import UniformTypeIdentifiers

/// One photo with EXIF-derived capture time and GPS (when present).
struct PhotoAssetMeta: Identifiable, Equatable {
    let id: UUID
    var imageData: Data
    var takenAt: Date?
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var placeName: String?
    var countryCode: String?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var hasGPS: Bool { latitude != nil && longitude != nil }
}

/// Reads date + GPS from image bytes (EXIF / GPS TIFF dictionaries) and reverse-geocodes.
enum PhotoMetadataService {

    // MARK: - Extract from image Data

    static func extract(from data: Data) -> (date: Date?, lat: Double?, lon: Double?, alt: Double?) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return (nil, nil, nil, nil)
        }
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return (nil, nil, nil, nil)
        }

        let date = parseDate(from: props)
        let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any]
        var lat = gps?[kCGImagePropertyGPSLatitude] as? Double
        var lon = gps?[kCGImagePropertyGPSLongitude] as? Double
        let alt = gps?[kCGImagePropertyGPSAltitude] as? Double

        if let latRef = gps?[kCGImagePropertyGPSLatitudeRef] as? String, latRef.uppercased() == "S", let v = lat {
            lat = -abs(v)
        }
        if let lonRef = gps?[kCGImagePropertyGPSLongitudeRef] as? String, lonRef.uppercased() == "W", let v = lon {
            lon = -abs(v)
        }

        // Some formats store GPS as nested numbers
        if lat == nil, let raw = gps?[kCGImagePropertyGPSLatitude] as? NSNumber {
            lat = raw.doubleValue
        }
        if lon == nil, let raw = gps?[kCGImagePropertyGPSLongitude] as? NSNumber {
            lon = raw.doubleValue
        }

        return (date, lat, lon, alt)
    }

    private static func parseDate(from props: [CFString: Any]) -> Date? {
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any]

        let candidates: [String?] = [
            exif?[kCGImagePropertyExifDateTimeOriginal] as? String,
            exif?[kCGImagePropertyExifDateTimeDigitized] as? String,
            tiff?[kCGImagePropertyTIFFDateTime] as? String
        ]

        let formatters: [DateFormatter] = {
            let f1 = DateFormatter()
            f1.locale = Locale(identifier: "en_US_POSIX")
            f1.dateFormat = "yyyy:MM:dd HH:mm:ss"
            let f2 = DateFormatter()
            f2.locale = Locale(identifier: "en_US_POSIX")
            f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let f3 = DateFormatter()
            f3.locale = Locale(identifier: "en_US_POSIX")
            f3.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return [f1, f2, f3]
        }()

        for raw in candidates {
            guard let s = raw, !s.isEmpty else { continue }
            for f in formatters {
                if let d = f.date(from: s) { return d }
            }
        }
        return nil
    }

    /// Compress JPEG for storage while keeping EXIF GPS/date when possible.
    static func compressPreservingMetadata(_ data: Data, quality: CGFloat = 0.78) -> Data {
        if let out = recompress(data, quality: quality) { return out }
        if let ui = UIImage(data: data), let jpeg = ui.jpegData(compressionQuality: quality) {
            return jpeg
        }
        return data
    }

    private static func recompress(_ data: Data, quality: CGFloat) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?
        let destData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            destData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }
        var outProps: [AnyHashable: Any] = [:]
        if let props = props as? [AnyHashable: Any] {
            outProps = props
        }
        outProps[kCGImageDestinationLossyCompressionQuality] = quality
        CGImageDestinationAddImage(dest, cgImage, outProps as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return destData as Data
    }

    // MARK: - Reverse geocode

    static func reverseGeocode(lat: Double, lon: Double) async -> (place: String, countryCode: String)? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        do {
            let marks = try await geocoder.reverseGeocodeLocation(location)
            guard let m = marks.first else { return nil }
            let city = m.locality ?? m.subLocality ?? m.administrativeArea
            let country = m.country
            var parts: [String] = []
            if let city { parts.append(city) }
            if let country { parts.append(country) }
            let place = parts.isEmpty ? (m.name ?? "Unknown place") : parts.joined(separator: ", ")
            let cc = m.isoCountryCode ?? "XX"
            return (place, cc)
        } catch {
            return nil
        }
    }

    // MARK: - Aggregate for a memory

    struct MemoryDraftMeta {
        var startDate: Date
        var endDate: Date
        var latitude: Double
        var longitude: Double
        var locationName: String
        var countryCode: String
        var titleSuggestion: String
        var steps: [MemoryStep]
        var photosWithGPS: Int
        var photosWithDate: Int
    }

    static func buildDraft(from photos: [PhotoAssetMeta]) async -> MemoryDraftMeta {
        let dates = photos.compactMap(\.takenAt).sorted()
        let start = dates.first ?? Date()
        let end = dates.last ?? start

        // Primary location: median of GPS samples, or first available
        let gpsPhotos = photos.filter(\.hasGPS)
        var lat = 0.0
        var lon = 0.0
        if !gpsPhotos.isEmpty {
            let lats = gpsPhotos.compactMap(\.latitude).sorted()
            let lons = gpsPhotos.compactMap(\.longitude).sorted()
            lat = lats[lats.count / 2]
            lon = lons[lons.count / 2]
        }

        var locationName = "Unknown place"
        var countryCode = "XX"
        if !gpsPhotos.isEmpty {
            if let geo = await reverseGeocode(lat: lat, lon: lon) {
                locationName = geo.place
                countryCode = geo.countryCode
            } else {
                locationName = String(format: "%.4f, %.4f", lat, lon)
            }
        }

        // Reverse-geocode per photo for step titles (limited concurrency)
        var enriched = photos
        await withTaskGroup(of: (UUID, String?, String?).self) { group in
            for p in photos where p.hasGPS && p.placeName == nil {
                group.addTask {
                    guard let la = p.latitude, let lo = p.longitude else { return (p.id, nil, nil) }
                    if let g = await reverseGeocode(lat: la, lon: lo) {
                        return (p.id, g.place, g.countryCode)
                    }
                    return (p.id, nil, nil)
                }
            }
            for await (id, place, cc) in group {
                if let idx = enriched.firstIndex(where: { $0.id == id }) {
                    enriched[idx].placeName = place
                    enriched[idx].countryCode = cc
                }
            }
        }

        // Group into steps by calendar day, then by place cluster
        let cal = Calendar.current
        let sorted = enriched.enumerated().sorted { a, b in
            let da = a.element.takenAt ?? .distantPast
            let db = b.element.takenAt ?? .distantPast
            return da < db
        }

        var dayBuckets: [(day: DateComponents, items: [(index: Int, meta: PhotoAssetMeta)])] = []
        for (idx, meta) in sorted {
            let day = cal.dateComponents([.year, .month, .day], from: meta.takenAt ?? start)
            if let last = dayBuckets.last, last.day == day {
                dayBuckets[dayBuckets.count - 1].items.append((idx, meta))
            } else {
                dayBuckets.append((day, [(idx, meta)]))
            }
        }

        var steps: [MemoryStep] = []
        for (dayIndex, bucket) in dayBuckets.enumerated() {
            // Split day by place name changes
            var clusters: [(place: String, indices: [Int], lat: Double?, lon: Double?)] = []
            for item in bucket.items {
                let place = item.meta.placeName
                    ?? (item.meta.hasGPS
                        ? String(format: "%.3f, %.3f", item.meta.latitude!, item.meta.longitude!)
                        : locationName)
                if let last = clusters.last, last.place == place {
                    clusters[clusters.count - 1].indices.append(item.index)
                } else {
                    clusters.append((place, [item.index], item.meta.latitude, item.meta.longitude))
                }
            }

            if clusters.isEmpty {
                continue
            }

            if clusters.count == 1 {
                let c = clusters[0]
                let dayDate = cal.date(from: bucket.day) ?? start
                let title = dayTitle(dayIndex: dayIndex, date: dayDate, place: c.place)
                steps.append(MemoryStep(
                    title: title,
                    note: "",
                    latitude: c.lat ?? lat,
                    longitude: c.lon ?? lon,
                    placeName: c.place,
                    dayIndex: dayIndex,
                    photoIndices: c.indices,
                    emoji: ""
                ))
            } else {
                for (ci, c) in clusters.enumerated() {
                    steps.append(MemoryStep(
                        title: c.place,
                        note: "Stop \(ci + 1)",
                        latitude: c.lat,
                        longitude: c.lon,
                        placeName: c.place,
                        dayIndex: dayIndex,
                        photoIndices: c.indices,
                        emoji: ""
                    ))
                }
            }
        }

        if steps.isEmpty {
            steps = [
                MemoryStep(
                    title: locationName,
                    placeName: locationName,
                    dayIndex: 0,
                    photoIndices: Array(photos.indices),
                    emoji: ""
                )
            ]
        }

        let city = locationName.split(separator: ",").first.map(String.init) ?? locationName
        let year = cal.component(.year, from: start)
        let titleSuggestion: String
        if gpsPhotos.isEmpty && dates.isEmpty {
            titleSuggestion = "New memory"
        } else if gpsPhotos.isEmpty {
            titleSuggestion = "Trip \(year)"
        } else {
            titleSuggestion = "Trip to \(city)"
        }

        return MemoryDraftMeta(
            startDate: start,
            endDate: end,
            latitude: lat,
            longitude: lon,
            locationName: locationName,
            countryCode: countryCode,
            titleSuggestion: titleSuggestion,
            steps: steps,
            photosWithGPS: gpsPhotos.count,
            photosWithDate: dates.count
        )
    }

    private static func dayTitle(dayIndex: Int, date: Date, place: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let day = f.string(from: date)
        let shortPlace = place.split(separator: ",").first.map(String.init) ?? place
        return "\(day) · \(shortPlace)"
    }
}
