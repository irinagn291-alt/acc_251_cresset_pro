import SwiftUI

/// Role: Wake. Fuse a sitting onto Board as a sheet. Logging fills Wake; the token does not walk.
struct SittingDraft: View {
    var watch: HarborWatch
    @Environment(\.dismiss) private var dismiss
    @FocusState private var minutesFocused: Bool
    @State private var minutesRaw = ""

    private var minutes: Double? {
        LampFigure.parseDecimal(minutesRaw)
    }

    private var minutesBinding: Binding<String> {
        Binding(
            get: { minutesRaw },
            set: { minutesRaw = LampFigure.sanitizeDecimal($0) }
        )
    }

    private var ready: Bool {
        minutes != nil && watch.focused?.moored != nil && !watch.isCommitting
    }

    var body: some View {
        NavigationStack {
            Form {
                if let isle = watch.focused, let volume = isle.moored {
                    Section {
                        LabeledContent("Volume") {
                            Text(volume.title)
                                .lampInk(.body)
                                .lineLimit(1)
                        }
                        LabeledContent("Isle") {
                            Text(isle.drift.mooringName)
                                .lampInk(.body)
                        }
                        LabeledContent("Pace") {
                            Text("\(LampFigure.pace(volume.pace)) pages / min")
                                .lampInk(.body)
                        }
                        TextField("Minutes", text: minutesBinding)
                            .lampInk(.body)
                            .keyboardType(.decimalPad)
                            .focused($minutesFocused)
                        if let minutes {
                            LabeledContent("Pages to Wake") {
                                Text(LampFigure.pages(watch.previewPages(minutes: minutes)))
                                    .lampInk(.figure)
                            }
                        }
                    } header: {
                        Text("Sitting")
                    } footer: {
                        Text("Pages equal minutes times pace and add to Wake. The token stays until you Step.")
                            .font(LampFace.font(.caption))
                    }
                } else {
                    Section {
                        Text("Place a volume before logging minutes.")
                            .lampInk(.body)
                    }
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
            .navigationTitle("Log minutes")
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
                        minutesFocused = false
                    }
                    .accessibilityLabel("Done")
                }
            }
            .safeAreaInset(edge: .bottom) {
                LampChromeButton(
                    title: "Add to Wake",
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
            minutesFocused = false
        }
    }

    private func submit() async {
        guard let minutes else { return }
        await watch.logSitting(minutes: minutes)
        if watch.fault == nil {
            dismiss()
        }
    }
}
