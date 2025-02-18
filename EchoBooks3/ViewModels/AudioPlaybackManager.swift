//
//  AudioPlaybackManager.swift
//  EchoBooks3
//
//  A manager that handles audio playback using AVAudioPlayer.
//  It is designed as an ObservableObject so that your UI can observe changes in playback state.

import Foundation
import AVFoundation
import SwiftUI

class AudioPlaybackManager: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    
    var onPlaybackFinished: (() -> Void)?
    
    /// The desired playback rate. This value is stored so that when a new audio file is loaded,
    /// the player can be reconfigured to use this rate.
    var currentRate: Float = 1.0

    /// Loads an audio file from the bundle using the given filename (including extension).
    /// - Parameter fileName: The name of the audio file (e.g. "0000001_GRIMM_S1_C1_P1_S1_en-US.aac").
    func loadAudio(fileName: String) {
        let resourceName = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension
        
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            // Reapply the currentRate to the newly loaded player.
            setRate(currentRate)
        } catch {
            return
        }
    }
    
    /// Convenience method to load audio for a given sentence.
    /// - Parameter sentence: The SentenceContent instance that contains the audioFile property.
    func loadAudio(for sentence: SentenceContent) {
        loadAudio(fileName: sentence.audioFile)
    }
    
    /// Starts audio playback.
    func play() {
        guard let player = audioPlayer else { return }
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
    /// - Parameter rate: The desired playback rate (e.g. 1.0 for normal speed).
    func setRate(_ rate: Float) {
        currentRate = rate
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

