//
//  TunerView.swift
//  Sonance
//
//  Created by Ahsan Minhas on 27/03/2025.
//

import SwiftUI


struct TunerView: View {
    @ObservedObject var audioAnalyzer: AudioAnalyzer // Use your existing AudioAnalyzer
    
    var detectedNote: (note: String, offset: Double) {
        return frequencyToNote(frequency: audioAnalyzer.frequency)
    }
    var tuningColor: Color {
        if abs(detectedNote.offset) > 15 {
            return .snRED
        } else if abs(detectedNote.offset) > 5 {
            return .snOrange
        } else {
            return Color.accentColor
        }
    }

    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack {
                    ZStack {
                        // Curved Gauge Background
                        ArcShape(angle: 180)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.38) // Adjust height

                        // Tick Marks (Curved)
                        ForEach(-5...5, id: \.self) { i in
                            let angle = Double(i) * 180.0 / 10.0 // Calculate angle for each tick
                            let tickHeight = i % 5 == 0 ? 15.0 : 8.0 // Longer ticks at 0, ±5
                            let radius = geometry.size.width * 0.38// Adjust radius to fit inside arc

                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: tickHeight)
                                .offset(y: -radius) // Move inward into the arc
                                .rotationEffect(.degrees(angle), anchor: .center)
                        }

                        // Needle
                        TunerNeedle(detectedOffset: detectedNote.offset)
                            .frame(width: geometry.size.width, height: 150)

                    }
                    .padding(.top,100)

                    
                    Text("\(detectedNote.note)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)

                    Text("\(detectedNote.offset, specifier: "%.1f") cents")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.top, 5)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(tuningColor) // Apply dynamic background color
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

// MARK: - Arc Shape
struct ArcShape: Shape {
    var angle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        let startAngle = Angle(degrees: 180) // Start from the left
        let endAngle = Angle(degrees: 180 + angle)   //add the angle to the starting angle.
        
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        return path
    }
}




struct TunerNeedle: View {
    var detectedOffset: Double // -50 to +50 cents

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Circular Base
                Circle()
                    .fill(Color.black)
                    .frame(width: 12, height: 12)
                    .offset(y: 75) // Adjust based on needle size
                
                // Needle
                Path { path in
                    let width: CGFloat = 4
                    let height: CGFloat = 150
                    path.move(to: CGPoint(x: 0, y: height)) // Bottom
                    path.addLine(to: CGPoint(x: width / 2, y: 0)) // Top point
                    path.addLine(to: CGPoint(x: -width / 2, y: 0)) // Top point other side
                    path.closeSubpath()
                }
                .fill(Color.red)
                .rotationEffect(.degrees(detectedOffset * 90.0 / 50.0), anchor: .bottom)
                .animation(.easeInOut, value: detectedOffset)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
