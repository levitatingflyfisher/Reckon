import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/entities/glossary_entry.dart';
import '../domain/repositories/glossary_repository.dart';

class GlossaryRepositoryImpl implements GlossaryRepository {
  GlossaryRepositoryImpl({String assetPath = 'assets/glossary.json'})
      : _assetPath = assetPath;

  final String _assetPath;
  List<GlossaryEntry>? _cache;

  Future<List<GlossaryEntry>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _cache = list.map(GlossaryEntry.fromJson).toList(growable: false);
    return _cache!;
  }

  @override
  Future<List<GlossaryEntry>> all() => _load();

  @override
  Future<GlossaryEntry?> byId(String id) async {
    final entries = await _load();
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }
}
