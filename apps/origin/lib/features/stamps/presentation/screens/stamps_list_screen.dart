import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:origin/core/services/database_service.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/features/stamps/presentation/widgets/stamp_card.dart';

/// Page listing document stamps.
class StampsListPage extends StatefulWidget {
  const StampsListPage({super.key});

  @override
  State<StampsListPage> createState() => _StampsListPageState();
}

class _StampsListPageState extends State<StampsListPage> {
  List<Map<String, dynamic>> _stamps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStamps();
  }

  Future<void> _loadStamps() async {
    try {
      final results = await globalDatabaseService.getAllStamps();
      if (mounted) {
        setState(() {
          _stamps = results;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[StampsListPage] Error loading stamps: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stamps.isEmpty) {
      return _buildEmptyState(style);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        size: 22, color: AppColor.neonGreen),
                    const SizedBox(width: 10),
                    Text(
                      'Stamps',
                      style: style.textTheme.headlineMedium!.copyWith(
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),

              const SizedBox(height: 16),

              // List
              Expanded(
                child: ListView.separated(
                  itemCount: _stamps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final stamp = _stamps[index];
                    final dateStr = stamp['timestamp'] as String? ?? '';
                    final date = dateStr.isNotEmpty
                        ? DateTime.tryParse(dateStr)
                        : null;
                    final title = stamp['content_hash'] as String? ?? 'Stamp';
                    final characters =
                        (stamp['content_length'] as num?)?.toInt() ?? 0;
                    final score = (stamp['authenticity_score'] as num?)
                                ?.toDouble() ??
                            0.0;
                    final sessionId = stamp['session_id'] as String? ?? '';
                    final userId = stamp['user_id'] as String? ?? '';

                    return StampCard(
                      date: date ?? DateTime.now(),
                      title: _truncateHash(title),
                      characters: characters,
                      score: score,
                      sessionId: sessionId,
                      userId: userId,
                    ).animate().fadeIn(
                          duration: 300.ms,
                          delay: (300 + index * 80).ms,
                        ).slide(begin: const Offset(-0.05, 0));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }

  Widget _buildEmptyState(ThemeData style) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppColor.textDim,
            ),
            const SizedBox(height: 20),
            Text(
              'No stamps yet.',
              style: style.textTheme.titleLarge!.copyWith(
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Write and complete a document to create one.',
              textAlign: TextAlign.center,
              style: style.textTheme.bodyMedium!.copyWith(
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
