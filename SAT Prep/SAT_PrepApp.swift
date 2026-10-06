// SAT_PrepApp.swift

import SwiftUI
import WebKit

@main
struct SAT_PrepApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Pre-warm WebKit helper processes (GPU, WebContent, Network) at launch
        // to eliminate the initial 2-3s delay when WebViews are first rendered.
        DispatchQueue.main.async {
            _ = WKWebView(frame: .zero)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    appState.loadVocabQuestions()  // Synchronous bundle load — instant
                    await appState.loadOpenSATQuestions()
                }
        }
    }
}
