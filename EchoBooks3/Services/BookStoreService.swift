//
//  BookStoreService.swift
//  EchoBooks3
//
//  Fetches available books by loading metadata from app bundle and combining
//  with StoreKit product information. All users can see all books (metadata is
//  in app bundle), but subscription status determines download access.
//

import Foundation
import StoreKit

@MainActor
class BookStoreService: ObservableObject {
    // MARK: - Properties
    
    /// All available books (from bundle metadata + StoreKit)
    @Published var availableBooks: [Book] = []
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    /// Error state
    @Published var error: Error?
    
    // MARK: - Fetch Available Books
    
    /// Fetches all available books by loading metadata from bundle and StoreKit products
    func fetchAvailableBooks() async throws {
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
        }
        
        // Load book metadata from app bundle
        let bundleBooks = loadBooksFromBundle()
        
        // Fetch StoreKit products for all books
        let productIdentifiers = bundleBooks.compactMap { $0.productIdentifier }
        let products = try await fetchStoreKitProducts(identifiers: productIdentifiers)
        
        // Combine bundle metadata with StoreKit product info
        var combinedBooks: [Book] = []
        
        for bundleBook in bundleBooks {
            // Always include books from bundle metadata
            // If StoreKit product exists, book is downloadable
            // If not, book is still visible but download button will be disabled
            if let productIdentifier = bundleBook.productIdentifier {
                // Check if product exists in StoreKit
                if products.contains(where: { $0.id == productIdentifier }) {
                    // Product exists - book is downloadable
                    combinedBooks.append(bundleBook)
                } else {
                    // Product ID exists but not found in StoreKit
                    // Still show the book (it will appear but download will be disabled)
                    // This allows the app to work even if StoreKit isn't configured yet
                    print("⚠️ BookStoreService: Product \(productIdentifier) not found in StoreKit - book will be visible but not downloadable")
                    combinedBooks.append(bundleBook)
                }
            } else {
                // No product identifier - bundle-only book (not downloadable)
                combinedBooks.append(bundleBook)
            }
        }
        
        availableBooks = combinedBooks
    }
    
    // MARK: - Load Books from Bundle
    
    /// Loads book metadata from app bundle (book_title.json files)
    private func loadBooksFromBundle() -> [Book] {
        var books: [Book] = []
        
        guard let resourcePath = Bundle.main.resourcePath else {
            print("❌ BookStoreService: Could not get bundle resource path")
            return books
        }
        
        let fileManager = FileManager.default
        let booksPath = (resourcePath as NSString).appendingPathComponent("Books")
        
        guard fileManager.fileExists(atPath: booksPath) else {
            print("❌ BookStoreService: Books folder not found")
            return books
        }
        
        // Find all book_title.json files
        func findBookTitleFiles(in directory: String) -> [String] {
            var foundFiles: [String] = []
            
            guard let enumerator = fileManager.enumerator(atPath: directory) else {
                return foundFiles
            }
            
            for case let item as String in enumerator {
                let fullPath = (directory as NSString).appendingPathComponent(item)
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory),
                   !isDirectory.boolValue {
                    let fileName = (item as NSString).lastPathComponent
                    if fileName == "book_title.json" {
                        foundFiles.append(fullPath)
                    }
                }
            }
            
            return foundFiles
        }
        
        let bookTitleFilePaths = findBookTitleFiles(in: booksPath)
        
        // Load metadata from each book_title.json
        for filePath in bookTitleFilePaths {
            let url = URL(fileURLWithPath: filePath)
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let metadata = try decoder.decode(BookMetadata.self, from: data)
                
                // Convert to Book object (similar to BookImporter logic)
                guard let bookID = UUID(uuidString: metadata.bookID) else {
                    print("⚠️ BookStoreService: Invalid book ID: \(metadata.bookID)")
                    continue
                }
                
                let languageCodes = metadata.languages.compactMap { langString in
                    LanguageCode.fromCode(langString)
                }
                
                guard !languageCodes.isEmpty else {
                    print("⚠️ BookStoreService: No valid languages for book: \(metadata.bookCode)")
                    continue
                }
                
                // Create a minimal Book object (we don't need full structure for store listing)
                let book = Book(
                    id: bookID,
                    bookTitle: metadata.bookTitle,
                    author: metadata.author,
                    languages: languageCodes,
                    bookDescription: metadata.bookDescription,
                    coverImageName: metadata.coverImageName,
                    bookCode: metadata.bookCode,
                    bookLevel: metadata.bookLevel,
                    learningTheme: metadata.learningTheme,
                    whatYouWillPractice: metadata.whatYouWillPractice,
                    estimatedLength: metadata.estimatedLength,
                    isFree: metadata.isFree ?? false,
                    productIdentifier: metadata.productIdentifier,
                    subBooks: nil // Will be loaded when book is actually imported
                )
                
                books.append(book)
            } catch {
                print("❌ BookStoreService: Failed to load book metadata from \(filePath): \(error.localizedDescription)")
                continue
            }
        }
        
        return books
    }
    
    // MARK: - StoreKit Product Fetching
    
    /// Fetches StoreKit products for the given product identifiers
    /// Returns empty array if StoreKit is not configured (won't crash)
    private func fetchStoreKitProducts(identifiers: [String]) async throws -> [Product] {
        guard !identifiers.isEmpty else {
            return []
        }
        
        do {
            let products = try await Product.products(for: identifiers)
            // Filter out products that don't exist (StoreKit returns empty array for invalid IDs)
            return products.filter { product in
                identifiers.contains(product.id)
            }
        } catch {
            print("⚠️ BookStoreService: StoreKit not configured or products not found: \(error.localizedDescription)")
            print("   This is expected if App Store Connect products are not set up yet.")
            // Return empty array instead of throwing - app won't crash
            // Books will still be visible from bundle metadata, just won't be downloadable
            return []
        }
    }
    
    // MARK: - Get Product for Book
    
    /// Gets the StoreKit product for a specific book
    func getProduct(for bookCode: String) async -> Product? {
        // Find book in available books
        guard let book = availableBooks.first(where: { $0.bookCode == bookCode }),
              let productID = book.productIdentifier else {
            return nil
        }
        
        do {
            let products = try await Product.products(for: [productID])
            return products.first
        } catch {
            print("❌ BookStoreService: Failed to get product for \(bookCode): \(error.localizedDescription)")
            return nil
        }
    }
}

