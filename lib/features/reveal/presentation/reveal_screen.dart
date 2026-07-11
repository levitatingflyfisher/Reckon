import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../case/data/case_providers.dart';
import '../../case/domain/entities/case.dart';
import '../../case/domain/entities/poll.dart';
import '../../predictions/data/prediction_providers.dart';
import '../../predictions/domain/entities/model_prediction.dart';
import '../data/reveal_providers.dart';
import '../domain/entities/reveal_observation.dart';

class RevealScreen extends ConsumerStatefulWidget {
  const RevealScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen> {
  RevealObservation? _observation;
  bool _loading = true;
  String _chosenOption = 'a';
  int? _selectedPoll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  /// Switch the chosen option and regenerate the observation for it — the reveal
  /// is keyed by chosen option, so a B-chooser no longer sees the A narrative
  /// produced from the default selection.
  void _selectOption(String option) {
    if (_chosenOption == option) return;
    setState(() {
      _chosenOption = option;
      _loading = true;
    });
    _prepare();
  }

  /// Render the reveal observation without flipping case status. The state
  /// transition (open → decided, plus poll reveal) happens only when the
  /// user commits via "Set resolution date", so backing out of this screen
  /// leaves the case exactly as it was.
  Future<void> _prepare() async {
    try {
      final case_ = await ref.read(caseByIdProvider(widget.caseId).future);
      final polls = await ref.read(pollsForCaseProvider(widget.caseId).future);
      if (case_ == null) throw StateError('Case not found');
      final uc = await ref.read(generateRevealProvider.future);
      final obs = await uc.call(
        case_: case_,
        polls: polls,
        chosenOption: _chosenOption,
      );
      if (mounted) {
        setState(() {
          _observation = obs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _observation = RevealObservation(
            text:
                'Your record is saved. Observation could not be generated: $e',
          );
          _loading = false;
        });
      }
    }
  }

  /// Commit the decision: reveal polls, flip status, and navigate to the
  /// resolution-date picker. The atomic transition lives in CaseRepository.
  Future<void> _commitAndProceed() async {
    await ref.read(markDecidedProvider).call(widget.caseId);
    ref.invalidate(pollsForCaseProvider(widget.caseId));
    ref.invalidate(caseByIdProvider(widget.caseId));
    if (!mounted) return;
    context.push('/resolution-date/${widget.caseId}?chosen=$_chosenOption');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pollsAsync = ref.watch(pollsForCaseProvider(widget.caseId));
    final caseAsync = ref.watch(caseByIdProvider(widget.caseId));

    return Scaffold(
      appBar: AppBar(title: const Text('The reveal')),
      body: pollsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (polls) {
          final case_ = caseAsync.value;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scroll the chart + observation so tall content (large text
                // scale, long rationale) can't overflow the column behind the
                // pinned choice chips and action button.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (polls.isEmpty)
                          Text(
                            "No polls were recorded before you decided — there's no time series to reveal.",
                            style: textTheme.bodyLarge,
                          )
                        else
                          SizedBox(
                            height: 240,
                            child: OHCard(
                              child: _LeanChart(
                                polls: polls,
                                onPointTapped: (i) =>
                                    setState(() => _selectedPoll = i),
                              ),
                            ),
                          ),
                        if (_selectedPoll != null &&
                            _selectedPoll! < polls.length) ...[
                          const SizedBox(height: 12),
                          OHCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Poll ${polls[_selectedPoll!].pollNumber}: lean ${polls[_selectedPoll!].lean}',
                                  style: textTheme.labelLarge,
                                ),
                                if (polls[_selectedPoll!].rationale != null)
                                  Text(polls[_selectedPoll!].rationale!,
                                      style: textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                        _DuelSection(caseId: widget.caseId, case_: case_),
                        const SizedBox(height: 24),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else if (_observation != null)
                          OHCard(
                            child: Text(
                              _observation!.text,
                              style: textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Lora',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (case_ != null) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(case_.optionA),
                        selected: _chosenOption == 'a',
                        onSelected: (_) => _selectOption('a'),
                      ),
                      ChoiceChip(
                        label: Text(case_.optionB),
                        selected: _chosenOption == 'b',
                        onSelected: (_) => _selectOption('b'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                OHButton(
                  label: 'Set resolution date',
                  expanded: true,
                  onPressed: _commitAndProceed,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The duel table — the forecasters' sealed leans, revealed alongside the
/// user's own poll series (they were logged before the reveal and could not
/// have influenced it — R1). Rendered only here: this screen IS the reveal
/// moment.
class _DuelSection extends ConsumerWidget {
  const _DuelSection({required this.caseId, this.case_});

  final String caseId;
  final Case? case_;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duels =
        ref.watch(duelForecastsForCaseProvider(caseId)).valueOrNull ??
            const <ModelPrediction>[];
    if (duels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const SectionHeader(label: 'THE DUEL'),
        for (final duel in duels)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DuelRow(
              prediction: duel,
              optionA: case_?.optionA ?? 'A',
              optionB: case_?.optionB ?? 'B',
            ),
          ),
      ],
    );
  }
}

class _DuelRow extends StatefulWidget {
  const _DuelRow({
    required this.prediction,
    required this.optionA,
    required this.optionB,
  });

  final ModelPrediction prediction;
  final String optionA;
  final String optionB;

  @override
  State<_DuelRow> createState() => _DuelRowState();
}

class _DuelRowState extends State<_DuelRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final payload = widget.prediction.payload;
    final lean = ((payload['lean'] as num?) ?? 50).round().clamp(0, 100);
    final name = payload['forecasterName'] as String? ??
        widget.prediction.modelVersion;
    final rationale = payload['rationale'] as String? ?? '';
    final towardB = lean >= 50;
    final toward = towardB ? widget.optionB : widget.optionA;

    return OHCard(
      onTap: rationale.isEmpty
          ? null
          : () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis),
              ),
              if (rationale.isNotEmpty)
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('A', style: textTheme.bodySmall),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: lean / 100,
                    minHeight: 6,
                    backgroundColor:
                        colors.surfaceContainerHighest.withValues(alpha: 0.6),
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('B', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'lean $lean — toward $toward',
            style: textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          if (_expanded && rationale.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(rationale, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _LeanChart extends StatelessWidget {
  const _LeanChart({required this.polls, required this.onPointTapped});
  final List<Poll> polls;
  final ValueChanged<int> onPointTapped;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spots = <FlSpot>[
      for (var i = 0; i < polls.length; i++)
        FlSpot(i.toDouble(), polls[i].lean.toDouble()),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: Text('Poll #', style: textTheme.bodySmall),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= polls.length) return const SizedBox.shrink();
                return Text('${polls[i].pollNumber}',
                    style: textTheme.bodySmall);
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text('Lean', style: textTheme.bodySmall),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 50,
              getTitlesWidget: (value, meta) {
                final v = value.toInt();
                final label = v == 0 ? 'A' : (v == 100 ? 'B' : '$v');
                return Text(label, style: textTheme.bodySmall);
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.lineBarSpots != null) {
              final idx = response!.lineBarSpots!.first.spotIndex;
              onPointTapped(idx);
            }
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: colors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
