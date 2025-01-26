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
    // For updating saveCount
    @Environment(CoffeeBrewManager.self) private var brewManager
    
    @State private var favorited: Bool = false
    @State private var localSaveCount: Int = 0  // Track # times saved
    
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
                        
                        // Show how many times it's saved
                        Text("Saved \(localSaveCount) times")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Card with brew details
                    VStack(alignment: .leading, spacing: 12) {
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
                    
                    if brew.creatorId == userManager.currentUID {
                        NavigationLink(destination: EditBrewView(brew: brew)) {
                            Text("Edit Brew")
                                .background(Color.brown.opacity(0.3))
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let wasFavorited = favorited
                        
                        Task {
                            // 1) Toggle in userManager
                            await userManager.toggleFavorite(brew: brew)
                            // Flip local 'favorited'
                            favorited.toggle()
                            
                            // 2) Update saveCount in Firestore
                            let incrementVal = wasFavorited ? -1 : +1
                            await brewManager.updateSaveCount(for: brew, incrementValue: incrementVal)
                            
                            // 3) Update local count for immediate UI feedback
                            localSaveCount += incrementVal
                        }
                    } label: {
                        Image(systemName: favorited ? "star.fill" : "star")
                    }
                }
            }
        }
        .navigationTitle(brew.title)
        .navigationBarTitleDisplayMode(.inline)
        // Load initial favorite state and saveCount on appear
        .onAppear {
            favorited = userManager.isFavorite(brew: brew)
            localSaveCount = brew.saveCount
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
