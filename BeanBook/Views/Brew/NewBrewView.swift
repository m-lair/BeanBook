import SwiftUI
import AVFoundation
import FirebaseStorage

struct NewBrewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AuthManager.self) var authManager
    @Environment(CoffeeBrewManager.self) var brewManager
    @Environment(UserManager.self) var userManager
    @Environment(CoffeeBagManager.self) var bagManager
    
    // MARK: - View State
    @State private var showCameraSettingsAlert = false
    @State private var showCameraUnavailableAlert = false
    @State private var showAlert: Bool = false
    @State private var errorMessage: String? = nil
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    // Basic fields
    @State private var title = ""
    
    // Brew parameters
    @State private var selectedMethod: BrewMethod = .espresso {
        didSet { updateParameters(for: selectedMethod) }
    }
    @State private var coffeeAmount = 18.0
    @State private var waterAmount = 30.0
    @State private var brewTimeSeconds = 30
    @State private var selectedGrindSize: GrindSize = .fine
    @State private var notes = ""
    
    // Coffee bag toggle and fields
    @State private var bagToggle: Bool = false
    @State private var brandName: String = ""
    @State private var bagOrigin: String = ""
    @State private var selectedRoast: RoastLevel = .medium
    @State private var location: String = ""
    @State private var bagId: String?
    // Image handling
    @State private var bagImage: UIImage?
    @State private var coffeeImage: UIImage?
    @State private var showBagCamera = false
    @State private var showBrewCamera = false
    @State private var isUploading = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // 1) Basic Info
                BasicInfoSection(title: $title, selectedMethod: $selectedMethod)
                
                // 2) Coffee Bag Toggle & Details
                Toggle("Add Coffee Bag", isOn: $bagToggle)
                if bagToggle {
                    BagDetailsForm(
                        brandName: $brandName,
                        bagId: $bagId,
                        origin: $bagOrigin,
                        location: $location,
                        bagImage: $bagImage,
                        selectedRoast: $selectedRoast
                    )
                    .task {
                        await bagManager.fetchCoffeeBags()
                    }
                    
                    PhotoSection(title: "Bag Photo",
                                 image: $bagImage,
                                 buttonLabel: "Coffee Bag Photo",
                                 isUploading: $isUploading
                    ) {
                        checkCameraAvailability(for: .bag)
                    }
                }
                // 3) Brew Parameters
                BrewParametersSection(
                    selectedMethod: $selectedMethod,
                    coffeeAmount: $coffeeAmount,
                    waterAmount: $waterAmount,
                    brewTimeSeconds: $brewTimeSeconds,
                    selectedGrindSize: $selectedGrindSize
                )
                
                // Brew Photo Section
                PhotoSection(title: "Coffee Photo",
                             image: $coffeeImage,
                             buttonLabel: "Coffee Photo",
                             isUploading: $isUploading
                ) {
                    checkCameraAvailability(for: .brew)
                }
                
                // 5) Notes
                Section("Notes") {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .formStyle(.grouped)
            .onChange(of: selectedMethod) { updateParameters(for: selectedMethod) }
            .alert(errorMessage ?? "", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            }
            .navigationTitle("Add Brew")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await handleSave()
                        }
                    }
                    .disabled(isUploading)
                }
            }
        }
        .fullScreenCover(isPresented: $showBagCamera) {
            CameraView(isPresented: $showBagCamera, image: $bagImage)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showBrewCamera) {
            CameraView(isPresented: $showBrewCamera, image: $coffeeImage)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleSave() async {
        isUploading = true
        defer {
            isUploading = false
            print("Finished handleSave")
        }

        do {
            guard let user = userManager.currentUserProfile,
                  let uid = userManager.currentUID
            else {
                print("User not found – aborting save process")
                return
            }
            print("Starting save process for user: \(uid)")

            // 1) Convert numeric values
            let brewTimeStr = "\(brewTimeSeconds)s"
            let coffeeStr   = String(format: "%.1f", coffeeAmount) + "g"
            let waterStr    = "\(Int(waterAmount))g"
            print("Converted: brewTime = \(brewTimeStr), coffee = \(coffeeStr), water = \(waterStr)")

            // 2) Handle Bag creation or update
            // If bagToggle is ON, use existing bagId if available, else create a new bag.
            var resolvedBagId: String? = bagId  // bagId might already be set from picking an existing bag
            if bagToggle {
                if let existingId = resolvedBagId, !existingId.isEmpty {
                    // Update existing bag
                    print("Bag toggle ON and we have an existing bagId (\(existingId)) – updating bag")
                    var existingBag = try await bagManager.fetchById(existingId)
                    existingBag.brandName = brandName
                    existingBag.origin    = bagOrigin
                    existingBag.roastLevel = selectedRoast.rawValue.capitalized
                    existingBag.location  = location

                    // If we have a new image, re-upload and update
                    if let bagImage {
                        print("Uploading updated bag image...")
                        existingBag.imageURL = try await uploadImage(bagImage, userId: uid, folder: "bag")
                        print("Bag image updated: \(existingBag.imageURL ?? "none")")
                    }
                    // Save the updated bag
                    bagManager.updateBag(existingBag)

                } else {
                    // Create new bag
                    print("Bag toggle ON but no existing bagId – creating a new bag")
                    var newBag = CoffeeBag(
                        brandName: brandName,
                        roastLevel: selectedRoast.rawValue.capitalized,
                        userName: user.displayName ?? "",
                        userId: uid,
                        location: location,
                        origin: bagOrigin
                    )
                    
                    if let bagImage {
                        print("Uploading bag image...")
                        newBag.imageURL = try await uploadImage(bagImage, userId: uid, folder: "bag")
                        print("New bag image URL: \(newBag.imageURL ?? "none")")
                    }
                    
                    resolvedBagId = try await bagManager.addBag(newBag)
                    print("New bag created with id: \(resolvedBagId ?? "nil")")
                }
            } else {
                print("Bag toggle OFF – no bag creation or update")
            }

            // 3) Build the brew object
            print("Building CoffeeBrew object")
            var brew = CoffeeBrew(
                title: title,
                method: selectedMethod.rawValue.capitalized,
                coffeeAmount: coffeeStr,
                waterAmount: waterStr,
                brewTime: brewTimeStr,
                grindSize: selectedGrindSize.rawValue.capitalized,
                creatorName: user.displayName ?? "",
                creatorId: uid,
                notes: notes
            )
            // Attach the resolved bag id (could be nil if toggle was off)
            brew.bagId = resolvedBagId

            // If we have a brew image, upload it
            if let coffeeImage {
                print("Uploading brew image...")
                brew.imageURL = try await uploadImage(coffeeImage, userId: uid, folder: "brew")
                print("Brew image URL: \(brew.imageURL ?? "none")")
            } else {
                print("No brew image provided")
            }

            // 4) Save brew
            print("Saving CoffeeBrew")
            await brewManager.addBrew(brew)
            print("CoffeeBrew saved successfully")
            dismiss()

        } catch {
            print("Error occurred: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showAlert = true
        }
    }

    
    // Updated camera handling
    private func checkCameraAvailability(for imageType: ImageType) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            switch imageType {
            case .bag: showBagCamera = true
            case .brew: showBrewCamera = true
            }
        case .notDetermined:
            requestCameraAccess(for: imageType)
        case .denied, .restricted:
            // Handle denied state
            cameraPermissionStatus = status
            showCameraSettingsAlert = true
        @unknown default:
            showCameraUnavailableAlert = true
        }
    }
        
    private func requestCameraAccess(for imageType: ImageType) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                if granted {
                    switch imageType {
                    case .bag: showBagCamera = true
                    case .brew: showBrewCamera = true
                    }
                } else {
                    cameraPermissionStatus = .denied
                    showCameraSettingsAlert = true
                }
            }
        }
    }

    // Add this enum for type safety
    enum ImageType {
        case bag, brew
    }
    
    /// Upload image to Firestore Storage
    private func uploadImage(_ image: UIImage, userId: String, folder: String) async throws -> String {
        // Resize and compress
        guard let resized = resizedImage(image, maxDimension: 1200),
              let imageData = resized.jpegData(compressionQuality: 0.75) else {
            throw UploadError.invalidImageData
        }
        
        let storageRef = Storage.storage().reference()
        let imageName = "\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString).jpg"
        let pathRef = storageRef.child("users/\(userId)/\(folder)/\(imageName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            _ = try await pathRef.putDataAsync(imageData, metadata: metadata)
            return try await pathRef.downloadURL().absoluteString
        } catch {
            throw UploadError.firebaseError(error)
        }
    }
    
    /// Simple image resizing helper
    private func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let aspectRatio = image.size.width / image.size.height
        var newSize = CGSize(width: maxDimension, height: maxDimension)
        
        if aspectRatio > 1 { // Landscape
            newSize.height = maxDimension / aspectRatio
        } else {            // Portrait
            newSize.width = maxDimension * aspectRatio
        }
        
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Sync UI with brew method defaults
    private func updateParameters(for method: BrewMethod) {
        switch method {
        case .espresso:
            coffeeAmount = 18.0
            waterAmount = 36.0
            brewTimeSeconds = 30
            selectedGrindSize = .fine
        case .pourOver:
            coffeeAmount = 20.0
            waterAmount = 300.0
            brewTimeSeconds = 180
            selectedGrindSize = .medium
        case .frenchPress:
            coffeeAmount = 30.0
            waterAmount = 500.0
            brewTimeSeconds = 240
            selectedGrindSize = .coarse
        case .coldBrew:
            coffeeAmount = 100.0
            waterAmount = 1000.0
            brewTimeSeconds = 12 * 3600 // 12 hours
            selectedGrindSize = .coarse
        }
    }
}

