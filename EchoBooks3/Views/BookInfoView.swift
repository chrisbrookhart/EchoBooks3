//
//  BookInfoView.swift
//  EchoBooks3
//
//  Displays detailed information about a book, including cover, description,
//  learning theme, practice areas, and estimated length. Shows a Download or
//  Start Reading button based on whether the book is on device.
//

import SwiftUI
import UIKit

struct BookInfoView: View {
    // MARK: - Properties
    
    let book: Book
    
    // MARK: - State
    
    @State private var isOnDevice: Bool = false
    @State private var availableLanguages: [LanguageCode] = []
    @State private var showLevelInfo: Bool = false
    
    // MARK: - Computed Properties
    
    /// Determines if the book is on device by checking if it exists in imported books
    private func checkIfOnDevice() {
        let onDeviceBooks = BookImporter.importBooks()
        isOnDevice = onDeviceBooks.contains { $0.id == book.id }
    }
    
    /// Determines available languages by checking the audio folder structure
    private func loadAvailableLanguages() {
        guard let resourcePath = Bundle.main.resourcePath else {
            return
        }
        
        let fileManager = FileManager.default
        let bookRootPath = "\(book.bookCode)_book"
        let booksPath = (resourcePath as NSString).appendingPathComponent("Books")
        let audioFolderPath = (booksPath as NSString).appendingPathComponent("\(bookRootPath)/audio")
        
        guard fileManager.fileExists(atPath: audioFolderPath) else {
            return
        }
        
        guard let audioContents = try? fileManager.contentsOfDirectory(atPath: audioFolderPath) else {
            return
        }
        
        var languages: [LanguageCode] = []
        for langFolder in audioContents {
            // Check if it's a directory
            let langFolderPath = (audioFolderPath as NSString).appendingPathComponent(langFolder)
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: langFolderPath, isDirectory: &isDirectory), isDirectory.boolValue {
                // Try to map the folder name to a LanguageCode
                if let languageCode = LanguageCode.fromCode(langFolder) {
                    languages.append(languageCode)
                }
            }
        }
        
        // Sort languages for consistent display
        availableLanguages = languages.sorted { $0.name < $1.name }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Cover Image
                coverImage(for: book)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 300)
                    .cornerRadius(DesignSystem.CornerRadius.card)
                    .shadow(DesignSystem.Shadow.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.top, DesignSystem.Spacing.md)
                
                // Book Title
                Text(book.bookTitle)
                    .font(DesignSystem.Typography.displayMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                
                // Book Level
                if let bookLevel = book.bookLevel {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text("Book Level")
                                .font(DesignSystem.Typography.h3)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Button(action: {
                                showLevelInfo = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(DesignSystem.Typography.label)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        Text("\(bookLevel)")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
                
                // Available Languages
                if !availableLanguages.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Available Languages")
                            .font(DesignSystem.Typography.h3)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            ForEach(availableLanguages, id: \.id) { language in
                                HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                                    Text("•")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    Text(language.name)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
                
                // Book Description
                if let description = book.bookDescription, !description.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Description")
                            .font(DesignSystem.Typography.h3)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Text(description)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineSpacing(DesignSystem.Spacing.xs)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
                
                // Learning Theme
                if let learningTheme = book.learningTheme {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Learning Theme")
                            .font(DesignSystem.Typography.h3)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Text(learningTheme)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
                
                // What You Will Practice
                if let practiceAreas = book.whatYouWillPractice, !practiceAreas.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("What You Will Practice")
                            .font(DesignSystem.Typography.h3)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            ForEach(practiceAreas, id: \.self) { practice in
                                HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                                    Text("•")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    Text(practice)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
                
                // Estimated Length
                if let estimatedLength = book.estimatedLength {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Estimated Length")
                            .font(DesignSystem.Typography.h3)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Text(estimatedLength)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
                
                // Action Button
                if isOnDevice {
                    NavigationLink(destination: BookDetailView(book: book)) {
                        Text("Start Reading")
                            .font(DesignSystem.Typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.buttonPadding)
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.CornerRadius.button)
                            .shadow(DesignSystem.Shadow.small)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                } else {
                    Button(action: {
                        // Download functionality to be implemented later
                    }) {
                        Text("Download")
                            .font(DesignSystem.Typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.buttonPadding)
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.CornerRadius.button)
                            .shadow(DesignSystem.Shadow.small)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLevelInfo) {
            LevelInfoView()
        }
        .onAppear {
            checkIfOnDevice()
            loadAvailableLanguages()
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

// MARK: - Level Info View

struct LevelInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("EchoBooks Level Guide")
                        .font(DesignSystem.Typography.h1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding(.bottom, DesignSystem.Spacing.sm)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        LevelRow(level: 1, descriptor: "Beginner", cefr: "A1 (low)")
                        LevelRow(level: 2, descriptor: "High Beginner", cefr: "A1 (high)")
                        LevelRow(level: 3, descriptor: "Pre-Intermediate", cefr: "A2 (low)")
                        LevelRow(level: 4, descriptor: "Intermediate", cefr: "A2–B1")
                        LevelRow(level: 5, descriptor: "Mid-Intermediate", cefr: "B1 (low)")
                        LevelRow(level: 6, descriptor: "Upper Intermediate", cefr: "B2")
                        LevelRow(level: 7, descriptor: "Advanced", cefr: "B2–C1")
                        LevelRow(level: 8, descriptor: "High Advanced", cefr: "C1")
                        LevelRow(level: 9, descriptor: "Near-Native", cefr: "C2")
                    }
                }
                .padding(DesignSystem.Spacing.screenPadding)
            }
            .navigationTitle("Level Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LevelRow: View {
    let level: Int
    let descriptor: String
    let cefr: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Text("\(level)")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(descriptor)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text("Approx. CEFR: \(cefr)")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

struct BookInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookInfoView(
                book: Book(
                    bookTitle: "Sample Book",
                    author: "Sample Author",
                    languages: [.en],
                    bookDescription: "This is a sample book description.",
                    coverImageName: "DefaultCover",
                    bookCode: "SAMPLE",
                    bookLevel: 6,
                    learningTheme: "Everyday Social Interaction",
                    whatYouWillPractice: ["Small Talk", "Polite Requests", "Daily Routines"],
                    estimatedLength: "Short novel · ~1.5–2 hours audio"
                )
            )
        }
    }
}

