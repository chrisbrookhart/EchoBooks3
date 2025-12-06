//
//  AudioMappingLoader.swift
//
//  Service for loading audio mapping information from content_index.json and playback_map.json.
//  Provides access to audio segments and chunk-based playback information.
//

import Foundation

/// Service for loading and accessing audio mapping information.
/// Handles both sentence-level (content_index.json) and chunk-level (playback_map.json) audio mappings.
class AudioMappingLoader {
    
    // MARK: - Properties
    
    /// The book code (e.g., "CLOCK")
    let bookCode: String
    
    /// The root directory path for this book in the bundle (e.g., "CLOCK_book")
    private var bookRootPath: String {
        "\(bookCode)_book"
    }
    
    // MARK: - Cached Data
    
    private var cachedContentIndex: ContentIndex?
    private var cachedPlaybackMap: PlaybackMap?
    
    // MARK: - Initialization
    
    /// Initialize an AudioMappingLoader for a specific book.
    /// - Parameter bookCode: The book code (e.g., "CLOCK")
    init(bookCode: String) {
        self.bookCode = bookCode
    }
    
    // MARK: - File Resource Helper
    
    /// Attempts to find a resource using FileManager as fallback
    private func findResourceWithFileManager(name: String, extension ext: String, subdirectory: String) -> URL? {
        // First try Bundle.main.url with Books prefix (works if files are properly registered)
        if let url = Bundle.main.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "Books/\(bookRootPath)/\(subdirectory)"
        ) {
            return url
        }
        