// MARK: - Subviews

/// Basic info section: Title & Method
private struct BasicInfoSection: View {
    @Binding var title: String
    @Binding var selectedMethod: BrewMethod
    
    var body: some View {
        Section("Basic Info") {
            TextField("Brew Title", text: $title)
                .submitLabel(.done)
            
            Picker("Method", selection: $selectedMethod) {
                ForEach(BrewMethod.allCases, id: \.self) { method in
                    Text(method.rawValue.capitalized).tag(method)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

/// Generic photo-taking section
private struct PhotoSection: View {
    let title: String
    @Binding var image: UIImage?
    let buttonLabel: String
    @Binding var isUploading: Bool
    let onTakePhoto: () -> Void
    
    var body: some View {
        Section(title) {
            Button {
                onTakePhoto()
            } label: {
                HStack {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    } else {
                        Label(buttonLabel, systemImage: "camera")
                    }
                }
            }
        }
    }
}

/// Brew parameters (coffee amount, water amount, brew time, grind size)
private struct BrewParametersSection: View {
    @Binding var selectedMethod: BrewMethod
    @Binding var coffeeAmount: Double
    @Binding var waterAmount: Double
    @Binding var brewTimeSeconds: Int
    @Binding var selectedGrindSize: GrindSize
    
    private var coffeeAmountRange: ClosedRange<Double> {
        switch selectedMethod {
        case .espresso: return 15...25
        case .pourOver: return 10...40
        case .frenchPress: return 20...50
        case .coldBrew: return 50...200
        }
    }
    
    private var coffeeStep: Double {
        selectedMethod == .espresso ? 0.5 : 1.0
    }
    
    private var waterAmountRange: ClosedRange<Double> {
        switch selectedMethod {
        case .espresso: return 10...100
        case .pourOver: return 100...500
        case .frenchPress: return 200...1000
        case .coldBrew: return 500...2000
        }
    }
    
    private var waterStep: Double {
        switch selectedMethod {
        case .pourOver: return 10
        case .frenchPress: return 50
        case .coldBrew: return 100
        default: return 1
        }
    }
    
    private var brewTimeOptions: [Int] {
        if selectedMethod == .coldBrew {
            // 5min to 24hr in 5min steps
            return Array(stride(from: 5*60, through: 24*60*60, by: 5*60))
        }
        // 20..300 for non-espresso, 1s steps for espresso
        return Array(stride(
            from: 20,
            through: 300,
            by: selectedMethod == .espresso ? 1 : 5
        ))
    }
    
    private var brewTimeLabel: String {
        selectedMethod == .coldBrew ? "Brew Time (hours:minutes)" : "Brew Time (seconds)"
    }
    
    var body: some View {
        Section("Parameters") {
            // Coffee Amount
            Stepper(value: $coffeeAmount, in: coffeeAmountRange, step: coffeeStep) {
                HStack {
                    Text("Coffee")
                    Spacer()
                    Text("\(String(format: "%.1f", coffeeAmount)) g")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Water Amount
            Stepper(value: $waterAmount, in: waterAmountRange, step: waterStep) {
                HStack {
                    Text(selectedMethod == .espresso ? "Yield" : "Water")
                    Spacer()
                    Text("\(Int(waterAmount)) g")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Brew Time
            VStack(alignment: .leading) {
                Text(brewTimeLabel)
                    .font(.headline)
                
                Picker("Brew Time", selection: $brewTimeSeconds) {
                    ForEach(brewTimeOptions, id: \.self) { time in
                        Text(timeFormatter(time))
                            .tag(time)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
            }
            
            // Grind Size
            Picker("Grind Size", selection: $selectedGrindSize) {
                ForEach(GrindSize.allCases, id: \.self) { size in
                    Text(size.rawValue.capitalized).tag(size)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private func coffeeAmountString(_ decimals: Int = 1) -> String {
        let needsDecimal = (selectedMethod == .espresso)
        return String(format: "%.\(needsDecimal ? "1" : "0")f g", coffeeAmount)
    }
    
    private func timeFormatter(_ seconds: Int) -> String {
        if selectedMethod == .coldBrew {
            let hours   = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return String(format: "%dh %02dm", hours, minutes)
        }
        return "\(seconds) s"
    }
}

/// A sub-form to capture coffee bag info
struct BagDetailsForm: View {
    @Environment(CoffeeBagManager.self) var bagManager
    @Binding var brandName: String
    @Binding var bagId: String?
    @Binding var origin: String
    @Binding var location: String
    @Binding var bagImage: UIImage?
    @Binding var selectedRoast: RoastLevel
    
    var existingBags: [CoffeeBag] { bagManager.bags }
    var body: some View {
        if !existingBags.isEmpty {
            Section {
                Menu {
                    ForEach(bagManager.bags) { bag in
                        Button {
                            // Populate fields when user taps an existing bag
                            brandName = bag.brandName
                            bagId = bag.id ?? ""
                            origin = bag.origin
                            location = bag.location ?? ""
                            
                            // If bag.roastLevel is stored as a capitalized string,
                            // parse it back into the enum (light, medium, dark).
                            if let roast = RoastLevel(rawValue: bag.roastLevel.lowercased()) {
                                selectedRoast = roast
                            }
                            
                            Task {
                                guard
                                    let urlString = bag.imageURL,
                                    let url = URL(string: urlString)
                                else {
                                    return
                                }
                                
                                do {
                                    let (data, _) = try await URLSession.shared.data(from: url)
                                    if let image = UIImage(data: data) {
                                        bagImage = image
                                    }
                                } catch {
                                    print("Failed to load bag image: \(error)")
                                }
                            }
                            print("Selected: \(bagId)")
                            // If bag.roastLevel is stored as a capitalized string,
                            // parse it back into the enum (light, medium, dark)
                            if let roast = RoastLevel(rawValue: bag.roastLevel.lowercased()) {
                                selectedRoast = roast
                            }
                        } label: {
                            HStack {
                                VStack {
                                    Text(bag.brandName)
                                    Text(bag.roastLevel)
                                }
                                Spacer()
                                if let url = bag.imageURL {
                                    AsyncImage(url: URL(string: url)) { image in
                                        image
                                            .resizable()
                                            .frame(width: 44, height: 44)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Circle()
                                            .frame(width: 44, height: 44)
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Label("Use Existing Bag", systemImage: "magnifyingglass.circle")
                }
            }
        } else {
            Section {
                Text("No Bags Found. Add a Bag one to select it from here next time!")
            }
        }
        Section("Basic Info") {
            TextField("Brand Name (e.g. 'Intelligentsia')", text: $brandName)
                .textContentType(.countryName)
            TextField("Location (e.g. 'Chicago')", text: $location)
                .textContentType(.countryName)
            Picker("Roast Level", selection: $selectedRoast) {
                ForEach(RoastLevel.allCases, id: \.self) { roast in
                    Text(roast.rawValue.capitalized).tag(roast)
                }
            }
            .pickerStyle(.segmented)
        }
        
        Section("Origin") {
            TextField("Origin (e.g. 'Ethiopia')", text: $origin)
                .textContentType(.countryName)
        }
    }
}

// MARK: - Enums & Errors

enum BrewMethod: String, CaseIterable {
    case espresso, pourOver, frenchPress, coldBrew
}

enum GrindSize: String, CaseIterable {
    case fine, medium, coarse
}

enum RoastLevel: String, CaseIterable {
    case light, medium, dark
}

enum UploadError: Error, LocalizedError {
    case invalidImageData
    case imageProcessingFailed
    case firebaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Failed to process image data"
        case .imageProcessingFailed:
            return "Could not resize image"
        case .firebaseError(let err):
            return "Upload failed: \(err.localizedDescription)"
        }
    }
}
