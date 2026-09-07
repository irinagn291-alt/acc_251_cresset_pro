import SwiftUI

/// Role: Volume. Fuse place-a-book onto Board as a sheet. Not a tab.
struct MooringDraft: View {
    var watch: HarborWatch
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: Field?
    @State private var title = ""
    @State private var pageRaw = ""
    @State private var paceRaw = "0.5"
    @State private var drift: Drift = .fable

    private enum Field: Hashable {
        case title
        case pages
        case pace
    }

    private var pageCount: Int? { LampFigure.parseCount(pageRaw) }
    private var pace: Double? { LampFigure.parseDecimal(paceRaw) }

    private var pagesBinding: Binding<String> {
        Binding(
            get: { pageRaw },
            set: { pageRaw = LampFigure.sanitizeCount($0) }
        )
    }

    private var paceBinding: Binding<String> {
        Binding(
            get: { paceRaw },
            set: { paceRaw = LampFigure.sanitizeDecimal($0) }
        )
    }

    private var ready: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard let pageCount, pageCount > 0 else { return false }
        guard let pace, pace > 0, pace.isFinite else { return false }
        return !watch.isCommitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .lampInk(.body)
                        .focused($focus, equals: .title)
                        .textInputAutocapitalization(.words)
                    TextField("Page count", text: pagesBinding)
                        .lampInk(.body)
                        .focused($focus, equals: .pages)
                        .keyboardType(.numberPad)
                    Picker("Genre isle", selection: $drift) {
                        ForEach(Drift.allCases) { item in
                            Text(item.mooringName).tag(item)
                        }
                    }
                    TextField("Pace, pages per minute", text: paceBinding)
                        .lampInk(.body)
                        .focused($focus, equals: .pace)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Volume")
                } footer: {
                    Text("The book lands on its genre isle. Logging later uses this pace.")
                        .font(LampFace.font(.caption))
                }
                if let fault = watch.fault {
                    Section {
                        Text(fault)
                            .font(LampFace.font(.callout))
                            .foregroundStyle(HarborInk.Palette.ink)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .contentMargins(.bottom, LampFace.space(3), for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(HarborInk.Palette.background.ignoresSafeArea())
            .navigationTitle("Place a book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: LampFace.tap, height: LampFace.tap)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focus = nil
                    }
                    .accessibilityLabel("Done")
                }
            }
            .safeAreaInset(edge: .bottom) {
                LampChromeButton(
                    title: "Moor this volume",
                    fills: true,
                    emphasized: true,
                    enabled: ready,
                    busy: watch.isCommitting
                ) {
                    Task { await submit() }
                }
                .padding(.horizontal, LampFace.space(2))
                .padding(.bottom, LampFace.space(2))
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(HarborInk.Palette.background)
        .onTapGesture {
            focus = nil
        }
        .animation(reduceMotion ? nil : LampFace.motion, value: ready)
    }

    private func submit() async {
        guard let pageCount, let pace else { return }
        await watch.placeVolume(title: title, pageCount: pageCount, drift: drift, pace: pace)
        if watch.fault == nil {
            dismiss()
        }
    }
}
