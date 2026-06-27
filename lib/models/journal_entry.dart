import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final int moodScore;
  final String text;
  final String emotion;
  final String aiMessage;
  final String aiTip;
  final DateTime date;

  JournalEntry({
    required this.id,
    required this.moodScore,
    required this.text,
    required this.emotion,
    required this.aiMessage,
    required this.aiTip,
    required this.date,
  });

  /// Convert a Firestore document snapshot into a JournalEntry object
  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalEntry(
      id: doc.id,
      moodScore: (data['moodScore'] as num?)?.toInt() ?? 1,
      text: data['text'] as String? ?? '',
      emotion: data['emotion'] as String? ?? '',
      aiMessage: data['aiMessage'] as String? ?? '',
      aiTip: data['aiTip'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert a JournalEntry object into a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'moodScore': moodScore,
      'text': text,
      'emotion': emotion,
      'aiMessage': aiMessage,
      'aiTip': aiTip,
      'date': Timestamp.fromDate(date),
    };
  }

  /// Create a copy of this entry with some fields changed
  JournalEntry copyWith({
    String? id,
    int? moodScore,
    String? text,
    String? emotion,
    String? aiMessage,
    String? aiTip,
    DateTime? date,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      moodScore: moodScore ?? this.moodScore,
      text: text ?? this.text,
      emotion: emotion ?? this.emotion,
      aiMessage: aiMessage ?? this.aiMessage,
      aiTip: aiTip ?? this.aiTip,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, moodScore: $moodScore, emotion: $emotion, date: $date)';
  }
}