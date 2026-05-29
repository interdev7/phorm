import '../phorm_annotations.dart';

/// Interface for model factories.
/// Used to generate mock data for testing or seeding.
abstract class Factory<T extends Model> {
  /// Generates a single model instance with random or predefined data.
  T create();

  /// Generates a list of model instances.
  List<T> createMany(int count) {
    return List.generate(count, (_) => create());
  }
}
