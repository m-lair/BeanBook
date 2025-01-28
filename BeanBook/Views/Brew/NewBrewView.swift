
import FirebaseStorage
import SwiftUI

struct NewBrewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AuthManager.self) var authManager
    @Environment(CoffeeBrewManager.self) var brewManager
    @Environment(UserManager.self) var userManager
    @Environment(CoffeeBagManager.self) var bagManager

    // Basic text fields
    @State private var title = ""
    
    // Brew method, amounts, etc.
    @State private var selectedMethod: BrewMethod = .espresso
    @State private var coffeeAmount = 18.0
    @State private var waterAmount = 30.0
    @State private var brewTimeSeconds = 30
    @State private var selectedGrindSize: GrindSize = .fine
    @State private var notes = ""
    
    // Toggle for including a new bag
    @State private var bagToggle: Bool = false
    
    // Bag fields (only used if bagToggle is on)
    @State private var brandName: String = ""
    @State private var bagOrigin: String = ""
    @State private var selectedRoast: RoastLevel = .medium
    @State private var location: String = ""
    
    // Image vars
    @State private var coffeeImage: UIImage?
    @State private var showCamera = false

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
                
                // Coffee Bag Info
                Toggle("Add Coffee Bag Info", isOn: $bagToggle)
                    
                    // If toggle is on, show the BagDetailsForm
                if bagToggle {
                    BagDetailsForm(
                        brandName: $brandName,
                        origin: $bagOrigin,
                        location: $location,
                        selectedRoast: $selectedRoast
                    )
                }
                
                // Brew amounts
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
                
                // Brew time & grind
                Section("Brew Time & Grind") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brew Time (seconds)")
                            .font(.headline)
                        
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
                
                Section("Coffee Photo") {
                    Button{ showCamera = true } label: {
                        if let coffeeImage {
                            Image(uiImage: coffeeImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } else {
                            Label("Take Coffee Photo", systemImage: "camera")
                        }
                    }
                }
                
                // Notes
                Section("Notes") {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .formStyle(.grouped)
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $coffeeImage)
            }
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
                            
                            // 1) Convert numeric values to strings
                            let brewTimeStr = "\(brewTimeSeconds)s"
                            let coffeeStr   = String(format: "%.1f", coffeeAmount) + "g"
                            let waterStr    = "\(Int(waterAmount))g"
                            
                            // 2) If bagToggle is on, create a bag first
                            var bagId: String? = nil
                            if bagToggle {
                                let newBag = CoffeeBag(
                                    brandName: brandName,
                                    roastLevel: selectedRoast.rawValue.capitalized,
                                    userName: userManager.currentUserProfile?.displayName ?? "Anonymous",
                                    userId: user.uid,
                                    location: location,
                                    origin: bagOrigin
                                )
                                
                                // The addBag(...) function can return the new doc ID
                                bagId = try? await bagManager.addBag(newBag)
                            }
                            
                            // 3) Build the brew object. If bagId is not nil, attach it
                            var brew = CoffeeBrew(
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
                            
                            brew.bagId = bagId
                            if let coffeeImage {
                                brew.imageURL = try await uploadCoffeeImage(coffeeImage, userId: user.uid)
                            }
                            
                            // 4) Save brew
                            await brewManager.addBrew(brew)
                            
                            // 5) Dismiss
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // Enhanced upload function with error handling
    private func uploadCoffeeImage(_ image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw UploadError.invalidImageData
        }
        
        let storageRef = Storage.storage().reference()
        let imageName = "\(UUID().uuidString).jpg"
        let userFolderRef = storageRef.child("users/\(userId)/brews/\(imageName)")
        
        do {
            _ = try await userFolderRef.putDataAsync(imageData)
            return try await userFolderRef.downloadURL().absoluteString
        } catch {
            throw UploadError.firebaseError(error)
        }
    }

    enum UploadError: Error, LocalizedError {
        case invalidImageData
        case firebaseError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidImageData: "Failed to process image"
            case .firebaseError(let error): "Upload failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - BrewMethod & GrindSize
enum BrewMethod: String, CaseIterable {
    case espresso, pourOver, frenchPress, coldBrew
}

enum GrindSize: String, CaseIterable {
    case fine, medium, coarse
}


/// A sub-form to capture coffee bag info, with no separate toolbar or navigation.
struct BagDetailsForm: View {
    @Binding var brandName: String
    @Binding var origin: String
    @Binding var location: String
    @Binding var selectedRoast: RoastLevel
    
    var body: some View {
        // We'll replicate the two sections from your NewBagView style:
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
        
        Section("Origin") {
            TextField("Origin (e.g. 'Ethiopia')", text: $origin)
        }
    }
}

// You can keep the same roast enum in here or in a shared file
enum RoastLevel: String, CaseIterable {
    case light, medium, dark
}
