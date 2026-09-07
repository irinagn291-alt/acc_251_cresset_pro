import SwiftUI

/// Role: Tile. Analytics of TileMarks, lamps, and sittings. Not a shelf of unread titles.
struct MarksAnalytics: View {
    var watch: HarborWatch
    @State private var twist = false

    var body: some View {
        Group {
            if watch.isHauling {
                ProgressView()
                    .tint(HarborInk.Palette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if watch.loadFailed {
                LampVacancy(
                    image: "crs_EmptyList",
                    headline: "Marks could not be read.",
                    line: watch.fault ?? "The harbor started empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else if watch.board.tileMarkCount == 0, watch.sittingsNewestFirst().isEmpty {
                LampVacancy(
                    image: "crs_EmptyList",
                    headline: "No TileMarks yet.",
                    line: "Log minutes, then Step when Wake holds ten pages.",
                    actionTitle: "Open the board"
                ) {
                    watch.tab = .board
                }
            } else {
                populated
            }
        }
        .background(HarborInk.Palette.background.ignoresSafeArea(edges: .top))
        .navigationTitle("Analytics")
        .sheet(isPresented: $twist) {
            WakeThenStep(watch: watch, onClose: { twist = false })
        }
    }

    private var populated: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 700
            Group {
                if wide {
                    wideLog(width: proxy.size.width)
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    phoneList
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(alignment: .bottom) {
                if let fault = watch.fault, !watch.loadFailed {
                    HarborBanner(text: fault) {
                        Task { await watch.retry() }
                    }
                    .padding(LampFace.space(2))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var phoneList: some View {
        List {
            Section {
                hero
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            Section("TileMarks") {
                ForEach(watch.marksNewestFirst()) { mark in
                    markRow(mark)
                }
            }
            Section("Sittings") {
                ForEach(watch.sittingsNewestFirst()) { sitting in
                    sittingRow(sitting)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, LampFace.space(6), for: .scrollContent)
    }

    private func wideLog(width: CGFloat) -> some View {
        HStack(alignment: .top, spacing: LampFace.space(2)) {
            heroColumn
                .frame(width: min(420, max(300, width * 0.36)))
            logColumn(
                title: "TileMarks",
                empty: "Step when Wake holds ten pages.",
                isEmpty: watch.marksNewestFirst().isEmpty,
                showsWake: false
            ) {
                ForEach(watch.marksNewestFirst()) { mark in
                    Button {
                        openIsle(watch.isle(for: mark))
                    } label: {
                        markCard(mark)
                    }
                    .buttonStyle(LampPressStyle(enabled: true))
                    .accessibilityLabel(markLabel(mark))
                    .accessibilityHint("Opens the board on this isle.")
                }
            }
            logColumn(
                title: "Sittings",
                empty: "Log minutes to fill Wake.",
                isEmpty: watch.sittingsNewestFirst().isEmpty,
                showsWake: true
            ) {
                ForEach(watch.sittingsNewestFirst()) { sitting in
                    Button {
                        openIsle(isle(for: sitting))
                    } label: {
                        sittingCard(sitting)
                    }
                    .buttonStyle(LampPressStyle(enabled: true))
                    .accessibilityLabel(sittingLabel(sitting))
                    .accessibilityHint("Opens the board on this isle.")
                }
            }
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var heroColumn: some View {
        VStack(alignment: .leading, spacing: LampFace.space(2)) {
            readout
                .clipShape(LampFace.cardShape)
            LampChromeButton(
                title: "Wake then step",
                detail: "Logging fills Wake. Step walks a tile.",
                artwork: "crs_TwistHero",
                fills: true,
                emphasized: true
            ) {
                twist = true
            }
            Image("crs_TokenPawn")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            Text("Tap a TileMark or sitting to open that isle on the board.")
                .font(LampFace.font(.caption))
                .foregroundStyle(HarborInk.Palette.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HarborInk.Palette.surface)
        .clipShape(LampFace.cardShape)
        .lampRaised()
    }

    private func logColumn<Content: View>(
        title: String,
        empty: String,
        isEmpty: Bool,
        showsWake: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: LampFace.space(1)) {
            Text(title)
                .lampInk(.title)
                .lineLimit(1)
            if isEmpty {
                Text(empty)
                    .font(LampFace.font(.callout))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: LampFace.space(1)) {
                    content()
                }
            }
            walkPlate(showsWake: showsWake)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HarborInk.Palette.surface)
        .clipShape(LampFace.cardShape)
        .lampRaised()
    }

    private func walkPlate(showsWake: Bool) -> some View {
        HarborWalkPlate(
            isles: watch.board.isles,
            showsWake: showsWake,
            stacked: true,
            onOpen: { isle in
                openIsle(isle)
            }
        )
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: LampFace.space(2)) {
            readout
            Button {
                twist = true
            } label: {
                HStack(spacing: LampFace.space(2)) {
                    Image("crs_TwistHero")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LampFace.tap, height: LampFace.tap)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Wake then step")
                            .lampInk(.title)
                            .lineLimit(1)
                        Text("Logging fills Wake. Step walks a tile.")
                            .font(LampFace.font(.caption))
                            .foregroundStyle(HarborInk.Palette.ink)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(HarborInk.Palette.ink)
                        .accessibilityHidden(true)
                }
                .padding(LampFace.space(2))
                .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
                .background(HarborInk.Palette.surface)
                .clipShape(LampFace.cardShape)
                .lampRaised()
                .contentShape(LampFace.cardShape)
            }
            .buttonStyle(LampPressStyle(enabled: true))
        }
        .padding(.vertical, LampFace.space(1))
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: LampFace.space(1)) {
            Text(LampFigure.count(watch.board.tileMarkCount))
                .lampInk(.beacon)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text("TileMarks")
                .font(LampFace.font(.callout))
                .foregroundStyle(HarborInk.Palette.ink)
            HStack(alignment: .firstTextBaseline, spacing: LampFace.space(3)) {
                figure(LampFigure.count(watch.board.lampCount), "Lamps")
                figure(LampFigure.count(watch.sittingsNewestFirst().count), "Sittings")
            }
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Image("crs_CardBackdrop")
                .resizable()
                .scaledToFill()
                .opacity(0.22)
                .clipped()
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(LampFigure.count(watch.board.tileMarkCount)) TileMarks, \(LampFigure.count(watch.board.lampCount)) lamps, \(LampFigure.count(watch.sittingsNewestFirst().count)) sittings"
        )
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: LampFace.space(1)) {
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
    }

    private func markRow(_ mark: TileMark) -> some View {
        HStack(spacing: LampFace.space(2)) {
            markGlyph
            markCopy(mark)
            Spacer(minLength: 0)
            lampGlyph(watch.isle(for: mark))
        }
        .frame(minHeight: LampFace.tap)
        .listRowBackground(HarborInk.Palette.surface)
    }

    private func sittingRow(_ sitting: Sitting) -> some View {
        HStack {
            sittingCopy(sitting)
            Spacer(minLength: 0)
            sittingFigures(sitting)
        }
        .frame(minHeight: LampFace.tap)
        .listRowBackground(HarborInk.Palette.surface)
    }

    private func markCard(_ mark: TileMark) -> some View {
        HStack(spacing: LampFace.space(1)) {
            markGlyph
            markCopy(mark)
            Spacer(minLength: 0)
            lampGlyph(watch.isle(for: mark))
        }
        .padding(LampFace.space(1))
        .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
        .background(HarborInk.Palette.background)
        .clipShape(LampFace.cardShape)
        .contentShape(LampFace.cardShape)
    }

    private func sittingCard(_ sitting: Sitting) -> some View {
        HStack(spacing: LampFace.space(1)) {
            sittingCopy(sitting)
            Spacer(minLength: 0)
            sittingFigures(sitting)
        }
        .padding(LampFace.space(1))
        .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
        .background(HarborInk.Palette.background)
        .clipShape(LampFace.cardShape)
        .contentShape(LampFace.cardShape)
    }

    private var markGlyph: some View {
        Image("crs_TokenPawn")
            .resizable()
            .scaledToFit()
            .frame(width: LampFace.space(4), height: LampFace.space(4))
            .accessibilityHidden(true)
    }

    private func lampGlyph(_ isle: Isle?) -> some View {
        Group {
            if isle?.lamp != nil {
                Image("crs_CressetLamp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LampFace.space(4), height: LampFace.space(4))
                    .accessibilityHidden(true)
            }
        }
    }

    private func markCopy(_ mark: TileMark) -> some View {
        let isle = watch.isle(for: mark)
        return VStack(alignment: .leading, spacing: 0) {
            Text(isle?.moored?.title ?? isle?.drift.mooringName ?? "Isle")
                .lampInk(.body)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text("Tile \(LampFigure.count(mark.index)) · \(LampFigure.day(mark.day, calendar: .current))")
                .font(LampFace.font(.caption))
                .foregroundStyle(HarborInk.Palette.ink)
                .lineLimit(1)
        }
    }

    private func sittingCopy(_ sitting: Sitting) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(watch.volumeTitle(id: sitting.volumeID))
                .lampInk(.body)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(LampFigure.day(sitting.day, calendar: .current))
                .font(LampFace.font(.caption))
                .foregroundStyle(HarborInk.Palette.ink)
                .lineLimit(1)
        }
    }

    private func sittingFigures(_ sitting: Sitting) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(LampFigure.minutes(sitting.minutes))
                .lampInk(.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text("min · \(LampFigure.pages(sitting.pages)) pg")
                .font(LampFace.font(.caption))
                .foregroundStyle(HarborInk.Palette.ink)
                .lineLimit(1)
        }
    }

    private func markLabel(_ mark: TileMark) -> String {
        let isle = watch.isle(for: mark)
        let title = isle?.moored?.title ?? isle?.drift.mooringName ?? "Isle"
        return "\(title), tile \(LampFigure.count(mark.index)), \(LampFigure.day(mark.day, calendar: .current))"
    }

    private func sittingLabel(_ sitting: Sitting) -> String {
        "\(watch.volumeTitle(id: sitting.volumeID)), \(LampFigure.minutes(sitting.minutes)) minutes, \(LampFigure.pages(sitting.pages)) pages"
    }

    private func isle(for sitting: Sitting) -> Isle? {
        watch.board.isles.first { isle in
            isle.sittings.contains { $0.id == sitting.id }
        }
    }

    private func openIsle(_ isle: Isle?) {
        if let isle {
            watch.focus(isle.id)
        }
        watch.tab = .board
    }
}
