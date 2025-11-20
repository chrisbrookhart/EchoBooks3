//
//  AudioSegment.swift
//  EchoBooks3
//
//  Represents a single audio segment for a sentence with timing information.
//

import Foundation

/// Represents an audio segment for a sentence, including timing and file path information.
struct AudioSegment: Codable, Equatable {
    /// The sentence ID this segment corresponds to.
    let sentenceId: String
    
    /// The start time of this segment in milliseconds within the audio file.
    let startMs: Int
    
    /// The duration of this segment in milliseconds.
    let durationMs: Int
    
    /// The path to the audio file (relative to the book's root directory).
    let wavPath: String
    
    /// The sample rate of the audio file in Hz.
    let sampleRateHz: Int?
    
    enum CodingKeys: String, CodingKey {
        case sentenceId = "sentence_id"
        case startMs = "start_ms"
        case durationMs = "duration_ms"
        case wavPath = "wav_path"
        case sampleRateHz = "sample_rate_hz"
    }
    
    /// Convenience initializer for creating an AudioSegment from content_index.json format.
    /// - Parameters:
    ///   - sentenceId: The sentence ID
    ///   - offsetMs: The offset in milliseconds (from content_index.json)
    ///   - durationMs: The duration in milliseconds
    ///   - wavPath: The path to the audio file
    ///   - sampleRateHz: Optional sample rate
    init(sentenceId: String, offsetMs: Int, durationMs: Int, wavPath: String, sampleRateHz: Int? = nil) {
        self.sentenceId = sentenceId
        self.startMs = offsetMs
        self.durationMs = durationMs
        self.wavPath = wavPath
        self.sampleRateHz = sampleRateHz
    }
}
