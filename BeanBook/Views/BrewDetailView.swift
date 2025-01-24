//
//  BrewDetailView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//
import SwiftUI

struct BrewDetailView: View {
    let brew: CoffeeBrew
    
    // For toggling favorites
    @Environment(UserManager.self) private var userManager
    
    @State private var favorited: Bool = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.brown.opacity(0.25), .black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Hero Image (if brew.imageURL exists)
                    if let imageURL = brew.imageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .clipped()
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(
                                            colors: [.black.opacity(0.0), .black.opacity(0.4)]
                                        ),
                                        startPoint: .center,
                                        endPoint: .bottom
                                    )
                                )
                        } placeholder: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.brown.opacity(0.2))
                                    .frame(height: 250)
                                ProgressView()
                            }
                        }
                    } else {
                        // If there's no image, use a placeholder
                        Image(systemName: "cup.and.saucer.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .padding()
                            .foregroundColor(.brown.opacity(0.7))
                    }
                    
                    // Title & (optional) creator info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(brew.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let creatorName = brew.creatorName {
                            Text("Created by \(creatorName)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Card with brew details
                    VStack(alignment: .leading, spacing: 12) {
                        // Basic info
                        Group {
                            infoRow(label: "Method", value: brew.method)
                            infoRow(label: "Coffee Amount", value: brew.coffeeAmount)
                            infoRow(label: "Water Amount", value: brew.waterAmount)
                            infoRow(label: "Brew Time", value: brew.brewTime)
                            infoRow(label: "Grind Size", value: brew.grindSize)
                        }
                        
                        // Notes
                        if let notes = brew.notes, !notes.isEmpty {
                            Divider()
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            // Add the favorite button in the top bar
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await userManager.toggleFavorite(brew: brew)
                            favorited.toggle()
                        }
                    } label: {
                        Image(systemName: favorited ? "star.fill" : "star")
                    }
                }
            }
        }
        .navigationTitle(brew.title)
        .navigationBarTitleDisplayMode(.inline)
        // Load initial favorite state
        .onAppear {
            favorited = userManager.isFavorite(brew: brew)
        }
    }
    
    // MARK: - Helper: Info Row
    /// A small, reusable row for key-value style info display
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(label):")
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }
}
