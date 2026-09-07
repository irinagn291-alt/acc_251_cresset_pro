import SwiftUI

/// Role: Lamp. SF Pro type scale, 8pt spacing, 20/12 radii, one shadow. Hex stays in HarborInk.
enum LampFace {
    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let cardRadius: CGFloat = 20
    static let chipRadius: CGFloat = 12
    static let motion = Animation.easeInOut(duration: 0.28)
    static let fade = Animation.easeInOut(duration: 0.22)

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    enum Step: CaseIterable {
        case beacon
        case title
        case body
        case callout
        case caption
        case figure

        var font: Font {
            switch self {
            case .beacon:
                .system(.title).weight(.semibold)
            case .title:
                .system(.title3).weight(.semibold)
            case .body:
                .system(.body)
            case .callout:
                .system(.callout)
            case .caption:
                .system(.caption)
            case .figure:
                .system(.title2).weight(.semibold).monospacedDigit()
            }
        }
    }

    static func font(_ step: Step) -> Font {
        step.font
    }

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
    }

    static var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
    }
}

/// Role: Lamp. Pressed scale on chrome. Reduce Motion fades instead. Disabled is faded, not missing.
struct LampPressStyle: ButtonStyle {
    var enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        LampPressBody(configuration: configuration, enabled: enabled)
    }
}

private struct LampPressBody: View {
    var configuration: ButtonStyle.Configuration
    var enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed && enabled ? 0.97 : 1)
            .opacity(enabled ? (configuration.isPressed ? 0.88 : 1) : 0.45)
            .animation(reduceMotion ? LampFace.fade : LampFace.motion, value: configuration.isPressed)
    }
}

private struct LampElevation: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(
            color: HarborInk.Palette.ink.opacity(0.12),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

extension View {
    func lampInk(_ step: LampFace.Step) -> some View {
        font(LampFace.font(step))
            .foregroundStyle(HarborInk.Palette.ink)
    }

    func lampRaised() -> some View {
        modifier(LampElevation())
    }

    func lampCardFill() -> some View {
        background(HarborInk.Palette.surface)
            .clipShape(LampFace.cardShape)
            .lampRaised()
    }
}

/// Role: Lamp. Soft-card primary control. The whole chrome is the target. Accent is a ring and fill, never the only signal.
struct LampChromeButton: View {
    var title: String
    var detail: String? = nil
    var artwork: String? = nil
    var fills: Bool = true
    var emphasized: Bool = false
    var enabled: Bool = true
    var busy: Bool = false
    var progress: Double? = nil
    var hint: String? = nil
    var action: () -> Void

    private var active: Bool { enabled && !busy }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: LampFace.space(2)) {
                    if let artwork {
                        Image(artwork)
                            .resizable()
                            .scaledToFit()
                            .frame(width: LampFace.space(4), height: LampFace.space(4))
                            .accessibilityHidden(true)
                    }
                    VStack(spacing: 0) {
                        Text(title)
                            .lampInk(.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        if let detail {
                            Text(detail)
                                .font(LampFace.font(.caption))
                                .foregroundStyle(HarborInk.Palette.ink)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                    }
                    .frame(maxWidth: fills ? .infinity : nil)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, LampFace.space(2))
                .padding(.vertical, LampFace.space(1))
                if let progress, emphasized {
                    LampWakeMeter(fill: progress)
                        .padding(.horizontal, LampFace.space(2))
                        .padding(.bottom, LampFace.space(1))
                }
            }
            .frame(maxWidth: fills ? .infinity : nil, minHeight: LampFace.tap)
            .background(HarborInk.Palette.surface)
            .clipShape(LampFace.cardShape)
            .overlay {
                LampFace.cardShape.stroke(
                    emphasized && active ? HarborInk.Palette.accent : HarborInk.Palette.muted.opacity(0.35),
                    lineWidth: emphasized && active ? 3 : 1
                )
            }
            .lampRaised()
            .contentShape(LampFace.cardShape)
        }
        .buttonStyle(LampPressStyle(enabled: active))
        .disabled(!active)
        .accessibilityLabel(detail.map { "\(title). \($0)" } ?? title)
        .accessibilityHint(hint ?? "")
    }
}

/// Role: Lamp. Accent progress fill with a shape, so colour is never the only signal.
struct LampWakeMeter: View {
    var fill: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                LampFace.chipShape
                    .fill(HarborInk.Palette.muted.opacity(0.18))
                LampFace.chipShape
                    .fill(HarborInk.Palette.accent)
                    .frame(width: max(LampFace.space(1), proxy.size.width * CGFloat(clamped)))
            }
        }
        .frame(height: LampFace.space(1))
        .accessibilityHidden(true)
    }

    private var clamped: Double {
        min(1, max(0, fill))
    }
}

/// Role: Lamp. Recoverable fault with a retry control.
struct HarborBanner: View {
    var text: String
    var retryTitle: String = "Retry"
    var retry: () -> Void

