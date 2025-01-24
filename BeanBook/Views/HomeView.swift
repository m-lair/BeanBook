//
//  HomeView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//
import SwiftUI

struct HomeView: View {
    @Environment(CoffeeBrewManager.self) var brewManager
    @State private var showNewBrew = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.brown.opacity(0.25), .black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content: A List of Brews
                List {
                    ForEach(brewManager.coffeeBrews) { brew in
                        // NavigationLink for detail
                        NavigationLink(destination: BrewDetailView(brew: brew)) {
                            brewRow(brew)
                                .padding(.vertical, 8) // Vertical spacing around each card
                        }
                        // Clear row background so our ZStack & card can show
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)  // Hides default separators
                    }
                }
                // Make the list’s background transparent
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                
                .navigationTitle("Community")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showNewBrew = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showNewBrew) {
                    NewBrewView()
                }
                .task {
                    // Fetch the latest brews when this view appears
                    await brewManager.fetchBrews()
                }
                .refreshable {
                    // Pull-to-refresh
                    await brewManager.fetchBrews()
                }
            }
        }
    }
    
    // MARK: - Brew Row View
    @ViewBuilder
    private func brewRow(_ brew: CoffeeBrew) -> some View {
        ZStack(alignment: .leading) {
            // Card background
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.brown.opacity(0.12))
                .shadow(color: .brown.opacity(0.4), radius: 3, x: 0, y: 3)
            
            HStack(spacing: 12) {
                // Optional icon or image placeholder
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.brown)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(brew.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(brew.method)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Show the brew’s creator
                    Text("Created by \(brew.creatorName ?? "Unknown")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }
}
