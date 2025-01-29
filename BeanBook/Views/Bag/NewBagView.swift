//
//  NewBagView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/26/25.
//


import SwiftUI
import Firebase

struct NewBagView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager
    @Environment(CoffeeBagManager.self) private var bagManager
    
    // Basic TextFields
    @State private var brandName = ""
    @State private var origin = ""
    @State private var location = ""
    
    // Segmented picker for roast levels
    @State private var selectedRoast: RoastLevel = .medium
    
    var body: some View {
        // MARK: - Basic Info
        Section("Basic Info") {
            TextField("Brand Name (e.g. 'Intelligentsia')", text: $brandName)
            TextField("Location (e.ge 'Chicago')", text: $location)
            Picker("Roast Level", selection: $selectedRoast) {
                ForEach(RoastLevel.allCases, id: \.self) { roast in
                    Text(roast.rawValue.capitalized).tag(roast)
                }
            }
            .pickerStyle(.segmented)
        }
        
        // MARK: - Origin
        Section("Origin") {
            TextField("Origin (e.g. 'Ethiopia')", text: $origin)
        }
        
        .formStyle(.grouped)  // iOS 17+ modern grouping style
        .navigationTitle("Add Bag")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        guard let _ = authManager.user else {
                            // If you need user context, handle that here
                            return
                        }
                        
                        let newBag = CoffeeBag(
                            brandName: brandName,
                            roastLevel: selectedRoast.rawValue.capitalized,
                            userName: authManager.user!.displayName ?? "Anonymous",
                            userId: userManager.currentUID ?? "Anonymous",
                            location: location,
                            origin: origin
                        )
                        
                        let bagId = try await bagManager.addBag(newBag)
                    }
                    dismiss()
                }
            }
        }
    }
    
    enum RoastLevel: String, CaseIterable {
        case light, medium, dark
    }
}
