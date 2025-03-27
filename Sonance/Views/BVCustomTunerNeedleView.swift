//
//  BVCustomTunerNeedle.swift
//  Sonance
//
//  Created by Ahsan Minhas on 27/03/2025.
//

import SwiftUI


struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        }
    }
}




struct ArcSample:Shape{
    func path(in rect: CGRect) -> Path {
        Path{ path in
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: rect.height/2,
                startAngle: Angle(degrees: -20),
                endAngle: Angle(degrees: +20),
                clockwise: true)

        }
    }
}


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

            path.move(to: CGPoint(x: tipX, y: tipY))
            path.addLine(to: CGPoint(x: rightBaseX, y: baseY - baseRadius))
            path.addArc(center: CGPoint(x: baseCenterX, y: baseY - baseRadius), radius: baseRadius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 180), clockwise: false)
            path.addLine(to: CGPoint(x: leftBaseX, y: baseY - baseRadius))
            path.closeSubpath()
        }
    }
}


struct BVCustomTunerNeedleView: View {
    var body: some View {
        ZStack{
            
            NeedleShapeWithRoundedBase()
                .frame(width: 2, height: 150)
                //.background(Color.green)
        
        }
    }
}

#Preview {
    BVCustomTunerNeedleView()
}
