import SwiftUI

/// Role: Lamp. Three-to-four pages. Skip still writes defaults. Re-runnable from Settings.
struct LampPassage: View {
    var watch: HarborWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let last = 3

    var body: some View {
        VStack(spacing: LampFace.space(2)) {
            Group {
                switch page {
                case 0:
                    pageView(
                        image: "crs_Onboarding1",
                        title: "Place a book on an island",
                        line: "Each genre has an isle. Moor a volume with its title, pages, and pace."
                    )
                case 1:
                    pageView(
                        image: "crs_Onboarding2",
                        title: "Log minutes into a wake",
                        line: "Pages equal minutes times pace. They pool in Wake. The token stays put."
                    )
                case 2:
                    pageView(
                        image: "crs_Onboarding3",
                        title: "Step when Wake holds ten",
                        line: "Step writes a TileMark, spends ten pages, and walks one tile."
                    )
                default:
                    pageView(
                        image: "crs_TwistHero",
                        title: "Light the lighthouse",
                        line: "The first TileMark lights the lamp and unlocks the eight-tile ring."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : LampFace.motion, value: page)
            LampChromeButton(
                title: page < last ? "Next" : "Open the board",
                fills: true,
                emphasized: true,
                busy: watch.isCommitting
            ) {
                if page < last {
                    page += 1
                } else {
                    Task { await watch.finishOnboarding(skipped: false) }
                }
            }
            Button {
                Task { await watch.finishOnboarding(skipped: true) }
            } label: {
                Text("Skip")
                    .lampInk(.body)
                    .frame(maxWidth: .infinity, minHeight: LampFace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(LampPressStyle(enabled: !watch.isCommitting))
            .disabled(watch.isCommitting)
            .accessibilityLabel("Skip")
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HarborInk.Palette.background.ignoresSafeArea())
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: LampFace.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            Text(title)
                .lampInk(.beacon)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(line)
                .font(LampFace.font(.body))
                .foregroundStyle(HarborInk.Palette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
