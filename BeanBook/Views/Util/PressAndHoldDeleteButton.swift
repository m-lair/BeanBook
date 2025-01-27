//
//  PressAndHoldDeleteButton.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/26/25.
//

import SwiftUI

/// A generic press-and-hold button that fills from bottom to top.
/// Once fully filled, `onComplete()` is called.
struct PressAndHoldActionButton: View {
    let label: String
    let baseColor: Color      // the lighter background color
    let fillColor: Color      // the color that fills upward
    let holdDuration: TimeInterval
    let onComplete: () -> Void
    
    @State private var progress: CGFloat = 0
    @State private var isPressing: Bool = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Light background
            Rectangle()
                .fill(baseColor)
            
            // Fill overlay
            Rectangle()
                .fill(fillColor)
                .frame(height: 50 * progress) // Fill grows from bottom
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .cornerRadius(8)
        .overlay(
            Text(label)
                .foregroundColor(.white)
                .bold()
        )
        .contentShape(Rectangle())  // So the gesture recognizes full area
        // Use a drag gesture so we can start the moment the finger touches
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        startTimer()
                    }
                }
                .onEnded { _ in
                    reset()
                }
        )
    }
    
    // MARK: - Timer Handling
    private func startTimer() {
        let start = Date()
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { t in
            guard isPressing else {
                t.invalidate()
                return
            }
            let elapsed = Date().timeIntervalSince(start)
            let fraction = min(elapsed / holdDuration, 1.0)
            
            progress = CGFloat(fraction)
            
            // Once we hit 100% progress, call onComplete
            if progress >= 1.0 {
                t.invalidate()
                onComplete()
                reset()
            }
        }
    }
    
    private func reset() {
        isPressing = false
        timer?.invalidate()
        timer = nil
        progress = 0
    }
}
