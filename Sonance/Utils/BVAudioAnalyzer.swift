//
//  BVAudioAnalyzer.swift
//  Sonance
//
//  Created by Ahsan Minhas on 27/03/2025.
//

import AVFoundation
import Accelerate

/// Detected note information including note name, octave, and cent offset
struct DetectedNote: Equatable {
    let note: String
    let octave: Int
    let offset: Double
    let frequency: Double
    
    static let empty = DetectedNote(note: "", octave: 0, offset: 0, frequency: 0)
    
    var displayName: String {
        note.isEmpty ? "" : "\(note)\(octave)"
    }
    
    var isDetected: Bool {
        !note.isEmpty && frequency > 0
    }
}

/// Audio analyzer that detects pitch from microphone input using FFT
class AudioAnalyzer: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var fftSetup: FFTSetup?
    private var log2n: vDSP_Length = 0
    private var bufferSizePOT: Int = 0
    
    @Published var frequency: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var amplitude: Float = 0.0
    
    var detectedNote: DetectedNote {
        return frequencyToNote(frequency: frequency)
    }
    
    init() {
        checkMicrophonePermission()
    }
    
    // MARK: - Permission Handling
    
    /// Check and request microphone permission
    private func checkMicrophonePermission() {
        #if os(macOS)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            DispatchQueue.main.async {
                self.permissionGranted = true
            }
            setupAudioEngine()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupAudioEngine()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.permissionGranted = false
            }
        @unknown default:
            break
        }
        #else
        // iOS
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if granted {
                    self?.setupAudioEngine()
                }
            }
        }
        #endif
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }
        
        let format = inputNode.outputFormat(forBus: 0)
        
        // Pre-calculate FFT parameters
        log2n = vDSP_Length(round(log2(Double(TunerConfig.bufferSize))))
        bufferSizePOT = Int(pow(2, Double(log2n)))
        
        // Create FFT setup once and reuse
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        
        inputNode.installTap(onBus: 0, bufferSize: TunerConfig.bufferSize, format: format) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer: buffer)
        }
    }
    
    // MARK: - Public Control Methods
    
    /// Start the audio analysis
    func start() {
        guard permissionGranted, let audioEngine = audioEngine, !isRunning else { return }
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRunning = true
            }
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    /// Stop the audio analysis
    func stop() {
        audioEngine?.stop()
        DispatchQueue.main.async {
            self.isRunning = false
            self.frequency = 0.0
            self.amplitude = 0.0
        }
    }
    
    deinit {
        stop()
        inputNode?.removeTap(onBus: 0)
        if let fftSetup = fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
        }
    }
    
    // MARK: - Note Detection
    
    /// Convert frequency to musical note with octave and cent offset
    private func frequencyToNote(frequency: Double) -> DetectedNote {
        guard frequency > 0 else { return .empty }
        
        // Calculate MIDI note number from frequency
        // Formula: midiNote = 69 + 12 * log2(frequency / 440)
        let midiNote = Double(TunerConfig.referenceMidiNote) + 12.0 * log2(frequency / TunerConfig.referenceFrequency)
        let roundedNote = Int(round(midiNote))
        
        // Handle negative MIDI notes (very low frequencies)
        let noteIndex = ((roundedNote % 12) + 12) % 12
        let noteName = TunerConfig.noteNames[noteIndex]
        
        // Calculate octave (MIDI note 0 = C-1, so octave = note/12 - 1)
        let octave = (roundedNote / 12) - 1
        
        // Calculate offset in cents (100 cents = 1 semitone)
        let offset = (midiNote - Double(roundedNote)) * 100.0
        
        return DetectedNote(note: noteName, octave: octave, offset: offset, frequency: frequency)
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        guard let floatChannelData = buffer.floatChannelData,
              let fftSetup = fftSetup else { return }
        
        let channelData = floatChannelData.pointee
        let bufferLength = Int(buffer.frameLength)
        
        var realParts = [Float](repeating: 0.0, count: bufferSizePOT)
        var imaginaryParts = [Float](repeating: 0.0, count: bufferSizePOT)
        
        let copyCount = min(bufferLength, bufferSizePOT)
        realParts.replaceSubrange(0..<copyCount, with: UnsafeBufferPointer(start: channelData, count: copyCount))
        
        // Apply Hanning window to reduce spectral leakage
        let window = vDSP.window(ofType: Float.self, usingSequence: .hanningDenormalized, count: bufferSizePOT, isHalfWindow: false)
        vDSP.multiply(window, realParts, result: &realParts)
        
        realParts.withUnsafeMutableBufferPointer { realBuffer in
            imaginaryParts.withUnsafeMutableBufferPointer { imagBuffer in
                var splitComplex = DSPSplitComplex(realp: realBuffer.baseAddress!, imagp: imagBuffer.baseAddress!)
                
                // Perform FFT
                vDSP_fft_zip(fftSetup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
                
                // Calculate magnitudes
                var magnitudes = [Float](repeating: 0.0, count: bufferSizePOT / 2)
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(bufferSizePOT / 2))
                
                // Normalize magnitudes
                var normalizedMagnitudes = [Float](repeating: 0.0, count: bufferSizePOT / 2)
                vvsqrtf(&normalizedMagnitudes, magnitudes, [Int32(bufferSizePOT / 2)])
                
                let maxMagnitude = normalizedMagnitudes.max() ?? 0.0
                
                // Update amplitude for UI feedback
                DispatchQueue.main.async {
                    self.amplitude = maxMagnitude
                }
                
                // Apply minimum amplitude threshold to ignore noise
                if maxMagnitude < TunerConfig.minAmplitude {
                    DispatchQueue.main.async {
                        self.frequency = 0.0
                    }
                    return
                }
                
                // Find peak frequency (skip first 5 bins to avoid DC offset)
                if let maxIndex = normalizedMagnitudes[5...].firstIndex(of: maxMagnitude) {
                    let sampleRate = buffer.format.sampleRate
                    let binWidth = sampleRate / Double(bufferSizePOT)
                    
                    // Use quadratic interpolation for sub-bin accuracy
                    let interpolatedIndex = quadraticPeakInterpolation(magnitudes: normalizedMagnitudes, maxIndex: maxIndex)
                    let detectedFrequency = Double(interpolatedIndex) * binWidth
                    
                    // Filter out frequencies outside musical range
                    if detectedFrequency >= TunerConfig.lowFrequencyCutoff &&
                       detectedFrequency <= TunerConfig.highFrequencyCutoff {
                        DispatchQueue.main.async {
                            self.frequency = detectedFrequency
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.frequency = 0.0
                        }
                    }
                }
            }
        }
    }
    
    /// Quadratic peak interpolation for more accurate frequency detection
    /// Uses parabolic interpolation around the peak bin
    private func quadraticPeakInterpolation(magnitudes: [Float], maxIndex: Int) -> Float {
        let left = maxIndex > 0 ? magnitudes[maxIndex - 1] : 0
        let center = magnitudes[maxIndex]
        let right = maxIndex < magnitudes.count - 1 ? magnitudes[maxIndex + 1] : 0
        
        let denominator = 2 * (2 * center - left - right)
        guard denominator != 0 else { return Float(maxIndex) }
        
        let correction = (right - left) / denominator
        return Float(maxIndex) + correction
    }
}
