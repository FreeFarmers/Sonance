//
//  BVAudioAnalyzer.swift
//  Sonance
//
//  Created by Ahsan Minhas on 27/03/2025.
//

import AVFoundation
import Accelerate

class AudioAnalyzer: ObservableObject {
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!

    @Published var frequency: Double = 0.0

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode

        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 8192, format: format) { (buffer, time) in
            self.processAudioBuffer(buffer: buffer)
        }
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    deinit {
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
    }
    
    
    private func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        guard let floatChannelData = buffer.floatChannelData else { return }
        let channelData = floatChannelData.pointee
        
        let bufferLength = Int(buffer.frameLength)
        let log2n = vDSP_Length(round(log2(Double(bufferLength))))
        let bufferSizePOT = Int(pow(2, Double(log2n)))

        var realParts = [Float](repeating: 0.0, count: bufferSizePOT)
        var imaginaryParts = [Float](repeating: 0.0, count: bufferSizePOT)

        // Copy input data safely
        let copyCount = min(bufferLength, bufferSizePOT)
        realParts.replaceSubrange(0..<copyCount, with: UnsafeBufferPointer(start: channelData, count: copyCount))

        // Apply Hann window
        let window = vDSP.window(ofType: Float.self, usingSequence: .hanningDenormalized, count: bufferSizePOT, isHalfWindow: false)
        vDSP.multiply(window, realParts, result: &realParts)

        realParts.withUnsafeMutableBufferPointer { realBuffer in
            imaginaryParts.withUnsafeMutableBufferPointer { imagBuffer in
                var splitComplex = DSPSplitComplex(realp: realBuffer.baseAddress!, imagp: imagBuffer.baseAddress!)

                // Setup FFT
                guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return }
                
                // Perform FFT
                vDSP_fft_zip(fftSetup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))

                // Compute magnitudes
                var magnitudes = [Float](repeating: 0.0, count: bufferSizePOT / 2)
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(bufferSizePOT / 2))

                // Normalize using square root
                var normalizedMagnitudes = [Float](repeating: 0.0, count: bufferSizePOT / 2)
                vvsqrtf(&normalizedMagnitudes, magnitudes, [Int32(bufferSizePOT / 2)])

                // Find peak frequency
                if let maxIndex = normalizedMagnitudes[5...].firstIndex(of: normalizedMagnitudes.max() ?? 0.0) {
                    let sampleRate = buffer.format.sampleRate
                    let binWidth = sampleRate / Double(bufferSizePOT)

                    // Use interpolation for better accuracy
                    let interpolatedIndex = quadraticPeakInterpolation(magnitudes: normalizedMagnitudes, maxIndex: maxIndex)
                    let detectedFrequency = Double(interpolatedIndex) * binWidth

                    DispatchQueue.main.async {
                        self.frequency = detectedFrequency
                    }
                }

                vDSP_destroy_fftsetup(fftSetup) // Cleanup
            }
        }
    }

    
    

    func quadraticPeakInterpolation(magnitudes: [Float], maxIndex: Int) -> Float {
        let left = maxIndex > 0 ? magnitudes[maxIndex - 1] : 0
        let center = magnitudes[maxIndex]
        let right = maxIndex < magnitudes.count - 1 ? magnitudes[maxIndex + 1] : 0

        let correction = (right - left) / (2 * (2 * center - left - right))
        return Float(maxIndex) + correction
    }

}
