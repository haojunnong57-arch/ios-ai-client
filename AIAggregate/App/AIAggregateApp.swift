import SwiftUI

@main
struct AIAggregateApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
        }
    }
}
