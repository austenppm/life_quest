import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../models/food_entry.dart';
import '../../providers/food_provider.dart';
import '../../services/ai_service.dart';
import '../../services/voice_service.dart';

class AddFoodDialog extends ConsumerStatefulWidget {
  final DateTime date;
  final MealType? initialMealType;

  const AddFoodDialog({
    super.key,
    required this.date,
    this.initialMealType,
  });

  @override
  ConsumerState<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends ConsumerState<AddFoodDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MealType _selectedMealType;
  
  // Manual entry fields
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '1');
  final _servingUnitController = TextEditingController(text: 'serving');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedMealType = widget.initialMealType ?? _getDefaultMealType();
  }

  MealType _getDefaultMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 20) return MealType.dinner;
    return MealType.snack;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingSizeController.dispose();
    _servingUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Food',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Meal type dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<MealType>(
              value: _selectedMealType,
              decoration: InputDecoration(
                labelText: 'Meal',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: MealType.values.map((type) {
                final config = _getMealConfig(type);
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(config.icon, color: config.color, size: 20),
                      const SizedBox(width: 12),
                      Text(config.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) {
                  setState(() => _selectedMealType = type);
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Voice'),
              Tab(text: 'AI Scan'),
              Tab(text: 'Quick Add'),
              Tab(text: 'Manual'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _VoiceInputTab(
                  mealType: _selectedMealType,
                  date: widget.date,
                  onFoodAdded: () => Navigator.pop(context),
                ),
                _AIScanTab(
                  mealType: _selectedMealType,
                  date: widget.date,
                  onFoodAdded: () => Navigator.pop(context),
                ),
                _QuickAddTab(
                  mealType: _selectedMealType,
                  date: widget.date,
                  onFoodAdded: () => Navigator.pop(context),
                ),
                _ManualEntryTab(
                  nameController: _nameController,
                  caloriesController: _caloriesController,
                  proteinController: _proteinController,
                  carbsController: _carbsController,
                  fatController: _fatController,
                  servingSizeController: _servingSizeController,
                  servingUnitController: _servingUnitController,
                  onSubmit: _submitManualEntry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _MealConfig _getMealConfig(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return _MealConfig('Breakfast', Icons.wb_sunny_outlined, const Color(0xFFFFB347));
      case MealType.morningSnack:
        return _MealConfig('AM Snack', Icons.coffee_outlined, const Color(0xFFE8A87C));
      case MealType.lunch:
        return _MealConfig('Lunch', Icons.wb_cloudy_outlined, const Color(0xFF4ECDC4));
      case MealType.afternoonSnack:
        return _MealConfig('PM Snack', Icons.icecream_outlined, const Color(0xFF85C1E9));
      case MealType.dinner:
        return _MealConfig('Dinner', Icons.nights_stay_outlined, const Color(0xFF6C5CE7));
      case MealType.eveningSnack:
        return _MealConfig('Eve Snack', Icons.bedtime_outlined, const Color(0xFFAF7AC5));
      case MealType.snack:
        return _MealConfig('Snack', Icons.cookie_outlined, const Color(0xFFFF85A2));
      case MealType.preWorkout:
        return _MealConfig('Pre-Workout', Icons.fitness_center_outlined, const Color(0xFF58D68D));
      case MealType.postWorkout:
        return _MealConfig('Post-Workout', Icons.sports_score_outlined, const Color(0xFF5DADE2));
      case MealType.supper:
        return _MealConfig('Supper', Icons.local_dining_outlined, const Color(0xFFD7BDE2));
    }
  }

  void _submitManualEntry() {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name')),
      );
      return;
    }

    if (calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter calories')),
      );
      return;
    }

    ref.read(foodNotifierProvider.notifier).addFoodEntry(
          name: name,
          mealType: _selectedMealType,
          calories: calories,
          protein: double.tryParse(_proteinController.text) ?? 0,
          carbs: double.tryParse(_carbsController.text) ?? 0,
          fat: double.tryParse(_fatController.text) ?? 0,
          servingSize: double.tryParse(_servingSizeController.text) ?? 1,
          servingUnit: _servingUnitController.text.isEmpty
              ? 'serving'
              : _servingUnitController.text,
          date: widget.date,
        );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to ${_selectedMealType.name}!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _MealConfig {
  final String label;
  final IconData icon;
  final Color color;

  _MealConfig(this.label, this.icon, this.color);
}

class _VoiceInputTab extends ConsumerStatefulWidget {
  final MealType mealType;
  final DateTime date;
  final VoidCallback onFoodAdded;

  const _VoiceInputTab({
    required this.mealType,
    required this.date,
    required this.onFoodAdded,
  });

  @override
  ConsumerState<_VoiceInputTab> createState() => _VoiceInputTabState();
}

class _VoiceInputTabState extends ConsumerState<_VoiceInputTab> {
  final _textController = TextEditingController();
  bool _isListening = false;
  bool _isProcessing = false;
  String _partialText = '';
  List<FoodAnalysis> _parsedFoods = [];
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final voiceService = ref.read(voiceServiceProvider);

    setState(() {
      _isListening = true;
      _partialText = '';
      _error = null;
    });

    await voiceService.startListening(
      onResult: (text) {
        setState(() {
          _textController.text = text;
          _isListening = false;
        });
        _processVoiceInput(text);
      },
      onPartialResult: (partial) {
        setState(() => _partialText = partial);
      },
      onDone: () {
        setState(() => _isListening = false);
      },
    );
  }

  Future<void> _stopListening() async {
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.stopListening();
    setState(() => _isListening = false);
  }

  Future<void> _processVoiceInput(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _parsedFoods = [];
    });

    final aiService = ref.read(aiServiceProvider);
    final result = await aiService.parseFoodFromVoice(text);

    setState(() {
      _isProcessing = false;
      _parsedFoods = result.foods;
      _error = result.error;
    });
  }

  void _addFood(FoodAnalysis food) {
    ref.read(foodNotifierProvider.notifier).addFoodEntry(
      name: food.name,
      mealType: widget.mealType,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      servingSize: 1,
      servingUnit: food.servingSize,
      date: widget.date,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food.name} added!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _addAllFoods() {
    for (final food in _parsedFoods) {
      _addFood(food);
    }
    widget.onFoodAdded();
  }

  @override
  Widget build(BuildContext context) {
    final aiService = ref.watch(aiServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // API Key Warning
          if (!aiService.isAvailable)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI not configured. Basic food matching will be used. For best results, add your Gemini API key in Settings.',
                      style: TextStyle(color: Colors.orange[300], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Text(
            'Describe what you ate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try saying: "I had two eggs and toast for breakfast"',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Microphone button
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isListening ? 100 : 80,
              height: _isListening ? 100 : 80,
              decoration: BoxDecoration(
                color: _isListening
                    ? AppColors.error.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isListening ? AppColors.error : AppColors.primary,
                  width: 3,
                ),
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                size: 40,
                color: _isListening ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isListening ? 'Listening...' : 'Tap to speak',
            style: TextStyle(
              color: _isListening ? AppColors.error : AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Partial text while listening
          if (_isListening && _partialText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _partialText,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Text input alternative
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Or type your meal description',
              hintText: 'e.g., chicken salad with dressing',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _processVoiceInput(_textController.text),
              ),
            ),
            onSubmitted: _processVoiceInput,
          ),

          const SizedBox(height: 24),

          // Processing indicator
          if (_isProcessing)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Analyzing your meal...'),
              ],
            ),

          // Error message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(color: AppColors.error))),
                ],
              ),
            ),

          // Parsed foods
          if (_parsedFoods.isNotEmpty) ...[
            Text(
              'Found ${_parsedFoods.length} item${_parsedFoods.length > 1 ? 's' : ''}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._parsedFoods.map((food) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(food.name),
                subtitle: Text(
                  '${food.calories} cal | P: ${food.protein.round()}g C: ${food.carbs.round()}g F: ${food.fat.round()}g',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.success),
                  onPressed: () => _addFood(food),
                ),
              ),
            )),
            const SizedBox(height: 16),
            if (_parsedFoods.length > 1)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addAllFoods,
                  icon: const Icon(Icons.add),
                  label: const Text('Add All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _QuickAddTab extends ConsumerWidget {
  final MealType mealType;
  final DateTime date;
  final VoidCallback onFoodAdded;

  const _QuickAddTab({
    required this.mealType,
    required this.date,
    required this.onFoodAdded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foods = CommonFoods.items;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Suggested for this meal
        Text(
          'Suggested for ${mealType.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        ...CommonFoods.getByMeal(mealType).map((food) => _QuickFoodTile(
              food: food,
              onTap: () {
                ref.read(foodNotifierProvider.notifier).quickAddFood(
                      food,
                      mealType,
                      date,
                    );
                onFoodAdded();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${food['name']} added!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            )),
        const SizedBox(height: 16),
        
        // All foods
        const Text(
          'All Foods',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        ...foods.map((food) => _QuickFoodTile(
              food: food,
              onTap: () {
                ref.read(foodNotifierProvider.notifier).quickAddFood(
                      food,
                      mealType,
                      date,
                    );
                onFoodAdded();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${food['name']} added!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            )),
      ],
    );
  }
}

class _QuickFoodTile extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onTap;

  const _QuickFoodTile({
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(food['name']),
        subtitle: Text(
          'P: ${food['protein']}g  C: ${food['carbs']}g  F: ${food['fat']}g',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${food['calories']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              'kcal',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.constitution.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.restaurant,
            color: AppColors.constitution,
          ),
        ),
      ),
    );
  }
}

