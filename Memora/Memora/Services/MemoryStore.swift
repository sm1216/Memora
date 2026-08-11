import Foundation
import SwiftUI
import PhotosUI

@MainActor
final class MemoryStore: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var tags: [NFCTagItem] = []

    private let memoriesKey = "memora.memories.v1"
    private let tagsKey = "memora.tags.v1"

    init() {
        load()
        if memories.isEmpty {
            seed()
        }
    }

    func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = UserDefaults.standard.data(forKey: memoriesKey),
           let decoded = try? decoder.decode([Memory].self, from: data) {
            memories = decoded
        }
        if let data = UserDefaults.standard.data(forKey: tagsKey),
           let decoded = try? decoder.decode([NFCTagItem].self, from: data) {
            tags = decoded
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(memories) {
            UserDefaults.standard.set(data, forKey: memoriesKey)
        }
        if let data = try? encoder.encode(tags) {
            UserDefaults.standard.set(data, forKey: tagsKey)
        }
    }

    func seed() {
        memories = SampleData.memories()
        tags = SampleData.tags(for: memories)
        // wire first two tags
        if tags.count >= 2, memories.count >= 2 {
            tags[0].memoryId = memories[0].id
            tags[0].shortId = memories[0].shortId
            tags[0].isConnected = true
            memories[0].tagIds = [tags[0].id]
            tags[1].memoryId = memories[1].id
            tags[1].shortId = memories[1].shortId
            tags[1].isConnected = true
            memories[1].tagIds = [tags[1].id]
        }
        save()
    }

    func resetDemoData() {
        seed()
    }

    func memory(id: UUID) -> Memory? {
        memories.first { $0.id == id }
    }

    func memory(shortId: String) -> Memory? {
        memories.first { $0.shortId.caseInsensitiveCompare(shortId) == .orderedSame }
    }

    func upsert(_ memory: Memory) {
        if let idx = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[idx] = memory
        } else {
            memories.insert(memory, at: 0)
        }
        save()
    }

    func delete(_ memory: Memory) {
        memories.removeAll { $0.id == memory.id }
        for i in tags.indices where tags[i].memoryId == memory.id {
            tags[i].memoryId = nil
            tags[i].shortId = nil
            tags[i].isConnected = false
        }
        save()
    }

    func years() -> [Int] {
        Array(Set(memories.map(\.year))).sorted(by: >)
    }

    func memories(for year: Int?) -> [Memory] {
        let list = memories.sorted { $0.startDate > $1.startDate }
        guard let year else { return list }
        return list.filter { $0.year == year }
    }

    // MARK: - Tags

    func addTag(name: String) {
        tags.append(NFCTagItem(id: UUID(), name: name, memoryId: nil, shortId: nil, lastWrittenAt: nil, isConnected: false))
        save()
    }

    func link(tag: NFCTagItem, to memory: Memory) {
        guard let idx = tags.firstIndex(where: { $0.id == tag.id }) else { return }
        // unlink previous
        if let oldId = tags[idx].memoryId, let mIdx = memories.firstIndex(where: { $0.id == oldId }) {
            memories[mIdx].tagIds.removeAll { $0 == tag.id }
        }
        tags[idx].memoryId = memory.id
        tags[idx].shortId = memory.shortId
        tags[idx].isConnected = true
        tags[idx].lastWrittenAt = Date()
        if let mIdx = memories.firstIndex(where: { $0.id == memory.id }) {
            if !memories[mIdx].tagIds.contains(tag.id) {
                memories[mIdx].tagIds.append(tag.id)
            }
        }
        save()
    }

    func unlink(tag: NFCTagItem) {
        guard let idx = tags.firstIndex(where: { $0.id == tag.id }) else { return }
        if let mid = tags[idx].memoryId, let mIdx = memories.firstIndex(where: { $0.id == mid }) {
            memories[mIdx].tagIds.removeAll { $0 == tag.id }
        }
        tags[idx].memoryId = nil
        tags[idx].shortId = nil
        tags[idx].isConnected = false
        save()
    }

    func markWritten(tagId: UUID) {
        guard let idx = tags.firstIndex(where: { $0.id == tagId }) else { return }
        tags[idx].lastWrittenAt = Date()
        tags[idx].isConnected = tags[idx].memoryId != nil
        save()
    }
}
