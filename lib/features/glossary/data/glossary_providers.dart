import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/glossary_entry.dart';
import '../domain/repositories/glossary_repository.dart';
import 'glossary_repository_impl.dart';

final glossaryRepositoryProvider = Provider<GlossaryRepository>((ref) {
  return GlossaryRepositoryImpl();
});

final glossaryEntriesProvider = FutureProvider<List<GlossaryEntry>>((ref) {
  return ref.watch(glossaryRepositoryProvider).all();
});

final glossaryEntryProvider =
    FutureProvider.family<GlossaryEntry?, String>((ref, id) {
  return ref.watch(glossaryRepositoryProvider).byId(id);
});
