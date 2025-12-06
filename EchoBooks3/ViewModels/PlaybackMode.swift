//
//  PlaybackMode.swift
//  EchoBooks3
// 
//


import Foundation

enum PlaybackMode: String, CaseIterable, Identifiable {
    case sentence = "Sentence"
    case paragraph = "Paragraph"
    
    var id: Self { self }
}
