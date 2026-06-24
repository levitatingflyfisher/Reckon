import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/outside_view/domain/entities/citation.dart';
import 'package:reckon/features/outside_view/presentation/citation_list.dart';

import 'visual_golden_helper.dart';

void main() {
  testWidgets('CitationList responsive golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'citation_list',
      // Self-contained: no providers needed. Mirrors the existing widget test's
      // plain MaterialApp host, but lets the helper supply the MaterialApp.
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CitationList(
              citations: [
                Citation(
                  author: 'BLS',
                  title: 'Employee Tenure in 2024',
                  url: 'https://www.bls.gov/tenure',
                ),
                Citation(author: 'Anon', title: 'Unlinked study', url: ''),
              ],
            ),
          ),
        ),
      ),
      sizes: const <String, Size>{
        'phone': Size(360, 740),
        'narrow': Size(320, 740),
      },
      textScales: const <double>[1.0, 3.0],
    );
  });
}
