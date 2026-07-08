import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/model_spec.dart';

void main() {
  test('trusted litert-community models are ungated (no HF token needed)', () {
    // Verified empirically: an unauthenticated resolve of these URLs returns
    // 302 (redirect to CDN), i.e. no token is required. They were previously
    // mis-flagged requiresToken:true, which put a needless token wall in front
    // of the TRUSTED models while the untrusted personal mirror was tokenless.
    expect(ReckonModelSpec.qwen25_1_5b.requiresToken, isFalse);
    expect(ReckonModelSpec.phi4Mini.requiresToken, isFalse);
    expect(ReckonModelSpec.qwen25_1_5b.downloadUrl, contains('litert-community/'));
    expect(ReckonModelSpec.phi4Mini.downloadUrl, contains('litert-community/'));
  });

  group('trusted-source catalog invariant', () {
    // The point of the catalog: no model may come from an untrusted or
    // token-gated source. Gemma 3 has no ungated build on a trusted org, so it
    // used to be pulled from a personal HF mirror (MiCkSoftware) — exactly the
    // supply-chain risk this invariant now forbids. Gemma *4* E2B, by contrast,
    // is ungated on Google's own litert-community org, so it can be the default
    // with neither a personal mirror nor a token wall.
    test('every available model is on the trusted litert-community org, ungated',
        () {
      for (final spec in ReckonModelSpec.availableModels) {
        expect(spec.downloadUrl, contains('huggingface.co/litert-community/'),
            reason: '${spec.id} must be sourced from the trusted LiteRT org, '
                'never a personal mirror');
        expect(spec.requiresToken, isFalse,
            reason: '${spec.id} must be ungated — Ghost mode takes no account');
      }
    });

    test('the default (no selection) is Google Gemma 4 E2B from the trusted org',
        () {
      final def = ReckonModelSpec.byId(null);
      expect(def.id, 'gemma-4-e2b-it');
      expect(def.downloadUrl, contains('litert-community/gemma-4-E2B'));
      expect(def.requiresToken, isFalse);
    });

    test('an unknown id also falls back to the trusted default', () {
      expect(ReckonModelSpec.byId('no-such-model').id, 'gemma-4-e2b-it');
    });

    test('a small (<800MB) trusted option exists for storage-limited phones',
        () {
      final light = ReckonModelSpec.availableModels
          .where((s) => s.approximateSizeBytes < 800 * 1000 * 1000)
          .toList();
      expect(light, isNotEmpty,
          reason: 'low-end devices need a small ungated model, filling the '
              'niche the retired 555MB Gemma 3 1B used to occupy');
    });

    test('the retired personal-mirror Gemma 3 spec is gone', () {
      // Guard against anyone re-adding a personal-mirror entry.
      for (final spec in ReckonModelSpec.availableModels) {
        expect(spec.downloadUrl.toLowerCase(), isNot(contains('micksoftware')));
        expect(spec.id, isNot('gemma-3-1b-it'));
      }
    });
  });
}
