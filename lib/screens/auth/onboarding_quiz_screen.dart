import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../models/user_profile.dart';

class OnboardingQuizScreen extends ConsumerStatefulWidget {
  const OnboardingQuizScreen({super.key});

  @override
  ConsumerState<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends ConsumerState<OnboardingQuizScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<String, int> _answers = {};

  final List<_QuizQuestion> _questions = [
    _QuizQuestion(
      question: 'How often do you exercise?',
      statKey: 'physical',
      options: [
        _QuizOption('Never or rarely', 1),
        _QuizOption('Once or twice a week', 2),
        _QuizOption('3-4 times a week', 3),
        _QuizOption('Almost every day', 4),
      ],
    ),
    _QuizQuestion(
      question: 'How would you describe your diet?',
      statKey: 'constitution',
      options: [
        _QuizOption('Fast food and snacks mostly', 1),
        _QuizOption('Mix of healthy and unhealthy', 2),
        _QuizOption('Mostly healthy with some treats', 3),
        _QuizOption('Very health-conscious', 4),
      ],
    ),
    _QuizQuestion(
      question: 'How often do you read or learn new things?',
      statKey: 'intelligence',
      options: [
        _QuizOption('Rarely', 1),
        _QuizOption('Occasionally', 2),
        _QuizOption('A few times a week', 3),
        _QuizOption('Daily', 4),
      ],
    ),
    _QuizQuestion(
      question: 'Do you practice mindfulness or reflection?',
      statKey: 'wisdom',
      options: [
        _QuizOption('Never tried it', 1),
        _QuizOption('Tried it a few times', 2),
        _QuizOption('Occasionally', 3),
        _QuizOption('Regular practice', 4),
      ],
    ),
    _QuizQuestion(
      question: 'How well can you focus on deep work?',
      statKey: 'focus',
      options: [
        _QuizOption('Easily distracted', 1),
        _QuizOption('Can focus for short periods', 2),
        _QuizOption('Good focus most of the time', 3),
        _QuizOption('Excellent concentration', 4),
      ],
    ),
    _QuizQuestion(
      question: 'How comfortable are you speaking in public?',
      statKey: 'charisma',
      options: [
        _QuizOption('Very uncomfortable', 1),
        _QuizOption('Nervous but can manage', 2),
        _QuizOption('Fairly comfortable', 3),
        _QuizOption('Love it!', 4),
      ],
    ),
    _QuizQuestion(
      question: 'How active is your social life?',
      statKey: 'social',
      options: [
        _QuizOption('Prefer being alone', 1),
        _QuizOption('Small circle of friends', 2),
        _QuizOption('Regular social activities', 3),
        _QuizOption('Very social and outgoing', 4),
      ],
    ),
    _QuizQuestion(
      question: 'How disciplined are you with routines?',
      statKey: 'discipline',
      options: [
        _QuizOption('No routines at all', 1),
        _QuizOption('Some loose habits', 2),
        _QuizOption('Good daily routines', 3),
        _QuizOption('Highly structured life', 4),
      ],
    ),
    _QuizQuestion(
      question: 'How creative do you consider yourself?',
      statKey: 'creativity',
      options: [
        _QuizOption('Not very creative', 1),
        _QuizOption('Occasionally creative', 2),
        _QuizOption('Fairly creative', 3),
        _QuizOption('Very creative', 4),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectAnswer(String statKey, int value) {
    setState(() {
      _answers[statKey] = value;
    });

    if (_currentPage < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  UserStats _calculateStats() {
    // Base stats at 10
    int strength = 10;
    int dexterity = 10;
    int constitution = 10;
    int intelligence = 10;
    int wisdom = 10;
    int focus = 10;
    int charisma = 10;
    int social = 10;
    int discipline = 10;
    int creativity = 10;

    // Apply quiz bonuses
    final physical = _answers['physical'] ?? 2;
    strength += (physical - 1) * 3;
    dexterity += (physical - 1) * 3;

    constitution += ((_answers['constitution'] ?? 2) - 1) * 4;
    intelligence += ((_answers['intelligence'] ?? 2) - 1) * 4;
    wisdom += ((_answers['wisdom'] ?? 2) - 1) * 4;
    focus += ((_answers['focus'] ?? 2) - 1) * 4;
    charisma += ((_answers['charisma'] ?? 2) - 1) * 4;
    social += ((_answers['social'] ?? 2) - 1) * 4;
    discipline += ((_answers['discipline'] ?? 2) - 1) * 4;
    creativity += ((_answers['creativity'] ?? 2) - 1) * 4;

    return UserStats(
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      focus: focus,
      charisma: charisma,
      social: social,
      discipline: discipline,
      creativity: creativity,
    );
  }

  Future<void> _finishQuiz() async {
    final stats = _calculateStats();

    // Update user profile with calculated stats
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      await ref.read(userProfileNotifierProvider.notifier).updateStats(stats);
    }

    if (mounted) {
      context.go('/home');
    }
  }

  void _skipQuiz() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Character Setup'),
        actions: [
          TextButton(
            onPressed: _skipQuiz,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return _QuizPage(
                  question: question,
                  selectedValue: _answers[question.statKey],
                  onSelect: (value) => _selectAnswer(question.statKey, value),
                );
              },
            ),
          ),
          // Navigation
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  )
                else
                  const SizedBox(width: 100),
                Text(
                  '${_currentPage + 1} / ${_questions.length}',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                if (_currentPage == _questions.length - 1)
                  ElevatedButton(
                    onPressed: _answers.length == _questions.length ? _finishQuiz : null,
                    child: const Text('Finish'),
                  )
                else
                  TextButton.icon(
                    onPressed: _answers.containsKey(_questions[_currentPage].statKey)
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizPage extends StatelessWidget {
  final _QuizQuestion question;
  final int? selectedValue;
  final ValueChanged<int> onSelect;

  const _QuizPage({
    required this.question,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            question.question,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),
          ...question.options.map((option) {
            final isSelected = selectedValue == option.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onSelect(option.value),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : null,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  final String question;
  final String statKey;
  final List<_QuizOption> options;

  _QuizQuestion({
    required this.question,
    required this.statKey,
    required this.options,
  });
}

class _QuizOption {
  final String label;
  final int value;

  _QuizOption(this.label, this.value);
}
