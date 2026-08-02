import 'package:domovoi/domovoi.dart' as domovoi;
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

    test('every catalog entry passes domovoi\'s ModelTrust laws', () {
      // The fleet-wide trust laws as one validator: https on huggingface.co,
      // allowlisted org, ungated (requiresToken false), `.task` bundle. The
      // hand-rolled assertions above are kept as documentation of the scars
      // that produced each law; this is the binding check.
      for (final spec in ReckonModelSpec.availableModels) {
        final violations = domovoi.ModelTrust.check(domovoi.ModelSpec(
          id: spec.id,
          displayName: spec.displayName,
          fileName: spec.fileName,
          downloadUrl: spec.downloadUrl,
          sizeBytes: spec.approximateSizeBytes,
          modelType: spec.modelType,
          description: spec.description,
          requiresToken: spec.requiresToken,
        ));
        expect(violations, isEmpty,
            reason: '${spec.id} breaks the model trust laws');
      }
    });

    test('the default (no selection) is a MediaPipe-loadable .task on the '
        'trusted org', () {
      // Gemma 4 E2B was briefly the default, but its weight is a raw LiteRT/
      // TFLite flatbuffer (magic "TFL3"), not the ZIP bundle MediaPipe's .task
      // loader needs — flutter_gemma 0.13.2 dies with "unable to open zip
      // archive". Qwen 2.5 1.5B ships a genuine ZIP .task (ModelType.qwen), so
      // it both loads AND stays on the trusted, ungated org.
      final def = ReckonModelSpec.byId(null);
      expect(def.id, 'qwen-2.5-1.5b-it');
      expect(def.downloadUrl, contains('litert-community/Qwen2.5-1.5B'));
      expect(def.modelType, 'qwen');
      expect(def.requiresToken, isFalse);
    });

    test('an unknown id also falls back to the trusted default', () {
      expect(ReckonModelSpec.byId('no-such-model').id, 'qwen-2.5-1.5b-it');
    });

    test('no model is sourced from a LiteRT-LM repo (TFL3, not a MediaPipe zip)',
        () {
      // The `-litert-lm` orgs host raw TFLite flatbuffers that the pinned
      // flutter_gemma's MediaPipe cannot open as a .task. Guard against
      // re-adding one until the runtime is bumped to a LiteRT-LM-aware build.
      for (final spec in ReckonModelSpec.availableModels) {
        expect(spec.downloadUrl.toLowerCase(), isNot(contains('litert-lm')),
            reason: '${spec.id} points at a LiteRT-LM (TFL3) weight that '
                'MediaPipe 0.13.2 cannot load');
      }
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
