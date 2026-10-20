import 'package:equatable/equatable.dart';
import 'dart:math';

/// Types of missions that must be completed to dismiss an alarm
enum AlarmMissionType {
  none('None', 'Tap to dismiss'),
  math('Math Problems', 'Solve math problems to dismiss'),
  shake('Shake Phone', 'Shake your phone to dismiss'),
  typing('Typing', 'Type a phrase to dismiss'),
  memory('Memory Game', 'Match pairs to dismiss'),
  barcode('Scan Barcode', 'Scan a specific barcode/QR code'),
  photo('Take Photo', 'Take a photo of a specific location'),
  steps('Walk Steps', 'Walk a number of steps to dismiss'),
  squat('Squats', 'Do squats to dismiss (with camera)');

  final String displayName;
  final String description;
  const AlarmMissionType(this.displayName, this.description);
}

/// Difficulty level for missions
enum MissionDifficulty {
  easy(1, 'Easy'),
  medium(2, 'Medium'),
  hard(3, 'Hard'),
  extreme(4, 'Extreme');

  final int level;
  final String displayName;
  const MissionDifficulty(this.level, this.displayName);
}

/// Configuration for an alarm mission
class AlarmMission extends Equatable {
  final AlarmMissionType type;
  final MissionDifficulty difficulty;
  final int count; // Number of problems/shakes/steps required
  final String? barcodeData; // For barcode mission - the barcode to scan
  final String? photoLocationHint; // For photo mission - description of location
  final String? savedPhotoPath; // For photo mission - reference photo

  const AlarmMission({
    required this.type,
    this.difficulty = MissionDifficulty.medium,
    this.count = 3,
    this.barcodeData,
    this.photoLocationHint,
    this.savedPhotoPath,
  });

  /// Get default count based on type and difficulty
  static int getDefaultCount(AlarmMissionType type, MissionDifficulty difficulty) {
    switch (type) {
      case AlarmMissionType.none:
        return 0;
      case AlarmMissionType.math:
        return 3 + difficulty.level; // 4-7 problems
      case AlarmMissionType.shake:
        return 20 + (difficulty.level * 10); // 30-60 shakes
      case AlarmMissionType.typing:
        return 1; // 1 phrase
      case AlarmMissionType.memory:
        return 4 + (difficulty.level * 2); // 6-12 pairs
      case AlarmMissionType.barcode:
        return 1;
      case AlarmMissionType.photo:
        return 1;
      case AlarmMissionType.steps:
        return 20 + (difficulty.level * 10); // 30-60 steps
      case AlarmMissionType.squat:
        return 5 + (difficulty.level * 5); // 10-25 squats
    }
  }

  factory AlarmMission.fromMap(Map<String, dynamic> map) {
    return AlarmMission(
      type: AlarmMissionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => AlarmMissionType.none,
      ),
      difficulty: MissionDifficulty.values.firstWhere(
        (d) => d.name == map['difficulty'],
        orElse: () => MissionDifficulty.medium,
      ),
      count: map['count'] ?? 3,
      barcodeData: map['barcodeData'],
      photoLocationHint: map['photoLocationHint'],
      savedPhotoPath: map['savedPhotoPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'difficulty': difficulty.name,
      'count': count,
      'barcodeData': barcodeData,
      'photoLocationHint': photoLocationHint,
      'savedPhotoPath': savedPhotoPath,
    };
  }

  AlarmMission copyWith({
    AlarmMissionType? type,
    MissionDifficulty? difficulty,
    int? count,
    String? barcodeData,
    String? photoLocationHint,
    String? savedPhotoPath,
  }) {
    return AlarmMission(
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      count: count ?? this.count,
      barcodeData: barcodeData ?? this.barcodeData,
      photoLocationHint: photoLocationHint ?? this.photoLocationHint,
      savedPhotoPath: savedPhotoPath ?? this.savedPhotoPath,
    );
  }

  @override
  List<Object?> get props => [type, difficulty, count, barcodeData, photoLocationHint, savedPhotoPath];
}

/// A math problem for the math mission
class MathProblem {
  final int operand1;
  final int operand2;
  final MathOperation operation;
  final int answer;

  MathProblem._({
    required this.operand1,
    required this.operand2,
    required this.operation,
    required this.answer,
  });

  String get questionText {
    return '$operand1 ${operation.symbol} $operand2 = ?';
  }

