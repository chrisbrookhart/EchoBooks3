//
//  AudioPlaybackManager.swift
//  EchoBooks3
//
//  Created by Chris Brookhart on 2/8/25.
//


import Foundation
import AVFoundation
import SwiftUI
import Combine

/// An audio playback manager for handling basic audiobook playback.
/// This manager uses AVAudioPlayer to load and play a local audio file.
/// It exposes published properties for playback state and time so that SwiftUI views can update accordingly.
final class AudioPlaybackManager: ObservableObject {
    
    // Published properties to drive the UI.
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0.0
    @Published var duration: TimeInterval = 0.0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    /// Loads an audio file from a local URL.
    /// - Parameter url: The URL of the audio file to load.
    func loadAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0.0
            currentTime = 0.0
            print("Audio loaded, duration: \(duration)")
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    /// Starts audio playback.
    func play() {
        guard let player = audioPlayer else {
            print("No audio loaded.")
            return
        }
        player.play()
        isPlaying = true
        startTimer()
        print("Playback started.")
    }
    
    /// Pauses audio playback.
    func pause() {
        guard let player = audioPlayer else { return }
        player.pause()
        isPlaying = false
        stopTimer()
        print("Playback paused.")
    }
    
    /// Skips forward by the specified number of seconds.
    /// - Parameter seconds: The number of seconds to skip forward.
    func skipForward(by seconds: TimeInterval = 15) {
        guard let player = audioPlayer else { return }
        let newTime = min(player.currentTime + seconds, player.duration)
        player.currentTime = newTime
        currentTime = newTime
        print("Skipped forward to \(newTime) seconds.")
    }
    
    /// Skips backward by the specified number of seconds.
    /// - Parameter seconds: The number of seconds to skip backward.
    func skipBackward(by seconds: TimeInterval = 15) {
        guard let player = audioPlayer else { return }
        let newTime = max(player.currentTime - seconds, 0)
        player.currentTime = newTime
        currentTime = newTime
        print("Skipped backward to \(newTime) seconds.")
    }
    
    /// Starts a timer to update the current playback time.
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
            if !player.isPlaying {
                self.isPlaying = false
                self.stopTimer()
            }
        }
    }
    
    /// Stops the timer that updates playback time.
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
