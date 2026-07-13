import 'sql_type.dart';

/// PostgreSQL-specific SQL types.
///
/// Cross-dialect types (VARCHAR, TEXT, JSON, ...) live in `common_types.dart`.

/// JSONB binary JSON type (PostgreSQL).
class JSONB extends SqlType {
  /// Creates a JSONB type marker.
  const JSONB();
}

// TODO(postgres): add BYTEA, UUID, SERIAL/BIGSERIAL, ARRAY, and other
// Postgres-only types as they become supported by the generator.
