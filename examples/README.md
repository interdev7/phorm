# PHORM Showcase

A comprehensive example application demonstrating the features and capabilities of the `phorm` ORM for Flutter.

## Features

This application includes several separate showcases, accessible via a bottom navigation bar:

1. **Validation Demo (`ValidationDemoPage`)**
   Demonstrates how `phorm` handles model validation, error reporting, and type safety when inserting or updating records.

2. **Social Feed (`SocialFeedPage`)**
   Shows a real-world use case of relational data, including fetching posts with their associated users or categories.

3. **Reactive Todos (`ReactiveTodoPage`)**
   Highlights the reactivity of `phorm`. The UI automatically updates when changes are made to the underlying database tables using streams.

## Getting Started

To run this example project, ensure you have the `phorm` and `phorm_generator` packages correctly set up in the parent directory, as they are referenced via relative paths.

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Generate ORM models (if they are not already generated):

   ```bash
   dart run build_runner build -d
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Testing

The project includes widget tests that use an in-memory `sqlite3` database to verify that the app's navigation and basic UI structure work properly without requiring a physical device or emulator.

To run the tests:

```bash
flutter test
```
