import SwiftUI
import SwiftData
import PhotosUI

struct NewBagSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(BagStore.self) private var bagStore

    var editing: Bag? = nil

    @State private var showingPaywall = false

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
    @State private var showCamera = false

    @State private var didHydrate = false
    @State private var isDirty = false
    @State private var savedSuccessfully = false

    private var isValid: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    IdentitySection(
                        brand: $brand,
                        name: $name,
                        origin: $origin,
                        imageData: $imageData,
                        photoItem: $photoItem,
                        showCamera: $showCamera
                    )
                    CharacteristicsSection(
                        roastLevel: $roastLevel,
                        process: $process,
                        roastedOn: $roastedOn,
                        hasRoastedOn: $hasRoastedOn
                    )
                    TastingSection(
                        tastingNotes: $tastingNotes,
                        notes: $notes
                    )
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New bag" : "Edit bag")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.ink)
                }
                ToolbarItem(placement: .principal) {
                    Text(editing == nil ? "New bag" : "Edit bag")
                        .font(Theme.display(17, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(Theme.body(15, weight: .semibold))
                        .foregroundStyle(isValid ? Theme.accent : Theme.ink3)
                        .disabled(!isValid)
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
            .sheet(isPresented: $showingPaywall) {
                NavigationStack {
                    PaywallSheet(headline: "You've reached the free limit of \(ProQuota.bags) bags. Unlock Pro for unlimited.")
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(imageData: $imageData)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Save / hydrate

    private func save() {
        let trimmedBrand = brand.trimmingCharacters(in: .whitespaces)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedOrigin = origin.trimmingCharacters(in: .whitespaces)
        let resolvedNotes = notes.isEmpty ? nil : notes
        let resolvedRoastedOn = hasRoastedOn ? roastedOn : nil

        if let editing {
            // Edits bypass the quota — never block existing data.
            editing.brand = trimmedBrand
            editing.name = trimmedName
            editing.origin = trimmedOrigin
            editing.roastLevel = roastLevel
            editing.process = process
            editing.tastingNotes = tastingNotes
            editing.roastedOn = resolvedRoastedOn
            editing.notes = resolvedNotes
            editing.imageData = imageData
            try? context.save()
            savedSuccessfully = true
            dismiss()
            return
        }

        do {
            try bagStore.create(
                brand: trimmedBrand,
                name: trimmedName,
                roastLevel: roastLevel,
                origin: trimmedOrigin,
                process: process,
                tastingNotes: tastingNotes,
                roastedOn: resolvedRoastedOn,
                notes: resolvedNotes,
                imageData: imageData
            )
            savedSuccessfully = true
            dismiss()
        } catch is QuotaExceededError {
            showingPaywall = true
        } catch {
            // Persistence failures fall through silently — same as the previous
            // `try? context.save()` behavior. Re-raise here if telemetry is added later.
        }
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

// MARK: - Identity

private struct IdentitySection: View {
    @Binding var brand: String
    @Binding var name: String
    @Binding var origin: String
    @Binding var imageData: Data?
    @Binding var photoItem: PhotosPickerItem?
    @Binding var showCamera: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Eyebrow("Identity", color: Theme.ink2)

            (Text("What did you ")
                .foregroundStyle(Theme.ink)
             + Text("open")
                .foregroundStyle(Theme.accent)
                .italic()
             + Text("?")
                .foregroundStyle(Theme.accent))
                .font(Theme.display(34, weight: .semibold))
                .lineSpacing(2)

            HStack(alignment: .top, spacing: 18) {
                BagPhotoTile(
                    imageData: $imageData,
                    photoItem: $photoItem,
                    showCamera: $showCamera
                )
                VStack(alignment: .leading, spacing: 14) {
                    EditorialField(label: "Roaster", placeholder: "Onyx Coffee Lab", text: $brand, serif: false)
                    EditorialField(label: "Bean", placeholder: "Geometry", text: $name, serif: true)
                }
            }

            EditorialField(
                label: "Origin",
                placeholder: "Ethiopia · Yirgacheffe",
                text: $origin,
                serif: false
            )
        }
    }
}

private struct BagPhotoTile: View {
    @Binding var imageData: Data?
    @Binding var photoItem: PhotosPickerItem?
    @Binding var showCamera: Bool
    @State private var showLibrary = false

    var body: some View {
        Menu {
            if CameraPicker.isAvailable {
                Button("Take Photo", systemImage: "camera") {
                    showCamera = true
                }
            }
            Button("Choose from Library", systemImage: "photo.on.rectangle") {
                showLibrary = true
            }
            if imageData != nil {
                Button("Remove Photo", systemImage: "trash", role: .destructive) {
                    imageData = nil
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.accentSoft)
                if let imageData, let img = UIImage(data: imageData) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(Theme.accent.opacity(0.8))
                        Text("Add photo")
                            .font(Theme.body(11, weight: .semibold))
                            .tracking(0.4)
                            .foregroundStyle(Theme.accent.opacity(0.85))
                    }
                }
            }
            .frame(width: 116, height: 116)
            .clipShape(.rect(cornerRadius: 18, style: .continuous))
            .contentShape(.rect(cornerRadius: 18, style: .continuous))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .photosPicker(isPresented: $showLibrary, selection: $photoItem, matching: .images)
        .accessibilityLabel(imageData == nil ? "Add bag photo" : "Replace bag photo")
    }
}

private struct EditorialField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var serif: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(label, color: Theme.ink2)
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundStyle(Theme.ink2.opacity(0.7))
            )
            .font(serif
                  ? Theme.display(22, weight: .semibold)
                  : Theme.body(17, weight: .regular))
            .foregroundStyle(Theme.ink)
            .textInputAutocapitalization(.words)
            .padding(.bottom, 6)
            HairRule(color: Theme.ink4)
        }
    }
}

