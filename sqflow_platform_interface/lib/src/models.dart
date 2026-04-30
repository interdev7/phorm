/// MODELS 🏗️
///
/// Base model interface for CRUD operations.
/// All models must implement this to work with [SqflowCore].
///
/// **Requirements:**
/// - `id`: Unique identifier (String, int, or Object).
/// - Timestamps: Optional getters for `createdAt`, `updatedAt`, `deletedAt` (for soft delete).
/// - `toJson()`: Serializes to Map<String, dynamic> for database insertion.
/// Base class for all database models.
///
/// Models must provide:
/// - `id`: Unique identifier (String, int, or Object).
/// - Timestamps: Optional getters for `createdAt`, `updatedAt`, `deletedAt` (for soft delete).
/// - `toJson()`: Serializes to Map<String, dynamic> for database insertion.
class Model {
  /// Unique identifier for the model instance.
  Object get id => '';

  /// Serializes the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {};
  }
}
