//
//  OnboardingView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/23/25.
//

import SwiftUI

struct OnboardingView: View {
    /// Called when the user wants to move on to profile setup.
    let onFinish: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.brown.opacity(0.15), .black],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Welcome to BeanBook!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.brown)
                
                Text("Here you can explore, share, and discover the best coffee brewing methods. Keep track of your favorite brews and learn from others!")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button {
                    onFinish()  // Trigger the profile setup
                } label: {
                    Text("Set Up My Profile")
                        .padding(.horizontal, 32)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brown)
            }
            .padding()
        }
    }
}
