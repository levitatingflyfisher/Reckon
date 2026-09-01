import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/llm_service_builder.dart' as selected;
import 'package:reckon/core/llm/llm_service_builder_native.dart' as native;
import 'package:reckon/core/llm/llm_service_builder_web.dart' as web;

/// The one capability seam for "can this build run an on-device model?". It
/// lives beside the platform-selected LLM builder so the answer and the
/// builder can never disagree: the variant that throws AiUnavailableOnWeb is
/// the variant that says false.
void main() {
  test('the web builder variant reports no on-device model runtime', () {
    expect(web.hasOnDeviceModelRuntime, isFalse);
  });

  test('the native builder variant reports an on-device model runtime', () {
    expect(native.hasOnDeviceModelRuntime, isTrue);
  });

  test('the conditionally exported builder picks the native answer on the VM',
      () {
    expect(selected.hasOnDeviceModelRuntime, isTrue);
  });

  test('the provider exposes the selected variant and can be overridden', () {
    final real = ProviderContainer();
    addTearDown(real.dispose);
    expect(real.read(onDeviceModelSupportedProvider),
        selected.hasOnDeviceModelRuntime);

    final asWeb = ProviderContainer(overrides: [
      onDeviceModelSupportedProvider.overrideWithValue(false),
    ]);
    addTearDown(asWeb.dispose);
    expect(asWeb.read(onDeviceModelSupportedProvider), isFalse);
  });
}
