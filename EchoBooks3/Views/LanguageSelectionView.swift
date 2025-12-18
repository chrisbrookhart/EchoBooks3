//
//  LanguageSelectionView.swift
//  EchoBooks3
//
//  View for selecting which languages to download for a book.
//  Displays checkboxes for each available language.
//

import SwiftUI

struct LanguageSelectionView: View {
    // MARK: - Properties
    
    let availableLanguages: [LanguageCode]
    @Binding var selectedLanguages: [LanguageCode]
    var onDownload: (() -> Void)?
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Select Languages to Download")) {
                    ForEach(availableLanguages, id: \.id) { language in
                        Button(action: {
                            toggleLanguage(language)
                        }) {
                            HStack {
                                Text(language.name)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Spacer()
                                if selectedLanguages.contains(language) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                    }
                }
                
                if !selectedLanguages.isEmpty {
                    Section {
                        Text("\(selectedLanguages.count) language\(selectedLanguages.count == 1 ? "" : "s") selected")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("Select Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Download") {
                        onDownload?()
                        dismiss()
                    }
                    .disabled(selectedLanguages.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleLanguage(_ language: LanguageCode) {
        if let index = selectedLanguages.firstIndex(of: language) {
            selectedLanguages.remove(at: index)
        } else {
            selectedLanguages.append(language)
        }
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView(
            availableLanguages: [.enUS, .esES, .frFR],
            selectedLanguages: .constant([.enUS])
        )
    }
}

