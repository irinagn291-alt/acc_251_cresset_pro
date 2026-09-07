import SwiftUI
import UIKit

/// Role: Isle. Board-tab chrome. Place and sitting fuse on Board. Analytics and Settings are siblings.
/// The dock sits on the home indicator; surface fill covers the home-indicator band.
struct ArchipelagoTabs: View {
    var watch: HarborWatch

    var body: some View {
        pane
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HarborDock(tab: tabBinding)
            }
            .background(HarborInk.Palette.background.ignoresSafeArea(edges: .top))
            .tint(HarborInk.Palette.accent)
            .onAppear {
                HarborScreen.paintWindows()
            }
    }

    private var pane: some View {
        ZStack {
            tabPage(.board) {
                BoardHarbor(watch: watch)
            }
            tabPage(.analytics) {
                MarksAnalytics(watch: watch)
            }
            tabPage(.settings) {
                BeaconSettings(watch: watch)
            }
        }
    }

    private func tabPage<Content: View>(
        _ item: HarborTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            content()
        }
        .opacity(watch.tab == item ? 1 : 0)
        .allowsHitTesting(watch.tab == item)
        .accessibilityHidden(watch.tab != item)
    }

    private var tabBinding: Binding<HarborTab> {
        Binding(
            get: { watch.tab },
            set: { watch.tab = $0 }
        )
    }
}

/// Role: Isle. Grounded tab dock. Surface fill extends through the home-indicator band.
private struct HarborDock: View {
    @Binding var tab: HarborTab

    var body: some View {
        HStack(spacing: LampFace.space(1)) {
            dockItem(.board, title: "Board", symbol: "map")
            dockItem(.analytics, title: "Analytics", symbol: "chart.bar")
            dockItem(.settings, title: "Settings", symbol: "gearshape")
        }
        .padding(.horizontal, LampFace.space(1))
        .padding(.top, LampFace.space(1))
        .padding(.bottom, LampFace.space(1))
        .frame(maxWidth: .infinity)
        .background {
            HarborInk.Palette.surface
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(HarborInk.Palette.ink.opacity(0.12))
                .frame(height: 1)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Harbor tabs")
    }

    private func dockItem(_ item: HarborTab, title: String, symbol: String) -> some View {
        let selected = tab == item
        return Button {
            tab = item
        } label: {
            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(LampFace.font(.body).weight(.semibold))
                    .symbolVariant(selected ? .fill : .none)
                Text(title)
                    .font(LampFace.font(.caption).weight(selected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? HarborInk.Palette.accent : HarborInk.Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: LampFace.tap)
            .padding(.vertical, LampFace.space(1))
            .background(selected ? HarborInk.Palette.accent.opacity(0.16) : Color.clear)
            .clipShape(LampFace.chipShape)
            .contentShape(Rectangle())
        }
        .buttonStyle(LampPressStyle(enabled: true))
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

/// Role: Isle. Window plate matches the dock so the home-indicator band is never cream or system white.
@MainActor
enum HarborScreen {
    static let fill = UIColor(red: 254 / 255, green: 254 / 255, blue: 253 / 255, alpha: 1)

    static func paintWindows() {
        let color = UIColor(named: "surface") ?? fill
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.backgroundColor = color
                window.rootViewController?.view.backgroundColor = color
            }
        }
    }
}
