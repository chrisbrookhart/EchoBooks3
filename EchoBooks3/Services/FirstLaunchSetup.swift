//
//  FirstLaunchSetup.swift
//  EchoBooks3
//
//  Handles first launch setup, including copying example books from bundle
//  to Application Support so they can be deleted by users.
//

import Foundation
import SwiftData

struct FirstLaunchSetup {
    
    /// Book codes for example books that should be copied on first launch
    /// These books are included in the bundle but copied to Application Support
    /// so users can delete them to save space
    static let exampleBookCodes: [String] = [
        // Add book codes for example books here
        // Example: "CLOCK", "LENAW"
        // Leave empty if you don't want any books copied automatically
    ]
    
    /// Performs first launch setup if needed
    /// - Parameter modelContext: SwiftData model context
    static func performFirstLaunchSetup(modelContext: ModelContext) async {
        // Check if setup has already been completed
        let globalStateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let fetchRequest = FetchDescriptor<AppState>(predicate: #Predicate<AppState> { state in
            return state.id == globalStateID
        })
        
        let appState: AppState
        if let existingState = try? modelContext.fetch(fetchRequest).first {
            appState = existingState
            if appState.hasCompletedFirstLaunchSetup {
                // Setup already completed
                return
            }
        } else {
            // Create new app state
            appState = AppState()
            modelContext.insert(appState)
        }
        
        // Copy example books to Application Support
        await copyExampleBooksToApplicationSupport()
        
        // Mark setup as complete
        appState.hasCompletedFirstLaunchSetup = true
        
        // Save the state
        try? modelContext.save()
        
        print("✅ FirstLaunchSetup: Completed first launch setup")
    }
    
    /// Copies example books from bundle to Application Support
    /// This allows users to delete them later to save space
    @MainActor
    private static func copyExampleBooksToApplicationSupport() async {
        guard !exampleBookCodes.isEmpty else {
            print("ℹ️ FirstLaunchSetup: No example books configured")
            return
        }
        
        let fileManager = FileManager.default
        let downloadManager = BookDownloadManager()
        
        // Get bundle path
        guard let resourcePath = Bundle.main.resourcePath else {
            print("❌ FirstLaunchSetup: Could not access bundle")
            return
        }
        
        let bundleBooksPath = (resourcePath as NSString).appendingPathComponent("Books")
        
        // Copy each example book
        for bookCode in exampleBookCodes {
            let bookRootPath = "\(bookCode)_book"
            let bundleBookPath = (bundleBooksPath as NSString).appendingPathComponent(bookRootPath)
            
            // Check if book exists in bundle
            guard fileManager.fileExists(atPath: bundleBookPath) else {
                print("⚠️ FirstLaunchSetup: Example book \(bookCode) not found in bundle")
                continue
            }
            
            // Check if already copied
            if downloadManager.isBookDownloadedOnly(bookCode: bookCode) {
                print("ℹ️ FirstLaunchSetup: Example book \(bookCode) already in Application Support, skipping")
                continue
            }
            
            // Copy to Application Support
            do {
                // Get all available languages from the book
                let audioPath = (bundleBookPath as NSString).appendingPathComponent("audio")
                var availableLanguages: [LanguageCode] = []
                
                if fileManager.fileExists(atPath: audioPath),
                   let audioContents = try? fileManager.contentsOfDirectory(atPath: audioPath) {
                    for langFolder in audioContents {
                        let langFolderPath = (audioPath as NSString).appendingPathComponent(langFolder)
                        var isDirectory: ObjCBool = false
                        if fileManager.fileExists(atPath: langFolderPath, isDirectory: &isDirectory),
                           isDirectory.boolValue,
                           let languageCode = LanguageCode.fromCode(langFolder) {
                            availableLanguages.append(languageCode)
                        }
                    }
                }
                
                // Copy with all available languages (user can delete later if needed)
                // If no languages found, pass empty array (will copy everything)
                try await downloadManager.downloadBook(
                    productIdentifier: nil, // Bundle book, no product ID
                    bookCode: bookCode,
                    selectedLanguages: availableLanguages
                )
                
                print("✅ FirstLaunchSetup: Copied example book \(bookCode) to Application Support")
            } catch {
                print("❌ FirstLaunchSetup: Failed to copy example book \(bookCode): \(error.localizedDescription)")
            }
        }
    }
}

