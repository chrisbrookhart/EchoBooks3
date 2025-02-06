//
//  BookImporter.swift
//  EchoBooks3
//
//  Created by [Your Name] on [Date].
//
//  This helper scans the app bundle for JSON files with "structure" in their filename
//  and decodes them into Book objects using the unified structure JSON format.
//

import Foundation

struct BookImporter {
    
    /// Scans the bundle for JSON files whose filenames contain "structure" and decodes them as Books.
    /// - Returns: An array of decoded Book objects.
    static func importBooks() -> [Book] {
        var books: [Book] = []
        let decoder = JSONDecoder()
        
        // Find all JSON files in the main bundle.
        guard let jsonURLs = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            print("No JSON files found in the bundle.")
            return books
        }
        
        // Filter for files whose names include "structure".
        let structureURLs = jsonURLs.filter { url in
            url.lastPathComponent.lowercased().contains("structure")
        }
        
        print("Found \(structureURLs.count) structure file(s).")
        for url in structureURLs {
            do {
                let data = try Data(contentsOf: url)
                let book = try decoder.decode(Book.self, from: data)
                books.append(book)
                print("Imported book: \(book.bookTitle)")
            } catch {
                print("Error decoding book structure from \(url.lastPathComponent): \(error)")
            }
        }
        
        return books
    }
}
