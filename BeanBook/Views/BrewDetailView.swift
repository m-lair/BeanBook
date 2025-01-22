//
//  BrewDetailView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//
import Foundation
import SwiftUI

struct BrewDetailView: View {
    let brew: CoffeeBrew
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(brew.title)
                    .font(.title)
                
                if let imageURL = brew.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 200)
                    .clipped()
                }
                
                Text("Method: \(brew.method)")
                Text("Coffee Amount: \(brew.coffeeAmount)")
                Text("Water Amount: \(brew.waterAmount)")
                Text("Brew Time: \(brew.brewTime)")
                Text("Grind Size: \(brew.grindSize)")
                
                if let notes = brew.notes {
                    Divider()
                    Text("Notes: \(notes)")
                }
            }
            .padding()
        }
        .navigationTitle(brew.title)
    }
}
