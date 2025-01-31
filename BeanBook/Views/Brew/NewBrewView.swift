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
    @State private var yield = 38.0
    @State private var selectedGrindSize: GrindSize = .fine
    @State private var notes = ""
    
    // Coffee bag toggle and fields
    @State private var bagToggle: Bool = false
    @State private var brandName: String = ""
    @State private var bagOrigin: String = ""
    @State private var selectedRoast: RoastLevel = .medium
    @State private var location: String = ""
    
    // Image handling
    @State private var bagImage: UIImage?
    @State private var coffeeImage: UIImage?
    @State private var imageType: String?
    @State private var showCamera = false
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
                        origin: $bagOrigin,
                        location: $location,
                        selectedRoast: $selectedRoast
                    )
                    
                    PhotoSection(
                        title: "Bag Photo",
                        image: $bagImage,
                        buttonLabel: "Coffee Bag",
                        isUploading: $isUploading
                    ) {
                        checkCameraAvailability()
                        imageType = "bag"
                    }
                }
                
                // 3) Brew Parameters
                BrewParametersSection(
                    selectedMethod: $selectedMethod,
                    coffeeAmount: $coffeeAmount,
                    waterAmount: $waterAmount,
                    brewTimeSeconds: $brewTimeSeconds,
                    yield: $yield,
                    selectedGrindSize: $selectedGrindSize
                )
                
                // 4) Coffee Photo (Brew photo)
                PhotoSection(
                    title: "Coffee Photo",
                    image: $coffeeImage,
                    buttonLabel: "Take Coffee Photo",
                    isUploading: $isUploading
                ) {
                    checkCameraAvailability()
                    imageType = "brew"
                }
                
                // 5) Notes
                Section("Notes") {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .formStyle(.grouped)
            .onChange(of: selectedMethod) { updateParameters(for: selectedMethod) }
            .fullScreenCover(isPresented: $showCamera) {
                // Present your custom camera
                // Provide the correct binding to store the captured photo
                if imageType == "bag" {
                    CameraView(image: $bagImage)
                        .ignoresSafeArea()
                } else {
                    CameraView(image: $coffeeImage)
                        .ignoresSafeArea()
                }
            }
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
    }
    
    // MARK: - Helper Methods
    
    private func handleSave() async {
        isUploading = true
        defer { isUploading = false }
        
        do {
            guard let user = userManager.currentUserProfile, let uid = userManager.currentUID else { return }
            
            // 1) Convert numeric values
            let brewTimeStr = "\(brewTimeSeconds)s"
            let coffeeStr   = String(format: "%.1f", coffeeAmount) + "g"
            let waterStr    = "\(Int(waterAmount))g"
            
            // 2) If bagToggle is on, create a bag first
            var bagId: String? = nil
            if bagToggle {
                var newBag = CoffeeBag(
                    brandName: brandName,
                    roastLevel: selectedRoast.rawValue.capitalized,
                    userName: user.displayName ?? "",
                    userId: uid,
                    location: location,
                    origin: bagOrigin
                )
                
                // Upload coffee bag image to "bag" folder
                if let bagImage {
                    newBag.imageURL = try await uploadImage(bagImage, userId: uid, folder: "bag")
                }
                
                bagId = try? await bagManager.addBag(newBag)
            }
            
            // 3) Build the brew object
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
            brew.bagId = bagId
            
            // Upload brew image to "brew" folder
            if let coffeeImage {
                brew.imageURL = try await uploadImage(coffeeImage, userId: uid, folder: "brew")
            }
            
            // 4) Save brew
            await brewManager.addBrew(brew)
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    /// Check camera availability & permissions
    private func checkCameraAvailability() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            requestCameraAccess()
        case .denied, .restricted:
            cameraPermissionStatus = status
            showCameraSettingsAlert = true
        @unknown default:
            showCameraUnavailableAlert = true
        }
    }
    
    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                if granted {
                    showCamera = true
                } else {
                    cameraPermissionStatus = .denied
                    showCameraSettingsAlert = true
                }
            }
        }
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
            yield = 38.0
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
        .overlay {
            if isUploading {
                ProgressView()
                    .tint(.white)
                    .background(Circle().fill(.brown.opacity(0.8)))
            }
        }
        .disabled(isUploading)
    }
}

/// Brew parameters (coffee amount, water amount, brew time, grind size)
private struct BrewParametersSection: View {
    @Binding var selectedMethod: BrewMethod
    @Binding var coffeeAmount: Double
    @Binding var waterAmount: Double
    @Binding var brewTimeSeconds: Int
    @Binding var yield: Double
    @Binding var selectedGrindSize: GrindSize
    
    // Computed
    private var shouldShowWater: Bool {
        !(selectedMethod == .espresso)
    }
    
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
        case .pourOver: return 100...500
        case .frenchPress: return 200...1000
        case .coldBrew: return 500...2000
        default: return 0...0
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
            if shouldShowWater {
                Stepper(value: $waterAmount, in: waterAmountRange, step: waterStep) {
                    HStack {
                        Text(selectedMethod == .espresso ? "Yield" : "Water")
                        Spacer()
                        Text("\(Int(waterAmount)) g")
                            .foregroundStyle(.secondary)
                    }
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
    @Binding var brandName: String
    @Binding var origin: String
    @Binding var location: String
    @Binding var selectedRoast: RoastLevel
    
    var body: some View {
        Section("Basic Info") {
            TextField("Brand Name (e.g. 'Intelligentsia')", text: $brandName)
            TextField("Location (e.g. 'Chicago')", text: $location)
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
