//
//  TunerView.swift
//  Sonance
//
//  Created by Ahsan Minhas on 27/03/2025.
//

import SwiftUI

struct TunerView: View {
    @ObservedObject var audioAnalyzer = AudioAnalyzer()

    var detectedNote: (note: String, offset: Double) {
        return frequencyToNote(frequency: audioAnalyzer.frequency)
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    ZStack {
                        // Gauge Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geometry.size.width * 0.8, height: 50)

                        // Tick Marks
                        HStack(spacing: 0) {
                            ForEach(-5...5, id: \.self) { i in
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 1, height: i % 5 == 0 ? 15 : 8)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(width: geometry.size.width * 0.8, height: 50)

                        // Needle
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 3, height: 40)
                            .offset(x: CGFloat(detectedNote.offset) * geometry.size.width * 0.8 / 200, y: -5)
                            .animation(.easeInOut, value: detectedNote.offset)
                    }

                    Text("Note: \(detectedNote.note)")
                        .font(.title)
                        .padding(.top, 10)

                    Text("\(detectedNote.offset, specifier: "%.1f") cents")
                        .font(.headline)
                        .padding(.top, 5)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    func frequencyToNote(frequency: Double) -> (String, Double) {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        guard frequency > 0 else { return ("", 0) }

        let midiNote = 69 + 12 * log2(frequency / 440.0)
        let roundedNote = Int(round(midiNote))
        let noteIndex = roundedNote % 12
        let noteName = noteNames[noteIndex]

        let offset = (midiNote - Double(roundedNote)) * 100.0

        return (noteName, offset)
    }
}

