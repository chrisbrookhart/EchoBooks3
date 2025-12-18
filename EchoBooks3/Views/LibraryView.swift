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
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var bookStoreService = BookStoreService()
    @StateObject private var downloadManager = BookDownloadManager()
    
    @State private var books: [Book] = []          // Downloaded books imported from bundle + Application Support
    @State private var availableBooks: [Book] = [] // All available books (from BookStoreService)
    @State private var searchText: String = ""       // Search text
    @State private var showMiniPlayer: Bool = false  // Whether to show the mini-player
    
    // MARK: - Computed Properties
    
    /// Books that are downloaded (on device - bundle or Application Support)
    /// For testing: bundle books show here so they can be used immediately
    private var downloadedBooks: [Book] {
        books.filter { downloadManager.isBookDownloaded(bookCode: $0.bookCode) }
    }
    
    /// Books that are available for download (not on device)
    private var booksForDownload: [Book] {
        availableBooks.filter { book in
            !downloadManager.isBookDownloaded(bookCode: book.bookCode)
        }
    }
    
    /// Filters downloaded books by search text
    private var filteredDownloadedBooks: [Book] {
        let filtered = downloadedBooks
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.bookTitle.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    /// Filters available books by search text
    private var filteredAvailableBooks: [Book] {
        let filtered = booksForDownload
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.bookTitle.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    /// Checks if a book is downloaded (in Application Support only)
    /// Used for deletion - only Application Support books can be deleted
    private func isBookDownloaded(_ book: Book) -> Bool {
        downloadManager.isBookDownloadedOnly(bookCode: book.bookCode)
    }
    
    /// Checks if a book is in the bundle (cannot be deleted)
    private func isBookInBundle(_ book: Book) -> Bool {
        downloadManager.isBookInBundle(bookCode: book.bookCode)
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
                                
                                if filteredDownloadedBooks.isEmpty {
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
                                            ForEach(filteredDownloadedBooks, id: \.id) { book in
                                                NavigationLink(destination: BookInfoView(book: book)) {
                                                    BookItemView(
                                                        book: book,
                                                        width: itemWidth,
                                                        height: itemHeight,
                                                        isSubscribed: subscriptionManager.isSubscribed,
                                                        isDownloaded: isBookDownloaded(book), // Only true for Application Support books
                                                        onDelete: isBookDownloaded(book) ? { // Only allow delete for downloaded books
                                                            deleteBook(book)
                                                        } : nil
                                                    )
                                                    .transition(.opacity)
                                                    .animation(DesignSystem.Animation.springQuick, value: filteredDownloadedBooks.count)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                    }
                                }
                            }
                            
                            // Available for Download Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text("Available for Download")
                                    .font(DesignSystem.Typography.h2)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                
                                if bookStoreService.isLoading {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                    .padding(DesignSystem.Spacing.lg)
                                } else if filteredAvailableBooks.isEmpty {
                                    VStack(spacing: DesignSystem.Spacing.sm) {
                                        Text("No books available for download.")
                                            .font(DesignSystem.Typography.body)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(DesignSystem.Spacing.lg)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: DesignSystem.Spacing.md) {
                                            ForEach(filteredAvailableBooks, id: \.id) { book in
                                                NavigationLink(destination: BookInfoView(book: book)) {
                                                    BookItemView(
                                                        book: book,
                                                        width: itemWidth,
                                                        height: itemHeight,
                                                        isSubscribed: subscriptionManager.isSubscribed,
                                                        isDownloaded: false, // Not downloaded yet
                                                        onDelete: nil // Can't delete what's not downloaded
                                                    )
                                                    .transition(.opacity)
                                                    .animation(DesignSystem.Animation.springQuick, value: filteredAvailableBooks.count)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                    }
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
        .task {
            // Load books and available books on appear
            await loadBooks()
        }
        .refreshable {
            // Refresh on pull-to-refresh
            await loadBooks()
            checkForUnfinishedBook()
        }
        .onChange(of: books.count) { _, _ in
            // Re-check when books are loaded
            checkForUnfinishedBook()
        }
    }
    
    // MARK: - Helper: Load Books
    
    /// Loads books from both bundle/Application Support and available books from StoreKit
    private func loadBooks() async {
        // Load downloaded books (bundle + Application Support)
        self.books = BookImporter.importBooks()
        
        // Load available books from StoreKit
        do {
            try await bookStoreService.fetchAvailableBooks()
            self.availableBooks = bookStoreService.availableBooks
        } catch {
            print("❌ LibraryView: Failed to load available books: \(error.localizedDescription)")
        }
        
        // Check subscription status
        await subscriptionManager.checkSubscriptionStatus()
    }
    
    // MARK: - Helper: Delete Book
    
    /// Deletes a downloaded book
    private func deleteBook(_ book: Book) {
        do {
            try downloadManager.deleteBook(bookCode: book.bookCode)
            // Refresh books list
            self.books = BookImporter.importBooks()
        } catch {
            print("❌ LibraryView: Failed to delete book: \(error.localizedDescription)")
            // TODO: Show error alert to user
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
