//
//  MiniPlayerView.swift
//  EchoBooks3
//
//  Mini-player component that appears at the bottom of LibraryView
//  to allow quick return to the last listened book.
//

import SwiftUI
import SwiftData
import UIKit

struct MiniPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var lastBook: Book? = nil
    @State private var allBooks: [Book] = []
    
    var body: some View {
        Group {
            if let book = lastBook {
                NavigationLink(destination: BookDetailView(book: book)) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        // Cover Image
                        coverImage(for: book)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipped()
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                        
                        // Book Title and Info
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(book.bookTitle)
                                .font(DesignSystem.Typography.bodySmall)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .lineLimit(1)
                            
                            Text("Tap to continue")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Play Button
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.cardBackground)
                    .shadow(DesignSystem.Shadow.small)
                }
            } else {
                // Placeholder while loading or if no book found
                HStack {
                    Spacer()
                    Text("Loading...")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.cardBackground)
                .shadow(DesignSystem.Shadow.small)
            }
        }
        .onAppear {
            loadLastBook()
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
    
    // MARK: - Load Last Book
    
    func loadLastBook() {
        // First, load all books from BookImporter
        allBooks = BookImporter.importBooks()
        
        let globalStateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let fetchRequest = FetchDescriptor<AppState>(predicate: #Predicate<AppState> { state in
            return state.id == globalStateID
        })
        
        if let appState = try? modelContext.fetch(fetchRequest).first,
           appState.lastBookUnfinished,
           let bookID = appState.lastOpenedBookID {
            print("🔍 MiniPlayerView: Loading book with ID: \(bookID.uuidString)")
            // Find the book in the imported books list instead of SwiftData
            lastBook = allBooks.first { $0.id == bookID }
            if lastBook != nil {
                print("✅ MiniPlayerView: Successfully loaded book: \(lastBook!.bookTitle)")
            } else {
                print("❌ MiniPlayerView: Book not found in imported books (have \(allBooks.count) books)")
            }
        } else {
            print("🔍 MiniPlayerView: No unfinished book or no book ID")
            lastBook = nil
        }
    }
}

