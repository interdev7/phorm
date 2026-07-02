import 'package:test/test.dart';

import 'gen_common.dart';

void main() {
  test(
    'SqlFunc functions generate sqlite registrations + extensions',
    () async {
      final out = await generateFunctions('''
import 'package:phorm_annotations/phorm_annotations.dart';

@SqlFunc(name: 'SLUGIFY')
String slugify(String input) => input;

@SqlFunc()
int wordCount(String? text) => 0;

@SqlFunc()
void noop() {}
''');
      expect(out, contains('customSqlFunctions'));
      expect(out, contains("SqlFunction.custom"));
      expect(out, contains("name: 'SLUGIFY'"));
      // Default name = uppercased dart name.
      expect(out, contains("name: 'WORDCOUNT'"));
      // Nullable param preserved.
      expect(out, contains('String?'));
      // void return maps to dynamic.
      expect(out, contains('PhormColumn<dynamic>'));
      // Extension for the first function.
      expect(out, contains('PhormColumnExtension'));
    },
  );

  test('no SqlFunc annotations yields empty output', () async {
    final out = await generateFunctions('''
import 'package:phorm_annotations/phorm_annotations.dart';

int plain(int x) => x;
''');
    expect(out, isEmpty);
  });
}
