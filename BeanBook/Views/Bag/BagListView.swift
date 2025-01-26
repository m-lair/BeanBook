//
//  BagListView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/25/25.
//
import SwiftUI

struct BagListView: View {
    @Environment(CoffeeBagManager.self) var bagManager

    var body: some View {
        List(bagManager.bags) { bag in
            VStack(alignment: .leading) {
                Text(bag.brandName).font(.headline)
                Text("\(bag.roastLevel) roast from \(bag.origin)")
                    .font(.subheadline)
            }
        }
        .onAppear {
            bagManager.startListening()
        }
        .onDisappear {
            bagManager.stopListening()
        }
    }
}
