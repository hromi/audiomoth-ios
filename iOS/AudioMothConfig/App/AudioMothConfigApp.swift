import SwiftUI

@main
struct AudioMothConfigApp: App {

    @State private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .onAppear { viewModel.startMonitoring() }
                .onDisappear { viewModel.stopMonitoring() }
        }
    }
}
