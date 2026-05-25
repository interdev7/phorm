// Tests for the BelongsTo FK getter pattern emitted by the code generator.
//
// The generator now emits:
//   dynamic get userId => user?.toJson()['id'] ?? _$userId;
//
// instead of the old hardcoded:
//   dynamic get userId => user?.id ?? _$userId;
//
// This file validates that the pattern works correctly at runtime, covering:
//  1. FK is read from the related object via toJson() when the object is loaded.
//  2. FK falls back to the stored raw value when the related object is null.
//  3. FK is correct for models where the PK SQL name differs from the Dart field name.
//  4. Setting the raw FK value works independently of the related object.

import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

// ---------------------------------------------------------------------------
// Minimal model stubs — these replicate what the generator would emit.
// ---------------------------------------------------------------------------

// --- Author (related model, PK = 'id' in SQL, 'id' in Dart) ---
class Author extends Model {
  final String id;
  final String name;

  Author({required this.id, required this.name});

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

// --- Article (owning side, BelongsTo Author via author_id) ---
// Simulates the generated mixin pattern where:
//   dynamic get authorId => author?.toJson()['id'] ?? _$authorId;
class Article extends Model {
  final int id;
  final String title;

  // Stored raw FK (set when author object is not loaded)
  dynamic _$authorId;

  // Related object (set after eager loading)
  Author? _$author;
  Author? get author => _$author;

  // Generated FK getter — uses toJson()['id'] instead of .id
  dynamic get authorId => author?.toJson()['id'] ?? _$authorId;
  set authorId(dynamic value) => _$authorId = value;

  Article({required this.id, required this.title});

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author_id': authorId,
      };
}

// ---------------------------------------------------------------------------
// Model with a CUSTOM PK SQL name:
//   PK Dart field = 'uid', PK SQL name = 'user_uid'
// Simulates @ID with columnName: 'user_uid'
// ---------------------------------------------------------------------------

class CustomPkUser extends Model {
  // Simulates @ID(columnName: 'user_uid')
  final String uid;
  final String email;

  CustomPkUser({required this.uid, required this.email});

  @override
  Map<String, dynamic> toJson() => {
        'user_uid': uid, // SQL name is 'user_uid'
        'email': email,
      };
}

// --- Comment (BelongsTo CustomPkUser via 'user_uid' FK) ---
// Generator resolves @ID on CustomPkUser → sqlName = 'user_uid'
// So it emits: dynamic get customPkUserId => customPkUser?.toJson()['user_uid'] ?? _$customPkUserId;
class Comment extends Model {
  final int id;
  final String body;

  dynamic _$customPkUserId;
  CustomPkUser? _$customPkUser;
  CustomPkUser? get customPkUser => _$customPkUser;

  // Getter uses the resolved SQL PK name 'user_uid' — not hardcoded 'uid' or 'id'
  dynamic get customPkUserId =>
      customPkUser?.toJson()['user_uid'] ?? _$customPkUserId;
  set customPkUserId(dynamic value) => _$customPkUserId = value;

  Comment({required this.id, required this.body});

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'user_uid': customPkUserId,
      };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BelongsTo FK getter — standard PK (id → id)', () {
    test('returns FK from related object toJson() when object is loaded', () {
      final author = Author(id: 'author-42', name: 'Tolstoy');
      final article = Article(id: 1, title: 'War and Peace')

        // Simulate eager loading (what fromJson cascade does)
        .._$author = author;

      // FK getter should read from author.toJson()['id'], not author.id directly
      expect(article.authorId, equals('author-42'));
    });

    test('falls back to raw stored value when related object is null', () {
      final article = Article(id: 2, title: 'Anna Karenina')

        // No eager-loaded object — FK was set from raw JSON
        ..authorId = 'author-99';

      expect(article.authorId, equals('author-99'));
    });

    test('loaded object takes priority over raw stored value', () {
      final author = Author(id: 'author-10', name: 'Chekhov');
      final article = Article(id: 3, title: 'The Cherry Orchard')

        // First set raw value
        ..authorId = 'author-OLD'
        // Then load the related object — getter should prefer toJson()
        .._$author = author;

      expect(article.authorId, equals('author-10'),
          reason:
              r'loaded object toJson() must take priority over raw _$field');
    });

    test('toJson() on owning model includes correct FK value', () {
      final author = Author(id: 'author-7', name: 'Dostoevsky');
      final article = Article(id: 4, title: 'Crime and Punishment')
        .._$author = author;

      final json = article.toJson();
      expect(json['author_id'], equals('author-7'));
    });

    test('FK is null when both related object and raw value are absent', () {
      final article = Article(id: 5, title: 'No author yet');
      // Neither _$author nor _$authorId set
      expect(article.authorId, isNull);
    });
  });

  group('BelongsTo FK getter — custom PK SQL name (uid → user_uid)', () {
    test('resolves FK using the correct SQL PK column name from toJson()', () {
      final user = CustomPkUser(uid: 'uid-abc', email: 'test@example.com');
      final comment = Comment(id: 1, body: 'Great post!')
        .._$customPkUser = user;

      // toJson() of CustomPkUser maps 'uid' Dart field → 'user_uid' SQL key
      // The getter must read toJson()['user_uid'], not toJson()['uid'] or .id
      expect(comment.customPkUserId, equals('uid-abc'));
    });

    test('falls back to raw stored FK when related object is null', () {
      final comment = Comment(id: 2, body: 'Hello world')
        ..customPkUserId = 'uid-fallback';

      expect(comment.customPkUserId, equals('uid-fallback'));
    });

    test('toJson() on Comment includes correct custom PK FK value', () {
      final user = CustomPkUser(uid: 'uid-xyz', email: 'x@y.com');
      final comment = Comment(id: 3, body: 'Interesting!')
        .._$customPkUser = user;

      final json = comment.toJson();
      expect(json['user_uid'], equals('uid-xyz'));
    });
  });

  group('BelongsTo FK setter', () {
    test('set FK persists and is readable when no object loaded', () {
      final article = Article(id: 10, title: 'Draft')
        ..authorId = 'new-author-id';

      expect(article.authorId, equals('new-author-id'));
    });

    test('set FK does not affect loaded related object reference', () {
      final author = Author(id: 'original', name: 'Original');
      final article = Article(id: 11, title: 'Test')
        .._$author = author

        // Setting raw FK does not clear the object — getter still prefers object
        ..authorId = 'overridden';

      // Because _$author is still set, getter returns from toJson()
      expect(article.authorId, equals('original'),
          reason: 'toJson() from loaded object must still win over raw setter');
    });
  });
}
