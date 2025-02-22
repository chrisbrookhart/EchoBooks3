//
//  PlaybackMode.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/21/25.
//


import Foundation

enum PlaybackMode: String, CaseIterable, Identifiable {
    case sentence = "Sentence"
    case paragraph = "Paragraph"
    
    var id: Self { self }
}
