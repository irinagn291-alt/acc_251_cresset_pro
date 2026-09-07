import SwiftUI

/// Role: Isle. Home board. One Canvas for the archipelago. Step is the persisted verb.
struct BoardHarbor: View {
    var watch: HarborWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var placing = false
    @State private var sitting = false
    @State private var twist = false
    @State private var showSuccess = false
    @State private var successTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 700
            VStack(spacing: 0) {
                header
                if wide, !watch.isEmpty, !watch.loadFailed {
                    HStack(alignment: .top, spacing: LampFace.space(2)) {
                        hero
                        chrome(expands: true)
                            .frame(width: min(380, max(280, proxy.size.width * 0.38)))
                    }
                    .padding(.horizontal, LampFace.space(2))
                    .padding(.bottom, LampFace.space(2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    hero
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .safeAreaInset(edge: .bottom) {
                if !wide, !watch.isEmpty, !watch.loadFailed {
                    chrome(expands: false)
                        .padding(.horizontal, LampFace.space(2))
                        .padding(.bottom, LampFace.space(1))
                }
            }
        }
        .background(HarborInk.Palette.background.ignoresSafeArea(edges: .top))
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $placing) {
            MooringDraft(watch: watch)
        }
        .sheet(isPresented: $sitting) {
            SittingDraft(watch: watch)
        }
        .sheet(isPresented: $twist) {
            WakeThenStep(watch: watch, onClose: { twist = false })
        }
        .sensoryFeedback(.success, trigger: watch.commitTick)
        .onChange(of: watch.steppedTick) { _, _ in
            flashSuccess()
        }
        .onDisappear {
            successTask?.cancel()
        }
        .overlay {
            if showSuccess {
                Image("crs_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LampFace.space(10), height: LampFace.space(10))
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? LampFace.fade : LampFace.motion, value: showSuccess)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: LampFace.space(1)) {
            ZStack(alignment: .topTrailing) {
                Image("crs_HeaderDecor")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: LampFace.space(6), maxHeight: LampFace.space(8))
                    .clipped()
                    .accessibilityHidden(true)
                HStack(spacing: LampFace.space(1)) {
                    LampGlyphButton(
                        systemName: "clock",
                        label: "Log minutes",
                        enabled: watch.focused?.moored != nil && !watch.isCommitting
                    ) {
                        sitting = true
                    }
                    LampGlyphButton(
                        systemName: "plus",
                        label: "Place a book",
                        enabled: !watch.isCommitting
                    ) {
                        placing = true
                    }
                }
                .padding(.trailing, LampFace.space(1))
                .padding(.top, LampFace.space(1))
            }
            HStack(alignment: .top, spacing: LampFace.space(1)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(watch.jobTitle)
                        .lampInk(.beacon)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(watch.jobLine)
                        .font(LampFace.font(.body))
                        .foregroundStyle(HarborInk.Palette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !watch.isEmpty {
                Button {
                    watch.tab = .analytics
                } label: {
                    HStack(spacing: LampFace.space(2)) {
                        stripFigure(LampFigure.count(watch.board.tileMarkCount), "TileMarks")
                        stripFigure(LampFigure.count(watch.board.lampCount), "Lamps")
                        stripFigure(LampFigure.pages(watch.focused?.wake.pages ?? 0), "Wake")
                    }
                    .padding(.horizontal, LampFace.space(2))
                    .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
                    .background(HarborInk.Palette.surface)
                    .clipShape(LampFace.cardShape)
                    .lampRaised()
                    .contentShape(LampFace.cardShape)
                }
                .buttonStyle(LampPressStyle(enabled: true))
                .accessibilityLabel(
                    "Analytics, \(LampFigure.count(watch.board.tileMarkCount)) TileMarks, \(LampFigure.count(watch.board.lampCount)) lamps"
                )
            }
        }
        .padding(.horizontal, LampFace.space(2))
        .padding(.bottom, LampFace.space(1))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HarborInk.Palette.background)
    }

    private func stripFigure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .lampInk(.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text(caption)
                .font(LampFace.font(.caption))
                .foregroundStyle(HarborInk.Palette.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var hero: some View {
        ZStack {
            if watch.isHauling {
                ProgressView()
                    .tint(HarborInk.Palette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if watch.loadFailed {
                LampVacancy(
                    image: "crs_EmptyHome",
                    headline: "The harbor could not be read.",
                    line: watch.fault ?? "The water is empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else if watch.isEmpty {
                LampVacancy(
                    image: "crs_EmptyHome",
                    headline: "The water is empty.",
                    line: "Place the first book on a genre island.",
                    actionTitle: "Place a book",
                    enabled: !watch.isCommitting
                ) {
                    placing = true
                }
            } else {
                archipelago
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var archipelago: some View {
        GeometryReader { proxy in
            let spots = MooringPlot.spots(
                isles: watch.board.isles,
                size: proxy.size,
                focusedID: watch.focused?.id
            )
            ZStack {
                ArchipelagoWater(spots: spots, water: HarborInk.Palette.background)
                ForEach(spots) { spot in
                    Button {
                        watch.focus(spot.id)
                    } label: {
                        Color.clear
                            .frame(
                                width: max(LampFace.tap, spot.radius * 2 + LampFace.space(2)),
                                height: max(LampFace.tap, spot.radius * 2 + LampFace.space(2))
                            )
                            .contentShape(Circle())
                    }
                    .buttonStyle(LampPressStyle(enabled: true))
                    .position(spot.center)
                    .accessibilityLabel(label(for: spot.isle))
                    .accessibilityHint("Selects this isle, then Step walks its token.")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? nil : LampFace.motion, value: watch.focused?.id)
    }

    private func chrome(expands: Bool) -> some View {
        VStack(alignment: .leading, spacing: LampFace.space(1)) {
            if watch.recovered, let fault = watch.fault {
                HarborBanner(text: fault) {
                    Task { await watch.retry() }
                }
            } else if let fault = watch.fault, !watch.recovered {
                HarborBanner(text: fault) {
                    Task { await watch.retry() }
                }
            }
            if let isle = watch.focused {
                readout(isle)
            }
            if expands, let isle = watch.focused {
                FocusedIsleWater(isle: isle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(minHeight: LampFace.space(16))
                    .layoutPriority(-1)
                    .accessibilityHidden(true)
            }
            LampChromeButton(
                title: "Step",
                detail: watch.stepDetail,
                artwork: "crs_ControlFace",
                fills: true,
                emphasized: true,
                enabled: watch.canStep,
                busy: watch.isCommitting,
                progress: watch.wakeFill,
                hint: watch.canStep ? "Steps the token one tile." : "Needs ten Wake pages."
            ) {
                Task { await watch.stepToken() }
            }
            Button {
                twist = true
            } label: {
                HStack(spacing: LampFace.space(1)) {
                    Image("crs_TwistHero")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LampFace.space(4), height: LampFace.space(4))
                        .accessibilityHidden(true)
                    Text("How stepping works")
                        .lampInk(.callout)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(HarborInk.Palette.ink)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, LampFace.space(2))
                .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
                .background(HarborInk.Palette.surface)
                .clipShape(LampFace.cardShape)
                .lampRaised()
                .contentShape(LampFace.cardShape)
            }
            .buttonStyle(LampPressStyle(enabled: true))
            .accessibilityLabel("How stepping works")
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: expands ? .infinity : nil, alignment: .top)
        .background {
            Image("crs_CardBackdrop")
                .resizable()
                .scaledToFill()
                .opacity(0.28)
                .clipped()
                .accessibilityHidden(true)
        }
        .background(HarborInk.Palette.surface)
        .clipShape(LampFace.cardShape)
        .lampRaised()
    }

    @ViewBuilder
    private func readout(_ isle: Isle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: LampFace.space(1)) {
                Text(isle.fold.caption)
                    .font(LampFace.font(.caption).weight(.semibold))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .padding(.horizontal, LampFace.space(1))
                    .padding(.vertical, LampFace.space(1))
                    .background(HarborInk.Palette.accent.opacity(0.18))
                    .clipShape(LampFace.chipShape)
                Text(isle.drift.mooringName)
                    .font(LampFace.font(.caption))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(isle.lamp == nil ? "Lamp unlit" : "Lamp lit")
                    .font(LampFace.font(.caption))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            HStack(spacing: LampFace.space(1)) {
                Text(isle.moored?.title ?? "No volume moored")
                    .lampInk(.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Text(LampFigure.pages(isle.wake.pages))
                    .lampInk(.figure)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
            }
        }
    }

    private func label(for isle: Isle) -> String {
        let title = isle.moored?.title ?? isle.drift.mooringName
        let wake = LampFigure.pages(isle.wake.pages)
        let lamp = isle.lamp == nil ? "lamp unlit" : "lamp lit"
        return "\(isle.drift.mooringName) isle, \(title), wake \(wake) pages, \(lamp)"
    }

    private func flashSuccess() {
        successTask?.cancel()
        showSuccess = true
        successTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            showSuccess = false
        }
    }
}

/// Role: Isle. Layout of moorings on the water. Not a view.
private struct MooringSpot: Identifiable {
    var id: UUID
    var isle: Isle
    var center: CGPoint
    var radius: CGFloat
    var focused: Bool
}

private enum MooringPlot {
    static func spots(isles: [Isle], size: CGSize, focusedID: UUID?) -> [MooringSpot] {
        let count = isles.count
        guard count > 0, size.width > 1, size.height > 1 else { return [] }
        let pad = LampFace.space(2)
        let cols = size.width >= 700 ? min(count, 4) : min(count, 2)
        let rows = Int(ceil(Double(count) / Double(max(cols, 1))))
        let cellW = (size.width - pad * 2) / CGFloat(cols)
        let cellH = (size.height - pad * 2) / CGFloat(max(rows, 1))
        let radius = min(cellW, cellH) * 0.32
        return isles.enumerated().map { index, isle in
            let col = index % cols
            let row = index / cols
            let center = CGPoint(
                x: pad + cellW * (CGFloat(col) + 0.5),
                y: pad + cellH * (CGFloat(row) + 0.5)
            )
            return MooringSpot(
                id: isle.id,
                isle: isle,
                center: center,
                radius: max(LampFace.space(4), radius),
                focused: isle.id == focusedID
            )
        }
    }

    static func lone(isle: Isle, size: CGSize) -> [MooringSpot] {
        guard size.width > 1, size.height > 1 else { return [] }
        let radius = min(size.width, size.height) * 0.28
        return [
            MooringSpot(
                id: isle.id,
                isle: isle,
                center: CGPoint(x: size.width / 2, y: size.height / 2),
                radius: max(LampFace.space(6), radius),
                focused: true
            )
        ]
    }

    static func tokenPoint(_ spot: MooringSpot) -> CGPoint {
        guard spot.isle.ringUnlocked else { return spot.center }
        return tilePoint(spot, index: spot.isle.tileIndex)
    }

    static func tilePoint(_ spot: MooringSpot, index: Int) -> CGPoint {
        let angle = (CGFloat(index) / CGFloat(Isle.totalTiles)) * 2 * .pi - .pi / 2
        let ring = spot.radius + LampFace.space(2)
        return CGPoint(
            x: spot.center.x + cos(angle) * ring,
            y: spot.center.y + sin(angle) * ring
        )
    }
}

/// Role: Isle. Close-up of the focused isle. Fills remaining Step-column height.
private struct FocusedIsleWater: View {
    var isle: Isle

    var body: some View {
        GeometryReader { proxy in
            ArchipelagoWater(
                spots: MooringPlot.lone(isle: isle, size: proxy.size),
                water: HarborInk.Palette.surface
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(LampFace.cardShape)
        .overlay {
            LampFace.cardShape.stroke(HarborInk.Palette.ink.opacity(0.12), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

/// Role: Isle. The one custom drawing surface. Every other screen is List, Form, stock controls.
private struct ArchipelagoWater: View {
    var spots: [MooringSpot]
    var water: Color

    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(water)
            )
            for ring in 1 ... 5 {
                let inset = CGFloat(ring) * LampFace.space(3)
                var ripple = Path()
                ripple.addEllipse(
                    in: CGRect(
                        x: inset,
                        y: inset,
                        width: max(0, size.width - inset * 2),
                        height: max(0, size.height - inset * 2)
                    )
                )
                context.stroke(
                    ripple,
                    with: .color(HarborInk.Palette.muted.opacity(0.18)),
                    lineWidth: 1
                )
            }
            for spot in spots {
                drawIsle(spot, in: &context)
            }
        }
        .accessibilityHidden(true)
    }

    private func drawIsle(_ spot: MooringSpot, in context: inout GraphicsContext) {
        let rect = CGRect(
            x: spot.center.x - spot.radius,
            y: spot.center.y - spot.radius * 0.82,
            width: spot.radius * 2,
            height: spot.radius * 1.64
        )
        var land = Path()
        land.addEllipse(in: rect)
        context.fill(land, with: .color(HarborInk.Palette.surface))
        context.stroke(
            land,
            with: .color(spot.focused ? HarborInk.Palette.accent : HarborInk.Palette.ink.opacity(0.35)),
            lineWidth: spot.focused ? 3 : 1.5
        )
        if spot.isle.wake.pages > 0 {
            var pool = Path()
            let poolRect = CGRect(
                x: spot.center.x - spot.radius * 0.55,
                y: spot.center.y + spot.radius * 0.08,
                width: spot.radius * 1.1,
                height: spot.radius * 0.42
            )
            pool.addEllipse(in: poolRect)
            context.fill(pool, with: .color(HarborInk.Palette.accent.opacity(0.28)))
        }
        if spot.isle.ringUnlocked {
            for index in 0 ..< Isle.totalTiles {
                let point = MooringPlot.tilePoint(spot, index: index)
                let tileR = LampFace.space(1)
                var tile = Path()
                tile.addEllipse(
                    in: CGRect(x: point.x - tileR, y: point.y - tileR, width: tileR * 2, height: tileR * 2)
                )
                let walked = spot.isle.marks.contains(where: { $0.index == index })
                if walked {
                    context.fill(tile, with: .color(HarborInk.Palette.accent))
                } else {
                    context.stroke(tile, with: .color(HarborInk.Palette.ink.opacity(0.55)), lineWidth: 1.5)
                }
            }
            drawLamp(at: CGPoint(x: spot.center.x + spot.radius * 0.45, y: spot.center.y - spot.radius * 0.78), in: &context)
        }
        drawToken(at: MooringPlot.tokenPoint(spot), in: &context)
        let title = spot.isle.moored?.title ?? spot.isle.drift.mooringName
        let caption = Text(title)
            .font(LampFace.font(.caption).weight(.semibold))
            .foregroundColor(HarborInk.Palette.ink)
        context.draw(
            caption,
            at: CGPoint(x: spot.center.x, y: spot.center.y - LampFace.space(1)),
            anchor: .center
        )
        let wake = Text("Wake \(LampFigure.pages(spot.isle.wake.pages))")
            .font(LampFace.font(.caption))
            .foregroundColor(HarborInk.Palette.ink)
        context.draw(
            wake,
            at: CGPoint(x: spot.center.x, y: spot.center.y + LampFace.space(2)),
            anchor: .top
        )
    }

    private func drawToken(at point: CGPoint, in context: inout GraphicsContext) {
        let r = LampFace.space(2)
        var head = Path()
        head.addEllipse(in: CGRect(x: point.x - r * 0.45, y: point.y - r, width: r * 0.9, height: r * 0.9))
        var body = Path()
        body.addEllipse(in: CGRect(x: point.x - r * 0.7, y: point.y - r * 0.15, width: r * 1.4, height: r * 0.95))
        context.fill(body, with: .color(HarborInk.Palette.ink))
        context.fill(head, with: .color(HarborInk.Palette.accent))
        context.stroke(body, with: .color(HarborInk.Palette.ink), lineWidth: 1)
    }

    private func drawLamp(at point: CGPoint, in context: inout GraphicsContext) {
        let w = LampFace.space(2)
        var tower = Path()
        tower.addEllipse(
            in: CGRect(x: point.x - w * 0.28, y: point.y - w * 0.1, width: w * 0.56, height: w * 1.05)
        )
        var flame = Path()
        flame.addEllipse(in: CGRect(x: point.x - w * 0.32, y: point.y - w * 0.85, width: w * 0.64, height: w * 0.64))
        context.fill(tower, with: .color(HarborInk.Palette.ink))
        context.fill(flame, with: .color(HarborInk.Palette.accent))
    }
}