        // Try without Books prefix
        if let url = Bundle.main.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "\(bookRootPath)/\(subdirectory)"
        ) {
            return url
        }
        
        // Fallback: Use FileManager to search in Books folder
        guard let resourcePath = Bundle.main.resourcePath else {
            return nil
        }
        
        let fileManager = FileManager.default
        let booksPath = (resourcePath as NSString).appendingPathComponent("Books")
        let searchPath = (booksPath as NSString).appendingPathComponent("\(bookRootPath)/\(subdirectory)")
        let filePath = (searchPath as NSString).appendingPathComponent("\(name).\(ext)")
        
        if fileManager.fileExists(atPath: filePath) {
            return URL(fileURLWithPath: filePath)
        }
        
        return nil
    }
    
    // MARK: - Content Index Loading
    
    /// Loads the content index from app/content_index.json
    /// - Returns: ContentIndex dictionary mapping sentence IDs to audio information
    func loadContentIndex() throws -> ContentIndex {
        if let cached = cachedContentIndex {
            return cached
        }
        
        guard let url = findResourceWithFileManager(name: "content_index", extension: "json", subdirectory: "app") else {
            throw AudioMappingLoaderError.fileNotFound("app/content_index.json")
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let contentIndex = try decoder.decode(ContentIndex.self, from: data)
        
        cachedContentIndex = contentIndex
        return contentIndex
    }
    
    // MARK: - Playback Map Loading
    
    /// Loads the playback map from app/playback_map.json
    /// - Returns: PlaybackMap dictionary mapping chunk IDs to playback information
    func loadPlaybackMap() throws -> PlaybackMap {
        if let cached = cachedPlaybackMap {
            return cached
        }
        
        guard let url = findResourceWithFileManager(name: "playback_map", extension: "json", subdirectory: "app") else {
            throw AudioMappingLoaderError.fileNotFound("app/playback_map.json")
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let playbackMap = try decoder.decode(PlaybackMap.self, from: data)
        
        cachedPlaybackMap = playbackMap
        return playbackMap
    }
    
    // MARK: - Audio Segment Access
    
    /// Gets an AudioSegment for a specific sentence and language.
    /// - Parameters:
    ///   - sentenceId: The sentence ID (e.g., "s000001")
    ///   - languageCode: The language code (e.g., "en", "en-US", "es", "es-ES")
    /// - Returns: AudioSegment if found, nil otherwise
    func audioSegment(for sentenceId: String, languageCode: String) throws -> AudioSegment? {
        let contentIndex = try loadContentIndex()
        
        guard let entry = contentIndex[sentenceId] else {
            return nil
        }
        
        let normalizedLang = normalizeLanguageCode(languageCode)
        guard let audioInfo = entry.audioInfo(for: normalizedLang) else {
            return nil
        }
        
        return AudioSegment(
            sentenceId: sentenceId,
            offsetMs: audioInfo.offsetMs,
            durationMs: audioInfo.durationMs,
            audioPath: audioInfo.audioPath,
            sampleRateHz: audioInfo.sampleRateHz
        )
    }
    
    /// Gets all audio segments for a specific language.
    /// - Parameter languageCode: The language code
    /// - Returns: Dictionary mapping sentence IDs to AudioSegments
    func audioSegments(for languageCode: String) throws -> [String: AudioSegment] {
        let contentIndex = try loadContentIndex()
        let normalizedLang = normalizeLanguageCode(languageCode)
        
        var segments: [String: AudioSegment] = [:]
        
        for (sentenceId, entry) in contentIndex {
            if let audioInfo = entry.audioInfo(for: normalizedLang) {
                segments[sentenceId] = AudioSegment(
                    sentenceId: sentenceId,
                    offsetMs: audioInfo.offsetMs,
                    durationMs: audioInfo.durationMs,
                    audioPath: audioInfo.audioPath,
                    sampleRateHz: audioInfo.sampleRateHz
                )
            }
        }
        
        return segments
    }
    
    // MARK: - Chunk Information
    
    /// Gets the chunk ID that contains a specific sentence.
    /// - Parameter sentenceId: The sentence ID
    /// - Parameter languageCode: The language code
    /// - Returns: Chunk ID if found, nil otherwise
    func chunkId(for sentenceId: String, languageCode: String) throws -> String? {
        let playbackMap = try loadPlaybackMap()
        let normalizedLang = normalizeLanguageCode(languageCode)
        
        for (chunkId, chunkInfo) in playbackMap {
            guard let langInfo = chunkInfo.languageInfo(for: normalizedLang) else { continue }
            
            // Check if sentence is in this chunk's sentences
            if langInfo.sentences.contains(where: { $0.sentenceId == sentenceId }) {
                return chunkId
            }
        }
        
        return nil
    }
    
    /// Gets all sentence IDs in a specific chunk for a language.
    /// - Parameters:
    ///   - chunkId: The chunk ID (e.g., "c00001")
    ///   - languageCode: The language code
    /// - Returns: Array of sentence IDs in order
    func sentenceIds(in chunkId: String, languageCode: String) throws -> [String] {
        let playbackMap = try loadPlaybackMap()
        let normalizedLang = normalizeLanguageCode(languageCode)
        
        guard let chunkInfo = playbackMap[chunkId],
              let langInfo = chunkInfo.languageInfo(for: normalizedLang) else {
            return []
        }
        
        return langInfo.sentences.map { $0.sentenceId }
    }
    
    /// Gets the audio file path for a chunk in a specific language.
    /// - Parameters:
    ///   - chunkId: The chunk ID
    ///   - languageCode: The language code
    /// - Returns: Audio file path if found, nil otherwise
    func audioPath(for chunkId: String, languageCode: String) throws -> String? {
        let playbackMap = try loadPlaybackMap()
        let normalizedLang = normalizeLanguageCode(languageCode)
        
        guard let chunkInfo = playbackMap[chunkId],
              let langInfo = chunkInfo.languageInfo(for: normalizedLang) else {
            return nil
        }
        
        return langInfo.audioPath
    }
    
    /// Gets paragraph information for a chunk in a specific language.
    /// - Parameters:
    ///   - chunkId: The chunk ID
    ///   - languageCode: The language code
    /// - Returns: Array of ChunkParagraph if found, empty array otherwise
    func paragraphs(in chunkId: String, languageCode: String) throws -> [ChunkParagraph] {
        let playbackMap = try loadPlaybackMap()
        let normalizedLang = normalizeLanguageCode(languageCode)
        
        guard let chunkInfo = playbackMap[chunkId],
              let langInfo = chunkInfo.languageInfo(for: normalizedLang) else {
            return []
        }
        
        return langInfo.paragraphs
    }
    
    // MARK: - Sentence Timing in Chunks
    
    /// Gets the start time and duration for a sentence within its chunk.
    /// - Parameters:
    ///   - sentenceId: The sentence ID
    ///   - languageCode: The language code
    /// - Returns: Tuple of (startMs, durationMs) if found, nil otherwise
    func sentenceTiming(in chunkId: String, sentenceId: String, languageCode: String) throws -> (startMs: Int, durationMs: Int)? {
        let playbackMap = try loadPlaybackMap()
        let normalizedLang = normalizeLanguageCode(languageCode)
        
        guard let chunkInfo = playbackMap[chunkId],
              let langInfo = chunkInfo.languageInfo(for: normalizedLang) else {
            return nil
        }
        
        guard let sentence = langInfo.sentences.first(where: { $0.sentenceId == sentenceId }) else {
            return nil
        }
        
        return (sentence.startMs, sentence.durationMs)
    }
    
    // MARK: - Helper Methods
    
    /// Normalizes a language code to its simplified form for file path lookup
    /// - Parameter code: Language code (e.g., "en-US" or "en")
    /// - Returns: Simplified code (e.g., "en")
    private func normalizeLanguageCode(_ code: String) -> String {
        // If it's already simplified (no hyphen), return as-is
        if !code.contains("-") {
            return code.lowercased()
        }
        
        // Extract the base language code (part before hyphen)
        let components = code.split(separator: "-")
        return String(components[0]).lowercased()
    }
    
    /// Gets the next chunk ID in sequence (for preloading).
    /// - Parameter currentChunkId: The current chunk ID (e.g., "c00001")
    /// - Returns: Next chunk ID if it exists, nil otherwise
    func nextChunkId(after currentChunkId: String) throws -> String? {
        let playbackMap = try loadPlaybackMap()
        
        // Extract number from chunk ID (e.g., "c00001" -> 1)
        let trimmed = currentChunkId.trimmingCharacters(in: CharacterSet.letters)
        guard let currentNumber = Int(trimmed) else {
            return nil
        }
        
        let nextNumber = currentNumber + 1
        let nextChunkId = String(format: "c%05d", nextNumber)
        
        return playbackMap[nextChunkId] != nil ? nextChunkId : nil
    }

    /// Gets the previous chunk ID in sequence.
    /// - Parameter currentChunkId: The current chunk ID
    /// - Returns: Previous chunk ID if it exists, nil otherwise
    func previousChunkId(before currentChunkId: String) throws -> String? {
        let playbackMap = try loadPlaybackMap()
        
        // Extract number from chunk ID
        let trimmed = currentChunkId.trimmingCharacters(in: CharacterSet.letters)
        guard let currentNumber = Int(trimmed),
              currentNumber > 1 else {
            return nil
        }
        
        let prevNumber = currentNumber - 1
        let prevChunkId = String(format: "c%05d", prevNumber)
        
        return playbackMap[prevChunkId] != nil ? prevChunkId : nil
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached data
    func clearCache() {
        cachedContentIndex = nil
        cachedPlaybackMap = nil
    }
}

// MARK: - AudioMappingLoaderError

enum AudioMappingLoaderError: LocalizedError {
    case fileNotFound(String)
    case decodingError(String)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Audio mapping file not found: \(path)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
