//
//  LibraryView.swift
//  EchoBooks3
//
//  Created by [Your Name] on [Date].
//  This view displays two horizontal sections: one for books on device and one for books available for download.
//  It uses a responsive layout, a search bar in the navigation bar, and a subscription icon that navigates
//  to a placeholder Manage Subscription view.
//

import SwiftUI

struct LibraryView: View {
    // MARK: - State Variables
    @State private var books: [Book] = []          // Downloaded books imported from the bundle.
    @State private var searchText: String = ""       // Search text.
    
    // MARK: - Computed Properties
    /// Filters the downloaded books by title.
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { $0.bookTitle.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                // Compute item dimensions based on available width.
                let screenWidth = geometry.size.width
                let itemWidth = max(80, screenWidth * 0.25)
                let itemHeight = itemWidth * 1.5  // Assume a 2:3 ratio for a typical book cover.
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // On Device Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("On Device")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if filteredBooks.isEmpty {
                                // Empty state view for downloaded books.
                                VStack(spacing: 8) {
                                    Text("No downloaded books found.")
                                    Text("Please download some books.")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(filteredBooks, id: \.id) { book in
                                            // Essential change: open BookDetailView instead of BookDetailViewStub.
                                            NavigationLink(destination: BookDetailView(book: book)) {
                                                VStack(spacing: 4) {
                                                    coverImage(for: book)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: itemWidth, height: itemHeight)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                    Text(book.bookTitle)
                                                        .font(.caption)
                                                        .foregroundColor(.primary)
                                                        .lineLimit(3)
                                                        .multilineTextAlignment(.center)
                                                }
                                                .transition(.opacity)
                                                .animation(.easeInOut, value: filteredBooks.count)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Available for Download Section (Placeholder)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Available for Download")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(0..<7, id: \.self) { index in
                                        VStack(spacing: 4) {
                                            Image("DefaultCover")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: itemWidth, height: itemHeight)
                                                .clipped()
                                                .cornerRadius(8)
                                            Text("Placeholder \(index + 1)")
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .lineLimit(3)
                                                .multilineTextAlignment(.center)
                                        }
                                        .transition(.opacity)
                                        .animation(.easeInOut, value: index)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            // Remove any default navigation title.
            .navigationTitle("")
            .toolbar {
                // Subscription icon in the top-right.
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ManageSubscriptionView()) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
        // Place the search bar in the navigation bar.
        .searchable(text: $searchText, prompt: "Search Books")
        .onAppear {
            self.books = BookImporter.importBooks()
        }
    }
    
    // MARK: - Helper: Cover Image Lookup
    /// Returns an Image for the book's cover by stripping any file extension from the coverImageName.
    private func coverImage(for book: Book) -> Image {
        let assetName = (book.coverImageName as NSString).deletingPathExtension
        if UIImage(named: assetName) != nil {
            return Image(assetName)
        } else {
            return Image("DefaultCover")
        }
    }
}

// MARK: - Stub Detail View (for preview fallback; should be replaced by your new BookDetailView)
struct BookDetailViewStub: View {
    let book: Book
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

