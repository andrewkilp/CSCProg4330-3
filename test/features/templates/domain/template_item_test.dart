import 'package:flutter_test/flutter_test.dart';
import 'package:csc4330prog3/features/templates/domain/template_item.dart';
import 'package:csc4330prog3/core/errors/app_exception.dart';

void main() {
  TemplateItem make() => TemplateItem(
    id: 1,
    templateId: 2,
    name: 'Socks',
    category: 'Clothes',
    quantity: 2,
  );
  test('SQLite round trip and value equality', () {
    final value = make();
    final restored = TemplateItem.fromMap(value.toMap());
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
    expect(TemplateItem.fromMap(value.toMap()), value);
  });
  test('invalid quantity fails at input boundary', () {
    expect(
      () => make().copyWith(quantity: 0).validate(),
      throwsA(isA<ValidationException>()),
    );
  });
}
