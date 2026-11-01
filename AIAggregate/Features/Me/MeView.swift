import SwiftUI

struct MeView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ModelsView()
                } label: {
                    Label("API 设置", systemImage: "key.fill")
                }
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("应用设置", systemImage: "gearshape.fill")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("我的")
        }
    }
}
