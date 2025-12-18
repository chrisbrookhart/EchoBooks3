//
//  BookItemView.swift
//  EchoBooks3
//
//  A reusable view that displays a single book's cover image and title.
//  Supports long press for deletion (for downloaded books) and lock icon overlay
//  for subscription-required books.
//

import SwiftUI
import UIKit

struct BookItemView: View {
    // MARK: - Properties
    
    let book: Book
    let width: CGFloat
    let height: CGFloat
    let isSubscribed: Bool
    let isDownloaded: Bool // True if book is in Application Support, false if in bundle
    let onDelete: (() -> Void)?
    
    // MARK: - State
    
    @State private var showDeleteButton: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ZStack(alignment: .bottomTrailing) {
                // Cover Image
                coverImage(for: book)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
                    .cornerRadius(DesignSystem.CornerRadius.bookCover)
                    .shadow(DesignSystem.Shadow.card)
                    .onLongPressGesture {
                        // Only show delete for downloaded books (not bundle books)
                        if isDownloaded, onDelete != nil {
                            showDeleteButton = true
                        }
                    }
                
                // Lock Icon (for non-free books when not subscribed)
                if !book.isFree && !isSubscribed {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .padding(8)
                }
                
                // Delete Button Overlay (shown on long press)
                if showDeleteButton && isDownloaded {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .shadow(DesignSystem.Shadow.medium)
                            }
                            .padding(8)
                        }
                    }
                }
            }
            
            // Book Title
            Text(book.bookTitle)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(4)
                .multilineTextAlignment(.center)
                .frame(width: width, height: 60) // Reserve space for up to 4 lines
        }
        .alert("Delete Book", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                showDeleteButton = false
            }
            Button("Delete", role: .destructive) {
                onDelete?()
                showDeleteButton = false
            }
        } message: {
            Text("Delete \"\(book.bookTitle)\"? This will free up storage space.")
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                // Dismiss delete button if visible (but don't block NavigationLink)
                if showDeleteButton {
                    showDeleteButton = false
                }
            }
        )
    }
    
    // MARK: - Helper Methods
    
    /// Returns an Image for the book's cover, checking downloaded book folder first, then bundle.
    private func coverImage(for book: Book) -> Image {
        CoverImageLoader.loadCoverImage(for: book)
    }
}

struct BookItemView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            BookItemView(
                book: Book(
                    bookTitle: "Sample Book",
                    author: "Author",
                    languages: [.enUS],
                    coverImageName: "DefaultCover",
                    bookCode: "SAMPLE",
                    isFree: false
                ),
                width: 100,
                height: 150,
                isSubscribed: false,
                isDownloaded: true,
                onDelete: { print("Delete tapped") }
            )
            
            BookItemView(
                book: Book(
                    bookTitle: "Free Book",
                    author: "Author",
                    languages: [.enUS],
                    coverImageName: "DefaultCover",
                    bookCode: "FREE",
                    isFree: true
                ),
                width: 100,
                height: 150,
                isSubscribed: true,
                isDownloaded: false,
                onDelete: nil
            )
        }
        .padding()
    }
}
