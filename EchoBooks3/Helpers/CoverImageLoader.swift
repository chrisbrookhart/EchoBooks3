//
//  CoverImageLoader.swift
//  EchoBooks3
//
//  Helper for loading cover images from downloaded books or bundle assets.
//  Checks downloaded book folder first, then bundle book folder, then bundle assets.
//

import Foundation
import SwiftUI
import UIKit

struct CoverImageLoader {
    
    /// Loads a cover image for a book, checking multiple locations in order:
    /// 1. Downloaded book folder (Application Support)
    /// 2. Bundle book folder
    /// 3. Bundle assets (UIImage(named:))
    /// 4. Default cover
    /// - Parameters:
    ///   - book: The book to load the cover for
    /// - Returns: A SwiftUI Image
    static func loadCoverImage(for book: Book) -> Image {
        let fileManager = FileManager.default
        let bookRootPath = "\(book.bookCode)_book"
        let coverName = (book.coverImageName as NSString).deletingPathExtension
        
        // Try multiple possible locations and extensions
        let possibleExtensions = ["png", "jpg", "jpeg"]
        let possiblePaths = [
            "universal/covers/\(coverName)",
            "universal/\(coverName)",
            "covers/\(coverName)",
            coverName
        ]
        
        // 1. Check Application Support (downloaded books)
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let booksPath = appSupport.appendingPathComponent("Books", isDirectory: true)
            let bookPath = booksPath.appendingPathComponent(bookRootPath, isDirectory: true)
            
            // Try different possible locations
            let locations = [
                "universal/covers",
                "universal",
                "covers",
                ""
            ]
            
            for location in locations {
                for ext in possibleExtensions {
                    let fileName = "\(coverName).\(ext)"
                    let imagePath: URL
                    if location.isEmpty {
                        imagePath = bookPath.appendingPathComponent(fileName)
                    } else {
                        imagePath = bookPath.appendingPathComponent(location).appendingPathComponent(fileName)
                    }
                    
                    if fileManager.fileExists(atPath: imagePath.path),
                       let uiImage = UIImage(contentsOfFile: imagePath.path) {
                        return Image(uiImage: uiImage)
                    }
                }
            }
        }
        
        // 2. Check Bundle book folder
        let bundleLocations = [
            "Books/\(bookRootPath)/universal/covers",
            "Books/\(bookRootPath)/universal",
            "Books/\(bookRootPath)/covers",
            "Books/\(bookRootPath)"
        ]
        
        for location in bundleLocations {
            for ext in possibleExtensions {
                if let url = Bundle.main.url(
                    forResource: coverName,
                    withExtension: ext,
                    subdirectory: location
                ), let uiImage = UIImage(contentsOfFile: url.path) {
                    return Image(uiImage: uiImage)
                }
            }
        }
        
        // 3. Check bundle assets (UIImage(named:))
        if UIImage(named: coverName) != nil {
            return Image(coverName)
        }
        
        // 4. Fall back to default cover
        return Image("DefaultCover")
    }
}

