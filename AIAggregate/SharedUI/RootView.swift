import SwiftUI

enum RootTab: String, CaseIterable, Identifiable {
    case chat, history, me, search
    var id: String { rawValue }

    var title: String {
        switch self {
        case .chat: return "对话"
        case .history: return "历史"
        case .me: return "我的"
        case .search: return "搜索"
        }
    }

    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .history: return "clock.fill"
        case .me: return "person.fill"
        case .search: return "magnifyingglass"
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var settings: AppSettings
    @State private var activeTab: RootTab = .chat
    @State private var currentSessionID: UUID?

    var body: some View {
        Group {
            switch activeTab {
            case .chat:
                ChatContainerView(
                    sessionID: $currentSessionID,
                    onGoModels: { activeTab = .me }
                )
            case .history:
                HistoryView(sessionID: $currentSessionID, onSelectChat: {
                    activeTab = .chat
                })
            case .me:
                MeView()
            case .search:
                SearchHomeView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 正确做法：用 safeAreaInset 预留底部空间，避免输入框与导航栏重叠
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LiquidGlassTabBar(activeTab: $activeTab)
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 6)
        }
        .preferredColorScheme(settings.resolvedColorScheme)
    }
}

struct LiquidGlassTabBar: View {
    @Binding var activeTab: RootTab
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        activeTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(activeTab == tab ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if activeTab == tab {
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
                                .matchedGeometryEffect(id: "pill", in: ns)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background {
            Capsule()
                .fill(.regularMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.08),
                                    Color.primary.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
        }
        .accessibilityElement(children: .contain)
    }
}
