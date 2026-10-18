import Foundation
import Combine

@MainActor
final class BenchmarkStore: ObservableObject {
    static let resultLimit = 10
    private static let csvHeader = "Model,Audio file,Audio duration (seconds),Processing time (seconds),Transcription"
    @Published private(set) var hasResults = false

    let resultsURL: URL
    private let recordingsDirectory: URL
    private let sequenceURL: URL
    private let legacyRecordingURL: URL
    private let files = FileManager.default

    init(documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        recordingsDirectory = documentsDirectory.appendingPathComponent("BenchmarkRecordings", isDirectory: true)
        resultsURL = documentsDirectory.appendingPathComponent("benchmark-results.csv")
        legacyRecordingURL = documentsDirectory.appendingPathComponent("recording.m4a")
        sequenceURL = documentsDirectory.appendingPathComponent("benchmark-next-number.txt")
    }

    func refresh() throws {
        // Remove audio retained by earlier app versions, keeping CSV results.
        for url in [recordingsDirectory, legacyRecordingURL, sequenceURL] {
            if files.fileExists(atPath: url.path) {
                try files.removeItem(at: url)
            }
        }
        hasResults = files.fileExists(atPath: resultsURL.path)
        if hasResults {
            let rows = try readCSVRows()
            if rows.count > Self.resultLimit + 1 {
                try writeResults(rows)
            }
        }
    }

    func appendResult(_ result: TranscriptionMeasurement, audioURL: URL, audioDuration: Double) throws {
        let duration = Self.seconds(audioDuration)
        let processing = Self.seconds(result.processingTime)
        print("""
        Model: \(result.modelName)
        Audio file: \(audioURL.lastPathComponent)
        Audio duration: \(duration) seconds
        Processing time: \(processing) seconds
        Transcription: \(result.text)
        """)
        let row = [result.modelName, audioURL.lastPathComponent, duration, processing, result.text]
            .map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
            .joined(separator: ",")
        var rows = try readCSVRows()
        if rows.isEmpty { rows = [Self.csvHeader] }
        rows.append(row)
        try writeResults(rows)
        hasResults = true
    }

    // Newlines inside quoted transcription fields belong to the same CSV record.
    private func readCSVRows() throws -> [String] {
        guard files.fileExists(atPath: resultsURL.path) else { return [] }
        let csv = try String(contentsOf: resultsURL, encoding: .utf8)
        var rows: [String] = []
        var row = ""
        var quoted = false
        for character in csv {
            if character == "\"" { quoted.toggle() }
            if !quoted && (character == "\n" || character == "\r\n" || character == "\r") {
                if !row.isEmpty { rows.append(row) }
                row = ""
            } else {
                row.append(character)
            }
        }
        guard !quoted else { throw CocoaError(.fileReadCorruptFile) }
        if !row.isEmpty { rows.append(row) }
        return rows
    }

    private func writeResults(_ rows: [String]) throws {
        let header = rows.first ?? Self.csvHeader
        let retained = [header] + Array(rows.dropFirst().suffix(Self.resultLimit))
        try (retained.joined(separator: "\r\n") + "\r\n")
            .write(to: resultsURL, atomically: true, encoding: .utf8)
    }

    static func seconds(_ value: Double) -> String {
        String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}
