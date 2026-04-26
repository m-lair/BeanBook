import SwiftUI
import SwiftData
import PhotosUI

struct NewBrewSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Bag.createdAt, order: .reverse) private var bags: [Bag]
    @Query(sort: \BrewPreset.createdAt, order: .reverse) private var presets: [BrewPreset]

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
                    bagPickerCard

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
                    resultCard

                    SectionHeader(title: "Save as preset", subtitle: "Reuse these settings later")
                    presetCard
                }
                .padding(Theme.screenPadding)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New Brew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !presets.isEmpty {
                        Menu {
                            ForEach(presets.filter { $0.method == method }) { preset in
                                Button(preset.name) { applyPreset(preset) }
                            }
                            if presets.filter({ $0.method == method }).isEmpty {
                                Text("No presets for \(method.displayName)")
                            }
                        } label: {
                            Image(systemName: "list.bullet.rectangle")
                        }
                    }
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
            .onChange(of: dose) { trackDirty() }
            .onChange(of: yield) { trackDirty() }
            .onChange(of: brewTimeSeconds) { trackDirty() }
            .onChange(of: grindSetting) { trackDirty() }
            .onChange(of: waterTempC) { trackDirty() }
            .onChange(of: bag) { _, newBag in
                trackDirty()
                if let newBag {
                    pullDefaultsFromLastBrew(on: newBag)
                }
            }
            .onChange(of: rating) { trackDirty() }
            .onChange(of: notes) { trackDirty() }
            .onChange(of: imageData) { trackDirty() }
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(item) }
            }
        }
    }

    // MARK: - Subsections

    private var bagPickerCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "bag.fill")
                    .foregroundStyle(Theme.primary)
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
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var resultCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Rating")
                        .font(.caption)
                        .foregroundStyle(Theme.onBackgroundVariant)
                    Spacer()
                    StarRating(rating: $rating)
                }

                Divider()

                Text("Notes")
                    .font(.caption)
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

    private var presetCard: some View {
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

    // MARK: - Defaults

    private func applyMethodDefaultsIfFresh(_ method: BrewMethod) {
        // Don't clobber if user has typed values, unless they're the previous method's defaults.
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
        didHydrate = true

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
        DispatchQueue.main.async { isDirty = false }
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
