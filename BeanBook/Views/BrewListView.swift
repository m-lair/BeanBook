//
//  BrewListView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//

import Foundation
import SwiftUI

struct BrewListView: View {
    @State private var showNewBrew = false
    @Environment(CoffeeBrewManager.self) var brewManager
    
    var body: some View {
        NavigationStack {
            List(brewManager.coffeeBrews) { brew in
                NavigationLink {
                    BrewDetailView(brew: brew)
                } label: {
                    Text(brew.title)
                }
            }
            .navigationTitle("Coffee Methods")
            .toolbar {
                Button("Add Brew") {
                    showNewBrew = true
                }
            }
            .sheet(isPresented: $showNewBrew) {
                NewBrewView()
            }
            .task {
                await brewManager.fetchBrews()
            }
        }
    }
}
