//
//  SettingsView.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/21/25.
//
import SwiftUI

struct SettingsView: View {
    // Use @AppStorage to persist the playback mode. Default is "Sentence".
    @AppStorage("playbackMode") private var playbackMode: String = PlaybackMode.sentence.rawValue
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Playback Mode")) {
                    // Use a segmented picker so that the current selection is highlighted.
                    Picker("", selection: $playbackMode) {
                        ForEach(PlaybackMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}



