//
//  Validatable.swift
//  YourAppName
//
//  Created by [Your Name] on [Date].
//
//  This protocol defines an interface for validating model objects.
//  Models conforming to Validatable must implement the validate(with:) method.
//
 
import Foundation

protocol Validatable {
    /// Validates the model against the provided language codes.
    /// - Parameter languages: An array of LanguageCode values.
    /// - Throws: A ValidationError if validation fails.
    func validate(with languages: [LanguageCode]) throws
}
