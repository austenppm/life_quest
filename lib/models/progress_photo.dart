import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Category/type of progress photo
enum ProgressPhotoType {
  front('Front', 'Front view'),
  back('Back', 'Back view'),
  side('Side', 'Side view'),
  flexing('Flexing', 'Flexing pose'),
  relaxed('Relaxed', 'Relaxed pose'),
  custom('Custom', 'Custom angle');

  final String displayName;
  final String description;
  const ProgressPhotoType(this.displayName, this.description);
}

/// A progress photo for tracking physical transformation
class ProgressPhoto extends Equatable {
  final String id;
  final String userId;
  final String imageUrl;
  final String? localPath; // For local storage before upload
  final DateTime date;
  final ProgressPhotoType type;
  final String? notes;
  // Associated measurements at time of photo
  final double? weight;
  final double? bodyFat;
  final Map<String, double>? measurements; // body measurements snapshot
  final DateTime createdAt;

  const ProgressPhoto({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.localPath,
    required this.date,
    this.type = ProgressPhotoType.front,
    this.notes,
    this.weight,
    this.bodyFat,
    this.measurements,
    required this.createdAt,
  });

  factory ProgressPhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgressPhoto(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      localPath: data['localPath'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: ProgressPhotoType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ProgressPhotoType.front,
      ),
      notes: data['notes'],
      weight: (data['weight'] as num?)?.toDouble(),
      bodyFat: (data['bodyFat'] as num?)?.toDouble(),
      measurements: data['measurements'] != null
          ? Map<String, double>.from(
              (data['measurements'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            )
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'localPath': localPath,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'notes': notes,
      'weight': weight,
      'bodyFat': bodyFat,
      'measurements': measurements,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ProgressPhoto copyWith({
    String? imageUrl,
    String? localPath,
    DateTime? date,
    ProgressPhotoType? type,
    String? notes,
    double? weight,
    double? bodyFat,
    Map<String, double>? measurements,
  }) {
    return ProgressPhoto(
      id: id,
      userId: userId,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      date: date ?? this.date,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      measurements: measurements ?? this.measurements,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, imageUrl, localPath, date, type, notes,
        weight, bodyFat, measurements, createdAt,
      ];
}

/// A comparison between two progress photos
class PhotoComparison {
  final ProgressPhoto before;
  final ProgressPhoto after;

  PhotoComparison({required this.before, required this.after});

  Duration get timeDifference => after.date.difference(before.date);

  int get daysDifference => timeDifference.inDays;

  double? get weightChange {
    if (before.weight == null || after.weight == null) return null;
    return after.weight! - before.weight!;
  }

  double? get bodyFatChange {
    if (before.bodyFat == null || after.bodyFat == null) return null;
    return after.bodyFat! - before.bodyFat!;
  }

  Map<String, double>? get measurementChanges {
    if (before.measurements == null || after.measurements == null) return null;

    final changes = <String, double>{};
    for (final key in after.measurements!.keys) {
      if (before.measurements!.containsKey(key)) {
        changes[key] = after.measurements![key]! - before.measurements![key]!;
      }
    }
    return changes.isEmpty ? null : changes;
  }
}

/// Stats for progress photos
class ProgressPhotoStats {
  final int totalPhotos;
  final DateTime? firstPhotoDate;
  final DateTime? latestPhotoDate;
  final int daysCovered;
  final Map<ProgressPhotoType, int> photosByType;

  const ProgressPhotoStats({
    this.totalPhotos = 0,
    this.firstPhotoDate,
    this.latestPhotoDate,
    this.daysCovered = 0,
    this.photosByType = const {},
  });

  factory ProgressPhotoStats.fromPhotos(List<ProgressPhoto> photos) {
    if (photos.isEmpty) return const ProgressPhotoStats();

    photos.sort((a, b) => a.date.compareTo(b.date));
    final first = photos.first;
    final last = photos.last;

    final byType = <ProgressPhotoType, int>{};
    for (final photo in photos) {
      byType[photo.type] = (byType[photo.type] ?? 0) + 1;
    }

    return ProgressPhotoStats(
      totalPhotos: photos.length,
      firstPhotoDate: first.date,
      latestPhotoDate: last.date,
      daysCovered: last.date.difference(first.date).inDays,
      photosByType: byType,
    );
  }
}
