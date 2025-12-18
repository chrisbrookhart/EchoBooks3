//
//  BookDownloadManager.swift
//  EchoBooks3
//
//  Manages downloading books from StoreKit hosted content, extracting them,
//  and filtering out unselected language folders. Books are stored in
//  Application Support Directory.
//

import Foundation
import StoreKit
import Compression

@MainActor
class BookDownloadManager: ObservableObject {
    // MARK: - Properties
    
    /// Download progress by product identifier (0.0 to 1.0)
    @Published var downloadProgress: [String: Double] = [:]
    
    /// Currently downloading product identifiers
    @Published var downloadingProducts: Set<String> = []
    
    // MARK: - Application Support Directory
    
    /// Gets the Application Support directory for downloaded books
    private var booksDirectory: URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let booksDir = appSupport.appendingPathComponent("Books", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: booksDir, withIntermediateDirectories: true)
        
        return booksDir
    }
    
    // MARK: - Download Book
    
    /// Downloads a book from StoreKit and extracts it with selected languages only
    /// Also handles copying bundle books to Application Support so they can be deleted
    /// - Parameters:
    ///   - productIdentifier: StoreKit product identifier (nil for bundle books)
    ///   - bookCode: Book code (e.g., "CLOCK")
    ///   - selectedLanguages: Languages to keep (others will be deleted)
    func downloadBook(
        productIdentifier: String?,
        bookCode: String,
        selectedLanguages: [LanguageCode]
    ) async throws {
        // Check if this is a bundle book (no product identifier or product not found)
        let isBundleBook = productIdentifier == nil || {
            // Quick check - if product ID is nil, it's definitely a bundle book
            // If product ID exists but product not found, treat as bundle book
            return false // Will be determined below
        }()
        
        // If book is already in Application Support, don't re-download
        if isBookDownloadedOnly(bookCode: bookCode) {
            print("📦 BookDownloadManager: Book \(bookCode) already downloaded, skipping")
            return
        }
        
        // Check if book is in bundle - if so, copy it to Application Support
        if isBookInBundle(bookCode: bookCode) {
            print("📦 BookDownloadManager: Copying bundle book \(bookCode) to Application Support")
            try await copyBundleBookToApplicationSupport(
                bookCode: bookCode,
                selectedLanguages: selectedLanguages
            )
            return
        }
        
        // Otherwise, download from StoreKit
        guard let productIdentifier = productIdentifier else {
            throw DownloadError.productNotFound
        }
        
        guard !downloadingProducts.contains(productIdentifier) else {
            throw DownloadError.alreadyDownloading
        }
        
        downloadingProducts.insert(productIdentifier)
        downloadProgress[productIdentifier] = 0.0
        
        defer {
            downloadingProducts.remove(productIdentifier)
            downloadProgress.removeValue(forKey: productIdentifier)
        }
        
        do {
            // Get the product
            let products = try await Product.products(for: [productIdentifier])
            guard let product = products.first else {
                throw DownloadError.productNotFound
            }
            
            // Purchase/download the product (if not already purchased)
            let purchaseResult = try await product.purchase()
            
            switch purchaseResult {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Transaction verified, download hosted content
                    downloadProgress[productIdentifier] = 0.1
                    
                    // Get the hosted content URL
                    guard let contentURL = try await downloadHostedContent(for: product) else {
                        await transaction.finish()
                        throw DownloadError.noHostedContent
                    }
                    
                    downloadProgress[productIdentifier] = 0.5
                    
                    // Extract and process the book
                    try await extractAndProcessBook(
                        contentURL: contentURL,
                        bookCode: bookCode,
                        selectedLanguages: selectedLanguages
                    )
                    
                    downloadProgress[productIdentifier] = 1.0
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                case .unverified(_, let error):
                    throw DownloadError.verificationFailed(error)
                }
            case .userCancelled:
                throw DownloadError.userCancelled
            case .pending:
                throw DownloadError.purchasePending
            @unknown default:
                throw DownloadError.unknownError
            }
        } catch {
            if let downloadError = error as? DownloadError {
                throw downloadError
            }
            throw DownloadError.downloadFailed(error)
        }
    }
    
    // MARK: - Copy Bundle Book
    
    /// Copies a bundle book to Application Support so it can be deleted later
    private func copyBundleBookToApplicationSupport(
        bookCode: String,
        selectedLanguages: [LanguageCode]
    ) async throws {
        let fileManager = FileManager.default
        let bookRootPath = "\(bookCode)_book"
        
        // Get bundle book path
        guard let resourcePath = Bundle.main.resourcePath else {
            throw DownloadError.extractionFailed("Could not access bundle")
        }
        
        let bundleBooksPath = (resourcePath as NSString).appendingPathComponent("Books")
        let bundleBookPath = (bundleBooksPath as NSString).appendingPathComponent(bookRootPath)
        
        guard fileManager.fileExists(atPath: bundleBookPath) else {
            throw DownloadError.extractionFailed("Bundle book not found: \(bookCode)")
        }
        
        // Destination in Application Support
        let destinationURL = booksDirectory.appendingPathComponent(bookRootPath, isDirectory: true)
        
        // Remove existing if it exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Copy entire book folder
        try fileManager.copyItem(atPath: bundleBookPath, toPath: destinationURL.path)
        
        // Delete unselected language folders
        try deleteUnselectedLanguages(
            bookPath: destinationURL,
            selectedLanguages: selectedLanguages
        )
        
        print("✅ BookDownloadManager: Copied bundle book \(bookCode) to Application Support")
    }
    
    // MARK: - Download Hosted Content
    
    /// Downloads hosted content for a product
    /// Note: StoreKit 2 automatically downloads hosted content during purchase.
    /// The content is available in the app's container. We need to access it via
    /// the transaction's content URL or check the app's container directory.
    private func downloadHostedContent(for product: Product) async throws -> URL? {
        // StoreKit 2 handles hosted content automatically during purchase
        // The content should be available in the app's container after purchase
        // We need to check the app's container for the downloaded content
        
        // Get the app's container directory (Application Support)
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw DownloadError.notImplemented("Could not access Application Support directory")
        }
        
        // StoreKit 2 stores hosted content in a specific location
        // The exact path depends on the product ID and StoreKit version
        // For now, we'll check common locations
        
        // Check if hosted content exists in the app's container
        // StoreKit typically stores it in: App Support/StoreKit/hosted_content/
        let hostedContentPath = appSupport.appendingPathComponent("StoreKit/hosted_content", isDirectory: true)
        
        // Look for the product's hosted content folder
        // The folder name typically matches the product ID or contains it
        if fileManager.fileExists(atPath: hostedContentPath.path) {
            // Try to find the product's content folder
            if let contents = try? fileManager.contentsOfDirectory(atPath: hostedContentPath.path) {
                // Look for a folder that might contain this product's content
                for item in contents {
                    let itemPath = hostedContentPath.appendingPathComponent(item)
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: itemPath.path, isDirectory: &isDirectory),
                       isDirectory.boolValue {
                        // Check if this folder might contain our book content
                        // This is a heuristic - in production you'd need proper StoreKit 2 API
                        return itemPath
                    }
                }
            }
        }
        
        // TODO: Implement proper hosted content location detection
        // This may require using StoreKit 1's SKDownload or waiting for StoreKit 2 APIs
        // For now, throw an error indicating this needs implementation
        throw DownloadError.notImplemented("Hosted content access - needs StoreKit 2 hosted content API or SKDownload integration")
    }
    
    // MARK: - Extract and Process Book
    
    /// Extracts the book zip and filters out unselected languages
    private func extractAndProcessBook(
        contentURL: URL,
        bookCode: String,
        selectedLanguages: [LanguageCode]
    ) async throws {
        let fileManager = FileManager.default
        let bookRootPath = "\(bookCode)_book"
        let destinationURL = booksDirectory.appendingPathComponent(bookRootPath, isDirectory: true)
        
        // Remove existing book if it exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Create temporary extraction directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            // Clean up temp directory
            try? fileManager.removeItem(at: tempDir)
        }
        
        // Extract zip file using Foundation's built-in zip support
        try extractZipFile(at: contentURL, to: tempDir)
        
        // Find the extracted book folder
        let extractedBookPath = tempDir.appendingPathComponent(bookRootPath)
        
        guard fileManager.fileExists(atPath: extractedBookPath.path) else {
            throw DownloadError.extractionFailed("Book folder not found in extracted content")
        }
        
        // Copy to Application Support
        try fileManager.copyItem(at: extractedBookPath, to: destinationURL)
        
        // Delete unselected language folders
        try deleteUnselectedLanguages(
            bookPath: destinationURL,
            selectedLanguages: selectedLanguages
        )
    }
    
    // MARK: - Zip Extraction
    
    /// Extracts a zip file to a destination directory
    /// Note: This requires a zip library. For production, add ZipFoundation via SPM:
    /// https://github.com/weichsel/ZIPFoundation
    /// For now, this is a placeholder that will need proper zip extraction implementation
    private func extractZipFile(at sourceURL: URL, to destinationURL: URL) throws {
        // TODO: Implement zip extraction
        // Options:
        // 1. Add ZipFoundation via Swift Package Manager
        // 2. Use a different zip library
        // 3. Implement manual zip extraction (complex)
        
        // For now, throw an error indicating this needs implementation
        throw DownloadError.notImplemented("Zip extraction - add ZipFoundation library or implement extraction")
        
        // Example with ZipFoundation (if added):
        // let archive = Archive(url: sourceURL, accessMode: .read)
        // try archive?.extract(to: destinationURL)
    }
    
    // MARK: - Delete Unselected Languages
    
    /// Deletes language folders that were not selected by the user
    /// Note: StoreKit downloads the full book zip. We delete unselected languages
    /// immediately after extraction to save storage space.
    private func deleteUnselectedLanguages(
        bookPath: URL,
        selectedLanguages: [LanguageCode]
    ) throws {
        let fileManager = FileManager.default
        
        // Get all available languages from the book structure
        let audioPath = bookPath.appendingPathComponent("audio", isDirectory: true)
        let translationsPath = bookPath.appendingPathComponent("translations", isDirectory: true)
        
        // Get selected language folder names
        let selectedLanguageFolders = Set(selectedLanguages.map { $0.rawValue })
        
        // Delete unselected audio language folders
        if fileManager.fileExists(atPath: audioPath.path) {
            if let audioContents = try? fileManager.contentsOfDirectory(atPath: audioPath.path) {
                for folder in audioContents {
                    let folderPath = audioPath.appendingPathComponent(folder)
                    var isDirectory: ObjCBool = false
                    
                    if fileManager.fileExists(atPath: folderPath.path, isDirectory: &isDirectory),
                       isDirectory.boolValue,
                       !selectedLanguageFolders.contains(folder) {
                        // This language folder was not selected, delete it
                        try fileManager.removeItem(at: folderPath)
                        print("🗑️ BookDownloadManager: Deleted unselected audio language: \(folder)")
                    }
                }
            }
        }
        
        // Delete unselected translation language folders
        if fileManager.fileExists(atPath: translationsPath.path) {
            if let translationContents = try? fileManager.contentsOfDirectory(atPath: translationsPath.path) {
                for folder in translationContents {
                    let folderPath = translationsPath.appendingPathComponent(folder)
                    var isDirectory: ObjCBool = false
                    
                    if fileManager.fileExists(atPath: folderPath.path, isDirectory: &isDirectory),
                       isDirectory.boolValue,
                       !selectedLanguageFolders.contains(folder) {
                        // This language folder was not selected, delete it
                        try fileManager.removeItem(at: folderPath)
                        print("🗑️ BookDownloadManager: Deleted unselected translation language: \(folder)")
                    }
                }
            }
        }
    }
    
    // MARK: - Check Download Status
    
    /// Checks if a book is already on device (either in Application Support or in bundle)
    func isBookDownloaded(bookCode: String) -> Bool {
        let fileManager = FileManager.default
        let bookRootPath = "\(bookCode)_book"
        
        // 1. Check Application Support (downloaded books)
        let downloadedPath = booksDirectory.appendingPathComponent(bookRootPath, isDirectory: true)
        if fileManager.fileExists(atPath: downloadedPath.path) {
            return true
        }
        
        // 2. Check bundle (books included in app)
        if let resourcePath = Bundle.main.resourcePath {
            let bundleBooksPath = (resourcePath as NSString).appendingPathComponent("Books")
            let bundleBookPath = (bundleBooksPath as NSString).appendingPathComponent(bookRootPath)
            if fileManager.fileExists(atPath: bundleBookPath) {
                return true
            }
        }
        
        return false
    }
    
    /// Gets the path to a downloaded book
    func getDownloadedBookPath(bookCode: String) -> URL? {
        let bookPath = booksDirectory.appendingPathComponent("\(bookCode)_book", isDirectory: true)
        return FileManager.default.fileExists(atPath: bookPath.path) ? bookPath : nil
    }
    
    // MARK: - Delete Book
    
    /// Deletes a downloaded book from the device
    /// Only deletes books from Application Support
    /// Bundle books must be "downloaded" (copied) first before they can be deleted
    func deleteBook(bookCode: String) throws {
        let fileManager = FileManager.default
        let bookRootPath = "\(bookCode)_book"
        
        // Only delete from Application Support
        let downloadedPath = booksDirectory.appendingPathComponent(bookRootPath, isDirectory: true)
        if fileManager.fileExists(atPath: downloadedPath.path) {
            try fileManager.removeItem(at: downloadedPath)
            print("🗑️ BookDownloadManager: Deleted book: \(bookCode)")
            return
        }
        
        // Book not found in Application Support
        // If it's a bundle book, user needs to "download" it first (copy to Application Support)
        if isBookInBundle(bookCode: bookCode) {
            throw DownloadError.mustDownloadFirst
        }
        
        throw DownloadError.bookNotDownloaded
    }
    
    /// Checks if a book is in the bundle (cannot be deleted)
    func isBookInBundle(bookCode: String) -> Bool {
        guard let resourcePath = Bundle.main.resourcePath else {
            return false
        }
        
        let fileManager = FileManager.default
        let bookRootPath = "\(bookCode)_book"
        let bundleBooksPath = (resourcePath as NSString).appendingPathComponent("Books")
        let bundleBookPath = (bundleBooksPath as NSString).appendingPathComponent(bookRootPath)
        
        return fileManager.fileExists(atPath: bundleBookPath)
    }
    
    /// Checks if a book is downloaded (in Application Support, not bundle)
    func isBookDownloadedOnly(bookCode: String) -> Bool {
        let downloadedPath = booksDirectory.appendingPathComponent("\(bookCode)_book", isDirectory: true)
        return FileManager.default.fileExists(atPath: downloadedPath.path)
    }
}

// MARK: - Download Errors

enum DownloadError: LocalizedError {
    case productNotFound
    case noHostedContent
    case alreadyDownloading
    case verificationFailed(Error)
    case userCancelled
    case purchasePending
    case downloadFailed(Error)
    case extractionFailed(String)
    case bookNotDownloaded
    case mustDownloadFirst
    case unknownError
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Book product not found. Please try again later."
        case .noHostedContent:
            return "This book has no downloadable content."
        case .alreadyDownloading:
            return "This book is already being downloaded."
        case .verificationFailed(let error):
            return "Download verification failed: \(error.localizedDescription)"
        case .userCancelled:
            return "Download was cancelled."
        case .purchasePending:
            return "Purchase is pending. Please wait for it to complete."
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .extractionFailed(let reason):
            return "Failed to extract book: \(reason)"
        case .bookNotDownloaded:
            return "Book is not downloaded."
        case .mustDownloadFirst:
            return "This book is part of the app. Please download it first (this will copy it so you can delete it later), then you can delete it."
        case .unknownError:
            return "An unknown error occurred."
        case .notImplemented(let feature):
            return "Feature not yet implemented: \(feature)"
        }
    }
}

