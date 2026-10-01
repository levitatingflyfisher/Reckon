import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails if any word of [finder]'s paragraph is split across two lines
/// ("de / cisions"). A word drawn on one line has every glyph box on the
/// same top edge.
void expectNoWordBroken(WidgetTester tester, Finder finder) {
  final para = tester.renderObject<RenderParagraph>(
      find.descendant(of: finder, matching: find.byType(RichText)).first);
  final text = para.text.toPlainText();
  for (final m in RegExp(r'\S+').allMatches(text)) {
    final boxes = para.getBoxesForSelection(
        TextSelection(baseOffset: m.start, extentOffset: m.end));
    final tops = boxes.map((b) => b.top.round()).toSet();
    expect(tops.length, 1,
        reason: '"${m.group(0)}" is broken across lines in "$text"');
  }
}
