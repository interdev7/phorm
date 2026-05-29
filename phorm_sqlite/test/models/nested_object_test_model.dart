import 'package:phorm_sqlite/phorm_sqlite.dart';

part 'nested_object_test_model.sql.g.dart';

late DB appDb;

class Location {
  final double lat;
  final double lng;

  const Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat'] as double,
      lng: json['lng'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

@Schema(tableName: 'users_with_location', timestamps: false)
class UserWithLocation with _$PhormUserWithLocationMixin implements Model {
  @ID()
  final int id;

  @Column()
  final String name;

  // This is NOT a column, but should be serialized/deserialized
  final Location? location;

  // Another non-column basic field
  final int? age;

  UserWithLocation({
    required this.id,
    required this.name,
    this.location,
    this.age,
  });
}