    var body: some View {
        HStack(spacing: LampFace.space(1)) {
            Text(text)
                .font(LampFace.font(.callout))
                .foregroundStyle(HarborInk.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: retry) {
                Text(retryTitle)
                    .font(LampFace.font(.callout).weight(.semibold))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .frame(minWidth: LampFace.tap, minHeight: LampFace.tap)
                    .padding(.horizontal, LampFace.space(1))
                    .background(HarborInk.Palette.surface)
                    .clipShape(LampFace.chipShape)
                    .contentShape(LampFace.chipShape)
            }
            .buttonStyle(LampPressStyle(enabled: true))
            .accessibilityLabel(retryTitle)
        }
        .padding(.horizontal, LampFace.space(2))
        .padding(.vertical, LampFace.space(1))
        .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
        .background(HarborInk.Palette.surface)
        .clipShape(LampFace.cardShape)
        .lampRaised()
    }
}

/// Role: Lamp. Sheet header with a dismiss that always works.
struct LampSheetBar: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: LampFace.space(1)) {
            Text(title)
                .lampInk(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(LampFace.font(.body).weight(.semibold))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .frame(width: LampFace.tap, height: LampFace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(LampPressStyle(enabled: true))
            .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, minHeight: LampFace.tap)
    }
}

/// Role: Lamp. Icon control. SF Symbol is the affordance, not the brand.
struct LampGlyphButton: View {
    var systemName: String
    var label: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(LampFace.font(.body).weight(.semibold))
                .foregroundStyle(HarborInk.Palette.ink)
                .frame(width: LampFace.tap, height: LampFace.tap)
                .background(HarborInk.Palette.surface)
                .clipShape(LampFace.chipShape)
                .lampRaised()
                .contentShape(LampFace.chipShape)
        }
        .buttonStyle(LampPressStyle(enabled: enabled))
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// Role: Lamp. Lit lamps and walked tiles. Fills leftover Settings / Analytics height.
struct HarborWalkPlate: View {
    var isles: [Isle]
    var showsWake: Bool
    var stacked: Bool
    var onOpen: (Isle) -> Void

    var body: some View {
        Group {
            if isles.isEmpty {
                Image("crs_EmptyHome")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(LampFace.space(2))
                    .accessibilityHidden(true)
            } else if stacked {
                VStack(spacing: LampFace.space(1)) {
                    ForEach(isles) { isle in
                        cell(isle)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: LampFace.space(1)) {
                    ForEach(0..<rowCount, id: \.self) { row in
                        HStack(spacing: LampFace.space(1)) {
                            ForEach(isles(in: row)) { isle in
                                cell(isle)
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LampFace.space(1))
        .background(HarborInk.Palette.background)
        .clipShape(LampFace.cardShape)
    }

    private var rowCount: Int {
        (isles.count + 1) / 2
    }

    private func isles(in row: Int) -> [Isle] {
        let start = row * 2
        let end = min(start + 2, isles.count)
        guard start < end else { return [] }
        return Array(isles[start..<end])
    }

    private func cell(_ isle: Isle) -> some View {
        Button {
            onOpen(isle)
        } label: {
            VStack(alignment: .leading, spacing: LampFace.space(1)) {
                HStack(spacing: LampFace.space(1)) {
                    Image(isle.lamp == nil ? "crs_VacantMooring" : "crs_CressetLamp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LampFace.space(5), height: LampFace.space(5))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(isle.moored?.title ?? isle.drift.mooringName)
                            .lampInk(.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(cellLine(isle))
                            .font(LampFace.font(.caption))
                            .foregroundStyle(HarborInk.Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(showsWake ? LampFigure.pages(isle.wake.pages) : LampFigure.count(isle.marks.count))
                        .lampInk(.figure)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(1)
                }
                HStack(spacing: LampFace.space(1)) {
                    ForEach(0..<Isle.totalTiles, id: \.self) { index in
                        Capsule()
                            .fill(
                                index < isle.marks.count
                                    ? HarborInk.Palette.accent
                                    : HarborInk.Palette.ink.opacity(0.18)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: LampFace.space(1))
                    }
                }
                .accessibilityHidden(true)
            }
            .padding(LampFace.space(1))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .frame(minHeight: LampFace.tap)
            .background(HarborInk.Palette.surface)
            .clipShape(LampFace.cardShape)
            .contentShape(LampFace.cardShape)
        }
        .buttonStyle(LampPressStyle(enabled: true))
        .accessibilityLabel(cellLabel(isle))
        .accessibilityHint("Opens the board on this isle.")
    }

    private func cellLine(_ isle: Isle) -> String {
        if showsWake {
            return "Wake \(LampFigure.pages(isle.wake.pages)) · \(LampFigure.count(isle.sittings.count)) sittings"
        }
        let lamp = isle.lamp == nil ? "Lamp unlit" : "Lamp lit"
        return "\(LampFigure.count(isle.marks.count)) tiles · \(lamp)"
    }

    private func cellLabel(_ isle: Isle) -> String {
        let title = isle.moored?.title ?? isle.drift.mooringName
        let lamp = isle.lamp == nil ? "lamp unlit" : "lamp lit"
        return "\(title), \(LampFigure.count(isle.marks.count)) tiles, wake \(LampFigure.pages(isle.wake.pages)), \(lamp)"
    }
}
