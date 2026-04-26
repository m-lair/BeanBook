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

    @State private var didHydrate = false
    @State private var isDirty = false
    @State private var savedSuccessfully = false

    private var isValid: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.cardSpacing) {
                    PhotoPickerSection(imageData: $imageData, photoItem: $photoItem)
                    BagDetailsSection(
                        brand: $brand,
                        name: $name,
                        origin: $origin,
                        roastLevel: $roastLevel,
                        process: $process,
                        tastingNotes: $tastingNotes,
                        roastedOn: $roastedOn,
                        hasRoastedOn: $hasRoastedOn
                    )
                    NotesSection(notes: $notes)
                }
                .padding(Theme.screenPadding)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New Bag" : "Edit Bag")
            .toolbarTitleDisplayMode(.inline)
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
            .onChange(of: brand) { _, _ in trackDirty() }
            .onChange(of: name) { _, _ in trackDirty() }
            .onChange(of: origin) { _, _ in trackDirty() }
            .onChange(of: roastLevel) { _, _ in trackDirty() }
            .onChange(of: process) { _, _ in trackDirty() }
            .onChange(of: tastingNotes) { _, _ in trackDirty() }
            .onChange(of: roastedOn) { _, _ in trackDirty() }
            .onChange(of: hasRoastedOn) { _, _ in trackDirty() }
            .onChange(of: notes) { _, _ in trackDirty() }
            .onChange(of: imageData) { _, _ in trackDirty() }
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(item) }
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
        guard !didHydrate else { return }
        defer {
            didHydrate = true
            isDirty = false
        }
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
    }

    private func trackDirty() {
        guard didHydrate else { return }
        isDirty = true
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        let compressed = await Task.detached(priority: .utility) {
            ImageCompressor.compress(data)
        }.value
        imageData = compressed
    }
}

// MARK: - Sections

private struct PhotoPickerSection: View {
    @Binding var imageData: Data?
    @Binding var photoItem: PhotosPickerItem?

    var body: some View {
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
                        .clipShape(.rect(cornerRadius: Theme.cardRadius))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.primary)
                            .accessibilityHidden(true)
                        Text("Add photo")
                            .font(.footnote)
                            .foregroundStyle(Theme.onBackgroundVariant)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(imageData == nil ? "Add bag photo" : "Replace bag photo")
    }
}

private struct BagDetailsSection: View {
    @Binding var brand: String
    @Binding var name: String
    @Binding var origin: String
    @Binding var roastLevel: RoastLevel
    @Binding var process: ProcessMethod?
    @Binding var tastingNotes: [String]
    @Binding var roastedOn: Date
    @Binding var hasRoastedOn: Bool

    var body: some View {
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
                    DatePicker("Roast date", selection: $roastedOn, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct NotesSection: View {
    @Binding var notes: String

    var body: some View {
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
}
