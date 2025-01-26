//
//  NewBrewView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/22/25.
//
import SwiftUI

struct NewBrewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AuthManager.self) var authManager
    @Environment(CoffeeBrewManager.self) var brewManager
    
    // Basic text fields
    @State private var title = ""
    
    // Let’s do an enum for the method with a segmented picker
    @State private var selectedMethod: BrewMethod = .espresso
    
    // For coffee & water amounts, we’ll store numeric doubles so we can use steppers
    @State private var coffeeAmount = 18.0
    @State private var waterAmount = 30.0
    
    // For brew time in seconds, we’ll do a wheel-style Picker from 10...240, stepping by 5
    @State private var brewTimeSeconds = 30
    
    // Another enum for grind size, also shown in a segmented picker
    @State private var selectedGrindSize: GrindSize = .fine
    
    // Multiline text for additional notes
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Brew Title (e.g. 'Morning Espresso')", text: $title)
                    
                    Picker("Method", selection: $selectedMethod) {
                        ForEach(BrewMethod.allCases, id: \.self) { method in
                            Text(method.rawValue.capitalized).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Amounts") {
                    // Coffee
                    Stepper(value: $coffeeAmount, in: 5.0...50.0, step: 0.1) {
                        HStack {
                            Text("Coffee")
                            Spacer()
                            Text("\(String(format: "%.1f", coffeeAmount)) g")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Water
                    Stepper(value: $waterAmount, in: 10...500, step: 1) {
                        HStack {
                            Text("Water")
                            Spacer()
                            Text("\(Int(waterAmount)) g")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Brew Time & Grind") {
                    // We'll use a wheel-style picker for brew time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brew Time (seconds)")
                            .font(.headline)
                        
                        Picker("Brew Time", selection: $brewTimeSeconds) {
                            // Generate a list of times in 5-second increments
                            ForEach(stride(from: 10, through: 240, by: 5).map({ Int($0) }), id: \.self) { sec in
                                Text("\(sec) s").tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120) // Enough room for the wheel
                    }
                    
                    Picker("Grind Size", selection: $selectedGrindSize) {
                        ForEach(GrindSize.allCases, id: \.self) { size in
                            Text(size.rawValue.capitalized).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Notes") {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .formStyle(.grouped)  // iOS 17+ modern grouping style (should look nice in iOS 18)
            .navigationTitle("Add Brew")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            guard let user = authManager.user else { return }
                            
                            // Convert numeric values to strings
                            let brewTimeStr = "\(brewTimeSeconds)s"
                            let coffeeStr   = "\(Double(coffeeAmount))g"
                            let waterStr    = "\(Int(waterAmount))g"
                            
                            let brew = CoffeeBrew(
                                title: title,
                                method: selectedMethod.rawValue.capitalized,
                                coffeeAmount: coffeeStr,
                                waterAmount: waterStr,
                                brewTime: brewTimeStr,
                                grindSize: selectedGrindSize.rawValue.capitalized,
                                creatorName: user.displayName ?? "",
                                creatorId: user.uid,
                                notes: notes
                            )
                            
                            await brewManager.addBrew(brew)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Enums

enum BrewMethod: String, CaseIterable {
    case espresso, pourOver, frenchPress, coldBrew
}

enum GrindSize: String, CaseIterable {
    case fine, medium, coarse
}
