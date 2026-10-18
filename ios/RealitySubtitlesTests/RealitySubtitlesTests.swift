import Foundation
import Testing
@testable import RealitySubtitles

struct RealitySubtitlesTests {
    @Test @MainActor func legacyAudioIsRemovedWithoutDeletingResultsOrOtherFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let savedDirectory = root.appendingPathComponent("BenchmarkRecordings")
        try FileManager.default.createDirectory(at: savedDirectory, withIntermediateDirectories: true)
        let legacyFiles = [root.appendingPathComponent("recording.m4a"),
                           root.appendingPathComponent("benchmark-next-number.txt"),
                           savedDirectory.appendingPathComponent("test01.m4a")]
        for url in legacyFiles { try Data([1, 2, 3]).write(to: url) }
        let unrelated = root.appendingPathComponent("notes.txt")
        try Data([4, 5]).write(to: unrelated)
        let store = BenchmarkStore(documentsDirectory: root)
        try store.appendResult(.init(modelName: "Tiny", text: "örnek", processingTime: 0.5),
                               audioURL: legacyFiles[0], audioDuration: 2)
        let csv = try Data(contentsOf: store.resultsURL)
        try store.refresh()
        try store.refresh() // Cleanup is safe on subsequent launches too.
        for url in legacyFiles + [savedDirectory] {
            #expect(!FileManager.default.fileExists(atPath: url.path))
        }
        #expect(try Data(contentsOf: unrelated) == Data([4, 5]))
        #expect(try Data(contentsOf: store.resultsURL) == csv)
        #expect(store.hasResults)
    }

    @Test @MainActor func csvPersistsWithoutRetainingAudio() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("temporary.m4a")
        let store = BenchmarkStore(documentsDirectory: root)
        let transcript = "Türkçe, \"merhaba\"\nyeni satır"
        try store.appendResult(.init(modelName: "Tiny", text: transcript, processingTime: 1.23456), audioURL: source, audioDuration: 2.5)
        let first = try Data(contentsOf: store.resultsURL)
        let csv = String(decoding: first, as: UTF8.self)
        #expect(csv.contains("\"2.500\",\"1.235\""))
        #expect(csv.contains("\"Türkçe, \"\"merhaba\"\"\nyeni satır\"\r\n"))
        try store.appendResult(.init(modelName: "Tiny", text: "örnek", processingTime: 0.5), audioURL: source, audioDuration: 2.5)
        #expect(try Data(contentsOf: store.resultsURL).starts(with: first))
        let reopened = BenchmarkStore(documentsDirectory: root)
        try reopened.refresh()
        #expect(reopened.hasResults)
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["benchmark-results.csv"])
    }

    @Test @MainActor func csvRetainsLatestTenIncludingMultilineResults() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BenchmarkStore(documentsDirectory: root)
        let header = "Model,Audio file,Audio duration (seconds),Processing time (seconds),Transcription\r\n"
        func row(_ index: Int) -> String {
            "\"Tiny\",\"test\(index).m4a\",\"2.000\",\"0.500\",\"Türkçe, \"\"merhaba\"\"\r\nsatır \(index)\"\r\n"
        }
        // Simulate a CSV from the previous version, before retention was enforced.
        try (header + (1...12).map(row).joined()).write(to: store.resultsURL, atomically: true, encoding: .utf8)
        try store.refresh()
        #expect(try String(contentsOf: store.resultsURL, encoding: .utf8) == header + (3...12).map(row).joined())
        try store.appendResult(
            .init(modelName: "Tiny", text: "Türkçe, \"merhaba\"\r\nsatır 13", processingTime: 0.5),
            audioURL: root.appendingPathComponent("test13.m4a"), audioDuration: 2
        )
        let expected = header + (4...13).map(row).joined()
        #expect(try String(contentsOf: store.resultsURL, encoding: .utf8) == expected)
        let reopened = BenchmarkStore(documentsDirectory: root)
        try reopened.refresh()
        #expect(try String(contentsOf: reopened.resultsURL, encoding: .utf8) == expected)
    }

}
