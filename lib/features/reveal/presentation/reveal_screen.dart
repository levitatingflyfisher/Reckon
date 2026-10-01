import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
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
import '../../../shared/theme/reckon_tokens.dart';
import '../../../core/llm/llm_providers.dart';

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
      if (case_ == null) throw StateError('Decision not found');
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
      debugPrint('Reckon: the reveal observation failed: $e');
      if (mounted) {
        setState(() {
          _observation = RevealObservation(
            text: ref.read(onDeviceModelSupportedProvider)
                ? "Your record is saved. Reckon couldn’t write an "
                    'observation about it this time.'
                : 'Your record is saved. The observation is written by the '
                    "on-device model, which this browser can’t run.",
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
      body: OhPage(
        padding: EdgeInsets.zero,
        child: pollsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => OhErrorState.fromError(e,
              stackTrace: st, title: "Couldn’t load your weigh-ins"),
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
                              "You didn’t weigh in before you decided, so there’s no drift to show.",
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
                          // R1/R4: the duel table renders only after the
                          // user's own record is complete. "I've decided"
                          // merely navigates here — while the case is still
                          // open the user can back out, keep re-polling, and
                          // re-run the duel, so showing leans now would let
                          // every later poll be scored as blind when it
                          // wasn't. The table appears once the decision has
                          // committed (status decided/resolving/closed).
                          if (case_ != null && case_.status != CaseStatus.open)
                            _DuelSection(caseId: widget.caseId, case_: case_),
                          const SizedBox(height: 24),
                          if (_loading)
                            const Center(child: CircularProgressIndicator())
                          else if (_observation != null)
                            OHCard(
                              child: Text(
                                _observation!.text,
                                style: ReckonTypography.serifItalic(textTheme.bodyLarge),
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
      ),
    );
  }
}

/// The duel table — the forecasters' sealed leans, revealed alongside the
/// user's own poll series (they were logged before the reveal and could not
/// have influenced it — R1). Rendered only here, and only once the case has
/// left `open` (the build site enforces it): the reveal moment is the
/// committed decision, not a visit to this screen.
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
        const SectionHeader(label: 'Forecasters'),
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
            'lean $lean, toward $toward',
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

    // Axis labels grow with the reader's text up to 2x (the WCAG floor) and
    // their slots grow with them, measured, so they never crowd or clip at
    // large text; the end labels are pulled inside the chart's edges.
    final labelStyle = textTheme.bodySmall;
    final scaler =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2.0);
    Size measure(String s) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: labelStyle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      final size = tp.size;
      tp.dispose();
      return size;
    }

    const gap = 6.0;
    final labelHeight = measure('0').height;
    final leftWidth = ['A', '50', 'B']
        .map((s) => measure(s).width)
        .reduce((a, b) => a > b ? a : b);
    Widget label(String text, TitleMeta meta) => SideTitleWidget(
          axisSide: meta.axisSide,
          space: gap,
          fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
          child: Text(text, style: labelStyle, textScaler: scaler),
        );

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
            axisNameWidget:
                Text('Poll #', style: labelStyle, textScaler: scaler),
            axisNameSize: labelHeight,
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: labelHeight + gap,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= polls.length) return const SizedBox.shrink();
                return label('${polls[i].pollNumber}', meta);
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text('Lean', style: labelStyle, textScaler: scaler),
            axisNameSize: labelHeight,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftWidth + gap,
              interval: 50,
              getTitlesWidget: (value, meta) {
                final v = value.toInt();
                return label(v == 0 ? 'A' : (v == 100 ? 'B' : '$v'), meta);
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