class _AIScanTab extends ConsumerStatefulWidget {
  final MealType mealType;
  final DateTime date;
  final VoidCallback onFoodAdded;

  const _AIScanTab({
    required this.mealType,
    required this.date,
    required this.onFoodAdded,
  });

  @override
  ConsumerState<_AIScanTab> createState() => _AIScanTabState();
}

class _AIScanTabState extends ConsumerState<_AIScanTab> {
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  FoodAnalysis? _analysis;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _analysis = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _analyzeFood() async {
    if (_selectedImage == null && _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a photo or description')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final imageBytes = _selectedImage != null
          ? await _selectedImage!.readAsBytes()
          : null;

      final result = await aiService.analyzeFood(
        imageBytes: imageBytes,
        description: _descriptionController.text,
      );

      setState(() {
        _analysis = result.analysis;
        _isAnalyzing = false;
      });

      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Could not analyze food. Try adding more details.'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _addFood() {
    if (_analysis == null) return;

    ref.read(foodNotifierProvider.notifier).addFoodEntry(
      name: _analysis!.name,
      mealType: widget.mealType,
      calories: _analysis!.calories,
      protein: _analysis!.protein,
      carbs: _analysis!.carbs,
      fat: _analysis!.fat,
      servingSize: 1,
      servingUnit: _analysis!.servingSize,
      date: widget.date,
    );

    widget.onFoodAdded();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_analysis!.name} added!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiService = ref.watch(aiServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // API Key Warning
          if (!aiService.isAvailable)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI not configured. Add your Gemini API key in Settings > AI Settings.',
                      style: TextStyle(color: Colors.orange[300], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Image selection area
          GestureDetector(
            onTap: () => _showImageSourceDialog(),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add photo',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Description field
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g., "Large bowl of chicken fried rice with vegetables"',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Analyze button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeFood,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze with AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Analysis result
          if (_analysis != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _analysis!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _analysis!.servingSize,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NutrientChip(
                        label: 'Calories',
                        value: '${_analysis!.calories}',
                        unit: 'kcal',
                        color: AppColors.primary,
                      ),
                      _NutrientChip(
                        label: 'Protein',
                        value: '${_analysis!.protein.toStringAsFixed(1)}',
                        unit: 'g',
                        color: const Color(0xFFFF6B6B),
                      ),
                      _NutrientChip(
                        label: 'Carbs',
                        value: '${_analysis!.carbs.toStringAsFixed(1)}',
                        unit: 'g',
                        color: const Color(0xFF4ECDC4),
                      ),
                      _NutrientChip(
                        label: 'Fat',
                        value: '${_analysis!.fat.toStringAsFixed(1)}',
                        unit: 'g',
                        color: const Color(0xFFFFD93D),
                      ),
                    ],
                  ),
                  if (_analysis!.reasoning != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _analysis!.reasoning!,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add to Log'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutrientChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ManualEntryTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final TextEditingController servingSizeController;
  final TextEditingController servingUnitController;
  final VoidCallback onSubmit;

  const _ManualEntryTab({
    required this.nameController,
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    required this.servingSizeController,
    required this.servingUnitController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Food Name *',
              hintText: 'e.g., Chicken Salad',
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: caloriesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Calories *',
              hintText: 'e.g., 350',
              suffixText: 'kcal',
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Macros (Optional)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: proteinController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Protein',
                    suffixText: 'g',
                    labelStyle: TextStyle(color: const Color(0xFFFF6B6B)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: carbsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Carbs',
                    suffixText: 'g',
                    labelStyle: TextStyle(color: const Color(0xFF4ECDC4)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: fatController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Fat',
                    suffixText: 'g',
                    labelStyle: TextStyle(color: const Color(0xFFFFD93D)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Serving Size',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: servingSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '1',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: servingUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    hintText: 'e.g., cup, slice, piece',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.constitution,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add Food'),
            ),
          ),
        ],
      ),
    );
  }
}
