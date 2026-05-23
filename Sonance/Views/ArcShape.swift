//
//  ArcShape.swift
//  Sonance
//
//  Created by Ahsan Minhas on 28/03/2025.
//
import SwiftUI

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
