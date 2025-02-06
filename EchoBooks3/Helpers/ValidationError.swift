//
//  ValidationError.swift
//  YourAppName
//
//  Created by [Your Name] on [Date].
//
//  This file defines errors used during model validation.
//
 
import Foundation

enum ValidationError: Error, LocalizedError {
    case missingSubBooks
    case missingChapters(subBookID: UUID)
    case missingParagraph(chapterID: UUID)
    case missingSentence(paragraphID: UUID)
    case missingText(language: LanguageCode)
    case missingAudioFile(language: LanguageCode)
    
    var errorDescription: String? {
        switch self {
        case .missingSubBooks:
            return "No subbooks are associated with this book."
        case .missingChapters(let subBookID):
            return "No chapters found for subbook with ID \(subBookID)."
        case .missingParagraph(let chapterID):
            return "No paragraphs found for chapter with ID \(chapterID)."
        case .missingSentence(let paragraphID):
            return "No sentences found for paragraph with ID \(paragraphID)."
        case .missingText(let language):
            return "Missing text for language \(language.rawValue)."
        case .missingAudioFile(let language):
            return "Missing audio file for language \(language.rawValue)."
        }
    }
}
