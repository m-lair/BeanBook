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
            List(brewManager.coffeeBrews) { brew in
                NavigationLink(destination: BrewDetailView(brew: brew)) {
                    VStack(alignment: .leading) {
                        Text(brew.title)
                            .font(.headline)
                        Text(brew.method)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Recently Added")
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
                // Fetch the latest brews on appear
                await brewManager.fetchBrews()
            }
            .refreshable {
                await brewManager.fetchBrews()
            }
        }
    }
}
