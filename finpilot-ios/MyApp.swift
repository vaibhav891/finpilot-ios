//
//  MyApp.swift
//  FinPilot
//

import SwiftUI
import SwiftData

@main
struct MyApp: App {
    private let stack = SwiftDataStack.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(stack.container)
    }
}
