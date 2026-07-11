import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/connection/connection.dart';

void main() {
  // The platform-selected [openConnection] is the seam that keeps `dart:io`
  // out of the web build. On the test VM it resolves to the native variant;
  // the web variant is compile-verified by `flutter build web`. Constructing
  // it must not touch the filesystem (the real open is deferred inside a
  // LazyDatabase), so this is safe to run without platform-channel plugins.
  test('openConnection() returns a lazily-opened QueryExecutor', () {
    final executor = openConnection();
    expect(executor, isA<QueryExecutor>());
    expect(executor, isA<LazyDatabase>());
  });
}
