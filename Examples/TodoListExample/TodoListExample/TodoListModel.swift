//
//  TodoListModel.swift
//  TodoListExample
//
//  Created by Nate Smith on 3/3/24.
//

import Foundation
import SkeleStore

struct TodoListModel: Identifiable, Codable {
    var id = UUID()
    var name: String = ""

    func save() {
//        let doc: DocumentOf<TodoListModel>
//        doc.save(document: self)
    }
}

@Observable
class TodoListViewModel {
    //    private let todos: [TodoListModel] = []
    private let store: StoreOf<TodoListModel> = .init()

//    init() {
//
//    }

    var todos: [TodoListModel] {
        get async throws {
            await store.fetchAll()
        }
    }

    func add(model: TodoListModel) async throws {
        try await store.save(document: model)
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            //            dataManager.delete(todo: todos[index])
            //            store.delete4rytgfvc
        }
    }
}