  /// Generate a random math problem based on difficulty
  factory MathProblem.generate(MissionDifficulty difficulty) {
    final random = Random();
    late int op1, op2, answer;
    late MathOperation operation;

    switch (difficulty) {
      case MissionDifficulty.easy:
        // Simple addition/subtraction under 20
        operation = random.nextBool() ? MathOperation.add : MathOperation.subtract;
        op1 = random.nextInt(15) + 5;
        op2 = random.nextInt(10) + 1;
        if (operation == MathOperation.subtract && op2 > op1) {
          final temp = op1;
          op1 = op2;
          op2 = temp;
        }
        break;

      case MissionDifficulty.medium:
        // Addition/subtraction/multiplication under 50
        final ops = [MathOperation.add, MathOperation.subtract, MathOperation.multiply];
        operation = ops[random.nextInt(ops.length)];
        if (operation == MathOperation.multiply) {
          op1 = random.nextInt(10) + 2;
          op2 = random.nextInt(8) + 2;
        } else {
          op1 = random.nextInt(40) + 10;
          op2 = random.nextInt(20) + 5;
          if (operation == MathOperation.subtract && op2 > op1) {
            final temp = op1;
            op1 = op2;
            op2 = temp;
          }
        }
        break;

      case MissionDifficulty.hard:
        // All operations with larger numbers
        operation = MathOperation.values[random.nextInt(MathOperation.values.length)];
        if (operation == MathOperation.multiply) {
          op1 = random.nextInt(12) + 3;
          op2 = random.nextInt(12) + 3;
        } else if (operation == MathOperation.divide) {
          op2 = random.nextInt(10) + 2;
          answer = random.nextInt(12) + 2;
          op1 = op2 * answer; // Ensure clean division
        } else {
          op1 = random.nextInt(80) + 20;
          op2 = random.nextInt(50) + 10;
          if (operation == MathOperation.subtract && op2 > op1) {
            final temp = op1;
            op1 = op2;
            op2 = temp;
          }
        }
        break;

      case MissionDifficulty.extreme:
        // Complex calculations
        operation = MathOperation.values[random.nextInt(MathOperation.values.length)];
        if (operation == MathOperation.multiply) {
          op1 = random.nextInt(15) + 6;
          op2 = random.nextInt(15) + 6;
        } else if (operation == MathOperation.divide) {
          op2 = random.nextInt(12) + 3;
          answer = random.nextInt(15) + 5;
          op1 = op2 * answer;
        } else {
          op1 = random.nextInt(150) + 50;
          op2 = random.nextInt(100) + 20;
          if (operation == MathOperation.subtract && op2 > op1) {
            final temp = op1;
            op1 = op2;
            op2 = temp;
          }
        }
        break;
    }

    // Calculate answer if not already set (for division)
    if (operation != MathOperation.divide) {
      answer = operation.calculate(op1, op2);
    }

    return MathProblem._(
      operand1: op1,
      operand2: op2,
      operation: operation,
      answer: answer,
    );
  }

  bool checkAnswer(int userAnswer) => userAnswer == answer;
}

enum MathOperation {
  add('+'),
  subtract('-'),
  multiply('×'),
  divide('÷');

  final String symbol;
  const MathOperation(this.symbol);

  int calculate(int a, int b) {
    switch (this) {
      case MathOperation.add:
        return a + b;
      case MathOperation.subtract:
        return a - b;
      case MathOperation.multiply:
        return a * b;
      case MathOperation.divide:
        return a ~/ b;
    }
  }
}

/// Typing challenge phrases by difficulty
class TypingChallenges {
  static const Map<MissionDifficulty, List<String>> phrases = {
    MissionDifficulty.easy: [
      'Good morning',
      'Wake up now',
      'Time to rise',
      'Start the day',
      'Rise and shine',
    ],
    MissionDifficulty.medium: [
      'The early bird catches the worm',
      'A new day brings new opportunities',
      'Success starts with waking up early',
      'Today is going to be a great day',
      'Every morning is a fresh beginning',
    ],
    MissionDifficulty.hard: [
      'The only way to do great work is to love what you do',
      'Believe you can and youre halfway there',
      'Your limitation is only your imagination',
      'Push yourself because no one else is going to do it',
      'Great things never come from comfort zones',
    ],
    MissionDifficulty.extreme: [
      'The future belongs to those who believe in the beauty of their dreams',
      'It does not matter how slowly you go as long as you do not stop',
      'Success is not final failure is not fatal it is courage to continue that counts',
      'The difference between ordinary and extraordinary is that little extra',
      'Do not watch the clock do what it does keep going',
    ],
  };

  static String getRandom(MissionDifficulty difficulty) {
    final list = phrases[difficulty]!;
    return list[Random().nextInt(list.length)];
  }
}

/// Memory game card for memory mission
class MemoryCard {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });

  static List<MemoryCard> generateCards(int pairCount) {
    const emojis = ['🌟', '🎯', '🚀', '💡', '🔥', '⚡', '🎨', '🎵', '🏆', '💪', '🌈', '🎁'];
    final selectedEmojis = emojis.take(pairCount).toList();
    final cards = <MemoryCard>[];

    for (int i = 0; i < selectedEmojis.length; i++) {
      cards.add(MemoryCard(id: i * 2, emoji: selectedEmojis[i]));
      cards.add(MemoryCard(id: i * 2 + 1, emoji: selectedEmojis[i]));
    }

    cards.shuffle();
    return cards;
  }
}
