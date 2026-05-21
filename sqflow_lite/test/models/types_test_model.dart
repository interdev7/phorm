import 'package:sqflow_core/sqflow_core.dart';
import 'package:sqflow_lite/sqflow_lite.dart';

part 'types_test_model.sql.g.dart';

late DB appDb;

// ───────────────────────────────────────────────────────────
// Model 1: Extended scalar types (BigInt, Uri, Duration)
// ───────────────────────────────────────────────────────────
@Schema(tableName: 'scalar_items', timestamps: false)
class ScalarItem with _$SQFlowScalarItemMixin implements Model {
  @ID()
  final int id;

  @Column()
  final BigInt bigValue;

  @Column()
  final Uri website;

  @Column()
  final Duration timeout;

  @Column()
  final BigInt? optionalBig;

  @Column()
  final Uri? optionalUri;

  @Column()
  final Duration? optionalDuration;

  ScalarItem({
    required this.id,
    required this.bigValue,
    required this.website,
    required this.timeout,
    this.optionalBig,
    this.optionalUri,
    this.optionalDuration,
  });

  factory ScalarItem.fromJson(Map<String, dynamic> json) =>
      _$SQFlowScalarItemFromJson(json);
}

// ───────────────────────────────────────────────────────────
// Model 2: Collection fields (List, Set, Map stored as JSON)
// ───────────────────────────────────────────────────────────
@Schema(tableName: 'collection_items', timestamps: false)
class CollectionItem with _$SQFlowCollectionItemMixin implements Model {
  @ID()
  final int id;

  @Column()
  final List<String> tags;

  @Column()
  final Set<int> scores;

  @Column()
  final Map<String, int> metadata;

  CollectionItem({
    required this.id,
    required this.tags,
    required this.scores,
    required this.metadata,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) =>
      _$SQFlowCollectionItemFromJson(json);
}

// ───────────────────────────────────────────────────────────
// Model 3: Generic class
// ───────────────────────────────────────────────────────────
@Schema(tableName: 'api_responses', timestamps: false)
class ApiResponse<T> with _$SQFlowApiResponseMixin<T> implements Model {
  @ID()
  final int id;

  @Column()
  final String status;

  /// Generic payload — not a DB column, populated from JSON
  final T? data;

  ApiResponse({
    required this.id,
    required this.status,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$SQFlowApiResponseFromJson(json, fromJsonT);
}
