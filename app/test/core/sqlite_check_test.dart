import 'package:flutter_application_1/core/sqlite_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SQLite is available where the tests run', () {
    expect(sqliteProblem(), isNull);
  });
}
