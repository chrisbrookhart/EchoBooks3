//
//  RootView.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/8/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    
    // This state will determine which view to show.
    @State private var initialView: LastOpenedView = .library
    @State private var lastOpenedBook: Book? = nil
    
    var body: some View {
        Group {
            if initialView == .bookDetail, let book = lastOpenedBook {
                BookDetailView(book: book)
            } else {
                LibraryView()
            }
        }
        .onAppear {
            loadGlobalAppState()
        }
    }
    
    private func loadGlobalAppState() {
        // Define a fixed global state identifier.
        let globalStateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let fetchRequest = FetchDescriptor<AppState>(predicate: #Predicate<AppState> { state in
            return state.id == globalStateID
        })
        
        if let appState = try? modelContext.fetch(fetchRequest).first {
            initialView = appState.lastOpenedView
            if appState.lastOpenedView == .bookDetail, let bookID = appState.lastOpenedBookID {
                // Fetch the corresponding Book.
                let bookFetch = FetchDescriptor<Book>(predicate: #Predicate<Book> { book in
                    return book.id == bookID
                })
                lastOpenedBook = try? modelContext.fetch(bookFetch).first
            }
        } else {
            // If no global state exists, default to the library.
            initialView = .library
        }
    }
}
