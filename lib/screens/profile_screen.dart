import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😢', 'label': 'Awful', 'color': Color(0xFFEF5350)},
    {'emoji': '😕', 'label': 'Bad', 'color': Color(0xFFFF7043)},
    {'emoji': '😐', 'label': 'Okay', 'color': Color(0xFFFFCA28)},
    {'emoji': '🙂', 'label': 'Good', 'color': Color(0xFF66BB6A)},
    {'emoji': '😄', 'label': 'Great', 'color': Color(0xFF42A5F5)},
  ];

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  String get _displayName {
    final name = _user?.displayName ?? '';
    return name.isNotEmpty ? name : 'Friend';
  }

  String get _email => _user?.email ?? '';

  /// Returns the user's initials for the avatar circle
  String get _initials {
    final name = _displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final m = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  double _calcAverage(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries.fold<int>(0, (s, e) => s + e.moodScore) / entries.length;
  }

  String _moodLabelForScore(double score) {
    if (score < 1.5) return 'Awful';
    if (score < 2.5) return 'Bad';
    if (score < 3.5) return 'Okay';
    if (score < 4.5) return 'Good';
    return 'Great';
  }

  // ─────────────────────────────────────────────
  // Delete Entry
  // ─────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, JournalEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry'),
        content: const Text(
            'Are you sure you want to delete this journal entry? '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteJournalEntry(entry.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ─────────────────────────────────────────────
  // Widgets
  // ─────────────────────────────────────────────

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFFB39DDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar circle with initials
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Text(
              _initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Expandable journal entry card with delete button
  Widget _buildEntryCard(JournalEntry entry) {
    final moodData = _moods[entry.moodScore - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        // Remove the default divider on ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Text(
            moodData['emoji'] as String,
            style: const TextStyle(fontSize: 30),
          ),
          title: Row(
            children: [
              Text(
                moodData['label'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: moodData['color'] as Color,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              if (entry.emotion.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF7C4DFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✨ ${entry.emotion}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            '${_formatDate(entry.date)}  •  ${_formatTime(entry.date)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          children: [
            // Journal Text
            _buildExpandedSection(
              icon: Icons.book_outlined,
              label: 'Journal Entry',
              content: entry.text,
              iconColor: Colors.grey,
            ),

            // AI Message
            if (entry.aiMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildExpandedSection(
                icon: Icons.auto_awesome,
                label: 'AI Message',
                content: entry.aiMessage,
                iconColor: const Color(0xFF7C4DFF),
                contentColor: const Color(0xFF7C4DFF),
                bgColor:
                    const Color(0xFF7C4DFF).withOpacity(0.05),
              ),
            ],

            // Coping Tip
            if (entry.aiTip.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildExpandedSection(
                icon: Icons.tips_and_updates,
                label: 'Coping Tip',
                content: entry.aiTip,
                iconColor: const Color(0xFF66BB6A),
                bgColor:
                    const Color(0xFF66BB6A).withOpacity(0.05),
              ),
            ],

            const SizedBox(height: 14),

            // Delete Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmDelete(context, entry),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 18),
                label: const Text(
                  'Delete Entry',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSection({
    required IconData icon,
    required String label,
    required String content,
    required Color iconColor,
    Color? contentColor,
    Color? bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: contentColor ?? Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Profile Header
          _buildProfileHeader(),
          const SizedBox(height: 24),

          StreamBuilder<List<JournalEntry>>(
            stream: _firestoreService.getAllEntries(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                );
              }

              final entries = snapshot.data ?? [];
              final avgScore = _calcAverage(entries);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Entries',
                        '${entries.length}',
                        Icons.book_outlined,
                        const Color(0xFF7C4DFF),
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        'Avg Mood',
                        entries.isEmpty
                            ? '—'
                            : avgScore.toStringAsFixed(1),
                        Icons.mood,
                        const Color(0xFF66BB6A),
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        'Overall',
                        entries.isEmpty
                            ? '—'
                            : _moods[(avgScore.round().clamp(1, 5)) - 1]
                                ['emoji'] as String,
                        Icons.insights,
                        const Color(0xFF42A5F5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Journal History Title
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Journal History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Entry List or Empty State
                  if (entries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.book_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No journal entries yet.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Head to the Home tab to log your\nfirst mood and journal entry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ...entries.map((entry) => _buildEntryCard(entry)),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}