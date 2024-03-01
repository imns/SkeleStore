# Action Plan for SkeleStore API Design

#### 1. **Generic Model Support with Codable**

* **Objective:** Ensure any model can be serialized to JSON for storage and deserialized back into its original form.
* **Approach:** Utilize Swift's `Codable` protocol to enforce that all models conform to a serializable and deserializable structure. This provides a flexible yet strict contract for models to be stored as documents.

#### 2. **Database Initialization and Document Table Creation**

* **Objective:** Automatically set up the necessary database infrastructure (e.g., the Documents table) when the app launches.
* **Approach:** Implement an initialization process within SkeleStore that checks for the existence of the table and creates it if not found. This process should be idempotent, causing no adverse effects if called multiple times.

#### 3. **Concurrency and SQLite Handling**

* **Objective:** Ensure safe, concurrent access to SQLite database, particularly in an environment with potential multiple readers but a single writer.
* **Approach:**
  * Explore SQLite's Write-Ahead Logging (WAL) mode to support high levels of concurrency.
  * Ensure all database interactions are encapsulated within Swift's actor model to maintain thread safety.
  * Investigate SQLite's capabilities and limitations with concurrent access to decide between transactional approaches or leveraging WAL for concurrency control.

#### 4. **Indexing and Query Optimization**

* **Objective:** Enhance query performance through efficient indexing strategies, possibly without relying on VIRTUAL columns.
* **Approach:**
  * Research and implement expression indexes using `json_extract()` for critical paths in the JSON documents. This method should provide the necessary indexing without the overhead of maintaining VIRTUAL columns.
  * Design a flexible indexing strategy that allows for easy addition of indexes based on application needs, possibly through a configuration or initialization script.

#### 5. **Schema Evolution and Migrations**

* **Objective:** Address potential future needs for schema evolution, despite the schema-less design for the JSON documents.
* **Approach:**
  * While the initial design does not require traditional schema migrations, it's prudent to consider a mechanism for evolving the database setup or indexes as the application grows or changes.
  * Implement versioning for the database setup to facilitate smooth transitions and updates in the future.

#### 6. **Extensibility and Future Directions**

* **Objective:** Lay the groundwork for future extensions, such as utilizing SQLite for additional use cases like graph databases.
* **Approach:**
  * Architect the library with clear separation of concerns, abstracting SQLite interaction, JSON document handling, and model serialization into distinct layers or components.
  * Ensure the core API is minimal and extensible, allowing for additional functionality to be added without breaking changes.
