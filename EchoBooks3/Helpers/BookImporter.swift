//
//  BookImporter.swift
//  EchoBooks3
// 
//  Updated to support the new book format structure.
//  Detects new format books and loads them using ContentLoader.
//

import Foundation

struct BookImporter {
    
    /// Scans both bundle and Application Support Directory for books in the new format and imports them.
    /// Downloaded books in Application Support take precedence over bundle books.
    /// - Returns: An array of decoded Book objects.
    static func importBooks() -> [Book] {
        var books: [Book] = []
        
        print("🔍 BookImporter: Starting book discovery...")
        
        // Get all book directories (bundle + Application Support)
        let bookDirectories = getBooksDirectories()
        
        // Track which books we've already imported (by bookCode) to avoid duplicates
        // Downloaded books take precedence
        var importedBookCodes: Set<String> = []
        
        // First, import from Application Support (downloaded books)
        if let appSupportDir = bookDirectories.first(where: { $0.path.contains("Application Support") }) {
            print("📦 BookImporter: Checking Application Support: \(appSupportDir.path)")
            let appSupportBooks = importBooks(from: appSupportDir)
            for book in appSupportBooks {
                books.append(book)
                importedBookCodes.insert(book.bookCode)
            }
        }
        
        // Then, import from bundle (only if not already imported from Application Support)
        if let bundleDir = bookDirectories.first(where: { $0.path.contains("Bundle") || !$0.path.contains("Application Support") }) {
            print("📦 BookImporter: Checking Bundle: \(bundleDir.path)")
            let bundleBooks = importBooks(from: bundleDir)
            for book in bundleBooks {
                if !importedBookCodes.contains(book.bookCode) {
                    books.append(book)
                    importedBookCodes.insert(book.bookCode)
                }
            }
        }
        
        print("📚 BookImporter: Imported \(books.count) books total")
        return books
    }
    
    /// Gets all directories where books can be found (bundle + Application Support)
    private static func getBooksDirectories() -> [URL] {
        var directories: [URL] = []
        let fileManager = FileManager.default
        
        // 1. Bundle directory
        if let resourcePath = Bundle.main.resourcePath {
            let booksPath = (resourcePath as NSString).appendingPathComponent("Books")
            if fileManager.fileExists(atPath: booksPath) {
                directories.append(URL(fileURLWithPath: booksPath))
            }
        }
        
        // 2. Application Support directory
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let booksPath = appSupport.appendingPathComponent("Books", isDirectory: true)
            if fileManager.fileExists(atPath: booksPath.path) {
                directories.append(booksPath)
            }
        }
        
