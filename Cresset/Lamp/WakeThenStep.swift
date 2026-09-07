import SwiftUI

/// Role: Lamp. Wake-then-step. Own screen plus the Step surface on Board.
struct WakeThenStep: View {
    var watch: HarborWatch
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LampFace.space(2)) {
                    Image("crs_TwistHero")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: LampFace.space(28))
                        .accessibilityHidden(true)
                    Text("Wake, then step")
                        .lampInk(.beacon)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text("Logging writes minutes. Pages equal minutes times pace and pool in Wake. The token does not walk on log.")
                        .lampInk(.body)
                    Text("When Wake holds ten pages, Step writes a TileMark, spends ten, and walks one tile. A sitting that leaves Wake under ten still saves.")
                        .lampInk(.body)
                    Text("The first TileMark lights the lighthouse and unlocks the eight-tile ring. Later steps stay lit until eight.")
                        .lampInk(.body)
                    if let isle = watch.focused {
                        VStack(alignment: .leading, spacing: LampFace.space(1)) {
                            Text(isle.moored?.title ?? isle.drift.mooringName)
                                .lampInk(.title)
                                .lineLimit(1)
                            HStack(spacing: LampFace.space(2)) {
                                figure(LampFigure.pages(isle.wake.pages), "Wake")
                                figure(LampFigure.count(isle.marks.count), "TileMarks")
                                figure(isle.lamp == nil ? "—" : "On", "Lamp")
                            }
                            Text(isle.canStep ? "Tap Step on the board to walk one tile." : "Log minutes until Wake holds ten pages.")
                                .font(LampFace.font(.callout))
                                .foregroundStyle(HarborInk.Palette.ink)
                        }
                        .padding(LampFace.space(2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HarborInk.Palette.surface)
                        .clipShape(LampFace.cardShape)
                        .lampRaised()
                    }
                    LampChromeButton(
                        title: "Back to the board",
                        fills: true,
                        emphasized: true
                    ) {
                        watch.tab = .board
                        close()
                    }
                }
                .padding(LampFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, LampFace.space(3), for: .scrollContent)
            .background(HarborInk.Palette.background.ignoresSafeArea())
            .navigationTitle("Wake then step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        close()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: LampFace.tap, height: LampFace.tap)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(HarborInk.Palette.background)
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .lampInk(.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(LampFace.font(.caption))
                .foregroundStyle(HarborInk.Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}
