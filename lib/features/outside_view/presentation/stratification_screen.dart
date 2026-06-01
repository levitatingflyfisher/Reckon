import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_button.dart';
import '../data/outside_view_providers.dart';
import '../domain/entities/user_profile.dart';

class StratificationScreen extends ConsumerStatefulWidget {
  const StratificationScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<StratificationScreen> createState() =>
      _StratificationScreenState();
}

class _StratificationScreenState extends ConsumerState<StratificationScreen> {
  String? _ses;
  String? _religiosity;
  String? _relationship;

  @override
  void initState() {
    super.initState();
    _maybeSkip();
  }

  Future<void> _maybeSkip() async {
    final repo = ref.read(outsideViewRepositoryProvider);
    final existing = await repo.getUserProfile();
    if (existing.hasAny && mounted) {
      context.go('/outside-view/${widget.caseId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('A few quick questions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'These help us choose a reference class that matches your situation. You can skip any.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _PickerRow(
              label: 'SES bracket',
              value: _ses,
              options: const ['working class', 'middle', 'upper-middle', 'wealthy'],
              onChanged: (v) => setState(() => _ses = v),
            ),
            _PickerRow(
              label: 'Religiosity',
              value: _religiosity,
              options: const ['none', 'occasional', 'weekly', 'deeply practicing'],
              onChanged: (v) => setState(() => _religiosity = v),
            ),
            _PickerRow(
              label: 'Relationship status',
              value: _relationship,
              options: const ['single', 'dating', 'partnered', 'married'],
              onChanged: (v) => setState(() => _relationship = v),
            ),
            const Spacer(),
            OHButton(
              label: 'Continue',
              expanded: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref.read(outsideViewRepositoryProvider).saveUserProfile(
          UserProfile(
            sesBracket: _ses,
            religiosity: _religiosity,
            relationshipStatus: _relationship,
          ),
        );
    if (mounted) context.go('/outside-view/${widget.caseId}');
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: options
                .map((o) => ChoiceChip(
                      label: Text(o),
                      selected: value == o,
                      onSelected: (selected) => onChanged(selected ? o : null),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
