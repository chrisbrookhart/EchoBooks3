//
//  ContentLoader.swift
//
//  Service for loading content from the new book format structure.
//  Handles loading universal content, language-specific translations, and chapter metadata.
//

import Foundation

/// Service for loading book content from the new format structure.
/// Provides caching and convenient access to sentences, paragraphs, and translations.
class ContentLoader {
    
    // MARK: - Properties
    
    /// The book code (e.g., "CLOCK")
    let bookCode: String
    
    /// The root directory path for this book in the bundle (e.g., "CLOCK_book")
    private var bookRootPath: String {
        "\(bookCode)_book"
    }
    
    // MARK: - Cached Content
    
    private var cachedBookMetadata: BookMetadata?
    private var cachedSentences: [SentenceData]?
    private var cachedParagraphs: [ParagraphData]?
    private var cachedTranslations: [String: [String: String]] = [:] // [languageCode: [sentenceId: translation]]
    private var cachedStructureMetadata: [String: StructureMetadata] = [:] // [languageCode: StructureMetadata]
    
    // MARK: - Initialization
    
    /// Initialize a ContentLoader for a specific book.
    /// - Parameter bookCode: The book code (e.g., "CLOCK")
    init(bookCode: String) {
        self.bookCode = bookCode
    }
    
    // MARK: - File Resource Helper
    
    /// Attempts to find a resource, checking Application Support first, then bundle.
    /// Downloaded books in Application Support take precedence over bundle books.
    private func findResourceWithFileManager(name: String, extension ext: String, subdirectory: String) -> URL? {
        let fileManager = FileManager.default
        let fileName = "\(name).\(ext)"
        
        // 1. First check Application Support Directory (downloaded books)
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let booksPath = appSupport.appendingPathComponent("Books", isDirectory: true)
            let bookPath = booksPath.appendingPathComponent(bookRootPath, isDirectory: true)
            let filePath = bookPath.appendingPathComponent(subdirectory).appendingPathComponent(fileName)
            
            if fileManager.fileExists(atPath: filePath.path) {
                return filePath
            }
        }
        
        // 2. Then check Bundle (bundle books)
        // Try Bundle.main.url with Books prefix
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
        
        // Fallback: Use FileManager to search in Bundle Books folder
        guard let resourcePath = Bundle.main.resourcePath else {
            return nil
        }
        
