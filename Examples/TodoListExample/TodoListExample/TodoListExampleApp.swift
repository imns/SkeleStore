//
//  TodoListExampleApp.swift
//  TodoListExample
//
//  Created by Nate Smith on 3/3/24.
//

import SkeleStore
import SwiftUI

@main
struct TodoListExampleApp: App {
    init() {
        Task {
            await Store.create()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: Store.shared)
        }
    }
}
