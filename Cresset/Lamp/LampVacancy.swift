import SwiftUI

/// Role: Lamp. Full-page empty or error. Art, headline, line, bottom CTA.
struct LampVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        VStack(spacing: LampFace.space(2)) {
            VStack(spacing: LampFace.space(2)) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .accessibilityHidden(true)
                Text(headline)
                    .lampInk(.title)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text(line)
                    .font(LampFace.font(.body))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            LampChromeButton(
                title: actionTitle,
                fills: true,
                emphasized: true,
                enabled: enabled,
                action: action
            )
        }
        .padding(.horizontal, LampFace.space(2))
        .padding(.bottom, LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HarborInk.Palette.background)
    }
}
