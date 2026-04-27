import 'package:flutter/material.dart';
import 'package:sfx_imjong_care/core/services/app_storage.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';
import 'package:sfx_imjong_care/features/will_card/presentation/screens/will_card_screen.dart';
// Date formatting is handled inline to avoid extra intl dependency

/// Displays the user's card history as scrollable thumbnails.
/// Features mini card previews with template-colored borders, creation dates,
/// "View again" tap actions, and swipe-to-delete functionality.
class CardHistorySection extends StatefulWidget {
  const CardHistorySection({super.key});

  @override
  State<CardHistorySection> createState() => _CardHistorySectionState();
}

class _CardHistorySectionState extends State<CardHistorySection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AppStorage.getCardHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final history = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CARD HISTORY / 최근 카드',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00DDFF),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${history.length}개',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                physics: const BouncingScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final entry = history[index];
                  return _CardHistoryThumbnail(
                    card: WillCard(
                      name: entry['name'] as String,
                      values: List<String>.from(entry['values'] as List),
                      will: entry['will'] as String,
                    ),
                    template: _parseTemplate(entry['template'] as String? ?? 'neon'),
                    timestamp: entry['timestamp'] as String? ?? '',
                    onTap: () => _openCard(context, entry),
                    onDelete: () => _deleteCard(index),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteCard(int index) {
    AppStorage.clearCardHistory();
    // Note: full re-fetch happens on next build via FutureBuilder
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '카드가 삭제되었습니다.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13),
          ),
          backgroundColor: Color(0xFFFF00AA),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  CardTemplate _parseTemplate(String name) {
    switch (name.toLowerCase()) {
      case 'neon':
        return CardTemplate.neon;
      case 'sunset':
        return CardTemplate.sunset;
      case 'ocean':
        return CardTemplate.ocean;
      case 'aurora':
        return CardTemplate.aurora;
      default:
        return CardTemplate.neon;
    }
  }

  void _openCard(BuildContext context, Map<String, dynamic> entry) {
    final card = WillCard(
      name: entry['name'] as String,
      values: List<String>.from(entry['values'] as List),
      will: entry['will'] as String,
    );
    final template = _parseTemplate(entry['template'] as String? ?? 'neon');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WillCardRenderScreen(card: card, template: template),
      ),
    );
  }
}

/// Small card thumbnail with template-colored border, creation date,
/// tap-to-view, and swipe-to-delete.
class _CardHistoryThumbnail extends StatefulWidget {
  final WillCard card;
  final CardTemplate template;
  final String timestamp;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CardHistoryThumbnail({
    required this.card,
    required this.template,
    required this.timestamp,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_CardHistoryThumbnail> createState() => _CardHistoryThumbnailState();
}

class _CardHistoryThumbnailState extends State<_CardHistoryThumbnail>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inHours < 1) return '${diff.inMinutes}분 전';
      if (diff.inDays < 1) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';

      // Manual MM/dd formatting (no intl dependency)
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      return '$month/$day';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: widget.template.accentColor.withValues(alpha: 0.3)),
                ),
                title: Text(
                  '카드 삭제',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    color: widget.template.accentColor,
                  ),
                ),
                content: Text(
                  '${widget.card.name} 카드를 정말 삭제하시겠습니까?',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFFCCCCCC),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      '취소',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      '삭제',
                      style: TextStyle(color: Color(0xFFFF4444)),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFFF4444), size: 20),
      ),
      onDismissed: (direction) {
        widget.onDelete();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 145,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.template.gradientColors[0],
                  widget.template.gradientColors[1],
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.template.accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.template.accentColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 4,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: widget.template.accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: widget.template.accentColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.card.name,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.template.accentColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Divider
                Container(
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.template.accentColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Value items (up to 2)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.card.values
                        .take(2)
                        .map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    color: widget.template.accentColor.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    v,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 8,
                                      color: Color(0xFFAAAAAA),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                // Footer row: date + "다시 보기"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(widget.timestamp),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 7,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 8,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '다시 보기',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 7,
                            color: widget.template.accentColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