        let booksPath = (resourcePath as NSString).appendingPathComponent("Books")
        let searchPath = (booksPath as NSString).appendingPathComponent("\(bookRootPath)/\(subdirectory)")
        let filePath = (searchPath as NSString).appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: filePath) {
            return URL(fileURLWithPath: filePath)
        }
        
        return nil
    }
    
    // MARK: - Book Metadata Loading
    
    /// Loads book metadata from universal/book_title.json
    /// - Returns: BookMetadata if successfully loaded, nil otherwise
    func loadBookMetadata() throws -> BookMetadata {
        if let cached = cachedBookMetadata {
            return cached
        }
        
        guard let url = findResourceWithFileManager(name: "book_title", extension: "json", subdirectory: "universal") else {
            throw ContentLoaderError.fileNotFound("universal/book_title.json")
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let metadata = try decoder.decode(BookMetadata.self, from: data)
        
        cachedBookMetadata = metadata
        return metadata
    }
    
    // MARK: - Universal Content Loading
    
    /// Loads all sentences from universal/sentences.simplified.json
    /// - Returns: Array of SentenceData
    func loadSentences() throws -> [SentenceData] {
        if let cached = cachedSentences {
            return cached
        }
        
        guard let url = findResourceWithFileManager(name: "sentences.simplified", extension: "json", subdirectory: "universal") else {
            throw ContentLoaderError.fileNotFound("universal/sentences.simplified.json")
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let sentences = try decoder.decode([SentenceData].self, from: data)
        
        cachedSentences = sentences
        return sentences
    }
    
    /// Loads all paragraphs from universal/paragraphs.simplified.json
    /// - Returns: Array of ParagraphData
    func loadParagraphs() throws -> [ParagraphData] {
        if let cached = cachedParagraphs {
            return cached
        }
        
        guard let url = findResourceWithFileManager(name: "paragraphs.simplified", extension: "json", subdirectory: "universal") else {
            throw ContentLoaderError.fileNotFound("universal/paragraphs.simplified.json")
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let paragraphs = try decoder.decode([ParagraphData].self, from: data)
        
        cachedParagraphs = paragraphs
        return paragraphs
    }
    
    // MARK: - Language-Specific Content Loading
    
    /// Loads sentence translations from translations/{lang}/sentences.{lang}.jsonl
    /// - Parameter languageCode: Language code (e.g., "en", "en-US", "es", "es-ES")
    /// - Returns: Dictionary mapping sentenceId to translation text
    func loadTranslations(for languageCode: String) throws -> [String: String] {
        // Normalize language code (use simplified version for file lookup)
        let normalizedLang = normalizeLanguageCode(languageCode)
        
        // Check cache
        if let cached = cachedTranslations[normalizedLang] {
            return cached
        }
        
        guard let url = findResourceWithFileManager(name: "sentences.\(normalizedLang)", extension: "jsonl", subdirectory: "translations/\(normalizedLang)") else {
            throw ContentLoaderError.fileNotFound("translations/\(normalizedLang)/sentences.\(normalizedLang).jsonl")
        }
        
        // Parse JSONL (line-delimited JSON)
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var translations: [String: String] = [:]
        let decoder = JSONDecoder()
        
        for line in lines {
            guard let lineData = line.data(using: .utf8) else { continue }
            if let translation = try? decoder.decode(SentenceTranslation.self, from: lineData) {
                translations[translation.sentenceId] = translation.translation
            }
        }
        
        cachedTranslations[normalizedLang] = translations
        return translations
    }
    
    /// Loads chapter structure metadata from translations/{lang}/structure.meta.{lang}.json
    /// - Parameter languageCode: Language code (e.g., "en", "en-US", "es", "es-ES")
    /// - Returns: StructureMetadata containing chapters
    func loadStructureMetadata(for languageCode: String) throws -> StructureMetadata {
        // Normalize language code
        let normalizedLang = normalizeLanguageCode(languageCode)
        
        // Check cache
        if let cached = cachedStructureMetadata[normalizedLang] {
            return cached
        }
        
        guard let url = findResourceWithFileManager(name: "structure.meta.\(normalizedLang)", extension: "json", subdirectory: "translations/\(normalizedLang)") else {
            throw ContentLoaderError.fileNotFound("translations/\(normalizedLang)/structure.meta.\(normalizedLang).json")
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let metadata = try decoder.decode(StructureMetadata.self, from: data)
        
        cachedStructureMetadata[normalizedLang] = metadata
        return metadata
    }
    
    // MARK: - Convenience Methods
    
    /// Gets sentences for a specific chapter
    /// - Parameter chapterIndex: The chapter index (1-based)
    /// - Returns: Array of SentenceData for the chapter
    func sentences(for chapterIndex: Int) throws -> [SentenceData] {
        let allSentences = try loadSentences()
        return allSentences.filter { $0.chapterIndex == chapterIndex }
    }
    
    /// Gets paragraphs for a specific chapter
    /// - Parameter chapterIndex: The chapter index (1-based)
    /// - Returns: Array of ParagraphData for the chapter
    func paragraphs(for chapterIndex: Int) throws -> [ParagraphData] {
        let allParagraphs = try loadParagraphs()
        return allParagraphs.filter { $0.chapterIndex == chapterIndex }
    }
    
    /// Gets a sentence by its ID
    /// - Parameter sentenceId: The sentence ID (e.g., "s000001")
    /// - Returns: SentenceData if found, nil otherwise
    func sentence(withId sentenceId: String) throws -> SentenceData? {
        let allSentences = try loadSentences()
        return allSentences.first { $0.sentenceId == sentenceId }
    }
    
    /// Gets a paragraph by its ID
    /// - Parameter paragraphId: The paragraph ID (e.g., "p00001")
    /// - Returns: ParagraphData if found, nil otherwise
    func paragraph(withId paragraphId: String) throws -> ParagraphData? {
        let allParagraphs = try loadParagraphs()
        return allParagraphs.first { $0.paragraphId == paragraphId }
    }
    
    /// Gets the translation for a sentence in a specific language
    /// - Parameters:
    ///   - sentenceId: The sentence ID
    ///   - languageCode: The language code
    /// - Returns: Translation text if found, nil otherwise
    func translation(for sentenceId: String, languageCode: String) throws -> String? {
        let translations = try loadTranslations(for: languageCode)
        return translations[sentenceId]
    }
    
    /// Gets sentences for a paragraph
    /// - Parameter paragraphId: The paragraph ID
    /// - Returns: Array of SentenceData for the paragraph, sorted by sentenceIndexInParagraph
    func sentences(for paragraphId: String) throws -> [SentenceData] {
        let allSentences = try loadSentences()
        return allSentences
            .filter { $0.paragraphId == paragraphId }
            .sorted { $0.sentenceIndexInParagraph < $1.sentenceIndexInParagraph }
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
    
    // MARK: - Cache Management
    
    /// Clears all cached content
    func clearCache() {
        cachedBookMetadata = nil
        cachedSentences = nil
        cachedParagraphs = nil
        cachedTranslations.removeAll()
        cachedStructureMetadata.removeAll()
    }
}

// MARK: - ContentLoaderError

enum ContentLoaderError: LocalizedError {
    case fileNotFound(String)
    case decodingError(String)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
