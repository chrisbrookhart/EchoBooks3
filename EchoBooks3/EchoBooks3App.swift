
// EchoBooks3App.swift 

import SwiftUI
import SwiftData

@main
struct EchoBooks3App: App {
    // Create a shared model container that registers your new models.
    var sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([
                Book.self,
                SubBook.self,
                Chapter.self,
                Paragraph.self,
                Sentence.self,
                BookState.self,
                AppState.self
            ])
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            // Use the RootView to determine which view to present.
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

