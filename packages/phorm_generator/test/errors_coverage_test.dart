import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'gen_common.dart';

void main() {
  test('@Schema on a non-class throws InvalidGenerationSourceError', () async {
    await expectLater(
      generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'x')
enum NotAClass { a, b }
'''),
      throwsA(isA<InvalidGenerationSourceError>()),
    );
  });

  test('class with no columns throws', () async {
    await expectLater(
      generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'empty', timestamps: false)
class Empty {
  final int notAColumn;
  const Empty(this.notAColumn);
}
'''),
      throwsA(isA<InvalidGenerationSourceError>()),
    );
  });

  test('relationship model that is neither String nor Type throws', () async {
    await expectLater(
      generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(
  tableName: 'bad',
  relationships: [BelongsTo(model: 123, foreignKey: 'x_id')],
)
class Bad {
  @ID()
  final int id;
  const Bad(this.id);
}
'''),
      throwsA(isA<InvalidGenerationSourceError>()),
    );
  });

  test('timestamps-only class (no @Column fields) still generates', () async {
    final out = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'ts_only')
class TsOnly {
  @ID()
  final String id;
  const TsOnly(this.id);
}
''');
    expect(out, contains('created_at'));
  });
}
