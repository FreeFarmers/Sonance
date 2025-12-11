//
//  TunerConfig.swift
//  Sonance
//
//  Created by Ahsan Minhas on 11/12/2025.
//

import AVFoundation

/// Configuration constants for the tuner
enum TunerConfig {
    // MARK: - Audio Processing
    
    /// Buffer size for audio capture (power of 2 for FFT efficiency)
    static let bufferSize: AVAudioFrameCount = 8192
    
    /// Minimum amplitude threshold to filter out noise
    static let minAmplitude: Float = 0.01
    
    /// Low frequency cutoff in Hz (below this is likely noise)
    static let lowFrequencyCutoff: Double = 50.0
    
    /// High frequency cutoff in Hz (~C8, highest practical note)
    static let highFrequencyCutoff: Double = 4200.0
    
    /// Reference frequency for A4 in Hz (standard tuning)
    static let referenceFrequency: Double = 440.0
    
    /// Reference MIDI note number for A4
    static let referenceMidiNote: Int = 69
    
    // MARK: - Tuning Thresholds (in cents)
    
    /// Threshold for "in tune" (within this many cents)
    static let inTuneThreshold: Double = 5.0
    
    /// Threshold for "close" (within this many cents)
    static let closeThreshold: Double = 15.0
    
    /// Maximum cents offset (for gauge scaling)
    static let maxCentsOffset: Double = 50.0
    
    // MARK: - Note Names
    
    /// Standard Western chromatic scale note names
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
}

