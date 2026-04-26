import SwiftUI
import SwiftData
import PhotosUI

struct NewBrewSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Bag.createdAt, order: .reverse) private var bags: [Bag]

    /// Optional bag to pre-link.
    var initialBag: Bag? = nil
    /// Optional brew to pre-fill from (for "Brew this again").
    var prefill: Brew? = nil

    @State private var method: BrewMethod = .espresso
    @State private var bag: Bag?
    @State private var dose: Double = 18
    @State private var yield: Double = 36
    @State private var brewTimeSeconds: Int = 30
    @State private var grindSetting: String = ""
    @State private var waterTempC: Double?
    @State private var rating: Int? = nil
    @State private var notes: String = ""
    @State private var imageData: Data?
    @State private var photoItem: PhotosPickerItem?

    @State private var saveAsPreset = false
    @State private var presetName = ""

    @State private var isDirty = false
    @State private var savedSuccessfully = false
    @State private var didHydrate = false

    private var isValid: Bool {
        dose > 0 && yield > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.cardSpacing) {
                    SectionHeader(title: "Method")
                    MethodPicker(selection: $method)
                        .onChange(of: method) { _, newValue in
                            applyMethodDefaultsIfFresh(newValue)
                            trackDirty()
                        }

                    SectionHeader(title: "Bag", subtitle: "Optional")
                    BagPickerCard(bags: bags, bag: $bag)

                    SectionHeader(title: "Parameters")
                    MethodParametersSection(
                        method: method,
                        dose: $dose,
                        yield: $yield,
                        brewTimeSeconds: $brewTimeSeconds,
                        grindSetting: $grindSetting,
                        waterTempC: $waterTempC
                    )

                    SectionHeader(title: "Result")
                    ResultCard(
                        rating: $rating,
                        notes: $notes,
                        imageData: $imageData,
                        photoItem: $photoItem
                    )

                    SectionHeader(title: "Save as preset", subtitle: "Reuse these settings later")
                    PresetCard(saveAsPreset: $saveAsPreset, presetName: $presetName)
                }
                .padding(Theme.screenPadding)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New Brew")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PresetMenu(method: method, apply: applyPreset)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .interactiveDismissDisabled(isDirty)
            .sensoryFeedback(.success, trigger: savedSuccessfully)
            .task { hydrate() }
            .onChange(of: dose) { _, _ in trackDirty() }
            .onChange(of: yield) { _, _ in trackDirty() }
            .onChange(of: brewTimeSeconds) { _, _ in trackDirty() }
            .onChange(of: grindSetting) { _, _ in trackDirty() }
            .onChange(of: waterTempC) { _, _ in trackDirty() }
            .onChange(of: bag) { _, newBag in
                trackDirty()
                if let newBag {
                    pullDefaultsFromLastBrew(on: newBag)
                }
            }
            .onChange(of: rating) { _, _ in trackDirty() }
            .onChange(of: notes) { _, _ in trackDirty() }
            .onChange(of: imageData) { _, _ in trackDirty() }
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(item) }
            }
        }
    }

    // MARK: - Defaults

    private func applyMethodDefaultsIfFresh(_ method: BrewMethod) {
        dose = method.defaultDose
        yield = method.defaultYield
        brewTimeSeconds = method.defaultTimeSeconds
        waterTempC = method.defaultWaterTempC
    }

    private func pullDefaultsFromLastBrew(on bag: Bag) {
        guard let last = bag.brews
            .filter({ $0.method == method })
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first else { return }
        dose = last.doseGrams
        yield = last.yieldGrams
        brewTimeSeconds = last.brewTimeSeconds
        grindSetting = last.grindSetting ?? ""
        waterTempC = last.waterTempC
    }

    private func hydrate() {
        guard !didHydrate else { return }

        if let prefill {
            method = prefill.method
            dose = prefill.doseGrams
            yield = prefill.yieldGrams
            brewTimeSeconds = prefill.brewTimeSeconds
            grindSetting = prefill.grindSetting ?? ""
            waterTempC = prefill.waterTempC
            bag = prefill.bag
        } else if let initialBag {
            bag = initialBag
            applyMethodDefaultsIfFresh(method)
            pullDefaultsFromLastBrew(on: initialBag)
        } else {
            applyMethodDefaultsIfFresh(method)
        }

        didHydrate = true
        isDirty = false
    }

    private func applyPreset(_ preset: BrewPreset) {
        method = preset.method
        dose = preset.doseGrams
        yield = preset.yieldGrams
        brewTimeSeconds = preset.brewTimeSeconds
        grindSetting = preset.grindSetting ?? ""
        waterTempC = preset.waterTempC
        trackDirty()
    }

    // MARK: - Save

    private func save() {
        let brew = Brew(
            method: method,
            doseGrams: dose,
            yieldGrams: yield,
            brewTimeSeconds: brewTimeSeconds,
            grindSetting: grindSetting.isEmpty ? nil : grindSetting,
            waterTempC: waterTempC,
            rating: rating,
            notes: notes.isEmpty ? nil : notes,
            imageData: imageData,
            bag: bag
        )
        context.insert(brew)

        if saveAsPreset {
            let trimmedName = presetName.trimmingCharacters(in: .whitespaces)
            let name = trimmedName.isEmpty ? "\(method.displayName) preset" : trimmedName
            let preset = BrewPreset(
                name: name,
                method: method,
                doseGrams: dose,
                yieldGrams: yield,
                brewTimeSeconds: brewTimeSeconds,
                grindSetting: grindSetting.isEmpty ? nil : grindSetting,
                waterTempC: waterTempC
            )
            context.insert(preset)
        }

        try? context.save()
        savedSuccessfully = true
        dismiss()
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

// MARK: - Subviews

private struct BagPickerCard: View {
    let bags: [Bag]
    @Binding var bag: Bag?

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "bag.fill")
                    .foregroundStyle(Theme.primary)
                    .accessibilityHidden(true)
                Menu {
                    Button("None") { bag = nil }
                    if !bags.isEmpty {
                        Section("Your bags") {
                            ForEach(bags) { b in
                                Button(b.displayTitle) { bag = b }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(bag?.displayTitle ?? "No bag selected")
                            .foregroundStyle(bag == nil ? Theme.onBackgroundVariant : Theme.onBackground)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(Theme.onBackgroundVariant)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel("Bag")
                .accessibilityValue(bag?.displayTitle ?? "None selected")
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct ResultCard: View {
    @Binding var rating: Int?
    @Binding var notes: String
    @Binding var imageData: Data?
    @Binding var photoItem: PhotosPickerItem?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Rating")
                        .font(.footnote)
                        .foregroundStyle(Theme.onBackgroundVariant)
                    Spacer()
                    StarRating(rating: $rating)
                }

                Divider()

                Text("Notes")
                    .font(.footnote)
                    .foregroundStyle(Theme.onBackgroundVariant)
                TextField("How did it taste?", text: $notes, axis: .vertical)
                    .lineLimit(2...5)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack {
                        Image(systemName: imageData == nil ? "camera" : "checkmark.circle.fill")
                        Text(imageData == nil ? "Add photo" : "Photo attached")
                            .font(.callout)
                    }
                    .foregroundStyle(Theme.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct PresetCard: View {
    @Binding var saveAsPreset: Bool
    @Binding var presetName: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $saveAsPreset) {
                    Text("Save these settings as a preset")
                        .font(.callout)
                        .foregroundStyle(Theme.onBackground)
                }
                if saveAsPreset {
                    TextField("Preset name (e.g. \"Morning shot\")", text: $presetName)
                }
            }
        }
    }
}

private struct PresetMenu: View {
    let method: BrewMethod
    let apply: (BrewPreset) -> Void

    @Query private var presets: [BrewPreset]

    init(method: BrewMethod, apply: @escaping (BrewPreset) -> Void) {
        self.method = method
        self.apply = apply
        _presets = Query(
            filter: #Predicate<BrewPreset> { $0.method == method },
            sort: \BrewPreset.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        Menu("Presets", systemImage: "list.bullet.rectangle") {
            if presets.isEmpty {
                Text("No presets for \(method.displayName)")
            } else {
                ForEach(presets) { preset in
                    Button(preset.name) { apply(preset) }
                }
            }
        }
        .labelStyle(.iconOnly)
    }
}
