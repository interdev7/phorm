/// MODELS 🏗️
///
/// Base model interface for CRUD operations.
/// All models must implement this to work with [PhormCore].
///
/// **Requirements:**
/// - `toJson()`: Serializes to `Map<String, dynamic>` for database insertion.
class Model {
  /// Serializes the model to a JSON map.
  Map<String, dynamic> toJson() => {};
}
