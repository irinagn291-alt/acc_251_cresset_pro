import SwiftUI

/// Role: Isle. Host. Passage first; then Board-tab chrome. Views never touch the store.
struct ContentView: View {
    var watch: HarborWatch
    @Environment(\.scenePhase) private var scenePhase

    init(watch: HarborWatch) {
        self.watch = watch
    }

    init() {
        self.watch = .previewPopulated()
    }

    var body: some View {
        Group {
            if watch.board.onboardingComplete {
                ArchipelagoTabs(watch: watch)
            } else {
                LampPassage(watch: watch)
            }
        }
        .tint(HarborInk.Palette.accent)
        .preferredColorScheme(.light)
        .background(HarborInk.Palette.background.ignoresSafeArea())
        .task {
            await watch.appear()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                Task { await watch.flush() }
            }
            if phase == .active {
                watch.markDay()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            watch.markDay()
        }
    }
}

#Preview {
    ContentView()
}
