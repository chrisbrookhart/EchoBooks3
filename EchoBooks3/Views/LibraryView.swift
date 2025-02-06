//
//  LibraryView.swift
//  EchoBooks3
//
//  Created by [Your Name] on [Date].
//  This view displays a list of available books by leveraging the BookImporter.
//  It decodes unified structure JSON files from the bundle and displays the imported books.
//

import SwiftUI

struct LibraryView: View {
    // State variable to hold imported books.
    @State private var books: [Book] = []
    
    var body: some View {
        NavigationStack {
            List(books, id: \.id) { book in
                NavigationLink(destination: BookDetailViewStub(book: book)) {
                    HStack {
                        // Use a placeholder image (system image "book"); replace with your asset if available.
                        Image(systemName: "book")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(4)
                        VStack(alignment: .leading) {
                            Text(book.bookTitle)
                                .font(.headline)
                            Text(book.author)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Library")
        }
        .onAppear {
            // When the view appears, import the books.
            self.books = BookImporter.importBooks()
        }
    }
}

// MARK: - Stub Detail View

struct BookDetailViewStub: View {
    let book: Book
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Title: \(book.bookTitle)")
                .font(.title)
            Text("Author: \(book.author)")
                .font(.subheadline)
            Text("Description: \(book.bookDescription ?? "N/A")")
                .font(.body)
            Spacer()
        }
        .padding()
        .navigationTitle(book.bookTitle)
    }
}

// MARK: - Preview

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}
