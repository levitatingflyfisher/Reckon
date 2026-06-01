import '../entities/glossary_entry.dart';

abstract class GlossaryRepository {
  Future<List<GlossaryEntry>> all();
  Future<GlossaryEntry?> byId(String id);
}
