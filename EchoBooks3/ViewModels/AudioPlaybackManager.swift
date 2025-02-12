import Foundation
import AVFoundation
import SwiftUI

/// A manager that handles audio playback using AVAudioPlayer.
/// It is designed as an ObservableObject so that your UI can observe changes in playback state.
class AudioPlaybackManager: NSObject, ObservableObject {
    /// Published property so the UI can observe playback state.
    @Published var isPlaying: Bool = false
    
    /// The underlying AVAudioPlayer instance.
    private var audioPlayer: AVAudioPlayer?
    
    /// A closure that is called when playback finishes.
    var onPlaybackFinished: (() -> Void)?
    
    /// Loads an audio file from the bundle using the given filename (including extension).
    ///
    /// - Parameter fileName: The name of the audio file (for example, "0000001_GRIMM_S1_C1_P1_S1_en-US.aac").
    func loadAudio(fileName: String) {
        let resourceName = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension
        
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            print("AudioPlaybackManager: Audio file not found: \(fileName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            print("AudioPlaybackManager: Loaded audio file: \(fileName)")
            if let duration = audioPlayer?.duration, duration > 0 {
                print("AudioPlaybackManager: Audio file duration: \(duration) seconds")
            }
        } catch {
            print("AudioPlaybackManager: Failed to load audio file \(fileName): \(error)")
        }
    }
    
    /// Convenience method to load audio for a given sentence.
    ///
    /// - Parameter sentence: The SentenceContent instance that contains the audioFile property.
    func loadAudio(for sentence: SentenceContent) {
        loadAudio(fileName: sentence.audioFile)
    }
    
    /// Starts audio playback.
    func play() {
        guard let player = audioPlayer else {
            print("AudioPlaybackManager: No audio loaded.")
            return
        }
        player.play()
        isPlaying = true
    }
    
    /// Pauses audio playback.
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    /// Stops audio playback.
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    /// Sets the playback rate.
    ///
    /// - Parameter rate: The desired playback rate (e.g. 1.0 for normal speed).
    func setRate(_ rate: Float) {
        audioPlayer?.enableRate = true
        audioPlayer?.rate = rate
    }
}

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        onPlaybackFinished?()
    }
}
