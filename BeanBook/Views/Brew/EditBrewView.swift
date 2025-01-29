//
//  EditBrewView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/25/25.
//


import SwiftUI

struct EditBrewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(CoffeeBrewManager.self) private var brewManager
    
    let brew: CoffeeBrew
    
    @State private var title: String
    @State private var selectedMethod: BrewMethod
    @State private var coffeeAmount: Double
    @State private var waterAmount: Int
    @State private var brewTimeSeconds: Int
    @State private var selectedGrindSize: GrindSize
    @State private var notes: String
    
    init(brew: CoffeeBrew) {
        self.brew = brew
        
        // 1) Break down each piece of parsing
        let rawMethod       = brew.method.lowercased()
        let coffeeValString = brew.coffeeAmount.replacingOccurrences(of: "g", with: "")
        let waterValString  = brew.waterAmount.replacingOccurrences(of: "g", with: "")
        let brewTimeString  = brew.brewTime.replacingOccurrences(of: "s", with: "")
        let rawGrind        = brew.grindSize.lowercased()
        let brewNotes       = brew.notes ?? ""
        
        // 2) Convert those raw strings to your desired types
        let methodEnum  = BrewMethod(rawValue: rawMethod) ?? .espresso
        let coffeeVal   = Double(coffeeValString) ?? 18
        let waterVal    = Int(waterValString)  ?? 30
        let brewTimeVal = Int(brewTimeString)     ?? 30
        let grindEnum   = GrindSize(rawValue: rawGrind) ?? .fine
        
        // 3) Assign to your @State properties
        _title             = State(initialValue: brew.title)
        _selectedMethod    = State(initialValue: methodEnum)
        _coffeeAmount      = State(initialValue: coffeeVal)
        _waterAmount       = State(initialValue: waterVal)
        _brewTimeSeconds   = State(initialValue: brewTimeVal)
        _selectedGrindSize = State(initialValue: grindEnum)
        _notes             = State(initialValue: brewNotes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Brew Title", text: $title)
                    Picker("Method", selection: $selectedMethod) {
                        ForEach(BrewMethod.allCases, id: \.self) { method in
                            Text(method.rawValue.capitalized).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Amounts") {
                    Stepper(value: $coffeeAmount, in: 5.0...50.0, step: 0.1) {
                        HStack {
                            Text("Coffee")
                            Spacer()
                            Text("\(String(format: "%.1f", coffeeAmount)) g")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brew Time (seconds)")
                            .font(.headline)
                        
                        // If you see the compiler complaining about this as well,
                        // you can store the sequence in a small Array first.
                        Picker("Brew Time", selection: $brewTimeSeconds) {
                            ForEach(Array(stride(from: 10, through: 240, by: 5)), id: \.self) { sec in
                                Text("\(sec) s").tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
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
            .navigationTitle("Edit Brew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            // Convert numeric values back to strings
                            let brewTimeStr = "\(brewTimeSeconds)s"
                            let coffeeStr   = String(format: "%.1f", coffeeAmount) + "g"
                            let waterStr    = "\(Int(waterAmount))g"
                            
                            // Create an updated copy of the brew
                            var updatedBrew = brew
                            updatedBrew.title        = title
                            updatedBrew.method       = selectedMethod.rawValue.capitalized
                            updatedBrew.coffeeAmount = coffeeStr
                            updatedBrew.waterAmount  = waterStr
                            updatedBrew.brewTime     = brewTimeStr
                            updatedBrew.grindSize    = selectedGrindSize.rawValue.capitalized
                            updatedBrew.notes        = notes
                            
                            await brewManager.updateBrew(updatedBrew)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
