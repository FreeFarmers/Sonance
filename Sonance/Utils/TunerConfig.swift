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
    
    /// Default input sensitivity (0 = least sensitive, 1 = most sensitive)
    static let defaultInputSensitivity: Double = 0.84
    
    /// RMS signal floor at maximum sensitivity
    static let minAmplitudeFloor: Float = 0.00075
    
    /// RMS signal floor at minimum sensitivity
    static let minAmplitudeCeiling: Float = 0.0195
    
    /// Input gain at minimum sensitivity
    static let inputGainMin: Float = 1.36
    
    /// Input gain at maximum sensitivity
    static let inputGainMax: Float = 11.2
    
    /// Consecutive buffers above threshold before pitch detection activates
    static let signalHoldBuffers: Int = 1
    
    /// Minimum interval between UI updates from the audio thread
    static let uiUpdateInterval: TimeInterval = 1.0 / 30.0
    
    /// Maps sensitivity to the RMS level required for detection
    static func minAmplitude(for sensitivity: Double) -> Float {
        let clamped = Float(min(max(sensitivity, 0), 1))
        let strictness = pow(1 - clamped, 0.5)
        return minAmplitudeFloor + strictness * (minAmplitudeCeiling - minAmplitudeFloor)
    }
    
    /// Maps sensitivity to pre-FFT input gain
    static func inputGain(for sensitivity: Double) -> Float {
        let clamped = Float(min(max(sensitivity, 0), 1))
        return inputGainMin + clamped * (inputGainMax - inputGainMin)
    }
    
    /// Peak must stand this many times above the spectral median
    static func peakProminenceThreshold(for sensitivity: Double) -> Float {
        let clamped = Float(min(max(sensitivity, 0), 1))
        let strictness = pow(1 - clamped, 0.32)
        return 0.375 + strictness * 1.65
    }
    
    /// Fixed meter headroom above the threshold marker
    static func inputMeterMax(for threshold: Float) -> Float {
        max(threshold + 0.06, 0.1)
    }
    
    /// Low frequency cutoff in Hz (below this is likely noise)
    static let lowFrequencyCutoff: Double = 50.0
    
    /// High frequency cutoff in Hz (~C8, highest practical note)
    static let highFrequencyCutoff: Double = 4200.0
    
    /// Search window for autocorrelation refinement (±% of estimated period)
    static let autocorrelationSearchRatio: Double = 0.05
    
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

