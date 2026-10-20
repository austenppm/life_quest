import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Warmup set calculator for progressive warmup before working sets
class WarmupCalculatorWidget extends StatefulWidget {
  final double workingWeight;
  final int workingReps;
  final Function(List<WarmupSet>)? onWarmupSetsGenerated;

  const WarmupCalculatorWidget({
    super.key,
    required this.workingWeight,
    this.workingReps = 5,
    this.onWarmupSetsGenerated,
  });

  @override
  State<WarmupCalculatorWidget> createState() => _WarmupCalculatorWidgetState();
}

class _WarmupCalculatorWidgetState extends State<WarmupCalculatorWidget> {
  late double _workingWeight;
  int _numWarmupSets = 4;
  double _barWeight = 20.0;
  bool _useKg = true;
  WarmupStyle _warmupStyle = WarmupStyle.standard;

  List<WarmupSet> _warmupSets = [];

  @override
  void initState() {
    super.initState();
    _workingWeight = widget.workingWeight;
    _generateWarmupSets();
  }

  void _generateWarmupSets() {
    _warmupSets = _warmupStyle.generateSets(
      workingWeight: _workingWeight,
      barWeight: _barWeight,
      numSets: _numWarmupSets,
    );
    setState(() {});
    widget.onWarmupSetsGenerated?.call(_warmupSets);
  }

  @override
  Widget build(BuildContext context) {
    final unit = _useKg ? 'kg' : 'lbs';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Warmup Calculator',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _UnitToggle(
                    label: 'kg',
                    isSelected: _useKg,
                    onTap: () {
                      setState(() => _useKg = true);
                      _generateWarmupSets();
                    },
                  ),
                  const SizedBox(width: 4),
                  _UnitToggle(
                    label: 'lbs',
                    isSelected: !_useKg,
                    onTap: () {
                      setState(() => _useKg = false);
                      _generateWarmupSets();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Working Weight Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Working Weight',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_workingWeight > _barWeight + 5) {
                          setState(() => _workingWeight -= 5);
                          _generateWarmupSets();
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                    ),
                    Text(
                      '${_workingWeight.toStringAsFixed(1)} $unit',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _workingWeight += 5);
                        _generateWarmupSets();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Warmup Style Selection
          const Text(
            'Warmup Style',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: WarmupStyle.values.map((style) {
                final isSelected = _warmupStyle == style;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _warmupStyle = style);
                      _generateWarmupSets();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                        ),
                      ),
                      child: Text(
                        style.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Number of Warmup Sets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Warmup Sets',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [3, 4, 5].map((num) {
                  final isSelected = _numWarmupSets == num;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _numWarmupSets = num);
                        _generateWarmupSets();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$num',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Generated Warmup Sets
          const Text(
            'Warmup Sets',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 1, child: Text('Set', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Weight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 1, child: Text('Reps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('% of Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                ..._warmupSets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final set = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: index < _warmupSets.length - 1
                            ? BorderSide(color: AppColors.surfaceLight)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${set.weight.toStringAsFixed(1)} $unit',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${set.reps}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(set.percentOfWorking * 100).toInt()}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Working set
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Icon(Icons.fitness_center, size: 16, color: AppColors.primary),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${_workingWeight.toStringAsFixed(1)} $unit',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${widget.workingReps}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'WORKING',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// A single warmup set
class WarmupSet {
  final double weight;
  final int reps;
  final double percentOfWorking;

  const WarmupSet({
    required this.weight,
    required this.reps,
    required this.percentOfWorking,
  });
}

/// Different warmup progression styles
enum WarmupStyle {
  standard('Standard'),
  aggressive('Aggressive'),
  conservative('Conservative'),
  pyramid('Pyramid');

  final String displayName;
  const WarmupStyle(this.displayName);

  List<WarmupSet> generateSets({
    required double workingWeight,
    required double barWeight,
    required int numSets,
  }) {
    final sets = <WarmupSet>[];
    final availableWeight = workingWeight - barWeight;

    List<double> percentages;
    List<int> reps;

    switch (this) {
      case WarmupStyle.standard:
        // Standard: 40%, 55%, 70%, 85%
        percentages = _getPercentages(numSets, [0.4, 0.55, 0.70, 0.85, 0.90]);
        reps = _getReps(numSets, [10, 8, 5, 3, 2]);
        break;
      case WarmupStyle.aggressive:
        // Aggressive: Faster ramp up
        percentages = _getPercentages(numSets, [0.5, 0.65, 0.80, 0.90, 0.95]);
        reps = _getReps(numSets, [8, 5, 3, 2, 1]);
        break;
      case WarmupStyle.conservative:
        // Conservative: Slower ramp up
        percentages = _getPercentages(numSets, [0.3, 0.45, 0.55, 0.70, 0.80]);
        reps = _getReps(numSets, [12, 10, 8, 5, 5]);
        break;
      case WarmupStyle.pyramid:
        // Pyramid: More volume in middle
        percentages = _getPercentages(numSets, [0.4, 0.60, 0.75, 0.85, 0.90]);
        reps = _getReps(numSets, [8, 6, 5, 4, 3]);
        break;
    }

    for (int i = 0; i < numSets; i++) {
      final percent = percentages[i];
      // Round to nearest 2.5kg/5lbs
      double weight = barWeight + (availableWeight * percent);
      weight = (weight / 2.5).round() * 2.5;
      weight = weight.clamp(barWeight, workingWeight);

      sets.add(WarmupSet(
        weight: weight,
        reps: reps[i],
        percentOfWorking: weight / workingWeight,
      ));
    }

    return sets;
  }

  List<double> _getPercentages(int numSets, List<double> fullList) {
    if (numSets >= fullList.length) return fullList;
    // Evenly sample from the list
    final step = fullList.length / numSets;
    return List.generate(numSets, (i) => fullList[(i * step).floor()]);
  }

  List<int> _getReps(int numSets, List<int> fullList) {
    if (numSets >= fullList.length) return fullList;
    final step = fullList.length / numSets;
    return List.generate(numSets, (i) => fullList[(i * step).floor()]);
  }
}

/// Helper function to show warmup calculator as bottom sheet
void showWarmupCalculator(
  BuildContext context, {
  required double workingWeight,
  int workingReps = 5,
  Function(List<WarmupSet>)? onWarmupSetsGenerated,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => WarmupCalculatorWidget(
      workingWeight: workingWeight,
      workingReps: workingReps,
      onWarmupSetsGenerated: onWarmupSetsGenerated,
    ),
  );
}
