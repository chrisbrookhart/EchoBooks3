//
//  PlaybackOptionRowView.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/11/25.
//


import SwiftUI

struct PlaybackOptionRowView: View {
    @Binding var selectedLanguage: String
    @Binding var selectedSpeed: Double
    let availableLanguages: [String]
    let speedOptions: [Double]
    
    var body: some View {
        HStack {
            Picker("", selection: $selectedLanguage) {
                ForEach(availableLanguages, id: \.self) { lang in
                    Text(lang).tag(lang)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Picker("", selection: $selectedSpeed) {
                ForEach(speedOptions, id: \.self) { speed in
                    Text(String(format: "%.2f", speed)).tag(speed)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
