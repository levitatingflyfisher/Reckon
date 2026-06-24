import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/record_providers.dart';
import '../domain/entities/calibration_report.dart';

class RecordScreen extends ConsumerWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final clarity = ref.watch(clarityScoreProvider);
    final insights = ref.watch(insightCardsProvider);
    final closed = ref.watch(closedCasesProvider);
    final calibration = ref.watch(calibrationReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Record')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(label: 'CLARITY SCORE'),
          clarity.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (score) {
              if (!score.hasEnoughData) {
                return OHCard(
                  child: Text(
                    'Your record is still young. It gets more useful after a few closed cases.',
                    style: textTheme.bodyLarge,
                  ),
                );
              }
              return OHCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${score.value}',
                        style: textTheme.displayLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Across ${score.caseCount} closed case${score.caseCount == 1 ? '' : 's'}.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          ),
          const SectionHeader(label: 'CALIBRATION'),
          calibration.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (report) {
              if (!report.hasEnoughData) {
                return Text(
                  'Calibration charts appear after ${5 - report.sampleCount} more closed case${5 - report.sampleCount == 1 ? '' : 's'}.',
                  style: textTheme.bodyMedium,
                );
              }
              return _CalibrationView(report: report);
            },
          ),
          const SectionHeader(label: 'PATTERNS'),
          insights.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (cards) {
              if (cards.isEmpty) {
                return Text(
                  'Patterns appear after you have several closed cases to compare.',
                  style: textTheme.bodyMedium,
                );
              }
              return Column(
                children: cards
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OHCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.title, style: textTheme.labelLarge),
                                const SizedBox(height: 8),
                                Text(c.body, style: textTheme.bodyLarge),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          OHCard(
            onTap: () => context.push('/model-scorecard'),
            child: Row(
              children: [
                Icon(Icons.timeline,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Model scorecard', style: textTheme.labelLarge),
                      Text(
                        'How well have the on-device models predicted your outcomes?',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SectionHeader(label: 'HISTORY'),
          closed.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (cases) {
              if (cases.isEmpty) {
                return Text(
                  'No closed cases yet.',
                  style: textTheme.bodyMedium,
                );
              }
              return Column(
                children: cases
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OHCard(
                            onTap: () => context.push('/case/${c.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.question,
                                    style: textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat.yMMMd().format(c.createdAt),
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalibrationView extends StatelessWidget {
  const _CalibrationView({required this.report});
  final CalibrationReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OHCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Satisfaction by category', style: textTheme.labelLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: _CategoryBars(stats: report.categoryStats),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (report.confidenceBuckets.isNotEmpty)
          OHCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Does your confidence track satisfaction?',
                    style: textTheme.labelLarge),
                const SizedBox(height: 8),
                for (final b in report.confidenceBuckets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            b.label,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (b.meanSatisfaction + 2) / 4,
                            minHeight: 8,
                            backgroundColor:
                                colors.surfaceContainerHighest,
                            valueColor:
                                AlwaysStoppedAnimation(colors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${b.meanSatisfaction.toStringAsFixed(1)} (n=${b.count})',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        OHCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mean lean drift',
                        style: textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      report.meanLeanDrift.toStringAsFixed(0),
                      style: textTheme.displaySmall,
                    ),
                    Text(
                      // Lean is 0–100, so a "swing" of 50+ means the user
                      // genuinely flipped sides between polls at least once.
                      // 20–50 is meaningful movement within one camp. Below
                      // 20 is noise.
                      report.meanLeanDrift >= 50
                          ? 'You tend to flip sides before deciding.'
                          : report.meanLeanDrift >= 20
                              ? 'Some wobble within one camp, nothing dramatic.'
                              : 'You tend to lock in early.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.stats});
  final List<CategoryStat> stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final groups = <BarChartGroupData>[
      for (var i = 0; i < stats.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: stats[i].meanSatisfaction,
              color: stats[i].meanSatisfaction >= 0
                  ? colors.primary
                  : colors.error,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
    ];
    return BarChart(
      BarChartData(
        minY: -2,
        maxY: 2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= stats.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    stats[i].category,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        barGroups: groups,
      ),
    );
  }
}
