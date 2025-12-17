// 
//  LibraryView.swift
//  This view displays two horizontal sections: one for books on device and one for books available for download.
//  It uses a responsive layout, a search bar in the navigation bar, and a subscription icon that navigates
//  to a placeholder Manage Subscription view.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State Variables
    @State private var books: [Book] = []          // Downloaded books imported from the bundle.
    @State private var searchText: String = ""       // Search text.
    @State private var showMiniPlayer: Bool = false  // Whether to show the mini-player
    
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
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    // Compute item dimensions based on available width.
                    let screenWidth = geometry.size.width
                    let itemWidth = max(DesignSystem.Layout.bookCoverMinWidth, screenWidth * 0.25)
                    let itemHeight = itemWidth * 1.5  // Assume a 2:3 ratio for a typical book cover.
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sectionSpacing) {
                            // On Device Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text("On Device")
                                    .font(DesignSystem.Typography.h2)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                
                                if filteredBooks.isEmpty {
                                    // Empty state view for downloaded books.
                                    VStack(spacing: DesignSystem.Spacing.sm) {
                                        Text("No downloaded books found.")
                                            .font(DesignSystem.Typography.body)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        Text("Please download some books.")
                                            .font(DesignSystem.Typography.bodySmall)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(DesignSystem.Spacing.lg)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: DesignSystem.Spacing.md) {
                                            ForEach(filteredBooks, id: \.id) { book in
                                                NavigationLink(destination: BookInfoView(book: book)) {
                                                    VStack(spacing: DesignSystem.Spacing.xs) {
                                                        coverImage(for: book)
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: itemWidth, height: itemHeight)
                                                            .clipped()
                                                            .cornerRadius(DesignSystem.CornerRadius.bookCover)
                                                            .shadow(DesignSystem.Shadow.card)
                                                        Text(book.bookTitle)
                                                            .font(DesignSystem.Typography.caption)
                                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                                            .lineLimit(4)
                                                            .multilineTextAlignment(.center)
                                                            .frame(width: itemWidth, height: 60) // Reserve space for up to 4 lines
                                                    }
                                                    .transition(.opacity)
                                                    .animation(DesignSystem.Animation.springQuick, value: filteredBooks.count)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                    }
                                }
                            }
                            
                            // Available for Download Section (Placeholder)
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text("Available for Download")
                                    .font(DesignSystem.Typography.h2)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: DesignSystem.Spacing.md) {
                                        ForEach(0..<7, id: \.self) { index in
                                            VStack(spacing: DesignSystem.Spacing.xs) {
                                                Image("DefaultCover")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: itemWidth, height: itemHeight)
                                                    .clipped()
                                                    .cornerRadius(DesignSystem.CornerRadius.bookCover)
                                                    .shadow(DesignSystem.Shadow.card)
                                                Text("Placeholder \(index + 1)")
                                                    .font(DesignSystem.Typography.caption)
                                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                                    .lineLimit(3)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: itemWidth)  // Constrain width for wrapping.
                                            }
                                            .transition(.opacity)
                                            .animation(DesignSystem.Animation.springQuick, value: index)
                                        }
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                }
                            }
                            
                            // Add bottom padding if mini-player is showing
                            if showMiniPlayer {
                                Spacer()
                                    .frame(height: 80) // Space for mini-player
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.lg)
                    }
                }
                
                // Mini-Player at bottom
                if showMiniPlayer {
                    MiniPlayerView()
                }
            }
            .navigationTitle("")
            .toolbar {
                // Subscription icon in the top-right.
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ManageSubscriptionView()) {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Books")
        .onAppear {
            self.books = BookImporter.importBooks()
            checkForUnfinishedBook()
        }
        .onChange(of: books.count) { _, _ in
            // Re-check when books are loaded
            checkForUnfinishedBook()
        }
        .refreshable {
            // Allow pull-to-refresh to update mini-player
            checkForUnfinishedBook()
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
    
    // MARK: - Helper: Check for Unfinished Book
    /// Checks if there's an unfinished book and shows/hides the mini-player accordingly
    private func checkForUnfinishedBook() {
        let globalStateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let fetchRequest = FetchDescriptor<AppState>(predicate: #Predicate<AppState> { state in
            return state.id == globalStateID
        })
        
        if let appState = try? modelContext.fetch(fetchRequest).first {
            let shouldShow = appState.lastBookUnfinished && appState.lastOpenedBookID != nil
            print("🔍 LibraryView: Checking unfinished book - lastBookUnfinished: \(appState.lastBookUnfinished), lastOpenedBookID: \(appState.lastOpenedBookID?.uuidString ?? "nil"), shouldShow: \(shouldShow)")
            showMiniPlayer = shouldShow
        } else {
            print("🔍 LibraryView: No AppState found")
            showMiniPlayer = false
        }
    }
    
    // MARK: - Helper: Load Mini Player Book
    /// Loads the last book for the mini-player
    private func loadMiniPlayerBook() {
        // This will be handled by MiniPlayerView's onAppear
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}
