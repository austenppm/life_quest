import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PlateCalculatorWidget extends StatefulWidget {
  final double? initialWeight;
  final Function(double)? onWeightSelected;

  const PlateCalculatorWidget({
    super.key,
    this.initialWeight,
    this.onWeightSelected,
  });

  @override
  State<PlateCalculatorWidget> createState() => _PlateCalculatorWidgetState();
}

class _PlateCalculatorWidgetState extends State<PlateCalculatorWidget> {
  double _targetWeight = 60.0;
  double _barWeight = 20.0; // Standard Olympic barbell
  bool _useKg = true;

  // Standard plate weights in kg
  static const List<_Plate> _platesKg = [
    _Plate(25.0, Colors.red, 'red'),
    _Plate(20.0, Colors.blue, 'blue'),
    _Plate(15.0, Colors.yellow, 'yellow'),
    _Plate(10.0, Colors.green, 'green'),
    _Plate(5.0, Colors.white, 'white'),
    _Plate(2.5, Colors.black, 'black'),
    _Plate(1.25, Colors.grey, 'grey'),
    _Plate(0.5, Colors.grey, 'grey'),
  ];

  // Standard plate weights in lbs
  static const List<_Plate> _platesLbs = [
    _Plate(45.0, Colors.red, 'red'),
    _Plate(35.0, Colors.yellow, 'yellow'),
    _Plate(25.0, Colors.green, 'green'),
    _Plate(10.0, Colors.white, 'white'),
    _Plate(5.0, Colors.blue, 'blue'),
    _Plate(2.5, Colors.grey, 'grey'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialWeight != null) {
      _targetWeight = widget.initialWeight!;
    }
  }

  List<_Plate> get _availablePlates => _useKg ? _platesKg : _platesLbs;

  Map<double, int> _calculatePlates() {
    final weightPerSide = (_targetWeight - _barWeight) / 2;
    if (weightPerSide <= 0) return {};

    final plates = <double, int>{};
    double remaining = weightPerSide;

    for (final plate in _availablePlates) {
      while (remaining >= plate.weight) {
        plates[plate.weight] = (plates[plate.weight] ?? 0) + 1;
        remaining -= plate.weight;
      }
    }

    return plates;
  }

  @override
  Widget build(BuildContext context) {
    final plates = _calculatePlates();
    final unit = _useKg ? 'kg' : 'lbs';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Plate Calculator',
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
                    onTap: () => setState(() => _useKg = true),
                  ),
                  const SizedBox(width: 4),
                  _UnitToggle(
                    label: 'lbs',
                    isSelected: !_useKg,
                    onTap: () => setState(() => _useKg = false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Target weight display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Target Weight',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_targetWeight > _barWeight) {
                          setState(() => _targetWeight -= 2.5);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                    ),
                    Text(
                      '${_targetWeight.toStringAsFixed(1)} $unit',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _targetWeight += 2.5);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bar: ${_barWeight.toStringAsFixed(1)} $unit',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Barbell visualization
          _BarbellVisualization(plates: plates, availablePlates: _availablePlates),
          const SizedBox(height: 20),

          // Plates per side
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Per Side:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                if (plates.isEmpty)
                  const Text(
                    'No plates needed - bar only',
                    style: TextStyle(color: AppColors.textMuted),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: plates.entries.map((entry) {
                      final plate = _availablePlates.firstWhere((p) => p.weight == entry.key);
                      return _PlateChip(
                        weight: entry.key,
                        count: entry.value,
                        color: plate.color,
                        unit: unit,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick select buttons
          const Text(
            'Quick Select',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _QuickWeightButton(
                weight: _useKg ? 60 : 135,
                unit: unit,
                onTap: () => setState(() => _targetWeight = _useKg ? 60 : 135),
              ),
              _QuickWeightButton(
                weight: _useKg ? 80 : 185,
                unit: unit,
                onTap: () => setState(() => _targetWeight = _useKg ? 80 : 185),
              ),
              _QuickWeightButton(
                weight: _useKg ? 100 : 225,
                unit: unit,
                onTap: () => setState(() => _targetWeight = _useKg ? 100 : 225),
              ),
              _QuickWeightButton(
                weight: _useKg ? 120 : 275,
                unit: unit,
                onTap: () => setState(() => _targetWeight = _useKg ? 120 : 275),
              ),
              _QuickWeightButton(
                weight: _useKg ? 140 : 315,
                unit: unit,
                onTap: () => setState(() => _targetWeight = _useKg ? 140 : 315),
              ),
            ],
          ),

          if (widget.onWeightSelected != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onWeightSelected!(_targetWeight),
                child: Text('Use ${_targetWeight.toStringAsFixed(1)} $unit'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Plate {
  final double weight;
  final Color color;
  final String colorName;

  const _Plate(this.weight, this.color, this.colorName);
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

class _PlateChip extends StatelessWidget {
  final double weight;
  final int count;
  final Color color;
  final String unit;

  const _PlateChip({
    required this.weight,
    required this.count,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count x ${weight.toString().replaceAll(RegExp(r'\.0$'), '')} $unit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color == Colors.white || color == Colors.yellow
                  ? AppColors.textPrimary
                  : color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickWeightButton extends StatelessWidget {
  final double weight;
  final String unit;
  final VoidCallback onTap;

  const _QuickWeightButton({
    required this.weight,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Text(
          '${weight.toInt()} $unit',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _BarbellVisualization extends StatelessWidget {
  final Map<double, int> plates;
  final List<_Plate> availablePlates;

  const _BarbellVisualization({
    required this.plates,
    required this.availablePlates,
  });

  @override
  Widget build(BuildContext context) {
    // Build list of plates to display (in order, largest to smallest from center)
    final plateWidgets = <Widget>[];

    // Sort plates by weight descending
    final sortedPlates = plates.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    for (final entry in sortedPlates) {
      final plate = availablePlates.firstWhere((p) => p.weight == entry.key);
      for (int i = 0; i < entry.value; i++) {
        plateWidgets.add(_VisualPlate(
          weight: entry.key,
          color: plate.color,
        ));
      }
    }

    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left plates (reversed)
          ...plateWidgets.reversed,
          // Bar
          Container(
            width: 80,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Right plates
          ...plateWidgets,
        ],
      ),
    );
  }
}

class _VisualPlate extends StatelessWidget {
  final double weight;
  final Color color;

  const _VisualPlate({
    required this.weight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Height based on weight
    final height = (weight / 25 * 50).clamp(20.0, 50.0);

    return Container(
      width: 8,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: color == Colors.white ? Colors.grey : Colors.transparent,
        ),
      ),
    );
  }
}

// Helper function to show plate calculator as bottom sheet
void showPlateCalculator(
  BuildContext context, {
  double? initialWeight,
  Function(double)? onWeightSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => PlateCalculatorWidget(
      initialWeight: initialWeight,
      onWeightSelected: onWeightSelected != null
          ? (weight) {
              onWeightSelected(weight);
              Navigator.pop(context);
            }
          : null,
    ),
  );
}