        return directories
    }
    
    /// Imports books from a specific directory
    private static func importBooks(from directory: URL) -> [Book] {
        var books: [Book] = []
        
        let fileManager = FileManager.default
        let booksPath = directory.path
        
        guard fileManager.fileExists(atPath: booksPath) else {
            print("❌ BookImporter: Books folder NOT found at: \(booksPath)")
            return books
        }
        
        print("✅ BookImporter: Books folder exists at: \(booksPath)")
        
        // List what's in Books folder
        if let booksContents = try? fileManager.contentsOfDirectory(atPath: booksPath) {
            print("📁 BookImporter: Books folder contains: \(booksContents)")
        }
        
        // Recursively search for book_title.json files and debug what we find
        func findBookTitleFiles(in directory: String) -> [String] {
            var foundFiles: [String] = []
            
            print("🔍 BookImporter: Searching in directory: \(directory)")
            
            guard let enumerator = fileManager.enumerator(atPath: directory) else {
                print("❌ BookImporter: Could not create enumerator for: \(directory)")
                return foundFiles
            }
            
            var fileCount = 0
            var jsonFiles: [String] = []
            
            for case let item as String in enumerator {
                let fullPath = (directory as NSString).appendingPathComponent(item)
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
//                    if isDirectory.boolValue {
//                        dirCount += 1
//                    } else {
//                        fileCount += 1
//                        if item.hasSuffix(".json") {
//                            jsonFiles.append(item)
//                            print("   📄 Found JSON file: \(item) at \(fullPath)")
//                        }
//                        if item == "book_title.json" {
//                            foundFiles.append(fullPath)
//                            print("✅ BookImporter: Found book_title.json at: \(fullPath)")
//                        }
//                    }
                    if !isDirectory.boolValue {
                        fileCount += 1
                        let fileName = (item as NSString).lastPathComponent
                        if fileName.hasSuffix(".json") {
                            jsonFiles.append(item)
                            print("   📄 Found JSON file: \(item) at \(fullPath)")
                        }
                        if fileName == "book_title.json" {
                            foundFiles.append(fullPath)
                            print("✅ BookImporter: Found book_title.json at: \(fullPath)")
                        }
                    }
                }
            }
            
            print("📊 BookImporter: Found \(fileCount) files")
            print("📄 BookImporter: Found \(jsonFiles.count) JSON files: \(jsonFiles)")
            
            // Also try listing CLOCK_book directly
            let clockBookPath = (directory as NSString).appendingPathComponent("CLOCK_book")
            if fileManager.fileExists(atPath: clockBookPath) {
                print("🔍 BookImporter: CLOCK_book exists, listing contents...")
                if let contents = try? fileManager.contentsOfDirectory(atPath: clockBookPath) {
                    print("   Contents of CLOCK_book: \(contents)")
                    
                    // Check universal folder
                    let universalPath = (clockBookPath as NSString).appendingPathComponent("universal")
                    if fileManager.fileExists(atPath: universalPath) {
                        print("   ✅ universal folder exists")
                        if let universalContents = try? fileManager.contentsOfDirectory(atPath: universalPath) {
                            print("   Contents of universal: \(universalContents)")
                        }
                    } else {
                        print("   ❌ universal folder NOT found")
                    }
                }
            } else {
                print("❌ BookImporter: CLOCK_book folder NOT found at: \(clockBookPath)")
            }
            
            return foundFiles
        }
        
        let bookTitleFilePaths = findBookTitleFiles(in: booksPath)
        print("📚 BookImporter: Found \(bookTitleFilePaths.count) book_title.json files")
        
        for filePath in bookTitleFilePaths {
            let url = URL(fileURLWithPath: filePath)
            print("   Processing: \(url.lastPathComponent) at \(url.path)")
            
            // Load the JSON to get the bookCode
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let metadata = try decoder.decode(BookMetadata.self, from: data)
                
                let bookCode = metadata.bookCode
                print("📖 BookImporter: Found book code: \(bookCode) from \(url.path)")
                
                // Check if this is a new format book
                if isNewFormatBook(bookCode: bookCode) {
                    print("✅ BookImporter: \(bookCode) is a new format book, importing...")
                    do {
                        let book = try importNewFormatBook(bookCode: bookCode)
                        books.append(book)
                        print("✅ BookImporter: Successfully imported \(book.bookTitle)")
                    } catch {
                        print("❌ BookImporter: Failed to import \(bookCode): \(error.localizedDescription)")
                        if let contentLoaderError = error as? ContentLoaderError {
                            print("   ContentLoader error: \(contentLoaderError)")
                        }
                        if let bookImporterError = error as? BookImporterError {
                            print("   BookImporter error: \(bookImporterError)")
                        }
                    }
                } else {
                    print("⚠️ BookImporter: \(bookCode) is not a new format book")
                }
            } catch {
                print("❌ BookImporter: Failed to decode \(url.path): \(error.localizedDescription)")
                continue
            }
        }
        
        print("📚 BookImporter: Imported \(books.count) books")
        return books
    }
    
    /// Checks if a book folder contains the new format structure.
    /// Checks both bundle and Application Support directories.
    /// - Parameter bookCode: The book code (e.g., "CLOCK")
    /// - Returns: true if new format files are found, false otherwise
    private static func isNewFormatBook(bookCode: String) -> Bool {
        let bookRootPath = "\(bookCode)_book"
        let fileManager = FileManager.default
        
        // Check both bundle and Application Support
        let directories = getBooksDirectories()
        
        for directory in directories {
            let bookPath = directory.appendingPathComponent(bookRootPath, isDirectory: true)
            
            let contentIndexPath = bookPath.appendingPathComponent("app/content_index.json")
            let bookTitlePath = bookPath.appendingPathComponent("universal/book_title.json")
            
            let hasContentIndex = fileManager.fileExists(atPath: contentIndexPath.path)
            let hasBookTitle = fileManager.fileExists(atPath: bookTitlePath.path)
            
            if hasContentIndex || hasBookTitle {
                print("🔍 BookImporter: Checking \(bookCode) in \(directory.path) - hasContentIndex: \(hasContentIndex), hasBookTitle: \(hasBookTitle)")
                return true
            }
        }
        
        return false
    }
    
    /// Imports a book from the new format structure.
    /// Checks both bundle and Application Support directories.
    /// - Parameter bookCode: The book code (e.g., "CLOCK")
    /// - Returns: A Book object if successfully loaded, nil otherwise
    private static func importNewFormatBook(bookCode: String) throws -> Book {
        // ContentLoader will check both bundle and Application Support
        // (we'll update ContentLoader to do this)
        let contentLoader = ContentLoader(bookCode: bookCode)
        
        // Load book metadata
        let bookMetadata = try contentLoader.loadBookMetadata()
        
        // Convert bookID string to UUID
        guard let bookID = UUID(uuidString: bookMetadata.bookID) else {
            throw BookImporterError.invalidBookID(bookMetadata.bookID)
        }
        
        // Convert language strings to LanguageCode enum
        let languageCodes = bookMetadata.languages.compactMap { langString in
            LanguageCode.fromCode(langString)
        }
        
        guard !languageCodes.isEmpty else {
            throw BookImporterError.noValidLanguages
        }
        
        // Load structure metadata (use first available language)
        let firstLanguage = languageCodes[0]
        let structureMetadata = try contentLoader.loadStructureMetadata(
            for: firstLanguage.rawValue
        )
        
        // Create chapters from structure metadata
        let chapters = structureMetadata.chapters.map { chapterMeta -> Chapter in
            // Create a UUID for the chapter (we'll use a deterministic approach)
            let chapterID = generateChapterID(bookCode: bookCode, chapterIndex: chapterMeta.index)
            
            return Chapter(
                id: chapterID,
                language: firstLanguage, // Default language, actual content loaded lazily
                chapterNumber: chapterMeta.index,
                chapterTitle: chapterMeta.title,
                paragraphs: [] // Paragraphs loaded lazily when needed
            )
        }
        
        // Create a default SubBook with all chapters
        let defaultSubBook = SubBook(
            id: UUID(), // Generate new UUID for default subbook
            subBookNumber: 1,
            subBookTitle: "Default",
            chapters: chapters
        )
        
        // Create the Book
        let book = Book(
            id: bookID,
            bookTitle: bookMetadata.bookTitle,
            author: bookMetadata.author,
            languages: languageCodes,
            bookDescription: bookMetadata.bookDescription?.isEmpty == false
                ? bookMetadata.bookDescription
                : nil,
            coverImageName: bookMetadata.coverImageName,
            bookCode: bookMetadata.bookCode,
            bookLevel: bookMetadata.bookLevel,
            learningTheme: bookMetadata.learningTheme,
            whatYouWillPractice: bookMetadata.whatYouWillPractice,
            estimatedLength: bookMetadata.estimatedLength,
            isFree: bookMetadata.isFree ?? false, // Default to false if not present
            productIdentifier: bookMetadata.productIdentifier,
            subBooks: [defaultSubBook]
        )
        
        return book
    }
    
    /// Generates a deterministic UUID for a chapter based on book code and chapter index.
    /// This ensures the same chapter always gets the same ID.
    /// - Parameters:
    ///   - bookCode: The book code
    ///   - chapterIndex: The chapter index
    /// - Returns: A UUID
    private static func generateChapterID(bookCode: String, chapterIndex: Int) -> UUID {
        // Create a deterministic UUID from book code and chapter index
        let seed = "\(bookCode)_chapter_\(chapterIndex)"
        var hasher = Hasher()
        hasher.combine(seed)
        let hash = hasher.finalize()
        
        // Convert to UUID format (not cryptographically secure, but deterministic)
        let uuidString = String(format: "%08x-%04x-%04x-%04x-%012x",
                                UInt32(truncatingIfNeeded: hash) & 0xffffffff,
                                UInt16(truncatingIfNeeded: hash >> 32) & 0xffff,
                                UInt16(truncatingIfNeeded: hash >> 48) & 0x0fff | 0x4000, // Version 4 variant
                                UInt16(truncatingIfNeeded: hash >> 60) & 0x3fff | 0x8000,
                                UInt64(abs(hash)) & 0xffffffffffff)
        
        return UUID(uuidString: uuidString) ?? UUID()
    }
}

// MARK: - BookImporterError

enum BookImporterError: LocalizedError {
    case invalidBookID(String)
    case noValidLanguages
    case missingMetadata
    case invalidStructure
    
    var errorDescription: String? {
        switch self {
        case .invalidBookID(let id):
            return "Invalid book ID format: \(id)"
        case .noValidLanguages:
            return "No valid languages found in book metadata"
        case .missingMetadata:
            return "Required metadata is missing"
        case .invalidStructure:
            return "Invalid book structure"
        }
    }
}
