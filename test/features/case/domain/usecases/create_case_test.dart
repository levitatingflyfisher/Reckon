import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/case/domain/repositories/case_repository.dart';
import 'package:reckon/features/case/domain/usecases/create_case.dart';

class _FakeCaseRepo implements CaseRepository {
  final List<Case> inserted = [];
  @override
  Future<void> insert(Case c) async => inserted.add(c);
  @override
  Future<Case?> getById(String id) async =>
      inserted.where((c) => c.id == id).firstOrNull;
  @override
  Future<List<Case>> getByStatus(CaseStatus s) async =>
      inserted.where((c) => c.status == s).toList();
  @override
  Future<List<Case>> getClosed() async =>
      inserted.where((c) => c.status == CaseStatus.closed).toList();
  @override
  Future<void> updateStatus(String id, CaseStatus s) async {}
  @override
  Stream<List<Case>> watchAll() => Stream.value(inserted);
  @override
  Stream<List<Case>> watchActive() => Stream.value(
      inserted.where((c) => c.status != CaseStatus.closed).toList());
  @override
  Future<void> markDecided(String id) async {}
}

void main() {
  test('CreateCase persists a new open case', () async {
    final repo = _FakeCaseRepo();
    final uc = CreateCase(repo);
    final result = await uc.call(
      question: 'Should I take the job?',
      optionA: 'Stay',
      optionB: 'Take offer',
      criteria: const [Criterion(label: 'comp', weight: 1.0)],
      stakes: Stakes.high,
      regretHorizon: RegretHorizon.years,
      deadline: DateTime(2026, 5, 1),
      now: DateTime(2026, 4, 10),
    );
    expect(repo.inserted, hasLength(1));
    expect(result.status, CaseStatus.open);
    expect(result.id, isNotEmpty);
  });
}
