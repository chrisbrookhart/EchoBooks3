//
//  AudioPlaybackManager.swift
//  EchoBooks3
//
//  Updated to support chunk-based WAV audio playback with time offsets.
//  Uses AudioMappingLoader to get audio segment information and handles
//  seeking within chunks and chunk transitions.
//

import Foundation
import AVFoundation
import SwiftUI

class AudioPlaybackManager: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var audioMappingLoader: AudioMappingLoader?
    
    // Current playback state
    private var currentBookCode: String?
    private var currentChunkId: String?
    private var currentSegment: AudioSegment?
    private var segmentEndTime: TimeInterval = 0
    private var playbackTimer: Timer?
    
    /// Flag to track if we're transitioning between files (for smooth fade)
    private var isTransitioning: Bool = false
    
    var onPlaybackFinished: (() -> Void)?
    
    /// The desired playback rate. This value is stored so that when a new audio file is loaded,
    /// the player can be reconfigured to use this rate.
    var currentRate: Float = 1.0
    
    // MARK: - Audio Loading (New Format)
    
    /// Loads audio for a specific sentence using the new chunk-based format.
    /// - Parameters:
    ///   - sentenceId: The sentence ID (e.g., "s000001")
    ///   - bookCode: The book code (e.g., "CLOCK")
    ///   - languageCode: The language code (e.g., "en-US" or "en")
    func loadAudio(sentenceId: String, bookCode: String, languageCode: String) {
        print("🔊 AudioPlaybackManager: loadAudio called")
        print("   sentenceId: \(sentenceId)")
        print("   bookCode: \(bookCode)")
        print("   languageCode: \(languageCode)")
        
        // Initialize or reuse AudioMappingLoader for this book
        if audioMappingLoader == nil || audioMappingLoader?.bookCode != bookCode {
            audioMappingLoader = AudioMappingLoader(bookCode: bookCode)
        }
        
        guard let loader = audioMappingLoader else { return }
        
        do {
            // Get the audio segment for this sentence
            guard let segment = try loader.audioSegment(for: sentenceId, languageCode: languageCode) else {
                print("ERROR: Could not find audio segment for sentence \(sentenceId) with language \(languageCode)")
                return
            }
            print("✅ AudioPlaybackManager: Found audio segment - offsetMs: \(segment.startMs), durationMs: \(segment.durationMs), wavPath: \(segment.wavPath)")
            
            // Get the chunk ID for this sentence
            guard let chunkId = try loader.chunkId(for: sentenceId, languageCode: languageCode) else {
                print("ERROR: Could not find chunk ID for sentence \(sentenceId) with language \(languageCode)")
                return
            }
            print("✅ AudioPlaybackManager: Found chunk ID: \(chunkId) for language \(languageCode)")
            
            // Get the WAV file path for this chunk
            guard let wavPath = try loader.wavPath(for: chunkId, languageCode: languageCode) else {
                print("ERROR: Could not find WAV path for chunk \(chunkId) with language \(languageCode)")
                return
            }
            print("✅ AudioPlaybackManager: Found WAV path: \(wavPath) for chunk \(chunkId) with language \(languageCode)")
            
            // Calculate segment end time (start + duration in seconds)
            let startTime = TimeInterval(segment.startMs) / 1000.0
            segmentEndTime = startTime + (TimeInterval(segment.durationMs) / 1000.0)
            
            // Check if we need to load a new chunk file
            // We need to reload if:
            // 1. No player exists, OR
            // 2. The chunk ID changed, OR
            // 3. The WAV path changed (different language or different chunk file)
            let needsNewChunk = audioPlayer == nil ||
                                currentChunkId != chunkId ||
                                currentSegment?.wavPath != segment.wavPath
            
            print("   needsNewChunk: \(needsNewChunk)")
            print("   audioPlayer exists: \(audioPlayer != nil)")
            print("   currentChunkId: \(currentChunkId ?? "nil"), newChunkId: \(chunkId)")
            print("   currentWavPath: \(currentSegment?.wavPath ?? "nil"), newWavPath: \(segment.wavPath)")
            
            // Store current state (after checking if we need a new chunk)
            currentBookCode = bookCode
            currentChunkId = chunkId
            currentSegment = segment
            
            if needsNewChunk {
                // Stop the old player gracefully before loading new file
                if let oldPlayer = audioPlayer, oldPlayer.isPlaying {
                    // Fade out and stop the old player smoothly to prevent static/pop
                    isTransitioning = true
                    oldPlayer.setVolume(0.0, fadeDuration: 0.05) // Quick fade out (50ms)
                    
                    // Stop after a brief delay to allow fade
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
                        oldPlayer.stop()
                        self?.isTransitioning = false
                    }
                } else {
                    audioPlayer?.stop()
                }
                
                // Load the chunk WAV file
                // wavPath is relative to book root, e.g., "audio/en/CLOCK__c00001.wav"
                let bookRootPath = "\(bookCode)_book"
                let fullPath = "\(bookRootPath)/\(wavPath)"
                
                print("🔊 AudioPlaybackManager: Loading chunk file")
                print("   wavPath from loader: \(wavPath)")
                print("   bookRootPath: \(bookRootPath)")
                print("   fullPath: \(fullPath)")
                print("   languageCode: \(languageCode)")
                
                // Extract filename and directory
                let pathComponents = fullPath.components(separatedBy: "/")
                let fileName = pathComponents.last ?? ""
                let directory = pathComponents.dropLast().joined(separator: "/")
                
                let resourceName = (fileName as NSString).deletingPathExtension
                let fileExtension = (fileName as NSString).pathExtension
                
                print("   fileName: \(fileName)")
                print("   directory: \(directory)")
                print("   resourceName: \(resourceName)")
                print("   fileExtension: \(fileExtension)")
                
                // Try with Books prefix first (since files are in Books/CLOCK_book/...)
                var url: URL?
                
                // Try 1: Books/CLOCK_book/audio/en
                let subdirectory1 = "Books/\(directory)"
                print("   Trying Bundle.main.url with subdirectory: \(subdirectory1)")
                url = Bundle.main.url(
                    forResource: resourceName,
                    withExtension: fileExtension,
                    subdirectory: subdirectory1
                )
                if let foundURL = url {
                    print("   ✅ Found file at: \(foundURL.path)")
                } else {
                    print("   ❌ Not found with Books prefix")
                }
                
                // Try 2: CLOCK_book/audio/en (without Books prefix)
                if url == nil {
                    print("   Trying Bundle.main.url with subdirectory: \(directory)")
                    url = Bundle.main.url(
                        forResource: resourceName,
                        withExtension: fileExtension,
                        subdirectory: directory.isEmpty ? nil : directory
                    )
                    if let foundURL = url {
                        print("   ✅ Found file at: \(foundURL.path)")
                    } else {
                        print("   ❌ Not found without Books prefix")
                    }
                }
                
                // Try 3: FileManager fallback
                if url == nil, let resourcePath = Bundle.main.resourcePath {
                    let fileManager = FileManager.default
                    let booksPath = (resourcePath as NSString).appendingPathComponent("Books")
                    let searchPath = (booksPath as NSString).appendingPathComponent(fullPath)
                    
                    print("   Trying FileManager at: \(searchPath)")
                    if fileManager.fileExists(atPath: searchPath) {
                        url = URL(fileURLWithPath: searchPath)
                        print("   ✅ Found file via FileManager at: \(searchPath)")
                    } else {
                        print("   ❌ File does not exist at: \(searchPath)")
                        
                        // List what's actually in the audio folder
                        let audioFolderPath = (booksPath as NSString).appendingPathComponent("\(bookRootPath)/audio")
                        if fileManager.fileExists(atPath: audioFolderPath) {
                            print("   📁 Audio folder exists: \(audioFolderPath)")
                            if let audioContents = try? fileManager.contentsOfDirectory(atPath: audioFolderPath) {
                                print("   📁 Audio folder contains: \(audioContents)")
                                
                                // Check the specific language folder
                                let langFolder = normalizeLanguageCode(languageCode)
                                let langFolderPath = (audioFolderPath as NSString).appendingPathComponent(langFolder)
                                if fileManager.fileExists(atPath: langFolderPath) {
                                    print("   📁 Language folder (\(langFolder)) exists: \(langFolderPath)")
                                    if let langContents = try? fileManager.contentsOfDirectory(atPath: langFolderPath) {
                                        print("   📁 Language folder contains: \(langContents)")
                                    }
                                } else {
                                    print("   ❌ Language folder (\(langFolder)) does NOT exist: \(langFolderPath)")
                                }
                            }
                        } else {
                            print("   ❌ Audio folder does NOT exist: \(audioFolderPath)")
                        }
                    }
                }
                
                guard let audioURL = url else {
                    print("ERROR: Could not find audio file at \(fullPath)")
                    print("   Tried: Books/\(fullPath)")
                    print("   Tried: \(fullPath)")
                    if let resourcePath = Bundle.main.resourcePath {
                        let fileManager = FileManager.default
                        let booksPath = (resourcePath as NSString).appendingPathComponent("Books")
                        let searchPath = (booksPath as NSString).appendingPathComponent(fullPath)
                        print("   Tried FileManager: \(searchPath)")
                        print("   File exists: \(fileManager.fileExists(atPath: searchPath))")
                    }
                    return
                }
                
                print("🎵 AudioPlaybackManager: Loading audio from: \(audioURL.path)")
                
                do {
                    // Small delay to ensure old player stops cleanly (if transitioning)
                    if isTransitioning {
                        // Wait briefly for fade-out to complete
                        RunLoop.current.run(until: Date().addingTimeInterval(0.06))
                    }
                    
                    audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                    audioPlayer?.delegate = self
                    audioPlayer?.volume = 1.0 // Ensure volume is reset
                    audioPlayer?.prepareToPlay()
                    
                    print("✅ AudioPlaybackManager: Successfully created AVAudioPlayer")
                } catch {
                    print("ERROR: Failed to create AVAudioPlayer: \(error)")
                    return
                }
            } else {
                print("🔄 AudioPlaybackManager: Reusing existing chunk, no need to reload")
            }
            
            // Ensure player is stopped before seeking to prevent clicks
            audioPlayer?.stop()
            
            // Seek to the start time of this segment
            print("   Seeking to startTime: \(startTime) seconds")
            audioPlayer?.currentTime = startTime
            
            // Reapply the currentRate to the newly loaded player
            setRate(currentRate)
            
            // Start monitoring playback to detect segment end
            startPlaybackMonitoring()
            
        } catch {
            print("ERROR: Failed to load audio: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Normalizes a language code to its simplified form for file path lookup
    /// - Parameter code: Language code (e.g., "en-US" or "en")
    /// - Returns: Simplified code (e.g., "en")
    private func normalizeLanguageCode(_ code: String) -> String {
        // If it's already simplified (no hyphen), return as-is
        if !code.contains("-") {
            return code.lowercased()
        }
        
        // Extract the base language code (part before hyphen)
        let components = code.split(separator: "-")
        return String(components[0]).lowercased()
    }
    
    // MARK: - Playback Control
    
    /// Starts audio playback.
    /// Starts audio playback.
    func play() {
        guard let player = audioPlayer else { return }
        
        // Check if we've reached the end of the current segment
        if player.currentTime >= segmentEndTime {
            // Segment finished, notify completion
            audioPlayerDidFinishPlaying(player, successfully: true)
            return
        }
        
        // Ensure player is stopped before starting (prevents clicks)
        if player.isPlaying {
            player.stop()
        }
        
        // Verify we're at the correct position
        let expectedStartTime = TimeInterval(currentSegment?.startMs ?? 0) / 1000.0
        if abs(player.currentTime - expectedStartTime) > 0.01 {
            // Reposition if we're not at the right spot
            player.currentTime = expectedStartTime
        }
        
        // Always start at volume 0 to prevent clicks, then fade in
        // This helps mask any click/pop from seeking to non-zero-crossing points
        player.volume = 0.0
        player.play()
        
        // Wait a brief moment (20ms) to let playback start and get past any potential click
        // Then fade in smoothly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            guard let self = self, let player = self.audioPlayer else { return }
            // Fade in over 100ms for smooth transition
            player.setVolume(1.0, fadeDuration: 0.1)
        }
        
        isPlaying = true
        startPlaybackMonitoring()
    }
    
    /// Pauses audio playback.
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopPlaybackMonitoring()
    }
    
    /// Stops audio playback.
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        stopPlaybackMonitoring()
        currentSegment = nil
        currentChunkId = nil
    }
    
    /// Sets the playback rate.
    /// - Parameter rate: The desired playback rate (e.g. 1.0 for normal speed).
    func setRate(_ rate: Float) {
        currentRate = rate
        audioPlayer?.enableRate = true
        audioPlayer?.rate = rate
    }
    
    // MARK: - Playback Monitoring
    
    /// Starts monitoring playback to detect when we reach the end of a segment.
    private func startPlaybackMonitoring() {
        stopPlaybackMonitoring()
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkSegmentCompletion()
        }
    }
    
    /// Stops monitoring playback.
    private func stopPlaybackMonitoring() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    /// Checks if we've reached the end of the current segment.
    private func checkSegmentCompletion() {
        guard let player = audioPlayer,
              let segment = currentSegment,
              isPlaying else {
            return
        }
        
        let currentTime = player.currentTime
        let segmentStart = TimeInterval(segment.startMs) / 1000.0
        let segmentEnd = segmentStart + (TimeInterval(segment.durationMs) / 1000.0)
        
        // Check if we've reached or passed the segment end
        if currentTime >= segmentEnd {
            // Stop monitoring and notify completion
            stopPlaybackMonitoring()
            audioPlayerDidFinishPlaying(player, successfully: true)
        }
    }
    
    /// Gets the current playback time within the segment.
    /// - Returns: Current time in seconds, or 0 if not playing
    var currentTime: TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    /// Gets the duration of the current segment.
    /// - Returns: Duration in seconds, or 0 if no segment loaded
    var duration: TimeInterval {
        guard let segment = currentSegment else { return 0 }
        return TimeInterval(segment.durationMs) / 1000.0
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopPlaybackMonitoring()
        onPlaybackFinished?()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("ERROR: Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
        isPlaying = false
        stopPlaybackMonitoring()
    }
}