// MARK: - Characteristics

private struct CharacteristicsSection: View {
    @Binding var roastLevel: RoastLevel
    @Binding var process: ProcessMethod?
    @Binding var roastedOn: Date
    @Binding var hasRoastedOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Eyebrow("Characteristics", color: Theme.ink2)

            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("Roast", color: Theme.ink2)
                RoastPillControl(level: $roastLevel)
                Text(roastHint)
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.ink2)
            }

            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("Process", color: Theme.ink2)
                ProcessPillControl(process: $process)
            }

            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("Roast date", color: Theme.ink2)
                RoastDateRow(date: $roastedOn, hasDate: $hasRoastedOn)
            }
        }
    }

    private var roastHint: String {
        switch roastLevel {
        case .mediumLight, .mediumDark:
            return "Tap again to refine (\(roastLevel.displayName))"
        default:
            return "Tap again to refine"
        }
    }
}

/// Three-pill roast control with "tap again to refine" — second tap on the
/// anchor pill snaps to the adjacent half-step (Light → Medium-Light, Dark → Medium-Dark).
private struct RoastPillControl: View {
    @Binding var level: RoastLevel

    private struct Anchor: Identifiable {
        let id: RoastLevel
        let title: String
        let refined: RoastLevel?
    }

    private let anchors: [Anchor] = [
        .init(id: .light, title: "Light", refined: .mediumLight),
        .init(id: .medium, title: "Medium", refined: nil),
        .init(id: .dark, title: "Dark", refined: .mediumDark)
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(anchors) { anchor in
                let active = isActive(anchor)
                Button {
                    tap(anchor)
                } label: {
                    Text(active && level == anchor.refined
                         ? level.displayName
                         : anchor.title)
                        .font(Theme.body(15, weight: active ? .semibold : .regular))
                        .foregroundStyle(active ? Color.white : Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(active ? Theme.accent : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule(style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Theme.rule, lineWidth: 0.5)
        )
        .animation(.snappy(duration: 0.2), value: level)
    }

    private func isActive(_ anchor: Anchor) -> Bool {
        if level == anchor.id { return true }
        if let refined = anchor.refined, level == refined { return true }
        return false
    }

    private func tap(_ anchor: Anchor) {
        if level == anchor.id, let refined = anchor.refined {
            level = refined
        } else {
            level = anchor.id
        }
    }
}

private struct ProcessPillControl: View {
    @Binding var process: ProcessMethod?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ProcessMethod.allCases) { p in
                    let active = process == p
                    Button {
                        process = active ? nil : p
                    } label: {
                        Text(p.displayName)
                            .font(Theme.body(14, weight: active ? .semibold : .regular))
                            .foregroundStyle(active ? Color.white : Theme.ink)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(active ? Theme.accent : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Theme.rule, lineWidth: 0.5)
            )
        }
        .animation(.snappy(duration: 0.2), value: process)
    }
}

private struct RoastDateRow: View {
    @Binding var date: Date
    @Binding var hasDate: Bool
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Text(hasDate ? date.formatted(date: .abbreviated, time: .omitted) : "Not sure")
                    .font(Theme.body(16))
                    .foregroundStyle(hasDate ? Theme.ink : Theme.ink2)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.rule, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            RoastDatePickerSheet(date: $date, hasDate: $hasDate)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct RoastDatePickerSheet: View {
    @Binding var date: Date
    @Binding var hasDate: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker("Roast date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Theme.accent)
                    .padding(.horizontal)
                Button("Not sure") {
                    hasDate = false
                    dismiss()
                }
                .font(Theme.body(15))
                .foregroundStyle(Theme.ink2)
            }
            .padding(.top, 8)
            .background(Theme.background)
            .navigationTitle("Roast date")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        hasDate = true
                        dismiss()
                    }
                    .font(Theme.body(15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Tasting

private struct TastingSection: View {
    @Binding var tastingNotes: [String]
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Eyebrow("Tasting", color: Theme.ink2)

            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("Notes", color: Theme.ink2)
                TastingNotesEditor(notes: $tastingNotes)
            }

            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("Memory", color: Theme.ink2)
                TextField(
                    "",
                    text: $notes,
                    prompt: Text("Anything to remember about this bag…")
                        .foregroundStyle(Theme.ink2.opacity(0.7)),
                    axis: .vertical
                )
                .font(Theme.body(15))
                .foregroundStyle(Theme.ink)
                .lineLimit(3...6)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.rule, lineWidth: 0.5)
                )
            }
        }
    }
}
