import 'package:flutter_test/flutter_test.dart';
import 'package:csc4330prog3/features/templates/domain/packing_template.dart';
import 'package:csc4330prog3/core/errors/app_exception.dart';

void main() {
  final date = DateTime.utc(2026, 9, 16);
  PackingTemplate make() =>
      PackingTemplate(id: 1, name: 'Weekend', createdAt: date);
  test('SQLite round trip and value equality', () {
    final value = make();
    final restored = PackingTemplate.fromMap(value.toMap());
    expect(restored, value);
    expect(restored.hashCode, value.hashCode);
    expect(value.copyWith(), value);
    expect(value.copyWith(name: 'Changed').name, 'Changed');
    expect(value.copyWith(name: 'Changed'), isNot(value));
    expect(value.copyWith(id: null).id, isNull);
  });
  test('blank names validate at input boundary only', () {
    final value = make().copyWith(name: '  ');
    expect(() => value.validate(), throwsA(isA<ValidationException>()));
    expect(PackingTemplate.fromMap(value.toMap()), value);
  });
}
