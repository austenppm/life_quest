import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_theme.dart';
import '../../models/body_measurement.dart';
import '../../providers/body_measurement_provider.dart';

class BodyMeasurementsScreen extends ConsumerStatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  ConsumerState<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends ConsumerState<BodyMeasurementsScreen> {
  @override
  Widget build(BuildContext context) {
    final measurements = ref.watch(bodyMeasurementsProvider);
    final latest = ref.watch(latestMeasurementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Measurements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: measurements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              if (latest != null) ...[
                _SummaryCards(measurement: latest),
                const SizedBox(height: 24),
              ],

              // Weight Chart
              _SectionHeader(title: 'Weight Progress'),
              const SizedBox(height: 12),
              _WeightChart(),
              const SizedBox(height: 24),

              // Body Measurements Overview
              _SectionHeader(title: 'Current Measurements'),
              const SizedBox(height: 12),
              if (latest != null)
                _MeasurementsGrid(measurement: latest)
              else
                _EmptyMeasurements(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeasurementSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Measurement'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAddMeasurementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddMeasurementSheet(),
    );
  }

  void _showHistory(BuildContext context) {
    final measurements = ref.read(bodyMeasurementsProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MeasurementHistory(measurements: measurements),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final BodyMeasurement measurement;

  const _SummaryCards({required this.measurement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (measurement.weight != null)
          Expanded(
            child: _SummaryCard(
              title: 'Weight',
              value: '${measurement.weight!.toStringAsFixed(1)} kg',
              icon: Icons.scale,
              color: AppColors.primary,
            ),
          ),
        if (measurement.weight != null && measurement.bodyFat != null)
          const SizedBox(width: 12),
        if (measurement.bodyFat != null)
          Expanded(
            child: _SummaryCard(
              title: 'Body Fat',
              value: '${measurement.bodyFat!.toStringAsFixed(1)}%',
              icon: Icons.percent,
              color: AppColors.accent,
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightHistory = ref.watch(weightHistoryProvider);

    if (weightHistory.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No weight data yet',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final minWeight = weightHistory.map((e) => e.value).reduce((a, b) => a < b ? a : b) - 2;
    final maxWeight = weightHistory.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minWeight,
          maxY: maxWeight,
          lineBarsData: [
            LineChartBarData(
              spots: weightHistory.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementsGrid extends StatelessWidget {
  final BodyMeasurement measurement;

  const _MeasurementsGrid({required this.measurement});

  @override
  Widget build(BuildContext context) {
    final items = <_MeasurementItem>[];

    if (measurement.neck != null) {
      items.add(_MeasurementItem('Neck', measurement.neck!, 'cm'));
    }
    if (measurement.shoulders != null) {
      items.add(_MeasurementItem('Shoulders', measurement.shoulders!, 'cm'));
    }
    if (measurement.chest != null) {
      items.add(_MeasurementItem('Chest', measurement.chest!, 'cm'));
    }
    if (measurement.waist != null) {
      items.add(_MeasurementItem('Waist', measurement.waist!, 'cm'));
    }
    if (measurement.hips != null) {
      items.add(_MeasurementItem('Hips', measurement.hips!, 'cm'));
    }
    if (measurement.averageBicep != null) {
      items.add(_MeasurementItem('Biceps', measurement.averageBicep!, 'cm'));
    }
    if (measurement.averageForearm != null) {
      items.add(_MeasurementItem('Forearms', measurement.averageForearm!, 'cm'));
    }
    if (measurement.averageThigh != null) {
      items.add(_MeasurementItem('Thighs', measurement.averageThigh!, 'cm'));
    }
    if (measurement.averageCalf != null) {
      items.add(_MeasurementItem('Calves', measurement.averageCalf!, 'cm'));
    }

    if (items.isEmpty) {
      return _EmptyMeasurements();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _MeasurementItem extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const _MeasurementItem(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMeasurements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.straighten,
            size: 48,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No measurements yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Log your first measurement to track progress',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _AddMeasurementSheet extends ConsumerStatefulWidget {
  const _AddMeasurementSheet();

  @override
  ConsumerState<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends ConsumerState<_AddMeasurementSheet> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _neckController = TextEditingController();
  final _shouldersController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _leftBicepController = TextEditingController();
  final _rightBicepController = TextEditingController();
  final _leftForearmController = TextEditingController();
  final _rightForearmController = TextEditingController();
  final _leftThighController = TextEditingController();
  final _rightThighController = TextEditingController();
  final _leftCalfController = TextEditingController();
  final _rightCalfController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _neckController.dispose();
    _shouldersController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _leftBicepController.dispose();
    _rightBicepController.dispose();
    _leftForearmController.dispose();
    _rightForearmController.dispose();
    _leftThighController.dispose();
    _rightThighController.dispose();
    _leftCalfController.dispose();
    _rightCalfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Measurements',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date picker
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Basic metrics
            const Text(
              'Basic Metrics',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MeasurementField(
                    controller: _weightController,
                    label: 'Weight',
                    unit: 'kg',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MeasurementField(
                    controller: _bodyFatController,
                    label: 'Body Fat',
                    unit: '%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Upper body
            const Text(
              'Upper Body',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MeasurementField(
                    controller: _neckController,
                    label: 'Neck',
                    unit: 'cm',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MeasurementField(
                    controller: _shouldersController,
                    label: 'Shoulders',
                    unit: 'cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MeasurementField(
                    controller: _chestController,
                    label: 'Chest',
                    unit: 'cm',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MeasurementField(
                    controller: _waistController,
                    label: 'Waist',
                    unit: 'cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MeasurementField(
              controller: _hipsController,
              label: 'Hips',
              unit: 'cm',
            ),
            const SizedBox(height: 24),

            // Arms
            const Text(
              'Arms',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MeasurementField(
                    controller: _leftBicepController,
                    label: 'Left Bicep',
                    unit: 'cm',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MeasurementField(
                    controller: _rightBicepController,
                    label: 'Right Bicep',
                    unit: 'cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MeasurementField(
                    controller: _leftForearmController,
                    label: 'Left Forearm',
                    unit: 'cm',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MeasurementField(
                    controller: _rightForearmController,
                    label: 'Right Forearm',
                    unit: 'cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Legs
            const Text(
              'Legs',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MeasurementField(
                    controller: _leftThighController,
                    label: 'Left Thigh',
                    unit: 'cm',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MeasurementField(
                    controller: _rightThighController,
                    label: 'Right Thigh',
                    unit: 'cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MeasurementField(
                    controller: _leftCalfController,
                    label: 'Left Calf',
                    unit: 'cm',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MeasurementField(
                    controller: _rightCalfController,
                    label: 'Right Calf',
                    unit: 'cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMeasurement,
                child: const Text('Save Measurement'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  void _saveMeasurement() {
    ref.read(bodyMeasurementNotifierProvider.notifier).addMeasurement(
          date: _selectedDate,
          weight: _parseDouble(_weightController.text),
          bodyFat: _parseDouble(_bodyFatController.text),
          neck: _parseDouble(_neckController.text),
          shoulders: _parseDouble(_shouldersController.text),
          chest: _parseDouble(_chestController.text),
          waist: _parseDouble(_waistController.text),
          hips: _parseDouble(_hipsController.text),
          leftBicep: _parseDouble(_leftBicepController.text),
          rightBicep: _parseDouble(_rightBicepController.text),
          leftForearm: _parseDouble(_leftForearmController.text),
          rightForearm: _parseDouble(_rightForearmController.text),
          leftThigh: _parseDouble(_leftThighController.text),
          rightThigh: _parseDouble(_rightThighController.text),
          leftCalf: _parseDouble(_leftCalfController.text),
          rightCalf: _parseDouble(_rightCalfController.text),
        );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Measurement saved'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;

  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _MeasurementHistory extends StatelessWidget {
  final List<BodyMeasurement> measurements;

  const _MeasurementHistory({required this.measurements});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measurement History',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (measurements.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No measurements logged yet',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.separated(
                itemCount: measurements.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final m = measurements[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.straighten,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '${m.date.month}/${m.date.day}/${m.date.year}',
                    ),
                    subtitle: Text(
                      m.weight != null ? '${m.weight!.toStringAsFixed(1)} kg' : 'No weight',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
