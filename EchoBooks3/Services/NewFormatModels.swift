//
//  NewFormatModels.swift
//  EchoBooks3
// 
//  Data models for decoding the new book format JSON files.
//

import Foundation

// MARK: - Book Metadata (from universal/book_title.json)

/// Metadata about a book from book_title.json
struct BookMetadata: Codable {
    let bookID: String
    let bookTitle: String
    let bookCode: String
    let author: String
    let languages: [String]
    let bookDescription: String?
    let coverImageName: String
    let defaultPlaybackOrder: [String]?
    let bookLevel: Int?
    let learningTheme: String?
    let whatYouWillPractice: [String]?
    let estimatedLength: String?
    
    enum CodingKeys: String, CodingKey {
        case bookID = "bookID"
        case bookTitle = "bookTitle"
        case bookCode = "bookCode"
        case author = "author"
        case languages = "languages"
        case bookDescription = "bookDescription"
        case coverImageName = "coverImageName"
        case defaultPlaybackOrder = "defaultPlaybackOrder"
        case bookLevel = "bookLevel"
        case learningTheme = "learningTheme"
        case whatYouWillPractice = "whatYouWillPractice"
        case estimatedLength = "estimatedLength"
    }
}

// MARK: - Chapter Metadata (from translations/{lang}/structure.meta.{lang}.json)

/// Chapter information from structure.meta.{lang}.json
struct ChapterMetadata: Codable {
    let index: Int
    let title: String
}

/// Structure metadata containing book title and chapters
struct StructureMetadata: Codable {
    let bookTitle: String
    let chapters: [ChapterMetadata]
}

// MARK: - Sentence Data (from universal/sentences.simplified.json)

/// Sentence data from sentences.simplified.json
struct SentenceData: Codable, Identifiable {
    let sentenceId: String
    let chapterIndex: Int
    let chapterTitle: String
    let paragraphId: String
    let paragraphType: String
    let sentenceIndexInParagraph: Int
    let text: String
    
    var id: String { sentenceId }
    
    enum CodingKeys: String, CodingKey {
        case sentenceId = "sentenceId"
        case chapterIndex = "chapterIndex"
        case chapterTitle = "chapterTitle"
        case paragraphId = "paragraphId"
        case paragraphType = "paragraphType"
        case sentenceIndexInParagraph = "sentenceIndexInParagraph"
        case text = "text"
    }
}

// MARK: - Paragraph Data (from universal/paragraphs.simplified.json)

/// Paragraph data from paragraphs.simplified.json
struct ParagraphData: Codable, Identifiable {
    let paragraphId: String
    let chapterIndex: Int
    let chapterTitle: String
    let paragraphIndexInChapter: Int
    let type: String
    let text: String
    let markers: [String]
    
    var id: String { paragraphId }
    
    enum CodingKeys: String, CodingKey {
        case paragraphId = "paragraphId"
        case chapterIndex = "chapterIndex"
        case chapterTitle = "chapterTitle"
        case paragraphIndexInChapter = "paragraphIndexInChapter"
        case type = "type"
        case text = "text"
        case markers = "markers"
    }
}

// MARK: - Content Index (from app/content_index.json)

/// Audio information for a specific language
struct LanguageAudioInfo: Codable {
    let audioPath: String
    let offsetMs: Int
    let durationMs: Int
    let sampleRateHz: Int
    
    enum CodingKeys: String, CodingKey {
        case audioPath = "audio_path"
        case offsetMs = "offset_ms"
        case durationMs = "duration_ms"
        case sampleRateHz = "sample_rate_hz"
    }
}

/// Content index entry for a sentence (contains audio info for all languages)
struct ContentIndexEntry: Codable {
    let en: LanguageAudioInfo?
    let es: LanguageAudioInfo?
    let fr: LanguageAudioInfo?
    // Add other languages as needed
    
    /// Get audio info for a specific language code
    func audioInfo(for languageCode: String) -> LanguageAudioInfo? {
        switch languageCode.lowercased() {
        case "en", "en-us": return en
        case "es", "es-es": return es
        case "fr", "fr-fr": return fr
        default: return nil
        }
    }
}

/// Content index mapping sentence IDs to audio information
typealias ContentIndex = [String: ContentIndexEntry]

// MARK: - Playback Map (from app/playback_map.json)

/// Sentence timing within a chunk
struct ChunkSentence: Codable {
    let sentenceId: String
    let startMs: Int
    let durationMs: Int
    
    enum CodingKeys: String, CodingKey {
        case sentenceId = "sentence_id"
        case startMs = "start_ms"
        case durationMs = "duration_ms"
    }
}

/// Paragraph timing within a chunk
struct ChunkParagraph: Codable {
    let paragraphId: String
    let sentences: [ChunkSentence]
    
    enum CodingKeys: String, CodingKey {
        case paragraphId = "paragraph_id"
        case sentences = "sentences"
    }
}

/// Playback information for a specific language within a chunk
struct ChunkLanguageInfo: Codable {
    let audioPath: String
    let sentences: [ChunkSentence]
    let paragraphs: [ChunkParagraph]
    
    enum CodingKeys: String, CodingKey {
        case audioPath = "audio_path"
        case sentences = "sentences"
        case paragraphs = "paragraphs"
    }
}

/// Chunk playback information (contains info for all languages)
struct ChunkPlaybackInfo: Codable {
    let en: ChunkLanguageInfo?
    let es: ChunkLanguageInfo?
    let fr: ChunkLanguageInfo?
    // Add other languages as needed
    
    /// Get language info for a specific language code
    func languageInfo(for languageCode: String) -> ChunkLanguageInfo? {
        switch languageCode.lowercased() {
        case "en", "en-us": return en
        case "es", "es-es": return es
        case "fr", "fr-fr": return fr
        default: return nil
        }
    }
}

/// Playback map mapping chunk IDs to playback information
typealias PlaybackMap = [String: ChunkPlaybackInfo]

// MARK: - Translation Data (from translations/{lang}/sentences.{lang}.jsonl)

/// Translation entry from sentences.{lang}.jsonl (JSONL format - one JSON object per line)
struct SentenceTranslation: Codable {
    let sentenceId: String
    let translation: String
    
    enum CodingKeys: String, CodingKey {
        case sentenceId = "sentence_id"
        case translation = "translation"
    }
}
