//
//  ContentView.swift
//  TodoListExample
//
//  Created by Nate Smith on 3/3/24.
//

import SkeleStore
import SwiftUI

struct ContentView: View {
    let store: Store
    let todoListViewModel = TodoListViewModel(store: store)
    
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView(store: Store.shared)
}
