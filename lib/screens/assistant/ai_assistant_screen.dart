import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';
import '../../services/voice_service.dart';
import '../../providers/food_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/food_entry.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  String _partialText = '';
  String _lastCommand = '';
  String _assistantResponse = '';
  List<_ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _messages.add(_ChatMessage(
      isAssistant: true,
      text: 'Hi! I\'m your Life Quest assistant. Try saying or typing:\n\n'
          '- "I had chicken and rice for lunch"\n'
          '- "Add a task to go to the gym"\n'
          '- "Show my stats"\n'
          '- "How many calories did I eat today?"',
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _focusNode.unfocus();
    _processCommand(text);
  }

  Future<void> _startListening() async {
    final voiceService = ref.read(voiceServiceProvider);

    setState(() {
      _isListening = true;
      _partialText = '';
    });

    await voiceService.startListening(
      onResult: (text) {
        setState(() {
          _lastCommand = text;
          _isListening = false;
        });
        _processCommand(text);
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

  // Check if input looks like a food description
  bool _looksLikeFood(String text) {
    final lower = text.toLowerCase();
    final foodIndicators = [
      'i had', 'i ate', 'i eat', 'had some', 'ate some', 'eating',
      'for breakfast', 'for lunch', 'for dinner', 'for snack',
      'just ate', 'just had', 'i drank', 'i drink',
    ];
    final commonFoods = [
      'chicken', 'rice', 'egg', 'bread', 'pizza', 'burger', 'salad',
      'pasta', 'sandwich', 'coffee', 'milk', 'banana', 'apple',
      'steak', 'fish', 'soup', 'noodle', 'sushi', 'taco', 'burrito',
    ];

    // Check food indicators
    if (foodIndicators.any((i) => lower.contains(i))) return true;
    // Check if it contains common food words
    if (commonFoods.any((f) => lower.contains(f))) return true;
    return false;
  }

  Future<void> _processCommand(String command) async {
    if (command.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _messages.add(_ChatMessage(isAssistant: false, text: command));
    });

    final aiService = ref.read(aiServiceProvider);
    String response = 'I\'m not sure what to do. Try saying "I had chicken for lunch" or "show my stats".';
    String action;

    // First, try to detect the action locally for common patterns
    final lower = command.toLowerCase();

    if (_looksLikeFood(lower)) {
      action = 'add_food';
    } else if (lower.contains('stats') || lower.contains('level') || lower.contains('character')) {
      action = 'check_stats';
    } else if (lower.contains('calorie') || lower.contains('nutrition') || lower.contains('macro')) {
      action = 'check_nutrition';
    } else if (lower.contains('quest') || lower.contains('goal')) {
      action = 'check_quests';
    } else if (lower.contains('task')) {
      action = 'add_task';
    } else if (lower.contains('workout') || lower.contains('exercise') || lower.contains('gym')) {
      action = 'log_workout';
    } else {
      // Fall back to AI parsing if available
      final result = await aiService.parseVoiceCommand(command);
      action = result.action;
    }

    // Execute the action
    switch (action) {
      case 'add_food':
        final foodResult = await aiService.parseFoodFromVoice(command);
        if (foodResult.foods.isNotEmpty) {
          for (final food in foodResult.foods) {
            ref.read(foodNotifierProvider.notifier).addFoodEntry(
              name: food.name,
              mealType: _getMealTypeFromTime(),
              calories: food.calories,
              protein: food.protein,
              carbs: food.carbs,
              fat: food.fat,
              servingSize: 1,
              servingUnit: food.servingSize,
              date: DateTime.now(),
            );
          }
          final names = foodResult.foods.map((f) => f.name).join(', ');
          final totalCal = foodResult.foods.fold(0, (sum, f) => sum + f.calories);
          response = 'Added $names to your food log. Total: $totalCal calories.';
        } else {
          response = foodResult.error ?? 'I couldn\'t identify the food. Could you describe it differently?';
        }
        break;

      case 'check_stats':
        if (mounted) context.push('/stats');
        response = 'Opening your character stats.';
        break;

      case 'check_nutrition':
        final nutrition = ref.read(dailyNutritionProvider);
        response = 'Today you\'ve had ${nutrition.totalCalories} calories, '
            '${nutrition.totalProtein.round()}g protein, '
            '${nutrition.totalCarbs.round()}g carbs, and '
            '${nutrition.totalFat.round()}g fat.';
        break;

      case 'check_quests':
        if (mounted) context.push('/quests');
        response = 'Opening your quests.';
        break;

      case 'log_workout':
        if (mounted) context.push('/workouts/log');
        response = 'Opening workout log.';
        break;

      case 'add_task':
        if (mounted) context.push('/tasks');
        response = 'Opening tasks. You can add a new task there.';
        break;

      default:
        // Keep the default response
        break;
    }

    setState(() {
      _isProcessing = false;
      _assistantResponse = response;
      _messages.add(_ChatMessage(isAssistant: true, text: response));
    });
  }

  MealType _getMealTypeFromTime() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 20) return MealType.dinner;
    return MealType.snack;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 24),
            SizedBox(width: 8),
            Text('AI Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text('Thinking...'),
                ],
              ),
            ),

          // Listening indicator
          if (_isListening && _partialText.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _partialText,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom controls
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Microphone button
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = _isListening
                            ? 1.0 + (_pulseController.value * 0.05)
                            : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isListening
                                    ? [AppColors.error, AppColors.error.withOpacity(0.7)]
                                    : [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isListening ? AppColors.error : AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              size: 24,
                              color: _isListening ? Colors.white : AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening...' : 'Type a message...',
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendTextMessage(),
                      enabled: !_isListening && !_isProcessing,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send button
                  GestureDetector(
                    onTap: _isProcessing ? null : _sendTextMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isAssistant;
  final String text;

  _ChatMessage({required this.isAssistant, required this.text});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isAssistant ? AppColors.card : AppColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: message.isAssistant ? const Radius.circular(4) : null,
            bottomRight: !message.isAssistant ? const Radius.circular(4) : null,
          ),
          border: message.isAssistant
              ? null
              : Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isAssistant) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isAssistant ? null : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
