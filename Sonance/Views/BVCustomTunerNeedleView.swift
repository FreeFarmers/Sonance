//
//  BVCustomTunerNeedle.swift
//  Sonance
//
//  Created by Ahsan Minhas on 27/03/2025.
//

import SwiftUI

/// Custom needle shape with a tapered body and rounded base
/// Used for the tuner indicator that shows pitch offset
struct NeedleShapeWithRoundedBase: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let tipX = rect.midX
            let tipY = rect.minY
            let baseWidth = rect.width * 0.4
            let baseY = rect.maxY
            let baseCenterX = rect.midX
            let baseRadius = baseWidth / 2
            let leftBaseX = baseCenterX - baseRadius
            let rightBaseX = baseCenterX + baseRadius
            
            // Draw tapered needle from tip to base
            path.move(to: CGPoint(x: tipX, y: tipY))
            path.addLine(to: CGPoint(x: rightBaseX, y: baseY - baseRadius))
            
            // Add rounded base
            path.addArc(
                center: CGPoint(x: baseCenterX, y: baseY - baseRadius),
                radius: baseRadius,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
            
            path.addLine(to: CGPoint(x: leftBaseX, y: baseY - baseRadius))
            path.closeSubpath()
        }
    }
}

#Preview {
    VStack {
        NeedleShapeWithRoundedBase()
            .fill(Color.red)
            .frame(width: 20, height: 150)
        
        NeedleShapeWithRoundedBase()
            .stroke(Color.blue, lineWidth: 2)
            .frame(width: 30, height: 200)
    }
    .padding()
}
