import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the Firestore collection for the current user's entries.
  /// Structure: users/{userId}/entries/{entryId}
  CollectionReference<Map<String, dynamic>> get _entriesCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User is not logged in.');
    return _db.collection('users').doc(uid).collection('entries');
  }

  // ─────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────

  /// Save a new journal entry to Firestore
  Future<void> saveJournalEntry(JournalEntry entry) async {
    try {
      await _entriesCollection.add(entry.toMap());
    } catch (e) {
      throw Exception('Failed to save entry: $e');
    }
  }

  // ─────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────

  /// Stream the most recent [limit] entries for the home screen
  Stream<List<JournalEntry>> getRecentEntries({int limit = 3}) {
    return _entriesCollection
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntry.fromFirestore(doc))
            .toList());
  }

  /// Stream ALL entries — used by Profile and Mood Trends screens
  Stream<List<JournalEntry>> getAllEntries() {
    return _entriesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntry.fromFirestore(doc))
            .toList());
  }

  /// Fetch entries within a date range — used for the weekly mood chart
  Stream<List<JournalEntry>> getEntriesInRange({
    required DateTime from,
    required DateTime to,
  }) {
    return _entriesCollection
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from),
            isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntry.fromFirestore(doc))
            .toList());
  }

  // ─────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────

  /// Update an existing entry by its Firestore document ID
  Future<void> updateJournalEntry(JournalEntry entry) async {
    if (entry.id.isEmpty) throw Exception('Entry ID is missing.');
    try {
      await _entriesCollection.doc(entry.id).update(entry.toMap());
    } catch (e) {
      throw Exception('Failed to update entry: $e');
    }
  }

  // ─────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────

  /// Delete an entry by its Firestore document ID
  Future<void> deleteJournalEntry(String entryId) async {
    if (entryId.isEmpty) throw Exception('Entry ID is missing.');
    try {
      await _entriesCollection.doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete entry: $e');
    }
  }

  // ─────────────────────────────────────────────
  // STATS (used by Mood Trends screen)
  // ─────────────────────────────────────────────

  /// Returns the last 7 days of entries for the weekly mood chart
  Stream<List<JournalEntry>> getWeeklyEntries() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final startOfWeek = DateTime(
        sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    return getEntriesInRange(from: startOfWeek, to: now);
  }

  /// Returns the total number of journal entries the user has written
  Future<int> getTotalEntryCount() async {
    final snapshot = await _entriesCollection.count().get();
    return snapshot.count ?? 0;
  }

  /// Returns the average mood score across all entries
  Future<double> getAverageMoodScore() async {
    final snapshot = await _entriesCollection.get();
    if (snapshot.docs.isEmpty) return 0.0;

    final entries =
        snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();
    final total =
        entries.fold<int>(0, (sum, entry) => sum + entry.moodScore);
    return total / entries.length;
  }
}