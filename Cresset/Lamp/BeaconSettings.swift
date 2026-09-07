import SwiftUI

/// Role: Lamp. Settings. Re-run onboarding, confirmed reset, contact URL.
struct BeaconSettings: View {
    var watch: HarborWatch
    @State private var confirmReset = false

    var body: some View {
        Group {
            if watch.isHauling {
                ProgressView()
                    .tint(HarborInk.Palette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if watch.loadFailed {
                LampVacancy(
                    image: "crs_EmptyList",
                    headline: "Settings could not be read.",
                    line: watch.fault ?? "The harbor started empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else if !watch.board.onboardingComplete {
                LampVacancy(
                    image: "crs_EmptyList",
                    headline: "Harbor not opened yet.",
                    line: "Finish the passage to keep a board, then return here.",
                    actionTitle: "Open the passage"
                ) {
                    Task { await watch.reopenOnboarding() }
                }
            } else {
                populated
            }
        }
        .background(HarborInk.Palette.background.ignoresSafeArea(edges: .top))
        .navigationTitle("Settings")
        .confirmationDialog(
            "Erase every isle, sitting, and TileMark?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                Task { await watch.resetAll() }
            }
            Button("Keep my harbor", role: .cancel) {}
        }
    }

    private var populated: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 700
            Group {
                if wide {
                    wideHarbor(width: proxy.size.width)
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    phoneList
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var phoneList: some View {
        VStack(spacing: LampFace.space(2)) {
            summary
            if let fault = watch.fault, !watch.loadFailed {
                HarborBanner(text: fault) {
                    Task { await watch.retry() }
                }
            }
            if watch.board.isles.isEmpty {
                LampChromeButton(
                    title: "Place a book",
                    detail: "Open the board and moor the first volume.",
                    fills: true,
                    emphasized: true,
                    enabled: !watch.isCommitting
                ) {
                    watch.tab = .board
                }
                .frame(maxHeight: .infinity, alignment: .top)
            } else {
                HarborWalkPlate(
                    isles: watch.board.isles,
                    showsWake: false,
                    stacked: false,
                    onOpen: openIsle
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            VStack(spacing: LampFace.space(1)) {
                rerunRow
                resetRow
                contactRow
            }
        }
        .padding(.horizontal, LampFace.space(2))
        .padding(.bottom, LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func openIsle(_ isle: Isle) {
        watch.focus(isle.id)
        watch.tab = .board
    }

    private func wideHarbor(width: CGFloat) -> some View {
        HStack(alignment: .top, spacing: LampFace.space(2)) {
            isleBoard
            toolsColumn
                .frame(width: min(420, max(300, width * 0.40)))
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var isleBoard: some View {
        VStack(alignment: .leading, spacing: LampFace.space(2)) {
            Text("Local harbor")
                .lampInk(.title)
                .lineLimit(1)
            Text("\(LampFigure.count(watch.board.isles.count)) isles · \(LampFigure.count(watch.board.tileMarkCount)) TileMarks")
                .font(LampFace.font(.callout))
                .foregroundStyle(HarborInk.Palette.ink)
                .lineLimit(2)
            if watch.board.isles.isEmpty {
                LampChromeButton(
                    title: "Place a book",
                    detail: "Open the board and moor the first volume.",
                    fills: true,
                    emphasized: true,
                    enabled: !watch.isCommitting
                ) {
                    watch.tab = .board
                }
                .frame(maxHeight: .infinity, alignment: .top)
            } else {
                VStack(spacing: LampFace.space(1)) {
                    ForEach(watch.board.isles) { isle in
                        Button {
                            openIsle(isle)
                        } label: {
                            isleRow(isle)
                        }
                        .buttonStyle(LampPressStyle(enabled: true))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel(isleLabel(isle))
                        .accessibilityHint("Opens the board on this isle.")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HarborInk.Palette.surface)
        .clipShape(LampFace.cardShape)
        .lampRaised()
    }

    private func isleRow(_ isle: Isle) -> some View {
        HStack(spacing: LampFace.space(2)) {
            VStack(alignment: .leading, spacing: 0) {
                Text(isle.moored?.title ?? isle.drift.mooringName)
                    .lampInk(.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(isle.drift.mooringName)
                    .font(LampFace.font(.caption))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text(LampFigure.pages(isle.wake.pages))
                    .lampInk(.figure)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                Text(isle.lamp == nil ? "Lamp unlit" : "Lamp lit")
                    .font(LampFace.font(.caption))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .lineLimit(1)
            }
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .frame(minHeight: LampFace.tap)
        .background(HarborInk.Palette.background)
        .clipShape(LampFace.cardShape)
        .contentShape(LampFace.cardShape)
    }

    private func isleLabel(_ isle: Isle) -> String {
        let title = isle.moored?.title ?? isle.drift.mooringName
        let lamp = isle.lamp == nil ? "lamp unlit" : "lamp lit"
        return "\(title), wake \(LampFigure.pages(isle.wake.pages)) pages, \(lamp)"
    }

    private var toolsColumn: some View {
        VStack(alignment: .leading, spacing: LampFace.space(2)) {
            HStack(spacing: LampFace.space(3)) {
                figure(LampFigure.count(watch.board.lampCount), "Lamps")
                figure(LampFigure.count(watch.sittingsNewestFirst().count), "Sittings")
            }
            .padding(LampFace.space(2))
            .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
            .background(HarborInk.Palette.background)
            .clipShape(LampFace.cardShape)
            if let fault = watch.fault, !watch.loadFailed {
                HarborBanner(text: fault) {
                    Task { await watch.retry() }
                }
            }
            LampChromeButton(
                title: "Re-run onboarding",
                fills: true,
                enabled: !watch.isCommitting,
                busy: watch.isCommitting
            ) {
                Task { await watch.reopenOnboarding() }
            }
            Button {
                confirmReset = true
            } label: {
                Text("Reset all data")
                    .font(LampFace.font(.body))
                    .foregroundStyle(HarborInk.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: LampFace.tap)
                    .background(HarborInk.Palette.background)
                    .clipShape(LampFace.cardShape)
                    .contentShape(LampFace.cardShape)
            }
            .buttonStyle(LampPressStyle(enabled: !watch.isCommitting))
            .disabled(watch.isCommitting)
            .accessibilityLabel("Reset all data")
            contactCard
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HarborInk.Palette.surface)
        .clipShape(LampFace.cardShape)
        .lampRaised()
    }

    private var contactCard: some View {
        Link(destination: BeaconClient.contactURL) {
            VStack(alignment: .leading, spacing: LampFace.space(2)) {
                Image("crs_CressetLamp")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityHidden(true)
                Text("Contact Cresset")
                    .lampInk(.title)
                    .lineLimit(1)
                Text(BeaconClient.contactURL.absoluteString)
                    .font(LampFace.font(.caption))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .lineLimit(2)
            }
            .padding(LampFace.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .frame(minHeight: LampFace.tap)
            .background(HarborInk.Palette.background)
            .clipShape(LampFace.cardShape)
            .contentShape(LampFace.cardShape)
        }
        .accessibilityLabel("Contact Cresset, \(BeaconClient.contactURL.absoluteString)")
    }

    private func figure(_ value: String, _ caption: String) -> some View {
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

    private var summary: some View {
        VStack(alignment: .leading, spacing: LampFace.space(1)) {
            HStack(spacing: LampFace.space(2)) {
                Image("crs_CressetLamp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LampFace.space(7), height: LampFace.space(7))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Local harbor")
                        .lampInk(.title)
                        .lineLimit(1)
                    Text("\(LampFigure.count(watch.board.isles.count)) isles · \(LampFigure.count(watch.board.tileMarkCount)) TileMarks")
                        .font(LampFace.font(.callout))
                        .foregroundStyle(HarborInk.Palette.ink)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: LampFace.space(3)) {
                figure(LampFigure.count(watch.board.lampCount), "Lamps")
                figure(LampFigure.count(watch.sittingsNewestFirst().count), "Sittings")
                figure(LampFigure.pages(watch.board.isles.reduce(0) { $0 + $1.wake.pages }), "Wake")
            }
        }
        .padding(LampFace.space(2))
        .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
        .background(HarborInk.Palette.surface)
        .clipShape(LampFace.cardShape)
        .lampRaised()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Local harbor, \(LampFigure.count(watch.board.isles.count)) isles, \(LampFigure.count(watch.board.tileMarkCount)) TileMarks, \(LampFigure.count(watch.board.lampCount)) lamps, \(LampFigure.count(watch.sittingsNewestFirst().count)) sittings"
        )
    }

    private var rerunRow: some View {
        Button {
            Task { await watch.reopenOnboarding() }
        } label: {
            Label("Re-run onboarding", systemImage: "arrow.counterclockwise")
                .lampInk(.body)
                .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
                .padding(.horizontal, LampFace.space(2))
                .background(HarborInk.Palette.surface)
                .clipShape(LampFace.cardShape)
                .contentShape(LampFace.cardShape)
        }
        .buttonStyle(LampPressStyle(enabled: !watch.isCommitting))
        .disabled(watch.isCommitting)
    }

    private var resetRow: some View {
        Button {
            confirmReset = true
        } label: {
            Label("Reset all data", systemImage: "trash")
                .font(LampFace.font(.body))
                .foregroundStyle(HarborInk.Palette.accent)
                .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
                .padding(.horizontal, LampFace.space(2))
                .background(HarborInk.Palette.surface)
                .clipShape(LampFace.cardShape)
                .contentShape(LampFace.cardShape)
        }
        .buttonStyle(LampPressStyle(enabled: !watch.isCommitting))
        .disabled(watch.isCommitting)
        .accessibilityLabel("Reset all data")
    }

    private var contactRow: some View {
        Link(destination: BeaconClient.contactURL) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Contact Cresset")
                    .lampInk(.body)
                Text(BeaconClient.contactURL.absoluteString)
                    .font(LampFace.font(.caption))
                    .foregroundStyle(HarborInk.Palette.ink)
                    .lineLimit(2)
            }
            .padding(.horizontal, LampFace.space(2))
            .frame(maxWidth: .infinity, minHeight: LampFace.tap, alignment: .leading)
            .background(HarborInk.Palette.surface)
            .clipShape(LampFace.cardShape)
            .contentShape(LampFace.cardShape)
        }
        .accessibilityLabel("Contact Cresset, \(BeaconClient.contactURL.absoluteString)")
    }
}
