import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/domain/models/course.dart';

Course _course(String name) =>
    Course(id: 1, shortName: '115_1_0000000_01', fullName: name);

void main() {
  test('a joined English and Chinese name splits by language', () {
    final c = _course('Software Analysis and Optimization軟體分析與最佳化');
    expect(c.name(chinese: true), '軟體分析與最佳化');
    expect(c.name(chinese: false), 'Software Analysis and Optimization');
    final p = _course('Special Project (III) 專題（三）');
    expect(p.name(chinese: true), '專題（三）');
    expect(p.name(chinese: false), 'Special Project (III)');
  });

  test('a name in one language comes back whole', () {
    expect(_course('軟體分析').name(chinese: false), '軟體分析');
    expect(_course('Operating Systems').name(chinese: true), 'Operating Systems');
  });
}
