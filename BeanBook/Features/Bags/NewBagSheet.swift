import SwiftUI
import SwiftData
import PhotosUI

struct NewBagSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var editing: Bag? = nil

    @State private var brand = ""
    @State private var name = ""
    @State private var origin = ""
    @State private var roastLevel: RoastLevel = .medium
    @State private var process: ProcessMethod? = nil
    @State private var tastingNotes: [String] = []
    @State private var roastedOn: Date = .now
    @State private var hasRoastedOn = false
    @State private var notes = ""
    @State private var imageData: Data?
    @State private var photoItem: PhotosPickerItem?

    @State private var isDirty = false
    @State private var savedSuccessfully = false

    private var isValid: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.cardSpacing) {
                    photoSection
                    detailsSection
                    notesSection
                }
                .padding(Theme.screenPadding)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New Bag" : "Edit Bag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .interactiveDismissDisabled(isDirty)
            .sensoryFeedback(.success, trigger: savedSuccessfully)
            .task { hydrateFromEditing() }
            .onChange(of: brand) { trackDirty() }
            .onChange(of: name) { trackDirty() }
            .onChange(of: origin) { trackDirty() }
            .onChange(of: roastLevel) { trackDirty() }
            .onChange(of: process) { trackDirty() }
            .onChange(of: tastingNotes) { trackDirty() }
            .onChange(of: roastedOn) { trackDirty() }
            .onChange(of: hasRoastedOn) { trackDirty() }
            .onChange(of: notes) { trackDirty() }
            .onChange(of: imageData) { trackDirty() }
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(item) }
            }
        }
    }

    // MARK: - Sections

    private var photoSection: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .fill(Theme.softGradient)
                    .frame(height: 160)
                if let imageData, let img = UIImage(data: imageData) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.primary)
                        Text("Add photo")
                            .font(.caption)
                            .foregroundStyle(Theme.onBackgroundVariant)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var detailsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                LabeledField("Roaster") {
                    TextField("e.g. Onyx Coffee Lab", text: $brand)
                        .textInputAutocapitalization(.words)
                }
                LabeledField("Bean name") {
                    TextField("e.g. Geometry", text: $name)
                        .textInputAutocapitalization(.words)
                }
                LabeledField("Origin") {
                    TextField("e.g. Ethiopia, Yirgacheffe", text: $origin)
                        .textInputAutocapitalization(.words)
                }
                LabeledField("Roast") {
                    Picker("Roast", selection: $roastLevel) {
                        ForEach(RoastLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                LabeledField("Process") {
                    Picker("Process", selection: $process) {
                        Text("—").tag(ProcessMethod?.none)
                        ForEach(ProcessMethod.allCases) { p in
                            Text(p.displayName).tag(ProcessMethod?.some(p))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                LabeledField("Tasting notes") {
                    TastingNotesEditor(notes: $tastingNotes)
                }
                Toggle(isOn: $hasRoastedOn) {
                    Text("Roast date")
                        .font(.callout)
                        .foregroundStyle(Theme.onBackground)
                }
                if hasRoastedOn {
                    DatePicker("", selection: $roastedOn, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var notesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.onBackground)
                TextField("Anything to remember about this bag…", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    // MARK: - Save / hydrate

    private func save() {
        let bag = editing ?? Bag()
        bag.brand = brand.trimmingCharacters(in: .whitespaces)
        bag.name = name.trimmingCharacters(in: .whitespaces)
        bag.origin = origin.trimmingCharacters(in: .whitespaces)
        bag.roastLevel = roastLevel
        bag.process = process
        bag.tastingNotes = tastingNotes
        bag.roastedOn = hasRoastedOn ? roastedOn : nil
        bag.notes = notes.isEmpty ? nil : notes
        bag.imageData = imageData
        if editing == nil {
            context.insert(bag)
        }
        try? context.save()
        savedSuccessfully = true
        dismiss()
    }

    private func hydrateFromEditing() {
        guard let editing else { return }
        brand = editing.brand
        name = editing.name
        origin = editing.origin
        roastLevel = editing.roastLevel
        process = editing.process
        tastingNotes = editing.tastingNotes
        if let roasted = editing.roastedOn {
            roastedOn = roasted
            hasRoastedOn = true
        }
        notes = editing.notes ?? ""
        imageData = editing.imageData
        // Reset dirty after hydration
        DispatchQueue.main.async { isDirty = false }
    }

    private func trackDirty() { isDirty = true }

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            imageData = compress(data)
        }
    }

    private func compress(_ data: Data) -> Data {
        guard let img = UIImage(data: data) else { return data }
        let max: CGFloat = 1200
        let scale = min(1, max / Swift.max(img.size.width, img.size.height))
        let target = CGSize(width: img.size.width * scale, height: img.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in img.draw(in: CGRect(origin: .zero, size: target)) }
        return resized.jpegData(compressionQuality: 0.75) ?? data
    }
}

