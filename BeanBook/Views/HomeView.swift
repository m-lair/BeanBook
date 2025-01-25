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
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.brown.opacity(0.25), .black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content: A List of Brews
                List(brewManager.coffeeBrews) { brew in
                    // NavigationLink for detail
                    Button {
                        path.append(brew)
                    } label: {
                        brewRow(brew)
                            .padding(.vertical, 8) // Vertical spacing around each card
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)  // Hides default separators
                }
                .navigationDestination(for: CoffeeBrew.self) { brew in  BrewDetailView(brew: brew)
                }
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
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.brown)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(brew.title)
                        .font(.headline)
                    
                    Text(brew.method)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Created by \(brew.creatorName ?? "Unknown")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    // New line: show saveCount
                    Text("Saved \(brew.saveCount) times")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }
}
