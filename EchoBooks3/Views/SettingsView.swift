import SwiftUI

struct SettingsView: View {
    // Persist the playback mode; default is Sentence.
    @AppStorage("playbackMode") private var playbackMode: String = PlaybackMode.sentence.rawValue

    // Persist language selections using raw values.
    @AppStorage("selectedLanguage1") private var selectedLanguage1Raw: String = "en-US"
    @AppStorage("selectedLanguage2") private var selectedLanguage2Raw: String = "None"
    @AppStorage("selectedLanguage3") private var selectedLanguage3Raw: String = "None"
    
    // Create computed bindings for the language selections.
    private var selectedLanguage1: Binding<String> {
        Binding(
            get: {
                let valid = LanguageCode.allCases.map { $0.rawValue }
                return valid.contains(selectedLanguage1Raw) ? selectedLanguage1Raw : "en-US"
            },
            set: { newValue in
                selectedLanguage1Raw = newValue
            }
        )
    }
    
    private var selectedLanguage2: Binding<String> {
        Binding(
            get: { selectedLanguage2Raw },
            set: { newValue in selectedLanguage2Raw = newValue }
        )
    }
    
    private var selectedLanguage3: Binding<String> {
        Binding(
            get: { selectedLanguage3Raw },
            set: { newValue in selectedLanguage3Raw = newValue }
        )
    }
    
    // Persist playback speeds.
    @AppStorage("selectedSpeed1") private var selectedSpeed1: Double = 1.0
    @AppStorage("selectedSpeed2") private var selectedSpeed2: Double = 1.0
    @AppStorage("selectedSpeed3") private var selectedSpeed3: Double = 1.0
    
    @Environment(\.dismiss) var dismiss
    
    // Speed options available.
    private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Playback Mode")) {
                    Picker("", selection: $playbackMode) {
                        ForEach(PlaybackMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Language Selection")) {
                    Picker("Primary", selection: selectedLanguage1) {
                        ForEach(LanguageCode.allCases, id: \.rawValue) { lang in
                            Text(lang.name).tag(lang.rawValue)
                        }
                    }
                    
                    Picker("Secondary", selection: selectedLanguage2) {
                        Text("None").tag("None")
                        ForEach(LanguageCode.allCases, id: \.rawValue) { lang in
                            Text(lang.name).tag(lang.rawValue)
                        }
                    }
                    
                    Picker("Tertiary", selection: selectedLanguage3) {
                        Text("None").tag("None")
                        ForEach(LanguageCode.allCases, id: \.rawValue) { lang in
                            Text(lang.name).tag(lang.rawValue)
                        }
                    }
                }
                
                Section(header: Text("Playback Speed")) {
                    Picker("Primary Speed", selection: $selectedSpeed1) {
                        ForEach(speedOptions, id: \.self) { speed in
                            Text(String(format: "%.2f", speed)).tag(speed)
                        }
                    }
                    
                    Picker("Secondary Speed", selection: $selectedSpeed2) {
                        ForEach(speedOptions, id: \.self) { speed in
                            Text(String(format: "%.2f", speed)).tag(speed)
                        }
                    }
                    
                    Picker("Tertiary Speed", selection: $selectedSpeed3) {
                        ForEach(speedOptions, id: \.self) { speed in
                            Text(String(format: "%.2f", speed)).tag(speed)
                        }
                    }
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
