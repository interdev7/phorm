import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';

import 'models/types_test_model.dart';

// Simple DTO class to test generic nested object serialization
class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) =>
      Location(lat: json['lat'] as double, lng: json['lng'] as double);

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;
}

void main() {
  late DB db;

  setUp(() async {
    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [scalar_itemsTable, collection_itemsTable, api_responsesTable],
    );
    appDb = db;
    await db.database; // Trigger tables creation
  });

  tearDown(() async {
    await db.close();
  });

  group('Extended Scalar Types (BigInt, Uri, Duration)', () {
    test('should correctly serialize and deserialize extended types', () async {
      final item = ScalarItem(
        id: 1,
        bigValue: BigInt.parse('123456789012345678901234567890'),
        website: Uri.parse('https://phorm.dev/orm'),
        timeout: const Duration(minutes: 5),
        optionalBig: BigInt.two,
      );

      // Verify toJson
      final json = item.toJson();
      expect(json['big_value'], '123456789012345678901234567890');
      expect(json['website'], 'https://phorm.dev/orm');
      expect(json['timeout'], 5 * 60 * 1000000); // 5 minutes in microseconds
      expect(json['optional_big'], '2');
      expect(json['optional_uri'], null);

      // Insert to DB using pluralized service
      await ScalarItems.insert(item);

      // Read from DB and check fromJson
      final retrieved = await ScalarItems.readOne(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 1);
      expect(
        retrieved.bigValue,
        BigInt.parse('123456789012345678901234567890'),
      );
      expect(retrieved.website.host, 'phorm.dev');
      expect(retrieved.timeout.inMinutes, 5);
      expect(retrieved.optionalBig, BigInt.two);
      expect(retrieved.optionalUri, null);

      // Verify manual deserialization via helper function
      final dbRawRow = {
        'id': 2,
        'big_value': '999999999999999999999999999999',
        'website': 'https://google.com',
        'timeout': 10000000, // 10s
        'optional_big': null,
        'optional_uri': 'https://github.com',
      };
      final manualDeserialized = ScalarItem.fromJson(dbRawRow);
      expect(manualDeserialized.id, 2);
      expect(
        manualDeserialized.bigValue,
        BigInt.parse('999999999999999999999999999999'),
      );
      expect(manualDeserialized.website.host, 'google.com');
      expect(manualDeserialized.timeout.inSeconds, 10);
      expect(manualDeserialized.optionalBig, null);
      expect(manualDeserialized.optionalUri?.host, 'github.com');
    });
  });

  group('Collections (List, Set, Map)', () {
    test(
      'should serialize collections to JSON strings in DB and deserialize them back',
      () async {
        final item = CollectionItem(
          id: 42,
          tags: ['dart', 'orm', 'sqlite'],
          scores: {10, 20, 30},
          metadata: {'version': 1, 'active': 1},
        );

        // Insert to DB
        await CollectionItems.insert(item);

        // Raw query to check SQLite storage format (should be JSON strings!)
        final rawRows = await db.database.then(
          (sqliteDb) => sqliteDb.query('collection_items'),
        );
        expect(rawRows.length, 1);
        final dbRow = rawRows.first;

        expect(dbRow['tags'], '["dart","orm","sqlite"]');
        expect(dbRow['scores'], '[10,20,30]');
        expect(dbRow['metadata'], '{"version":1,"active":1}');

        // Deserialization should automatically decode from JSON strings
        final retrieved = await CollectionItems.readOne(42);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, 42);
        expect(retrieved.tags, ['dart', 'orm', 'sqlite']);
        expect(retrieved.scores, {10, 20, 30});
        expect(retrieved.metadata, {'version': 1, 'active': 1});

        // Verify manual deserialization via helper function
        final manualDeserialized = CollectionItem.fromJson(dbRow);
        expect(manualDeserialized.id, 42);
        expect(manualDeserialized.tags, ['dart', 'orm', 'sqlite']);
        expect(manualDeserialized.scores, {10, 20, 30});
        expect(manualDeserialized.metadata, {'version': 1, 'active': 1});
      },
    );
  });

  group('Generics support', () {
    test(
      'should correctly handle generic payload serialization and deserialization',
      () async {
        final response = ApiResponse<Location>(
          id: 100,
          status: 'success',
          data: Location(lat: 55.7558, lng: 37.6173),
        );

        // Verify toJson with generic serialization helper
        final json = response.toJson((loc) => loc.toJson());
        expect(json['status'], 'success');
        expect(json['data'], '{"lat":55.7558,"lng":37.6173}');

        // Insert to DB (payload "data" is non-column field, so it will be ignored by SQLite schema)
        await ApiResponses.insert(response);

        // Verify DB storage structure (data column should not exist in schema)
        final rawRows = await db.database.then(
          (sqliteDb) => sqliteDb.query('api_responses'),
        );
        expect(rawRows.length, 1);
        expect(
          rawRows.first.containsKey('data'),
          isFalse,
        ); // Non-column field is filtered out!

        // Simulate a raw server/payload response
        final serverJson = {
          'id': 100,
          'status': 'success',
          'data': {'lat': 55.7558, 'lng': 37.6173},
        };

        // Deserialization with generic deserialization helper
        final deserialized = ApiResponse.fromJson(
          serverJson,
          (dataJson) => Location.fromJson(dataJson as Map<String, dynamic>),
        );

        expect(deserialized.id, 100);
        expect(deserialized.status, 'success');
        expect(deserialized.data, Location(lat: 55.7558, lng: 37.6173));
      },
    );

    test(
      'should insert and read generic payload without conflicts with SQLite',
      () async {
        final serverJson = {
          'id': 200,
          'status': 'error',
          'data': {'lat': 40.7128, 'lng': -74.0060},
        };

        // 1. Deserialize from server payload containing raw nested object
        final deserialized = ApiResponse.fromJson(
          serverJson,
          (dataJson) => Location.fromJson(dataJson as Map<String, dynamic>),
        );

        // 2. Insert into SQLite database (non-column field 'data' will be automatically filtered out)
        await ApiResponses.insert(deserialized);

        // 3. Retrieve from SQLite (should not throw and should load matching columns)
        final retrieved = await ApiResponses.readOne(200);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, 200);
        expect(retrieved.status, 'error');
        expect(
          retrieved.data,
          null,
        ); // SQLite does not store non-column 'data' payload
      },
    );
  });
}
