import 'package:flutter/material.dart';

import '../../shared/widgets/oh_text_field.dart';
import 'model_download_service.dart';
import 'model_spec.dart';

/// Shows the HuggingFace token dialog for a gated [spec]. Returns the trimmed
/// token, or null if cancelled. Shared by onboarding and settings.
Future<String?> promptForHfToken(BuildContext context, ReckonModelSpec spec) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _HfTokenDialog(spec: spec),
  );
}

/// Owns the text controller so it is disposed with the dialog (after the
/// dismiss animation), not synchronously after `showDialog` returns.
class _HfTokenDialog extends StatefulWidget {
  const _HfTokenDialog({required this.spec});

  final ReckonModelSpec spec;

  @override
  State<_HfTokenDialog> createState() => _HfTokenDialogState();
}

class _HfTokenDialogState extends State<_HfTokenDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('HuggingFace token'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.spec.displayName} is gated on HuggingFace. Paste a '
            'read-only access token — stored securely on this device only.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OHTextField(controller: _controller, hint: 'hf_...'),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Ensures a HuggingFace token is stored for a gated [spec], prompting the user
/// if needed. Returns true if a non-empty token is available afterwards.
/// Ungated specs no-op to true.
Future<bool> ensureHfToken(
    BuildContext context, ModelDownloadService svc, ReckonModelSpec spec) async {
  if (!spec.requiresToken) return true;
  final existing = await svc.getHfToken();
  if (existing != null && existing.isNotEmpty) return true;
  if (!context.mounted) return false;
  final entered = await promptForHfToken(context, spec);
  if (entered == null || entered.isEmpty) return false;
  await svc.setHfToken(entered);
  return true;
}
