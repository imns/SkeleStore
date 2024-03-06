# Action Plan for SkeleStore API Design

## **General TODOs**

-   Add transaction support to the DocumentAdapter
-   Finish the Indexing code
-   Add filter methods to the DocumentAdapter

## **Indexing and Query Optimization**

-   **Objective:** Enhance query performance through efficient indexing strategies, possibly without relying on VIRTUAL columns.
-   **Approach:**

    -   Research and implement expression indexes using `json_extract()` for critical paths in the JSON documents. This method should provide the necessary indexing without the overhead of maintaining VIRTUAL columns.
    -   Design a flexible indexing strategy that allows for easy addition of indexes based on application needs, possibly through a configuration or initialization script.

    #### Notes

    -   This is partially stubbed out, but not implemented yet.

## **Schema Evolution and Migrations**

-   **Objective:** Address potential future needs for schema evolution, despite the schema-less design for the JSON documents.
-   **Approach:**
    -   While the initial design does not require traditional schema migrations, it's prudent to consider a mechanism for evolving the database setup or indexes as the application grows or changes.
    -   Implement versioning for the database setup to facilitate smooth transitions and updates in the future.

## **Extensibility and Future Directions**

-   **Objective:** Lay the groundwork for future extensions, such as utilizing SQLite for additional use cases like graph databases.
