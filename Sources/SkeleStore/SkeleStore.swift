import Foundation

@available(iOS 13.0, macOS 10.15, *)
public final actor Store {
    // TODO: might not want to initialize here
    public static var shared = Store()
    public var storageEngine = SQLiteEngine()

    private init() {
//        adapter = DocumentAdapter<T>(storage: Store.shared.storageEngine)
    }

    public convenience init<T>(of modelType: T) {
        self.init()
    }

    public static func of<T>(_ modelType: T) {
//        adapter = DocumentAdapter<T>(storage: Store.shared.storageEngine)
    }

    public static func create(storageType: StorageType = .file(path: "SkeleStore.sqlite")) async {
        // Ensure that `shared` is only initialized once.
//        guard shared == nil else {
//            print("Store is already initialized.")
//            return
//        }

        await shared.setup(storageType: storageType)
    }

    private func setup(storageType: StorageType) async {
        do {
            try await storageEngine.open(storage: storageType)
            try await storageEngine.setupDatabase()
        } catch {
            print("Database initialization failed: \(error)")
        }
    }
}

/// Store.documentOf<TodoList>(self.encoded)
@available(iOS 13.0, macOS 10.15, *)
public actor StoreOf<T: Codable & Identifiable> {
    private let store = Store.shared
//    private var adapter = DocumentAdapter<T>(storage: Store.shared.storageEngine)

//    init() {
//        Task {
//            self.adapter = await DocumentAdapter<T>(storage: store.storageEngine)
//        }
//    }
    public init() {}
    public func save(document: T) async throws {}
    public func fetchAll<T>() async -> [T] {
        return []
    }
}
